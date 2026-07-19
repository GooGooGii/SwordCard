class_name Ascension
extends RefCounted

# 難度層級（cumulative，對齊 Slay the Spire A1-A20）：
#   A1  精英出現更頻繁
#   A2  一般敵人更致命（傷害↑）
#   A3  精英更致命（傷害↑）
#   A4  Boss 更致命（傷害↑）
#   A5  Boss 戰後回血變少（missing HP 75%）
#   A6  開局即受傷（起始 HP -10%）
#   A7  一般敵人更強韌（HP↑）
#   A8  精英更強韌（HP↑）
#   A9  Boss 更強韌（HP↑）
#   A10 開局帶 1 張詛咒（業報）
#   A11 藥水格 -1
#   A12 獎勵升級卡出現率減半
#   A13 Boss 掉落銅錢 -25%
#   A14 最大 HP 額外 -5
#   A15 奇遇結果更糟
#   A16 商店漲價 +10%
#   A17 一般敵人招式更刁
#   A18 精英招式更刁
#   A19 Boss 招式更刁
#   A20 第三/最終幕 雙 Boss
# 每完成一級 boss → 解鎖下一級。
#
# tier 字串："normal" / "elite" / "boss"，給敵人相關 multiplier 區分等級。

const PATH: String = "user://progression.cfg"
const SECTION: String = "ascension"
const MAX_LEVEL: int = 20

const BOSS_IDS: Array[String] = ["moon_worshipper", "centipede_lord", "witch_queen", "red_eye_demon", "zombie_general", "ghost_general", "baiyue_lord"]

static func get_unlocked_max() -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return clampi(int(cfg.get_value(SECTION, "max_cleared", -1)) + 1, 0, MAX_LEVEL)

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

static func is_boss_id(enemy_id: String) -> bool:
	return enemy_id in BOSS_IDS or enemy_id in ["miao_chieftain", "tomb_general", "zhenyu_mingwang"]

# ── 敵人 HP（A7 一般 / A8 精英 / A9 Boss，各 ×1.25）──
static func enemy_hp_multiplier(level: int, is_boss: bool, is_elite: bool = false) -> float:
	var mult: float = 1.0
	if is_boss:
		if level >= 9:
			mult *= 1.25
	elif is_elite:
		if level >= 8:
			mult *= 1.25
	else:
		if level >= 7:
			mult *= 1.25
	return mult

# tier 版本（給新呼叫點用）
static func enemy_hp_multiplier_tier(level: int, tier: String) -> float:
	return enemy_hp_multiplier(level, tier == "boss", tier == "elite")

# ── 敵人傷害（A2 一般 / A3 精英 / A4 Boss，各 ×1.1）──
static func enemy_damage_multiplier(level: int, tier: String) -> float:
	var mult: float = 1.0
	match tier:
		"boss":
			if level >= 4:
				mult *= 1.1
		"elite":
			if level >= 3:
				mult *= 1.1
		_:
			if level >= 2:
				mult *= 1.1
	return mult

# ── A5：Boss 戰後回血變少（StS：missing HP 的 75%）──
static func boss_heal_multiplier(level: int) -> float:
	return 0.75 if level >= 5 else 1.0

# ── A6：開局即受傷（起始 HP -10%）──
static func starting_hp_multiplier(level: int) -> float:
	return 0.9 if level >= 6 else 1.0

# ── A10：開局帶 1 張詛咒 ──
static func starts_cursed(level: int) -> bool:
	return level >= 10

# ── A11：藥水格 -1 ──
static func potion_slot_penalty(level: int) -> int:
	return 1 if level >= 11 else 0

# ── A12：獎勵升級卡出現率（基礎 base，A12 起減半）──
static func reward_upgrade_chance(level: int, base: float) -> float:
	return base * 0.5 if level >= 12 else base

# ── A13：Boss 掉落銅錢 -25%（僅 boss）──
static func boss_gold_multiplier(level: int) -> float:
	return 0.75 if level >= 13 else 1.0

# ── A14：最大 HP 額外 -5（平鋪，套在 starting_hp_multiplier 之後）──
static func max_hp_flat_penalty(level: int) -> int:
	return 5 if level >= 14 else 0

# ── A15：奇遇結果更糟（增益 ×0.75、風險 ×1.25，由 event 結算讀取）──
static func event_reward_multiplier(level: int) -> float:
	return 0.75 if level >= 15 else 1.0

static func event_penalty_multiplier(level: int) -> float:
	return 1.25 if level >= 15 else 1.0

# ── A16：商店漲價 +10% ──
static func shop_price_multiplier(level: int) -> float:
	return 1.1 if level >= 16 else 1.0

# ── A17-19：招式更刁（一般/精英/Boss），由 next_enemy_action 讀取，傾向高傷招式 ──
static func harder_movesets(level: int, tier: String) -> bool:
	match tier:
		"boss":
			return level >= 19
		"elite":
			return level >= 18
		_:
			return level >= 17

# ── A1：精英出現更頻繁（給 map_generator 的額外權重）──
static func elite_frequency_bonus(level: int) -> int:
	return 1 if level >= 1 else 0

# ── A20：最終幕雙 Boss ──
static func double_boss(level: int) -> bool:
	return level >= 20

static func describe(level: int) -> String:
	if level <= 0:
		return "標準難度"
	var lines: Array[String] = []
	if level >= 1: lines.append("精英更常出現")
	if level >= 2: lines.append("一般敵傷害 +10%")
	if level >= 3: lines.append("精英傷害 +10%")
	if level >= 4: lines.append("Boss 傷害 +10%")
	if level >= 5: lines.append("Boss 戰後回血變少")
	if level >= 6: lines.append("起始 HP -10%")
	if level >= 7: lines.append("一般敵 HP +25%")
	if level >= 8: lines.append("精英 HP +25%")
	if level >= 9: lines.append("Boss HP +25%")
	if level >= 10: lines.append("開局帶 1 張詛咒")
	if level >= 11: lines.append("藥水格 -1")
	if level >= 12: lines.append("升級卡出現率減半")
	if level >= 13: lines.append("Boss 掉落銅錢 -25%")
	if level >= 14: lines.append("最大 HP -5")
	if level >= 15: lines.append("奇遇結果更糟")
	if level >= 16: lines.append("商店漲價 +10%")
	if level >= 17: lines.append("一般敵招式更刁")
	if level >= 18: lines.append("精英招式更刁")
	if level >= 19: lines.append("Boss 招式更刁")
	if level >= 20: lines.append("最終幕雙 Boss")
	return "、".join(lines)
