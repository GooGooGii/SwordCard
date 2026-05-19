class_name GameData
extends RefCounted

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
