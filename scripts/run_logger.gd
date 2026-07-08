class_name RunLogger
extends RefCounted
#
# 逐事件 run 記錄器（JSONL，一行一事件），供試玩後多面向分析。
# ---------------------------------------------------------------------------
# 設計：
#   - **只在電腦寫檔**：`OS.has_feature("mobile")` 為真時整個停用（no-op），手機版不寫。
#   - 未呼叫 start() 前一律 no-op → smoke test / 一般模擬不受影響、零負擔。
#   - 全靜態狀態、單一 process 內共用；BattleController（戰鬥效果）與 AiRunEngine / main.gd
#     （meta 決策）都寫同一個檔，串成完整一局。
#   - 每行 JSON：{seq, cat, ev, ...data}。cat ∈ {"run","meta","battle"}。
#   - flush per line → 中途崩潰也讀得到已寫部分。
#
# 分析用法（試玩後）：直接 Read 檔、或 jq/python 依 cat/ev 切面向：
#   - 出牌效率：filter ev=="play_card" → 每張牌 total_dmg / cost
#   - 每回合節奏：group by turn
#   - 敵人壓力：ev=="enemy_action" 的 player_hp_delta
#   - meta 取捨：cat=="meta"（reward/shop/event/map/rest）
# ---------------------------------------------------------------------------

static var _file: FileAccess = null
static var _active: bool = false
static var _seq: int = 0
static var _path: String = ""

static func is_active() -> bool:
	return _active

static func log_path() -> String:
	return _path

# 開始記錄。path 空 → user://run_logs/run_<seed>.jsonl（一般遊戲）；
# 測試驅動器可傳 res:// 路徑（如 "res://_run_log.jsonl"）方便直接讀。
static func start(meta: Dictionary, path: String = "") -> void:
	stop()
	if OS.has_feature("mobile"):
		return  # 手機版不寫 log
	var p: String = path
	if p.is_empty():
		var dir: String = "user://run_logs"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		p = "%s/run_%s.jsonl" % [dir, str(meta.get("seed", "run"))]
	_file = FileAccess.open(p, FileAccess.WRITE)
	if _file == null:
		push_warning("[RunLogger] cannot open %s" % p)
		return
	_active = true
	_seq = 0
	_path = p
	log_event("run", "run_start", meta)

static func log_event(category: String, event: String, data: Dictionary = {}) -> void:
	if not _active or _file == null:
		return
	_seq += 1
	var rec: Dictionary = {"seq": _seq, "cat": category, "ev": event}
	for k: Variant in data:
		rec[k] = data[k]
	_file.store_line(JSON.stringify(rec))
	_file.flush()

static func finish(result: Dictionary = {}) -> void:
	if _active:
		log_event("run", "run_end", result)
	stop()

static func stop() -> void:
	if _file != null:
		_file.close()
		_file = null
	_active = false
	_seq = 0
