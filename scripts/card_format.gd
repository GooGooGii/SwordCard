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
