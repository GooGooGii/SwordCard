class_name GameData
extends RefCounted

# ──────────────────────────────────────────────
#  Equipment factory
# ──────────────────────────────────────────────

static func make_equip(id: String, display_name: String, slot: String, description: String, effects: Array[Dictionary], rarity: String = "common", price: int = 100, owner: String = "") -> EquipmentData:
	var e: EquipmentData = EquipmentData.new()
	e.id = id
	e.display_name = display_name
	e.slot = slot
	e.description = description
	e.effects = effects
	e.rarity = rarity
	e.price = price
	e.owner = owner
	return e

static func all_equipment() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	result.append_array(_armor_equipment())
	result.append_array(_accessory_equipment())
	return result

static func character_weapons() -> Array[EquipmentData]:
	return [_lxy_weapon(), _zl_weapon(), _lyr_weapon(), _anu_weapon()]

static func artifacts() -> Array[EquipmentData]:
	return [_xuanyuan_sword(), _pangu_axe(), _shennong_cauldron(), _fuxi_qin(), _nvwa_stone()]

# ── 防具 15 件 ──

static func _armor_equipment() -> Array[EquipmentData]:
	return [
		make_equip("white_deer_armor", "白鹿皮甲", "armor", "每回合開始獲得 3 護體。",
			[{"trigger":"turn_start","kind":"block","amount":3}], "common", 80),
		make_equip("xuantie_mirror", "玄鐵護心鏡", "armor", "戰鬥開始獲得 10 護體。",
			[{"trigger":"battle_start","kind":"block","amount":10}], "common", 80),
		make_equip("silkworm_robe", "蠶絲長袍", "armor", "最大生命 +10。",
			[{"trigger":"passive","kind":"max_hp","amount":10}], "common", 80),
		make_equip("jade_armor", "玉璧護甲", "armor", "每回合開始獲得 5 護體。",
			[{"trigger":"turn_start","kind":"block","amount":5}], "uncommon", 120),
		make_equip("dragon_scale_armor", "龍鱗戰甲", "armor", "戰鬥開始獲得 20 護體。",
			[{"trigger":"battle_start","kind":"block","amount":20}], "uncommon", 130),
		make_equip("ice_silk_robe", "冰蠶衣", "armor", "每回合開始獲得 3 護體；最大生命 +8。",
			[{"trigger":"turn_start","kind":"block","amount":3},{"trigger":"passive","kind":"max_hp","amount":8}], "uncommon", 120),
		make_equip("vermilion_armor", "朱雀金甲", "armor", "護體效果 +2。",
			[{"trigger":"passive","kind":"block_bonus","amount":2}], "uncommon", 130),
		make_equip("azure_bracers", "青龍護腕", "armor", "戰鬥開始獲得 12 護體並抽 1 張牌。",
			[{"trigger":"battle_start","kind":"block","amount":12},{"trigger":"battle_start","kind":"draw","amount":1}], "uncommon", 130),
		make_equip("phoenix_armor", "鳳羽輕甲", "armor", "每回合開始獲得 8 護體。",
			[{"trigger":"turn_start","kind":"block","amount":8}], "rare", 180),
		make_equip("taiyin_robe", "太陰法袍", "armor", "最大生命 +20。",
			[{"trigger":"passive","kind":"max_hp","amount":20}], "rare", 180),
		make_equip("hunyuan_shell", "混元金鬥", "armor", "護體效果 +4。",
			[{"trigger":"passive","kind":"block_bonus","amount":4}], "rare", 200),
		make_equip("xuanming_shield", "玄冥護盾", "armor", "戰鬥開始獲得 30 護體。",
			[{"trigger":"battle_start","kind":"block","amount":30}], "rare", 190),
		make_equip("sky_silkworm", "天蠶甲", "armor", "每回合開始獲得 10 護體；最大生命 +10。",
			[{"trigger":"turn_start","kind":"block","amount":10},{"trigger":"passive","kind":"max_hp","amount":10}], "rare", 200),
		make_equip("star_armor", "星辰戰甲", "armor", "護體效果 +5；戰鬥開始獲得 10 護體。",
			[{"trigger":"passive","kind":"block_bonus","amount":5},{"trigger":"battle_start","kind":"block","amount":10}], "rare", 200),
		make_equip("golden_body_armor", "九轉金身甲", "armor", "最大生命 +30；護體效果 +3。",
			[{"trigger":"passive","kind":"max_hp","amount":30},{"trigger":"passive","kind":"block_bonus","amount":3}], "rare", 220),
	]

# ── 飾品 30 件 ──

static func _accessory_equipment() -> Array[EquipmentData]:
	return [
		# ── common 10 件 ──
		make_equip("spirit_bracelet", "靈石手環", "accessory", "戰鬥開始回復 5 生命。",
			[{"trigger":"battle_start","kind":"heal","amount":5}], "common", 70),
		make_equip("copper_charm", "銅錢符", "accessory", "戰鬥勝利獲得 5 金幣。",
			[{"trigger":"on_victory","kind":"gold","amount":5}], "common", 60),
		make_equip("spirit_talisman", "靈符護身", "accessory", "攻擊傷害 +1。",
			[{"trigger":"passive","kind":"attack","amount":1}], "common", 70),
		make_equip("jade_pendant", "玉佩", "accessory", "戰鬥開始靈力 +1。",
			[{"trigger":"battle_start","kind":"energy","amount":1}], "common", 80),
		make_equip("mountain_token", "山海令", "accessory", "每回合抽牌 +1。",
			[{"trigger":"turn_start","kind":"draw","amount":1}], "common", 90),
		make_equip("evil_bead", "辟邪珠", "accessory", "每回合開始回復 2 生命。",
			[{"trigger":"turn_start","kind":"heal","amount":2}], "common", 80),
		make_equip("herb_sachet", "靈草香囊", "accessory", "休息節點額外回復 10 生命。",
			[{"trigger":"rest","kind":"heal_bonus","amount":10}], "common", 70),
		make_equip("wind_bell_jade", "風鈴玉珮", "accessory", "每回合開始回復 3 生命。",
			[{"trigger":"turn_start","kind":"heal","amount":3}], "common", 80),
		make_equip("spring_bottle", "靈泉玉瓶", "accessory", "戰鬥勝利回復 8 生命。",
			[{"trigger":"on_victory","kind":"heal","amount":8}], "common", 80),
		make_equip("poison_worm", "靈毒蠱蟲", "accessory", "戰鬥開始敵人受到 2 層蠱毒。",
			[{"trigger":"battle_start","kind":"poison_enemy","amount":2}], "common", 80),
		# ── uncommon 10 件 ──
		make_equip("silver_bracers", "銀絲護腕", "accessory", "攻擊傷害 +2。",
			[{"trigger":"passive","kind":"attack","amount":2}], "uncommon", 120),
		make_equip("nine_curve_bead", "九曲靈珠", "accessory", "每回合抽牌 +2。",
			[{"trigger":"turn_start","kind":"draw","amount":2}], "uncommon", 130),
		make_equip("sun_crown", "太陽金冠", "accessory", "每回合開始靈力 +1。",
			[{"trigger":"turn_start","kind":"energy","amount":1}], "uncommon", 140),
		make_equip("fire_brand", "靈火烙符", "accessory", "攻擊傷害 +2；戰鬥勝利獲得 8 金幣。",
			[{"trigger":"passive","kind":"attack","amount":2},{"trigger":"on_victory","kind":"gold","amount":8}], "uncommon", 130),
		make_equip("five_element_bead", "五行神珠", "accessory", "戰鬥開始獲得 8 護體並回復 6 生命。",
			[{"trigger":"battle_start","kind":"block","amount":8},{"trigger":"battle_start","kind":"heal","amount":6}], "uncommon", 140),
		make_equip("seven_star_pendant", "七星寶劍墜", "accessory", "攻擊傷害 +3。",
			[{"trigger":"passive","kind":"attack","amount":3}], "uncommon", 130),
		make_equip("jade_rabbit_ring", "玉兔靈環", "accessory", "每回合開始回復 4 生命。",
			[{"trigger":"turn_start","kind":"heal","amount":4}], "uncommon", 120),
		make_equip("ghost_chain", "鬼臉鎖鏈", "accessory", "戰鬥開始敵人受到 5 層蠱毒。",
			[{"trigger":"battle_start","kind":"poison_enemy","amount":5}], "uncommon", 130),
		make_equip("dragon_amulet", "龍氣護符", "accessory", "最大生命 +12；攻擊傷害 +1。",
			[{"trigger":"passive","kind":"max_hp","amount":12},{"trigger":"passive","kind":"attack","amount":1}], "uncommon", 140),
		make_equip("moon_pendant", "月輪玉佩", "accessory", "技能牌費用全部 -1。",
			[{"trigger":"passive","kind":"skill_cost","amount":1}], "uncommon", 150),
		# ── rare 10 件 ──
		make_equip("heaven_lamp", "祭天神燈", "accessory", "攻擊傷害 +4。",
			[{"trigger":"passive","kind":"attack","amount":4}], "rare", 200),
		make_equip("kunlun_mirror", "崑崙銅鏡", "accessory", "每回合開始靈力 +1。",
			[{"trigger":"turn_start","kind":"energy","amount":1}], "rare", 200),
		make_equip("taixu_dust", "太虛仙塵", "accessory", "每回合抽牌 +3。",
			[{"trigger":"turn_start","kind":"draw","amount":3}], "rare", 200),
		make_equip("soul_lamp", "靈魂血燈", "accessory", "每回合開始回復 6 生命。",
			[{"trigger":"turn_start","kind":"heal","amount":6}], "rare", 200),
		make_equip("poison_bottle", "萬毒瓶", "accessory", "戰鬥開始敵人受到 8 層蠱毒。",
			[{"trigger":"battle_start","kind":"poison_enemy","amount":8}], "rare", 200),
		make_equip("tiangang_compass", "天罡羅盤", "accessory", "攻擊傷害 +5。",
			[{"trigger":"passive","kind":"attack","amount":5}], "rare", 210),
		make_equip("qiankun_bag", "乾坤袋", "accessory", "所有卡牌費用 -1。",
			[{"trigger":"passive","kind":"cost_all","amount":1}], "rare", 220),
		make_equip("yin_yang_buckle", "陰陽魚扣", "accessory", "每回合開始靈力 +2。",
			[{"trigger":"turn_start","kind":"energy","amount":2}], "rare", 220),
		make_equip("kunlun_seal", "崑崙玉璽", "accessory", "戰鬥開始回復 15 生命並獲得 10 護體。",
			[{"trigger":"battle_start","kind":"heal","amount":15},{"trigger":"battle_start","kind":"block","amount":10}], "rare", 220),
		make_equip("chaos_bead", "混沌神珠", "accessory", "攻擊傷害 +3；護體效果 +3；每回合回復 2 生命。",
			[{"trigger":"passive","kind":"attack","amount":3},{"trigger":"passive","kind":"block_bonus","amount":3},{"trigger":"turn_start","kind":"heal","amount":2}], "rare", 250),
	]

# ── 角色專武 4 件 ──

static func _lxy_weapon() -> EquipmentData:
	return make_equip("lxy_divine_sword", "御劍神兵", "weapon",
		"攻擊傷害 +5；最大生命 +10；戰鬥開始靈力 +1。",
		[{"trigger":"passive","kind":"attack","amount":5},{"trigger":"passive","kind":"max_hp","amount":10},{"trigger":"battle_start","kind":"energy","amount":1}],
		"rare", 250, "li_xiaoyao")

static func _zl_weapon() -> EquipmentData:
	return make_equip("zl_nvwa_stone", "女媧石", "weapon",
		"攻擊傷害 +4；戰鬥開始回復 12 生命；護體效果 +3。",
		[{"trigger":"passive","kind":"attack","amount":4},{"trigger":"battle_start","kind":"heal","amount":12},{"trigger":"passive","kind":"block_bonus","amount":3}],
		"rare", 250, "zhao_linger")

static func _lyr_weapon() -> EquipmentData:
	return make_equip("lyr_demon_sword", "降魔靈劍", "weapon",
		"攻擊傷害 +6；護體效果 +3；每回合開始獲得 5 護體。",
		[{"trigger":"passive","kind":"attack","amount":6},{"trigger":"passive","kind":"block_bonus","amount":3},{"trigger":"turn_start","kind":"block","amount":5}],
		"rare", 250, "lin_yueru")

static func _anu_weapon() -> EquipmentData:
	return make_equip("anu_gu_token", "蠱王令牌", "weapon",
		"攻擊傷害 +4；戰鬥開始敵人受到 6 層蠱毒；每回合回復 3 生命。",
		[{"trigger":"passive","kind":"attack","amount":4},{"trigger":"battle_start","kind":"poison_enemy","amount":6},{"trigger":"turn_start","kind":"heal","amount":3}],
		"rare", 250, "anu")

# ── 神器 5 件 ──

static func _xuanyuan_sword() -> EquipmentData:
	return make_equip("xuanyuan_sword", "軒轅劍", "weapon",
		"攻擊傷害 +8；護體效果 +4；每回合回復 5 生命。",
		[{"trigger":"passive","kind":"attack","amount":8},{"trigger":"passive","kind":"block_bonus","amount":4},{"trigger":"turn_start","kind":"heal","amount":5}],
		"artifact", 0)

static func _pangu_axe() -> EquipmentData:
	return make_equip("pangu_axe", "盤古斧", "weapon",
		"攻擊傷害 +12；每回合靈力 +1；戰鬥開始獲得 20 護體。",
		[{"trigger":"passive","kind":"attack","amount":12},{"trigger":"turn_start","kind":"energy","amount":1},{"trigger":"battle_start","kind":"block","amount":20}],
		"artifact", 0)

static func _shennong_cauldron() -> EquipmentData:
	return make_equip("shennong_cauldron", "洪荒神鼎", "weapon",
		"最大生命 +50；每回合回復 10 生命；戰鬥勝利回復 20 生命。",
		[{"trigger":"passive","kind":"max_hp","amount":50},{"trigger":"turn_start","kind":"heal","amount":10},{"trigger":"on_victory","kind":"heal","amount":20}],
		"artifact", 0)

static func _fuxi_qin() -> EquipmentData:
	return make_equip("fuxi_qin", "伏羲琴", "weapon",
		"所有卡牌費用 -1；每回合多抽 2 張；每回合靈力 +1。",
		[{"trigger":"passive","kind":"cost_all","amount":1},{"trigger":"turn_start","kind":"draw","amount":2},{"trigger":"turn_start","kind":"energy","amount":1}],
		"artifact", 0)

static func _nvwa_stone() -> EquipmentData:
	return make_equip("nvwa_sky_stone", "女媧補天石", "weapon",
		"攻擊傷害 +5；護體效果 +5；戰鬥開始敵人受到 6 層蠱毒；最大生命 +25。",
		[{"trigger":"passive","kind":"attack","amount":5},{"trigger":"passive","kind":"block_bonus","amount":5},{"trigger":"battle_start","kind":"poison_enemy","amount":6},{"trigger":"passive","kind":"max_hp","amount":25}],
		"artifact", 0)

static func _artifact_boss() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "ancient_guardian"
	enemy.display_name = "上古守護靈"
	enemy.max_hp = 150
	enemy.portrait_path = ""
	enemy.actions = [
		{"intent": "聖光裂擊 20", "effects": [{"kind": "damage", "amount": 20}]},
		{"intent": "神盾 20",   "effects": [{"kind": "block",  "amount": 20}]},
		{"intent": "天雷連擊 15×2", "effects": [{"kind": "damage", "amount": 15}, {"kind": "damage", "amount": 15}]},
		{"intent": "封印術",    "effects": [{"kind": "weak", "amount": 3}, {"kind": "poison", "amount": 4}]},
		{"intent": "滅世神擊 35", "effects": [{"kind": "damage", "amount": 35}]},
	]
	return enemy

# ──────────────────────────────────────────────
#  Card factory (original)
# ──────────────────────────────────────────────

static func make_card(id: String, display_name: String, owner: String, cost: int, card_type: String, description: String, effects: Array[Dictionary], rarity: String = "basic") -> CardData:
	var card: CardData = CardData.new()
	card.id = id
	card.display_name = display_name
	card.owner = owner
	card.cost = cost
	card.card_type = card_type
	card.description = description
	card.effects = effects
	card.rarity = rarity
	card.art_path = "res://assets/art/cards/%s.png" % id
	return card

static func characters() -> Array[CharacterData]:
	return [_li_xiaoyao(), _zhao_linger(), _lin_yueru(), _anu()]

static func enemies() -> Array[EnemyData]:
	return [_bandit(), _beast(), _gu_cultist(), _moon_worshipper()]

static func _li_xiaoyao() -> CharacterData:
	var cards: Array[CardData] = [
		make_card("lxy_yujian", "御劍術", "李逍遙", 1, "attack", "造成 7 點傷害。", [{"kind": "damage", "amount": 7}]),
		make_card("lxy_wanjian", "萬劍訣", "李逍遙", 2, "attack", "連續劍氣，造成 5 點傷害三次。", [{"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}]),
		make_card("lxy_feilong", "飛龍探雲手", "李逍遙", 1, "skill", "造成 4 點傷害，抽 1 張牌並回復 1 點靈力。", [{"kind": "damage", "amount": 4}, {"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}]),
		make_card("lxy_tianshi", "天師符法", "李逍遙", 1, "attack", "造成 9 點法術傷害。", [{"kind": "damage", "amount": 9}]),
		make_card("lxy_jiushen", "酒神咒", "李逍遙", 3, "attack", "造成 32 點傷害，自身承受 6 點反噬。", [{"kind": "damage", "amount": 32}, {"kind": "self_damage", "amount": 6}], "rare"),
		make_card("lxy_xianfeng", "仙風雲體", "李逍遙", 1, "skill", "獲得 8 點護體，抽 1 張牌。", [{"kind": "block", "amount": 8}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_zuimeng", "醉夢望月", "李逍遙", 2, "power", "本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("lxy_jianqi", "劍氣護身", "李逍遙", 1, "skill", "獲得 10 點護體。", [{"kind": "block", "amount": 10}])
	]
	return _character("li_xiaoyao", "李逍遙", 74, "劍術、爆發、偷取與酒神系高風險高傷害。", cards)

static func _zhao_linger() -> CharacterData:
	var cards: Array[CardData] = [
		make_card("zl_guanyin", "觀音咒", "趙靈兒", 1, "skill", "回復 8 點生命。", [{"kind": "heal", "amount": 8}]),
		make_card("zl_wuqi", "五氣朝元", "趙靈兒", 2, "skill", "回復 16 點生命並獲得 6 點護體。", [{"kind": "heal", "amount": 16}, {"kind": "block", "amount": 6}], "uncommon"),
		make_card("zl_xuanbing", "玄冰咒", "趙靈兒", 1, "attack", "造成 6 點傷害，使敵人虛弱 2 層。", [{"kind": "damage", "amount": 6}, {"kind": "weak", "amount": 2}]),
		make_card("zl_leizhou", "雷咒", "趙靈兒", 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}]),
		make_card("zl_mengshe", "夢蛇", "趙靈兒", 2, "power", "本場戰鬥傷害提升 3，並抽 1 張牌。", [{"kind": "power", "amount": 3}, {"kind": "draw", "amount": 1}], "rare"),
		make_card("zl_fengling", "風靈符", "趙靈兒", 0, "skill", "抽 1 張牌。", [{"kind": "draw", "amount": 1}], "uncommon"),
		make_card("zl_tianlei", "天雷破", "趙靈兒", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("zl_lingguang", "靈光護體", "趙靈兒", 1, "skill", "獲得 12 點護體。", [{"kind": "block", "amount": 12}])
	]
	return _character("zhao_linger", "趙靈兒", 68, "五靈仙術、治療、護盾與夢蛇爆發。", cards)

static func _lin_yueru() -> CharacterData:
	var cards: Array[CardData] = [
		make_card("lyr_qijianzhi", "氣劍指", "林月如", 1, "attack", "造成 8 點傷害。", [{"kind": "damage", "amount": 8}]),
		make_card("lyr_yiyang", "一陽指", "林月如", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("lyr_zhanlong", "斬龍訣", "林月如", 3, "attack", "造成 30 點傷害。", [{"kind": "damage", "amount": 30}], "rare"),
		make_card("lyr_qiankun", "乾坤一擲", "林月如", 0, "attack", "消耗全部靈力，每點造成 9 點傷害。", [{"kind": "consume_energy_damage", "amount": 9}], "rare"),
		make_card("lyr_fanji", "回身反擊", "林月如", 1, "skill", "獲得 8 點護體並造成 5 點傷害。", [{"kind": "block", "amount": 8}, {"kind": "damage", "amount": 5}]),
		make_card("lyr_bianying", "鞭影連環", "林月如", 1, "attack", "造成 4 點傷害兩次，施加 1 層破綻。", [{"kind": "damage", "amount": 4}, {"kind": "damage", "amount": 4}, {"kind": "vulnerable", "amount": 1}]),
		make_card("lyr_shenfa", "月影身法", "林月如", 1, "skill", "獲得 7 點護體，抽 1 張牌。", [{"kind": "block", "amount": 7}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_juesha", "絕殺一擊", "林月如", 2, "attack", "造成 14 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 2}], "uncommon")
	]
	return _character("lin_yueru", "林月如", 72, "鞭劍武學、連擊、反擊與單體爆發。", cards)

static func _anu() -> CharacterData:
	var cards: Array[CardData] = [
		make_card("anu_yufeng", "御蜂術", "阿奴", 1, "attack", "造成 3 點傷害四次。", [{"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}]),
		make_card("anu_wanyi", "萬蟻蝕象", "阿奴", 1, "skill", "施加 6 層蠱毒。", [{"kind": "poison", "amount": 6}]),
		make_card("anu_mihun", "迷魂術", "阿奴", 1, "skill", "使敵人虛弱 3 層。", [{"kind": "weak", "amount": 3}]),
		make_card("anu_baozhagu", "爆炸蠱", "阿奴", 2, "attack", "引爆全部蠱毒，每層造成 3 點傷害。", [{"kind": "poison_burst", "amount": 3}], "uncommon"),
		make_card("anu_lingxue", "靈血咒", "阿奴", 0, "skill", "自身承受 4 點反噬，抽 2 張牌並回復 1 點靈力。", [{"kind": "self_damage", "amount": 4}, {"kind": "draw", "amount": 2}, {"kind": "energy", "amount": 1}], "rare"),
		make_card("anu_jiedu", "解毒咒", "阿奴", 1, "skill", "回復 7 點生命並獲得 5 點護體。", [{"kind": "heal", "amount": 7}, {"kind": "block", "amount": 5}]),
		make_card("anu_guling", "蠱靈護身", "阿奴", 1, "skill", "獲得 12 點護體。", [{"kind": "block", "amount": 12}], "uncommon"),
		make_card("anu_wangyou", "忘憂蠱", "阿奴", 2, "skill", "施加 4 層蠱毒與 2 層破綻。", [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 2}], "uncommon")
	]
	return _character("anu", "阿奴", 66, "蠱毒、召喚、持續傷害、削弱與干擾。", cards)

static func _character(id: String, display_name: String, max_hp: int, style: String, cards: Array[CardData]) -> CharacterData:
	var character: CharacterData = CharacterData.new()
	character.id = id
	character.display_name = display_name
	character.max_hp = max_hp
	character.battle_style = style
	character.portrait_path = "res://assets/art/portraits/%s.png" % id
	character.starting_deck = [cards[0], cards[0], cards[1], cards[2], cards[3], cards[4], cards[7], cards[7]]
	character.reward_pool = cards.slice(5)
	return character

static func _bandit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "bandit"
	enemy.display_name = "山賊頭目"
	enemy.max_hp = 56
	enemy.portrait_path = "res://assets/art/enemies/bandit.png"
	enemy.actions = [
		{"intent": "劈砍 10", "effects": [{"kind": "damage", "amount": 10}]},
		{"intent": "防守 8", "effects": [{"kind": "block", "amount": 8}]},
		{"intent": "猛擊 14", "effects": [{"kind": "damage", "amount": 14}]}
	]
	return enemy

static func _beast() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "beast"
	enemy.display_name = "山林妖獸"
	enemy.max_hp = 64
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.actions = [
		{"intent": "撕咬 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "怒吼 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "撲擊 18", "effects": [{"kind": "damage", "amount": 18}]}
	]
	return enemy

static func _gu_cultist() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "gu_cultist"
	enemy.display_name = "蠱毒妖人"
	enemy.max_hp = 58
	enemy.portrait_path = "res://assets/art/enemies/gu_cultist.png"
	enemy.actions = [
		{"intent": "毒霧 3", "effects": [{"kind": "poison", "amount": 3}]},
		{"intent": "邪術 9", "effects": [{"kind": "damage", "amount": 9}, {"kind": "weak", "amount": 1}]},
		{"intent": "護咒 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _moon_worshipper() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "moon_worshipper"
	enemy.display_name = "拜月教徒"
	enemy.max_hp = 86
	enemy.portrait_path = "res://assets/art/enemies/moon_worshipper.png"
	enemy.actions = [
		{"intent": "拜月咒 13", "effects": [{"kind": "damage", "amount": 13}]},
		{"intent": "妖術：蠱毒 4", "effects": [{"kind": "poison", "amount": 4}]},
		{"intent": "結界 12", "effects": [{"kind": "block", "amount": 12}]},
		{"intent": "邪月重擊 20", "effects": [{"kind": "damage", "amount": 20}]}
	]
	return enemy
