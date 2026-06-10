class_name PotionCatalog
extends RefCounted

static func all() -> Array[Dictionary]:
	return [
		{
			"id": "huichun_dan",
			"display_name": "回春丹",
			"rarity": "common",
			"description": "回復 15 點生命。",
			"effects": [{"kind": "heal", "amount": 15}]
		},
		{
			"id": "lingli_dan",
			"display_name": "靈力丹",
			"rarity": "common",
			"description": "本回合靈力 +2。",
			"effects": [{"kind": "energy", "amount": 2}]
		},
		{
			"id": "huti_fu",
			"display_name": "護體符",
			"rarity": "common",
			"description": "獲得 10 點護體。",
			"effects": [{"kind": "block", "amount": 10}]
		},
		{
			"id": "jiedu_san",
			"display_name": "解毒散",
			"rarity": "common",
			"description": "清除所有蠱毒。",
			"effects": [{"kind": "cure_poison"}]
		},
		{
			"id": "lingshe_dan",
			"display_name": "靈蛇膽",
			"rarity": "uncommon",
			"description": "施加敵人 3 層破綻。",
			"effects": [{"kind": "vulnerable", "amount": 3}]
		},
		{
			"id": "hugu_jiu",
			"display_name": "虎骨酒",
			"rarity": "uncommon",
			"description": "本場戰鬥攻擊力 +3。",
			"effects": [{"kind": "power", "amount": 3}]
		},
		{
			"id": "jinchuang_yao",
			"display_name": "金瘡藥",
			"rarity": "uncommon",
			"description": "回復 30 點生命。",
			"effects": [{"kind": "heal", "amount": 30}]
		},
		{
			"id": "tianling_dan",
			"display_name": "天靈丹",
			"rarity": "rare",
			"description": "回復 50 點生命。",
			"effects": [{"kind": "heal", "amount": 50}]
		},
		{
			"id": "xianren_xue",
			"display_name": "仙人遺血",
			"rarity": "rare",
			"description": "回復 40 點生命，並提升本場攻擊力 +2。",
			"effects": [{"kind": "heal", "amount": 40}, {"kind": "power", "amount": 2}]
		},
		{
			"id": "yuehun_cao",
			"display_name": "月魂草",
			"rarity": "rare",
			"description": "抽 3 張牌並恢復靈力 +1。",
			"effects": [{"kind": "draw", "amount": 3}, {"kind": "energy", "amount": 1}]
		},
		{
			# PAL1：蝶妖彩依以奇花異草煎製，用以續劉晉元之命的仙釀。
			"id": "baihua_xianniang",
			"display_name": "百花仙釀",
			"rarity": "rare",
			"description": "回復 25 點生命並清除所有蠱毒。",
			"effects": [{"kind": "heal", "amount": 25}, {"kind": "cure_poison"}]
		},
		{
			"id": "shexiang_wan",
			"display_name": "麝香丸",
			"rarity": "common",
			"description": "清除所有負面狀態。",
			"effects": [{"kind": "cure_debuff"}]
		},
		{
			"id": "xiongdan_jiu",
			"display_name": "雄膽酒",
			"rarity": "common",
			"description": "本場戰鬥攻擊力 +2，但受到 1 層虛弱。",
			"effects": [{"kind": "power", "amount": 2}, {"kind": "weak", "amount": 1}]
		},
		{
			"id": "xuehai_dan",
			"display_name": "血海丹",
			"rarity": "common",
			"description": "回復 8 點生命，並獲得 5 點護體。",
			"effects": [{"kind": "heal", "amount": 8}, {"kind": "block", "amount": 5}]
		},
		{
			# PAL1：天師符法為李逍遙習得的符咒攻擊系法術。
			"id": "tianshi_fu",
			"display_name": "天師符",
			"rarity": "common",
			"description": "對敵人造成 10 點傷害，並施加 1 層破綻與 1 層虛弱。",
			"effects": [{"kind": "damage", "amount": 10}, {"kind": "vulnerable", "amount": 1}, {"kind": "weak", "amount": 1}]
		},
		{
			# 投擲暗器，雷火炸裂。
			"id": "pili_zi",
			"display_name": "霹靂子",
			"rarity": "common",
			"description": "對敵人造成 12 點傷害。",
			"effects": [{"kind": "damage", "amount": 12}]
		},
		{
			# PAL1 靈珠系統：火靈珠可施火系法術。
			"id": "huoling_zhu",
			"display_name": "火靈珠",
			"rarity": "uncommon",
			"description": "對敵人造成 20 點火傷。",
			"effects": [{"kind": "damage", "amount": 20}]
		},
		{
			# PAL1 靈珠系統：雷靈珠可施雷系群攻法術。
			"id": "leiling_zhu",
			"display_name": "雷靈珠",
			"rarity": "uncommon",
			"description": "對所有敵人各造成 11 點雷傷。",
			"effects": [{"kind": "damage_all", "amount": 11}]
		},
		{
			# 玄火焚天，群攻並引燃蠱毒。
			"id": "fentian_zhu",
			"display_name": "焚天珠",
			"rarity": "rare",
			"description": "對所有敵人各造成 18 點傷害，並施加 2 層蠱毒。",
			"effects": [{"kind": "damage_all", "amount": 18}, {"kind": "poison_all", "amount": 2}]
		},
		{
			"id": "jiedu_cao",
			"display_name": "解毒草",
			"rarity": "common",
			"description": "清除所有蠱毒，並回復 3 點生命。",
			"effects": [{"kind": "cure_poison"}, {"kind": "heal", "amount": 3}]
		},
		{
			"id": "xiancha_san",
			"display_name": "仙茶散",
			"rarity": "uncommon",
			"description": "抽 2 張牌。",
			"effects": [{"kind": "draw", "amount": 2}]
		},
		{
			"id": "lingzhi_dan",
			"display_name": "靈芝丹",
			"rarity": "uncommon",
			"description": "本回合靈力 +1，並抽 1 張牌。",
			"effects": [{"kind": "energy", "amount": 1}, {"kind": "draw", "amount": 1}]
		},
		{
			"id": "fumo_xiang",
			"display_name": "伏魔香",
			"rarity": "uncommon",
			"description": "施加所有敵人 2 層虛弱。",
			"effects": [{"kind": "weak_all", "amount": 2}]
		},
		{
			"id": "shanhua_mijiu",
			"display_name": "山花蜜酒",
			"rarity": "uncommon",
			"description": "全隊回復 10 點生命。",
			"effects": [{"kind": "heal_party", "amount": 10}]
		},
		{
			"id": "duhuo_dan",
			"display_name": "毒活丸",
			"rarity": "uncommon",
			"description": "施加所有敵人 3 層蠱毒。",
			"effects": [{"kind": "poison_all", "amount": 3}]
		},
		{
			"id": "jiujie_changpu",
			"display_name": "九節菖蒲",
			"rarity": "rare",
			"description": "救回第一個倒下的後排同伴（回復 15 點生命），若無人倒下則改為自己回復 15 點生命。",
			"effects": [{"kind": "revive", "amount": 15}]
		},
		{
			"id": "longxian_shi",
			"display_name": "龍涎石",
			"rarity": "rare",
			"description": "獲得 25 點護體。",
			"effects": [{"kind": "block", "amount": 25}]
		},
		{
			"id": "shenxian_cha",
			"display_name": "神仙茶",
			"rarity": "rare",
			"description": "本回合靈力 +3。",
			"effects": [{"kind": "energy", "amount": 3}]
		},
		{
			"id": "zijin_dan",
			"display_name": "紫金丹",
			"rarity": "rare",
			"description": "全隊回復 20 點生命，並清除所有負面狀態。",
			"effects": [{"kind": "heal_party", "amount": 20}, {"kind": "cure_debuff"}]
		},
		{
			"id": "nvwa_yulu",
			"display_name": "女媧玉露",
			"rarity": "rare",
			"description": "回復 30 點生命，並提升本場攻擊力 +3。",
			"effects": [{"kind": "heal", "amount": 30}, {"kind": "power", "amount": 3}]
		},
		{
			"id": "jincan_wang",
			"display_name": "金蠶王",
			"rarity": "rare",
			"description": "使當前角色等級 +1，並立即習得該等級解鎖的全部招式（若有）。",
			"effects": [{"kind": "level_up"}]
		},
		{
			# 符咒定身：重擊加暈眩控場。
			"id": "dingshen_fu",
			"display_name": "定身符",
			"rarity": "uncommon",
			"description": "對敵人造成 6 點傷害並使其暈眩（下回合無法行動）。",
			"effects": [{"kind": "damage", "amount": 6}, {"kind": "stun", "amount": 1}]
		},
		{
			# 封印法術：剋施法系敵人 / boss。
			"id": "fengling_fu",
			"display_name": "封靈符",
			"rarity": "uncommon",
			"description": "封印敵人法術 2 回合（無法施法）。",
			"effects": [{"kind": "silence", "amount": 2}]
		},
		{
			# 苗蠱迷魂：使敵人失控，多敵時可能誤擊友軍。
			"id": "mihun_gu",
			"display_name": "迷魂蠱",
			"rarity": "rare",
			"description": "使敵人陷入瘋魔 1 回合（失控隨機攻擊，可能誤擊友軍）。",
			"effects": [{"kind": "berserk", "amount": 1}]
		},
		{
			# build-enabler（StS Duplication Potion 式）：下一張攻擊/技能牌發動兩次 → combo turn。
			"id": "fenshen_dan",
			"display_name": "分身丹",
			"rarity": "rare",
			"description": "下一張攻擊或技能牌效果發動兩次。",
			"effects": [{"kind": "next_card_double", "amount": 1}]
		},
		{
			# build-enabler（StS Fairy in a Bottle 式）：預先服下、瀕死時自動保命一次。
			"id": "xianren_yitui",
			"display_name": "仙人遺蛻",
			"rarity": "rare",
			"description": "服下後，本場戰鬥瀕死時自動回復 25 生命並存活（僅一次）。",
			"effects": [{"kind": "revive_charge", "amount": 25}]
		},
		{
			# build-enabler（StS Chaos/Entropic 式）：本回合手牌全 0 費 → 爆發 combo turn。
			"id": "hunyuan_dan",
			"display_name": "混元丹",
			"rarity": "rare",
			"description": "本回合手牌費用全部視為 0。",
			"effects": [{"kind": "free_turn"}]
		},
	]

static func by_id(id: String) -> Dictionary:
	for p: Dictionary in all():
		if p["id"] == id:
			return p
	return {}

# 戰鬥外仍有意義的 effect kind（回血、永久能力增益）。
# heal / heal_party 直接補 run HP；未來若加 max_hp 等永久 buff 也列在此。
const OUT_OF_BATTLE_VALUE_KINDS: Array[String] = ["heal", "heal_party", "max_hp", "level_up"]
# 戰鬥外無作用、但也不浪費價值的 kind（清毒在無毒時是 noop）。
const OUT_OF_BATTLE_NOOP_KINDS: Array[String] = ["cure_poison"]

# 此藥是否可在非戰鬥時使用：至少含一個「戰鬥外有價值」的 effect，且其餘 effect
# 都只是戰鬥外無害（noop）的——避免把 power/護體 等只在戰鬥有效的價值白白浪費掉。
static func usable_outside_battle(potion: Dictionary) -> bool:
	var has_value: bool = false
	for effect: Dictionary in (potion.get("effects", []) as Array):
		var kind: String = String(effect.get("kind", ""))
		if kind in OUT_OF_BATTLE_VALUE_KINDS:
			has_value = true
		elif not (kind in OUT_OF_BATTLE_NOOP_KINDS):
			return false
	return has_value

static func price_of(potion: Dictionary, is_black_shop: bool) -> int:
	var base: int = 40
	match potion.get("rarity", "common"):
		"uncommon":
			base = 65
		"rare":
			base = 95
	if is_black_shop:
		base = int(ceil(base * 1.2))
	return base

static func rarity_color(potion: Dictionary) -> Color:
	match potion.get("rarity", "common"):
		"uncommon":
			return Color("4adcff")
		"rare":
			return Color("c87eff")
	return Color("c8c8c8")
