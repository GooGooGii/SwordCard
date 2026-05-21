class_name Bestiary
extends RefCounted

# 跨 run 持久化的圖鑑紀錄。獨立於 savegame.json 之外，所以
# 即使玩家 abandon 一次冒險，已擊敗紀錄仍保留。

const PATH: String = "user://bestiary.cfg"
const SECTION: String = "defeated"

static func mark_defeated(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PATH)  # 不存在沒關係，cfg 視為空
	var current: int = int(cfg.get_value(SECTION, enemy_id, 0))
	cfg.set_value(SECTION, enemy_id, current + 1)
	cfg.save(PATH)

static func kill_count(enemy_id: String) -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return int(cfg.get_value(SECTION, enemy_id, 0))

static func is_defeated(enemy_id: String) -> bool:
	return kill_count(enemy_id) > 0

static func load_all() -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return {}
	var out: Dictionary = {}
	if not cfg.has_section(SECTION):
		return out
	for key: String in cfg.get_section_keys(SECTION):
		out[key] = int(cfg.get_value(SECTION, key, 0))
	return out

static func clear_all() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("bestiary.cfg")
