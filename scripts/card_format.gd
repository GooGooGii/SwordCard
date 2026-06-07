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
	var has_status: bool = false   # 對玩家施加的負面狀態（毒/弱/破綻）
	var has_control: bool = false  # 控制（暈眩/禁言/瘋魔）
	var has_buff: bool = false     # 敵人自身強化（力量）
	var has_heal: bool = false     # 敵人自我治療
	var has_summon: bool = false   # 召喚
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		match kind:
			"damage", "damage_all":
				has_damage = true
			"block":
				has_block = true
			"poison", "weak", "vulnerable", "poison_all", "weak_all", "vulnerable_all":
				has_status = true
			"stun", "silence", "berserk":
				has_control = true
			"power":
				has_buff = true
			"heal", "heal_party":
				has_heal = true
			"summon":
				has_summon = true
	var badges: Array[String] = []
	if has_damage:
		badges.append("[攻擊]")
	if has_block:
		badges.append("[防守]")
	if has_control:
		badges.append("[控制]")
	if has_status:
		badges.append("[異常]")
	if has_buff:
		badges.append("[強化]")
	if has_heal:
		badges.append("[治療]")
	if has_summon:
		badges.append("[召喚]")
	if badges.is_empty():
		badges.append("[行動]")
	return " ".join(badges)

# 意圖圖示分類：回傳該 action 命中的 icon 類別 key（優先序），對應圖檔
# res://assets/ui/intent/<key>.png。main.gd 取前幾個顯示為 icon；圖未補時 fallback 文字。
const INTENT_ICON_DIR: String = "res://assets/ui/intent/"
static func intent_icon_names(action: Dictionary) -> Array[String]:
	var has_damage: bool = false
	var has_block: bool = false
	var has_status: bool = false
	var has_control: bool = false
	var has_buff: bool = false
	var has_heal: bool = false
	var has_summon: bool = false
	for effect: Dictionary in (action.get("effects", []) as Array):
		match String(effect.get("kind", "")):
			"damage", "damage_all":
				has_damage = true
			"block":
				has_block = true
			"poison", "weak", "vulnerable", "poison_all", "weak_all", "vulnerable_all":
				has_status = true
			"stun", "silence", "berserk":
				has_control = true
			"power":
				has_buff = true
			"heal", "heal_party":
				has_heal = true
			"summon":
				has_summon = true
	var keys: Array[String] = []
	if has_damage: keys.append("attack")
	if has_block: keys.append("defend")
	if has_control: keys.append("control")
	if has_status: keys.append("debuff")
	if has_buff: keys.append("buff")
	if has_heal: keys.append("heal")
	if has_summon: keys.append("summon")
	return keys

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
		var k: String = String(effect.get("kind", ""))
		if k == "damage" or k == "damage_all":
			return true
	return false

# 玩家手牌：哪些 effect kind 是「打到敵人身上」（drag 時需要丟到敵人附近才算）。
# 其餘的（block / heal / draw / energy / power / self_damage）視為非單體，丟到手牌以外
# 任何地方都算打出。
const ENEMY_TARGETED_KINDS: Array[String] = ["damage", "damage_all", "poison", "poison_all", "weak", "weak_all", "vulnerable", "vulnerable_all", "consume_energy_damage", "consume_energy_damage_all", "poison_burst", "damage_debuff_bonus", "stun", "silence", "berserk"]

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
# 回傳: {raw, blocked, dealt, hits, per_hit}。hits = 傷害段數（敵人多段攻擊以重複
# damage effect 表示）；per_hit = 各段「實際入手前」傷害（套 weak/vuln/減傷後），
# 各段不一致時為 -1。
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
	var hits: int = 0
	var per_hit: int = -2  # -2 = 未設；-1 = 各段不一致
	for effect: Dictionary in (action.get("effects", []) as Array):
		var k: String = String(effect.get("kind", ""))
		if k != "damage" and k != "damage_all":
			continue
		var amount: int = int(effect.get("amount", 0))
		var modified: int = max(0, amount - enemy_weak)
		if player_vuln_at_hit > 0:
			modified = int(ceil(modified * 1.5))
		modified = max(0, modified - damage_reduction)
		if per_hit == -2:
			per_hit = modified
		elif per_hit != modified:
			per_hit = -1
		var b: int = min(remaining_block, modified)
		remaining_block -= b
		raw += amount
		blocked += b
		dealt += modified - b
		hits += 1
	if per_hit == -2:
		per_hit = 0
	return {"raw": raw, "blocked": blocked, "dealt": dealt, "hits": hits, "per_hit": per_hit}

# 戰鬥手牌即時數值：把玩家卡片 effects 依當前 state（power / weak / vulnerable / 各種
# relic+potion bonus）算成「實際打出」的數字。與 EffectResolver._resolve_effect 的
# player（from_enemy=false）路徑保持同步。回傳 [{label, value, base, hits}]，只涵蓋
# 有數字意義的 kind；其餘（draw / energy / power / 狀態施加）不列。
static func live_effect_previews(card: CardData, state: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var power: int = int(state.get("player_power", 0))
	var weak: int = int(state.get("player_weak", 0))
	var dmg_bonus: int = int(state.get("damage_out_bonus", 0))
	var enemy_vuln: int = int(state.get("enemy_vulnerable", 0))
	for effect: Dictionary in card.effects:
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"damage", "damage_all":
				var hits: int = max(1, int(effect.get("hits", 1)))
				var modified: int = max(0, amount + power - weak) + dmg_bonus
				if enemy_vuln > 0:
					modified = int(ceil(modified * 1.5))
				out.append({"label": "傷害", "value": modified, "base": amount, "hits": hits})
			"damage_debuff_bonus":
				var bonus_per: int = int(effect.get("bonus_per_layer", 0))
				var layers: int = int(state.get("enemy_weak", 0)) + enemy_vuln
				var raw: int = amount + bonus_per * layers
				var modified: int = max(0, raw + power - weak) + dmg_bonus
				if enemy_vuln > 0:
					modified = int(ceil(modified * 1.5))
				out.append({"label": "傷害", "value": modified, "base": amount, "hits": 1})
			"consume_energy_damage", "consume_energy_damage_all":
				var spent: int = int(state.get("energy", 0))
				var d: int = max(0, amount * spent - weak)
				if enemy_vuln > 0:
					d = int(ceil(d * 1.5))
				out.append({"label": "傷害", "value": d, "base": amount, "hits": 1})
			"block":
				out.append({"label": "護體", "value": amount + int(state.get("block_bonus", 0)), "base": amount, "hits": 1})
			"heal", "heal_party":
				out.append({"label": "治療", "value": amount + int(state.get("heal_bonus", 0)), "base": amount, "hits": 1})
			"poison", "poison_all":
				out.append({"label": "蠱毒", "value": amount + int(state.get("poison_bonus", 0)), "base": amount, "hits": 1})
	return out

# 一行即時預覽字串，例如「傷害 12 / 護體 8」。無可顯示數值時回傳空字串。
static func live_preview_text(card: CardData, state: Dictionary) -> String:
	var parts: Array[String] = []
	for p: Dictionary in live_effect_previews(card, state):
		var v: int = int(p["value"])
		var hits: int = int(p["hits"])
		if hits > 1:
			parts.append("%s %d×%d" % [p["label"], v, hits])
		else:
			parts.append("%s %d" % [p["label"], v])
	return " / ".join(parts)

# 整體增減：>0 表示比卡面基礎值強（被增益）、<0 表示被削弱（虛弱等）、0 無變化。
static func live_preview_delta(card: CardData, state: Dictionary) -> int:
	var diff: int = 0
	for p: Dictionary in live_effect_previews(card, state):
		diff += (int(p["value"]) - int(p["base"])) * int(p["hits"])
	return diff
