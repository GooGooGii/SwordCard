class_name EventData
extends RefCounted

const REST_HEAL_PERCENT: float = 0.25

# choices: which buttons show up in this event (order matters)
# outcomes: flavor text displayed after each choice (key = choice key)
# pact_* / gamble_* fields are only used by their respective special events
const VARIANTS: Dictionary = {
	"spring": {
		"title": "幽泉清聲",
		"flavor": "山壁後藏著一眼清泉，水氣溫潤，卻也像在引你更深一步。",
		"heal": 12, "gain_cost": 7, "power": 1, "power_label": "凝神",
		"choices": ["heal", "gain_card", "power", "view_deck"],
		"outcomes": {
			"heal": "清泉水氣滌盡倦意，傷口悄然合攏。清冽的涼意在胸口久久不散。",
			"gain_card": "你伸手探入泉底，指尖觸到一縷泠冽靈韻——新的招式浮現腦海，如泉湧而出。",
			"power": "泉聲入耳如磬，靈台一清，劍意無形中更為凝實。"
		}
	},
	"talisman_cache": {
		"title": "符匣殘光",
		"flavor": "破舊符匣半埋土中，靈光未散。取用它，也可能驚動殘留禁制。",
		"heal": 6, "gain_cost": 4, "power": 2, "power_label": "催符",
		"choices": ["heal", "gain_card", "power", "remove"],
		"outcomes": {
			"heal": "符匣中溢出一縷溫熱靈氣，緩緩流入掌心，驅散了幾分傷痛。",
			"gain_card": "禁制應聲碎裂，靈光中浮現出一道術法的輪廓，烙進了你的記憶。",
			"power": "殘符入體，一道灼熱沿著招式的紋路走遍全身，殺意悄悄加深。",
			"remove": "你割斷那道殘餘禁制。雜念隨符灰一同飄散，心中忽然輕了許多。"
		}
	},
	"shrine": {
		"title": "山路異光",
		"flavor": "石壁間浮現微光，像是前人留下的靈痕。你可以停步調息，也可以冒險汲取其中力量。",
		"heal": 8, "gain_cost": 6, "power": 1, "power_label": "凝神",
		"choices": ["heal", "power", "upgrade"],
		"outcomes": {
			"heal": "靈痕輕觸肌膚，如同有人將一掌暖意按在背脊，傷口漸漸閉合。",
			"power": "古人的意念透過石壁注入，你感到某種久遠的殺意悄悄疊加進了自身。",
			"upgrade": "沉靜片刻，手中一道招式的謬誤竟自行顯現——你明白了它的精髓。"
		}
	},
	"treasure_chest": {
		"title": "寶箱機關",
		"flavor": "倒塌的木箱半埋在落葉裡。鎖鏈鏽蝕但機關未解，輕觸還可聽見細微的扣響。",
		"heal": 4, "gain_cost": 3, "power": 1, "power_label": "解鎖",
		"choices": ["gain_card", "upgrade", "remove"],
		"outcomes": {
			"gain_card": "機關應聲而開，箱底壓著一卷泛黃的功法殘頁，術法輪廓躍然紙上。",
			"upgrade": "鎖扣扣響，一股細微靈氣流過你的雙手，某道招式因此更趨純熟。",
			"remove": "倒刺擦過掌心，一陣刺痛——但某道雜亂的招式也隨之從腦海中剝落。"
		}
	},
	"ancestor_relic": {
		"title": "先靈遺骨",
		"flavor": "古老的祭壇上擺著一具尚未化盡的骨殖，靈氣濃郁。傳說供奉者能繼承一縷意志。",
		"heal": 5, "gain_cost": 8, "power": 3, "power_label": "祈靈",
		"choices": ["power", "upgrade", "heal"],
		"outcomes": {
			"power": "骨殖微微顫動，一縷殘存的意志悄然融入你的劍意，殺伐之氣更甚從前。",
			"upgrade": "那意志短暫地附在你手上，某道招式的謬誤就此被先靈之手抹去。",
			"heal": "虔誠供奉，先靈庇佑，傷口癒合的速度比尋常快了幾分。"
		}
	},
	"wandering_sage": {
		"title": "雲遊隱士",
		"flavor": "竹笠下白髮垂胸的老者煮著一壺粗茶，看你走來只是抬眼，不發一語。",
		"heal": 10, "gain_cost": 5, "power": 2, "power_label": "問道",
		"choices": ["heal", "upgrade", "remove", "view_deck"],
		"outcomes": {
			"heal": "老者拈起一把草葉往你傷口一貼，涼意透入，血色退去大半。",
			"upgrade": "老者只說了半句話，你便悟透了剩下那半句——那道招式從此不同了。",
			"remove": "老者搖搖頭：「此式有礙根基。」隨手將那頁功法投入爐火，煙散無痕。"
		}
	},
	"moonlit_pool": {
		"title": "月光浸水潭",
		"flavor": "夜色凝在潭面，倒映出比山更深的星辰。傳說潭水能洗去俗血、也能引出舊傷。",
		"heal": 15, "gain_cost": 9, "power": 1, "power_label": "沐月",
		"choices": ["heal", "power"],
		"outcomes": {
			"heal": "月光滲入水中，你的舊傷如紙浸軟、輕輕化開，浮上水面的是清澈的倒影。",
			"power": "潭面映出你自己的雙眼——那雙眼裡，有什麼東西比昨夜更深了。"
		}
	},
	"broken_temple": {
		"title": "廢棄山神廟",
		"flavor": "山神泥像剝落大半，神龕底卻還壓著一道暗紅符紙，墨色仍鮮。",
		"heal": 4, "gain_cost": 2, "power": 3, "power_label": "撕符",
		"choices": ["gain_card", "power", "remove"],
		"outcomes": {
			"gain_card": "符紙在掌心炸裂，一道混濁卻濃烈的術法如烙印燒進了你的記憶。",
			"power": "你將那道暗紅符紙投入口中。灼熱自丹田升起，殺意更烈，心卻意外地更靜。",
			"remove": "紙灰飄散，某一式冗餘的招法跟著消散——如同卸下了一件舊時的鎧甲。"
		}
	},
	"yokai_pact": {
		"title": "妖契",
		"flavor": "黑霧中浮起一張瓜子臉，眼底比夜還黑。「給我一點，我給你十倍。」",
		"heal": 0, "gain_cost": 4, "power": 4, "power_label": "立契",
		"pact_max_hp_cost": 8, "pact_power": 4,
		"choices": ["gain_card", "pact"],
		"outcomes": {
			"gain_card": "黑霧中遞來一卷黑色符紙，術法的輪廓燒灼在指尖，讓你不舒服卻難以拒絕。",
			"pact": "妖女抬手，一縷黑絲穿過你的胸口。你感到生機被悄悄抽走一縷——但那股力量確實湧了進來。"
		}
	},
	"forgotten_altar": {
		"title": "棄祭壇",
		"flavor": "風吹過破爛的供品。香爐裡還有一炷未滅的香，灰燼下隱約有字跡。",
		"heal": 7, "gain_cost": 6, "power": 2, "power_label": "焚香",
		"choices": ["heal", "power", "upgrade"],
		"outcomes": {
			"heal": "香灰中壓著一帖古方，入口苦澀，卻有一股暖意從丹田散開，傷口漸止。",
			"power": "香煙繞身，灰燼下的字跡拼成一套手訣——你只看了一眼，便已銘記於心。",
			"upgrade": "火光中字跡浮現，某道招式的癥結所在，你終於在這一炷香裡讀懂了。"
		}
	},
	"ancient_battlefield": {
		"title": "古戰場遺跡",
		"flavor": "殘破的旌旗插在乾涸的血土上，風過時像是有人低鳴。踏入此地，眼前不自覺浮現金戈鐵馬。",
		"heal": 3, "gain_cost": 5, "power": 3, "power_label": "祭英靈",
		"choices": ["power", "upgrade", "view_deck"],
		"outcomes": {
			"power": "鐵馬嘯聲穿越千年壓來，死亡的殺機從血土中沁透腳底，浸入你的每一道招式。",
			"upgrade": "亡靈的眼神在你某道招式上短暫停留——離開時，那招已帶上了戰場的鋒銳。"
		}
	},
	"alchemy_furnace": {
		"title": "煉丹爐火",
		"flavor": "青石台上的爐子還燒著，藥香混著焦味。爐蓋壓著一張藥方，字跡模糊。",
		"heal": 10, "gain_cost": 8, "power": 2, "power_label": "服丹",
		"choices": ["heal", "gain_card", "upgrade"],
		"outcomes": {
			"heal": "藥香入鼻，熱氣蒸騰，舊傷在爐火的溫度中悄悄癒合，比預期快了幾分。",
			"gain_card": "藥方上的字跡在火光中顯形，是一套從未見過的鍛體之法——你將它記下。",
			"upgrade": "爐火高燃，你將那道招式在熱浪中反覆鍛打，純度比鍊丹之前高了一層。"
		}
	},
	"ghost_forest": {
		"title": "鬼林迷霧",
		"flavor": "樹影在霧中晃動，有什麼在彼端注視著你。越深入，心跳卻越發清晰有力。",
		"heal": 0, "gain_cost": 3, "power": 5, "power_label": "借膽",
		"gamble_win_power": 5, "gamble_lose_damage": 10,
		"choices": ["gain_card", "gamble"],
		"outcomes": {
			"gain_card": "霧中有什麼東西跟了你一段路，離去前在地上留下一手殘術。",
			"gamble_win": "心跳越來越清晰，不再是恐懼——是膽氣。那股力量從丹田直衝頭頂。",
			"gamble_lose": "樹影猛地撲來，爪痕划過胸口。你忍著痛跑出了霧林，背後有嘲笑聲漸漸遠去。"
		}
	},
	"immortal_ruins": {
		"title": "仙人遺址",
		"flavor": "地上的符紋已褪色，踩上去腳底仍有微微震動，像是某種呼吸尚未停止。",
		"heal": 6, "gain_cost": 6, "power": 2, "power_label": "感悟",
		"choices": ["power", "upgrade", "view_deck"],
		"outcomes": {
			"power": "符紋震動，古仙的意念透過腳底傳入——某種久遠的悟境，在這一刻流過了你。",
			"upgrade": "仙人的殘跡讓你看懂了一道本以為無從精進的招式，那道罅隙終於彌合。"
		}
	}
}

static func for_variant(variant: String) -> Dictionary:
	return VARIANTS.get(variant, VARIANTS["shrine"]) as Dictionary

static func rest_heal_for(max_hp: int) -> int:
	return max(1, int(ceil(max_hp * REST_HEAL_PERCENT)))
