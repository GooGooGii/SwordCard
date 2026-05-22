class_name GameData
extends RefCounted

static func make_card(id: String, display_name: String, owner: String, cost: int, card_type: String, description: String, effects: Array[Dictionary], rarity: String = "basic", art_id: String = "") -> CardData:
	var card: CardData = CardData.new()
	card.id = id
	card.display_name = display_name
	card.owner = owner
	card.cost = cost
	card.card_type = card_type
	card.description = description
	card.effects = effects
	card.rarity = rarity
	var image_id: String = id if art_id.is_empty() else art_id
	card.art_path = "res://assets/art/cards/%s.png" % image_id
	return card

static func characters() -> Array[CharacterData]:
	return [_li_xiaoyao(), _zhao_linger(), _lin_yueru(), _anu()]

static func enemies() -> Array[EnemyData]:
	return [_bandit(), _beast(), _gu_cultist(), _sword_spirit(), _fox_spirit(), _serpent_demon()]

static func bosses() -> Array[EnemyData]:
	return [_moon_worshipper(), _centipede_lord(), _witch_queen()]

static func _li_xiaoyao() -> CharacterData:
	var cards: Array[CardData] = [
		make_card("lxy_yujian", "御劍術", "李逍遙", 1, "attack", "造成 7 點傷害。", [{"kind": "damage", "amount": 7}]),
		make_card("lxy_wanjian", "萬劍訣", "李逍遙", 2, "attack", "連續劍氣，造成 5 點傷害三次。", [{"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}]),
		make_card("lxy_feilong", "飛龍探雲手", "李逍遙", 1, "skill", "造成 4 點傷害，抽 1 張牌並回復 1 點靈力。", [{"kind": "damage", "amount": 4}, {"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}]),
		make_card("lxy_tianshi", "天師符法", "李逍遙", 1, "attack", "造成 9 點法術傷害。", [{"kind": "damage", "amount": 9}]),
		make_card("lxy_jiushen", "酒神咒", "李逍遙", 3, "attack", "造成 28 點傷害，自身承受 8 點反噬。", [{"kind": "damage", "amount": 28}, {"kind": "self_damage", "amount": 8}], "rare"),
		make_card("lxy_xianfeng", "仙風雲體", "李逍遙", 1, "skill", "獲得 8 點護體，抽 1 張牌。", [{"kind": "block", "amount": 8}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_zuimeng", "醉夢望月", "李逍遙", 2, "power", "本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("lxy_jianqi", "劍氣護身", "李逍遙", 1, "skill", "獲得 10 點護體。", [{"kind": "block", "amount": 10}]),
		make_card("lxy_linghuo", "靈火符", "李逍遙", 1, "attack", "造成 6 點傷害，施加 1 層破綻。", [{"kind": "damage", "amount": 6}, {"kind": "vulnerable", "amount": 1}], "uncommon"),
		make_card("lxy_xiaoyao_you", "逍遙遊", "李逍遙", 0, "skill", "抽 1 張牌並回復 1 點靈力。", [{"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}], "rare")
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
		make_card("zl_lingguang", "靈光護體", "趙靈兒", 1, "skill", "獲得 12 點護體。", [{"kind": "block", "amount": 12}]),
		make_card("zl_huanyu", "幻雨咒", "趙靈兒", 1, "skill", "獲得 7 點護體，使敵人虛弱 1 層。", [{"kind": "block", "amount": 7}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("zl_nvwa", "女媧靈息", "趙靈兒", 2, "power", "回復 6 點生命，本場戰鬥傷害提升 2。", [{"kind": "heal", "amount": 6}, {"kind": "power", "amount": 2}], "rare"),
		make_card("zl_huihun", "回魂咒", "趙靈兒", 2, "skill", "救回 1 名倒下的同伴（30 HP 上場）；若無人倒下，改為自己回復 30 生命。", [{"kind": "revive", "amount": 30}], "rare")
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
		make_card("lyr_juesha", "絕殺一擊", "林月如", 2, "attack", "造成 14 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("lyr_lianhuan", "連環快斬", "林月如", 1, "attack", "造成 3 點傷害三次。", [{"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}], "uncommon"),
		make_card("lyr_jinchan", "金蟬卸力", "林月如", 1, "skill", "獲得 5 點護體，抽 2 張牌。", [{"kind": "block", "amount": 5}, {"kind": "draw", "amount": 2}], "rare")
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
		make_card("anu_wangyou", "忘憂蠱", "阿奴", 2, "skill", "施加 4 層蠱毒與 2 層破綻。", [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("anu_duwu", "毒霧繚繞", "阿奴", 1, "skill", "施加 3 層蠱毒，使敵人虛弱 1 層。", [{"kind": "poison", "amount": 3}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("anu_guxue", "蠱血共鳴", "阿奴", 2, "power", "本場戰鬥傷害提升 1，施加 5 層蠱毒。", [{"kind": "power", "amount": 1}, {"kind": "poison", "amount": 5}], "rare")
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
	character.passives = _passives_for(id)
	return character

static func _passives_for(id: String) -> Array[Dictionary]:
	match id:
		"li_xiaoyao":
			return [{
				"trigger": "first_attack_cost",
				"amount": 1,
				"label": "每場戰鬥第一張攻擊牌費用 -1",
				"status_label": "下一張攻擊牌費用 -1"
			}]
		"zhao_linger":
			return [{
				"trigger": "battle_start",
				"kind": "self_heal",
				"amount": 4,
				"label": "每場戰鬥開始回復 4 點生命"
			}]
		"lin_yueru":
			return [{
				"trigger": "first_block_counter",
				"amount": 4,
				"label": "每回合第一次獲得護體時，造成 4 點反擊傷害",
				"status_label": "本回合下一次護體反擊可用"
			}]
		"anu":
			return [{
				"trigger": "battle_start",
				"kind": "enemy_poison",
				"amount": 5,
				"label": "敵人每場戰鬥開場受到 5 層蠱毒"
			}]
	return []

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

static func _sword_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "sword_spirit"
	enemy.display_name = "劍冢靈影"
	enemy.max_hp = 62
	enemy.portrait_path = "res://assets/art/enemies/sword_spirit.png"
	enemy.actions = [
		{"intent": "劍芒 11", "effects": [{"kind": "damage", "amount": 11}]},
		{"intent": "護劍 9", "effects": [{"kind": "block", "amount": 9}]},
		{"intent": "破勢 8", "effects": [{"kind": "damage", "amount": 8}, {"kind": "weak", "amount": 1}]}
	]
	return enemy

static func _fox_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "fox_spirit"
	enemy.display_name = "魅狐幻影"
	enemy.max_hp = 52
	enemy.portrait_path = "res://assets/art/enemies/fox_spirit.png"
	enemy.actions = [
		{"intent": "魅惑 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "幻爪 10", "effects": [{"kind": "damage", "amount": 10}]},
		{"intent": "遁形 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _serpent_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "serpent_demon"
	enemy.display_name = "赤蛇妖"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.actions = [
		{"intent": "毒牙 9", "effects": [{"kind": "damage", "amount": 9}, {"kind": "poison", "amount": 2}]},
		{"intent": "盤身 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "蛇吻 15", "effects": [{"kind": "damage", "amount": 15}]}
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
	enemy.phase_2_actions = [
		{"intent": "月蝕重擊 18 + 虛弱 2", "effects": [
			{"kind": "damage", "amount": 18},
			{"kind": "weak", "amount": 2}
		]},
		{"intent": "邪結界 18", "effects": [{"kind": "block", "amount": 18}]},
		{"intent": "拜月狂咒 24", "effects": [{"kind": "damage", "amount": 24}]}
	]
	return enemy

static func _centipede_lord() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "centipede_lord"
	enemy.display_name = "蜈蚣大王"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/centipede_lord.png"
	enemy.actions = [
		{"intent": "多足踏擊 5x4", "effects": [
			{"kind": "damage", "amount": 5},
			{"kind": "damage", "amount": 5},
			{"kind": "damage", "amount": 5},
			{"kind": "damage", "amount": 5}
		]},
		{"intent": "毒尾掃 12 + 蠱毒 3", "effects": [
			{"kind": "damage", "amount": 12},
			{"kind": "poison", "amount": 3}
		]},
		{"intent": "蜷甲防禦 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "蝕骨蝕魂 18 + 虛弱 1", "effects": [
			{"kind": "damage", "amount": 18},
			{"kind": "weak", "amount": 1}
		]}
	]
	enemy.phase_2_actions = [
		{"intent": "怒爪掃 7x4", "effects": [
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7}
		]},
		{"intent": "噬魂咒 22", "effects": [{"kind": "damage", "amount": 22}]},
		{"intent": "毒霧 蠱毒 6 + 破綻 2", "effects": [
			{"kind": "poison", "amount": 6},
			{"kind": "vulnerable", "amount": 2}
		]}
	]
	return enemy

static func _witch_queen() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "witch_queen"
	enemy.display_name = "山靈巫后"
	enemy.max_hp = 78
	enemy.portrait_path = "res://assets/art/enemies/witch_queen.png"
	enemy.actions = [
		{"intent": "蠱咒 蠱毒 5", "effects": [{"kind": "poison", "amount": 5}]},
		{"intent": "詛咒 虛弱 3", "effects": [{"kind": "weak", "amount": 3}]},
		{"intent": "邪結界 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "魂噬 15 + 蠱毒 2", "effects": [
			{"kind": "damage", "amount": 15},
			{"kind": "poison", "amount": 2}
		]}
	]
	enemy.phase_2_actions = [
		{"intent": "山靈怒火 20 + 虛弱 1", "effects": [
			{"kind": "damage", "amount": 20},
			{"kind": "weak", "amount": 1}
		]},
		{"intent": "蠱噬 蠱毒 6 + 破綻 2", "effects": [
			{"kind": "poison", "amount": 6},
			{"kind": "vulnerable", "amount": 2}
		]},
		{"intent": "邪音咒 12 + 破綻 3", "effects": [
			{"kind": "damage", "amount": 12},
			{"kind": "vulnerable", "amount": 3}
		]}
	]
	return enemy
