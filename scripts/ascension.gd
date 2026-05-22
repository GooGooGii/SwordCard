class_name Ascension
extends RefCounted

# 難度層級（cumulative）：
#   A0  標準
#   A1  一般敵人 HP +20%
#   A2  加 boss HP +20%
#   A3  加 起始 HP -15%
#   A4  加 戰勝銅錢 -25%
# 每完成一級 boss → 解鎖下一級。

const PATH: String = "user://progression.cfg"
const SECTION: String = "ascension"
const MAX_LEVEL: int = 4

const BOSS_IDS: Array[String] = ["moon_worshipper", "centipede_lord", "witch_queen", "red_eye_demon", "zombie_general", "baiyue_lord"]

static func get_unlocked_max() -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return int(cfg.get_value(SECTION, "max_cleared", -1)) + 1

static func mark_cleared(level: int) -> void:
	if level < 0:
		return
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PATH)
	var current: int = int(cfg.get_value(SECTION, "max_cleared", -1))
	if level > current:
		cfg.set_value(SECTION, "max_cleared", level)
		cfg.save(PATH)

static func clear_all() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("progression.cfg")

static func enemy_hp_multiplier(level: int, is_boss: bool) -> float:
	var mult: float = 1.0
	if level >= 1 and not is_boss:
		mult *= 1.2
	if level >= 2 and is_boss:
		mult *= 1.2
	return mult

static func starting_hp_multiplier(level: int) -> float:
	return 0.85 if level >= 3 else 1.0

static func gold_multiplier(level: int) -> float:
	return 0.75 if level >= 4 else 1.0

static func is_boss_id(enemy_id: String) -> bool:
	return enemy_id in BOSS_IDS

static func describe(level: int) -> String:
	if level <= 0:
		return "標準難度"
	var lines: Array[String] = []
	if level >= 1:
		lines.append("一般敵人 HP +20%")
	if level >= 2:
		lines.append("Boss HP +20%")
	if level >= 3:
		lines.append("起始 HP -15%")
	if level >= 4:
		lines.append("戰勝銅錢 -25%")
	return "、".join(lines)
