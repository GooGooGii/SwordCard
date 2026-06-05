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
#
# 檔案協定（repo 根目錄）：
#   _ai_view.json — 本驅動器寫出，{ seq, kind, phase_label, run, state, options, [terminal,result] }
#   _ai_cmd.json  — 由我（agent）寫入，{ seq, choice }；choice 是給 engine.apply 的字串
#
# 流程：寫出 _ai_view.json（seq=N），等我寫 _ai_cmd.json（seq=N）→ 套用 → 推進 →
#       寫出新的 _ai_view.json（seq=N+1）。run 結束寫 _ai_result.json + _ai_transcript.json 後 quit。
#
# 看完自行刪除 _ai_*.json 暫存檔（同 render_effects.gd 的清理慣例）。
# ---------------------------------------------------------------------------

const VIEW_PATH := "res://_ai_view.json"
const CMD_PATH := "res://_ai_cmd.json"
const RESULT_PATH := "res://_ai_result.json"
const TRANSCRIPT_PATH := "res://_ai_transcript.json"

var _engine: AiRunEngine
var _seq: int = 0
var _auto: bool = false
var _done: bool = false

func _initialize() -> void:
	_auto = OS.get_environment("AIRUN_AUTO") == "1"
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
	print("[ai_run] party=%s asc=%d seed=%s auto=%s" % [str(party), asc, str(run_seed), str(_auto)])

	if _auto:
		_run_auto()
		_finish_and_quit()
		quit(0)
		return

	_emit_next_view()
	await _poll_loop()
	quit(0)

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
		_engine.apply(cmd.get("choice", "skip"))
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
	if String(view.get("kind", "")) == "done":
		_finish_and_quit()
		return
	_seq += 1
	view["seq"] = _seq
	_write_json(VIEW_PATH, view)
	print("[ai_run] seq=%d kind=%s phase=%s" % [_seq, view.get("kind", "?"), view.get("phase_label", "")])

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
