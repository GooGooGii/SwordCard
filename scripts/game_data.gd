class_name GameData
extends RefCounted

static func make_card(id: String, display_name: String, owner: String, cost: int, card_type: String, description: String, effects: Array[Dictionary], rarity: String = "basic", art_id: String = "", reduces_cost: bool = false, exhaust: bool = false) -> CardData:
	var card: CardData = CardData.new()
	card.id = id
	card.display_name = display_name
	card.owner = owner
	card.cost = cost
	card.card_type = card_type
	card.description = description
	card.effects = effects
	card.rarity = rarity
	card.upgrade_reduces_cost = reduces_cost
	card.exhaust = exhaust
	var image_id: String = id if art_id.is_empty() else art_id
	card.art_path = "res://assets/art/cards/%s.png" % image_id
	return card

static func characters() -> Array[CharacterData]:
	return [_li_xiaoyao(), _zhao_linger(), _lin_yueru(), _anu()]

# 劍氣 token（StS Shiv 式）：劍氣縱橫生成的 0 費臨時攻擊，打出後消耗。art 借御劍卡。
static func jianqi_token() -> CardData:
	var c: CardData = make_card("token_jianqi", "劍氣", "李逍遙", 0, "attack", "造成 4 點傷害，打出後消耗。", [{"kind": "damage", "amount": 4}], "basic")
	c.exhaust = true
	return c

# 共同牌（STS colorless 移植）：owner = "無門"，任何角色都能在 獎勵/商店/事件 取得。
# art 暫借既有同類卡（記入 ART_GUIDE「借圖待補」）。
static func colorless_cards() -> Array[CardData]:
	var list: Array[CardData] = [
		make_card("cl_xunjiezhan", "迅捷斬", "無門", 0, "attack", "造成 7 點傷害。", [{"kind": "damage", "amount": 7}], "uncommon"),
		make_card("cl_hanfengjue", "寒鋒訣", "無門", 0, "attack", "造成 3 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 3}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("cl_hushenjue", "金鐘護體", "無門", 0, "skill", "獲得 6 點護體。", [{"kind": "block", "amount": 6}], "uncommon"),
		make_card("cl_qiaojin", "借力卸勁", "無門", 0, "skill", "獲得 2 點護體，抽 1 張牌。", [{"kind": "block", "amount": 2}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("cl_zhimingfu", "致盲符", "無門", 0, "skill", "使敵人虛弱 2 層。", [{"kind": "weak", "amount": 2}], "uncommon"),
		make_card("cl_poshi", "覷破空門", "無門", 0, "skill", "施加 2 層破綻。", [{"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("cl_jinchuangtie", "金創藥帖", "無門", 0, "skill", "回復 5 點生命。打出後消耗。", [{"kind": "heal", "amount": 5}], "uncommon", "", false, true),
		make_card("cl_qimendunjia", "奇門遁甲", "無門", 0, "attack", "對全體敵人造成 8 點傷害。", [{"kind": "damage_all", "amount": 8}], "uncommon"),
		make_card("cl_yunchou", "運籌帷幄", "無門", 0, "skill", "抽 3 張牌。打出後消耗。", [{"kind": "draw", "amount": 3}], "rare", "", false, true),
		make_card("cl_huacaijianyi", "華彩劍意", "無門", 1, "power", "本回合每出 5 張牌，對全體敵人造成 10 點傷害。", [{"kind": "combo_strike", "amount": 10, "threshold": 5}], "rare"),
		# debuff 引爆 finisher（通用，讓四角色的破綻/虛弱堆疊都有爆發出口）
		make_card("cl_chenxi_poshi", "趁隙破勢", "無門", 1, "attack", "趁敵破綻盡顯，引爆敵人全部虛弱與破綻，每層造成 4 點傷害。", [{"kind": "consume_debuff_damage", "amount": 4}], "rare"),
		# ── 消耗流 archetype（通用，對齊 StS Feel No Pain / Dark Embrace / Fiend Fire）──
		make_card("cl_wutongjue", "無痛訣", "無門", 1, "power", "凝神忘痛。本場戰鬥每消耗 1 張牌，獲得 3 點護體。", [{"kind": "block_on_exhaust", "amount": 3}], "uncommon"),
		make_card("cl_shipaijue", "噬牌訣", "無門", 1, "power", "以牌飼心。本場戰鬥每消耗 1 張牌，抽 1 張牌。", [{"kind": "draw_on_exhaust", "amount": 1}], "rare", "", true),
		make_card("cl_fenjinjue", "焚盡訣", "無門", 1, "attack", "引燃真氣，消耗手牌中其餘所有牌，每張對敵人造成 5 點傷害。打出後消耗。", [{"kind": "exhaust_hand_damage", "amount": 5}], "rare", "", false, true),
	]
	# exhaust 標記（make_card 無此參數，直接設）
	for c: CardData in list:
		if c.id == "cl_jinchuangtie" or c.id == "cl_yunchou":
			c.exhaust = true
	return list

static func colorless_card_by_id(id: String) -> CardData:
	for c: CardData in colorless_cards():
		if c.id == id:
			return c
	return null

static func enemies() -> Array[EnemyData]:
	return [_bandit(), _beast(), _gu_cultist(), _sword_spirit(), _fox_spirit(), _serpent_demon(),
		_zombie_soldier(), _toxic_centipede(), _tower_demon(), _tower_ghost_soldier(),
		_baiyue_guard(), _ancient_evil_spirit(),
		_wild_bee(), _cave_bat(), _water_imp(), _skeleton_soldier(), _grave_fire(),
		_rock_guardian(), _trial_swordshade(),
		_thief(), _tree_demon(), _xing_tian(), _black_impermanence(), _white_impermanence(),
		_viper(), _flying_skull(), _cleaver_granny(), _man_eating_flower(), _gourd_sage(), _puppet_girl(),
		_green_snake(), _grass_spider(), _lantern_ghost(), _hydra_snake(), _flying_snake(),
		_baby_toad(), _poison_toad(), _vampire_giant(), _scorpion(), _female_thief(),
		_birdman(), _demihuman_villager(), _five_eyed_demon(), _unicorn_demon(), _pincer_demon(),
		_jumping_frog(), _fire_kirin_whelp(), _ice_beast(), _man_eater_beast(), _two_headed_snake(),
		_bee_cocoon(), _leaf_sprite(), _grass_sprite(), _thug(), _miao_maiden(),
		_octopus_imp(), _clam_spirit(), _conch_maiden(), _turtle_demon(),
		_gambler(), _lecher_thief(), _rat_demon(), _bully(),
		_earth_imp(), _blood_worm(), _venom_spider(), _fire_toad()]

# === PAL1 對齊補充小怪（借用既有肖像，專屬美術見 ART_TODO） ===
static func _bee_cocoon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "bee_cocoon"
	enemy.default_facing_left = true  # 原圖面向左，戰鬥中不再翻轉
	enemy.portrait_scale = 0.72  # 小型：蜂蛹（借 wild_bee 圖）
	enemy.display_name = "蜂蛹"
	enemy.max_hp = 30
	enemy.portrait_path = "res://assets/art/enemies/bee_cocoon.png"
	enemy.actions = [
		{"intent": "蠕動撞 6", "effects": [{"kind": "damage", "amount": 6}]},
		{"intent": "結繭 12", "effects": [{"kind": "block", "amount": 12}]},
		{"intent": "孵化毒針 8 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 8}, {"kind": "poison", "amount": 2}]}
	]
	# 機制（倒數計時）：出手 2 次後破繭狂化——act 1 的「教學版」計時敵，數字小但規則可見
	enemy.passive = {"kind": "enrage_after", "turns": 2, "amount": 5,
		"label": "破繭倒數：蜂蛹出手兩次後將孵化狂暴（力量 +5）",
		"on_trigger": "破繭而出！力量 +5！"}
	return enemy

static func _leaf_sprite() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "leaf_sprite"
	enemy.portrait_scale = 0.78  # 小型：綠葉小妖（借 tree_demon 圖）
	enemy.display_name = "綠葉小妖"
	enemy.max_hp = 26
	enemy.portrait_path = "res://assets/art/enemies/leaf_sprite.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "葉刃 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "孢子 蠱毒 2", "effects": [{"kind": "poison", "amount": 2}]},
		{"intent": "光合護 8", "effects": [{"kind": "block", "amount": 8}]}
	]
	return enemy

static func _grass_sprite() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "grass_sprite"
	enemy.portrait_scale = 0.8  # 小型：草精（借 tree_demon 圖）
	enemy.display_name = "草精"
	enemy.max_hp = 34
	enemy.portrait_path = "res://assets/art/enemies/grass_sprite.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "藤鞭抽 10", "effects": [{"kind": "damage", "amount": 10}]},
		{"intent": "纏繞 虛弱 1", "effects": [{"kind": "weak", "amount": 1}]},
		{"intent": "紮根 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _thug() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "thug"
	enemy.display_name = "打手"
	enemy.max_hp = 58
	enemy.portrait_path = "res://assets/art/enemies/thug.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "拳打 13", "effects": [{"kind": "damage", "amount": 13}]},
		{"intent": "悶棍 11 + 破綻 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "抱架 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _miao_maiden() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "miao_maiden"
	enemy.display_name = "長鞭苗女"
	enemy.max_hp = 62
	enemy.portrait_path = "res://assets/art/enemies/miao_maiden.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "長鞭抽 13 + 破綻 1", "effects": [{"kind": "damage", "amount": 13}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "苗女毒鏢 11 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 11}, {"kind": "poison", "amount": 3}]},
		{"intent": "騰挪 11", "effects": [{"kind": "block", "amount": 11}]}
	]
	return enemy

static func _octopus_imp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "octopus_imp"
	enemy.portrait_scale = 0.9  # 水族：短腿章魚（借 water_tentacle 圖）
	enemy.display_name = "短腿章魚"
	enemy.max_hp = 58
	enemy.portrait_path = "res://assets/art/enemies/octopus_imp.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "觸腕纏 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "墨噴 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "吸盤護 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _clam_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "clam_spirit"
	enemy.display_name = "蚌殼精"
	enemy.max_hp = 72
	enemy.portrait_path = "res://assets/art/enemies/clam_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "蚌夾 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "閉殼 22", "effects": [{"kind": "block", "amount": 22}]},
		{"intent": "珍珠光 12 + 破綻 1", "effects": [{"kind": "damage", "amount": 12}, {"kind": "vulnerable", "amount": 1}]}
	]
	return enemy

static func _conch_maiden() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "conch_maiden"
	enemy.display_name = "海螺女"
	enemy.max_hp = 64
	enemy.portrait_path = "res://assets/art/enemies/conch_maiden.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "海螺音波 13 + 虛弱 1", "effects": [{"kind": "damage", "amount": 13}, {"kind": "weak", "amount": 1}]},
		{"intent": "纏絲 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "護鱗 13", "effects": [{"kind": "block", "amount": 13}]}
	]
	# 機制（蓄力釋放，act 8 雜兵）：每 3 回合「攝魂音波」16 + 虛弱 2
	enemy.ultimate_every = 3
	enemy.ultimate_action = {"intent": "攝魂音波 16 + 虛弱 2", "effects": [
		{"kind": "damage", "amount": 16}, {"kind": "weak", "amount": 2}]}
	return enemy

static func _turtle_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "turtle_demon"
	enemy.portrait_scale = 1.1  # 水族：傻仔龜（借 rock_guardian 圖）
	enemy.display_name = "傻仔龜"
	enemy.max_hp = 84
	enemy.portrait_path = "res://assets/art/enemies/turtle_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "龜殼撞 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "縮殼 24", "effects": [{"kind": "block", "amount": 24}]},
		{"intent": "噴水 12 + 虛弱 1", "effects": [{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 1}]}
	]
	return enemy

# === 蘇州城補充小怪（市井人類 + 鼠妖；借用既有肖像，專屬美術見 ART_TODO） ===
static func _gambler() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "gambler"
	enemy.display_name = "賭棍"
	enemy.max_hp = 50
	enemy.portrait_path = "res://assets/art/enemies/gambler.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "比大小（莊家贏→傷14 / 你贏→賞銅錢20）", "effects": [{"kind": "gamble_attack", "amount": 14, "gold": 20}]},
		{"intent": "詐賭 11 + 破綻 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "油滑閃 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	# 機制（蓄力釋放）：每 3 回合「孤注一擲」重壓——意圖預警，玩家提前佈防或搶殺
	enemy.ultimate_every = 3
	enemy.ultimate_action = {"intent": "孤注一擲 22", "effects": [{"kind": "damage", "amount": 22}]}
	return enemy

static func _lecher_thief() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "lecher_thief"
	enemy.display_name = "淫賊"
	enemy.max_hp = 48
	enemy.portrait_path = "res://assets/art/enemies/lecher_thief.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "偷襲 13", "effects": [{"kind": "damage", "amount": 13}]},
		{"intent": "鹹豬手（女性：撲飛偷內衣→虛弱2）", "effects": [{"kind": "lecher_steal", "damage": 6, "weak": 2, "chance": 0.6}]},
		{"intent": "溜牆 9", "effects": [{"kind": "block", "amount": 9}]}
	]
	return enemy

static func _rat_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "rat_demon"
	enemy.portrait_scale = 0.78  # 小型：鼠妖
	enemy.swarm_size = 3  # 成群出沒：遭遇時整組換成 3 隻鼠妖（受 MAX_ENEMIES 上限）
	enemy.display_name = "鼠妖"
	enemy.max_hp = 24  # 單隻很弱，靠數量
	enemy.portrait_path = "res://assets/art/enemies/rat_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "啃咬 6 + 蠱毒 1", "effects": [{"kind": "damage", "amount": 6}, {"kind": "poison", "amount": 1}]},
		{"intent": "鼠群竄 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "鑽縫 6", "effects": [{"kind": "block", "amount": 6}]}
	]
	return enemy

static func _bully() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "bully"
	enemy.display_name = "惡霸"
	enemy.max_hp = 64
	enemy.portrait_path = "res://assets/art/enemies/bully.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "橫行霸道 15（35%暈眩）", "effects": [{"kind": "damage", "amount": 15}, {"kind": "stun_chance", "amount": 1, "chance": 0.35}]},
		{"intent": "推搡 11 + 破綻 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "仗勢 14", "effects": [{"kind": "block", "amount": 14}]}
	]
	return enemy

# === 將軍塚 / 試煉窟補充小怪（PAL1 正史怪；借用既有肖像，專屬美術見 ART_TODO） ===
static func _earth_imp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "earth_imp"
	enemy.portrait_scale = 0.82  # 小型：小土鬼（借 rock_guardian 圖）
	enemy.display_name = "小土鬼"
	enemy.max_hp = 46
	enemy.portrait_path = "res://assets/art/enemies/earth_imp.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "泥拳 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "擲石 10 + 破綻 1", "effects": [{"kind": "damage", "amount": 10}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "遁土 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _blood_worm() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "blood_worm"
	enemy.portrait_scale = 0.85  # 小型：血口蟲（借 toxic_centipede 圖）
	enemy.display_name = "血口蟲"
	enemy.max_hp = 52
	enemy.portrait_path = "res://assets/art/enemies/blood_worm.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "吸血咬 13", "effects": [{"kind": "damage", "amount": 13}]},
		{"intent": "血口噴 11 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 11}, {"kind": "poison", "amount": 3}]},
		{"intent": "蠕伏 9", "effects": [{"kind": "block", "amount": 9}]}
	]
	return enemy

static func _venom_spider() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "venom_spider"
	enemy.portrait_scale = 0.9  # 試煉窟：五毒蜘蛛（借 grass_spider 圖）
	enemy.display_name = "五毒蜘蛛"
	enemy.max_hp = 58
	enemy.portrait_path = "res://assets/art/enemies/venom_spider.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "毒絲咬 12 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 12}, {"kind": "poison", "amount": 3}]},
		{"intent": "蛛網纏 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "疾爬 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _fire_toad() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "fire_toad"
	enemy.display_name = "食火蟾"
	enemy.max_hp = 64
	enemy.portrait_path = "res://assets/art/enemies/fire_toad.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "噴火舌 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "灼毒 11 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 11}, {"kind": "poison", "amount": 2}]},
		{"intent": "鼓腹 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func bosses() -> Array[EnemyData]:
	return [_moon_worshipper(), _centipede_lord(), _witch_queen(),
		_red_eye_demon(), _zombie_general(), _baiyue_lord(),
		_miao_chieftain(), _tomb_general(), _zhenyu_mingwang()]

# Multi-Enemy Mode：召喚物（minions）— 由 boss 召喚出來的弱化版敵人
static func minions() -> Array[EnemyData]:
	return [_water_tentacle(), _red_eye_imp(), _zombie_thrall(), _centipede_brood(), _tower_wisp(), _miao_soldier(), _fox_demon()]

# 統一 id → EnemyData 查表，給 BattleController.spawn_enemy 與其他系統用
static func enemy_by_id(id: String) -> EnemyData:
	if id.is_empty():
		return null
	for e: EnemyData in enemies():
		if e.id == id:
			return e
	for b: EnemyData in bosses():
		if b.id == id:
			return b
	for m: EnemyData in minions():
		if m.id == id:
			return m
	return null

# 八幕（PAL1 劇情順序）：餘杭 → 仙靈島 → 蘇州 → 將軍塚 → 試煉窟 → 鎖妖塔 → 苗疆 → 拜月
static func enemies_for_act(act: int) -> Array[EnemyData]:
	match act:
		1: return [_bandit(), _beast(), _wild_bee(), _bee_cocoon(), _leaf_sprite(), _thief(), _viper(), _green_snake(), _grass_spider(), _lantern_ghost()] # 餘杭山間
		2: return [_serpent_demon(), _fox_spirit(), _sword_spirit(), _cave_bat(), _water_imp(), _grass_sprite(), _miao_soldier(), _miao_maiden(), _viper(), _man_eating_flower(), _baby_toad()] # 仙靈島（黑苗血洗仙靈島，苗兵/苗女登場；樹妖移至第 7 幕）
		3: return [_bandit(), _thug(), _thief(), _female_thief(), _cleaver_granny(), _gambler(), _lecher_thief(), _bully(), _rat_demon()] # 蘇州城（市井人類為主 + 城中鼠妖）
		4: return [_zombie_soldier(), _ancient_evil_spirit(), _skeleton_soldier(), _grave_fire(), _earth_imp(), _blood_worm(), _cleaver_granny(), _flying_skull(), _vampire_giant()] # 將軍塚
		5: return [_rock_guardian(), _trial_swordshade(), _jumping_frog(), _venom_spider(), _fire_toad(), _gourd_sage(), _scorpion(), _fire_kirin_whelp(), _ice_beast()] # 試煉窟（跳跳蛙/五毒蜘蛛/食火蟾為正史怪；塔妖/刑天/無常只在鎖妖塔）
		6: return [_tower_demon(), _tower_ghost_soldier(), _ancient_evil_spirit(), _xing_tian(), _black_impermanence(), _white_impermanence(), _flying_skull(), _gourd_sage(), _five_eyed_demon(), _unicorn_demon(), _pincer_demon(), _jumping_frog()] # 鎖妖塔
		7: return [_gu_cultist(), _miao_soldier(), _miao_maiden(), _serpent_demon(), _toxic_centipede(), _tree_demon(), _man_eating_flower(), _puppet_girl(), _birdman(), _demihuman_villager()] # 苗疆蠱土
		8: return [_moon_worshipper(), _baiyue_guard(), _miao_soldier(), _miao_maiden(), _octopus_imp(), _clam_spirit(), _conch_maiden(), _turtle_demon(), _ancient_evil_spirit(), _puppet_girl()] # 拜月決戰（水底迷宮水族 + 拜月/黑苗）
	return [_bandit(), _beast()]

# 精英敵人候選：取該幕一般敵中 max_hp 最高的前 3 名（精英 = 強化版一般戰，不另造敵人）。
static func elites_for_act(act: int) -> Array[EnemyData]:
	var pool: Array[EnemyData] = enemies_for_act(act)
	pool.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.max_hp > b.max_hp)
	var out: Array[EnemyData] = []
	for i: int in range(min(3, pool.size())):
		out.append(pool[i])
	return out

static func boss_for_act(act: int) -> EnemyData:
	match act:
		1: return _red_eye_demon()      # 餘杭山間：蛇妖男（以隱龍窟正史 boss 代替原創山魈）
		2: return _miao_chieftain()     # 仙靈島：黑苗頭領（正史·血洗仙靈島擄靈兒）
		3: return _zombie_general()     # 蘇州城：殭屍王
		4: return _tomb_general()       # 將軍塚：赤鬼王
		5: return _witch_queen()        # 火麒麟洞：火眼麒麟
		6: return _zhenyu_mingwang()    # 鎖妖塔：鎮獄明王（正史）
		7: return _centipede_lord()     # 苗疆蠱土：石長老
		8: return _baiyue_lord()        # 拜月決戰：拜月教主 → 水魔獸（phase 2）
	return _red_eye_demon()

static func _li_xiaoyao() -> CharacterData:
	# PAL1 對齊版本：
	# - 萬劍訣 (PAL1 Lv7) → uncommon
	# - 天師符法 (PAL1 Lv12) → uncommon
	# - 新增 氣療術（PAL1 初登場 75 HP heal）、冰心訣（手卷 解狀態）
	var cards: Array[CardData] = [
		make_card("lxy_yujian", "御劍術", "李逍遙", 1, "attack", "造成 7 點傷害。", [{"kind": "damage", "amount": 7}]),
		make_card("lxy_wanjian", "萬劍訣", "李逍遙", 2, "attack", "萬劍齊飛，對全體敵人造成 5 點傷害三次。", [{"kind": "damage_all", "amount": 5, "hits": 3}], "uncommon"),
		make_card("lxy_feilong", "飛龍探雲手", "李逍遙", 1, "skill", "造成 4 點傷害，抽 1 張牌，回復 1 點靈力，並從敵人身上偷取一件物品。", [{"kind": "damage", "amount": 4}, {"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}, {"kind": "steal"}]),
		make_card("lxy_tianshi", "天師符法", "李逍遙", 1, "attack", "符法天降，對全體敵人造成 9 點法術傷害。", [{"kind": "damage_all", "amount": 9}], "uncommon"),
		make_card("lxy_jiushen", "酒神咒", "李逍遙", 3, "attack", "造成 28 點傷害，自身承受 8 點反噬。", [{"kind": "damage", "amount": 28}, {"kind": "self_damage", "amount": 8}], "rare"),
		make_card("lxy_xianfeng", "仙風雲體", "李逍遙", 1, "skill", "獲得 8 點護體，抽 1 張牌。", [{"kind": "block", "amount": 8}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_zuimeng", "醉夢望月", "李逍遙", 2, "power", "本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("lxy_jianqi", "劍氣成牆", "李逍遙", 1, "skill", "獲得 8 點護體。", [{"kind": "block", "amount": 8}]),
		make_card("lxy_linghuo", "靈火符", "李逍遙", 1, "attack", "造成 6 點傷害，施加 1 層破綻。", [{"kind": "damage", "amount": 6}, {"kind": "vulnerable", "amount": 1}], "uncommon"),
		make_card("lxy_xiaoyao_you", "逍遙遊", "李逍遙", 0, "skill", "抽 1 張牌並回復 1 點靈力。", [{"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}], "rare"),
		make_card("lxy_jianzhen", "八方劍陣", "李逍遙", 2, "attack", "困敵於劍陣之中，造成 6 點傷害並機率性使敵人暈眩一回合。", [{"kind": "damage", "amount": 6}, {"kind": "stun", "amount": 1, "chance": 0.5}], "uncommon"),
		make_card("lxy_liepo", "裂魄斬", "李逍遙", 1, "attack", "造成 10 點傷害，使敵人虛弱 1 層。", [{"kind": "damage", "amount": 10}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("lxy_qingfeng", "清風御劍", "李逍遙", 1, "skill", "獲得 5 點護體，抽 2 張牌。", [{"kind": "block", "amount": 5}, {"kind": "draw", "amount": 2}], "uncommon"),
		make_card("lxy_jiulong", "九龍訣", "李逍遙", 3, "attack", "御劍三式如九龍出海，造成 12 點傷害三次。", [{"kind": "damage", "amount": 12, "hits": 3}], "rare"),
		make_card("lxy_zuilong", "醉龍翻江", "李逍遙", 2, "attack", "造成 18 點傷害，自身承受 5 點反噬，抽 1 張牌。", [{"kind": "damage", "amount": 18}, {"kind": "self_damage", "amount": 5}, {"kind": "draw", "amount": 1}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片，未來再補正式插圖）
		make_card("lxy_qiliao", "氣療術", "李逍遙", 1, "skill", "回復 6 點生命。", [{"kind": "heal", "amount": 6}], "basic"),
		make_card("lxy_bingxin", "冰心訣", "李逍遙", 1, "skill", "清除自身全部負面狀態，獲得 3 點護體。", [{"kind": "cure_debuff"}, {"kind": "block", "amount": 3}], "basic"),
		# 劍流（御劍術連擊）：與烈火令／純鈞劍／龍泉劍 synergy；每段各吃力量
		make_card("lxy_wanjianguizong", "萬劍歸宗", "李逍遙", 1, "attack", "御劍齊出歸於一念，對全體敵人造成 4 點傷害三次。", [{"kind": "damage_all", "amount": 4, "hits": 3}], "uncommon"),
		make_card("lxy_jianshen", "人劍合一", "李逍遙", 2, "power", "人劍合一，本場戰鬥傷害提升 2，獲得 6 點護體。", [{"kind": "power", "amount": 2}, {"kind": "block", "amount": 6}], "rare"),
		make_card("lxy_tiangangqi", "天罡氣", "李逍遙", 1, "skill", "凝聚天罡護身之氣，獲得 9 點護體，抽 1 張牌。", [{"kind": "block", "amount": 9}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_tianjian", "天劍出鞘", "李逍遙", 2, "attack", "天劍出鞘，對全體敵人造成 20 點傷害。", [{"kind": "damage_all", "amount": 20}], "rare"),
		make_card("lxy_xiaoyao_shenjian", "逍遙神劍", "李逍遙", 3, "attack", "御出逍遙神劍，造成 10 點傷害兩次，抽 2 張牌。", [{"kind": "damage", "amount": 10, "hits": 2}, {"kind": "draw", "amount": 2}], "rare"),
		make_card("lxy_yuanlinggui", "元靈歸心術", "李逍遙", 2, "skill", "元靈歸心，回復 7 點生命並獲得 10 點護體。", [{"kind": "heal", "amount": 7}, {"kind": "block", "amount": 10}], "uncommon", "lyr_yuanlinggui"),
		make_card("lxy_zhenyuan", "真元凝聚", "李逍遙", 1, "skill", "凝聚真元之氣，抽 2 張牌並回復 4 點生命。", [{"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 4}], "uncommon"),
		make_card("lxy_jinchan_ls", "金蟬脫殼", "李逍遙", 1, "skill", "金蟬脫殼，獲得 12 點護體，抽 2 張牌，回復 6 點生命。打出後消耗。", [{"kind": "block", "amount": 12}, {"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 6}], "rare", "", false, true),
		make_card("lxy_ningyuan_ls", "凝元化神", "李逍遙", 2, "power", "凝聚本源化為神氣，本場戰鬥傷害提升 3，回復 8 點生命。", [{"kind": "power", "amount": 3}, {"kind": "heal", "amount": 8}], "rare"),
		# 連打牌組（0 費 / 減靈耗升級）：御劍連擊軸，art 暫借既有劍系卡
		make_card("lxy_jianjue", "信手一劍", "李逍遙", 0, "attack", "造成 4 點傷害。", [{"kind": "damage", "amount": 4}], "basic"),
		make_card("lxy_huijian", "乘風引氣", "李逍遙", 0, "attack", "造成 3 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 3}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_yufengbu", "御風步", "李逍遙", 0, "skill", "獲得 4 點護體。", [{"kind": "block", "amount": 4}], "basic"),
		# 御劍 setup / 靈犀（StS Setup/Vigor + Demon Form）
		make_card("lxy_xujian", "蓄劍式", "李逍遙", 1, "skill", "蓄勢御劍，下一張攻擊牌傷害變為 2 倍。", [{"kind": "next_attack_mult", "amount": 2}], "uncommon", "", true),
		make_card("lxy_jianyi", "靈犀訣", "李逍遙", 2, "power", "靈犀漸明，每回合開始攻擊力 +1。", [{"kind": "power_per_turn", "amount": 1}], "rare", "", true),
		# 牌庫操作（StS Armaments+ / Dual Wield / Shiv）
		make_card("lxy_linzhen", "臨陣磨槍", "李逍遙", 1, "skill", "臨陣磨礪，將手上所有牌升級（本場戰鬥）。", [{"kind": "upgrade_hand"}], "rare", "", true),
		make_card("lxy_xiangcheng", "御劍相承", "李逍遙", 1, "skill", "御劍化形，複製手上一張攻擊牌。", [{"kind": "copy_attack"}], "uncommon", "", true),
		make_card("lxy_jianqizonghen", "劍氣縱橫", "李逍遙", 1, "skill", "劍氣化形，生成 3 道「劍氣」置於抽牌堆頂。", [{"kind": "spawn_top_tokens", "amount": 3}], "uncommon"),
		# 幽冥仙途語感（明心劍宗）：青煙竹影＝節節拔升多段劍。art 暫借八方劍陣
		make_card("lxy_qingyan_zhuying", "青煙竹影", "李逍遙", 2, "attack", "劍勢如新筍出土節節拔升，造成 4 點傷害四次。", [{"kind": "damage", "amount": 4, "hits": 4}], "uncommon"),
		# 劍流引擎核心：御劍心訣 —— 每出攻擊牌抽 1，接上既有 0 費攻擊 / 複製攻擊 / 劍氣置頂 →「御劍不滅」連打循環。
		make_card("lxy_yujianxinjue", "御劍心訣", "李逍遙", 1, "power", "心與劍合，本場戰鬥每打出一張攻擊牌便抽 1 張牌。", [{"kind": "draw_on_attack", "amount": 1}], "rare", "", true),
	]
	var character: CharacterData = _character("li_xiaoyao", "李逍遙", 74, "劍仙風流，禦劍、偷取與酒神系高風險高傷害。", cards)
	# PAL1 對齊：9 basic + 3 uncommon + 0 rare
	# 加 萬劍訣 (PAL1 Lv7 早期可習) 作為 burst attack，否則對 boss 過弱
	character.starting_deck = [
		cards[0], cards[0], cards[0],     # 3x 御劍術 (山神廟 basic 7dmg)
		cards[15],                         # 1x 氣療術 (初登場 basic heal6)
		cards[8],                          # 1x 靈火符 (uncommon 6dmg+破綻1) — 補李逍遙早期直傷、減一張純補
		cards[16],                         # 1x 冰心訣 (手卷 basic cure_debuff+3block)
		cards[2],                          # 1x 飛龍探雲手 (手卷 basic 4dmg+steal+draw+energy)
		cards[7], cards[7],                # 2x 劍氣成牆 (basic 8block)
		cards[1],                          # 1x 萬劍訣 (PAL1 Lv7 uncommon 5x3=15 burst)
		cards[5],                          # 1x 仙風雲體 (蜀山 uncommon 8block+draw1)
		cards[6],                          # 1x 醉夢望月 (蜀山 uncommon power+2)
	]
	# 修：index 0-4 中未進起手的卡（reward_pool=slice(5) 會漏掉）補進獎勵池，否則永遠拿不到
	character.reward_pool.append(cards[3])  # 天師符法
	character.reward_pool.append(cards[4])  # 酒神咒
	return character

static func _zhao_linger() -> CharacterData:
	# PAL1 對齊版本：
	# - 新增 金剛咒（初登場 增防禦）、冰咒（初登場 初級冰，與 Lv9 玄冰咒區分）、
	#   炎咒（初登場 初級火）、冰心訣（初登場 解狀態）
	# - 天雷破 (PAL1 Lv22) → rare（從 uncommon 升）
	var cards: Array[CardData] = [
		make_card("zl_guanyin", "觀音咒", "趙靈兒", 1, "skill", "回復 6 點生命。", [{"kind": "heal", "amount": 6}]),
		make_card("zl_wuqi", "五氣朝元", "趙靈兒", 2, "skill", "全體仙術。全隊回復 7 點生命，自身獲得 6 點護體。", [{"kind": "heal_party", "amount": 7}, {"kind": "block", "amount": 6}], "uncommon"),
		make_card("zl_xuanbing", "玄冰咒", "趙靈兒", 1, "attack", "玄冰寒徹全場，對全體敵人造成 6 點傷害並使其虛弱 2 層。", [{"kind": "damage_all", "amount": 6}, {"kind": "weak_all", "amount": 2}], "uncommon"),
		make_card("zl_leizhou", "雷咒", "趙靈兒", 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}]),
		make_card("zl_mengshe", "夢蛇靈印", "趙靈兒", 2, "power", "夢蛇之力凝為靈印，本場戰鬥傷害提升 2，回復 4 點生命並抽 1 張牌。", [{"kind": "power", "amount": 2}, {"kind": "heal", "amount": 4}, {"kind": "draw", "amount": 1}], "rare"),
		make_card("zl_fengling", "風靈符", "趙靈兒", 0, "skill", "抽 1 張牌。", [{"kind": "draw", "amount": 1}], "uncommon"),
		make_card("zl_tianlei", "天雷破", "趙靈兒", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("zl_lingguang", "靈光護體", "趙靈兒", 1, "skill", "獲得 8 點護體。", [{"kind": "block", "amount": 8}]),
		make_card("zl_huanyu", "幻雨咒", "趙靈兒", 1, "skill", "獲得 7 點護體，使敵人虛弱 1 層。", [{"kind": "block", "amount": 7}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("zl_nvwa", "女媧靈息", "趙靈兒", 2, "power", "回復 6 點生命，本場戰鬥傷害提升 2。", [{"kind": "heal", "amount": 6}, {"kind": "power", "amount": 2}], "rare"),
		make_card("zl_huihun", "還魂咒", "趙靈兒", 2, "skill", "救回 1 名倒下的同伴（30 HP 上場）；若無人倒下，改為自己回復 30 生命。", [{"kind": "revive", "amount": 30}], "rare"),
		make_card("zl_shuiling", "明鏡止水", "趙靈兒", 2, "skill", "回復 6 點生命並獲得 8 點護體。", [{"kind": "heal", "amount": 6}, {"kind": "block", "amount": 8}], "uncommon"),
		make_card("zl_leiguang", "紫電連珠", "趙靈兒", 1, "attack", "雷光雙擊，造成 4 點傷害兩次，使敵人虛弱 1 層。", [{"kind": "damage", "amount": 4}, {"kind": "damage", "amount": 4}, {"kind": "weak", "amount": 1}]),
		make_card("zl_lingxi", "靈息吐納", "趙靈兒", 1, "skill", "抽 2 張牌並回復 4 點生命。", [{"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 4}], "uncommon"),
		make_card("zl_shenlei", "神雷降世", "趙靈兒", 3, "attack", "天降神雷，造成 20 點傷害並機率性使敵人暈眩一回合。", [{"kind": "damage", "amount": 20}, {"kind": "stun", "amount": 1, "chance": 0.6}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片）
		make_card("zl_jingang", "金剛咒", "趙靈兒", 1, "skill", "獲得 8 點護體（道家護身咒術）。", [{"kind": "block", "amount": 8}], "basic"),
		make_card("zl_bingzhou", "冰咒", "趙靈兒", 1, "attack", "初級冰系仙術，造成 6 點傷害並使敵人虛弱 1 層。", [{"kind": "damage", "amount": 6}, {"kind": "weak", "amount": 1}], "basic"),
		make_card("zl_yanzhou", "炎咒", "趙靈兒", 1, "attack", "初級火系仙術，造成 8 點傷害並施加 1 層破綻。", [{"kind": "damage", "amount": 8}, {"kind": "vulnerable", "amount": 1}], "basic"),
		make_card("zl_bingxin", "冰心訣", "趙靈兒", 1, "skill", "清除自身全部負面狀態，獲得 3 點護體。", [{"kind": "cure_debuff"}, {"kind": "block", "amount": 3}], "basic"),
		# 杖流 payoff：對虛弱/破綻敵加傷（與冰咒/炎咒/玄冰咒/幻雨咒 synergy）
		make_card("zl_shuiyin", "水靈封印", "趙靈兒", 2, "attack", "造成 5 點傷害（目標每層虛弱或破綻 +3 點傷害）並封印其法術 1 回合（無法施法）。", [{"kind": "damage_debuff_bonus", "amount": 5, "bonus_per_layer": 3}, {"kind": "silence", "amount": 1}], "uncommon"),
		# 治療+護體一體（杖流續戰：靈族慈悲化作護身）
		make_card("zl_ganlin", "甘霖咒", "趙靈兒", 1, "skill", "回復 6 點生命並獲得 6 點護體。", [{"kind": "heal", "amount": 6}, {"kind": "block", "amount": 6}], "uncommon"),
		make_card("zl_diliebeng", "地裂崩", "趙靈兒", 3, "attack", "大地崩裂，對全體敵人造成 15 點傷害。", [{"kind": "damage_all", "amount": 15}], "rare"),
		make_card("zl_fengxuebing", "風雪冰天", "趙靈兒", 1, "attack", "風雪冰天席捲，對全體敵人造成 8 點傷害並使其虛弱 2 層。", [{"kind": "damage_all", "amount": 8}, {"kind": "weak_all", "amount": 2}], "uncommon"),
		make_card("zl_kuanglei", "狂雷破", "趙靈兒", 2, "attack", "天雷狂擊，對全體敵人造成 11 點傷害兩次。", [{"kind": "damage_all", "amount": 11, "hits": 2}], "rare"),
		make_card("zl_sanmeizhenhuo", "三昧真火", "趙靈兒", 2, "attack", "三昧真火燃天，對全體敵人造成 10 點傷害並施加 2 層破綻。", [{"kind": "damage_all", "amount": 10}, {"kind": "vulnerable_all", "amount": 2}], "rare"),
		make_card("zl_taishan", "泰山壓頂", "趙靈兒", 2, "attack", "泰山壓頂之勢，對全體敵人造成 20 點傷害並施加 2 層破綻。", [{"kind": "damage_all", "amount": 20}, {"kind": "vulnerable_all", "amount": 2}], "rare"),
		make_card("zl_wuleizhou", "五雷咒", "趙靈兒", 3, "attack", "五雷齊降，對全體敵人造成 6 點傷害五次。", [{"kind": "damage_all", "amount": 6, "hits": 5}], "rare"),
		make_card("zl_xuanfengzhou", "旋風咒", "趙靈兒", 1, "skill", "旋風捲場，獲得 10 點護體，使全體敵人虛弱 1 層。", [{"kind": "block", "amount": 10}, {"kind": "weak_all", "amount": 1}], "uncommon"),
		make_card("zl_mengshe_ls", "夢蛇靈印★", "趙靈兒", 2, "power", "夢蛇靈印大成，本場戰鬥傷害提升 3，回復 6 點生命，抽 2 張牌。", [{"kind": "power", "amount": 3}, {"kind": "heal", "amount": 6}, {"kind": "draw", "amount": 2}], "rare"),
		# 連打牌組（0 費 / 減靈耗升級）：連咒軸，art 暫借既有仙術卡
		make_card("zl_xiaoleizhou", "小雷咒", "趙靈兒", 0, "attack", "造成 4 點傷害。", [{"kind": "damage", "amount": 4}]),
		make_card("zl_yinlingfu", "引靈符", "趙靈兒", 0, "skill", "抽 1 張牌並獲得 2 點護體。", [{"kind": "draw", "amount": 1}, {"kind": "block", "amount": 2}], "uncommon"),
		make_card("zl_huguangzhou", "琉璃護光", "趙靈兒", 0, "skill", "獲得 4 點護體。", [{"kind": "block", "amount": 4}]),
		make_card("zl_lianzhuzhou", "連珠雷咒", "趙靈兒", 1, "attack", "造成 5 點傷害兩次。", [{"kind": "damage", "amount": 5, "hits": 2}], "uncommon", "", true),
		# 靈族神術引擎（StS Entrench / Metallicize / Combust，art 暫借既有仙術卡）
		make_card("zl_juling", "聚靈訣", "趙靈兒", 1, "skill", "聚斂靈氣，當前護體翻倍。", [{"kind": "block_multiply", "amount": 2}], "uncommon", "", true),
		make_card("zl_lingguangpuzhao", "靈光普照", "趙靈兒", 1, "power", "靈光普照，每回合開始獲得 5 點護體。", [{"kind": "block_per_turn", "amount": 5}], "uncommon"),
		make_card("zl_wuleihongding", "五雷轟頂", "趙靈兒", 2, "power", "凝聚天雷，每回合開始對所有敵人降下 6 點雷傷。", [{"kind": "end_turn_damage_all", "amount": 6}], "rare"),
		# 神術引擎核心：靈息訣 —— 每出技能牌抽 1，接上既有 0 費技能 →「靈息不息」循環。
		make_card("zl_lingxijue", "靈息訣", "趙靈兒", 1, "power", "靈息綿長，本場戰鬥每打出一張技能牌便抽 1 張牌。", [{"kind": "draw_on_skill", "amount": 1}], "rare", "", true),
		# 杖流 payoff：萬靈噬 —— 對全體依各自虛弱/破綻層數加傷，承接她大量的 weak_all / vulnerable_all 鋪場。
		make_card("zl_wanlingshi", "萬靈噬", "趙靈兒", 2, "attack", "五靈反噬，對所有敵人造成 6 點傷害，敵人每層虛弱／破綻額外 +4。", [{"kind": "damage_debuff_bonus_all", "amount": 6, "bonus_per_layer": 4}], "rare"),
		# 護咒（Artifact）source：靈族護身咒術，結護咒層擋下敵人施加的負面狀態（含蠱毒），art 已補齊專屬圖
		make_card("zl_huxinzhou", "護心咒", "趙靈兒", 1, "skill", "結 2 層護咒（每層擋下敵人施加的一個負面狀態，含蠱毒），並獲得 5 點護體。", [{"kind": "player_artifact", "amount": 2}, {"kind": "block", "amount": 5}], "uncommon"),
	]
	var character: CharacterData = _character("zhao_linger", "趙靈兒", 68, "五靈仙術、治療、護盾、解狀態與長戰持續。", cards)
	# PAL1 對齊：9 basic + 3 uncommon + 0 rare
	# 加 天雷破 (PAL1 Lv22) 作為 boss burst — uncommon 18dmg
	character.starting_deck = [
		cards[3], cards[3], cards[3],     # 3x 雷咒 (初登場 basic 10dmg；被動 +3 力 → 實打 13)
		cards[0], cards[0],                # 2x 觀音咒 (初登場 basic heal6)
		cards[15],                         # 1x 金剛咒 (初登場 basic 8block)
		cards[16],                         # 1x 冰咒 (初登場 basic 6dmg+weak1)
		cards[17],                         # 1x 炎咒 (初登場 basic 8dmg+vuln1)
		cards[18],                         # 1x 冰心訣 (初登場 basic cure_debuff+3block)
		cards[1],                          # 1x 五氣朝元 (PAL1 Lv8 uncommon 全隊回7+6block)
		cards[6],                          # 1x 天雷破 (uncommon 18dmg) — burst
		cards[8],                          # 1x 幻雨咒 (uncommon 7block+weak1)
	]
	# 修：補進獎勵池，否則永遠拿不到（reward_pool=slice(5) 漏掉的 index 0-4 非起手卡）
	character.reward_pool.append(cards[2])  # 玄冰咒
	character.reward_pool.append(cards[4])  # 夢蛇靈印
	return character

static func _lin_yueru() -> CharacterData:
	# PAL1 對齊版本：
	# - 凝神歸元 是她 PAL1 初登場就會的特色（HP 220）！補上
	# - 一陽指 (PAL1 Lv7) 保持 uncommon
	# - 萬里狂沙 (PAL1 Lv35) 是 rare（已是）
	var cards: Array[CardData] = [
		make_card("lyr_qijianzhi", "氣劍指", "林月如", 1, "attack", "凝氣為劍，對全體敵人造成 8 點傷害。", [{"kind": "damage_all", "amount": 8}]),
		make_card("lyr_yiyang", "一陽指", "林月如", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("lyr_zhanlong", "斬龍訣", "林月如", 3, "attack", "斬龍訣橫掃，對全體敵人造成 30 點傷害。", [{"kind": "damage_all", "amount": 30}], "rare"),
		make_card("lyr_qiankun", "乾坤一擲", "林月如", 0, "attack", "消耗全部靈力，每點對全體敵人造成 9 點傷害。", [{"kind": "consume_energy_damage_all", "amount": 9}], "rare"),
		make_card("lyr_fanji", "回鋒劍", "林月如", 1, "skill", "獲得 8 點護體並造成 5 點傷害。", [{"kind": "block", "amount": 8}, {"kind": "damage", "amount": 5}]),
		make_card("lyr_bianying", "劍影重重", "林月如", 1, "attack", "造成 4 點傷害兩次，施加 1 層破綻。", [{"kind": "damage", "amount": 4}, {"kind": "damage", "amount": 4}, {"kind": "vulnerable", "amount": 1}]),
		make_card("lyr_shenfa", "月影身法", "林月如", 1, "skill", "獲得 7 點護體，抽 1 張牌。", [{"kind": "block", "amount": 7}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_juesha", "索命一劍", "林月如", 2, "attack", "造成 14 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		# 2026-07-10 砍白開水：亂雲連斬（3×3 無特色，與銅錢鏢 4×3 重複；銅錢鏢是 PAL1 正典留下）
		make_card("lyr_jinchan", "四兩撥千斤", "林月如", 1, "skill", "獲得 5 點護體，抽 2 張牌。", [{"kind": "block", "amount": 5}, {"kind": "draw", "amount": 2}], "rare"),
		make_card("lyr_xuanjian", "旋劍花舞", "林月如", 1, "attack", "造成 5 點傷害兩次。", [{"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}]),
		make_card("lyr_kuaijian", "流光快劍", "林月如", 0, "attack", "造成 6 點傷害。", [{"kind": "damage", "amount": 6}], "uncommon"),
		make_card("lyr_poqian", "破軍劍", "林月如", 2, "attack", "造成 20 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 20}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tianv", "飛花亂舞", "林月如", 1, "attack", "造成 4 點傷害，施加 1 層破綻，抽 1 張牌。", [{"kind": "damage", "amount": 4}, {"kind": "vulnerable", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tieyi", "鐵衣功", "林月如", 2, "skill", "獲得 15 點護體。", [{"kind": "block", "amount": 15}], "rare"),
		# PAL1 初登場新增（她原作 Lv1 就會凝神歸元 HP 220 治療，是她的特色；art 暫借）
		# 2026-07-10 改消耗牌：1費回8無限重複×起手兩張=長戰永動機（違反支柱3），
		# 每場戰鬥每張只能回一次血（先前口頭決議補落地）
		make_card("lyr_ningshen", "凝神歸元", "林月如", 1, "skill", "凝神運氣，回復 8 點生命。打出後消耗。", [{"kind": "heal", "amount": 8}], "basic", "", false, true),
		# 反擊流（鳳鳴刀／Thorns）：被攻擊時反彈傷害給攻擊者（不衰減，跨回合）
		make_card("lyr_fenghuan", "鳳鳴反擊", "林月如", 1, "power", "本場戰鬥獲得 3 點荊棘（被攻擊時反彈傷害給攻擊者）。", [{"kind": "thorns", "amount": 3}], "uncommon"),
		make_card("lyr_yuehua", "月華護體", "林月如", 1, "skill", "獲得 6 點護體與 1 點荊棘。", [{"kind": "block", "amount": 6}, {"kind": "thorns", "amount": 1}], "uncommon"),
		make_card("lyr_lielong", "烈龍衝擊", "林月如", 3, "attack", "烈龍衝撞，造成 24 點傷害並機率性使敵人暈眩一回合。", [{"kind": "damage", "amount": 24}, {"kind": "stun", "amount": 1, "chance": 0.6}], "rare"),
		make_card("lyr_qijuejianqi", "七訣劍氣", "林月如", 1, "attack", "七訣劍氣縱橫，對全體敵人造成 9 點傷害並施加 1 層破綻，抽 1 張牌。", [{"kind": "damage_all", "amount": 9}, {"kind": "vulnerable_all", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tongqianbiao", "銅錢鏢", "林月如", 1, "attack", "擲出三枚銅錢鏢，造成 4 點傷害三次。", [{"kind": "damage", "amount": 4, "hits": 3}], "uncommon"),
		make_card("lyr_wanlikuang", "萬里狂沙", "林月如", 2, "skill", "狂沙漫天，對全體敵人施加 3 層破綻，抽 1 張牌。", [{"kind": "vulnerable_all", "amount": 3}, {"kind": "draw", "amount": 1}], "rare"),
		make_card("lyr_yuanlinggui", "元靈歸心術", "林月如", 2, "skill", "元靈歸心，回復 6 點生命並獲得 12 點護體。", [{"kind": "heal", "amount": 6}, {"kind": "block", "amount": 12}], "uncommon"),
		# 連打牌組（0 費）：鞭劍連擊軸
		# 2026-07-10 砍白開水：驚鴻一點（0費4傷純數字，與流光快劍/拈花一劍三胞胎）、
		# 鴛鴦雙劍（5×2 與旋劍花舞完全同款）
		make_card("lyr_huaci", "拈花一劍", "林月如", 0, "attack", "造成 3 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 3}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_qiebushan", "凌波微步", "林月如", 0, "skill", "獲得 4 點護體。", [{"kind": "block", "amount": 4}]),
		# 反擊軸（thorns 複用，做成 payoff）：荊棘流錨點
		make_card("lyr_shuangren", "霜刃反擊", "林月如", 1, "skill", "凝霜於刃，獲得 8 點荊棘（被攻擊時反彈傷害給攻擊者）。", [{"kind": "thorns", "amount": 8}], "uncommon"),
		# 連武架式 / 鐵骨（StS Demon Form 護體版 / Dexterity）
		make_card("lyr_jianwu", "劍舞架式", "林月如", 1, "power", "舞劍成勢，本場戰鬥每出一張攻擊牌獲得 3 點護體。", [{"kind": "block_per_attack", "amount": 3}], "uncommon"),
		make_card("lyr_tiegu", "鐵骨樁", "林月如", 1, "power", "紮穩鐵骨樁步，本場戰鬥每次獲得護體額外 +2。", [{"kind": "self_block_bonus", "amount": 2}], "uncommon"),
		# debuff payoff（破綻/虛弱越多打越痛）：呼應她的萬里狂沙/索命一劍堆破綻 → 一劍爆發。
		make_card("lyr_suohun", "索魂十三劍", "林月如", 2, "attack", "趁敵頹勢連刺，造成 6 點傷害；敵人每層虛弱與破綻額外造成 3 點傷害。", [{"kind": "damage_debuff_bonus", "amount": 6, "bonus_per_layer": 3}], "uncommon"),
	]
	var character: CharacterData = _character("lin_yueru", "林月如", 72, "鞭劍武學、連擊、反擊與內勁治療。", cards)
	# PAL1 對齊：10 basic + 2 uncommon + 0 rare
	# ⚠️ cards[N] 是位置索引：增刪上方卡片清單時，index 8（原亂雲連斬）以後的索引會位移
	character.starting_deck = [
		cards[0], cards[0], cards[0], cards[0],   # 4x 氣劍指 (初登場 basic 8dmg)
		cards[14], cards[14],                      # 2x 凝神歸元 (初登場 basic heal8)
		cards[4], cards[4],                        # 2x 回身反擊 (basic 8block+5dmg)
		cards[9], cards[9],                        # 2x 旋劍花舞 (basic 5x2)
		cards[1],                                   # 1x 一陽指 (PAL1 Lv7 uncommon 18dmg)
		cards[6],                                   # 1x 月影身法 (uncommon 7block+draw1)
	]
	# 修：補進獎勵池，否則永遠拿不到（PAL1 名招斬龍訣、乾坤一擲先前被 slice(5) 漏掉）
	character.reward_pool.append(cards[2])  # 斬龍訣（PAL1 名招）
	character.reward_pool.append(cards[3])  # 乾坤一擲
	return character

static func _anu() -> CharacterData:
	# PAL1 對齊版本：
	# - 命名對齊：解毒咒 = 清除負面狀態（cure_debuff），靈血咒 = 回血（heal+block）
	# - 新增 鬼降（PAL1 初登場 瘋魔 5 回合 → 簡化為 敵人虛弱 3）
	# - 萬蟻蝕象 PAL1 Lv30 → 升 uncommon
	# - 爆炸蠱 PAL1 Lv33 → 已是 uncommon（維持）
	var cards: Array[CardData] = [
		make_card("anu_yufeng", "御蜂術", "阿奴", 1, "attack", "笛音引毒蜂群，對全體敵人造成 3 點傷害三次。", [{"kind": "damage_all", "amount": 3, "hits": 3}]),
		make_card("anu_wanyi", "萬蟻蝕象", "阿奴", 1, "skill", "萬蟻齊出，對所有敵人施加 4 層蠱毒。", [{"kind": "poison_all", "amount": 4}], "uncommon"),
		make_card("anu_mihun", "醉蝶迷魂", "阿奴", 1, "skill", "蝶粉惑敵，封印其法術 2 回合（無法施法）並使其虛弱 1 層。", [{"kind": "silence", "amount": 2}, {"kind": "weak", "amount": 1}]),
		make_card("anu_baozhagu", "毒卵迸裂", "阿奴", 2, "attack", "引爆全部蠱毒，每層造成 3 點傷害。", [{"kind": "poison_burst", "amount": 3}], "uncommon"),
		make_card("anu_lingxue", "靈血咒", "阿奴", 1, "skill", "苗疆靈血續命之術，回復 5 點生命並獲得 3 點護體。", [{"kind": "heal", "amount": 5}, {"kind": "block", "amount": 3}]),
		make_card("anu_jiedu", "解毒咒", "阿奴", 1, "skill", "清除自身全部負面狀態，抽 1 張牌。", [{"kind": "cure_debuff"}, {"kind": "draw", "amount": 1}]),
		make_card("anu_guling", "金蠶結甲", "阿奴", 1, "skill", "獲得 9 點護體。", [{"kind": "block", "amount": 9}], "uncommon"),
		make_card("anu_wangyou", "忘憂蠱", "阿奴", 2, "skill", "施加 4 層蠱毒與 2 層破綻。", [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("anu_duwu", "毒霧繚繞", "阿奴", 1, "skill", "施加 2 層蠱毒，使敵人虛弱 1 層。", [{"kind": "poison", "amount": 2}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("anu_guxue", "以血飼毒", "阿奴", 2, "power", "本場戰鬥傷害提升 1，施加 5 層蠱毒。", [{"kind": "power", "amount": 1}, {"kind": "poison", "amount": 5}], "rare"),
		make_card("anu_baizu", "百足蠱", "阿奴", 2, "skill", "施加 8 層蠱毒。", [{"kind": "poison", "amount": 8}], "uncommon"),
		make_card("anu_duzhen", "毒針連射", "阿奴", 1, "attack", "造成 5 點傷害，施加 2 層蠱毒。", [{"kind": "damage", "amount": 5}, {"kind": "poison", "amount": 2}], "uncommon"),
		make_card("anu_guwang", "懾魂巫音", "阿奴", 1, "skill", "巫音懾魂，封印敵人法術 1 回合（無法施法）並使其虛弱 1 層。", [{"kind": "silence", "amount": 1}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("anu_sanmao", "斑蝥噬心", "阿奴", 2, "skill", "施加 5 層蠱毒，使敵人虛弱 2 層。", [{"kind": "poison", "amount": 5}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("anu_gushen", "蠱神附體", "阿奴", 3, "power", "本場戰鬥傷害提升 3，施加 4 層蠱毒。", [{"kind": "power", "amount": 3}, {"kind": "poison", "amount": 4}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片）
		make_card("anu_guijiang", "鬼降", "阿奴", 1, "skill", "苗疆咒術，使敵人陷入瘋魔 1 回合（失控隨機攻擊，可能誤擊友軍）並虛弱 1 層。", [{"kind": "berserk", "amount": 1}, {"kind": "weak", "amount": 1}], "basic"),
		# 刀流（巫月神刀）：力量 + 連擊軸。淬鋒疊力量，連斬牌每段各吃力量 → 越疊越痛。
		# art 暫借既有阿奴卡（未來補正式插圖）
		make_card("anu_cuifeng", "淬鋒蠱刃", "阿奴", 1, "power", "刀刃淬入蠱毒，本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("anu_wuyuezhan", "巫月斬", "阿奴", 1, "attack", "巫月神刀連斬，造成 5 點傷害兩次。", [{"kind": "damage", "amount": 5, "hits": 2}], "uncommon"),
		make_card("anu_xuerenwu", "血刃亂舞", "阿奴", 2, "attack", "亂刀狂舞，造成 4 點傷害三次。", [{"kind": "damage", "amount": 4, "hits": 3}], "rare"),
		make_card("anu_duohun", "奪魂術", "阿奴", 1, "attack", "勾魂奪命，憑運氣定生死。對小怪有 20% 機率當場索命；對 Boss 則有機率施加隨機負面狀態與隨機層數（亦可能毫無作用）。", [{"kind": "soul_reap", "chance": 0.2, "boss_effect_chance": 0.65, "boss_min": 1, "boss_max": 4}], "uncommon", "", true),
		make_card("anu_sanshigu", "三屍蠱", "阿奴", 2, "skill", "三屍蠱毒入體，施加 10 層蠱毒。", [{"kind": "poison", "amount": 10}], "rare"),
		make_card("anu_shuhun", "聖姑庇佑", "阿奴", 1, "power", "術魂加持，本場戰鬥傷害提升 1，抽 1 張牌。", [{"kind": "power", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("anu_wangushitian", "萬蠱噬天", "阿奴", 3, "skill", "萬蠱齊發，施加 12 層蠱毒，使敵人虛弱 3 層。", [{"kind": "poison", "amount": 12}, {"kind": "weak", "amount": 3}], "rare"),
		make_card("anu_wanyi_ls", "萬蟻蝕骨", "阿奴", 1, "skill", "萬蟻蝕骨，施加 8 層蠱毒。", [{"kind": "poison", "amount": 8}], "rare"),
		make_card("anu_yanshazhou", "燃殺咒", "阿奴", 2, "attack", "燃殺之咒，造成 14 點傷害並施加 3 層蠱毒。", [{"kind": "damage", "amount": 14}, {"kind": "poison", "amount": 3}], "uncommon"),
		# 毒引擎（StS Noxious Fumes 式）：阿奴蠱術的核心——放出蠱蟲化瘴，每回合自動疊毒，
		# 讓她不必每回合花牌施毒、騰出手牌防禦。art 暫借百足蠱。
		make_card("anu_guzhang", "蠱瘴瀰漫", "阿奴", 1, "power", "放出蠱蟲化作毒瘴，每回合開始時對所有敵人施加 3 層蠱毒。", [{"kind": "poison_engine", "amount": 3}], "uncommon"),
		# 連打牌組（0 費 / 減靈耗升級）：蠱毒連擊軸，art 暫借既有蠱術卡
		make_card("anu_sandu", "散蠱", "阿奴", 0, "skill", "施加 2 層蠱毒。", [{"kind": "poison", "amount": 2}]),
		make_card("anu_yindu", "引蠱", "阿奴", 0, "attack", "造成 3 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 3}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("anu_huguzhao", "逆影遁法", "阿奴", 0, "skill", "獲得 4 點護體。", [{"kind": "block", "amount": 4}]),
		make_card("anu_lianduzhen", "攢針亂射", "阿奴", 1, "attack", "造成 3 點傷害兩次，施加 1 層蠱毒。", [{"kind": "damage", "amount": 3, "hits": 2}, {"kind": "poison", "amount": 1}], "uncommon", "", true),
		# 毒流 combo 三張（StS Catalyst / Noxious / Sporic 對齊，art 暫借既有蠱術卡）：
		# 蠱毒催化＝翻倍毒層、蠱刃淬煉＝攻擊無格擋敵人疊毒、蠱蟲寄屍＝死敵殘毒轉移（多敵 combo）。
		make_card("anu_cuihua", "毒入膏肓", "阿奴", 1, "skill", "使目標敵人的蠱毒層數變為 2 倍。", [{"kind": "poison_multiply", "amount": 2}], "rare"),
		make_card("anu_gudaocui", "五毒淬刃", "阿奴", 1, "power", "攻擊無格擋的敵人時，每次攻擊施加 1 層蠱毒（多段攻擊每段各 1 層）。", [{"kind": "poison_on_attack", "amount": 1}], "uncommon", "", true),
		make_card("anu_jishigu", "借屍還蠱", "阿奴", 1, "power", "中毒的敵人死亡時，將其殘餘蠱毒隨機轉移給另一個敵人。", [{"kind": "corpse_poison"}], "uncommon", "", true),
		# 鬼／冥 系（苗巫邪術·厲鬼冥河）：已補正式插圖
		make_card("anu_guiling_zhuansheng", "鬼靈轉生", "阿奴", 2, "skill", "驅鬼靈轉生，救回 1 名倒下的同伴（25 HP 上場）；若無人倒下，改為自己回復 25 生命。", [{"kind": "revive", "amount": 25}], "rare"),
		make_card("anu_minghe_yindu", "冥河引渡", "阿奴", 2, "attack", "冥河引渡亡魂，對全體敵人造成 8 點傷害並施加 3 層蠱毒。", [{"kind": "damage_all", "amount": 8}, {"kind": "poison_all", "amount": 3}], "rare"),
		make_card("anu_suoming_egui", "幽魂噬影", "阿奴", 1, "attack", "幽魂噬影撲身，造成 9 點傷害並使敵人虛弱 2 層。", [{"kind": "damage", "amount": 9}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("anu_youming_shigu", "幽冥蝕骨", "阿奴", 2, "skill", "幽冥之毒蝕骨，施加 7 層蠱毒並使敵人破綻 2 層。", [{"kind": "poison", "amount": 7}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("anu_guihuo_liaoyuan", "鬼火燎原", "阿奴", 3, "attack", "鬼火燎原，對全體敵人造成 7 點傷害兩次並施加 2 層蠱毒。", [{"kind": "damage_all", "amount": 7, "hits": 2}, {"kind": "poison_all", "amount": 2}], "rare"),
		# 蝶毒群控（呼應單體的「醉蝶迷魂」，補阿奴缺的 AOE 虛弱）：art 暫借醉蝶迷魂
		make_card("anu_huadie_guimeng", "化蝶歸夢", "阿奴", 1, "skill", "化蝶入夢，使全體敵人虛弱 2 層並抽 1 張牌。", [{"kind": "weak_all", "amount": 2}, {"kind": "draw", "amount": 1}], "uncommon"),
		# 蠱毒 payoff（疊毒爆發）：傷害隨敵蠱毒層數成長、且毒不消耗（持續 tick）→ 獎勵阿奴疊毒。
		make_card("anu_guxue_shixin", "蠱血噬心", "阿奴", 2, "attack", "驅蠱入血，造成 6 點傷害；敵人每層蠱毒額外造成 2 點傷害（蠱毒不消耗）。", [{"kind": "damage_poison_bonus", "amount": 6, "bonus_per_layer": 2}], "rare"),
	]
	# HP 66→82：阿奴是「長戰持續傷害」毒龜流，毒需要時間 ramp+tick，必須夠肉才撐得到
	# 毒生效（pilot 實測：66 HP 對上 +15% 傷害的多敵戰撐不過 3 回合就被消耗死）。
	var character: CharacterData = _character("anu", "阿奴", 82, "苗疆巫女。巫術通蠱、驅鬼、攝魂、巫醫——蠱毒只是其一，長於纏戰削弱。", cards)
	# PAL1 對齊：10 basic + 2 uncommon + 0 rare
	# 御蜂術 ×3 → ×2（4 hits 連擊堆疊太快，每張 12 dmg + 觸發毒 tick 過強）
	# 平衡修正（2026-06，run_simulator 揭露）：原起始牌組 13 張有 8 張純治療/淨化/
	# 虛弱、唯一攻擊只有 2x 御蜂術，毒疊不起來 → 殺速過慢 → 帶傷續戰被消耗致死
	# （全 run 清關率僅 15%）。改成有實際毒流 win-con：加 2x 毒針連射(攻擊+毒)、
	# 1x 萬蟻蝕象(毒 ramp)，砍掉冗餘的治療/淨化牌。
	# 毒流 win-con（StS Silent / Noxious Fumes 流對齊）：毒引擎被動疊毒 + 防禦續命 +
	# 爆炸蠱 burst payoff。蠱瘴瀰漫(引擎)讓她不必每回合花牌施毒、騰出手牌防禦。
	character.starting_deck = [
		cards[0],                          # 1x 御蜂術 (basic damage_all 3x3)
		cards[25],                         # 1x 蠱瘴瀰漫 (uncommon poison_engine 2/回合) — 毒引擎
		cards[11], cards[11],              # 2x 毒針連射 (uncommon 5 傷害 + 2 蠱毒) — 早期輸出
		cards[3],                          # 1x 爆炸蠱 (uncommon poison_burst ×3) — 毒爆 payoff
		cards[1],                          # 1x 萬蟻蝕象 (uncommon 毒 5) — 毒 ramp
		cards[8],                          # 1x 毒霧繚繞 (uncommon 2poison+weak1)
		cards[2],                          # 1x 迷魂術 (basic 3 weak)
		cards[4], cards[4],                # 2x 靈血咒 (basic 5heal+3block)
		cards[5],                          # 1x 解毒咒 (basic cure_debuff+draw1)
		cards[6],                          # 1x 蠱靈護身 (uncommon 12block)
	]
	return character

static func _character(id: String, display_name: String, max_hp: int, style: String, cards: Array[CardData]) -> CharacterData:
	var character: CharacterData = CharacterData.new()
	character.id = id
	character.display_name = display_name
	character.max_hp = max_hp
	character.battle_style = style
	character.portrait_path = "res://assets/art/portraits/%s.png" % id
	character.starting_deck = [cards[0], cards[0], cards[0], cards[0], cards[1], cards[2], cards[3], cards[4], cards[7], cards[7], cards[7], cards[7]]
	character.reward_pool = cards.slice(5)
	character.all_defined_cards = cards  # 全部定義卡（供 smoke 驗證無不可取得卡）
	character.passives = _passives_for(id)
	return character

static func _passives_for(id: String) -> Array[Dictionary]:
	match id:
		"li_xiaoyao":
			return [{
				"trigger": "first_attack_cost",
				"amount": 1,
				# 2026-06 平衡：每場 1 次 → 戰鬥前 3 回合每回合 1 次。
				# 每場版 mid 勝率 3%（墊底）、無限每回合版 73%（衝頂），前 3 回合版取中間帶。
				"label": "戰鬥前 3 回合，每回合第一張攻擊牌費用 -1",
				"status_label": "下一張攻擊牌費用 -1"
			}]
		"zhao_linger":
			return [{
				"trigger": "battle_start",
				"kind": "self_power",
				"amount": 3,
				"label": "靈台啟明：每場戰鬥開始攻擊提升 3",
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
				# 2026-06 平衡驗證：試過 5→3，mid 勝率僅 83→80（毒 DoT 賽跑贏在牌組毒卡、
				# 不在開場層數）——nerf 無實效、損蠱術 identity，維持 5
				# 2026-06-11 重審（BattlePolicy 會玩毒了）再試 5→4：mid 因 RNG 流向反跳 100、
				# Lv20 僅 -3 —— 開場層數確定不是阿奴的檔位閘（兩代 AI 結論一致），維持 5。
				# 她的強度在毒引擎+引爆時機，要 nerf 得動引爆倍率或 boss 端淨化，見 BALANCE_REPORT §七。
				"amount": 5,
				"label": "下蠱（巫術之一）：敵人每場戰鬥開場受到 5 層蠱毒"
			}]
	return []

static func loot_table_for(enemy_id: String) -> Array[Dictionary]:
	match enemy_id:
		"bandit":
			return [
				{"type": "gold",   "amount": 40,          "display_name": "40 銅錢"},
				{"type": "potion", "potion_id": "huichun_dan",  "display_name": "回春丹"},
				{"type": "potion", "potion_id": "jinchuang_yao","display_name": "金瘡藥"},
			]
		"gu_cultist":
			return [
				{"type": "potion", "potion_id": "jiedu_san",  "display_name": "解毒散"},
				{"type": "potion", "potion_id": "lingshe_dan","display_name": "靈蛇膽"},
			]
		"sword_spirit":
			return [
				{"type": "potion", "potion_id": "lingli_dan", "display_name": "靈力丹"},
				{"type": "potion", "potion_id": "huti_fu",    "display_name": "護體符"},
			]
		"fox_spirit":
			return [
				{"type": "potion", "potion_id": "yuehun_cao", "display_name": "月魂草"},
				{"type": "potion", "potion_id": "lingli_dan", "display_name": "靈力丹"},
			]
		"serpent_demon":
			return [
				{"type": "potion", "potion_id": "lingshe_dan","display_name": "靈蛇膽"},
				{"type": "potion", "potion_id": "jiedu_san",  "display_name": "解毒散"},
			]
		"zombie_soldier":
			return [
				{"type": "potion", "potion_id": "huti_fu",    "display_name": "護體符"},
				{"type": "gold",   "amount": 20,              "display_name": "20 銅錢"},
			]
		"toxic_centipede":
			return [
				{"type": "potion", "potion_id": "jiedu_san",  "display_name": "解毒散"},
				{"type": "potion", "potion_id": "hugu_jiu",   "display_name": "虎骨酒"},
			]
		"tower_demon":
			return [
				{"type": "potion", "potion_id": "huti_fu",    "display_name": "護體符"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"tower_ghost_soldier":
			return [
				{"type": "potion", "potion_id": "lingli_dan", "display_name": "靈力丹"},
				{"type": "potion", "potion_id": "huti_fu",    "display_name": "護體符"},
			]
		"baiyue_guard":
			return [
				{"type": "potion", "potion_id": "jinchuang_yao","display_name": "金瘡藥"},
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
			]
		# Bosses — 稀有掉落
		"moon_worshipper":
			return [
				{"type": "potion", "potion_id": "yuehun_cao",   "display_name": "月魂草"},
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
			]
		"centipede_lord":
			return [
				{"type": "potion", "potion_id": "jiedu_san",    "display_name": "解毒散"},
				{"type": "potion", "potion_id": "xianren_xue",  "display_name": "仙人遺血"},
			]
		"witch_queen":
			return [
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
			]
		"flower_spirit":
			return [
				{"type": "potion", "potion_id": "yuehun_cao",   "display_name": "月魂草"},
				{"type": "potion", "potion_id": "lingli_dan",   "display_name": "靈力丹"},
				{"type": "gold",   "amount": 30,                "display_name": "30 銅錢"},
			]
		"red_eye_demon":
			return [
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
				{"type": "potion", "potion_id": "hugu_jiu",      "display_name": "虎骨酒"},
			]
		"zombie_general":
			return [
				{"type": "potion", "potion_id": "jinchuang_yao","display_name": "金瘡藥"},
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
			]
		"baiyue_lord":
			return [
				{"type": "potion", "potion_id": "xianren_xue",  "display_name": "仙人遺血"},
				{"type": "potion", "potion_id": "yuehun_cao",   "display_name": "月魂草"},
			]
		"thief":
			return [
				{"type": "gold",   "amount": 50,              "display_name": "50 銅錢"},
				{"type": "potion", "potion_id": "jinchuang_yao","display_name": "金瘡藥"},
			]
		"tree_demon":
			return [
				{"type": "potion", "potion_id": "xiongdan_jiu", "display_name": "雄膽酒"},
				{"type": "potion", "potion_id": "jiedu_san",   "display_name": "解毒散"},
			]
		"xing_tian":
			return [
				{"type": "potion", "potion_id": "lingli_dan",   "display_name": "靈力丹"},
				{"type": "gold",   "amount": 30,              "display_name": "30 銅錢"},
			]
		"black_impermanence":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
			]
		"white_impermanence":
			return [
				{"type": "potion", "potion_id": "jiedu_san",    "display_name": "解毒散"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"viper":
			return [
				{"type": "potion", "potion_id": "xiongdan_jiu", "display_name": "雄膽酒"},
				{"type": "potion", "potion_id": "jiedu_cao",   "display_name": "解毒草"},
			]
		"flying_skull":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "gold",   "amount": 20,              "display_name": "20 銅錢"},
			]
		"cleaver_granny":
			return [
				{"type": "gold",   "amount": 35,              "display_name": "35 銅錢"},
				{"type": "potion", "potion_id": "shexiang_wan", "display_name": "麝香丸"},
			]
		"man_eating_flower":
			return [
				{"type": "potion", "potion_id": "xiongdan_jiu", "display_name": "雄膽酒"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"gourd_sage":
			return [
				{"type": "potion", "potion_id": "lingli_dan",   "display_name": "靈力丹"},
				{"type": "potion", "potion_id": "xiancha_san",  "display_name": "仙茶散"},
			]
		"puppet_girl":
			return [
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
				{"type": "potion", "potion_id": "duhuo_dan",    "display_name": "毒活丸"},
			]
		"green_snake":
			return [
				{"type": "potion", "potion_id": "jiedu_cao",    "display_name": "解毒草"},
				{"type": "gold",   "amount": 15,              "display_name": "15 銅錢"},
			]
		"grass_spider":
			return [
				{"type": "potion", "potion_id": "jiedu_cao",    "display_name": "解毒草"},
				{"type": "gold",   "amount": 10,              "display_name": "10 銅錢"},
			]
		"lantern_ghost":
			return [
				{"type": "potion", "potion_id": "shexiang_wan", "display_name": "麝香丸"},
				{"type": "gold",   "amount": 12,              "display_name": "12 銅錢"},
			]
		"hydra_snake":
			return [
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"flying_snake":
			return [
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
				{"type": "gold",   "amount": 20,              "display_name": "20 銅錢"},
			]
		"baby_toad":
			return [
				{"type": "potion", "potion_id": "jiedu_cao",    "display_name": "解毒草"},
				{"type": "gold",   "amount": 18,              "display_name": "18 銅錢"},
			]
		"poison_toad":
			return [
				{"type": "potion", "potion_id": "jiedu_san",    "display_name": "解毒散"},
				{"type": "gold",   "amount": 22,              "display_name": "22 銅錢"},
			]
		"vampire_giant":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "gold",   "amount": 30,              "display_name": "30 銅錢"},
			]
		"scorpion":
			return [
				{"type": "potion", "potion_id": "jiedu_san",    "display_name": "解毒散"},
				{"type": "gold",   "amount": 20,              "display_name": "20 銅錢"},
			]
		"female_thief":
			return [
				{"type": "potion", "potion_id": "jinchuang_yao","display_name": "金瘡藥"},
				{"type": "gold",   "amount": 60,              "display_name": "60 銅錢"},
			]
		"birdman":
			return [
				{"type": "potion", "potion_id": "xiancha_san",  "display_name": "仙茶散"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"demihuman_villager":
			return [
				{"type": "potion", "potion_id": "xiongdan_jiu", "display_name": "雄膽酒"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"five_eyed_demon":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
			]
		"unicorn_demon":
			return [
				{"type": "potion", "potion_id": "hugu_jiu",     "display_name": "虎骨酒"},
				{"type": "gold",   "amount": 30,              "display_name": "30 銅錢"},
			]
		"pincer_demon":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "gold",   "amount": 30,              "display_name": "30 銅錢"},
			]
		"jumping_frog":
			return [
				{"type": "potion", "potion_id": "jiedu_san",    "display_name": "解毒散"},
				{"type": "gold",   "amount": 20,              "display_name": "20 銅錢"},
			]
		"fire_kirin_whelp":
			return [
				{"type": "potion", "potion_id": "hugu_jiu",     "display_name": "虎骨酒"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"ice_beast":
			return [
				{"type": "potion", "potion_id": "huti_fu",      "display_name": "護體符"},
				{"type": "gold",   "amount": 25,              "display_name": "25 銅錢"},
			]
		"man_eater_beast":
			return [
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
				{"type": "gold",   "amount": 35,              "display_name": "35 銅錢"},
			]
		"two_headed_snake":
			return [
				{"type": "potion", "potion_id": "lingshe_dan",  "display_name": "靈蛇膽"},
				{"type": "gold",   "amount": 30,              "display_name": "30 銅錢"},
			]
	return []

static func _bandit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "bandit"
	enemy.display_name = "山賊頭目"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/bandit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "劈砍 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "防守 10", "effects": [{"kind": "block", "amount": 10}]},
		{"intent": "猛擊 21", "effects": [{"kind": "damage", "amount": 21}]}
	]
	return enemy

static func _beast() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "beast"
	enemy.portrait_scale = 1.1  # 偏大：野獸
	enemy.display_name = "山林妖獸"
	enemy.max_hp = 80
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "撕咬 17", "effects": [{"kind": "damage", "amount": 17}]},
		{"intent": "怒吼 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "撲擊 26", "effects": [{"kind": "damage", "amount": 26}]}
	]
	return enemy

# ── PAL1 小怪補充（八幕擴充）：借用近似肖像，專屬美術見 ART_TODO「六、B」──
# 餘杭/十里坡：野蜂（PAL1 十里坡名怪「蜜蜂」）
static func _wild_bee() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "wild_bee"
	enemy.portrait_scale = 0.78  # 小型：野蜂
	enemy.display_name = "十里坡野蜂"
	enemy.max_hp = 48
	enemy.portrait_path = "res://assets/art/enemies/wild_bee.png"  # 專屬野蜂美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "螫刺 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "亂舞 6 + 虛弱 1", "effects": [{"kind": "damage", "amount": 6}, {"kind": "weak", "amount": 1}]},
		{"intent": "振翅 7", "effects": [{"kind": "block", "amount": 7}]}
	]
	return enemy

# 仙靈島：洞窟噬血蝠（PAL1 仙靈島/洞窟蝙蝠）
static func _cave_bat() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "cave_bat"
	enemy.portrait_scale = 0.8  # 小型：洞穴蝙蝠
	enemy.display_name = "噬血蝠"
	enemy.max_hp = 58
	enemy.portrait_path = "res://assets/art/enemies/cave_bat.png"  # 專屬蝙蝠美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "撲咬 13", "effects": [{"kind": "damage", "amount": 13}]},
		{"intent": "吸血 10", "effects": [{"kind": "damage", "amount": 10}]},
		{"intent": "亂飛閃避 11", "effects": [{"kind": "block", "amount": 11}]}
	]
	return enemy

# 仙靈島：水妖（PAL1 仙靈島水族小妖）
static func _water_imp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "water_imp"
	enemy.display_name = "靈島水妖"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/water_imp.png"  # 專屬水妖美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "水箭 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "纏縛 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "水幕護身 13", "effects": [{"kind": "block", "amount": 13}]}
	]
	return enemy

# 將軍塚：骷髏兵（PAL1 經典不死系小怪）
static func _skeleton_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "skeleton_soldier"
	enemy.display_name = "塚中骷髏兵"
	enemy.max_hp = 82
	enemy.portrait_path = "res://assets/art/enemies/skeleton_soldier.png"  # 專屬骷髏兵美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "鏽刀劈 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "白骨盾 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "亂骨突刺 11 + 破綻 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "vulnerable", "amount": 1}]}
	]
	return enemy

# 將軍塚：塚中鬼火（PAL1「鬼火」）
static func _grave_fire() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "grave_fire"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.display_name = "塚中鬼火"
	enemy.max_hp = 64
	enemy.portrait_path = "res://assets/art/enemies/grave_fire.png"  # 專屬鬼火美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "幽焰 15 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 15}, {"kind": "poison", "amount": 2}]},
		{"intent": "鬼火縈繞 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "飄忽不定 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

# 試煉窟：石靈守衛（PAL1「石頭怪」，高護體）
static func _rock_guardian() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "rock_guardian"
	enemy.default_facing_left = true  # 原圖面向左，戰鬥中不再翻轉
	enemy.portrait_scale = 1.2  # 大型：石守衛
	enemy.display_name = "試煉石靈"
	enemy.max_hp = 100
	enemy.portrait_path = "res://assets/art/enemies/rock_guardian.png"  # 專屬石靈美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "巨岩砸 19", "effects": [{"kind": "damage", "amount": 19}]},
		{"intent": "岩甲 22", "effects": [{"kind": "block", "amount": 22}]},
		{"intent": "崩石 14 + 破綻 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "怒岩漸盛 攻擊力+4", "effects": [{"kind": "enemy_strength", "amount": 4}]}
	]
	return enemy

# 試煉窟：試煉劍靈（PAL1 試煉窟守護劍意）
static func _trial_swordshade() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "trial_swordshade"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.display_name = "試煉劍靈"
	enemy.max_hp = 86
	enemy.portrait_path = "res://assets/art/enemies/trial_swordshade.png"  # 專屬試煉劍靈美術
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "試煉劍芒 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "御劍守勢 15", "effects": [{"kind": "block", "amount": 15}]},
		{"intent": "破式斬 13 + 虛弱 1", "effects": [{"kind": "damage", "amount": 13}, {"kind": "weak", "amount": 1}]}
	]
	return enemy

static func _gu_cultist() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "gu_cultist"
	enemy.display_name = "蠱毒妖人"
	enemy.max_hp = 72
	enemy.portrait_path = "res://assets/art/enemies/gu_cultist.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "毒霧 4", "effects": [{"kind": "poison", "amount": 4}]},
		{"intent": "邪術 14", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 1}]},
		{"intent": "殘蠱降身", "effects": [{"kind": "gain_curse_player", "curse_id": "gu_du"}]}
	]
	return enemy

static func _sword_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "sword_spirit"
	enemy.display_name = "劍冢靈影"
	enemy.max_hp = 78
	enemy.portrait_path = "res://assets/art/enemies/sword_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "劍芒 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "護劍 11", "effects": [{"kind": "block", "amount": 11}]},
		{"intent": "破勢 12", "effects": [{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 1}]}
	]
	return enemy

static func _fox_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "fox_spirit"
	enemy.display_name = "魅狐幻影"
	enemy.max_hp = 65
	enemy.portrait_path = "res://assets/art/enemies/fox_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "魅惑 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "幻爪 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "遁形 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _flower_spirit_enemy() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "flower_spirit"
	enemy.display_name = "花妖"
	enemy.max_hp = 46
	enemy.portrait_path = "res://assets/art/enemies/flower_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "迷香 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "花瓣刺 9", "effects": [{"kind": "damage", "amount": 9}]},
		{"intent": "魅惑破綻", "effects": [{"kind": "vulnerable", "amount": 1}, {"kind": "block", "amount": 8}]},
	]
	return enemy

static func flower_spirit_enemy() -> EnemyData:
	return _flower_spirit_enemy()

static func _serpent_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "serpent_demon"
	enemy.display_name = "赤蛇妖"
	enemy.max_hp = 88
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "毒牙 14", "effects": [{"kind": "damage", "amount": 14}, {"kind": "poison", "amount": 3}]},
		{"intent": "盤身 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "蛇吻 22", "effects": [{"kind": "damage", "amount": 22}]},
		{"intent": "蛇蛻回春 回14 + 防8", "effects": [{"kind": "enemy_heal", "amount": 14}, {"kind": "block", "amount": 8}]}
	]
	return enemy

static func _moon_worshipper() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "moon_worshipper"
	enemy.display_name = "拜月教徒"
	enemy.max_hp = 105
	enemy.portrait_path = "res://assets/art/enemies/moon_worshipper.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "拜月咒 20", "effects": [{"kind": "damage", "amount": 20}]},
		{"intent": "妖術：蠱毒 5", "effects": [{"kind": "poison", "amount": 5}]},
		{"intent": "結界 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "邪月重擊 29", "effects": [{"kind": "damage", "amount": 29}]}
	]
	enemy.phase_2_actions = [
		{"intent": "月蝕重擊 25 + 虛弱 2", "effects": [
			{"kind": "damage", "amount": 25},
			{"kind": "weak", "amount": 2}
		]},
		{"intent": "邪結界 20", "effects": [{"kind": "block", "amount": 20}]},
		{"intent": "拜月狂咒 35", "effects": [{"kind": "damage", "amount": 35}]}
	]
	return enemy

static func _centipede_lord() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "centipede_lord"
	enemy.portrait_scale = 1.25  # boss：石長老（暫沿用舊圖，後續補正專屬立繪）
	enemy.display_name = "石長老"
	enemy.max_hp = 108
	enemy.portrait_path = "res://assets/art/enemies/centipede_lord.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "苗刀連斬 9x3", "effects": [
			{"kind": "damage", "amount": 9},
			{"kind": "damage", "amount": 9},
			{"kind": "damage", "amount": 9}
		]},
		{"intent": "毒砂掌 17 + 蠱毒 4", "effects": [
			{"kind": "damage", "amount": 17},
			{"kind": "poison", "amount": 4}
		]},
		# 機制（狀態反轉，act 7 boss・蠱毒之王）：吞噬自身蠱毒每 2 層化 1 力量——
		# 毒流到苗疆撞上「毒物剋星」，無毒時此招≈只剩護體
		{"intent": "百毒歸宗", "effects": [{"kind": "absorb_poison"}, {"kind": "block", "amount": 8}]},
		{"intent": "黑苗軍陣 18", "effects": [{"kind": "block", "amount": 18}]},
		{"intent": "攝魂咒 24 + 虛弱 1", "effects": [
			{"kind": "damage", "amount": 24},
			{"kind": "weak", "amount": 1}
		]}
	]
	enemy.phase_2_display_name = "赤血毒焰"
	enemy.phase_2_portrait_path = "res://assets/art/enemies/centipede_lord_phase2.png"
	enemy.phase_2_actions = [
		{"intent": "赤血烈掌 10x3", "effects": [
			{"kind": "damage", "amount": 10},
			{"kind": "damage", "amount": 10},
			{"kind": "damage", "amount": 10}
		]},
		{"intent": "虯龍拳 29", "effects": [{"kind": "damage", "amount": 29}]},
		{"intent": "毒焰爆散 蠱毒 6 + 破綻 2", "effects": [
			{"kind": "poison", "amount": 6},
			{"kind": "vulnerable", "amount": 2}
		]},
		{"intent": "召喚苗槍卒", "effects": [{"kind": "summon", "count": 1}]}
	]
	enemy.summon_pool = ["miao_soldier"]
	return enemy

static func _witch_queen() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "witch_queen"
	enemy.portrait_scale = 1.85  # 原作低伏四足 Boss，橫向占滿敵人區
	enemy.display_name = "火麒麟"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/fire_qilin_pal1_v1.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "麒麟火 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "炎息 虛弱 2", "effects": [{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 2}]},
		{"intent": "火靈護體 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "烈焰撲殺 20 + 破綻 1", "effects": [
			{"kind": "damage", "amount": 20},
			{"kind": "vulnerable", "amount": 1}
		]}
	]
	# PAL1 中開戰時就已是火眼麒麟，戰後才化為麒麟老人；不使用半血變身。
	# 機制（蓄力釋放，act 5 boss）：每 4 回合「炎獄吐息」30，預警可見
	enemy.ultimate_every = 4
	enemy.ultimate_action = {"intent": "炎獄吐息 30", "effects": [{"kind": "damage", "amount": 30}]}
	return enemy

static func _zombie_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zombie_soldier"
	enemy.display_name = "地底殭屍"
	enemy.max_hp = 78
	enemy.portrait_path = "res://assets/art/enemies/zombie_soldier.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "腐爛爪 14 + 虛弱 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 1}]},
		{"intent": "殭步衝 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "死硬護 13", "effects": [{"kind": "block", "amount": 13}]}
	]
	return enemy

static func _toxic_centipede() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "toxic_centipede"
	enemy.default_facing_left = true  # 原圖面向左，戰鬥中不再翻轉
	enemy.portrait_scale = 0.88  # 小型：毒蜈蚣
	enemy.display_name = "毒蜈蚣"
	enemy.max_hp = 69
	enemy.portrait_path = "res://assets/art/enemies/toxic_centipede.png"
	enemy.actions = [
		{"intent": "毒噬 13 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 13}, {"kind": "poison", "amount": 3}]},
		{"intent": "多足撲 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "蛻甲 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _tower_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tower_demon"
	enemy.portrait_scale = 1.15  # 偏大：鎖妖塔妖
	enemy.display_name = "塔中封魔"
	enemy.max_hp = 90
	enemy.portrait_path = "res://assets/art/enemies/tower_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "邪焰 15 + 破綻 1", "effects": [{"kind": "damage", "amount": 15}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "衝擊 22", "effects": [{"kind": "damage", "amount": 22}]},
		{"intent": "封魔護 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "封魔蓄力 攻擊力+5", "effects": [{"kind": "enemy_strength", "amount": 5}]}
	]
	return enemy

static func _tower_ghost_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tower_ghost_soldier"
	enemy.display_name = "鎖妖塔鬼兵"
	enemy.max_hp = 81
	enemy.portrait_path = "res://assets/art/enemies/tower_ghost_soldier.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "魂刃 16 + 虛弱 1", "effects": [{"kind": "damage", "amount": 16}, {"kind": "weak", "amount": 1}]},
		{"intent": "鬼卒衝 21", "effects": [{"kind": "damage", "amount": 21}]},
		{"intent": "幻影遁 11", "effects": [{"kind": "block", "amount": 11}]}
	]
	return enemy

static func _baiyue_guard() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "baiyue_guard"
	enemy.display_name = "拜月教衛"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/baiyue_guard.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "拜月斬 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "邪毒 蠱毒 4 + 破綻 1", "effects": [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "教衛盾 15", "effects": [{"kind": "block", "amount": 15}]}
	]
	return enemy

static func _ancient_evil_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "ancient_evil_spirit"
	enemy.portrait_scale = 1.15  # 偏大：上古邪靈
	enemy.display_name = "上古惡靈"
	enemy.max_hp = 85
	enemy.portrait_path = "res://assets/art/enemies/ancient_evil_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "噬魂 15 + 虛弱 1", "effects": [{"kind": "damage", "amount": 15}, {"kind": "weak", "amount": 1}]},
		{"intent": "邪氣蝕 16 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 16}, {"kind": "poison", "amount": 3}]},
		{"intent": "邪盾 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _red_eye_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "red_eye_demon"
	enemy.portrait_scale = 1.3  # boss：蛇妖男（phase 2 對位狐妖女）
	enemy.display_name = "蛇妖男"
	enemy.max_hp = 95
	enemy.portrait_path = "res://assets/art/enemies/red_eye_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "妖蛇噬咬 14 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 14}, {"kind": "poison", "amount": 2}]},
		{"intent": "蛇息纏身 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "尾掃 17 + 破綻 1", "effects": [{"kind": "damage", "amount": 17}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "盤身絞殺 10+10", "effects": [{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}]}
	]
	# 隱龍窟正史：蛇妖男與狐妖女是兩隻接續的妖（不是同隻半血變身）。
	# 擊殺蛇妖男 → 狐妖女滿血登場接續打。
	enemy.successor = "fox_demon"
	return enemy

# 狐妖女（隱龍窟雙妖之二）：蛇妖男死後接續登場的第二隻 boss。
static func _fox_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "fox_demon"
	enemy.portrait_scale = 1.25  # boss：狐妖女
	enemy.display_name = "狐妖女"
	enemy.max_hp = 90
	enemy.portrait_path = "res://assets/art/enemies/red_eye_demon_phase2.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "狐火魅襲 21 + 虛弱 1", "effects": [{"kind": "damage", "amount": 21}, {"kind": "weak", "amount": 1}]},
		{"intent": "妖狐幻爪 26", "effects": [{"kind": "damage", "amount": 26}]},
		{"intent": "魅香 蠱毒 4 + 破綻 2", "effects": [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 2}]},
		{"intent": "血怒漸盛 攻擊力+4", "effects": [{"kind": "enemy_strength", "amount": 4}]}
	]
	return enemy

static func _zombie_general() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zombie_general"
	enemy.portrait_scale = 1.35  # boss：殭屍王
	enemy.display_name = "殭屍王"
	enemy.max_hp = 106
	enemy.portrait_path = "res://assets/art/enemies/zombie_general.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "鬼將劈砍 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "腐臭毒氣 蠱毒 5", "effects": [{"kind": "poison", "amount": 5}]},
		{"intent": "屍甲護衛 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "千年寒氣 14 + 虛弱 2", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 2}]}
	]
	# 機制（倒數計時，act 3 boss 主場）：屍變——出手 4 次後力量 +8。
	# 開戰即告示，整場變成「在屍變前打出多少血線」的賽跑，不能慢慢磨
	enemy.passive = {"kind": "enrage_after", "turns": 4, "amount": 8,
		"label": "屍變倒數：殭屍王出手四次後屍變（力量 +8）",
		"on_trigger": "屍變！邪氣暴漲，力量 +8！"}
	enemy.phase_2_actions = [
		{"intent": "殭屍狂咒 24", "effects": [{"kind": "damage", "amount": 24}]},
		{"intent": "殭咒縛身 妖債", "effects": [{"kind": "gain_curse_player", "curse_id": "yao_zhai"}]},
		{"intent": "鬼將斬魂 29", "effects": [{"kind": "damage", "amount": 29}]},
		{"intent": "召喚殭屍奴", "effects": [{"kind": "summon", "count": 1}]}
	]
	enemy.summon_pool = ["zombie_thrall"]
	return enemy

static func _baiyue_lord() -> EnemyData:
	# PAL1 最終 boss：拜月教主 HP 過半召出水魔獸現世（phase 2 變身）
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "baiyue_lord"
	enemy.portrait_scale = 1.25      # phase 1：拜月教主（人形）
	enemy.phase_2_portrait_scale = 2.0  # phase 2：水魔獸現世，遠比主角巨大
	enemy.display_name = "拜月教主"
	enemy.max_hp = 136
	enemy.portrait_path = "res://assets/art/enemies/baiyue_lord.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "拜月神力 18 + 破綻 1", "effects": [{"kind": "damage", "amount": 18}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "月蝕暗咒 蠱毒 6", "effects": [{"kind": "poison", "amount": 6}]},
		{"intent": "邪印烙身", "effects": [{"kind": "gain_curse_player", "curse_id": "xie_yin"}]},
		{"intent": "邪神降世 26", "effects": [{"kind": "damage", "amount": 26}]}
	]
	# 機制（蓄力＋吸血，終幕 boss）：每 4 回合「攝魂奪魄」24 傷＋自療 12——
	# 拖戰會被他補回去，逼玩家在大招週期間建立斬殺節奏
	enemy.ultimate_every = 4
	enemy.ultimate_action = {"intent": "攝魂奪魄 24 + 自療 12", "effects": [
		{"kind": "damage", "amount": 24}, {"kind": "enemy_heal", "amount": 12}]}
	# Phase 2：召出水魔獸（PAL1 原作終局妖獸）
	enemy.phase_2_display_name = "水魔獸"
	enemy.phase_2_portrait_path = "res://assets/art/enemies/baiyue_lord_phase2.png"
	enemy.phase_2_actions = [
		{"intent": "海嘯襲擊 31 + 虛弱 2", "effects": [{"kind": "damage", "amount": 31}, {"kind": "weak", "amount": 2}]},
		{"intent": "水妖蝕魂 蠱毒 9 + 破綻 2", "effects": [{"kind": "poison", "amount": 9}, {"kind": "vulnerable", "amount": 2}]},
		{"intent": "召喚水妖觸手", "effects": [{"kind": "summon", "count": 1}]},
		{"intent": "觸手鞭打 10x3", "effects": [{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}]},
		{"intent": "滅世巨浪 37", "effects": [{"kind": "damage", "amount": 37}]}
	]
	enemy.summon_pool = ["water_tentacle"]
	return enemy

# 仙靈島 boss（第二幕）：PAL1 正史——黑苗血洗仙靈島、擄走南詔公主趙靈兒的黑苗頭領。
static func _miao_chieftain() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "miao_chieftain"
	enemy.portrait_scale = 1.6  # boss：黑苗頭領（放大強化 Boss 壓迫感；超出部分往上利用敵人區空間）
	enemy.display_name = "黑苗頭領"
	enemy.max_hp = 96
	enemy.portrait_path = "res://assets/art/enemies/miao_chieftain_pal1_v2.png"
	# 此欄位描述「原圖是否已朝左」。新版原圖朝右，因此設 false，UI 會水平翻轉成朝向左側玩家。
	enemy.default_facing_left = false
	enemy.actions = [
		{"intent": "苗刀劈砍 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "下蠱 蠱毒 4 + 破綻 1", "effects": [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "擒拿 14 + 虛弱 2", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 2}]},
		{"intent": "黑苗結界 18", "effects": [{"kind": "block", "amount": 18}]}
	]
	# 機制（護持光環，act 2 boss 三體戰）：頭領活著時苗兵每回合 +4 護體——
	# 「先清小兵」的習慣打法被收稅，集火頭領 vs 先拔小兵成為真選擇
	enemy.passive = {"kind": "ally_block_aura", "amount": 4,
		"label": "頭領號令：黑苗頭領在場時，其他敵人每回合 +4 護體"}
	enemy.phase_2_actions = [
		{"intent": "血洗狂攻 27 + 虛弱 1", "effects": [{"kind": "damage", "amount": 27}, {"kind": "weak", "amount": 1}]},
		{"intent": "攝魂蠱 蠱毒 7 + 破綻 2", "effects": [{"kind": "poison", "amount": 7}, {"kind": "vulnerable", "amount": 2}]},
		{"intent": "苗疆秘法 22", "effects": [{"kind": "block", "amount": 22}]},
		{"intent": "奪命苗刀 31", "effects": [{"kind": "damage", "amount": 31}]}
	]
	return enemy

# 黑苗頭領手下士兵小怪
static func _miao_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "miao_soldier"
	enemy.display_name = "黑苗士兵"
	enemy.max_hp = 36
	enemy.portrait_path = "res://assets/art/enemies/miao_soldier.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "苗刀劈 9", "effects": [{"kind": "damage", "amount": 9}]},
		{"intent": "毒砂 蠱毒 2", "effects": [{"kind": "poison", "amount": 2}]},
		{"intent": "橫掃 7", "effects": [{"kind": "damage", "amount": 7}]}
	]
	return enemy

# 將軍塚 boss（第四幕）：PAL1 正史赤鬼王，盤據血池、以妖血邪法吞魂。
static func _tomb_general() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tomb_general"
	enemy.portrait_scale = 1.72  # 巨大上半身浮出血池，充分使用敵人區上方空間
	enemy.display_name = "赤鬼王"
	enemy.max_hp = 110
	enemy.portrait_path = "res://assets/art/enemies/tomb_general_pal1_v2.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "血爪 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "奪魂咒 虛弱 2 + 破綻 1", "effects": [{"kind": "weak", "amount": 2}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "血池妖氣 20", "effects": [{"kind": "block", "amount": 20}]},
		{"intent": "飛岩術 14 + 14", "effects": [{"kind": "damage", "amount": 14}, {"kind": "damage", "amount": 14}]}
	]
	# 機制（蓄力釋放，act 4 boss）：每 4 回合「赤鬼大斬」28 重擊，預警可見
	enemy.ultimate_every = 4
	enemy.ultimate_action = {"intent": "赤鬼大斬 28", "effects": [{"kind": "damage", "amount": 28}]}
	# 第四幕已改為「鬼將軍 → 地裂血池劇情 → 赤鬼王」雙層 Boss；
	# 赤鬼王本身不再使用半血變身，避免連續第三階段。
	return enemy

# 鎖妖塔 boss（第六幕）：PAL1 正史鎮獄明王，鎮守鎖妖塔、揭露靈兒人蛇身世之地。
static func _zhenyu_mingwang() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zhenyu_mingwang"
	enemy.portrait_scale = 1.5  # boss：鎮獄明王（巨型）
	enemy.display_name = "鎮獄明王"
	enemy.max_hp = 124
	enemy.portrait_path = "res://assets/art/enemies/zhenyu_mingwang.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "明王怒喝 20 + 破綻 1", "effects": [{"kind": "damage", "amount": 20}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "鎖妖鐵鏈 16 + 虛弱 2", "effects": [{"kind": "damage", "amount": 16}, {"kind": "weak", "amount": 2}]},
		{"intent": "金剛法相 護22·噬毒", "effects": [{"kind": "absorb_poison"}, {"kind": "block", "amount": 22}]},
		{"intent": "降魔杵 28", "effects": [{"kind": "damage", "amount": 28}]}
	]
	enemy.phase_2_actions = [
		{"intent": "明王金身 護26·噬毒", "effects": [{"kind": "absorb_poison"}, {"kind": "block", "amount": 26}]},
		{"intent": "鎮獄業火 32 + 破綻 2", "effects": [{"kind": "damage", "amount": 32}, {"kind": "vulnerable", "amount": 2}]},
		{"intent": "召喚鎖妖塔殘魂", "effects": [{"kind": "summon", "count": 1}]},
		{"intent": "怒目摧魂 38", "effects": [{"kind": "damage", "amount": 38}]}
	]
	enemy.summon_pool = ["tower_wisp"]
	# 機制型試點（懲罰型被動）：業鏡照心——玩家每打出一張「技能牌」，明王力量 +1。
	# 龜縮疊盾餵養他、攻擊牌不觸發 → 同一副牌在這場被迫換打法（明王審判惰戰者）。
	enemy.passive = {"kind": "strength_on_player_skill", "amount": 1,
		"label": "業鏡照心：你每打出一張技能牌，鎮獄明王力量 +1"}
	return enemy

# Multi-Enemy Mode：召喚物 — 水妖觸手（拜月教主 phase 2 召出）
static func _water_tentacle() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "water_tentacle"
	enemy.display_name = "水妖觸手"
	enemy.max_hp = 22
	enemy.portrait_path = "res://assets/art/enemies/water_tentacle.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "鞭打 6", "effects": [{"kind": "damage", "amount": 6}]},
		{"intent": "防 8", "effects": [{"kind": "block", "amount": 8}]},
		{"intent": "纏繞 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
	]
	return enemy

# 召喚物 — 赤眼幼魈（赤眼山魈 phase 2 召出；輕量物理 + 虛弱）
static func _red_eye_imp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "red_eye_imp"
	enemy.portrait_scale = 0.78  # 召喚物：赤眼幼魈（小）
	enemy.display_name = "赤眼幼魈"
	enemy.max_hp = 18
	enemy.portrait_path = "res://assets/art/enemies/red_eye_imp.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "撓擊 5", "effects": [{"kind": "damage", "amount": 5}]},
		{"intent": "怒吼 虛弱 1", "effects": [{"kind": "weak", "amount": 1}]},
	]
	return enemy

# 召喚物 — 殭屍奴（殭屍大帥 phase 2 召出；前排打手）
static func _zombie_thrall() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zombie_thrall"
	enemy.display_name = "殭屍奴"
	enemy.max_hp = 20
	enemy.portrait_path = "res://assets/art/enemies/zombie_thrall.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "抓撲 6", "effects": [{"kind": "damage", "amount": 6}]},
		{"intent": "守 5", "effects": [{"kind": "block", "amount": 5}]},
	]
	return enemy

# 召喚物 — 蜈蚣幼蟲（蜈蚣大王 phase 2 召出；毒系群擾）
static func _centipede_brood() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "centipede_brood"
	enemy.portrait_scale = 0.75  # 召喚物：蜈蚣幼蟲（小）
	enemy.display_name = "蜈蚣幼蟲"
	enemy.max_hp = 14
	enemy.portrait_path = "res://assets/art/enemies/centipede_brood.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "啃噬 4 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 4}, {"kind": "poison", "amount": 2}]},
	]
	return enemy

# 召喚物 — 鎖妖塔殘魂（山靈巫后 phase 2 召出；魂吸下毒）
static func _tower_wisp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tower_wisp"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.portrait_scale = 0.85  # 召喚物：鎖妖塔殘魂（小）
	enemy.display_name = "鎖妖塔殘魂"
	enemy.max_hp = 16
	enemy.portrait_path = "res://assets/art/enemies/tower_wisp.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "魂吸 4 + 蠱毒 1", "effects": [{"kind": "damage", "amount": 4}, {"kind": "poison", "amount": 1}]},
	]
	return enemy

static func _thief() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "thief"
	enemy.default_facing_left = true  # 原圖面向左，戰鬥中不再翻轉
	enemy.display_name = "小偷"
	enemy.max_hp = 62
	enemy.portrait_path = "res://assets/art/enemies/thief.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "探雲手 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "防守 7", "effects": [{"kind": "block", "amount": 7}]},
		{"intent": "劫財 12 + 破綻 1", "effects": [{"kind": "damage", "amount": 12}, {"kind": "vulnerable", "amount": 1}]}
	]
	return enemy

static func _tree_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tree_demon"
	enemy.portrait_scale = 1.3  # 大型妖獸：樹妖
	enemy.display_name = "樹妖"
	enemy.max_hp = 76
	enemy.portrait_path = "res://assets/art/enemies/tree_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "纏繞 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "藤鞭 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "妖藤護體 15", "effects": [{"kind": "block", "amount": 15}]},
		{"intent": "毒根突刺 9 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 9}, {"kind": "poison", "amount": 2}]}
	]
	return enemy

static func _xing_tian() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "xing_tian"
	enemy.portrait_scale = 1.25  # 大型：刑天
	enemy.display_name = "刑天"
	enemy.max_hp = 98
	enemy.portrait_path = "res://assets/art/enemies/xing_tian.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "破軍斬 碎甲 + 22", "effects": [{"kind": "strip_block", "amount": 0}, {"kind": "damage", "amount": 22}]},
		{"intent": "刑天戰盾 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "狂暴橫掃 14 + 破綻 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 1}]}
	]
	# 機制型試點（蓄力釋放）：每 3 回合「斷罪巨斧」34 重擊，意圖可預警 →
	# 玩家要算準大招回合囤格擋或搶斬殺，戰鬥節奏不再是平鋪數值交換
	enemy.ultimate_every = 3
	enemy.ultimate_action = {"intent": "斷罪巨斧 34", "effects": [{"kind": "damage", "amount": 34}]}
	return enemy

static func _black_impermanence() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "black_impermanence"
	enemy.display_name = "黑無常"
	enemy.max_hp = 84
	enemy.portrait_path = "res://assets/art/enemies/black_impermanence.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "勾魂索 14 + 虛弱 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 1}]},
		{"intent": "奪魄掌 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "無常結界 14", "effects": [{"kind": "block", "amount": 14}]}
	]
	return enemy

static func _white_impermanence() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "white_impermanence"
	enemy.display_name = "白無常"
	enemy.max_hp = 84
	enemy.portrait_path = "res://assets/art/enemies/white_impermanence.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "哭喪棒 13 + 破綻 1", "effects": [{"kind": "damage", "amount": 13}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "無常索命 16 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 16}, {"kind": "poison", "amount": 2}]},
		{"intent": "陰煞護身 15", "effects": [{"kind": "block", "amount": 15}]}
	]
	return enemy

static func _viper() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "viper"
	enemy.portrait_scale = 0.85  # 小型：蝮蛇
	enemy.display_name = "毒蛇"
	enemy.max_hp = 42
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "毒牙穿甲 7（無視護體）+ 蠱毒 2", "effects": [{"kind": "damage", "amount": 7, "pierce": true}, {"kind": "poison", "amount": 2}]},
		{"intent": "盤繞 6", "effects": [{"kind": "block", "amount": 6}]}
	]
	return enemy

static func _flying_skull() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "flying_skull"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.portrait_scale = 0.8  # 小型：飛骷髏
	enemy.display_name = "飛頭蠻"
	enemy.max_hp = 72
	enemy.portrait_path = "res://assets/art/enemies/grave_fire.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "幽冥鬼火 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "飛頭詛咒 虛弱 1 + 破綻 1", "effects": [{"kind": "weak", "amount": 1}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "飄忽 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _cleaver_granny() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "cleaver_granny"
	enemy.display_name = "菜刀婆婆"
	enemy.max_hp = 80
	enemy.portrait_path = "res://assets/art/enemies/zombie_soldier.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "亂砍 5x3", "effects": [{"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}]},
		{"intent": "揮刀 10", "effects": [{"kind": "block", "amount": 10}]},
		{"intent": "飛躍砍 16", "effects": [{"kind": "damage", "amount": 16}]}
	]
	return enemy

static func _man_eating_flower() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "man_eating_flower"
	enemy.portrait_scale = 1.15  # 偏大：食人花
	enemy.display_name = "狂暴食人花"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "撕咬 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "花藤護甲 18", "effects": [{"kind": "block", "amount": 18}]},
		{"intent": "消化液 10 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 10}, {"kind": "poison", "amount": 2}]}
	]
	# 機制（倒數計時）：血食漸飽 → 狂化。act 2/7 的計時敵
	enemy.passive = {"kind": "enrage_after", "turns": 3, "amount": 4,
		"label": "血食倒數：食人花出手三次後血食狂化（力量 +4）",
		"on_trigger": "血食狂化！力量 +4！"}
	return enemy

static func _gourd_sage() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "gourd_sage"
	enemy.display_name = "靈葫仙翁"
	enemy.max_hp = 88
	enemy.portrait_path = "res://assets/art/enemies/gu_cultist.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "葫蘆護咒 防 16 + 護咒 2", "effects": [{"kind": "block", "amount": 16}, {"kind": "enemy_artifact", "amount": 2}]},
		{"intent": "收妖葫蘆 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "神葫仙芒 18", "effects": [{"kind": "damage", "amount": 18}]}
	]
	return enemy

static func _puppet_girl() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "puppet_girl"
	enemy.display_name = "傀儡女"
	enemy.max_hp = 82
	enemy.portrait_path = "res://assets/art/enemies/fox_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "傀儡咒 破綻 2 + 虛弱 1", "effects": [{"kind": "vulnerable", "amount": 2}, {"kind": "weak", "amount": 1}]},
		{"intent": "飛針 6x2", "effects": [{"kind": "damage", "amount": 6}, {"kind": "damage", "amount": 6}]},
		{"intent": "替身草偶 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "降蠱 蠱毒 3", "effects": [{"kind": "poison", "amount": 3}]}
	]
	# 機制（護持光環，act 7/8 群戰）：傀儡絲線護持同伴——先殺傀儡女成為集火題
	enemy.passive = {"kind": "ally_block_aura", "amount": 4,
		"label": "傀儡絲線：傀儡女在場時，其他敵人每回合 +4 護體"}
	return enemy

static func _green_snake() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "green_snake"
	enemy.portrait_scale = 0.85  # 小型：青蛇
	enemy.display_name = "綠松蛇"
	enemy.max_hp = 44
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "毒咬 4 + 蠱毒 1", "effects": [{"kind": "damage", "amount": 4}, {"kind": "poison", "amount": 1}]},
		{"intent": "纏繞 6", "effects": [{"kind": "block", "amount": 6}]}
	]
	return enemy

static func _grass_spider() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "grass_spider"
	enemy.portrait_scale = 0.82  # 小型：草蜘蛛
	enemy.display_name = "草蛛"
	enemy.max_hp = 38
	enemy.portrait_path = "res://assets/art/enemies/wild_bee.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "吐絲 5 + 虛弱 1", "effects": [{"kind": "damage", "amount": 5}, {"kind": "weak", "amount": 1}]},
		{"intent": "棘網 防 5 + 反甲 3", "effects": [{"kind": "block", "amount": 5}, {"kind": "enemy_thorns", "amount": 3}]}
	]
	return enemy

static func _lantern_ghost() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "lantern_ghost"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.portrait_scale = 0.85  # 小型：燈籠鬼
	enemy.display_name = "燈籠怪"
	enemy.max_hp = 40
	enemy.portrait_path = "res://assets/art/enemies/grave_fire.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "燈火 6", "effects": [{"kind": "damage", "amount": 6}]},
		{"intent": "熱浪 5 + 破綻 1", "effects": [{"kind": "damage", "amount": 5}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "燈影 6", "effects": [{"kind": "block", "amount": 6}]}
	]
	return enemy

static func _hydra_snake() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "hydra_snake"
	enemy.portrait_scale = 1.25  # 大型：多頭蛇
	enemy.display_name = "九頭蛇"
	enemy.max_hp = 72
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "狂毒噬 10 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 10}, {"kind": "poison", "amount": 2}]},
		{"intent": "蛇尾掃 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "盤鱗 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	# 分裂：被斬到半血時頭顱再生，分出一條小青蛇
	enemy.split_into = "green_snake"
	return enemy

static func _flying_snake() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "flying_snake"
	enemy.floats = true  # 飄浮系：懸浮+陰影縮小（Phase A2）
	enemy.portrait_scale = 0.82  # 小型：飛蛇
	enemy.display_name = "飛蛇"
	enemy.max_hp = 60
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "俯衝 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "毒液 8 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 8}, {"kind": "poison", "amount": 2}]},
		{"intent": "滑翔 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _baby_toad() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "baby_toad"
	enemy.portrait_scale = 0.72  # 小型：幼蟾
	enemy.display_name = "小蛤蟆"
	enemy.max_hp = 50
	enemy.portrait_path = "res://assets/art/enemies/water_imp.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "跳躍砸 8", "effects": [{"kind": "damage", "amount": 8}]},
		{"intent": "泡泡 虛弱 1", "effects": [{"kind": "weak", "amount": 1}]},
		{"intent": "縮身 8", "effects": [{"kind": "block", "amount": 8}]}
	]
	return enemy

static func _poison_toad() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "poison_toad"
	enemy.portrait_scale = 0.85  # 小型：毒蟾
	enemy.display_name = "毒蟾蜍"
	enemy.max_hp = 78
	enemy.portrait_path = "res://assets/art/enemies/toxic_centipede.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "蟾毒吐息 11 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 11}, {"kind": "poison", "amount": 3}]},
		{"intent": "巨舌鞭笞 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "蟾皮護身 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _vampire_giant() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "vampire_giant"
	enemy.portrait_scale = 1.3  # 大型：吸血巨人
	enemy.display_name = "吸血巨人"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/zombie_soldier.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "狂暴巨拳 20", "effects": [{"kind": "damage", "amount": 20}]},
		{"intent": "吸血齧咬 12（回 12）", "effects": [{"kind": "damage", "amount": 12}, {"kind": "enemy_heal", "amount": 12}]},
		{"intent": "骨甲 16", "effects": [{"kind": "block", "amount": 16}]}
	]
	return enemy

static func _scorpion() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "scorpion"
	enemy.portrait_scale = 0.82  # 小型：蠍
	enemy.display_name = "毒蠍子"
	enemy.max_hp = 68
	enemy.portrait_path = "res://assets/art/enemies/toxic_centipede.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "蠍尾針 12 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 12}, {"kind": "poison", "amount": 2}]},
		{"intent": "巨鉗夾 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "堅殼 10", "effects": [{"kind": "block", "amount": 10}]}
	]
	return enemy

static func _female_thief() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "female_thief"
	enemy.display_name = "女飛賊"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/bandit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "雙匕急刺 7x2", "effects": [{"kind": "damage", "amount": 7}, {"kind": "damage", "amount": 7}]},
		{"intent": "迷煙 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "飛燕卸力 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _birdman() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "birdman"
	enemy.portrait_scale = 1.1  # 偏大：鳥人
	enemy.display_name = "鳥人"
	enemy.max_hp = 84
	enemy.portrait_path = "res://assets/art/enemies/fox_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "利爪俯衝 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "尖嘴啄擊 11 + 破綻 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "疾風振翅 13", "effects": [{"kind": "block", "amount": 13}]}
	]
	return enemy

static func _demihuman_villager() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "demihuman_villager"
	enemy.display_name = "半妖村民"
	enemy.max_hp = 75
	enemy.portrait_path = "res://assets/art/enemies/gu_cultist.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "鋤頭重擊 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "半妖狂怒 12 + 虛弱 1", "effects": [{"kind": "damage", "amount": 12}, {"kind": "weak", "amount": 1}]},
		{"intent": "退守 11", "effects": [{"kind": "block", "amount": 11}]}
	]
	return enemy

static func _five_eyed_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "five_eyed_demon"
	enemy.portrait_scale = 1.15  # 偏大：五眼魔
	enemy.display_name = "五眼魔"
	enemy.max_hp = 88
	enemy.portrait_path = "res://assets/art/enemies/ancient_evil_spirit.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "五眼邪光 16 + 破綻 1", "effects": [{"kind": "damage", "amount": 16}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "五眼咒視 虛弱 2 + 破綻 2", "effects": [{"kind": "weak", "amount": 2}, {"kind": "vulnerable", "amount": 2}]},
		# 機制型試點（狀態反轉）：吞噬自身蠱毒、每 2 層化 1 力量——毒流玩家的檔位閘：
		# 對牠疊毒等於餵養牠，counterplay 是改打直傷（無毒時此招只剩 6 護體，等於空過）
		{"intent": "噬毒蛻化", "effects": [{"kind": "absorb_poison"}, {"kind": "block", "amount": 6}]},
		{"intent": "魔影重重 14", "effects": [{"kind": "block", "amount": 14}]}
	]
	return enemy

static func _unicorn_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "unicorn_demon"
	enemy.portrait_scale = 1.2  # 大型：獨角魔
	enemy.display_name = "獨角獸"
	enemy.max_hp = 90
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "獨角頂撞 21", "effects": [{"kind": "damage", "amount": 21}]},
		{"intent": "雷角電擊 15 + 虛弱 1", "effects": [{"kind": "damage", "amount": 15}, {"kind": "weak", "amount": 1}]},
		{"intent": "聖獸屏障 15", "effects": [{"kind": "block", "amount": 15}]}
	]
	# 大招：每 3 個自身回合改放「獨角貫穿」（穿甲 28），意圖預警可見 → 玩家要在大招前布防
	enemy.ultimate_every = 3
	enemy.ultimate_action = {"intent": "獨角貫穿 28（穿甲）", "effects": [{"kind": "damage", "amount": 28, "pierce": true}]}
	return enemy

static func _pincer_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "pincer_demon"
	enemy.portrait_scale = 1.15  # 偏大：螯魔
	enemy.display_name = "夾子怪"
	enemy.max_hp = 94
	enemy.portrait_path = "res://assets/art/enemies/rock_guardian.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "巨鉗剪切 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "夾子撞擊 14 + 破綻 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "尖甲豎刺 防 20 + 反甲 4", "effects": [{"kind": "block", "amount": 20}, {"kind": "enemy_thorns", "amount": 4}]}
	]
	return enemy

static func _jumping_frog() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "jumping_frog"
	enemy.portrait_scale = 0.8  # 小型：跳蛙
	enemy.display_name = "跳跳蛙"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/jumping_frog.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "跳躍砸 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "毒腺突刺 8 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 8}, {"kind": "poison", "amount": 2}]},
		{"intent": "黏液阻礙 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]}
	]
	return enemy

static func _fire_kirin_whelp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "fire_kirin_whelp"
	enemy.portrait_scale = 0.85  # 小型：火麒麟幼體
	enemy.display_name = "火麒麟幼獸"
	enemy.max_hp = 86
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "烈焰爪 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "幼獸火吼 12 + 破綻 1", "effects": [{"kind": "damage", "amount": 12}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "赤炎護身 14", "effects": [{"kind": "block", "amount": 14}]}
	]
	return enemy

static func _ice_beast() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "ice_beast"
	enemy.portrait_scale = 1.2  # 大型：冰獸
	enemy.display_name = "冰青獸"
	enemy.max_hp = 86
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "玄冰擊 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "寒氣吐息 11 + 虛弱 1", "effects": [{"kind": "damage", "amount": 11}, {"kind": "weak", "amount": 1}]},
		{"intent": "冰壁 15", "effects": [{"kind": "block", "amount": 15}]}
	]
	return enemy

static func _man_eater_beast() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "man_eater_beast"
	enemy.portrait_scale = 1.2  # 大型妖獸：食人獸
	enemy.display_name = "食人獸"
	enemy.max_hp = 100
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "撕裂吞噬 24", "effects": [{"kind": "damage", "amount": 24}]},
		{"intent": "深淵咆哮 16 + 虛弱 1", "effects": [{"kind": "damage", "amount": 16}, {"kind": "weak", "amount": 1}]},
		{"intent": "暴獸重鎧 18", "effects": [{"kind": "block", "amount": 18}]}
	]
	return enemy

static func _two_headed_snake() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "two_headed_snake"
	enemy.portrait_scale = 1.25  # 大型妖獸：雙頭蛇
	enemy.display_name = "雙頭蛇"
	enemy.max_hp = 96
	enemy.portrait_path = "res://assets/art/enemies/serpent_demon.png"
	enemy.default_facing_left = true
	enemy.actions = [
		{"intent": "雙頭噬 10x2 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}, {"kind": "poison", "amount": 2}]},
		{"intent": "毒牙鞭打 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "鱗甲防護 16", "effects": [{"kind": "block", "amount": 16}]}
	]
	return enemy
