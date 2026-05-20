class_name EventData
extends RefCounted

const REST_HEAL_PERCENT: float = 0.25

const VARIANTS: Dictionary = {
	"spring": {
		"title": "幽泉清聲",
		"flavor": "山壁後藏著一眼清泉，水氣溫潤，卻也像在引你更深一步。",
		"heal": 12,
		"gain_cost": 7,
		"power": 1,
		"power_label": "凝神"
	},
	"talisman_cache": {
		"title": "符匣殘光",
		"flavor": "破舊符匣半埋土中，靈光未散。取用它，也可能驚動殘留禁制。",
		"heal": 6,
		"gain_cost": 4,
		"power": 2,
		"power_label": "催符"
	},
	"shrine": {
		"title": "山路異光",
		"flavor": "石壁間浮現微光，像是前人留下的靈痕。你可以停步調息，也可以冒險汲取其中力量。",
		"heal": 8,
		"gain_cost": 6,
		"power": 1,
		"power_label": "凝神"
	},
	"treasure_chest": {
		"title": "寶箱機關",
		"flavor": "倒塌的木箱半埋在落葉裡。鎖鏈鏽蝕但機關未解，輕觸還可聽見細微的扣響。",
		"heal": 4,
		"gain_cost": 3,
		"power": 1,
		"power_label": "解鎖"
	},
	"ancestor_relic": {
		"title": "先靈遺骨",
		"flavor": "古老的祭壇上擺著一具尚未化盡的骨殖，靈氣濃郁。傳說供奉者能繼承一縷意志。",
		"heal": 5,
		"gain_cost": 8,
		"power": 3,
		"power_label": "祈靈"
	}
}

static func for_variant(variant: String) -> Dictionary:
	return VARIANTS.get(variant, VARIANTS["shrine"]) as Dictionary

static func rest_heal_for(max_hp: int) -> int:
	return max(1, int(ceil(max_hp * REST_HEAL_PERCENT)))
