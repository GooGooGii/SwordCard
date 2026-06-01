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
	return [_bandit(), _beast(), _gu_cultist(), _sword_spirit(), _fox_spirit(), _serpent_demon(),
		_zombie_soldier(), _toxic_centipede(), _tower_demon(), _tower_ghost_soldier(),
		_baiyue_guard(), _ancient_evil_spirit()]

static func bosses() -> Array[EnemyData]:
	return [_moon_worshipper(), _centipede_lord(), _witch_queen(),
		_red_eye_demon(), _zombie_general(), _baiyue_lord()]

# Multi-Enemy Mode：召喚物（minions）— 由 boss 召喚出來的弱化版敵人
static func minions() -> Array[EnemyData]:
	return [_water_tentacle(), _red_eye_imp(), _zombie_thrall(), _centipede_brood(), _tower_wisp()]

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

static func enemies_for_act(act: int) -> Array[EnemyData]:
	match act:
		1: return [_bandit(), _beast()]
		2: return [_sword_spirit(), _fox_spirit(), _zombie_soldier()]
		3: return [_gu_cultist(), _serpent_demon(), _toxic_centipede()]
		4: return [_tower_demon(), _tower_ghost_soldier()]
		5: return [_moon_worshipper(), _baiyue_guard(), _ancient_evil_spirit()]
	return [_bandit(), _beast()]

static func boss_for_act(act: int) -> EnemyData:
	match act:
		1: return _red_eye_demon()
		2: return _zombie_general()
		3: return _centipede_lord()
		4: return _witch_queen()
		5: return _baiyue_lord()
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
		make_card("lxy_tianshi", "天師符法", "李逍遙", 1, "attack", "造成 9 點法術傷害。", [{"kind": "damage", "amount": 9}], "uncommon"),
		make_card("lxy_jiushen", "酒神咒", "李逍遙", 3, "attack", "造成 28 點傷害，自身承受 8 點反噬。", [{"kind": "damage", "amount": 28}, {"kind": "self_damage", "amount": 8}], "rare"),
		make_card("lxy_xianfeng", "仙風雲體", "李逍遙", 1, "skill", "獲得 8 點護體，抽 1 張牌。", [{"kind": "block", "amount": 8}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_zuimeng", "醉夢望月", "李逍遙", 2, "power", "本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("lxy_jianqi", "劍氣護身", "李逍遙", 1, "skill", "獲得 10 點護體。", [{"kind": "block", "amount": 10}]),
		make_card("lxy_linghuo", "靈火符", "李逍遙", 1, "attack", "造成 6 點傷害，施加 1 層破綻。", [{"kind": "damage", "amount": 6}, {"kind": "vulnerable", "amount": 1}], "uncommon"),
		make_card("lxy_xiaoyao_you", "逍遙遊", "李逍遙", 0, "skill", "抽 1 張牌並回復 1 點靈力。", [{"kind": "draw", "amount": 1}, {"kind": "energy", "amount": 1}], "rare"),
		make_card("lxy_jianzhen", "劍陣", "李逍遙", 2, "attack", "布下劍陣，造成 6 點傷害兩次。", [{"kind": "damage", "amount": 6, "hits": 2}], "uncommon"),
		make_card("lxy_liepo", "裂魄斬", "李逍遙", 1, "attack", "造成 10 點傷害，使敵人虛弱 1 層。", [{"kind": "damage", "amount": 10}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("lxy_qingfeng", "清風御劍", "李逍遙", 1, "skill", "獲得 5 點護體，抽 2 張牌。", [{"kind": "block", "amount": 5}, {"kind": "draw", "amount": 2}], "uncommon"),
		make_card("lxy_jiulong", "九龍訣", "李逍遙", 3, "attack", "御劍三式如九龍出海，造成 12 點傷害三次。", [{"kind": "damage", "amount": 12, "hits": 3}], "rare"),
		make_card("lxy_zuilong", "醉龍翻江", "李逍遙", 2, "attack", "造成 18 點傷害，自身承受 5 點反噬，抽 1 張牌。", [{"kind": "damage", "amount": 18}, {"kind": "self_damage", "amount": 5}, {"kind": "draw", "amount": 1}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片，未來再補正式插圖）
		make_card("lxy_qiliao", "氣療術", "李逍遙", 1, "skill", "回復 8 點生命。", [{"kind": "heal", "amount": 8}], "basic"),
		make_card("lxy_bingxin", "冰心訣", "李逍遙", 1, "skill", "清除自身全部負面狀態，獲得 3 點護體。", [{"kind": "cure_debuff"}, {"kind": "block", "amount": 3}], "basic"),
		# 劍流（御劍術連擊）：與烈火令／純鈞劍／龍泉劍 synergy；每段各吃力量
		make_card("lxy_wanjianguizong", "萬劍歸宗", "李逍遙", 1, "attack", "御劍齊出歸於一念，造成 4 點傷害三次。", [{"kind": "damage", "amount": 4, "hits": 3}], "uncommon"),
		make_card("lxy_jianshen", "劍身合一", "李逍遙", 2, "power", "劍身合一，本場戰鬥傷害提升 2，獲得 6 點護體。", [{"kind": "power", "amount": 2}, {"kind": "block", "amount": 6}], "rare"),
		make_card("lxy_tiangangqi", "天罡氣", "李逍遙", 1, "skill", "凝聚天罡護身之氣，獲得 14 點護體，抽 1 張牌。", [{"kind": "block", "amount": 14}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lxy_tianjian", "天劍出鞘", "李逍遙", 2, "attack", "天劍出鞘，造成 20 點傷害。", [{"kind": "damage", "amount": 20}], "rare"),
		make_card("lxy_xiaoyao_shenjian", "逍遙神劍", "李逍遙", 3, "attack", "御出逍遙神劍，造成 10 點傷害兩次，抽 2 張牌。", [{"kind": "damage", "amount": 10, "hits": 2}, {"kind": "draw", "amount": 2}], "rare"),
		make_card("lxy_yuanlinggui", "元靈龜庇護", "李逍遙", 2, "skill", "靈龜護佑，回復 10 點生命並獲得 14 點護體。", [{"kind": "heal", "amount": 10}, {"kind": "block", "amount": 14}], "uncommon"),
		make_card("lxy_zhenyuan", "真元凝聚", "李逍遙", 1, "skill", "凝聚真元之氣，抽 2 張牌並回復 4 點生命。", [{"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 4}], "uncommon"),
		make_card("lxy_jinchan_ls", "金蟬脫殼", "李逍遙", 1, "skill", "金蟬脫殼，獲得 12 點護體，抽 2 張牌，回復 6 點生命。", [{"kind": "block", "amount": 12}, {"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 6}], "rare"),
		make_card("lxy_ningyuan_ls", "凝元化神", "李逍遙", 2, "power", "凝聚本源化為神氣，本場戰鬥傷害提升 3，回復 8 點生命。", [{"kind": "power", "amount": 3}, {"kind": "heal", "amount": 8}], "rare"),
	]
	var character: CharacterData = _character("li_xiaoyao", "李逍遙", 74, "劍仙風流，禦劍、偷取與酒神系高風險高傷害。", cards)
	# PAL1 對齊：9 basic + 3 uncommon + 0 rare
	# 加 萬劍訣 (PAL1 Lv7 早期可習) 作為 burst attack，否則對 boss 過弱
	character.starting_deck = [
		cards[0], cards[0], cards[0],     # 3x 御劍術 (山神廟 basic 7dmg)
		cards[15], cards[15],              # 2x 氣療術 (初登場 basic heal8)
		cards[16],                         # 1x 冰心訣 (手卷 basic cure_debuff+3block)
		cards[2],                          # 1x 飛龍探雲手 (手卷 basic 4dmg+steal+draw+energy)
		cards[7], cards[7],                # 2x 劍氣護身 (basic 10block)
		cards[1],                          # 1x 萬劍訣 (PAL1 Lv7 uncommon 5x3=15 burst)
		cards[5],                          # 1x 仙風雲體 (蜀山 uncommon 8block+draw1)
		cards[6],                          # 1x 醉夢望月 (蜀山 uncommon power+2)
	]
	return character

static func _zhao_linger() -> CharacterData:
	# PAL1 對齊版本：
	# - 新增 金剛咒（初登場 增防禦）、冰咒（初登場 初級冰，與 Lv9 玄冰咒區分）、
	#   炎咒（初登場 初級火）、冰心訣（初登場 解狀態）
	# - 天雷破 (PAL1 Lv22) → rare（從 uncommon 升）
	var cards: Array[CardData] = [
		make_card("zl_guanyin", "觀音咒", "趙靈兒", 1, "skill", "回復 8 點生命。", [{"kind": "heal", "amount": 8}]),
		make_card("zl_wuqi", "五氣朝元", "趙靈兒", 2, "skill", "全體仙術。全隊回復 10 點生命，自身獲得 6 點護體。", [{"kind": "heal_party", "amount": 10}, {"kind": "block", "amount": 6}], "uncommon"),
		make_card("zl_xuanbing", "玄冰咒", "趙靈兒", 1, "attack", "造成 6 點傷害，使敵人虛弱 2 層。", [{"kind": "damage", "amount": 6}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("zl_leizhou", "雷咒", "趙靈兒", 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}]),
		make_card("zl_mengshe", "夢蛇靈印", "趙靈兒", 2, "power", "夢蛇之力凝為靈印，本場戰鬥傷害提升 2，回復 4 點生命並抽 1 張牌。", [{"kind": "power", "amount": 2}, {"kind": "heal", "amount": 4}, {"kind": "draw", "amount": 1}], "rare"),
		make_card("zl_fengling", "風靈符", "趙靈兒", 0, "skill", "抽 1 張牌。", [{"kind": "draw", "amount": 1}], "uncommon"),
		make_card("zl_tianlei", "天雷破", "趙靈兒", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("zl_lingguang", "靈光護體", "趙靈兒", 1, "skill", "獲得 12 點護體。", [{"kind": "block", "amount": 12}]),
		make_card("zl_huanyu", "幻雨咒", "趙靈兒", 1, "skill", "獲得 7 點護體，使敵人虛弱 1 層。", [{"kind": "block", "amount": 7}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("zl_nvwa", "女媧靈息", "趙靈兒", 2, "power", "回復 6 點生命，本場戰鬥傷害提升 2。", [{"kind": "heal", "amount": 6}, {"kind": "power", "amount": 2}], "rare"),
		make_card("zl_huihun", "還魂咒", "趙靈兒", 2, "skill", "救回 1 名倒下的同伴（30 HP 上場）；若無人倒下，改為自己回復 30 生命。", [{"kind": "revive", "amount": 30}], "rare"),
		make_card("zl_shuiling", "水靈護罩", "趙靈兒", 2, "skill", "回復 8 點生命並獲得 10 點護體。", [{"kind": "heal", "amount": 8}, {"kind": "block", "amount": 10}], "uncommon"),
		make_card("zl_leiguang", "雷光連擊", "趙靈兒", 1, "attack", "雷光雙擊，造成 4 點傷害兩次，使敵人虛弱 1 層。", [{"kind": "damage", "amount": 4}, {"kind": "damage", "amount": 4}, {"kind": "weak", "amount": 1}]),
		make_card("zl_lingxi", "靈息術", "趙靈兒", 1, "skill", "抽 2 張牌並回復 4 點生命。", [{"kind": "draw", "amount": 2}, {"kind": "heal", "amount": 4}], "uncommon"),
		make_card("zl_shenlei", "神雷降世", "趙靈兒", 3, "attack", "天降神雷，造成 30 點傷害。", [{"kind": "damage", "amount": 30}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片）
		make_card("zl_jingang", "金剛咒", "趙靈兒", 1, "skill", "獲得 10 點護體（道家護身咒術）。", [{"kind": "block", "amount": 10}], "basic"),
		make_card("zl_bingzhou", "冰咒", "趙靈兒", 1, "attack", "初級冰系仙術，造成 6 點傷害並使敵人虛弱 1 層。", [{"kind": "damage", "amount": 6}, {"kind": "weak", "amount": 1}], "basic"),
		make_card("zl_yanzhou", "炎咒", "趙靈兒", 1, "attack", "初級火系仙術，造成 8 點傷害並施加 1 層破綻。", [{"kind": "damage", "amount": 8}, {"kind": "vulnerable", "amount": 1}], "basic"),
		make_card("zl_bingxin", "冰心訣", "趙靈兒", 1, "skill", "清除自身全部負面狀態，獲得 3 點護體。", [{"kind": "cure_debuff"}, {"kind": "block", "amount": 3}], "basic"),
		# 杖流 payoff：對虛弱/破綻敵加傷（與冰咒/炎咒/玄冰咒/幻雨咒 synergy）
		make_card("zl_shuiyin", "水靈封印", "趙靈兒", 1, "attack", "造成 5 點傷害；目標每層虛弱或破綻 +2 點傷害。", [{"kind": "damage_debuff_bonus", "amount": 5, "bonus_per_layer": 2}], "uncommon"),
		# 治療+護體一體（杖流續戰：靈族慈悲化作護身）
		make_card("zl_ganlin", "甘霖咒", "趙靈兒", 1, "skill", "回復 6 點生命並獲得 6 點護體。", [{"kind": "heal", "amount": 6}, {"kind": "block", "amount": 6}], "uncommon"),
		make_card("zl_diliebeng", "地裂崩", "趙靈兒", 3, "attack", "大地崩裂，對全體敵人造成 15 點傷害。", [{"kind": "damage_all", "amount": 15}], "rare"),
		make_card("zl_fengxuebing", "風雪冰咒", "趙靈兒", 1, "attack", "冰雪風系仙術，造成 8 點傷害，使敵人虛弱 2 層。", [{"kind": "damage", "amount": 8}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("zl_kuanglei", "狂雷破", "趙靈兒", 2, "attack", "天雷狂擊，造成 11 點傷害兩次。", [{"kind": "damage", "amount": 11, "hits": 2}], "rare"),
		make_card("zl_sanmeizhenhuo", "三昧真火", "趙靈兒", 2, "attack", "三昧真火燃天，對全體敵人造成 10 點傷害並施加 2 層破綻。", [{"kind": "damage_all", "amount": 10}, {"kind": "vulnerable_all", "amount": 2}], "rare"),
		make_card("zl_taishan", "泰山壓頂", "趙靈兒", 2, "attack", "泰山壓頂之勢，造成 20 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 20}, {"kind": "vulnerable", "amount": 2}], "rare"),
		make_card("zl_wuleizhou", "五雷咒", "趙靈兒", 3, "attack", "五雷齊降，造成 6 點傷害五次。", [{"kind": "damage", "amount": 6, "hits": 5}], "rare"),
		make_card("zl_xuanfengzhou", "旋風咒", "趙靈兒", 1, "skill", "旋風護體，獲得 10 點護體，使敵人虛弱 1 層。", [{"kind": "block", "amount": 10}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("zl_mengshe_ls", "夢蛇靈印★", "趙靈兒", 2, "power", "夢蛇靈印大成，本場戰鬥傷害提升 3，回復 6 點生命，抽 2 張牌。", [{"kind": "power", "amount": 3}, {"kind": "heal", "amount": 6}, {"kind": "draw", "amount": 2}], "rare"),
	]
	var character: CharacterData = _character("zhao_linger", "趙靈兒", 68, "五靈仙術、治療、護盾、解狀態與長戰持續。", cards)
	# PAL1 對齊：9 basic + 3 uncommon + 0 rare
	# 加 天雷破 (PAL1 Lv22) 作為 boss burst — uncommon 18dmg
	character.starting_deck = [
		cards[3], cards[3], cards[3],     # 3x 雷咒 (初登場 basic 10dmg)
		cards[0], cards[0],                # 2x 觀音咒 (初登場 basic 8heal)
		cards[15],                         # 1x 金剛咒 (初登場 basic 10block)
		cards[16],                         # 1x 冰咒 (初登場 basic 6dmg+weak1)
		cards[17],                         # 1x 炎咒 (初登場 basic 8dmg+vuln1)
		cards[18],                         # 1x 冰心訣 (初登場 basic cure_debuff+3block)
		cards[1],                          # 1x 五氣朝元 (PAL1 Lv8 uncommon 16heal+6block)
		cards[6],                          # 1x 天雷破 (uncommon 18dmg) — burst
		cards[8],                          # 1x 幻雨咒 (uncommon 7block+weak1)
	]
	return character

static func _lin_yueru() -> CharacterData:
	# PAL1 對齊版本：
	# - 凝神歸元 是她 PAL1 初登場就會的特色（HP 220）！補上
	# - 一陽指 (PAL1 Lv7) 保持 uncommon
	# - 萬里狂沙 (PAL1 Lv35) 是 rare（已是）
	var cards: Array[CardData] = [
		make_card("lyr_qijianzhi", "氣劍指", "林月如", 1, "attack", "凝氣為劍，對全體敵人造成 8 點傷害。", [{"kind": "damage_all", "amount": 8}]),
		make_card("lyr_yiyang", "一陽指", "林月如", 2, "attack", "造成 18 點傷害。", [{"kind": "damage", "amount": 18}], "uncommon"),
		make_card("lyr_zhanlong", "斬龍訣", "林月如", 3, "attack", "造成 30 點傷害。", [{"kind": "damage", "amount": 30}], "rare"),
		make_card("lyr_qiankun", "乾坤一擲", "林月如", 0, "attack", "消耗全部靈力，每點造成 9 點傷害。", [{"kind": "consume_energy_damage", "amount": 9}], "rare"),
		make_card("lyr_fanji", "回身反擊", "林月如", 1, "skill", "獲得 8 點護體並造成 5 點傷害。", [{"kind": "block", "amount": 8}, {"kind": "damage", "amount": 5}]),
		make_card("lyr_bianying", "鞭影連環", "林月如", 1, "attack", "造成 4 點傷害兩次，施加 1 層破綻。", [{"kind": "damage", "amount": 4}, {"kind": "damage", "amount": 4}, {"kind": "vulnerable", "amount": 1}]),
		make_card("lyr_shenfa", "月影身法", "林月如", 1, "skill", "獲得 7 點護體，抽 1 張牌。", [{"kind": "block", "amount": 7}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_juesha", "絕殺一擊", "林月如", 2, "attack", "造成 14 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 14}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("lyr_lianhuan", "連環快斬", "林月如", 1, "attack", "造成 3 點傷害三次。", [{"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}, {"kind": "damage", "amount": 3}], "uncommon"),
		make_card("lyr_jinchan", "金蟬卸力", "林月如", 1, "skill", "獲得 5 點護體，抽 2 張牌。", [{"kind": "block", "amount": 5}, {"kind": "draw", "amount": 2}], "rare"),
		make_card("lyr_xuanjian", "旋劍花舞", "林月如", 1, "attack", "造成 5 點傷害兩次。", [{"kind": "damage", "amount": 5}, {"kind": "damage", "amount": 5}]),
		make_card("lyr_kuaijian", "輕劍急刺", "林月如", 0, "attack", "造成 6 點傷害。", [{"kind": "damage", "amount": 6}], "uncommon"),
		make_card("lyr_poqian", "破千謀", "林月如", 2, "attack", "造成 20 點傷害，抽 1 張牌。", [{"kind": "damage", "amount": 20}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tianv", "飛花亂舞", "林月如", 1, "attack", "造成 4 點傷害，施加 1 層破綻，抽 1 張牌。", [{"kind": "damage", "amount": 4}, {"kind": "vulnerable", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tieyi", "鐵衣功", "林月如", 2, "skill", "獲得 18 點護體。", [{"kind": "block", "amount": 18}], "rare"),
		# PAL1 初登場新增（她原作 Lv1 就會凝神歸元 HP 220 治療，是她的特色；art 暫借）
		make_card("lyr_ningshen", "凝神歸元", "林月如", 1, "skill", "凝神運氣，回復 12 點生命。", [{"kind": "heal", "amount": 12}], "basic"),
		# 反擊流（鳳鳴刀／Thorns）：被攻擊時反彈傷害給攻擊者（不衰減，跨回合）
		make_card("lyr_fenghuan", "鳳鳴反擊", "林月如", 1, "power", "本場戰鬥獲得 3 點荊棘（被攻擊時反彈傷害給攻擊者）。", [{"kind": "thorns", "amount": 3}], "uncommon"),
		make_card("lyr_yuehua", "月華護體", "林月如", 1, "skill", "獲得 6 點護體與 1 點荊棘。", [{"kind": "block", "amount": 6}, {"kind": "thorns", "amount": 1}], "uncommon"),
		make_card("lyr_lielong", "烈龍衝擊", "林月如", 2, "attack", "烈龍衝擊，造成 24 點傷害，施加 2 層破綻。", [{"kind": "damage", "amount": 24}, {"kind": "vulnerable", "amount": 2}], "rare"),
		make_card("lyr_qijuejianqi", "氣絕劍氣", "林月如", 1, "attack", "劍氣縱橫，造成 9 點傷害，施加 1 層破綻，抽 1 張牌。", [{"kind": "damage", "amount": 9}, {"kind": "vulnerable", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("lyr_tongqianbiao", "銅錢鏢", "林月如", 1, "attack", "擲出三枚銅錢鏢，造成 4 點傷害三次。", [{"kind": "damage", "amount": 4, "hits": 3}], "uncommon"),
		make_card("lyr_wanlikuang", "萬里狂沙", "林月如", 2, "skill", "狂沙漫天，對全體敵人施加 3 層破綻，抽 1 張牌。", [{"kind": "vulnerable_all", "amount": 3}, {"kind": "draw", "amount": 1}], "rare"),
		make_card("lyr_yuanlinggui", "元靈護體", "林月如", 2, "skill", "靈龜護體，回復 8 點生命並獲得 16 點護體。", [{"kind": "heal", "amount": 8}, {"kind": "block", "amount": 16}], "uncommon"),
	]
	var character: CharacterData = _character("lin_yueru", "林月如", 72, "鞭劍武學、連擊、反擊與內勁治療。", cards)
	# PAL1 對齊：10 basic + 2 uncommon + 0 rare
	character.starting_deck = [
		cards[0], cards[0], cards[0], cards[0],   # 4x 氣劍指 (初登場 basic 8dmg)
		cards[15], cards[15],                      # 2x 凝神歸元 (初登場 basic 12heal)
		cards[4], cards[4],                        # 2x 回身反擊 (basic 8block+5dmg)
		cards[10], cards[10],                      # 2x 旋劍花舞 (basic 5x2)
		cards[1],                                   # 1x 一陽指 (PAL1 Lv7 uncommon 18dmg)
		cards[6],                                   # 1x 月影身法 (uncommon 7block+draw1)
	]
	return character

static func _anu() -> CharacterData:
	# PAL1 對齊版本：
	# - 命名對齊：解毒咒 = 清除負面狀態（cure_debuff），靈血咒 = 回血（heal+block）
	# - 新增 鬼降（PAL1 初登場 瘋魔 5 回合 → 簡化為 敵人虛弱 3）
	# - 萬蟻蝕象 PAL1 Lv30 → 升 uncommon
	# - 爆炸蠱 PAL1 Lv33 → 已是 uncommon（維持）
	var cards: Array[CardData] = [
		make_card("anu_yufeng", "御蜂術", "阿奴", 1, "attack", "笛音引毒蜂群，對全體敵人造成 3 點傷害三次。", [{"kind": "damage_all", "amount": 3, "hits": 3}]),
		make_card("anu_wanyi", "萬蟻蝕象", "阿奴", 1, "skill", "施加 5 層蠱毒。", [{"kind": "poison", "amount": 5}], "uncommon"),
		make_card("anu_mihun", "迷魂術", "阿奴", 1, "skill", "使敵人虛弱 3 層。", [{"kind": "weak", "amount": 3}]),
		make_card("anu_baozhagu", "爆炸蠱", "阿奴", 2, "attack", "引爆全部蠱毒，每層造成 3 點傷害。", [{"kind": "poison_burst", "amount": 3}], "uncommon"),
		make_card("anu_lingxue", "靈血咒", "阿奴", 1, "skill", "苗疆靈血續命之術，回復 5 點生命並獲得 3 點護體。", [{"kind": "heal", "amount": 5}, {"kind": "block", "amount": 3}]),
		make_card("anu_jiedu", "解毒咒", "阿奴", 1, "skill", "清除自身全部負面狀態，抽 1 張牌。", [{"kind": "cure_debuff"}, {"kind": "draw", "amount": 1}]),
		make_card("anu_guling", "蠱靈護身", "阿奴", 1, "skill", "獲得 12 點護體。", [{"kind": "block", "amount": 12}], "uncommon"),
		make_card("anu_wangyou", "忘憂蠱", "阿奴", 2, "skill", "施加 4 層蠱毒與 2 層破綻。", [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 2}], "uncommon"),
		make_card("anu_duwu", "毒霧繚繞", "阿奴", 1, "skill", "施加 2 層蠱毒，使敵人虛弱 1 層。", [{"kind": "poison", "amount": 2}, {"kind": "weak", "amount": 1}], "uncommon"),
		make_card("anu_guxue", "蠱血共鳴", "阿奴", 2, "power", "本場戰鬥傷害提升 1，施加 5 層蠱毒。", [{"kind": "power", "amount": 1}, {"kind": "poison", "amount": 5}], "rare"),
		make_card("anu_baizu", "百足蠱", "阿奴", 2, "skill", "施加 8 層蠱毒。", [{"kind": "poison", "amount": 8}], "uncommon"),
		make_card("anu_duzhen", "毒針連射", "阿奴", 1, "attack", "造成 5 點傷害，施加 2 層蠱毒。", [{"kind": "damage", "amount": 5}, {"kind": "poison", "amount": 2}], "uncommon"),
		make_card("anu_guwang", "蠱王號令", "阿奴", 0, "skill", "使敵人虛弱 2 層。", [{"kind": "weak", "amount": 2}], "uncommon"),
		make_card("anu_sanmao", "三毛蠱", "阿奴", 2, "skill", "施加 5 層蠱毒，使敵人虛弱 2 層。", [{"kind": "poison", "amount": 5}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("anu_gushen", "蠱神附體", "阿奴", 3, "power", "本場戰鬥傷害提升 3，施加 4 層蠱毒。", [{"kind": "power", "amount": 3}, {"kind": "poison", "amount": 4}], "rare"),
		# PAL1 初登場新增（art 暫借既有卡片）
		make_card("anu_guijiang", "鬼降", "阿奴", 1, "skill", "苗疆咒術，使敵人陷入瘋魔狀態（虛弱 3 層）。", [{"kind": "weak", "amount": 3}], "basic"),
		# 刀流（巫月神刀）：力量 + 連擊軸。淬鋒疊力量，連斬牌每段各吃力量 → 越疊越痛。
		# art 暫借既有阿奴卡（未來補正式插圖）
		make_card("anu_cuifeng", "淬鋒蠱刃", "阿奴", 1, "power", "刀刃淬入蠱毒，本場戰鬥傷害提升 2。", [{"kind": "power", "amount": 2}], "uncommon"),
		make_card("anu_wuyuezhan", "巫月斬", "阿奴", 1, "attack", "巫月神刀連斬，造成 5 點傷害兩次。", [{"kind": "damage", "amount": 5, "hits": 2}], "uncommon"),
		make_card("anu_xuerenwu", "血刃亂舞", "阿奴", 2, "attack", "亂刀狂舞，造成 4 點傷害三次。", [{"kind": "damage", "amount": 4, "hits": 3}], "rare"),
		make_card("anu_duohun", "奪魂術", "阿奴", 1, "attack", "奪魂之術，造成 8 點傷害，使敵人虛弱 2 層。", [{"kind": "damage", "amount": 8}, {"kind": "weak", "amount": 2}], "uncommon"),
		make_card("anu_sanshigu", "三屍蠱", "阿奴", 2, "skill", "三屍蠱毒入體，施加 10 層蠱毒。", [{"kind": "poison", "amount": 10}], "rare"),
		make_card("anu_shuhun", "術魂加持", "阿奴", 1, "power", "術魂加持，本場戰鬥傷害提升 1，抽 1 張牌。", [{"kind": "power", "amount": 1}, {"kind": "draw", "amount": 1}], "uncommon"),
		make_card("anu_wangushitian", "萬蠱噬天", "阿奴", 3, "skill", "萬蠱齊發，施加 12 層蠱毒，使敵人虛弱 3 層。", [{"kind": "poison", "amount": 12}, {"kind": "weak", "amount": 3}], "rare"),
		make_card("anu_wanyi_ls", "萬蟻蝕骨", "阿奴", 1, "skill", "萬蟻蝕骨，施加 8 層蠱毒。", [{"kind": "poison", "amount": 8}], "rare"),
		make_card("anu_yanshazhou", "燃殺咒", "阿奴", 2, "attack", "燃殺之咒，造成 14 點傷害並施加 3 層蠱毒。", [{"kind": "damage", "amount": 14}, {"kind": "poison", "amount": 3}], "uncommon"),
		# 毒引擎（StS Noxious Fumes 式）：阿奴蠱術的核心——放出蠱蟲化瘴，每回合自動疊毒，
		# 讓她不必每回合花牌施毒、騰出手牌防禦。art 暫借百足蠱。
		make_card("anu_guzhang", "蠱瘴瀰漫", "阿奴", 1, "power", "放出蠱蟲化作毒瘴，每回合開始時對所有敵人施加 2 層蠱毒。", [{"kind": "poison_engine", "amount": 2}], "uncommon", "anu_baizu"),
	]
	var character: CharacterData = _character("anu", "阿奴", 66, "蠱毒、咒術、削弱與長戰持續傷害。", cards)
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
				"amount": 5,
				"label": "敵人每場戰鬥開場受到 5 層蠱毒"
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
		"beast":
			return [
				{"type": "potion", "potion_id": "hugu_jiu",    "display_name": "虎骨酒"},
				{"type": "potion", "potion_id": "huichun_dan", "display_name": "回春丹"},
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
		"ancient_evil_spirit":
			return [
				{"type": "potion", "potion_id": "xianren_xue",  "display_name": "仙人遺血"},
				{"type": "potion", "potion_id": "tianling_dan",  "display_name": "天靈丹"},
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
	return []

static func _bandit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "bandit"
	enemy.display_name = "山賊頭目"
	enemy.max_hp = 70
	enemy.portrait_path = "res://assets/art/enemies/bandit.png"
	enemy.actions = [
		{"intent": "劈砍 15", "effects": [{"kind": "damage", "amount": 15}]},
		{"intent": "防守 10", "effects": [{"kind": "block", "amount": 10}]},
		{"intent": "猛擊 21", "effects": [{"kind": "damage", "amount": 21}]}
	]
	return enemy

static func _beast() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "beast"
	enemy.display_name = "山林妖獸"
	enemy.max_hp = 80
	enemy.portrait_path = "res://assets/art/enemies/beast.png"
	enemy.actions = [
		{"intent": "撕咬 17", "effects": [{"kind": "damage", "amount": 17}]},
		{"intent": "怒吼 12", "effects": [{"kind": "damage", "amount": 12}]},
		{"intent": "撲擊 26", "effects": [{"kind": "damage", "amount": 26}]}
	]
	return enemy

static func _gu_cultist() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "gu_cultist"
	enemy.display_name = "蠱毒妖人"
	enemy.max_hp = 72
	enemy.portrait_path = "res://assets/art/enemies/gu_cultist.png"
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
	enemy.portrait_path = "res://assets/art/enemies/fox_spirit.png"
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
	enemy.actions = [
		{"intent": "毒牙 14", "effects": [{"kind": "damage", "amount": 14}, {"kind": "poison", "amount": 3}]},
		{"intent": "盤身 14", "effects": [{"kind": "block", "amount": 14}]},
		{"intent": "蛇吻 22", "effects": [{"kind": "damage", "amount": 22}]}
	]
	return enemy

static func _moon_worshipper() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "moon_worshipper"
	enemy.display_name = "拜月教徒"
	enemy.max_hp = 105
	enemy.portrait_path = "res://assets/art/enemies/moon_worshipper.png"
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
	enemy.display_name = "蜈蚣大王"
	enemy.max_hp = 108
	enemy.portrait_path = "res://assets/art/enemies/centipede_lord.png"
	enemy.actions = [
		{"intent": "多足踏擊 7x4", "effects": [
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7},
			{"kind": "damage", "amount": 7}
		]},
		{"intent": "毒尾掃 16 + 蠱毒 4", "effects": [
			{"kind": "damage", "amount": 16},
			{"kind": "poison", "amount": 4}
		]},
		{"intent": "蜷甲防禦 18", "effects": [{"kind": "block", "amount": 18}]},
		{"intent": "蝕骨蝕魂 24 + 虛弱 1", "effects": [
			{"kind": "damage", "amount": 24},
			{"kind": "weak", "amount": 1}
		]}
	]
	enemy.phase_2_actions = [
		{"intent": "怒爪掃 9x4", "effects": [
			{"kind": "damage", "amount": 9},
			{"kind": "damage", "amount": 9},
			{"kind": "damage", "amount": 9},
			{"kind": "damage", "amount": 9}
		]},
		{"intent": "噬魂咒 29", "effects": [{"kind": "damage", "amount": 29}]},
		{"intent": "毒霧 蠱毒 6 + 破綻 2", "effects": [
			{"kind": "poison", "amount": 6},
			{"kind": "vulnerable", "amount": 2}
		]},
		{"intent": "召喚蜈蚣幼蟲", "effects": [{"kind": "summon", "count": 1}]}
	]
	enemy.summon_pool = ["centipede_brood"]
	return enemy

static func _witch_queen() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "witch_queen"
	enemy.display_name = "山靈巫后"
	enemy.max_hp = 92
	enemy.portrait_path = "res://assets/art/enemies/witch_queen.png"
	enemy.actions = [
		{"intent": "蠱咒 蠱毒 6", "effects": [{"kind": "poison", "amount": 6}]},
		{"intent": "詛咒 虛弱 3", "effects": [{"kind": "weak", "amount": 3}]},
		{"intent": "邪結界 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "魂噬 20 + 蠱毒 3", "effects": [
			{"kind": "damage", "amount": 20},
			{"kind": "poison", "amount": 3}
		]}
	]
	enemy.phase_2_actions = [
		{"intent": "山靈怒火 26 + 虛弱 1", "effects": [
			{"kind": "damage", "amount": 26},
			{"kind": "weak", "amount": 1}
		]},
		{"intent": "蠱噬 蠱毒 7 + 破綻 2", "effects": [
			{"kind": "poison", "amount": 7},
			{"kind": "vulnerable", "amount": 2}
		]},
		{"intent": "邪音咒 16 + 破綻 3", "effects": [
			{"kind": "damage", "amount": 16},
			{"kind": "vulnerable", "amount": 3}
		]},
		{"intent": "召喚鎖妖塔殘魂", "effects": [{"kind": "summon", "count": 1}]}
	]
	enemy.summon_pool = ["tower_wisp"]
	return enemy

static func _zombie_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zombie_soldier"
	enemy.display_name = "地底殭屍"
	enemy.max_hp = 78
	enemy.portrait_path = "res://assets/art/enemies/zombie_soldier.png"
	enemy.actions = [
		{"intent": "腐爛爪 14 + 虛弱 1", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 1}]},
		{"intent": "殭步衝 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "死硬護 13", "effects": [{"kind": "block", "amount": 13}]}
	]
	return enemy

static func _toxic_centipede() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "toxic_centipede"
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
	enemy.display_name = "塔中封魔"
	enemy.max_hp = 90
	enemy.portrait_path = "res://assets/art/enemies/tower_demon.png"
	enemy.actions = [
		{"intent": "邪焰 15 + 破綻 1", "effects": [{"kind": "damage", "amount": 15}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "衝擊 22", "effects": [{"kind": "damage", "amount": 22}]},
		{"intent": "封魔護 14", "effects": [{"kind": "block", "amount": 14}]}
	]
	return enemy

static func _tower_ghost_soldier() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tower_ghost_soldier"
	enemy.display_name = "鎖妖塔鬼兵"
	enemy.max_hp = 81
	enemy.portrait_path = "res://assets/art/enemies/tower_ghost_soldier.png"
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
	enemy.actions = [
		{"intent": "拜月斬 18", "effects": [{"kind": "damage", "amount": 18}]},
		{"intent": "邪毒 蠱毒 4 + 破綻 1", "effects": [{"kind": "poison", "amount": 4}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "教衛盾 15", "effects": [{"kind": "block", "amount": 15}]}
	]
	return enemy

static func _ancient_evil_spirit() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "ancient_evil_spirit"
	enemy.display_name = "上古惡靈"
	enemy.max_hp = 85
	enemy.portrait_path = "res://assets/art/enemies/ancient_evil_spirit.png"
	enemy.actions = [
		{"intent": "噬魂 15 + 虛弱 1", "effects": [{"kind": "damage", "amount": 15}, {"kind": "weak", "amount": 1}]},
		{"intent": "邪氣蝕 16 + 蠱毒 3", "effects": [{"kind": "damage", "amount": 16}, {"kind": "poison", "amount": 3}]},
		{"intent": "邪盾 12", "effects": [{"kind": "block", "amount": 12}]}
	]
	return enemy

static func _red_eye_demon() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "red_eye_demon"
	enemy.display_name = "赤眼山魈"
	enemy.max_hp = 95
	enemy.portrait_path = "res://assets/art/enemies/red_eye_demon.png"
	enemy.actions = [
		{"intent": "爪擊 14", "effects": [{"kind": "damage", "amount": 14}]},
		{"intent": "怒吼 虛弱 2", "effects": [{"kind": "weak", "amount": 2}]},
		{"intent": "血眼撲擊 17 + 破綻 1", "effects": [{"kind": "damage", "amount": 17}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "山魈跳踏 10+10", "effects": [{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}]}
	]
	enemy.phase_2_actions = [
		{"intent": "赤眼怒火 21 + 虛弱 1", "effects": [{"kind": "damage", "amount": 21}, {"kind": "weak", "amount": 1}]},
		{"intent": "血月衝擊 26", "effects": [{"kind": "damage", "amount": 26}]},
		{"intent": "群怪呼嘯 18 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 18}, {"kind": "poison", "amount": 2}]},
		{"intent": "召喚赤眼幼魈", "effects": [{"kind": "summon", "count": 1}]}
	]
	enemy.summon_pool = ["red_eye_imp"]
	return enemy

static func _zombie_general() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "zombie_general"
	enemy.display_name = "殭屍大帥"
	enemy.max_hp = 106
	enemy.portrait_path = "res://assets/art/enemies/zombie_general.png"
	enemy.actions = [
		{"intent": "鬼將劈砍 16", "effects": [{"kind": "damage", "amount": 16}]},
		{"intent": "腐臭毒氣 蠱毒 5", "effects": [{"kind": "poison", "amount": 5}]},
		{"intent": "屍甲護衛 16", "effects": [{"kind": "block", "amount": 16}]},
		{"intent": "千年寒氣 14 + 虛弱 2", "effects": [{"kind": "damage", "amount": 14}, {"kind": "weak", "amount": 2}]}
	]
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
	enemy.display_name = "拜月教主"
	enemy.max_hp = 136
	enemy.portrait_path = "res://assets/art/enemies/baiyue_lord.png"
	enemy.actions = [
		{"intent": "拜月神力 18 + 破綻 1", "effects": [{"kind": "damage", "amount": 18}, {"kind": "vulnerable", "amount": 1}]},
		{"intent": "月蝕暗咒 蠱毒 6", "effects": [{"kind": "poison", "amount": 6}]},
		{"intent": "邪印烙身", "effects": [{"kind": "gain_curse_player", "curse_id": "xie_yin"}]},
		{"intent": "邪神降世 26", "effects": [{"kind": "damage", "amount": 26}]}
	]
	# Phase 2：召出水魔獸（PAL1 原作終局妖獸）
	enemy.phase_2_display_name = "水魔獸"
	enemy.phase_2_actions = [
		{"intent": "海嘯襲擊 31 + 虛弱 2", "effects": [{"kind": "damage", "amount": 31}, {"kind": "weak", "amount": 2}]},
		{"intent": "水妖蝕魂 蠱毒 9 + 破綻 2", "effects": [{"kind": "poison", "amount": 9}, {"kind": "vulnerable", "amount": 2}]},
		{"intent": "召喚水妖觸手", "effects": [{"kind": "summon", "count": 1}]},
		{"intent": "觸手鞭打 10x3", "effects": [{"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}, {"kind": "damage", "amount": 10}]},
		{"intent": "滅世巨浪 37", "effects": [{"kind": "damage", "amount": 37}]}
	]
	enemy.summon_pool = ["water_tentacle"]
	return enemy

# Multi-Enemy Mode：召喚物 — 水妖觸手（拜月教主 phase 2 召出）
static func _water_tentacle() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "water_tentacle"
	enemy.display_name = "水妖觸手"
	enemy.max_hp = 22
	enemy.portrait_path = "res://assets/art/enemies/water_tentacle.png"
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
	enemy.display_name = "赤眼幼魈"
	enemy.max_hp = 18
	enemy.portrait_path = "res://assets/art/enemies/red_eye_imp.png"
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
	enemy.actions = [
		{"intent": "抓撲 6", "effects": [{"kind": "damage", "amount": 6}]},
		{"intent": "守 5", "effects": [{"kind": "block", "amount": 5}]},
	]
	return enemy

# 召喚物 — 蜈蚣幼蟲（蜈蚣大王 phase 2 召出；毒系群擾）
static func _centipede_brood() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "centipede_brood"
	enemy.display_name = "蜈蚣幼蟲"
	enemy.max_hp = 14
	enemy.portrait_path = "res://assets/art/enemies/centipede_brood.png"
	enemy.actions = [
		{"intent": "啃噬 4 + 蠱毒 2", "effects": [{"kind": "damage", "amount": 4}, {"kind": "poison", "amount": 2}]},
	]
	return enemy

# 召喚物 — 鎖妖塔殘魂（山靈巫后 phase 2 召出；魂吸下毒）
static func _tower_wisp() -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = "tower_wisp"
	enemy.display_name = "鎖妖塔殘魂"
	enemy.max_hp = 16
	enemy.portrait_path = "res://assets/art/enemies/tower_wisp.png"
	enemy.actions = [
		{"intent": "魂吸 4 + 蠱毒 1", "effects": [{"kind": "damage", "amount": 4}, {"kind": "poison", "amount": 1}]},
	]
	return enemy
