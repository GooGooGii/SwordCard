class_name LevelSystem
extends RefCounted

# 角色等級系統。
#
# Unlock 表按 PAL1 原作等級壓縮對應到 game Lv 3-22：
#   PAL1 Lv7  ≈ game Lv4
#   PAL1 Lv11 ≈ game Lv6
#   PAL1 Lv15 ≈ game Lv9
#   PAL1 Lv20 ≈ game Lv12
#   PAL1 Lv25 ≈ game Lv15
#   PAL1 Lv30 ≈ game Lv18
#   PAL1 Lv35 ≈ game Lv22
#
# 卡片 ID 與 game_data.gd 內既有的 ID 衝突時，level_system 這邊用 _ls 後綴避免重複。
# 之所以不直接 reference game_data 卡片是因為 unlock 卡的數值常與 reward pool 版本不同，
# 而且 GameData.make_card 重新建構不會有 by-ref 問題。

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

# 李逍遙：PAL1 招式按等級壓縮對應
static func _lxy_unlocks() -> Dictionary:
	return {
		# Lv4 (PAL1 Lv9) — 天罡戰氣：普通攻擊威力加倍（七回合）
		4: [
			GameData.make_card("lxy_tiangangqi", "天罡戰氣", "李逍遙", 1, "power",
				"PAL1 Lv9 招式。本場攻擊提升 2，獲得 4 點護體。",
				([{"kind": "power", "amount": 2}, {"kind": "block", "amount": 4}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv6 (PAL1 Lv11) — 凝神歸元：恢復 HP 220
		6: [
			GameData.make_card("lxy_ningyuan_ls", "凝神歸元", "李逍遙", 2, "skill",
				"PAL1 Lv11 內勁恢復術，回復 18 點生命並獲得 6 點護體。",
				([{"kind": "heal", "amount": 18}, {"kind": "block", "amount": 6}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv9 (PAL1 Lv17) — 元靈歸心術：恢復 HP 500
		9: [
			GameData.make_card("lxy_yuanlinggui", "元靈歸心術", "李逍遙", 2, "skill",
				"PAL1 Lv17 高階治療，回復 28 點生命。",
				([{"kind": "heal", "amount": 28}] as Array[Dictionary]),
				"rare"),
		],
		# Lv11 (PAL1 Lv20) — 真元護體：增防九回合
		11: [
			GameData.make_card("lxy_zhenyuan", "真元護體", "李逍遙", 1, "skill",
				"PAL1 Lv20 護體真氣，獲得 14 點護體，本場傷害提升 1。",
				([{"kind": "block", "amount": 14}, {"kind": "power", "amount": 1}] as Array[Dictionary]),
				"rare"),
		],
		# Lv13 (PAL1 Lv22) — 天劍：人劍合一攻擊
		13: [
			GameData.make_card("lxy_tianjian", "天劍", "李逍遙", 2, "attack",
				"PAL1 Lv22 自創劍意，人劍合一造成 22 點傷害。",
				([{"kind": "damage", "amount": 22}] as Array[Dictionary]),
				"rare"),
		],
		# Lv15 (PAL1 Lv26) — 金蟬脫殼：戰鬥中逃跑（卡牌化為「閃避+回手」）
		15: [
			GameData.make_card("lxy_jinchan_ls", "金蟬脫殼", "李逍遙", 1, "skill",
				"PAL1 Lv26 身法。獲得 12 點護體並抽 2 張牌。",
				([{"kind": "block", "amount": 12}, {"kind": "draw", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
		# Lv18 (PAL1 Lv30) — 逍遙神劍：自創絕招
		18: [
			GameData.make_card("lxy_xiaoyao_shenjian", "逍遙神劍", "李逍遙", 3, "attack",
				"PAL1 Lv30 自創絕招，造成 10 點傷害三次。",
				([{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}] as Array[Dictionary]),
				"rare"),
		],
		# Lv22 (PAL1 Lv34) — 劍神：召喚劍神施展萬劍齊飛
		22: [
			GameData.make_card("lxy_jianshen", "劍神", "李逍遙", 3, "attack",
				"PAL1 Lv34 召喚劍神，萬劍齊飛造成 32 點傷害並施加 2 層破綻。",
				([{"kind": "damage", "amount": 32}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
	}

# 趙靈兒：PAL1 仙術等級對應
static func _zl_unlocks() -> Dictionary:
	return {
		# Lv4 (PAL1 Lv7) — 旋風咒：風系全體攻擊
		4: [
			GameData.make_card("zl_xuanfengzhou", "旋風咒", "趙靈兒", 1, "attack",
				"PAL1 Lv7 風系中級。造成 8 點傷害並施加 2 層虛弱。",
				([{"kind": "damage", "amount": 8}, {"kind": "weak", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv6 (PAL1 Lv11) — 五雷咒：雷系中級
		6: [
			GameData.make_card("zl_wuleizhou", "五雷咒", "趙靈兒", 2, "attack",
				"PAL1 Lv11 雷系中級。造成 16 點傷害。",
				([{"kind": "damage", "amount": 16}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv7 (PAL1 Lv13) — 三昧真火：火系中級
		7: [
			GameData.make_card("zl_sanmeifire", "三昧真火", "趙靈兒", 2, "attack",
				"PAL1 Lv13 火系。造成 10 點傷害並施加 2 層破綻。",
				([{"kind": "damage", "amount": 10}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv10 (PAL1 Lv17) — 風雪冰天：冰系高級
		10: [
			GameData.make_card("zl_fengxuebing", "風雪冰天", "趙靈兒", 2, "attack",
				"PAL1 Lv17 冰系高級。造成 12 點傷害並施加 2 層虛弱。",
				([{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
		# Lv12 (PAL1 Lv20) — 地裂天崩：土系高級
		12: [
			GameData.make_card("zl_diliebeng", "地裂天崩", "趙靈兒", 3, "attack",
				"PAL1 Lv20 土系絕招。造成 20 點傷害並施加 3 層破綻。",
				([{"kind": "damage", "amount": 20}, {"kind": "vulnerable", "amount": 3}] as Array[Dictionary]),
				"rare"),
		],
		# Lv16 (PAL1 Lv24) — 泰山壓頂
		16: [
			GameData.make_card("zl_taishan", "泰山壓頂", "趙靈兒", 3, "attack",
				"PAL1 Lv24 土系絕招。造成 28 點傷害。",
				([{"kind": "damage", "amount": 28}] as Array[Dictionary]),
				"rare"),
		],
		# Lv18 (PAL1 Lv26) — 狂雷
		18: [
			GameData.make_card("zl_kuanglei", "狂雷", "趙靈兒", 3, "attack",
				"PAL1 Lv26 雷系絕招。造成 30 點傷害。",
				([{"kind": "damage", "amount": 30}] as Array[Dictionary]),
				"rare"),
		],
		# Lv22 (鎖妖塔變身 — act 4 對應 game Lv22) — 夢蛇
		22: [
			GameData.make_card("zl_mengshe_ls", "夢蛇", "趙靈兒", 2, "power",
				"PAL1 鎖妖塔變身。本場戰鬥傷害提升 3，並抽 1 張牌。",
				([{"kind": "power", "amount": 3}, {"kind": "draw", "amount": 1}] as Array[Dictionary]),
				"rare"),
		],
	}

# 林月如：鞭劍武學等級對應
static func _lyr_unlocks() -> Dictionary:
	return {
		# Lv5 (PAL1 Lv9) — 銅錢鏢：以金錢為暗器
		5: [
			GameData.make_card("lyr_tongqianbiao", "銅錢鏢", "林月如", 1, "attack",
				"PAL1 Lv9 暗器。造成 5 點傷害並施加 2 層破綻。",
				([{"kind": "damage", "amount": 5}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv7 (PAL1 Lv13) — 七訣劍氣：以指代劍裂地劍氣
		7: [
			GameData.make_card("lyr_qijuejianqi", "七訣劍氣", "林月如", 1, "attack",
				"PAL1 Lv13 以指代劍。造成 6 點傷害兩次。",
				([{"kind": "damage", "amount": 6}, {"kind": "damage", "amount": 6}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv9 (PAL1 Lv15) — 元靈歸心術：HP 500 治療
		9: [
			GameData.make_card("lyr_yuanlinggui", "元靈歸心術", "林月如", 2, "skill",
				"PAL1 Lv15 高階治療，回復 28 點生命。",
				([{"kind": "heal", "amount": 28}] as Array[Dictionary]),
				"rare"),
		],
		# Lv10 (PAL1 Lv16) — 乾坤一擲：金錢鏢全體
		10: [
			GameData.make_card("lyr_qiankun_ls", "乾坤一擲", "林月如", 0, "attack",
				"PAL1 Lv16 散財絕招。消耗全部靈力，每點造成 9 點傷害。",
				([{"kind": "consume_energy_damage", "amount": 9}] as Array[Dictionary]),
				"rare"),
		],
		# Lv12 (PAL1 Lv20) — 斬龍訣：氣勁橫掃
		12: [
			GameData.make_card("lyr_zhanlong_ls", "斬龍訣", "林月如", 3, "attack",
				"PAL1 Lv20 氣勁橫掃群魔，造成 30 點傷害。",
				([{"kind": "damage", "amount": 30}] as Array[Dictionary]),
				"rare"),
		],
		# Lv22 (PAL1 Lv35) — 萬里狂沙：林家獨門絕招
		22: [
			GameData.make_card("lyr_wanlikuang", "萬里狂沙", "林月如", 2, "skill",
				"PAL1 Lv35 林家獨門。施加 4 層虛弱、4 層破綻，抽 2 張牌。",
				([{"kind": "weak", "amount": 4}, {"kind": "vulnerable", "amount": 4}, {"kind": "draw", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
	}

# 阿奴：苗疆蠱術等級對應（她在 PAL1 是高等級加入，原作 Lv1 已有許多技能）
static func _anu_unlocks() -> Dictionary:
	return {
		# Lv4 — 三屍蠱（PAL1 初登場但效果偏強，當早期 unlock）
		4: [
			GameData.make_card("anu_sanshigu", "三屍蠱", "阿奴", 1, "skill",
				"PAL1 苗疆蠱術。施加 4 層蠱毒並使敵人虛弱 1 層。",
				([{"kind": "poison", "amount": 4}, {"kind": "weak", "amount": 1}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv6 — 炎殺咒（PAL1 初登場高級火系）
		6: [
			GameData.make_card("anu_yanshazhou", "炎殺咒", "阿奴", 2, "attack",
				"PAL1 高級火系咒術。造成 15 點傷害並施加 1 層破綻。",
				([{"kind": "damage", "amount": 15}, {"kind": "vulnerable", "amount": 1}] as Array[Dictionary]),
				"uncommon"),
		],
		# Lv9 — 贖魂（PAL1 初登場 復活 30%）
		9: [
			GameData.make_card("anu_shuhun", "贖魂", "阿奴", 2, "skill",
				"PAL1 苗疆復活術。救回 1 名倒下同伴（25 HP）；若無人倒下，自身回復 25 HP。",
				([{"kind": "revive", "amount": 25}] as Array[Dictionary]),
				"rare"),
		],
		# Lv12 — 奪魂（PAL1 初登場 機率秒殺 → 卡牌化為高傷害）
		12: [
			GameData.make_card("anu_duohun", "奪魂", "阿奴", 2, "attack",
				"PAL1 吸取魂魄。造成 18 點傷害並施加 3 層蠱毒。",
				([{"kind": "damage", "amount": 18}, {"kind": "poison", "amount": 3}] as Array[Dictionary]),
				"rare"),
		],
		# Lv18 (PAL1 Lv30) — 萬蟻蝕象
		18: [
			GameData.make_card("anu_wanyi_ls", "萬蟻蝕象", "阿奴", 2, "skill",
				"PAL1 Lv30 食人毒蟻。施加 10 層蠱毒。",
				([{"kind": "poison", "amount": 10}] as Array[Dictionary]),
				"rare"),
		],
		# Lv22 (PAL1 Lv35) — 萬蠱蝕天
		22: [
			GameData.make_card("anu_wangushitian", "萬蠱蝕天", "阿奴", 2, "skill",
				"PAL1 Lv35 放蠱攻擊。施加 8 層蠱毒並施加 2 層破綻。",
				([{"kind": "poison", "amount": 8}, {"kind": "vulnerable", "amount": 2}] as Array[Dictionary]),
				"rare"),
		],
	}
