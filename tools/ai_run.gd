extends SceneTree
#
# AI-Agent-Driven Full-Run 驅動器（檔案協定 wrapper）
# ---------------------------------------------------------------------------
# 跑法（headless 即可，無需 rendering）：
#   godot --headless --path . -s tools/ai_run.gd
#
# 參數透過環境變數：
#   AIRUN_PARTY=li_xiaoyao            # 逗號分隔角色 id（隊長在前），預設 li_xiaoyao
#   AIRUN_ASC=0                       # ascension 難度，預設 0
#   AIRUN_SEED=0                      # run seed，0=隨機
#   AIRUN_AUTO=0                      # 1=用內建啟發式 policy 自動跑完（不等檔案）
#   AIRUN_SESSION=                    # 多開時的 session 名（見下）。空=用 repo 根目錄 legacy 檔名
#
# 檔案協定（單開 / AIRUN_SESSION 為空時用 repo 根目錄 legacy 檔名）：
#   _ai_view.json — 本驅動器寫出，{ seq, kind, phase_label, run, state, options, [terminal,result] }
#   _ai_cmd.json  — 由我（agent）寫入，{ seq, choice }；choice 是給 engine.apply 的字串
#
# 多 agent 同時測試：每個 godot 程序帶不同 AIRUN_SESSION（如 A / li_s1 / 任意字串），
#   協定檔改放 res://_ai_runs/<session>/{view,cmd,result,transcript}.json，彼此不衝突。
#   搭配各自不同的 AIRUN_PARTY / AIRUN_SEED / AIRUN_ASC 即可平行跑多組組合。
#
# 流程：寫出 view（seq=N），等我寫 cmd（seq=N）→ 套用 → 推進 →
#       寫出新的 view（seq=N+1）。run 結束寫 result + transcript 後 quit。
#
# 看完自行刪除暫存檔（單開：_ai_*.json；多開：整個 _ai_runs/<session>/ 目錄）。
# ---------------------------------------------------------------------------

var VIEW_PATH := "res://_ai_view.json"
var CMD_PATH := "res://_ai_cmd.json"
var RESULT_PATH := "res://_ai_result.json"
var TRANSCRIPT_PATH := "res://_ai_transcript.json"

var _engine: AiRunEngine
var _seq: int = 0
var _auto: bool = false
var _done: bool = false
var _session: String = ""
# 混合委派：例行決策用內建啟發式自動跑、只把關鍵決策交給 agent，大幅減少 round-trip。
#   off    = 每個戰鬥回合都問 agent（原行為）
#   normal = 自動打非 boss 戰鬥，boss 戰 + 所有 meta 交給 agent（甜蜜點）
#   all    = 自動打所有戰鬥，agent 只決定 meta（最快，戰術失真換速度）
#   focus  = agent 只管「關鍵」決策：boss 戰 + 牌組變更（獎勵/加護/boss 遺物）+ 商店 + 奇遇；
#            雜兵戰 / 地圖 / 休息全自動。聚焦在「牌組構築 + 關鍵戰」，round-trip 最少。
var _auto_battle_mode: String = "off"
# focus 模式下交給啟發式自動的 view kind（battle_turn 另依 is_boss 判斷）
const FOCUS_AUTO_KINDS: Array = ["map", "rest"]
# agent 隨需委派：在某個 battle_turn 寫 choice="auto" → 該場剩餘回合自動打完
var _force_auto_this_battle: bool = false

# 倒帶重放（rewind）：auto 自動打導致全滅時，用同 seed 重建引擎、重放到「前 N 個 agent
# 決策點」再交還 agent。引擎是 seed 確定性的 → 重放完全重現原局面（抽牌/敵人行動一致），
# agent 靠重新決策（換牌/換路線/親自打）翻盤。倒帶後關閉自動戰鬥、agent 全程接手。
var _rewind_n: int = 3              # 倒回幾個 agent 決策點（AIRUN_REWIND；<=0 關閉此功能）
var _rewinds_done: int = 0
const MAX_REWINDS: int = 3          # 防呆：agent 重打也一直輸時的上限
var _history: Array = []           # 所有套用過的 choice 字串（agent + auto），依序，供重放
var _checkpoints: Array = []       # 每個 agent-surfaced 決策點當下的 _history.size()
# 重建用：記住 setup 參數與「實際採用」的 seed（原 seed=0 時引擎挑了 randi，必須沿用同值）
var _party: Array = []
var _asc: int = 0
var _resolved_seed: int = 0

# 每幕完成暫停（incremental reporting）：每跑完一幕就 surface 一個 act_complete view，
# 帶該 run 至今的 context + transcript，讓 agent 寫一份分析報告、再決定 continue / stop。
# 避免一口氣跑完 8 幕太久、想停就停。
var _act_pause: bool = true
var _acts_reported: int = 0        # 已出過報告的最高「完成幕」
var _awaiting_act_ack: bool = false  # 正等 agent 對 act_complete 回 continue/stop

func _initialize() -> void:
	_auto = OS.get_environment("AIRUN_AUTO") == "1"
	var abm: String = OS.get_environment("AIRUN_AUTO_BATTLE").strip_edges().to_lower()
	if abm in ["normal", "all", "focus"]:
		_auto_battle_mode = abm
	if OS.get_environment("AIRUN_REWIND").is_valid_int():
		_rewind_n = int(OS.get_environment("AIRUN_REWIND"))
	# 每幕完成暫停出報告（互動模式預設開；AIRUN_ACT_PAUSE=0 關閉）
	_act_pause = OS.get_environment("AIRUN_ACT_PAUSE") != "0" and not _auto
	_resolve_paths()
	var party_env: String = OS.get_environment("AIRUN_PARTY")
	if party_env.is_empty():
		party_env = "li_xiaoyao"
	var party: Array = []
	for id: String in party_env.split(",", false):
		party.append(id.strip_edges())
	var asc: int = int(OS.get_environment("AIRUN_ASC")) if OS.get_environment("AIRUN_ASC").is_valid_int() else 0
	var run_seed: int = int(OS.get_environment("AIRUN_SEED")) if OS.get_environment("AIRUN_SEED").is_valid_int() else 0

	# 清理舊協定檔
	for p: String in [VIEW_PATH, CMD_PATH, RESULT_PATH, TRANSCRIPT_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

	_engine = AiRunEngine.new()
	_engine.setup(party, asc, run_seed)
	# 記住重建參數；run_seed=0 時引擎挑了 randi，沿用其實際值才能重放重現
	_party = party.duplicate()
	_asc = asc
	_resolved_seed = _engine.run_state.map_seed
	print("[ai_run] session=%s party=%s asc=%d seed=%s auto=%s" % [
		(_session if not _session.is_empty() else "(root)"), str(party), asc, str(run_seed), str(_auto)])
	if not _session.is_empty():
		print("[ai_run] protocol dir: res://_ai_runs/%s/" % _session)

	if _auto:
		_run_auto()
		_finish_and_quit()
		quit(0)
		return

	_emit_next_view()
	await _poll_loop()
	quit(0)

# 依 AIRUN_SESSION 決定協定檔路徑。空 → repo 根 legacy 檔名（向後相容）；
# 非空 → res://_ai_runs/<session>/，各 session 互不干擾。
func _resolve_paths() -> void:
	_session = OS.get_environment("AIRUN_SESSION").strip_edges()
	if _session.is_empty():
		return  # 維持 legacy 根目錄檔名
	# 清理 session 名，只留檔名安全字元
	var safe: String = ""
	for c: String in _session:
		safe += c if (c.to_lower() != c.to_upper() or c.is_valid_int() or c == "_" or c == "-") else "_"
	_session = safe
	var dir_rel: String = "_ai_runs/%s" % _session
	var abs_dir: String = ProjectSettings.globalize_path("res://" + dir_rel)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var base: String = "res://%s/" % dir_rel
	VIEW_PATH = base + "view.json"
	CMD_PATH = base + "cmd.json"
	RESULT_PATH = base + "result.json"
	TRANSCRIPT_PATH = base + "transcript.json"

# 互動模式主迴圈：每幀輪詢 _ai_cmd.json，對上 seq 就套用、推進、寫新 view
func _poll_loop() -> void:
	var ticks_since_poll: int = 0
	while not _done:
		await process_frame
		# 約每 3 幀檢查一次檔案，降低 IO 壓力（headless 無 vsync）
		ticks_since_poll += 1
		if ticks_since_poll < 3:
			continue
		ticks_since_poll = 0
		if not FileAccess.file_exists(CMD_PATH):
			continue
		var txt: String = FileAccess.get_file_as_string(CMD_PATH)
		if txt.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(txt)
		if not (parsed is Dictionary):
			continue
		var cmd: Dictionary = parsed as Dictionary
		if int(cmd.get("seq", -1)) != _seq:
			continue  # 還沒對上當前 seq
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CMD_PATH))
		var choice_str: String = str(cmd.get("choice", "skip")).strip_edges()
		if _awaiting_act_ack:
			# 對 act_complete 暫停的回應：stop=提前結算、其餘=繼續下一幕
			_awaiting_act_ack = false
			if choice_str == "stop":
				print("[ai_run] agent 要求停止，提前結算（act %d）。" % _acts_reported)
				_engine.stop_early("agent_stopped_act_%d" % _acts_reported)
				_finish_and_quit()
			else:
				_emit_next_view()
		elif choice_str == "auto":
			# agent 隨需把這場戰鬥剩餘回合委派給啟發式打完
			_force_auto_this_battle = true
			_emit_next_view()
			_force_auto_this_battle = false
		else:
			_history.append(choice_str)
			_engine.apply(choice_str)
			_emit_next_view()

func _run_auto() -> void:
	var guard: int = 0
	while guard < 200000:
		guard += 1
		var view: Dictionary = _engine.next_view()
		if String(view.get("kind", "")) == "done":
			break
		var choice: String = AiRunEngine.auto_choice(view)
		_engine.apply(choice)

func _emit_next_view() -> void:
	# 剛跨入新一幕（agent 打完 boss 或 auto 推進）→ 先暫停出報告
	if _emit_act_report_if_boundary():
		return
	var view: Dictionary = _engine.next_view()
	# 混合委派：把不需要 agent 智慧的例行決策用啟發式自動跑掉，只在關鍵決策停下交給 agent。
	var auto_played: bool = false
	var auto_guard: int = 0
	while _should_auto_play(view) and auto_guard < 100000:
		auto_guard += 1
		var ac: String = AiRunEngine.auto_choice(view)
		_history.append(ac)
		auto_played = auto_played or String(view.get("kind", "")) == "battle_turn"
		_engine.apply(ac)
		# auto 自動推進跨入新一幕 → 暫停出報告（下次 continue 再續跑）
		if _emit_act_report_if_boundary():
			return
		view = _engine.next_view()
	if String(view.get("kind", "")) == "done":
		# auto 自動打導致全滅 → 倒帶交還 agent（而非直接判 run 失敗）
		if auto_played and not bool(_engine.result.get("victory", false)) \
				and _rewind_n > 0 and _rewinds_done < MAX_REWINDS:
			_rewind_and_handoff()
			return
		_finish_and_quit()
		return
	_seq += 1
	_checkpoints.append(_history.size())  # 此 agent 決策點對應的 history 長度（供倒帶定位）
	view["seq"] = _seq
	_write_json(VIEW_PATH, view)
	print("[ai_run] seq=%d kind=%s phase=%s" % [_seq, view.get("kind", "?"), view.get("phase_label", "")])

# 若剛完成一幕（run_state.act 已遞增到尚未出報告的幕之後），surface 一個 act_complete
# 暫停 view 給 agent（帶 context + transcript 供寫分析報告），回傳是否已 surface。
func _emit_act_report_if_boundary() -> bool:
	if not _act_pause or _awaiting_act_ack:
		return false
	var completed: int = _engine.run_state.act - 1  # act 從 1 起；推進到 N+1 表示第 N 幕完成
	if completed <= _acts_reported:
		return false
	_acts_reported = completed
	_awaiting_act_ack = true
	_seq += 1
	var report_view: Dictionary = {
		"seq": _seq,
		"kind": "act_complete",
		"phase_label": "第 %d 幕完成 — 暫停分析" % completed,
		"act_completed": completed,
		"run": _engine._run_context(),
		"transcript": _engine.transcript,
		"options": [
			{"id": "continue", "label": "繼續下一幕", "detail": "寫完報告後續跑"},
			{"id": "stop", "label": "停止並結算", "detail": "提前結束這個 run"}],
	}
	_write_json(VIEW_PATH, report_view)
	print("[ai_run] ACT %d COMPLETE — 暫停分析（回 continue 續跑 / stop 結算）" % completed)
	return true

# auto 戰敗 → 用同 seed 重建引擎、重放到「前 _rewind_n 個 agent 決策點」，交還 agent。
func _rewind_and_handoff() -> void:
	_rewinds_done += 1
	var cp_index: int = max(0, _checkpoints.size() - _rewind_n)
	var target_len: int = int(_checkpoints[cp_index]) if cp_index < _checkpoints.size() else 0
	var replay: Array = _history.slice(0, target_len)
	print("[ai_run] REWIND #%d：auto 戰敗，倒回 %d 個 agent 決策點（重放 %d/%d 個 choice）。auto 已關閉、交還 agent。" % [
		_rewinds_done, _checkpoints.size() - cp_index, target_len, _history.size()])
	# 同 seed 重建 → 完全重現；逐步 next_view→apply 重放（鏡像原驅動順序，確保 _ctx 被建好）
	_engine = AiRunEngine.new()
	_engine.setup(_party, _asc, _resolved_seed)
	for c_v: Variant in replay:
		var v: Dictionary = _engine.next_view()
		if String(v.get("kind", "")) == "done":
			break
		_engine.apply(c_v)
	_history = replay
	_checkpoints = _checkpoints.slice(0, cp_index)
	# 倒帶後關閉自動戰鬥：agent 全程接手（仍可逐場 choice="auto" 重新加速）
	_auto_battle_mode = "off"
	_force_auto_this_battle = false
	_emit_next_view()

# 是否該由啟發式自動跑這個決策點（而非交給 agent）。
func _should_auto_play(view: Dictionary) -> bool:
	var kind: String = String(view.get("kind", ""))
	if _force_auto_this_battle and kind == "battle_turn":
		return true
	match _auto_battle_mode:
		"all":
			return kind == "battle_turn"
		"normal":
			return kind == "battle_turn" and not bool(view.get("is_boss", false))
		"focus":
			# agent 只管 boss 戰 + 牌組變更 + 商店 + 奇遇；雜兵戰 / 地圖 / 休息自動
			if kind == "battle_turn":
				return not bool(view.get("is_boss", false))
			return kind in FOCUS_AUTO_KINDS
		_:
			return false

func _finish_and_quit() -> void:
	_write_json(RESULT_PATH, _engine.result)
	_write_json(TRANSCRIPT_PATH, {"transcript": _engine.transcript})
	# 清掉最後的 view（避免我誤讀舊決策）
	if FileAccess.file_exists(VIEW_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(VIEW_PATH))
	print("[ai_run] DONE victory=%s reason=%s act=%d floor=%d steps=%d" % [
		str(_engine.result.get("victory", false)), str(_engine.result.get("reason", "")),
		int(_engine.result.get("final_act", 0)), int(_engine.result.get("final_floor", 0)),
		int(_engine.result.get("steps", 0))])
	_done = true

func _write_json(path: String, data: Variant) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[ai_run] cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()
