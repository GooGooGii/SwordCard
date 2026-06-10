class_name RunHistory
extends RefCounted

# 征途錄（IMPROVEMENT_PLAN P2-6）：跨 run 持久化的戰績檔案。
# 獨立於 savegame.json（同 Bestiary 模式），abandon / 換存檔都不影響紀錄。
# 每筆 = 一輪結束（勝利通關或戰敗），上限 MAX_ENTRIES 筆、舊的滾掉。

const PATH: String = "user://history.cfg"
const SECTION: String = "runs"
const KEY: String = "entries"
const MAX_ENTRIES: int = 50

# entry 欄位：
#   ts: String（ISO 日期時間）
#   victory: bool
#   characters: Array[String]（隊伍角色 id，[0] 是隊長）
#   ascension: int
#   act: int / floor_index: int（到達進度；victory 時 act=8）
#   death_by: String（敗者填擊殺敵 id；勝利空字串）
#   deck_size: int / relic_count: int / gold: int
#   seed: int
static func record(entry: Dictionary) -> void:
	var entries: Array = load_all()
	entries.push_front(entry.duplicate(true))
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PATH)  # 不存在沒關係
	cfg.set_value(SECTION, KEY, entries)
	cfg.save(PATH)

# 由 RunState 組一筆 entry（victory / death_by 由呼叫端給）
static func entry_from_run(rs, victory: bool, death_by: String = "") -> Dictionary:
	var char_ids: Array = []
	var deck_size: int = 0
	if rs != null:
		for c in rs.characters:
			char_ids.append(c.id)
		for deck_v in rs.character_decks:
			deck_size += (deck_v as Array).size()
	return {
		"ts": Time.get_datetime_string_from_system(),
		"victory": victory,
		"characters": char_ids,
		"ascension": rs.ascension_level if rs != null else 0,
		"act": rs.act if rs != null else 0,
		"floor_index": rs.encounter_index if rs != null else 0,
		"death_by": death_by,
		"deck_size": deck_size,
		"relic_count": rs.relics.size() if rs != null else 0,
		"gold": rs.gold if rs != null else 0,
		"seed": rs.map_seed if rs != null else 0,
	}

static func load_all() -> Array:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return []
	var v: Variant = cfg.get_value(SECTION, KEY, [])
	return (v as Array) if v is Array else []

# 統計摘要：總場數 / 勝場 / 最高過關 A 層（給主選單征途錄頁首）
static func summary() -> Dictionary:
	var entries: Array = load_all()
	var wins: int = 0
	var best_asc: int = -1
	for e_v: Variant in entries:
		var e: Dictionary = e_v as Dictionary
		if bool(e.get("victory", false)):
			wins += 1
			best_asc = max(best_asc, int(e.get("ascension", 0)))
	return {"total": entries.size(), "wins": wins, "best_victory_ascension": best_asc}

static func clear_all() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("history.cfg")
