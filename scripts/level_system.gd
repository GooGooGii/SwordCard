class_name LevelSystem
extends RefCounted

const MAX_LEVEL: int = 50

static func exp_to_next_level(current_level: int) -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return 15 * current_level

static func level_from_exp(total_exp: int) -> int:
	var level: int = 1
	var accumulated: int = 0
	while level < MAX_LEVEL:
		var needed: int = exp_to_next_level(level)
		if needed == 0 or accumulated + needed > total_exp:
			break
		accumulated += needed
		level += 1
	return level

static func exp_remainder(total_exp: int) -> int:
	var accumulated: int = 0
	var level: int = 1
	while level < MAX_LEVEL:
		var needed: int = exp_to_next_level(level)
		if needed == 0 or accumulated + needed > total_exp:
			break
		accumulated += needed
		level += 1
	return total_exp - accumulated

static func battle_exp(is_boss: bool, floor_index: int) -> int:
	if is_boss:
		return 150
	return 30 + floor_index * 5

# 傳回角色在 level 這個等級「剛升到」時解鎖的卡片（可能為空）
static func unlock_cards_for(character_id: String, level: int) -> Array[CardData]:
	var table: Dictionary = _build_table()
	if not table.has(character_id):
		return []
	var char_table: Dictionary = table[character_id] as Dictionary
	if not char_table.has(level):
		return []
	var result: Array[CardData] = []
	for c: Variant in (char_table[level] as Array):
		result.append(c as CardData)
	return result

# 傳回角色 level <= max_level 的全部解鎖卡片（reward pool 用）
static func all_unlocked_cards(character_id: String, max_level: int) -> Array[CardData]:
	var result: Array[CardData] = []
	var table: Dictionary = _build_table()
	if not table.has(character_id):
		return result
	var char_table: Dictionary = table[character_id] as Dictionary
	for lv_v: Variant in char_table.keys():
		if int(lv_v) <= max_level:
			for c: Variant in (char_table[lv_v] as Array):
				result.append(c as CardData)
	return result

static func _build_table() -> Dictionary:
	return {
		"li_xiaoyao": _lxy_unlocks(),
		"zhao_linger": _zl_unlocks(),
		"lin_yueru": _lyr_unlocks(),
		"anu": _anu_unlocks(),
	}

static func _lxy_unlocks() -> Dictionary:
	return {
		3: [
			GameData.make_card("lxy_tiangangqi", "天罡戰氣", "李逍遙", 1, "skill",
				"施加 2 層虛弱，抽 1 張牌。",
				([{"kind": "weak", "amount": 2}, {"kind": "draw", "amount": 1}] as Array[Dictionary]),
				"uncommon"),
		],
		6: [
			GameData.make_card("lxy_ningyuan", "凝神歸元", "李逍遙", 2, "skill",
				"回復 14 點生命，獲得 6 點護體。",
				([{"kind": "heal", "amount": 14}, {"kind": "block", "amount": 6}] as Array[Dictionary]),
				"uncommon"),
		],
		10: [
			GameData.make_card("lxy_huyuan", "護元真氣", "李逍遙", 1, "skill",
				"獲得 14 點護體，本場傷害提升 1。",
				([{"kind": "block", "amount": 14}, {"kind": "power", "amount": 1}] as Array[Dictionary]),
				"rare"),
		],
		15: [
			GameData.make_card("lxy_tianjian", "天劍", "李逍遙", 2, "attack",
				"造成 22 點傷害。",
				([{"kind": "damage", "amount": 22}] as Array[Dictionary]),
				"rare"),
		],
		20: [
			GameData.make_card("lxy_xiaoyaoshen", "逍遙神劍", "李逍遙", 3, "attack",
				"御劍飛旋，造成 8 點傷害三次。",
				([{"kind": "damage", "amount": 8}, {"kind": "damage", "amount": 8}, {"kind": "damage", "amount": 8}] as Array[Dictionary]),
				"rare"),
		],
	}

static func _zl_unlocks() -> Dictionary:
	return {
		3: [
			GameData.make_card("zl_xuanfengzhou", "旋風咒", "趙靈兒", 1, "attack",
				"造成 8 點傷害，施加 2 層虛弱。",
				([{"kind": "damage", "amount": 8}, {"kind": "weak", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		6: [
			GameData.make_card("zl_wuleizhou", "五雷咒", "趙靈兒", 2, "attack",
				"雷霆齊落，造成 16 點傷害。",
				([{"kind": "damage", "amount": 16}] as Array[Dictionary]),
				"uncommon"),
		],
		10: [
			GameData.make_card("zl_sanmeifire", "三昧真火", "趙靈兒", 2, "attack",
				"造成 10 點傷害，施加 2 層破綻。",
				([{"kind": "damage", "amount": 10}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		15: [
			GameData.make_card("zl_fengxuebing", "風雪冰天", "趙靈兒", 2, "attack",
				"造成 12 點傷害，施加 2 層虛弱。",
				([{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
		20: [
			GameData.make_card("zl_diliebeng", "地裂天崩", "趙靈兒", 3, "attack",
				"大地崩裂，造成 20 點傷害，施加 3 層破綻。",
				([{"kind": "damage", "amount": 20}, {"kind": "vulnerable", "amount": 3}] as Array[Dictionary]),
				"rare"),
		],
	}

static func _lyr_unlocks() -> Dictionary:
	return {
		3: [
			GameData.make_card("lyr_qijuejianqi", "七絕劍氣", "林月如", 1, "attack",
				"造成 6 點傷害兩次。",
				([{"kind": "damage", "amount": 6}, {"kind": "damage", "amount": 6}] as Array[Dictionary]),
				"common"),
		],
		6: [
			GameData.make_card("lyr_tongqianbiao", "銅錢鏢", "林月如", 1, "attack",
				"擲出銅錢，造成 5 點傷害，施加 2 層破綻。",
				([{"kind": "damage", "amount": 5}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		10: [
			GameData.make_card("lyr_xianyue", "弦月斬", "林月如", 2, "attack",
				"造成 14 點傷害，獲得 8 點護體。",
				([{"kind": "damage", "amount": 14}, {"kind": "block", "amount": 8}] as Array[Dictionary]),
				"uncommon"),
		],
		15: [
			GameData.make_card("lyr_wanlikuang", "萬里狂沙", "林月如", 2, "skill",
				"施加 3 層虛弱，抽 2 張牌。",
				([{"kind": "weak", "amount": 3}, {"kind": "draw", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
		20: [
			GameData.make_card("lyr_longhuzhen", "龍虎震天", "林月如", 3, "attack",
				"造成 28 點傷害。",
				([{"kind": "damage", "amount": 28}] as Array[Dictionary]),
				"rare"),
		],
	}

static func _anu_unlocks() -> Dictionary:
	return {
		3: [
			GameData.make_card("anu_sanshigu", "三尸蠱", "阿奴", 1, "skill",
				"施加 4 層蠱毒，使敵人虛弱 1 層。",
				([{"kind": "poison", "amount": 4}, {"kind": "weak", "amount": 1}] as Array[Dictionary]),
				"uncommon"),
		],
		6: [
			GameData.make_card("anu_hunqian", "魂牽蠱", "阿奴", 1, "skill",
				"施加 5 層蠱毒，抽 1 張牌。",
				([{"kind": "poison", "amount": 5}, {"kind": "draw", "amount": 1}] as Array[Dictionary]),
				"uncommon"),
		],
		10: [
			GameData.make_card("anu_wangushitian", "萬蠱蝕天", "阿奴", 2, "skill",
				"施加 8 層蠱毒，施加 2 層破綻。",
				([{"kind": "poison", "amount": 8}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
		15: [
			GameData.make_card("anu_guchan", "蠱嬋殺陣", "阿奴", 1, "attack",
				"造成 6 點傷害，施加 3 層蠱毒。",
				([{"kind": "damage", "amount": 6}, {"kind": "poison", "amount": 3}] as Array[Dictionary]),
				"uncommon"),
		],
		20: [
			GameData.make_card("anu_gushenjiang", "蠱神降世", "阿奴", 2, "power",
				"本場傷害提升 3，施加 6 層蠱毒。",
				([{"kind": "power", "amount": 3}, {"kind": "poison", "amount": 6}] as Array[Dictionary]),
				"rare"),
		],
	}
