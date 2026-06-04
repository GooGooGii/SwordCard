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
			"id": "tianshi_fu",
			"display_name": "天師符",
			"rarity": "common",
			"description": "施加敵人 1 層破綻與 1 層虛弱。",
			"effects": [{"kind": "vulnerable", "amount": 1}, {"kind": "weak", "amount": 1}]
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
