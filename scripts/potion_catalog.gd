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
	]

static func by_id(id: String) -> Dictionary:
	for p: Dictionary in all():
		if p["id"] == id:
			return p
	return {}

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
