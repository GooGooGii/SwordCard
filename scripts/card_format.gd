class_name CardFormat
extends RefCounted

static func card_type_name(card_type: String) -> String:
	match card_type:
		"attack":
			return "攻擊"
		"skill":
			return "技能"
		"power":
			return "能力"
	return card_type

static func card_color(card_type: String, affordable: bool) -> Color:
	if not affordable:
		return Color("5f6673")
	match card_type:
		"attack":
			return Color("8f3f35")
		"skill":
			return Color("2f6f61")
		"power":
			return Color("7756a8")
	return Color("4f5f73")

static func card_rarity_name(card: CardData) -> String:
	if card.upgraded:
		return "升"
	match card.rarity:
		"rare":
			return "稀"
		"uncommon":
			return "良"
	return "基"

static func card_rarity_color(card: CardData) -> Color:
	if card.upgraded:
		return ThemeColors.ACCENT_GOLD
	match card.rarity:
		"rare":
			return Color("d9c2ff")
		"uncommon":
			return Color("b9ead6")
	return Color("c7d2e3")

static func intent_badge(action: Dictionary) -> String:
	var effects: Array = action.get("effects", []) as Array
	var has_damage: bool = false
	var has_block: bool = false
	var has_status: bool = false
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		if kind == "damage":
			has_damage = true
		elif kind == "block":
			has_block = true
		elif kind == "poison" or kind == "weak" or kind == "vulnerable":
			has_status = true
	var badges: Array[String] = []
	if has_damage:
		badges.append("[攻擊]")
	if has_block:
		badges.append("[防守]")
	if has_status:
		badges.append("[異常]")
	if badges.is_empty():
		badges.append("[行動]")
	return " ".join(badges)

static func enemy_action_effect_summary(action: Dictionary) -> String:
	var effects: Array = action.get("effects", []) as Array
	var parts: Array[String] = []
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"damage":
				parts.append("傷害 %d" % amount)
			"block":
				parts.append("護體 +%d" % amount)
			"poison":
				parts.append("蠱毒 +%d" % amount)
			"weak":
				parts.append("虛弱 +%d" % amount)
			"vulnerable":
				parts.append("破綻 +%d" % amount)
			"heal":
				parts.append("治療 +%d" % amount)
			_:
				if amount > 0:
					parts.append("%s %d" % [kind, amount])
	if parts.is_empty():
		return ""
	return " / ".join(parts)

static func action_has_damage(action: Dictionary) -> bool:
	for effect: Dictionary in (action.get("effects", []) as Array):
		if String(effect.get("kind", "")) == "damage":
			return true
	return false

# 玩家手牌：哪些 effect kind 是「打到敵人身上」（drag 時需要丟到敵人附近才算）。
# 其餘的（block / heal / draw / energy / power / self_damage）視為非單體，丟到手牌以外
# 任何地方都算打出。
const ENEMY_TARGETED_KINDS: Array[String] = ["damage", "damage_all", "poison", "poison_all", "weak", "weak_all", "vulnerable", "vulnerable_all", "consume_energy_damage", "poison_burst", "damage_debuff_bonus"]

# 全體牌：含 AoE effect，不需要鎖定特定敵人目標
static func is_aoe_card(card: CardData) -> bool:
	for effect: Dictionary in card.effects:
		if String(effect.get("kind", "")) in AOE_KINDS:
			return true
	return false

# 單體牌：需要拖曳到敵人肖像附近才算打出（含 steal，但 AoE 不算）
static func requires_enemy_target(card: CardData) -> bool:
	# 能力牌（card_type=="power"）一律對自己：power 增益本就 self，混的 debuff
	# 自動套到 active 敵，玩家不該被迫拖到敵將才能啟動「自我強化」。
	if card.card_type == "power":
		return false
	for effect: Dictionary in card.effects:
		if String(effect.get("kind", "")) in ENEMY_TARGETED_KINDS:
			return true
	return false

# 預測敵人 action 結算後玩家會受到的實際傷害。
# 與 EffectResolver._resolve_effect 的「from_enemy=true、damage」分支保持同步。
# 回傳: {raw, blocked, dealt} 三個 int。
# 注意：begin_enemy_phase 會在敵人攻擊前先把 player_weak / player_vulnerable -1，
# 所以這裡使用 max(0, value-1) 模擬。state 中的 enemy_weak 維持原值不變。
static func predict_enemy_damage(action: Dictionary, state: Dictionary) -> Dictionary:
	var enemy_weak: int = int(state.get("enemy_weak", 0))
	var player_vuln_at_hit: int = max(0, int(state.get("player_vulnerable", 0)) - 1)
	var damage_reduction: int = int(state.get("damage_taken_reduction", 0))
	var remaining_block: int = int(state.get("player_block", 0))
	var raw: int = 0
	var blocked: int = 0
	var dealt: int = 0
	for effect: Dictionary in (action.get("effects", []) as Array):
		if String(effect.get("kind", "")) != "damage":
			continue
		var amount: int = int(effect.get("amount", 0))
		var modified: int = max(0, amount - enemy_weak)
		if player_vuln_at_hit > 0:
			modified = int(ceil(modified * 1.5))
		modified = max(0, modified - damage_reduction)
		var b: int = min(remaining_block, modified)
		remaining_block -= b
		raw += amount
		blocked += b
		dealt += modified - b
	return {"raw": raw, "blocked": blocked, "dealt": dealt}
