class_name RelicCatalog
extends RefCounted

# 56 件裝備：45 通用 + 8 角色專武 + 3 神器

static func all() -> Array[RelicData]:
	var list: Array[RelicData] = []
	list.append_array(_generals())
	list.append_array(_weapons())
	list.append_array(_artifacts())
	return list

static func by_id(id: String) -> RelicData:
	for r: RelicData in all():
		if r.id == id:
			return r.clone()
	return null

static func generals() -> Array[RelicData]:
	return _generals()

static func weapons() -> Array[RelicData]:
	return _weapons()

static func artifacts() -> Array[RelicData]:
	return _artifacts()

static func weapons_for_character(character_id: String) -> Array[RelicData]:
	var out: Array[RelicData] = []
	for r: RelicData in _weapons():
		if r.character_id == character_id:
			out.append(r)
	return out

static func _make(id: String, name: String, desc: String, rarity: String, triggers: Array[Dictionary], color: Color = Color("c8b46f"), shape: String = "diamond") -> RelicData:
	var r: RelicData = RelicData.new()
	r.id = id
	r.display_name = name
	r.description = desc
	r.rarity = rarity
	r.slot = "general"
	r.triggers = triggers
	r.icon_color = color
	r.icon_shape = shape
	return r

static func _make_weapon(id: String, name: String, desc: String, char_id: String, rarity: String, triggers: Array[Dictionary], color: Color) -> RelicData:
	var r: RelicData = _make(id, name, desc, rarity, triggers, color, "star")
	r.slot = "weapon"
	r.character_id = char_id
	return r

static func _make_artifact(id: String, name: String, desc: String, boss_id: String, triggers: Array[Dictionary], color: Color) -> RelicData:
	var r: RelicData = _make(id, name, desc, "legendary", triggers, color, "hex")
	r.slot = "artifact"
	r.boss_id = boss_id
	return r

static func _generals() -> Array[RelicData]:
	var l: Array[RelicData] = []
	# ── 8 battle_start effects (開場一次性) ──
	l.append(_make("hu_xin_jing", "護心鏡", "戰鬥開始獲得 8 護體。", "common",
		[{"trigger": "battle_start", "effects": [{"kind": "self_block", "amount": 8}]}], Color("a8c4e8")))
	l.append(_make("yu_ling_yu", "御靈玉", "戰鬥開始獲得 5 護體。", "common",
		[{"trigger": "battle_start", "effects": [{"kind": "self_block", "amount": 5}]}], Color("8edcff")))
	l.append(_make("long_xue_shi", "龍血石", "戰鬥開始回復 6 生命。", "common",
		[{"trigger": "battle_start", "effects": [{"kind": "self_heal", "amount": 6}]}], Color("d76a5a")))
	l.append(_make("she_dan", "蛇膽", "戰鬥開始敵人受到 3 層蠱毒。", "common",
		[{"trigger": "battle_start", "effects": [{"kind": "enemy_poison", "amount": 3}]}], Color("76c46a")))
	l.append(_make("zhu_sha_bi", "朱砂筆", "戰鬥開始敵人虛弱 2 層。", "uncommon",
		[{"trigger": "battle_start", "effects": [{"kind": "enemy_weak", "amount": 2}]}], Color("c84a3a")))
	l.append(_make("han_shuang_zhu", "寒霜珠", "戰鬥開始敵人破綻 2 層。", "uncommon",
		[{"trigger": "battle_start", "effects": [{"kind": "enemy_vulnerable", "amount": 2}]}], Color("9bd8ff")))
	l.append(_make("ning_qi_dan", "凝氣丹", "戰鬥開始多 1 點靈力（僅第 1 回合）。", "uncommon",
		[{"trigger": "battle_start", "effects": [{"kind": "self_energy", "amount": 1}]}], Color("c8b46f")))
	l.append(_make("feng_hun_yu", "風魂玉", "本場戰鬥傷害 +1。", "rare",
		[{"trigger": "battle_start", "effects": [{"kind": "self_power", "amount": 1}]}], Color("f4d985")))
	# ── 8 turn_start effects (每回合開始) ──
	l.append(_make("wu_qi_chao_yuan", "五氣朝元", "每回合開始獲得 3 護體。", "common",
		[{"trigger": "turn_start", "effects": [{"kind": "self_block", "amount": 3}]}], Color("a8c4e8")))
	l.append(_make("nian_xiang_lu", "戀香爐", "每回合開始回復 1 生命。", "common",
		[{"trigger": "turn_start", "effects": [{"kind": "self_heal", "amount": 1}]}], Color("e08a76")))
	l.append(_make("zhi_fu_xiang", "紙符箱", "每回合開始額外抽 1 張牌。", "rare",
		[{"trigger": "turn_start", "effects": [{"kind": "self_draw", "amount": 1}]}], Color("f4d985")))
	l.append(_make("shi_gu_zhen", "蝕骨陣", "每回合開始敵人 +1 層蠱毒。", "uncommon",
		[{"trigger": "turn_start", "effects": [{"kind": "enemy_poison", "amount": 1}]}], Color("6aa44a")))
	l.append(_make("feng_ling_dang", "風鈴鐺", "每回合開始敵人 +1 層破綻。", "uncommon",
		[{"trigger": "turn_start", "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("9bd8ff")))
	l.append(_make("e_yun_fu", "厄運符", "每回合開始敵人 +1 層虛弱。", "uncommon",
		[{"trigger": "turn_start", "effects": [{"kind": "enemy_weak", "amount": 1}]}], Color("c84a3a")))
	l.append(_make("yu_qi_lin", "玉麒麟", "每回合開始獲得 5 護體。", "uncommon",
		[{"trigger": "turn_start", "effects": [{"kind": "self_block", "amount": 5}]}], Color("d9c2ff")))
	l.append(_make("zhao_hun_fan", "招魂幡", "戰鬥第一回合多抽 1 張牌。", "common",
		[{"trigger": "battle_start", "effects": [{"kind": "self_draw_next_turn", "amount": 1}]}], Color("8a76c8")))
	# ── 8 turn_end effects (回合結束) ──
	l.append(_make("zhu_que_huo", "朱雀火", "每回合結束對敵人造成 3 傷害。", "uncommon",
		[{"trigger": "turn_end", "effects": [{"kind": "enemy_damage", "amount": 3}]}], Color("c84a3a")))
	l.append(_make("xuan_wu_hun", "玄武魂", "每回合結束保留 2 護體（轉到下回合）。", "rare",
		[{"trigger": "turn_end", "effects": [{"kind": "block_carry", "amount": 2}]}], Color("4a6478")))
	l.append(_make("qing_long_yi", "青龍翼", "每回合結束回復 1 生命。", "common",
		[{"trigger": "turn_end", "effects": [{"kind": "self_heal", "amount": 1}]}], Color("76c4d8")))
	l.append(_make("bai_hu_ya", "白虎牙", "每回合結束對敵人造成 2 傷害。", "common",
		[{"trigger": "turn_end", "effects": [{"kind": "enemy_damage", "amount": 2}]}], Color("e8e2c8")))
	l.append(_make("yin_hun_deng", "引魂燈", "每回合結束敵人 +1 層蠱毒。", "common",
		[{"trigger": "turn_end", "effects": [{"kind": "enemy_poison", "amount": 1}]}], Color("8a76c8")))
	l.append(_make("zi_fu_fu", "紫府符", "每回合結束獲得 2 護體。", "common",
		[{"trigger": "turn_end", "effects": [{"kind": "self_block", "amount": 2}]}], Color("9b76d8")))
	l.append(_make("lei_zhen_zi", "雷震子", "每回合結束敵人 +1 層破綻。", "uncommon",
		[{"trigger": "turn_end", "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("f4d985")))
	l.append(_make("xue_hun_fu", "雪魂符", "每回合結束回復 1 生命並獲得 1 護體。", "uncommon",
		[{"trigger": "turn_end", "effects": [{"kind": "self_heal", "amount": 1}, {"kind": "self_block", "amount": 1}]}], Color("c8e8ff")))
	# ── 8 card_played triggers (出牌時) ──
	l.append(_make("lie_huo_ling", "烈火令", "每出一張攻擊牌，對敵人額外造成 1 傷害。", "uncommon",
		[{"trigger": "card_played", "filter": {"card_type": "attack"}, "effects": [{"kind": "enemy_damage", "amount": 1}]}], Color("e25a3a")))
	l.append(_make("jiao_long_xian", "蛟龍弦", "每出一張攻擊牌，敵人 +1 層破綻（每場戰鬥僅前 3 次）。", "rare",
		[{"trigger": "card_played", "filter": {"card_type": "attack", "max_per_battle": 3}, "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("4a8acd")))
	l.append(_make("zhen_shan_fan", "鎮山幡", "每出一張技能牌，獲得 2 額外護體。", "uncommon",
		[{"trigger": "card_played", "filter": {"card_type": "skill"}, "effects": [{"kind": "self_block", "amount": 2}]}], Color("76c4a8")))
	l.append(_make("tie_xue_ling", "鐵血令", "每場戰鬥第 1 次出技能牌時，回復 2 生命。", "common",
		[{"trigger": "card_played", "filter": {"card_type": "skill", "max_per_battle": 1}, "effects": [{"kind": "self_heal", "amount": 2}]}], Color("a85a4a")))
	l.append(_make("wu_cai_shi", "五彩石", "出能力牌時，敵人 +2 層蠱毒。", "uncommon",
		[{"trigger": "card_played", "filter": {"card_type": "power"}, "effects": [{"kind": "enemy_poison", "amount": 2}]}], Color("d9c2ff")))
	l.append(_make("nu_mu_zhu", "怒目珠", "每次獲得護體，敵人 +1 層破綻。", "uncommon",
		[{"trigger": "card_played", "filter": {"effect_has": "block"}, "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("c84a3a")))
	l.append(_make("long_lin_jia", "龍鱗甲", "每次獲得護體，額外 +2 護體。", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "block_bonus", "amount": 2}]}], Color("76c4d8")))
	l.append(_make("yin_hun_die", "引魂蝶", "出 0 費牌時，下回合多抽 1 張。", "rare",
		[{"trigger": "card_played", "filter": {"cost_eq": 0}, "effects": [{"kind": "self_draw_next_turn", "amount": 1}]}], Color("e2a8ff")))
	# ── 8 passive modifiers (常駐) ──
	l.append(_make("tie_gu_dan", "鐵骨丹", "受到的傷害 -1。", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "damage_taken_reduction", "amount": 1}]}], Color("786258")))
	l.append(_make("gui_jia_fu", "龜甲符", "受到的傷害 -2（最低 0）。", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "damage_taken_reduction", "amount": 2}]}], Color("6a8a78")))
	l.append(_make("nu_huo_ling", "怒火令", "造成的傷害 +2。", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "damage_out_bonus", "amount": 2}]}], Color("c84a3a")))
	l.append(_make("zui_xian_hu", "醉仙葫", "造成的傷害 +1。", "uncommon",
		[{"trigger": "passive_modifier", "effects": [{"kind": "damage_out_bonus", "amount": 1}]}], Color("d8a456")))
	l.append(_make("tai_ji_zhu", "太極珠", "治療效果 +2。", "uncommon",
		[{"trigger": "passive_modifier", "effects": [{"kind": "heal_bonus", "amount": 2}]}], Color("e8e2c8")))
	l.append(_make("fan_hun_zhou", "反魂咒", "敵人受到的蠱毒 +1。", "uncommon",
		[{"trigger": "passive_modifier", "effects": [{"kind": "poison_bonus", "amount": 1}]}], Color("8a4a76")))
	l.append(_make("zhen_hun_yu", "鎮魂玉", "獲得的護體 +1。", "uncommon",
		[{"trigger": "passive_modifier", "effects": [{"kind": "block_bonus", "amount": 1}]}], Color("a8c4e8")))
	l.append(_make("hu_fa_zhou", "護法咒", "戰鬥開始回復 4 生命，受到的傷害 -1。", "rare",
		[{"trigger": "battle_start", "effects": [{"kind": "self_heal", "amount": 4}]},
		{"trigger": "passive_modifier", "effects": [{"kind": "damage_taken_reduction", "amount": 1}]}], Color("c8b46f")))
	# ── 5 economy / non-battle ──
	l.append(_make("ju_bao_pen", "聚寶盆", "戰鬥勝利額外獲得 12 銅錢。", "common",
		[{"trigger": "battle_victory", "effects": [{"kind": "gold_bonus", "amount": 12}]}], Color("e4c66a")))
	l.append(_make("tong_bao_qian", "通寶錢", "商店每件商品 -8 銅錢。", "uncommon",
		[{"trigger": "permanent", "effects": [{"kind": "shop_discount", "amount": 8}]}], Color("c8b46f")))
	l.append(_make("suo_hun_huan", "鎖魂環", "休息回復額外 +10 HP。", "uncommon",
		[{"trigger": "permanent", "effects": [{"kind": "rest_heal_bonus", "amount": 10}]}], Color("e0e4f0")))
	l.append(_make("yao_qian_shu", "搖錢樹", "奇遇增傷 +1。", "uncommon",
		[{"trigger": "permanent", "effects": [{"kind": "event_power_bonus", "amount": 1}]}], Color("76c46a")))
	l.append(_make("duo_bao_ge", "多寶閣", "卡牌獎勵顯示 4 張（原 3）。", "rare",
		[{"trigger": "permanent", "effects": [{"kind": "card_reward_count_bonus", "amount": 1}]}], Color("d9c2ff")))
	return l

static func _weapons() -> Array[RelicData]:
	var l: Array[RelicData] = []
	# 李逍遙 (劍)
	l.append(_make_weapon("chunjun_jian", "純鈞劍", "戰鬥開始本場戰鬥造成的傷害 +1。", "li_xiaoyao", "uncommon",
		[{"trigger": "battle_start", "effects": [{"kind": "self_power", "amount": 1}]}], Color("a8c4e8")))
	l.append(_make_weapon("longquan_jian", "龍泉劍", "戰鬥開始敵人 +2 層破綻。", "li_xiaoyao", "rare",
		[{"trigger": "battle_start", "effects": [{"kind": "enemy_vulnerable", "amount": 2}]}], Color("9bd8ff")))
	# 趙靈兒 (法器)
	l.append(_make_weapon("suoyao_yu", "鎖妖玉", "戰鬥開始回復 10 生命。", "zhao_linger", "uncommon",
		[{"trigger": "battle_start", "effects": [{"kind": "self_heal", "amount": 10}]}], Color("d9c2ff")))
	l.append(_make_weapon("nuwa_shi", "女媧石", "治療效果 +3。", "zhao_linger", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "heal_bonus", "amount": 3}]}], Color("e2a8ff")))
	# 林月如 (鞭劍)
	l.append(_make_weapon("longshe_zhang", "龍蛇杖", "戰鬥開始本場戰鬥造成的傷害 +2。", "lin_yueru", "rare",
		[{"trigger": "battle_start", "effects": [{"kind": "self_power", "amount": 2}]}], Color("c84a3a")))
	l.append(_make_weapon("xuanshuang_bian", "玄霜鞭", "每出一張攻擊牌，敵人 +1 層破綻。", "lin_yueru", "rare",
		[{"trigger": "card_played", "filter": {"card_type": "attack"}, "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("8edcff")))
	# 阿奴 (蠱蟲)
	l.append(_make_weapon("wanyi_wang", "萬蟻王", "敵人受到的蠱毒 +2。", "anu", "rare",
		[{"trigger": "passive_modifier", "effects": [{"kind": "poison_bonus", "amount": 2}]}], Color("6aa44a")))
	l.append(_make_weapon("shigu_gu", "蝕骨蠱", "每回合開始敵人 +2 層蠱毒。", "anu", "rare",
		[{"trigger": "turn_start", "effects": [{"kind": "enemy_poison", "amount": 2}]}], Color("8a4a76")))
	return l

static func _artifacts() -> Array[RelicData]:
	var l: Array[RelicData] = []
	l.append(_make_artifact("baiyue_shenfu", "拜月神符",
		"戰鬥開始敵人虛弱 3 層、破綻 3 層。每回合結束敵人 +1 層破綻。",
		"moon_worshipper",
		[{"trigger": "battle_start", "effects": [{"kind": "enemy_weak", "amount": 3}, {"kind": "enemy_vulnerable", "amount": 3}]},
		{"trigger": "turn_end", "effects": [{"kind": "enemy_vulnerable", "amount": 1}]}], Color("d9c2ff")))
	l.append(_make_artifact("wugong_jia", "蜈蚣甲",
		"受到的傷害 -3（最低 0）。每回合開始獲得 4 護體。",
		"centipede_lord",
		[{"trigger": "passive_modifier", "effects": [{"kind": "damage_taken_reduction", "amount": 3}]},
		{"trigger": "turn_start", "effects": [{"kind": "self_block", "amount": 4}]}], Color("76c46a")))
	l.append(_make_artifact("shiling_gu", "噬靈骨",
		"敵人受到的蠱毒 +2。每回合結束對敵人造成的蠱毒翻倍引爆 50%。",
		"witch_queen",
		[{"trigger": "passive_modifier", "effects": [{"kind": "poison_bonus", "amount": 2}]},
		{"trigger": "turn_end", "effects": [{"kind": "poison_resonance", "amount": 50}]}], Color("e2a8ff")))
	return l
