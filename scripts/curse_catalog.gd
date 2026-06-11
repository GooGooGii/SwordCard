class_name CurseCatalog
extends RefCounted

# 詛咒牌目錄（Event Branching Phase 4）
#
# Curse 是 card_type="curse" 的特殊卡：
#   - 不可主動打（BattleController.play_card 直接拒）
#   - 不可移除（標準 remove 流程跳過；只有 jing_hua_fu 遺物 / zhao_linger 專屬事件 /
#     未來的黑市驅邪服務可清除）
#   - 不可升級（_upgradeable_cards 過濾掉）
#   - 滯留效果：依 retention.trigger 在對應時機觸發（BattleController._apply_curse_retention）
#
# 玩家獲得 curse 是經由 event tree outcome 的 `{kind:"gain_curse", curse_id:"..."}`
# effect，由 main.gd._resolve_observe_effects 處理 → 從目錄取出 → make_card() →
# 加入該角色的 deck。

const CURSE_COST: int = 99  # 不可能負擔的高 cost（雙保險：play_card 拒絕 + 視覺暗示）

static func all() -> Array[Dictionary]:
	return [
		{
			"id": "yao_zhai",
			"display_name": "妖債",
			"description": "妖契留下的索命債。回合開始時 -2 點生命。",
			"retention": {"trigger": "turn_start", "effects": [{"kind": "damage_self", "amount": 2}]},
		},
		{
			"id": "xie_yin",
			"display_name": "邪印",
			"description": "拜月邪印纏身，凡俗手段無法抹去。回合開始時 +1 虛弱。",
			"retention": {"trigger": "turn_start", "effects": [{"kind": "weak_self", "amount": 1}]},
			"removable": false,  # 不可去除型（拜月神符之印、纏身難消）
		},
		{
			"id": "tong_ji",
			"display_name": "通緝",
			"description": "官府通緝在身。商店所有物品價格 +20%（每張疊加）。",
			"retention": {"trigger": "shop", "effects": [{"kind": "shop_surcharge", "amount": 20}]},
		},
		{
			"id": "hua_zhai",
			"display_name": "花債",
			"description": "花妖留下的咒。回合開始時 +1 破綻。",
			"retention": {"trigger": "turn_start", "effects": [{"kind": "vulnerable_self", "amount": 1}]},
		},
		{
			"id": "jiu_zui",
			"display_name": "醉魂",
			"description": "醉劍仙的酒未散。回合開始時 50% 機率 -1 靈力。",
			"retention": {"trigger": "turn_start", "effects": [{"kind": "energy_drain_chance", "amount": 1, "chance": 0.5}]},
		},
		{
			"id": "gu_du",
			"display_name": "殘蠱",
			"description": "苗疆殘蠱入骨，難以剔除。戰鬥開始時 +2 蠱毒。",
			"retention": {"trigger": "battle_start", "effects": [{"kind": "poison_self", "amount": 2}]},
			"removable": false,  # 不可去除型（黑苗戰鎧之蠱、入骨難除）
		},
	]

static func by_id(curse_id: String) -> Dictionary:
	for c: Dictionary in all():
		if c["id"] == curse_id:
			return c
	return {}

# 此詛咒是否可被去除（商店削牌服務 / 移除類效果）。預設可去除；
# 標記 "removable": false 的為「不可去除型」（邪印 / 殘蠱）。
static func is_removable(card: CardData) -> bool:
	if not is_curse(card):
		return true  # 非詛咒卡走原本移除規則，不受此限
	var data: Dictionary = by_id(card.id)
	return bool(data.get("removable", true))

# 把 curse dict 轉成 CardData（card_type="curse"），可加入 deck
static func make_card(curse_id: String) -> CardData:
	var data: Dictionary = by_id(curse_id)
	if data.is_empty():
		# silent — 呼叫方應自己處理 null（test 也驗證了這個情形）
		return null
	# Curse 沒有 effects（不可打）；retention 由 BattleController 自己讀目錄
	var card: CardData = GameData.make_card(
		String(data["id"]),
		String(data["display_name"]),
		"X",
		CURSE_COST,
		"curse",
		String(data["description"]),
		[] as Array[Dictionary]
	)
	return card

# 是否為 curse 牌（給呼叫方判斷 deck 內的卡）
static func is_curse(card: CardData) -> bool:
	return card != null and card.card_type == "curse"

# 取一張 curse 的 retention 規格。沒設 retention → 回傳空 dict。
static func retention_for(card: CardData) -> Dictionary:
	if not is_curse(card):
		return {}
	var data: Dictionary = by_id(card.id)
	if data.is_empty():
		return {}
	return data.get("retention", {}) as Dictionary
