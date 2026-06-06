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
# 混合委派：例行戰鬥用內建啟發式自動打、只把 meta 決策與 boss 戰交給 agent，大幅減少 round-trip。
#   off    = 每個戰鬥回合都問 agent（原行為）
#   normal = 自動打非 boss 戰鬥，boss 戰仍交給 agent（預設甜蜜點）
#   all    = 自動打所有戰鬥，agent 只決定 meta（最快，戰術失真換速度）
var _auto_battle_mode: String = "off"
# agent 隨需委派：在某個 battle_turn 寫 choice="auto" → 該場剩餘回合自動打完
var _force_auto_this_battle: bool = false

func _initialize() -> void:
	_auto = OS.get_environment("AIRUN_AUTO") == "1"
	var abm: String = OS.get_environment("AIRUN_AUTO_BATTLE").strip_edges().to_lower()
	if abm in ["normal", "all"]:
		_auto_battle_mode = abm
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
		if choice_str == "auto":
			# agent 隨需把這場戰鬥剩餘回合委派給啟發式打完
			_force_auto_this_battle = true
			_emit_next_view()
			_force_auto_this_battle = false
		else:
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
	var view: Dictionary = _engine.next_view()
	# 混合委派：把不需要 agent 智慧的例行戰鬥回合用啟發式自動打掉，只在 meta 決策 /
	# boss 戰停下交給 agent。一場雜兵戰可省下 20-40 次 round-trip。
	var auto_guard: int = 0
	while _should_auto_play(view) and auto_guard < 100000:
		auto_guard += 1
		_engine.apply(AiRunEngine.auto_choice(view))
		view = _engine.next_view()
	if String(view.get("kind", "")) == "done":
		_finish_and_quit()
		return
	_seq += 1
	view["seq"] = _seq
	_write_json(VIEW_PATH, view)
	print("[ai_run] seq=%d kind=%s phase=%s" % [_seq, view.get("kind", "?"), view.get("phase_label", "")])

# 是否該由啟發式自動打這個戰鬥回合（而非交給 agent）。
func _should_auto_play(view: Dictionary) -> bool:
	if String(view.get("kind", "")) != "battle_turn":
		return false
	if _force_auto_this_battle:
		return true
	match _auto_battle_mode:
		"all": return true
		"normal": return not bool(view.get("is_boss", false))
		_: return false

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
