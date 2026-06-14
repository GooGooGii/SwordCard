class_name EventData
extends RefCounted

const REST_HEAL_PERCENT: float = 0.25

# choices: which buttons show up in this event (order matters)
# outcomes / character_outcomes: flavor text after each choice
# character_flavors: per-character opening prose (keyed by character id)
const VARIANTS: Dictionary = {
	"spring": {
		"title": "幽泉清聲",
		"flavor": "山壁後藏著一眼清泉，水氣溫潤，卻也像在引你更深一步。",
		"character_flavors": {
			"li_xiaoyao": "山壁後藏著一眼清泉，水聲淙淙。逍遙蹲下來用手掬水嚐了一口，涼意沁入喉頭，比餘杭客棧最好的花雕還爽快。外婆說，後院那口老井裡住著水神——現在他覺得，這眼泉裡，搞不好也住著什麼。",
			"zhao_linger": "清泉的水氣撲來，靈兒不由自主地停下腳步。她蹲下來，把手腕伸入水中——涼意沿著脈搏一路竄上手肘，讓她輕輕地吸了一口氣。四下無人，她乾脆把外袍的袖子往上挽，讓泉水漫過小臂，看著水面漾動，倒映出她有些泛紅的臉頰。",
			"lin_yueru": "月如注視著清泉，斷定靈氣來源純淨無虞，才允許自己放鬆戒備。父親林天南說過：『上善若水，知水者知劍。』她靜靜地聆聽了片刻，覺得劍意無形中沉澱了幾分，像是找到了一個久違的錨。",
			"anu": "阿奴在泉邊蹲了很久，只是看著水流。苗疆的山泉是苦的，帶著礦石與草藥的味道；這裡的水卻甜，讓她想起一些說不清道不明的遙遠事情。她把指尖浸進水裡，感受那一絲細微的靈氣，覺得此刻什麼都不必說。",
		},
		"heal": 12, "gain_cost": 7, "power": 1, "power_label": "凝神",
		"observe_text": "你蹲在泉邊靜聽。水聲底下藏著另一種更細微的聲音——像是有靈體在水脈深處低語，但不帶威脅，只是純粹的存在感。這眼泉並非無主，但泉靈寬厚，不會苛責造訪者。",
		"observe_effects": [{"kind": "heal", "amount": 5}, {"kind": "gold", "amount": 5}],
		"choices": ["heal", "gain_card", "power", "view_deck", "observe", "leave"],
		"outcomes": {
			"heal": "清泉水氣滌盡倦意，傷口悄然合攏。清冽的涼意從掌心漫上胸口，比任何藥草都要久久不散。",
			"gain_card": "你伸手探入泉底，指尖觸到一縷泠冽靈韻——新的招式如泉湧而出，澄澈而自然，不帶一絲雜念。",
			"power": "泉聲入耳如磬，靈台一清。你閉目聆聽良久，劍意在水聲中無形地凝練，變得更堅實，也更沉靜。"
		},
		# ── tree schema (Phase 1 schema demonstration) ────────────────
		# 對應 docs/EVENT_BRANCHING.md「已凍結的 6 個事件分支樹」之 spring。
		# UI 接 tree 走訪在 P2；effects 結算在 P6 加 kinds（gain_relic_pool /
		# next_battle_buff / permanent_power）。目前此 tree 只給 EventRunner
		# + smoke test 走訪用，舊扁平 schema 仍是 runtime fallback。
		"tree": {
			"root": {
				"prompt": "水聲是先到的，隔著一面山壁，淙淙地敲。繞過去，一眼清泉嵌在石窩裡，水面平得像一塊未琢的鏡，倒映著你風塵僕僕的臉。水氣溫潤撲面，喉頭忽然發緊——這一路，你已經很久沒有喝過一口乾淨的水了。",
				"choices": [
					{
						"id": "drink",
						"label": "掬一捧，痛快喝下",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 12},
								{"kind": "next_battle_buff", "effects": [{"kind": "energy", "amount": 1}]},
							],
							"log": "清冽順著喉頭一路涼到底，連日的疲乏像被水沖開的泥。你長長吐出一口氣，丹田裡有一縷暖意自己升了起來——下一場交手，你的氣會比平時更足。",
						},
					},
					{
						"id": "bathe",
						"label": "卸甲入水，洗去一身風塵",
						"kind_hint": "mixed",
						"next": "node_bathe",
					},
					{
						"id": "observe_pool",
						"label": "屏息凝神，細看泉底",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_observe",
					},
					{
						"id": "lxy_meditate",
						"label": "（李逍遙）學師父的樣子，臨水打坐",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 10},
							],
							"log": "酒劍仙說過：「水不爭，所以無物能傷。」當時逍遙只當醉話。此刻盤膝臨泉，水聲一圈圈漫過耳朵，那句醉話忽然在經脈裡走通了——他睜眼時，握劍的手穩了一分，往後都是。",
						},
					},
					{
						"id": "siphon_spring_spirit",
						"label": "以劍逼泉，強取泉靈精華",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "gain_card_pool", "pool": "rare"},
								{"kind": "damage", "amount": 8},
								{"kind": "gain_curse", "curse_id": "yao_zhai"},
							],
							"log": "劍尖入水的剎那，整眼泉像被踩了尾巴的活物猛地一縮。冰冷的呵斥順著劍身灌進經脈，你咬牙撐住，硬是從翻湧的水心扯出一縷精純靈韻。拔劍退開，掌心發白——拿是拿到了，但水面再不映你的影子。山野有靈，這筆債記下了。",
						},
					},
					{
						"id": "bandit_ambush",
						"label": "水面倒影裡，多了一個不該在的人",
						"kind_hint": "battle",
						"requires": {"event_flag": "marked_by_bandits"},
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "thug",
								"enemy_hp_mult": 1.0,
								"victory_effects": [
									{"kind": "gold", "amount": 25},
									{"kind": "set_flag", "flag": "marked_by_bandits", "value": false},
								],
								"defeat_effects": [
									{"kind": "gold", "amount": -20},
								],
							},
							"log": "你沒有回頭，只是看著水面——倒影裡那人躡步而來，刀已出半鞘。是酒館裡那隻悄悄轉過來的耳朵，一路跟到了這眼泉邊。山靜，水清，正好算帳。",
						},
					},
					{
						"id": "leave",
						"label": "向泉水拱手，不擾此地清修",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你掬起一捧水洗了把臉，向泉眼拱了拱手。轉身走出幾步，水聲還跟著你，像是送客，又像是道別。"},
					},
				],
			},
			"nodes": {
				"node_bathe": {
					"prompt": "你解下兵刃放在伸手可及的石上，緩緩沒入水中。水深及腰，涼意貼著皮膚收緊又鬆開，連日的瘀傷在水裡輕輕發燙。就在你閉眼的瞬間——水底深處，有什麼東西碰了碰你的腳踝。很輕，像試探。",
					"choices": [
						{
							"id": "relax",
							"label": "不動，把自己交給這眼泉",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.6,
									"win_effects": [
										{"kind": "power", "amount": 1},
										{"kind": "max_hp", "amount": 2},
									],
									"lose_effects": [
										{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 2}]},
										{"kind": "gold", "amount": -8},
									],
								},
								"log": "你聽見自己的心跳沉進水聲裡，那個輕輕的觸碰繞著你游了一圈，又一圈——是福是禍，全看泉靈今日的心情了。",
							},
						},
						{
							"id": "alert",
							"label": "按住石上的兵刃，緩緩起身",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 6},
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 5}]},
								],
								"log": "你的手指剛碰到劍柄，腳踝邊那絲流動便倏地退了。水面盪開一圈淺笑似的漣漪——泉靈識趣，你也識趣。彼此留了體面，你帶著一身警醒上岸，這份警醒會替你擋下一陣。",
							},
						},
					],
				},
				"node_observe": {
					"prompt": "你沉下呼吸，目光一寸寸推開水光。泉底鋪著圓潤的卵石，其中一塊不是石——是玉，磨得極平，刻著半枚你不認得的上古符紋，像被人鄭重地沉在這裡，又像在等誰來撿。",
					"choices": [
						{
							"id": "take_jade",
							"label": "探手入水，取那塊玉",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "gold", "amount": 5},
								],
								"log": "指尖破開水面，涼意直竄手肘。那塊玉像是等了很久，輕輕一托便離了泉底，入掌溫潤微熱，彷彿還帶著誰的體溫。水面合攏，倒影裡你的身後，似乎有什麼悄悄退開了。",
							},
						},
						{
							"id": "leave_jade",
							"label": "看清楚了，但讓它留在原處",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 8},
									{"kind": "power", "amount": 1},
								],
								"log": "有些東西沉在水底，是有人託付給水的。你收回手，向泉心微微頷首。水聲忽然軟了一拍，一縷暖意逆著指尖游上來——泉靈記下了你的分寸，這份回禮，比玉重。",
							},
						},
					],
				},
			},
		},
	},
	"talisman_cache": {
		"title": "符匣殘光",
		"flavor": "破舊符匣半埋土中，靈光未散。取用它，也可能驚動殘留禁制。",
		"character_flavors": {
			"li_xiaoyao": "逍遙用腳踢了踢那個半埋的符匣，靈光不穩地閃了閃，像隻被踩了尾巴的貓。「這到底是寶物，還是地雷？」他蹲下去仔細端詳，鎖鏈鏽蝕，但禁制尚在，隱隱透著一種試探的氣息——彷彿在問他：有膽，就拿。",
			"zhao_linger": "靈兒以指尖輕觸匣面，符文的走向讓她一怔——那筆觸與靈族文字有幾分相似，卻像是被人生硬地翻譯過，溫柔已然磨損，只剩力量。她把指腹慢慢貼上禁制，那一刻，指尖傳來一陣不尋常的溫熱，像有什麼在另一邊輕輕回握了一下。靈兒把手縮回，低著頭，不讓人看見她有些泛紅的耳尖。",
			"lin_yueru": "月如拔出佩劍，在符匣周圍確認了一圈。林家堡的規矩是：不明之物，先查再動。符文層次分明，出自行家，靈光的溫度也比預期穩定——這是某個認真修道之人留下的遺物，並非陷阱。她把劍收回，蹲下身來。",
			"anu": "阿奴從腰間取出一根骨針，試探性地碰了碰禁制的邊緣。在苗疆，這種殘留的靈跡通常由女巫接手，用來煉蠱或鎮邪。骨針感應到的靈氣溫和而陳舊，主人離去已久，不再有人來過了——她把骨針收回，仔細思量。",
		},
		"heal": 6, "gain_cost": 4, "power": 2, "power_label": "催符",
		"observe_text": "你細細打量符匣。鎖鏈鏽蝕但禁制完整，符文走向是中原正統派系，書寫的人態度極為認真——這不是隨意拋棄的，是某個修者刻意留下的「給有緣人」的遺贈。其中一道符紋帶著一絲警告意味：「貪者，反噬」。",
		"observe_effects": [{"kind": "heal", "amount": 4}, {"kind": "power", "amount": 1}],
		"choices": ["heal", "gain_card", "power", "remove", "observe", "leave"],
		"outcomes": {
			"heal": "符匣中溢出一縷溫熱靈氣，緩緩流入掌心，驅散了幾分傷痛。那股暖意像有人把手攏在你的傷口上，不聲不響地待了片刻。",
			"gain_card": "禁制應聲碎裂，靈光中浮現出一道術法的輪廓，烙進了你的記憶。那輪廓很陌生，卻意外地貼合你的習慣，像是為你量身留下的。",
			"power": "殘符入體，一道灼熱沿著招式的紋路走遍全身，殺意悄悄加深。你感到某處縫隙被填滿了，那裡曾經空著，你自己都沒意識到。",
			"remove": "你割斷那道殘餘禁制，符灰隨風飄散。雜念跟著一同消散，心中忽然輕了許多，像是卸下了一件穿了太久的厚甲。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §7）
		"tree": {
			"root": {
				"prompt": "先是一點微光，在路旁草根下一明一滅，像誰沒掐熄的香頭。撥開浮土，一只符匣半埋其中，鎖鏈鏽成了暗紅色，匣上禁制卻還醒著，隔著木蓋一下一下地搏動——像心跳，也像在數你站了多久。",
				"choices": [
					{
						"id": "force_open",
						"label": "扯斷鏽鏈，硬撬開它",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "gain_card_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 4},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
							},
							"log": "鏽鏈在你掌中應聲而斷，鏽末簌簌落了一地。匣裡的靈光猛地一漲，照得你滿手通明——是遺贈還是反噬，全看留物之人當年封進去的，是善意還是脾氣。",
						},
					},
					{
						"id": "slow_unfold",
						"label": "順著符紋，一道道緩解",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 5}]},
								{"kind": "heal", "amount": 6},
							],
							"log": "你指尖壓著符紋，循它的筆順一道一道往回退，像替人解一個打了多年的結。禁制鬆開的剎那，一縷溫熱靈氣裹上你的傷處，不聲不響待了片刻——往後幾步路，你身上像多披了一層看不見的軟甲。",
						},
					},
					{
						"id": "observe_runes",
						"label": "凝神細讀匣上符紋",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inspect",
					},
					{
						"id": "zhao_lineage",
						"label": "（趙靈兒）以靈族古文讀它來歷",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "max_hp", "amount": 3},
							],
							"log": "靈兒指尖撫過符紋，輕聲讀了出來——筆意竟與水月宮的靈族古文同源，是上代修者留給後來人的遺贈。讀到落款那一筆，匣中溫熱湧上指尖，像隔著歲月被誰托了一下手。她直起身時，眉目間多了一分沉靜的力氣。",
						},
					},
					{
						"id": "leave",
						"label": "向匣拱手，不取分外之物",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你把浮土撥回去，蓋住那點微光，向符匣拱了拱手。走出十幾步回頭看，草根下的光已斂了，像一句沒說出口的話，留給下一個有緣人。"},
					},
				],
			},
			"nodes": {
				"node_inspect": {
					"prompt": "你屏住呼吸，目光順著符紋一路推到匣底，鏽鏈的陰影裡浮出四個極淡的字：「貪者反噬」。字跡端正，不像恫嚇，倒像一個認真的人留下的最後一句囑咐。",
					"choices": [
						{
							"id": "take_potion_only",
							"label": "依囑取藥，不碰符紋分毫",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_potion"},
									{"kind": "gold", "amount": 8},
								],
								"log": "你雙手捧出匣角的藥包，自始至終不讓指尖掠過符紋半分。匣中靈光安安靜靜看著你做完這一切，臨了輕輕一閃，像點了個頭。藥香透紙而出——是好藥。",
							},
						},
						{
							"id": "erase_warning",
							"label": "抹去那四字囑咐，開匣取法",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"log": "四個字在你指腹下化作符灰，簌簌散盡。匣蓋應聲而啟，靈光湧出，在你掌紋裡烙下一道術法的輪廓——陌生，卻意外貼合你的手。只是往後夜靜時，你偶爾會想起那句被你親手抹掉的囑咐。",
							},
						},
					],
				},
			},
		},
	},
	"shrine": {
		"title": "山路異光",
		"flavor": "石壁間浮現微光，像是前人留下的靈痕。你可以停步調息，也可以冒險汲取其中力量。",
		"character_flavors": {
			"li_xiaoyao": "「這靈光是有人留下的？」逍遙伸手往石壁靠近，光暈輕輕晃了晃，像是在回應他。他想起劍靈第一次現身時那淡淡的清冷，只是這縷光比劍靈更安靜，也更寂寞，彷彿在山壁裡等待了不知多少歲月，只等一個肯停下來的人。",
			"zhao_linger": "石壁間的光讓靈兒想起了靈族聖地的模樣。她向光暈深深行禮，低聲念著感謝之語——不知是否只是錯覺，那光在她靠近時，像是向她包裹過來，溫熱地貼著她的臉頰和頸間。她閉上眼睛，在那一刻忘記了自己身在何處，只感到有什麼在悄悄觸碰她，輕柔得像一個凝住了的吐息。",
			"lin_yueru": "月如在靈痕前站立片刻，神色肅然。父親說過：『真正的劍意不拘形式，有時一道壁上殘痕，也能讓人頓悟一生的功夫。』她深吸一口氣，放開了平日戒備的心，以劍客之禮向前人的靈跡致意。",
			"anu": "阿奴沒有立刻靠近。她在距離石壁三步外蹲下，閉上眼睛，用蠱術感應那縷氣息的來歷——確認沒有隱匿的敵意，也沒有吞噬之念，才緩緩向前走了一步，伸出手。",
		},
		"heal": 8, "gain_cost": 6, "power": 1, "power_label": "凝神",
		"observe_text": "你細看石壁上的光痕。那是一個曾經參透了什麼的人，最後留下的靈光，沒有指向具體的招式，只是一個「我懂了」的時刻被定格在石壁上。光痕的溫度因參訪者的心態而變化——焦躁者它退、平靜者它近。",
		"observe_effects": [{"kind": "heal", "amount": 4}, {"kind": "power", "amount": 1}],
		"choices": ["heal", "power", "upgrade", "observe", "leave"],
		"outcomes": {
			"heal": "靈痕輕觸肌膚，如同有人將一掌暖意按在背脊，傷口漸漸閉合。那股力量溫和而持久，像是前人最後的善意。",
			"power": "古人的意念透過石壁注入，你感到某種久遠的殺意悄悄疊加進了自身。那是別人走過的路留下的鋒芒，此刻，卻成了你的。",
			"upgrade": "沉靜片刻，手中某道招式的謬誤竟自行顯現——你終於明白了它的精髓。前人彷彿就站在你身後，帶著笑，讓你自己看見答案。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §8）
		"tree": {
			"root": {
				"prompt": "暮色裡的山道靜得只剩你的腳步聲，一拐彎，石壁間忽然浮出一片微光，淡得像水裡化開的月。那不是火，也不是磷——是前人留下的靈痕，無聲無息，卻有一種沉沉的存在感，彷彿有人在石壁裡等了很多年，等一個肯停下來的人。",
				"choices": [
					{
						"id": "stand_quietly",
						"label": "走近三步，靜立感應",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 8},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "你在光前站定，什麼也不做，只把呼吸放慢。靈痕的溫度便一寸寸漫過來，先是掌心，再是心口，像爐邊烤暖的舊棉衣。離開時你的步子穩了，往後也一直穩著——有些東西留下來了。",
						},
					},
					{
						"id": "siphon",
						"label": "張掌按進光暈，汲它入體",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "power", "amount": 2},
									{"kind": "max_hp", "amount": 2},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 5},
									{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
								],
							},
							"log": "你張開五指，往光暈正中按下去。光在你掌下劇烈地明滅，像被驚醒的人猛然睜眼——它在掂你，掂你這雙手，配不配。",
						},
					},
					{
						"id": "meditate",
						"label": "盤膝坐下，臨痕悟法",
						"kind_hint": "reward",
						"next": "node_meditate",
					},
					{
						"id": "observe_origin",
						"label": "細辨這縷光的來歷",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_origin",
					},
					{
						"id": "lin_salute",
						"label": "（林月如）以林家堡劍禮致敬",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 4},
							],
							"log": "月如退半步，劍交左手，行的是林家堡晚輩參見前輩的全禮。劍尖垂地的剎那，壁上殘光倏然大亮，與她的劍意疊在一處錚然一鳴——像父親林天南喂招時那一聲「好」。她收劍入鞘，掌心多了一式新的領會。",
						},
					},
					{
						"id": "force_inherit",
						"label": "不請自取，強納殘光入丹田",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "permanent_power", "amount": 3},
								{"kind": "damage", "amount": 6},
								{"kind": "gain_curse", "curse_id": "xie_yin"},
							],
							"log": "你不請自取，引那道殘光入體。前輩的劍意冷冷地掃過你的經脈——『不請而取者，自承其患。』那股力量留了下來，但某種你也說不清的東西，從此跟著你走。",
						},
					},
					{
						"id": "leave",
						"label": "低頭一禮，趕路要緊",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向石壁低頭一禮，轉身下山。走出很遠回頭望，那點微光還亮著，不增不減——它等的或許不是你，你也不必是它等的人。"},
					},
				],
			},
			"nodes": {
				"node_meditate": {
					"prompt": "你盤膝坐定，山風從耳邊退開，靈光順著眉心緩緩流入識海，在黑暗裡一筆一畫，組成一段殘缺的心法。字句斷在最要緊處——剩下的，要你自己接。",
					"choices": [
						{
							"id": "ascend",
							"label": "順著殘篇，把一招練透",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "heal", "amount": 4},
								],
								"log": "你照著殘篇行氣，行到斷句處，掌中那道熟悉的招式忽然自己動了——多年的滯澀一夕貫通，識海輕輕一震。睜眼時日頭已斜，你把那一招在掌心又走了一遍：是了，就是這樣。",
							},
						},
						{
							"id": "memorize",
							"label": "只記不練，原樣收進心底",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "common"},
									{"kind": "gold", "amount": 5},
								],
								"log": "你逐字把殘篇默誦三遍，不行氣、不催勁，讓它安安靜靜躺進記憶。起身時，石縫裡一枚前人留下的銅錢硌了你的腳——像在獎勵你的不貪。心法在你心底睡著，總有用得上的一天。",
							},
						},
					],
				},
				"node_origin": {
					"prompt": "你湊近細看，光痕深處的氣息竟與你一路修行的路數隱隱呼應——這位坐化在山壁裡的前輩，與你的師承怕是同出一源。山道往下，正通著一座塌了半邊的山神廟，香火斷了，靈痕卻留在這裡。",
					"choices": [
						{
							"id": "kneel",
							"label": "整衣斂容，叩首三拜",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你拂去衣上塵土，朝石壁端端正正拜了三拜。第三拜起身時，光暈離壁而出，繞你一周，像長輩端詳遠道而來的後生。它隱回石壁前，在你眉心輕輕一點——那一點暖，往後一直在。",
							},
						},
						{
							"id": "respectful_pass",
							"label": "不領這份情，繞行而過",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 8}]},
								],
								"log": "你抱拳道了聲謝——同源歸同源，情不能白受，說罷繞行而過。走出半里，山風忽然繞著你轉了個圈才散。前輩到底不肯讓你空手：往前這一段路，有什麼在替你擋著。",
							},
						},
					],
				},
			},
		},
	},
	"treasure_chest": {
		"title": "寶箱機關",
		"flavor": "倒塌的木箱半埋在落葉裡，鎖鏈鏽蝕但機關未解，輕觸還可聽見細微的扣響。",
		"character_flavors": {
			"li_xiaoyao": "「呦，還是個有機關的！」逍遙興致勃勃地蹲下來，用一根樹枝戳了戳鎖扣。喀嗒一聲，他立刻往後跳了一步，但什麼也沒爆炸。他咧嘴笑了笑：「好，就這麼著。」在冒險這件事上，他從來不擅長三思而後行。",
			"zhao_linger": "靈兒在木箱旁蹲下，袖子不小心滑落到了肘彎處，露出小臂。她沒有立刻整理，只是用手心感應了一下鎖鏈的靈氣——很淡，很老，等了很久了。她想起母親說的，世間萬物皆有靈性，善待它，它也善待你。然後才低頭，拉好了袖子，假裝那一截手臂什麼都沒有露出來。",
			"lin_yueru": "月如蹲下來仔細打量機關的結構。林家堡有一門功課叫做「識陣」，專門研究各類禁制與機關——這個鎖扣的設計很紮實，出自武林之人，不是妖物。她嘴角微微一動：解開這種機關，正是她拿手的事。",
			"anu": "阿奴湊近鼻子嗅了嗅木箱的氣息——裡面有一縷不尋常的草藥香，和苗疆某種只在儀式中使用的香料類似。她抬起頭，環顧四周確認沒人監視，才重新低頭看向那道鎖扣，骨針已握在手心。",
		},
		"heal": 4, "gain_cost": 3, "power": 1, "power_label": "解鎖",
		"observe_text": "你不急著開鎖，先在箱蓋邊緣摸了一圈。指尖傳來一根極細的金屬絲——是觸發毒針的暗器。前主人並非不想讓人開，是不想讓「不懂規矩的人」開。看穿這個機關，才能安全地取得寶物。",
		"observe_effects": [{"kind": "gold", "amount": 12}],
		"choices": ["gain_card", "upgrade", "remove", "observe", "leave"],
		"outcomes": {
			"gain_card": "機關應聲而開，箱底壓著一卷泛黃的功法殘頁，術法輪廓躍然紙上。那字跡略顯潦草，像是主人在某個倉皇的夜裡草草記下的，越看越覺得字裡藏著什麼故事。",
			"upgrade": "鎖扣喀嗒扣響，一股細微靈氣流過你的雙手。某道招式因此更趨純熟，就好像那股靈氣知道你哪裡還差了一點，精準地補進去了。",
			"remove": "倒刺擦過掌心，一陣刺痛——但某道雜亂的招式也隨之從腦海中剝落。鮮血滴在落葉上，心卻意外地輕了，雜念隨符灰一同飄散。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §9）
		"tree": {
			"root": {
				"prompt": "落葉堆裡先露出一角鐵鏽色，撥開來，是一只半埋的木箱，鎖鏈鏽得發黑，箱身卻紋絲未腐。指尖才碰上箱蓋，裡頭便傳來一聲極細的「喀」——機關還活著，像將軍塚裡那些埋了百年仍會咬人的暗扣。",
				"choices": [
					{
						"id": "pry",
						"label": "抽刀挑鎖，硬撬開它",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "gold", "amount": 25},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "gold", "amount": 5},
								],
							},
							"log": "你刀尖一沉，整條鎖鏈應聲繃斷。箱蓋彈起的剎那，一縷陳年的暗香混著鐵鏽味撲面而來——箱裡的東西，和箱裡的毒針，在這一刻同時醒了。",
						},
					},
					{
						"id": "careful",
						"label": "以劍鞘代手，遠遠引動機關",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 15},
								{"kind": "gain_potion"},
							],
							"log": "你退開半步，用劍鞘遠遠壓下鎖扣。「噗」的一聲輕響，毒針釘進劍鞘，只挑斷了一根縫線。箱中銅錢成串，還臥著一只油紙裹好的藥瓶——前主人收拾得很體面。",
						},
					},
					{
						"id": "observe_trap",
						"label": "貼耳細聽機關的咬合",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_trap",
					},
					{
						"id": "anu_disarm",
						"label": "（阿奴）以骨針反解毒機關",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 25},
								{"kind": "gain_potion"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "阿奴鼻尖一動就笑了——毒針上抹的配方，是苗疆寨子裡老人們的手筆，她閉著眼都認得。骨針逆著機簧輕輕一挑，毒針乖乖反扣回鞘，像被喊了名字的蟲。她翻開箱蓋，順手把那點毒粉也刮走了：好東西，不能浪費。",
						},
					},
					{
						"id": "leave",
						"label": "掂掂分量，放它繼續埋著",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你蹲下掂了掂箱子，又把落葉撥回去蓋好。有些箱子鎖了百年，自有它的道理——你拍拍手上的土，把這份好奇留在原地。"},
					},
				],
			},
			"nodes": {
				"node_trap": {
					"prompt": "你把耳朵貼近箱蓋，屏息聽機簧的咬合——一根極細的金屬絲在蓋下繃著，連著毒針。可繃法不對：設計的人故意在絲的另一頭留了鬆口，是給識貨之人的旁路。",
					"choices": [
						{
							"id": "bypass",
							"label": "循那道鬆口，無聲開鎖",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gold", "amount": 20},
									{"kind": "gain_card_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 5},
								],
								"log": "你指尖捻著金屬絲的鬆口，輕輕一送，毒針從另一側無聲彈空。箱蓋開時連灰都沒驚起。箱底功法殘卷與碎銀齊整疊放——設計機關的人，等的就是你這樣的手。",
							},
						},
						{
							"id": "trigger_grab",
							"label": "伸臂硬吃一針，搶先翻箱",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "damage", "amount": 6},
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "gold", "amount": 10},
								],
								"log": "毒針扎進小臂的剎那，你已經把箱底掀了個遍。麻意順著手肘往上爬，你咬牙把那件不打眼的舊物揣進懷裡，才坐下運氣逼毒。疼是真疼——但值。",
							},
						},
					],
				},
			},
		},
	},
	"ancestor_relic": {
		"title": "先靈遺骨",
		"flavor": "古老的祭壇上擺著一具尚未化盡的骨殖，靈氣濃郁。傳說供奉者能繼承一縷意志。",
		"character_flavors": {
			"li_xiaoyao": "逍遙在祭壇前站了一會兒，背脊有些發涼——骨殖雖只剩殘片，靈氣卻出奇地強烈，像是有一雙看不見的眼睛正在打量他。「好啦好啦，我很尊敬你們……」他小聲咕噥，把師父教過的致敬之禮依稀想了起來，做了個半吊子的行禮。",
			"zhao_linger": "靈兒在祭壇前緩緩跪下。低頭念咒語的時候，散開的青絲貼著臉頰垂落，她顧不上撥開，任由那縷髮絲掃過頸側——涼涼的，像是先靈伸出了一根指尖。她念完之後，才把那縷頭髮輕輕攏到耳後，在空曠的祭壇裡，覺得這個動作有些孤單。",
			"lin_yueru": "月如肅然行禮，同時暗自打量那縷靈氣的品質——純粹、強烈，是武人留下的意志，而非妖物的殘存。林家堡山後的供奉之地，她見過類似的氣息，但這裡的更古老，更凝重，像是某個在戰場上完成了使命的靈魂。",
			"anu": "阿奴看著那具骨殖，心中有些複雜。在苗疆，對先人的祭禮極為隆重，骨殖是神聖的——擅自動用先人的力量，在她的文化裡是禁忌。她站在祭壇前衡量了很久，最終向那縷殘留的意志低下頭，以苗疆之禮祈求寬恕，才伸出手。",
		},
		"heal": 5, "gain_cost": 8, "power": 3, "power_label": "祈靈",
		"observe_text": "你細細打量這具骨殖。它的姿勢蜷縮著，雙手抱於胸前——是修者坐化的姿態，不是死於非命。骨殖周圍沒有戰鬥痕跡，反倒擺著三朵已乾枯的小白花，是某個後人來祭拜過的。這個前輩，是有人記得的。",
		"observe_effects": [{"kind": "heal", "amount": 5}, {"kind": "power", "amount": 1}],
		"choices": ["power", "upgrade", "heal", "observe", "leave"],
		"outcomes": {
			"power": "骨殖微微顫動，一縷殘存的意志悄然融入你的劍意，殺伐之氣更甚從前。那是另一個人走了一輩子才走出來的鋒芒，此刻，傳到了你的手上。",
			"upgrade": "那意志短暫地附在你手上，某道招式的謬誤就此被先靈之手抹去。你感到有人站在你身後，靜靜地看著，滿意地點了點頭。",
			"heal": "虔誠供奉，先靈庇佑，傷口癒合的速度比尋常快了幾分。那股暖意不像草藥，更像是一個陌生的老人，把手放在你肩膀上，不說話，只是讓你知道：有人看顧著你。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §10）
		"tree": {
			"root": {
				"prompt": "林間忽然安靜下來，連蟲鳴都歇了。前方一座古老祭壇爬滿藤蔓，壇上端坐著一具尚未化盡的骨殖——雙手抱於胸前，是修者坐化之姿。骨前擺著三朵乾枯的小白花，靈氣濃得壓住了風：他走了很久，卻還有人記得。",
				"choices": [
					{
						"id": "venerate",
						"label": "焚香拜祭，執晚輩之禮",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 10},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "你拾了一束山花替換壇上的乾枝，俯身行了個全禮。起身時，骨殖周圍的靈氣輕輕一蕩，像有人隔著歲月點了個頭。下山的路上，你的傷口不疼了，腳步也比來時沉穩。",
						},
					},
					{
						"id": "extract_bone",
						"label": "掰下一節指骨，攜走煉化",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "max_hp", "amount": -3},
								{"kind": "permanent_power", "amount": 3},
							],
							"log": "你伸手掰下一節指骨，入手的剎那，林間的靜變成了另一種靜——被注視的靜。那縷意志沒有阻止你，只是從此跟著你：每次出手，他都看著。你說不清這是傳承，還是討債。",
						},
					},
					{
						"id": "observe_legacy",
						"label": "細看這位前輩坐化的姿勢",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_legacy",
					},
					{
						"id": "lin_lineage",
						"label": "（林月如）行林家弟子禮認師",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "月如解下佩劍橫於膝前，行的是林家堡弟子拜師的大禮。額頭觸地的一瞬，一個從未聽過的聲音在識海裡輕喚她的名字——是父親林天南也未曾提起的師伯。聲音教了她半式劍訣便散了，像怕多留一刻會捨不得。",
						},
					},
					{
						"id": "leave",
						"label": "斂聲屏息，繞壇而行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向骨殖低頭一禮，貼著祭壇邊緣輕輕繞了過去，不讓鞋底碾響一片枯葉。走遠了回頭看，三朵乾花在壇上微微晃——像揮手，也像目送。"},
					},
				],
			},
			"nodes": {
				"node_legacy": {
					"prompt": "你繞著骨殖細看，那蜷縮的坐姿不是痛苦，是把最後一口氣護在胸前的鄭重。壇沿內側刻著一行極小的字，指腹拂過才顯：「接得住者，即吾傳人。」",
					"choices": [
						{
							"id": "kneel_accept",
							"label": "雙膝落地，接下這份傳承",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 2},
								],
								"log": "你跪下的剎那，骨殖中那縷意志傾身而出，沉沉壓進你的胸口——像接住一柄遞了百年的劍。熱意自心口散向四肢，有什麼從此長在你的招式裡。你向骨殖叩首：「前輩，接住了。」",
							},
						},
						{
							"id": "decline_take_flowers",
							"label": "婉拒傳承，只帶走三朵乾花",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "heal", "amount": 8},
									{"kind": "max_hp", "amount": 2},
								],
								"log": "你向骨殖搖了搖頭，說自己的路要自己走，只把那三朵乾花輕輕收進胸口的暗袋。轉身時，一縷暖意追上來貼著你的傷處——前輩不收回禮，這份念想，他折成了別的東西還你。",
							},
						},
					],
				},
			},
		},
	},
	"wandering_sage": {
		"title": "雲遊隱士",
		"flavor": "竹笠下白髮垂胸的老者煮著一壺粗茶，看你走來只是抬眼，不發一語。",
		"character_flavors": {
			"li_xiaoyao": "竹笠下的老者看起來比外婆還老，但氣質截然不同——外婆說話快，這老人連眼神都是慢的。逍遙拱手道了個「前輩好」，老人只是端著茶杯看他，也不說有緣沒緣，那眼神像是把逍遙從頭到腳掃了個底朝天，然後發現了幾個他自己都沒注意到的漏洞。",
			"zhao_linger": "老者打量她的眼神平靜而直接，像是把她從頭到腳看了一遍，不帶評判，卻也無遮無擋。靈兒微微挺直了背，端著茶盞，覺得臉頰有些熱——不像是發燒，更像是被什麼真實地看見了，不習慣，但也說不上排斥。她低頭喝了一口茶，粗茶苦而回甘，讓她的心跳慢慢平復下來。",
			"lin_yueru": "月如打量老者的氣息，判斷是修為深厚的隱士。她直接開口：「前輩，您可否指點晚輩劍術？」老者沒有立刻回答，只是把茶杯放下，抬眼看了看她的劍，然後看了看她的眼睛，緩緩說：「你的劍快，但你的心不靜。」月如沉默了片刻。",
			"anu": "阿奴在老者旁邊坐下，一言不發。她不擅長和陌生人搭話，但老者似乎也不需要言語——他們就這樣沉默地對坐了一會兒，直到老者向她遞過來一個小小的東西，也不解釋用途。阿奴接過，感應了一下——是某種靈草，是苗疆的。",
		},
		"heal": 10, "gain_cost": 5, "power": 2, "power_label": "問道",
		"observe_text": "你不開口，只是靜靜看著老者。他煮茶的動作極慢，每一個步驟都精準到像是練過幾十年的招式——這位老者並非閒人，他的靜止是經過無數動作淬鍊出來的。他的目光偶爾抬起，掃過你身上的傷口、神色、佩劍位置——他看見的，比他說出來的多得多。",
		"observe_effects": [{"kind": "power", "amount": 1}, {"kind": "heal", "amount": 3}],
		"choices": ["heal", "upgrade", "remove", "view_deck", "observe", "leave"],
		"outcomes": {
			"heal": "老者拈起一把草葉往你傷口一貼，涼意透入，血色退去大半。他一句話都沒說，就那樣放手，轉身繼續煮茶，好像幫你療傷只是順手的事。",
			"upgrade": "老者只說了半句話，你便悟透了剩下那半句。那道招式從此不同了——不是更強了，而是更真了，像是終於去掉了最後一層假。",
			"remove": "老者搖搖頭：『此式有礙根基。』隨手將那頁功法投入爐火，煙散無痕。他端起茶，若無其事，但你感到招式裡確實有什麼東西消失了，而心也隨之輕了。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §11）
		"tree": {
			"root": {
				"prompt": "茶香先一步攔住了你——粗茶，火氣很足，混著松枝燒裂的味道。道旁石上，一位竹笠下白髮垂胸的老者守著一只小泥爐，看你走來只是抬眼，又低頭撥火，不發一語。那一眼很短，卻像把你連人帶劍都稱過了。",
				"choices": [
					{
						"id": "seek_teaching",
						"label": "上前拱手，誠心求教",
						"kind_hint": "reward",
						"next": "node_teach",
					},
					{
						"id": "silent_sit",
						"label": "不發一語，在他對面坐下",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "permanent_power", "amount": 2}],
							"log": "你坐了一炷香，他添了三次水，誰都沒開口。起身告辭時，老者忽然頭也不抬地說：「你的劍會找到答案。」就這一句，卻在你往後每次出手時隱隱作響。",
						},
					},
					{
						"id": "observe_master",
						"label": "細看他煮茶的手法",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_recognize",
					},
					{
						"id": "lxy_uncle",
						"label": "（李逍遙）打聽師父的下落",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 10},
							],
							"log": "逍遙試探著提起師父，老者眯眼笑了：「酒劍仙啊……他欠我三壺酒，你見著了替我討。」說罷拈葉貼上逍遙的傷口，又口授了半式劍訣——說是抵那三壺酒的利錢。茶喝完，傷也好得七七八八。",
						},
					},
					{
						"id": "demand_destiny",
						"label": "跪地不起，強求一道天命",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "gain_card_pool", "pool": "rare"},
								{"kind": "max_hp", "amount": -6},
								{"kind": "lose_card", "mode": "random"},
							],
							"log": "你跪下不肯起：「請前輩賜一道天命！」老者嘆口氣：『強求之物，皆有代價。』他拈起一片葉子點向你眉心——你看見了，卻也失去了一些原本握在手裡的東西。",
						},
					},
					{
						"id": "leave",
						"label": "討一碗茶，喝完便走",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你討了一碗粗茶，蹲在爐邊喝完，向老者拱手作別。走出十幾丈回頭，石上空空——爐、茶、人都不在了，只有舌根那點回甘，證明你沒做夢。"},
					},
				],
			},
			"nodes": {
				"node_teach": {
					"prompt": "老者放下茶杯，竟真的開了口，聲音像爐底的炭，又暗又穩：「我能教你三樣——療傷、煉招、去雜念。只能挑一樣，挑了就不能反悔。」爐火劈啪一響，他等著你。",
					"choices": [
						{
							"id": "heal_lesson",
							"label": "求一帖療傷的本事",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 18},
									{"kind": "max_hp", "amount": 2},
								],
								"log": "老者拈起三片不知名的草葉，在掌心揉碎了往你傷處一貼。涼意透骨而入，疼處像被慢慢熨平。他順手把剩下的藥渣抖進你手心：「記住這味道，往後自己找得到。」",
							},
						},
						{
							"id": "refine_lesson",
							"label": "求精煉招式之竅",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "老者讓你把最熟的一招打給他看，看完只說了半句話。你便在那半句裡悟透了剩下那半句——那道招式從此不同了，不是更強，而是更真，像終於去掉了最後一層假。",
							},
						},
						{
							"id": "remove_lesson",
							"label": "求斬除心中雜念",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "lose_card"},
									{"kind": "heal", "amount": 5},
								],
								"log": "老者盯著你看了半晌，伸兩指在你眉心一點：「就是它了。」一道你練了很久、其實一直在拖累你的念頭，隨指尖被拈了出來，投入爐火，煙散無痕。你忽然輕了。",
							},
						},
					],
				},
				"node_recognize": {
					"prompt": "你盯著他煮茶的手——提壺、注水、收腕，每個動作都準得像練了幾十年的劍招，半分不多，半分不少。這不是山野閒人，是把一身驚人的功夫，收進一壺粗茶裡的高人。",
					"choices": [
						{
							"id": "apprentice",
							"label": "撩衣下拜，拜一日之師",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 1},
									{"kind": "next_battle_buff", "effects": [{"kind": "energy", "amount": 1}]},
								],
								"log": "你撩衣下拜，口稱「一日之師」。老者沒攔，受了這一拜，便把一道罕見的心法掰開揉碎了說與你聽，連你問到第三層他都不嫌煩。臨別他擺擺手：「拜過就算，路自己走。」",
							},
						},
						{
							"id": "leave_wine",
							"label": "不打擾，留一壺好酒作謝",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gold", "amount": -10},
									{"kind": "heal", "amount": 6},
								],
								"log": "你把行囊裡那壺捨不得喝的好酒擱在爐邊，沒說話，只抬手一揖。老者向你抬了抬竹笠，算是受了。你回頭時，石上已空——酒不在，人也不在，唯獨你的傷口輕快了許多。",
							},
						},
					],
				},
			},
		},
	},
	"moonlit_pool": {
		"title": "月光浸水潭",
		"flavor": "夜色凝在潭面，倒映出比山更深的星辰。傳說潭水能洗去俗血、也能引出舊傷。",
		"character_flavors": {
			"li_xiaoyao": "逍遙仰頭看了看天上的月，再低頭看看潭面的月——兩個月亮。「這算一個還是兩個？」他蹲下去用手指輕輕撥了撥潭面，水中的月亮隨著漣漪碎開，然後又慢慢地聚攏回來。這潭水的靈氣比他想的要複雜，有什麼古老的東西沉在底部，一動不動地等著。",
			"zhao_linger": "靈兒確認四下無人，才脫去外袍，踏入潭中。月光把水映成銀白，也把她的倒影映得清清楚楚。她剛把髮帶解開、長髮散落水面，突然聽見岸邊蘆葦叢裡一聲細響——她猛地回身，水花四濺，耳尖立刻燙紅。對面蘆葦一動也不動，什麼都沒有。她緩緩吐出那口氣，低聲罵了一句，繼續沐浴，卻始終沒能完全放鬆下來。",
			"lin_yueru": "潭面如鏡，映出比天空更清晰的星辰。月如看著那個倒影中的自己，難得在無人的地方卸下了幾分防備——林家堡的大小姐不能示弱，但月光下的這個倒影，只是個想把父親接回家的女兒。她把那個念頭壓了下去，挺直了脊背。",
			"anu": "阿奴在潭邊坐了很久，什麼都沒有說，什麼都沒有做。她只是看著水面上的星辰，讓月光一點一點地照進胸口。南詔的夜晚沒有這樣的潭，也沒有這樣的靜——這裡的靜讓她有些不習慣，卻也說不上不喜歡。",
		},
		"heal": 15, "gain_cost": 9, "power": 1, "power_label": "沐月",
		"observe_text": "你細看潭面。月光在水中映出的不是天上那輪，是一個更古老、更圓滿、更明亮的月——傳說中，這種雙月之潭在中原幾近絕跡，是某個失落仙派的修行之地。潭水有兩面：對著光的這一面是淨化，對著陰的那一面是引誘。要靠近時必須帶著明確的意圖。",
		"observe_effects": [{"kind": "heal", "amount": 6}, {"kind": "max_hp", "amount": 2}],
		"choices": ["heal", "power", "observe", "leave"],
		"outcomes": {
			"heal": "月光滲入水中，你的舊傷如紙浸軟、輕輕化開，浮上水面的是清澈的倒影。走出潭邊時，你發現身上有些東西不只是傷，也一起淡去了。",
			"power": "潭面映出你自己的雙眼——那雙眼裡，有什麼東西比昨夜更深了。你說不清那是什麼，只知道它讓你的招式多了一層力量，像是某種本來就在那裡、只是還沒被看見的東西。"
		},
		# Batch A 凍結設計（docs/EVENT_BRANCHING.md §12）
		"tree": {
			"root": {
				"prompt": "夜露落在肩上時，你才發現林子盡頭藏著一泓水潭。夜色凝在潭面，倒映的星辰比山還深，潭心一輪月，竟比天上那輪更圓更亮。水氣沁涼撲面——傳說這樣的潭水能洗去俗血，也能引出你以為早好了的舊傷。",
				"choices": [
					{
						"id": "bathe",
						"label": "解衣入潭，沐月療傷",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 15},
								{"kind": "max_hp", "amount": 2},
							],
							"log": "你緩緩沒入潭中，月光貼著水面漫過你的肩。舊傷如紙浸軟、輕輕化開，連那些你早不去想的暗痛也一併浮出，散在銀白的水裡。上岸時你覺得自己輕了，往後也會一直輕一點。",
						},
					},
					{
						"id": "drink",
						"label": "掬潭心月影，仰頭飲下",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"lose_effects": [
									{"kind": "max_hp", "amount": -3},
									{"kind": "damage", "amount": 4},
								],
							},
							"log": "你掬起那輪水中月，連光帶水一飲而盡。涼意墜進丹田，像吞下一枚會呼吸的月亮——潭水有兩面，對著光是淨化，對著陰是引誘，此刻它正在你腹中決定翻向哪一面。",
						},
					},
					{
						"id": "observe_moons",
						"label": "屏息細看潭中那輪月",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_double_moon",
					},
					{
						"id": "zhao_lineage",
						"label": "（趙靈兒）以靈族水德沐浴歸宗",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 20},
								{"kind": "max_hp", "amount": 5},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "靈兒赤足踏入潭中，水紋自她足尖一圈圈盪開，竟自動讓出一條銀亮的路。月光把水映成仙靈島水月宮的顏色，那一刻她聽見了母親的聲音，很輕，像隔著水喚她的乳名。她在潭心站了很久，出水時眼眶是熱的，渾身的傷卻都好了。",
						},
					},
					{
						"id": "dive_to_bottom",
						"label": "潛入潭底取那顆古老的東西",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "gain_relic_pool", "pool": "rare"},
								{"kind": "damage", "amount": 10},
								{"kind": "max_hp", "amount": -5},
							],
							"log": "你深吸一口氣潛入水中。月光在水下變成黑色，潭底有一塊溫熱的東西——你伸手抓住，瞬間幾股冰冷的氣息湧入肺裡。你勉強浮出水面，咳了好幾口水，掌心是那件古物，胸口卻多了一道揮不去的悶痛。",
						},
					},
					{
						"id": "leave",
						"label": "向潭拱手，不擾雙月清輝",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向潭面拱了拱手，把這份古意原樣留下。轉身入林，月光送你一程，在你肩頭停了停才退回水面——下一個有緣人來時，潭水還是滿的。"},
					},
				],
			},
			"nodes": {
				"node_double_moon": {
					"prompt": "你屏息看了半晌，終於確定——水中那輪月不是天上的倒影，是另一輪更古老、更圓滿的月。雙月之潭，中原幾近絕跡，傳說是某個失落仙派的修行地，潭底的靜，是他們留下的。",
					"choices": [
						{
							"id": "twin_moon_seal",
							"label": "以雙月為印起念",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 5},
								],
								"log": "你對著雙月合掌起念，兩輪月光在你眉心交疊成一點印記，一觸即逝。退開時，潭邊石上多了一件不屬於這個時代的物事，靜靜等你拾起——像是仙派隔著歲月遞來的回禮。",
							},
						},
						{
							"id": "sit_until_moonset",
							"label": "不擾古事，靜坐至月偏",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "heal", "amount": 8},
								],
								"log": "你在潭邊坐定，不取、不問、不擾，陪著那輪古月走完它的夜。月偏西時你起身，雙腳發麻，胸中卻異常清明——有些功夫不是練來的，是這樣坐出來的。",
							},
						},
					],
				},
			},
		},
	},
	"broken_temple": {
		"title": "廢棄山神廟",
		"flavor": "山神泥像剝落大半，神龕底卻還壓著一道暗紅符紙，墨色仍鮮。",
		"character_flavors": {
			"li_xiaoyao": "泥像剝落大半，神龕空蕩蕩的，但那道暗紅符紙墨色仍鮮，像是有人最近才留下的。逍遙在廟門口站了一下，心裡有個聲音說不要進去，另一個聲音說裡面說不定有好東西。他最後聽了第二個聲音，小心翼翼地跨過了門檻。",
			"zhao_linger": "靈兒走進廟中，跪在空蕩的神龕前念詞。香煙的氣味繞過神像，像有人悄悄站在她身後，把一縷煙紗搭在她的肩上。她念到一半，感到脖頸一陣酥意，才意識到是飄散的煙霧貼著頸側過去了。她沒有停下，繼續念完，但臉頰已悄悄熱了幾分。",
			"lin_yueru": "月如沒有遲疑，直接走進了廟中。廢棄的山神廟對林家堡的弟子而言是常見的野外歇腳之地，她比任何人都清楚這種地方的靈氣殘留既有危險，也有機緣。她蹲下來取出暗紅符紙仔細查看——字跡不是她所認識的任何一派法脈。",
			"anu": "阿奴進廟前先停在門口，用蠱術探了探裡面的氣息。暗紅符紙的氣味讓她皺了眉——不是苗疆的術法，但有幾分相似，像是從同一個源頭流出的兩條支流，走著走著就不認識彼此了。她慢慢走進去，在符紙旁蹲下。",
		},
		"heal": 4, "gain_cost": 2, "power": 3, "power_label": "撕符",
		"observe_text": "你蹲下細看那道暗紅符紙。墨色仍鮮，是近期才有人來過——而且不只是路過，是在這裡進行了完整的儀式。符紙背面有極淡的指印，像是按下符紙時用力的痕跡。這個施符者並非熟手，動作有遲疑，是某個剛入門的後輩，可能還會回來。",
		"observe_effects": [{"kind": "gold", "amount": 4}, {"kind": "power", "amount": 1}],
		"choices": ["gain_card", "power", "remove", "observe", "leave"],
		"outcomes": {
			"gain_card": "符紙在掌心炸裂，一道混濁卻濃烈的術法如烙印燒進了你的記憶。那字跡潦草，像是主人在某個倉皇的夜裡草草記下的，越想越覺得字裡藏著什麼故事。",
			"power": "你將那道暗紅符紙投入口中。灼熱自丹田升起，殺意更烈，心卻意外地更靜。你說不清那是什麼感覺，只知道它讓你的出手更準了一分。",
			"remove": "紙灰飄散，某一式冗餘的招法跟著消散。那一刻，你感到肩上有什麼東西輕了，像是卸下了一件穿了太久、卻早該扔掉的舊衫。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §13）
		"tree": {
			"root": {
				"prompt": "廟門半塌，風從屋脊的破洞灌進來，捲著一股陳年的香灰味。山神泥像剝落大半，露出裡頭發黑的草胎，像極了餘杭山道上那些荒了的小廟。唯獨神龕底壓著一道暗紅符紙，墨色仍鮮——這座廟死了很多年，這道符卻是活的。",
				"choices": [
					{
						"id": "tear_seal",
						"label": "伸手撕下那道暗紅符",
						"kind_hint": "mixed",
						"next": "node_seal",
					},
					{
						"id": "search_shrine",
						"label": "撥開香灰，翻找神龕底",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 18},
								{"kind": "gain_potion"},
							],
							"log": "你撥開積了厚厚一層的香灰，從神龕底拖出半個布包——乾糧、藥草，還有幾枚用油紙包好的銅錢，是某個行旅人寄放的家當。你猶豫了一下，留下乾糧，只取走了能救命的。",
						},
					},
					{
						"id": "observe_recent",
						"label": "細查符紙上的新鮮痕跡",
						"kind_hint": "battle",
						"requires": {"observe_token": true},
						"next": "node_recent",
					},
					{
						"id": "anu_purify",
						"label": "（阿奴）以蠱術反解殘符",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 5},
							],
							"log": "阿奴蹲在符前，骨針蘸著指尖一點血，逆著符上筆順一路倒寫回去——苗疆解蠱就是這個理，路怎麼走來，就怎麼送回去。符紙無聲化灰，邪意盡散，灰裡竟還剩一小瓶沒被汙到的好藥。她拈起來晃了晃，笑了。",
						},
					},
					{
						"id": "leave",
						"label": "心頭發毛，退出廟門",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你後退著跨出門檻，目光始終沒離開那道符。廟外日頭正好，背上的涼意卻過了半里地才散——有些渾水，不淌是對的。"},
					},
				],
			},
			"nodes": {
				"node_seal": {
					"prompt": "符紙離龕的剎那在你指間發起燙來，暗紅的墨字一個個浮出紙面，緩緩蠕動——這不是裝飾，是還在生效的封印，而你剛剛親手揭了它。",
					"choices": [
						{
							"id": "burn",
							"label": "就地引火，燒了它",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "gold", "amount": 8},
								],
								"log": "你火摺子一抖，符紙蜷成一團暗紅的灰。火光熄滅的瞬間，整座廟忽然安靜下來——是那種多年不曾有過的、乾乾淨淨的靜。泥像剝落的臉上，彷彿鬆了一口氣。",
							},
						},
						{
							"id": "keep",
							"label": "把這燙手的東西收進懷裡",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "gain_curse", "curse_id": "xie_yin"},
									{"kind": "gain_card_pool", "pool": "evil"},
								],
								"log": "你把發燙的符紙折好，貼身收進懷裡。它在你胸口發出極輕的脈動，一下，又一下，像有什麼隔著布料貼著你的心跳，低聲笑你的選擇。往後夜深，它偶爾還會熱起來。",
							},
						},
					],
				},
				"node_recent": {
					"prompt": "你細看符背——指印極淡，按得遲疑，是個剛入門的修者，而且香灰上的腳印朝外，人走了不久，多半還會回來。你吹熄火摺，在樑影裡找了個看得見門口的位置。",
					"choices": [
						{
							"id": "ambush",
							"label": "藏身樑後，等他回來",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "ancient_evil_spirit",
									"enemy_hp_mult": 0.7,
									"victory_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
										{"kind": "gold", "amount": 20},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 10},
										{"kind": "gold", "amount": -10},
									],
								},
								"log": "你伏在樑後，聽著自己的呼吸一點點放慢。半個時辰後，廟門咿呀一聲被推開——進來的卻不是什麼後輩修者。那道符鎮著的東西，順著被撕動的封印，先一步回了家。",
							},
						},
					],
				},
			},
		},
	},
	"yokai_pact": {
		"title": "妖契",
		"flavor": "黑霧中浮起一張瓜子臉，眼底比夜還黑。「給我一點，我給你十倍。」",
		"character_flavors": {
			"li_xiaoyao": "逍遙盯著那張瓜子臉，努力讓自己看起來一點都不緊張。黑霧裡的妖女笑得嫵媚，但那雙眼睛裡沒有人類的溫度——和劍靈不一樣，那個鬼丫頭雖然難纏，至少是真心的。「你說的『給我一點』，是指什麼？」他覺得自己應該先把條件問清楚。",
			"zhao_linger": "黑霧裡的女人太美了。靈兒沒想到妖也能長成這樣——瓜子臉，皮膚白得透光，眼底比夜還黑，卻莫名讓人想多看幾眼。靈兒強迫自己把視線從那張臉上移開，去聽她說話的內容。但對方似乎察覺到了，嘴角微微上揚，用那雙黑眼睛慢慢地、有些挑釁地，看回來。",
			"lin_yueru": "月如手按劍柄，警惕地打量著黑霧中的身影。林家堡有一句話：見妖不殺，非懦，是智——但也有另一句：與妖立契，非勇，是愚。她深知這道理，但那妖女說的條件確實讓她心動了一瞬，而她最討厭自己被心動。她沉默著，沒有立刻回應。",
			"anu": "阿奴見過苗疆的妖，也和幾個性情溫和的山妖做過交易。但黑霧裡這個不同——她的氣息太涼，不是自然生長的妖，更像是刻意塑造出來的。阿奴沒有動，只是靜靜地打量著對方，等著看她葫蘆裡賣的是什麼藥。",
		},
		"heal": 0, "gain_cost": 4, "power": 3, "power_label": "立契",
		"pact_max_hp_cost": 8, "pact_power": 4,
		"observe_text": "你細細打量這個自稱要與你交易的妖女。她的瞳孔縱裂，瓜子臉看似溫柔，但嘴角扯動的弧度過於精準——是學過人類面部表情的妖物。她身後的黑霧裡有極細的鏈條，像是有什麼東西把她拴在這個位置——她並非自由的存在，這個交易，可能不只是給你力量、收你血肉這麼單純。她在等的，或許是替她解開那條鏈子的人。",
		"observe_effects": [{"kind": "damage", "amount": 2}, {"kind": "gold", "amount": 5}],
		"choices": ["gain_card", "pact", "observe", "leave"],
		"outcomes": {
			"gain_card": "黑霧中遞來一卷黑色符紙，術法的輪廓燒灼在指尖，讓你不舒服卻難以拒絕。那招式有效，但總讓你覺得，它來自某個你最好不要深究的地方。",
			"pact": "妖女抬手，一縷黑絲穿過你的胸口。你感到生機被悄悄抽走一縷，那份損失是真實的，是永久的——但那股力量確實也湧了進來，像一把借來的刀，鋒利，卻不完全屬於你。"
		},
		"tree": {
			"root": {
				"prompt": "先聞到的是冷香，像雪夜裡開錯季節的花。黑霧自林隙無聲漫來，霧心浮起一張瓜子臉，眼底比夜還黑，看你的眼神卻急切得不像妖。「給我一點，我給你十倍。」她伸出一截慘白的手腕，指尖滴落黑色的血珠，落地無聲——這笑容學得太像人了，像到讓你後頸發涼。",
				"choices": [
					{
						"id": "ask_price",
						"label": "按住心動，先問她要什麼",
						"kind_hint": "mixed",
						"next": "node_negotiate",
					},
					{
						"id": "observe_chain",
						"label": "細看她背後那縷黑霧",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_chain",
					},
					{
						"id": "anu_counter",
						"label": "（阿奴）以苗疆蠱術反制",
						"kind_hint": "gamble",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.65,
								"win_effects": [
									{"kind": "gain_card_pool", "pool": "uncommon"},
									{"kind": "gold", "amount": 10},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "gain_curse", "curse_id": "gu_du"},
								],
							},
							"log": "阿奴從袖口抖出一隻紫晶蠱，貼著掌心輕聲念訣。妖女臉上的笑第一次裂開一道縫——「苗女的蟲……」她往後縮了半寸。苗疆蠱術與妖契在霧裡無聲交咬，要看誰先咬住誰的根。",
						},
					},
					{
						"id": "power_overwhelm",
						"label": "以一身殺意壓她，逼出更好的條件",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["power"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "gold", "amount": 12},
							],
							"log": "你沒接她的話，只是把滿身殺意緩緩壓了過去。她臉上的笑僵了一瞬——立契講的是誰更不怕誰。她識相地把條件抬高了一截，主動退讓。",
						},
					},
					{
						"id": "lowhp_desperate_pact",
						"label": "重傷垂危，乾脆把命押上立契",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.35},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.6,
								"win_effects": [
									{"kind": "heal", "amount": 18},
									{"kind": "permanent_power", "amount": 2},
								],
								"lose_effects": [
									{"kind": "max_hp", "amount": -4},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
							},
							"log": "反正快撐不住了。你伸手按上她遞來的黑霧：「就賭這一把。」妖契認垂死之人的孤注，吃下去是重生，還是反噬，全在一念。",
						},
					},
					{
						"id": "leave",
						"label": "拱手婉拒",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向那張瓜子臉拱手，繞行而過。黑霧在身後悠悠散去，像是嘆了一口氣。"},
					},
				],
			},
			"nodes": {
				"node_negotiate": {
					"prompt": "你把那點心動按了回去，她眼裡反而亮了一下，像終於遇到肯講價的客人。「簡單，」她屈起三根蒼白的手指，笑得像在數一道甜點，「一滴血、一縷魂、或一段記憶。挑一個——挑慢一點也行，我等得起。」最後半句，她說得太輕，也太久了。",
					"choices": [
						{
							"id": "drop_of_blood",
							"label": "劃破掌心，付她一滴血",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "damage", "amount": 3},
									{"kind": "power", "amount": 2},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"log": "她以指尖蘸去你掌心那滴血，舔了舔，眼睛瞇成兩彎月。「就一滴？」她把一卷黑符拋進你懷裡，語氣裡有掩不住的失落，「下回……多帶一點來。」黑霧深處，似乎有什麼東西不滿地動了動。",
							},
						},
						{
							"id": "wisp_of_soul",
							"label": "咬牙割捨一縷生魂",
							"kind_hint": "punish",
							"outcome": {
								"kind": "punish",
								"effects": [
									{"kind": "max_hp", "amount": -10},
									{"kind": "permanent_power", "amount": 3},
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "gain_curse", "curse_id": "yao_zhai"},
								],
								"log": "她伸手在你胸口輕輕一拉，你聽見靈台深處「啵」地一聲輕響，像燈芯被掐去一截。力量湧進來的同時，她背過身去，肩膀垮了一下——「謝謝你，」聲音輕得幾乎聽不見，「也對不起。」黑霧深處，鏈條收緊的聲音響了一記。",
							},
						},
						{
							"id": "fragment_of_memory",
							"label": "閉眼任她翻一段記憶",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "lose_card", "mode": "random"},
									{"kind": "gain_relic_pool", "pool": "uncommon"},
								],
								"log": "你閉眼任她翻你的記憶，指尖冰涼地掠過眉心。她抽走了什麼，你已經不記得了——睜眼時掌心多了一件冰涼的法器，她正怔怔看著你，像看一個她羨慕的人。「原來人的記憶，是這個味道。」她說得很慢，捨不得嚥下去似的。",
							},
						},
					],
				},
				"node_chain": {
					"prompt": "你瞇眼細看——她背後有一條極細的黑鏈，繞過頸間，沉入更深的黑霧裡。她並非自由的，這場交易也並非她自願。",
					"choices": [
						{
							"id": "cut_chain",
							"label": "斬斷鎖鏈",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "ancient_evil_spirit",
									"enemy_hp_mult": 0.8,
									"victory_effects": [
										{"kind": "gain_relic_pool", "pool": "rare"},
										{"kind": "heal", "amount": 10},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 15},
										{"kind": "max_hp", "amount": -3},
									],
								},
								"log": "你拔劍劈向那條黑鏈。黑霧瞬間崩塌，鏈子另一端的東西——醒了。",
							},
						},
						{
							"id": "fake_pact",
							"label": "假意立契、反手破符",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.45,
									"win_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 10},
										{"kind": "permanent_power", "amount": -1},
									],
								},
								"log": "你伸手與她握住——指尖一翻，反手在符面上劃出破口。妖女的瞳孔縮成一線。",
							},
						},
					],
				},
			},
		},
	},
	"forgotten_altar": {
		"title": "棄祭壇",
		"flavor": "風吹過破爛的供品。香爐裡還有一炷未滅的香，灰燼下隱約有字跡。",
		"character_flavors": {
			"li_xiaoyao": "那炷香燒了大半，灰燼細細的一條，像是在用最後的力氣站著。逍遙湊近看見香灰下隱約有字跡，忍不住輕輕吹開——不是法術，更像是留言，是一個普通人感謝神明保佑的心意，歪歪扭扭的字，讓他愣了一下。",
			"zhao_linger": "靈兒在冷石上跪下，裙擺在石板上鋪開。她跪了很久，久到石板的涼意透過薄薄的料子滲進了膝蓋。但她沒有起身，只是靜靜地讓那份涼意蔓延，讓它提醒她：她是真實的，她在這裡，她的祈求是真的。點燃備用香的時候，她的指尖略帶顫抖，不是因為寒冷。",
			"lin_yueru": "月如打量著廢棄的祭壇，目光落在那炷未滅的香上。林家堡從不輕視神明——父親林天南說：『劍者，也是人，人者，也要敬天地。』月如在祭壇前做了個簡單的行禮，才去查看那些殘留的符跡。",
			"anu": "阿奴不需要靠近就感應到了——那炷香下面的字跡帶著一種很深的祈願，是普通人的心意，沒有術法，只有那種最樸素的、願世事平安的盼望。在苗疆，她的祖母也常這樣祈求。她在香爐邊靜靜待了片刻，才去看那些神龕底的符文。",
		},
		"heal": 7, "gain_cost": 6, "power": 2, "power_label": "焚香",
		"observe_text": "你蹲下細看那炷未滅的香。香灰下的字跡可以勉強辨認——是一個母親祈求孩子平安歸來的留言，落款日期已是七十多年前。神龕底部刻著一行更小的字：「願後來者，亦能在此片刻平靜」。這個祭壇早被遺忘，但前人留下的善念仍在低語，等待著被聽見。",
		"observe_effects": [{"kind": "heal_party", "amount": 4}],
		"choices": ["approach", "observe", "leave"],
		"branch_labels": {
			"approach": ["接近祭壇", "走到神龕前細看殘留的痕跡"]
		},
		"sub_choices": {
			"approach": ["heal", "power", "upgrade"]
		},
		"sub_flavors": {
			"approach": "你走到神龕前，跪下整理那一炷殘香。香灰下的字跡漸漸清晰，神龕的角落裡還藏著一個小布包。你必須決定：取走藥方、研讀手訣，或是純粹靜坐領悟。"
		},
		"outcomes": {
			"heal": "香灰中壓著一帖古方，入口苦澀，卻有一股暖意從丹田散開，傷口漸漸止痛。你把那個小小的藥包收好，覺得它不只是治傷，也是某個人留給下一個路人的祝福。",
			"power": "香煙繞身，灰燼下的字跡拼成一套手訣——你只看了一眼，便已銘記於心。那是前人用一生走出來的東西，此刻，就這樣飄在香煙裡，等著你。",
			"upgrade": "火光中字跡浮現，某道招式的癥結所在，你終於在這一炷香裡讀懂了。前人大概也為同樣的問題卡了很久，不然那個字跡，不會寫得那樣深。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §14）
		"tree": {
			"root": {
				"prompt": "風捲著破爛的供品紙屑打了個旋。壇身低矮，不是拜月教那種高聳嗜血的祭壇，是尋常人求平安的小香火——香爐裡竟還有一炷未滅的香，細細一線青煙直直地立著。灰燼底下，隱約壓著字跡。",
				"choices": [
					{
						"id": "incense_silence",
						"label": "焚香靜立致意",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 6},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "你續上一炷香，退後一步靜立。青煙繞身一周，全隊的傷處都泛起一陣溫熱，像被誰用掌心捂過。七十年的善念積在這裡，今天終於又有人來領。",
						},
					},
					{
						"id": "take_bundle",
						"label": "抄起布包，頭也不回地走",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "gold", "amount": 10},
								{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
							],
							"log": "你把布包塞進行囊，快步走下壇階。背上有一道淡淡的視線跟了你幾步，不怒，只是失望——東西是死人的，這份失望卻活得很久，下次拔刀時你會想起它。",
						},
					},
					{
						"id": "observe_inscription",
						"label": "俯身辨認神龕底的刻字",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inscription",
					},
					{
						"id": "disturb_incense",
						"label": "踢翻香爐，看看誰會出來",
						"kind_hint": "battle",
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "sword_spirit",
								"enemy_hp_mult": 0.8,
								"victory_effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "permanent_power", "amount": 1},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "max_hp", "amount": -2},
								],
							},
							"log": "香爐應聲而倒，香灰潑了滿地。青煙猛地一束，一道劍光自神龕之後直撲你面門——守了七十年的東西被你親手喊醒了，它很不高興。",
						},
					},
					{
						"id": "zhao_superdu",
						"label": "（趙靈兒）以靈族禮超渡母子兩魂",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal_party", "amount": 10},
							],
							"log": "靈兒跪坐壇前，以靈族古禮輕聲誦咒，一句一句，替那位等了七十年的母親把話說完。咒文落盡，香煙化作一個輕薄的人形，向她深深拱手，散在風裡。壇上忽然暖了，像久別的家。",
						},
					},
					{
						"id": "lowhp_old_remedy",
						"label": "顧不得了，抓起古方就嚥",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.4},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.65,
								"win_effects": [
									{"kind": "heal", "amount": 20},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 4},
									{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
								],
							},
							"log": "你撐不住了，也顧不得那古方是治傷還是禁忌，抓起就嚥。藥性在垂死的身子裡橫衝直撞——是救命，還是催命，賭一把。",
						},
					},
					{
						"id": "leave",
						"label": "上一炷香，作別趕路",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你在壇前上了一炷香，深深一禮。走下壇階時風停了一瞬，那縷青煙筆直地送你到路口——平安兩個字，前人求過的，如今也分你一點。"},
					},
				],
			},
			"nodes": {
				"node_inscription": {
					"prompt": "你拂開積灰，神龕底一行小字漸漸清晰：「願後來者，亦能在此片刻平靜。」字痕旁壓著一封信，紙脆得一碰即碎——是七十年前，一位母親求孩子平安歸來的留言，沒有寫完。",
					"choices": [
						{
							"id": "finish_letter",
							"label": "替她念完未盡之語",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 3},
									{"kind": "heal", "amount": 12},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你捧著那封脆黃的信，輕聲把沒寫完的話替她念完——「願吾兒平安，歸來食一碗熱飯。」香爐中的火苗安靜地搖了一下，像有人應了。你起身時，胸口那點舊疼不見了。",
							},
						},
						{
							"id": "respect_silence",
							"label": "不擾這段執念",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "common"},
								],
								"log": "你把信照原樣折好，壓回香灰底下，沒有念，也沒有帶走——有些話只屬於寫的人和等的人。離開時，神龕底多了一件小物，靜靜朝著你，是替她守了七十年的回禮。",
							},
						},
					],
				},
			},
		},
	},
	"ancient_battlefield": {
		"title": "古戰場遺跡",
		"flavor": "殘破的旌旗插在乾涸的血土上，風過時像是有人低鳴。踏入此地，眼前不自覺浮現金戈鐵馬。",
		"character_flavors": {
			"li_xiaoyao": "逍遙踩在乾涸的血土上，感到腳底有一種說不清的沉重。這裡曾經死過很多人——不是妖，是人，是會哭會笑的人，最後倒在這片土地上，連旌旗都敗破了。「你們是為什麼而戰的？」他問，風過，沒有回答，只有旌旗在風中低鳴。",
			"zhao_linger": "風從古戰場一端橫掃過來，靈兒的髮帶被吹開，長髮散在肩頭。她沒有立刻束起，就讓那些頭髮在風裡飛著，擋住視線，貼上臉頰——彷彿讓那縷風替她，暫時感受一下什麼是自由。她繼續走，心裡默念著安魂咒，頭髮披著，沒有人看見她此刻的模樣，這讓她稍微放鬆。",
			"lin_yueru": "月如在古戰場中走得很慢，眼神認真地打量每一面旌旗、每一把插在土裡的折斷武器。林家堡藏有一部《古戰史》，記載各個時期武林的血戰始末——這個戰場的規模，有幾分像書中某一頁的記載。她彎腰拾起一枚殘破鐵甲片，放在掌心看了一會兒。",
			"anu": "阿奴在戰場中停下腳步，低頭看著腳下的土。苗疆的土地也見過血，那種記憶在大地裡不會完全消散——只要你懂得感應，就能聽見。她用手指觸碰地面，感受那些埋藏的悲哀，比她預想的更深，更古老。",
		},
		"heal": 3, "gain_cost": 5, "power": 3, "power_label": "祭英靈",
		"observe_text": "你蹲下，撿起一小塊乾涸的旌旗碎片。布上的紋章你不認得，但編織的方法是中原某個失落王朝的軍服樣式——這片戰場至少有千年之久。風吹過，旌旗的低鳴中能聽到極微弱的、像是無數人同時呼喊的尾音，但每一個聲音都已散得太遠，連自己的名字都記不起來了。",
		"observe_effects": [{"kind": "power", "amount": 2}, {"kind": "damage", "amount": 2}],
		"choices": ["power", "upgrade", "view_deck", "observe", "leave"],
		"outcomes": {
			"power": "鐵馬嘯聲穿越千年壓來，死亡的殺機從血土中沁透腳底，浸入你的每一道招式。那份重量讓你的出手更沉，也更狠，像是帶著那些人最後沒能打出去的力氣。",
			"upgrade": "亡靈的眼神在你某道招式上短暫停留。離開時，那招已帶上了戰場的鋒銳——那是只有在真正的生死之間才能磨出來的東西，他們把它留給了你。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §15）
		"tree": {
			"root": {
				"prompt": "風還沒到，低鳴先到了——滿地殘旌在乾涸的血土上獵獵作響，像無數人壓著嗓子說話。斷戟與鏽甲半埋土中，沉得像將軍塚裡的陪葬。你每走一步，腳底都傳來一種說不清的重，彷彿土裡有什麼，正隔著千年看你。",
				"choices": [
					{
						"id": "pickup_banner",
						"label": "拾起殘旌，俯首祭英靈",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "heal", "amount": 5},
							],
							"log": "你拾起一角殘旌，拂去血土，朝四野俯首三拜。風忽然靜了，千年的鐵血沿著你的手腕緩緩流入心口，沉甸甸地落定——那是他們最後沒能打出去的力氣，從今往後，由你的手替他們打。",
						},
					},
					{
						"id": "summon_souls",
						"label": "焚旌喚魂，聽他們的遺言",
						"kind_hint": "battle",
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "sword_spirit",
								"enemy_hp_mult": 1.0,
								"victory_effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 2},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 12},
									{"kind": "gain_curse", "curse_id": "jiu_zui"},
								],
							},
							"log": "你祭起殘旌大喝一聲，聲音滾過空蕩的戰場。血土無聲裂開，一個披甲身影緩緩升起，斷劍橫胸——他沒有遺言，他只認得一件事：來者，先過我這一劍。",
						},
					},
					{
						"id": "observe_unfinished",
						"label": "蹲下細看那柄斷劍",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_unfinished",
					},
					{
						"id": "lin_lineage",
						"label": "（林月如）辨認旌旗上的家名",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 2},
							],
							"log": "月如一面面辨過殘旌，指尖忽然停住——褪色的紋章，是林家堡《古戰史》裡記過的先人遺名。她在父親提過的那柄劍前跪下，雙手捧劍過眉。一道蒼老的劍意流入她心中，像隔著幾代人，摸了摸她的頭。",
						},
					},
					{
						"id": "blade_communion",
						"label": "以滿身劍意與千年戰魂共鳴",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["attack"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "你拔劍一引，滿地殘旌與斷戟轟然共鳴。千年前的殺伐意志認出了同道，把一式失傳的軍陣劍法，痛快地交到了你手裡。",
						},
					},
					{
						"id": "lowhp_last_stand",
						"label": "拖著傷軀，擺出死戰之姿",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.4},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.6,
								"win_effects": [
									{"kind": "permanent_power", "amount": 3},
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 8}]},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 5},
								],
							},
							"log": "你拖著傷軀立於古戰場中央，擺出與滿地英靈相同的死戰之姿。鐵血在絕境裡反而燒得更旺——能不能燒成戰意，看你撐不撐得住。",
						},
					},
					{
						"id": "wraith_duel",
						"label": "拔劍直指土心，搦鬼一戰",
						"kind_hint": "battle",
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "ancient_evil_spirit",
								"enemy_hp_mult": 0.9,
								"victory_effects": [
									{"kind": "gain_relic_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 3},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 15},
									{"kind": "max_hp", "amount": -3},
								],
							},
							"log": "你劍尖直指土心，朗聲搦戰。地底沉默了三息，然後整片戰場的低鳴驟然止住——有什麼東西應了你，正從千年的血土深處，一寸一寸地上來。",
						},
					},
					{
						"id": "leave",
						"label": "整衣默禮，繞道而行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你整了整衣甲，向滿地殘旌深深一禮，繞著戰場的邊緣走了過去。低鳴一路跟著你，到戰場盡頭忽然齊齊一靜——像是受了禮，也還了禮。"},
					},
				],
			},
			"nodes": {
				"node_unfinished": {
					"prompt": "你蹲下身，撥開半埋的土——是一柄從中折斷的劍，劍身上深深刻著兩個字：「未竟」。刻痕是用劍尖劃的，最後一筆拖得極長，是劍主嚥氣前，用盡最後力氣留下的。",
					"choices": [
						{
							"id": "carry_will",
							"label": "拾起斷劍，接下這份未竟",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你把斷劍從土裡請出來，拭淨，別在腰間。金屬貼著腰側微微發熱，像認了主。你對著空蕩的戰場低聲許了一個諾言——「未竟」二字，從今天起有人接著寫。",
							},
						},
						{
							"id": "incense_for_him",
							"label": "堆土為壇，為他補一炷香",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 8},
								],
								"log": "你在斷劍前堆了個小小的土壇，點起隨身的香。香煙繞著斷劍打了一個圈，又一個圈，最後輕輕落在你的肩頭，像一只告別的手。你起身時，掌中多了一件他留下的物事。",
							},
						},
					],
				},
			},
		},
	},
	"alchemy_furnace": {
		"title": "煉丹爐火",
		"flavor": "青石台上的爐子還燒著，藥香混著焦味。爐蓋壓著一張藥方，字跡模糊。",
		"character_flavors": {
			"li_xiaoyao": "「哇，有人在裡面煉丹？」逍遙探頭往爐子裡瞧了一眼，又趕快縮回來——熱氣燙臉。那張藥方被壓在蓋子底下，字跡因高溫而模糊，但他眯眼辨認出了幾個字，是外婆的老方子裡也有的草藥名。真是巧，他搖了搖頭，伸出手。",
			"zhao_linger": "藥香蒸騰，靈兒不由得靠近了幾分。爐氣撲臉，讓她的臉頰瞬間紅了，也讓她的頭髮微微濕潤，貼著額頭和頸側。她用袖口扇了扇熱氣，才想起四下無人，也就不再端著，乾脆把外袍解開一點，讓熱意散去，低頭繼續辨認藥香，嘴角帶著一絲自己都沒意識到的放鬆。",
			"lin_yueru": "月如看著爐火，想起了林家堡後山的煉器房——那裡常年爐火不熄，用來磨礪劍刃而非煉藥，但那熱氣蒸騰的感覺如出一轍。林家堡的弟子從小就在高溫和壓力中鍛煉意志。她走近爐子，用劍尖挑起那張藥方，仔細查看。",
			"anu": "阿奴對煉丹不熟，但她對藥材比任何人都了解。她閉上眼睛，逐一辨認那縷縷藥香——九種，她能辨認出七種，其中兩種確定是苗疆才有的毒草，在這裡出現讓她心生警惕，同時也有幾分意外的親切。",
		},
		"heal": 10, "gain_cost": 8, "power": 2, "power_label": "服丹",
		"observe_text": "你細看丹爐的構造。爐壁上刻著一段失傳的「煉魂篇」殘卷，看似教人煉丹，實則暗藏對煉丹者本身的考驗——「丹未成而人先成」。爐口殘留的氣味告訴你，前主人嘗試的丹方是極端的「以己為材」，他可能沒有走出這裡。",
		"observe_effects": [{"kind": "upgrade_random"}],
		"choices": ["approach", "observe", "leave"],
		"branch_labels": {
			"approach": ["走近丹爐", "靠近爐口取走藥方或試丹"]
		},
		"sub_choices": {
			"approach": ["heal", "gain_card", "upgrade"]
		},
		"sub_flavors": {
			"approach": "你走到丹爐前。熱氣撲面，藥香混雜著焦味——這個爐火還在燒，主人卻已不見。爐口的藥方半埋在灰燼中，爐底還有半粒未完成的丹藥。你必須決定：取藥方、服半丹，或是借爐火磨練招式。"
		},
		"outcomes": {
			"heal": "藥香入鼻，熱氣蒸騰，舊傷在爐火的溫度中悄悄癒合，比預期快了幾分。走出爐房時，你甚至覺得呼吸都比進來時更深了一些。",
			"gain_card": "藥方上的字跡在火光中顯形，是一套從未見過的鍛體之法——你將它記下，同時也在心裡記下了那個不知名的人，留下這藥方，大概是希望後來者用得上。",
			"upgrade": "爐火高燃，你將那道招式在熱浪中反覆鍛打，純度比鍊丹之前高了一層。那個過程有些像消融，又有些像重塑——走出來時，你覺得那道招式更屬於你了。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §16）
		"tree": {
			"root": {
				"prompt": "藥香先勾住你，再走近些，又混進一股焦苦。青石台上一座丹爐還燒著，爐火無人看顧，卻燒得不急不徐。爐口擱著半粒未完成的丹，紫潤的成色竟有幾分像傳聞中水月宮的紫金丹——只是主人不見了，灰裡壓著一張字跡模糊的藥方。",
				"choices": [
					{
						"id": "swallow_half_pill",
						"label": "拈起半粒丹，仰頭嚥下",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "heal", "amount": 10},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "gain_curse", "curse_id": "jiu_zui"},
								],
							},
							"log": "丹入喉的瞬間先是甜，緊接著一股藥力在腹中炸開，順著經脈亂竄——這丹只煉了一半，剩下那一半的火候，現在要在你身體裡補完。是補是劫，看你的底子。",
						},
					},
					{
						"id": "complete_refine",
						"label": "接手爐火，替他把丹煉完",
						"kind_hint": "battle",
						"next": "node_refine",
					},
					{
						"id": "observe_secret",
						"label": "湊近爐口，細嗅那股焦味",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_secret",
					},
					{
						"id": "anu_refit",
						"label": "（阿奴）細嗅九味藥的配伍",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "gain_potion"},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "阿奴閉眼逐縷分辨藥香，鼻尖一動：「這兩味，是我們苗疆的毒草嘛。」配伍的關竅一通，她挽起袖子重調火候，添藥、收火，一氣呵成——爐蓋掀開，丹香撲面，一爐成丹。她得意地把丹瓶拋給你：「接好。」",
						},
					},
					{
						"id": "leave",
						"label": "退開三步，不沾這爐丹",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你深深吸了一口藥香，當作此行的便宜，退出了爐房。無主的爐火還在燒，燒給誰看不知道——有些便宜，聞聞就夠了。"},
					},
				],
			},
			"nodes": {
				"node_refine": {
					"prompt": "你捲起袖子接手爐火，照著爐壁上「煉魂篇」殘卷的火訣一路補火。焰光忽然拔高，由橙轉青——爐底深處有什麼被驚動了，正貼著爐壁緩緩遊走。",
					"choices": [
						{
							"id": "push_fire",
							"label": "咬牙催火，逼它現形",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "fox_spirit",
									"enemy_hp_mult": 0.8,
									"victory_effects": [
										{"kind": "gain_potion"},
										{"kind": "gain_potion"},
										{"kind": "gain_card_pool", "pool": "rare"},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 10},
										{"kind": "max_hp", "amount": -2},
									],
								},
								"log": "你不退反進，火訣連催，爐焰轟然立起一人多高。火光深處一聲嬌笑，一縷火靈幻化現形，眉目如畫，眼底卻全是火——丹是它的，爐是它的，你算什麼？",
							},
						},
						{
							"id": "pull_back",
							"label": "見勢不對，退火收功",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_potion"},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你迅速撤手收功，焰光一矮，那道貼著爐壁遊走的東西未及成形，便沉回爐底去了。爐火復歸平穩，爐心靜靜躺著一粒剛剛成形的丹——見好就收，本身就是火候。",
							},
						},
					],
				},
				"node_secret": {
					"prompt": "你湊近爐口，那股焦味裡有一絲不該有的東西——人氣。爐壁「煉魂篇」殘卷寫得明白：前主人煉的是「以己為材」的煉魂之術。爐還燒著，人沒有走出這裡。",
					"choices": [
						{
							"id": "collect_remains",
							"label": "收殮遺物，替他收場",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你在爐邊的灰裡找到一塊未化盡的骨片，用乾淨的布裹了三層，鄭重收進行囊。不管他求的是什麼，總算有人替他收了場。爐火在你身後輕輕一矮，像鬆了一口氣。",
							},
						},
						{
							"id": "burn_scroll",
							"label": "撕掉殘卷阻斷邪法傳承",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "lose_card"},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你把「煉魂篇」殘卷從爐壁上整片撕下，投進爐火。紙灰打著旋升起來，你心中某道攥了很久的執念，也跟著一同鬆動、脫落——這條邪路，到此為止，不傳了。",
							},
						},
					],
				},
			},
		},
	},
	"ghost_forest": {
		"title": "鬼林迷霧",
		"flavor": "樹影在霧中晃動，有什麼在彼端注視著你。越深入，心跳卻越發清晰有力。",
		"character_flavors": {
			"li_xiaoyao": "霧林讓逍遙想起了鎖妖塔的底層——那裡也是這樣，樹影搖晃，像是有什麼東西在你身後跟著你，但一回頭又什麼都沒有。他在樹叢中慢慢走，把手放在劍柄上，告訴自己：越怕越要走直，越怕越要走快。",
			"zhao_linger": "霧林裡有很多眼睛在看她。靈兒感應到了，輕飄飄的，圍著她轉，有些是好奇，有些是別的什麼。有什麼東西悄悄從她身旁滑過，帶起了裙擺的邊緣，讓她感到一陣細細的涼意從腳踝升上小腿。她沒有加快腳步，只是把護身薄膜凝得更緊一些，繼續往前，心跳微微快了幾分。",
			"lin_yueru": "月如把手按在劍上，穩步走入霧林。林家堡有一門功課叫做「亂境心法」，訓練弟子在視覺干擾下保持平衡的心態——這片霧林，對她而言更像一道考驗，而非一場威脅。越深入，她的心跳反而越清晰有力，像是劍心在此刻得到了磨礪。",
			"anu": "阿奴在霧林裡走得很安靜，幾乎沒有腳步聲。她從小在南詔的密林中長大，習慣了和各種存在共處——那些在彼端注視你的眼睛，不見得都是惡意的，有些只是好奇，有些只是寂寞。她輕聲用苗語問了一句：「你們想要什麼？」",
		},
		"heal": 0, "gain_cost": 3, "power": 3, "power_label": "借膽",
		"gamble_win_power": 4, "gamble_lose_damage": 10,
		"observe_text": "你停下腳步，閉眼感應周遭。霧中的眼睛有兩種：一種帶著好奇，從遠處飄過，並不靠近；另一種懸在你正前方一棵老樹的高處，紋絲不動，呼吸極淺——這個是危險的，是會撲擊的捕食者。你知道：往北走是安全方向，往南走會迎向那雙眼睛。賭一把進去，可以借膽，也可能受傷。",
		"observe_effects": [{"kind": "heal", "amount": 5}, {"kind": "gold", "amount": 4}],
		"choices": ["gain_card", "gamble", "observe", "leave"],
		"outcomes": {
			"gain_card": "霧中有什麼東西跟了你一段路，離去前在地上留下一手殘術。那術法粗糙，卻透著一股野生的力量——像是某個從未拜師的存在，自己摸索出來的東西。",
			"gamble_win": "心跳越來越清晰，不再是恐懼——是膽氣。那股力量從丹田直衝頭頂，讓你在走出霧林的那一刻，覺得自己大了一點，也深了一點。",
			"gamble_lose": "樹影猛地撲來，爪痕划過胸口。你忍著痛跑出了霧林，背後有嘲笑聲漸漸遠去——那聲音讓你咬牙，也讓你記住了今天，記住了這個教訓。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §17）
		"tree": {
			"root": {
				"prompt": "霧先漫過腳踝，再漫過刀柄，濃得像仙靈島外那座困過無數人的迷陣。樹影在霧中緩緩晃動，明明無風。有什麼在彼端注視著你——看不見，但你的後頸知道。奇怪的是，越往深處走，你的心跳反而越清晰、越有力。",
				"choices": [
					{
						"id": "quick_cross",
						"label": "壓低身形，搶快穿過去",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "gold", "amount": 12},
								],
								"lose_effects": [
									{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 2}]},
									{"kind": "damage", "amount": 4},
								],
							},
							"log": "你壓低身形，揀著樹影的縫隙快步穿行，霧中那些目光緊緊跟著你的背——它們在等你跑出破綻，一個趔趄、一聲喘，都算。",
						},
					},
					{
						"id": "brave_charge",
						"label": "拔刃直入，朝那目光闖去",
						"kind_hint": "battle",
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "fox_spirit",
								"enemy_hp_mult": 0.9,
								"victory_effects": [
									{"kind": "permanent_power", "amount": 3},
									{"kind": "gain_card_pool", "pool": "rare"},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 12},
									{"kind": "gain_curse", "curse_id": "gu_du"},
								],
							},
							"log": "你拔出兵刃，不挑路，直直朝那道注視走過去。霧忽然向兩旁讓開——一隻金瞳狐影自霧心浮出，姿態慵懶，眼裡卻全是算計：敢闖進來的，不是膽子大，就是肉好吃。",
						},
					},
					{
						"id": "observe_directions",
						"label": "屏息分辨霧中每雙眼睛",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_directions",
					},
					{
						"id": "lxy_sword_guide",
						"label": "（李逍遙）請劍靈感應指路",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 8},
							],
							"log": "逍遙握緊劍柄小聲商量：「老夥計，幫個忙唄。」劍身嗡了一聲。「往這邊走。」劍靈在他腦中冷冷地說，「別再亂晃了你。」一路被數落著出了霧林，傷口倒是被劍氣順手收拾妥當——嘴硬心軟，說的就是它。",
						},
					},
					{
						"id": "poison_commune",
						"label": "放出蠱蟲與霧林毒瘴相認",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["poison"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 6},
							],
							"log": "你放出隨身的蠱蟲。牠們沒入毒瘴，竟與林中的妖氣一拍即合——霧林像是認了同類，替你讓開一條路，還回贈了一道馴毒的手法。",
						},
					},
					{
						"id": "lowhp_feign_corpse",
						"label": "索性伏倒裝死，誘它靠近",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.4},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 6},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 5},
								],
							},
							"log": "你撐不住了，乾脆伏倒裝死，屏息等那雙金瞳湊近——拿傷勢當餌，賭牠先鬆懈，還是你先撐不住。",
						},
					},
					{
						"id": "fox_repays",
						"label": "向霧中那雙熟悉的金瞳輕聲問候",
						"kind_hint": "reward",
						"requires": {"event_flag": "fox_spared"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 10},
								{"kind": "gain_potion"},
							],
							"log": "霧中那雙金瞳一亮——是你先前在隱龍窟放走的狐女。她認得你。她沒有現出全身，只把一條最安全的小徑照亮，又留下一枚療傷妖丹：「這次換我引你。」恩，是會回來的。",
						},
					},
					{
						"id": "leave",
						"label": "按下好奇，原路退出去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你倒退著走出霧界，直到後頸那道注視鬆開，才轉身快步離去。霧林在你身後合攏，像一張沒等到獵物的網——不冒這個險，不丟人。"},
					},
				],
			},
			"nodes": {
				"node_directions": {
					"prompt": "你站定屏息，把霧中每一雙眼睛分開來聽。多數是遠遠飄過的好奇，不傷人；唯獨南面一棵老樹高處，懸著一雙紋絲不動的眼，呼吸壓得極淺——那是會撲下來的。北面，氣息乾淨。",
					"choices": [
						{
							"id": "north_safe",
							"label": "取北線，繞開那雙眼睛",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 10},
									{"kind": "gold", "amount": 8},
								],
								"log": "你貼著北線的樹根輕步而行，霧一路稀薄下去，最後一步跨出林緣，陽光重新落到肩上，曬得人想嘆氣。林口草叢裡還躺著前人失落的錢囊——識路的人，總有路費。",
							},
						},
						{
							"id": "south_ambush",
							"label": "摸向南線，反伏擊那捕食者",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "serpent_demon",
									"enemy_hp_mult": 0.8,
									"victory_effects": [
										{"kind": "gain_relic_pool", "pool": "rare"},
										{"kind": "permanent_power", "amount": 2},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 14},
										{"kind": "max_hp", "amount": -3},
									],
								},
								"log": "既然看清了它，先手就是你的。你繞到老樹背風的下方，足尖借力，第一劍直刺那雙黃眼——獵人與獵物，今天換個位置坐坐。",
							},
						},
					],
				},
			},
		},
	},
	"immortal_ruins": {
		"title": "仙人遺址",
		"flavor": "地上的符紋已褪色，踩上去腳底仍有微微震動，像是某種呼吸尚未停止。",
		"character_flavors": {
			"li_xiaoyao": "逍遙站在符紋上，腳底傳來的震動讓他想起了師父說過的話：『仙人不是傳說，只是走遠了而已。』他努力回想那句話的語氣，不像是開玩笑，更像是在說一件親眼見過的事。他低下頭，看著腳下那些褪色的符紋，想像著它們曾經燃亮的樣子。",
			"zhao_linger": "靈兒踩上符紋，震動從腳底傳入，沿著腿骨一路上升，抵達腰脊，又繼續往上——一種非常細微、卻無法忽視的顫動，讓她閉上眼睛，站定不動。她站了很久，讓那振動慢慢流遍全身，在心裡問它：你們，和我的先人，是否認識？它再次震動，像是回答，也像是一個久違了的擁抱，終於抵達。",
			"lin_yueru": "月如踩著符紋，感受腳底那微微的震動。林家堡藏書閣裡有幾卷殘篇，記載了仙人遺址的探訪規矩：不強行汲取，不輕易破壞，只是感受。她深吸一口氣，放開了對力量的主動追求，讓那些古意自然地流過自己，像水過石縫。",
			"anu": "阿奴知道什麼是仙人遺址。南詔的山地裡有幾處，是苗疆女巫的禁地。這裡的符紋她讀不懂，但那種氣息她認識——是某種已經完成了的存在的殘跡，不是死去，是『已然圓滿』的歸寂。她站在遺址中央，感到了一種罕見的心靜。",
		},
		"heal": 6, "gain_cost": 6, "power": 2, "power_label": "感悟",
		"observe_text": "你細感腳下符紋的震動。那不是死去的符紋的迴響，是「仍在運作中」的——這位仙人並未離去，只是入定到極深的層次，他的修為仍在以一種你理解不了的方式繼續著。在這裡的存在本身，就是一種「被見證」的福氣。",
		"observe_effects": [{"kind": "max_hp", "amount": 3}, {"kind": "heal", "amount": 5}],
		"choices": ["power", "upgrade", "gain_card", "view_deck", "observe", "leave"],
		"choice_filters": {
			"gain_card": {"if_character": ["li_xiaoyao"]}
		},
		"character_outcomes": {
			"li_xiaoyao": {
				"gain_card": "逍遙踩上符紋的瞬間，腳底傳來的震動和他學御劍術第一年的某次冥想相似——那是師父指導他「以身合天」的那一晚。符紋認得他這個血脈中的劍仙之氣。一道精煉版的「仙風雲體術」在他腦中徐徐展開，這不是新東西，是這位仙人替他把已有的招式擦得更亮了一些。"
			}
		},
		"outcomes": {
			"power": "符紋震動，古仙的意念透過腳底傳入——某種久遠的悟境，在這一刻流過了你。你說不清那是什麼，只知道離開時，你的招式裡多了某種你以前沒有的東西。",
			"upgrade": "仙人的殘跡讓你看懂了一道本以為無從精進的招式，那道罅隙終於彌合。你在遺址中站立了很久，久到腳底的震動都靜了，才慢慢走出去。",
			"gain_card": "符紋之光在你體內流轉，一道古仙的招式輪廓隨著震動烙進記憶。那招式樸素卻深邃，像是用最簡單的動作說最複雜的道理。"
		},
		# Batch B 凍結設計（docs/EVENT_BRANCHING.md §18）
		"tree": {
			"root": {
				"prompt": "腳掌落下的剎那，你感到地面在極輕地顫——像呼吸。低頭看，褪色的符紋鋪滿整片石坪，一圈一圈收向中央，古老得像試煉窟最底層的陣法。仙人遺址。可這震動不是殘響，是還沒停下的修行：他沒有走，只是入定得太深。",
				"choices": [
					{
						"id": "accept_legacy",
						"label": "跪入符紋中央，靜受傳承",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "max_hp", "amount": 3},
								{"kind": "gain_card_pool", "pool": "rare"},
							],
							"log": "你跪在符紋中央，把呼吸放到最輕。許久，一道古老的意念自地底升起，輕拂你的眉心，像翻一頁書那樣翻過了你的一生，然後在某一頁停下，添了幾筆。你起身時，那幾筆已長在你身上。",
						},
					},
					{
						"id": "invade_inner",
						"label": "踏破符紋，闖內陣奪法",
						"kind_hint": "battle",
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "ancient_evil_spirit",
								"enemy_hp_mult": 1.0,
								"victory_effects": [
									{"kind": "gain_relic_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 3},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 15},
									{"kind": "max_hp", "amount": -5},
								],
							},
							"log": "你一腳踏碎外圈符紋，朝陣心直闖。地底的震動驟然一亂，像沉睡之人被踩了手——守陣的餘魂自地下浮起，無面無目，卻通身都是被冒犯的怒意。",
						},
					},
					{
						"id": "observe_meditation",
						"label": "感應仙人呼吸頻率",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_meditation",
					},
					{
						"id": "lxy_resonance",
						"label": "（李逍遙）以仙風雲體術共鳴",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 2},
								{"kind": "max_hp", "amount": 3},
							],
							"log": "逍遙依稀記得師父教的「仙風雲體術」起手，半信半疑地踏進陣中比劃起來。符紋忽然逐圈亮起——它認得這路數，認得他血脈裡那點劍仙之氣。一道精煉過的招式直接刻進他的識海，像前輩替後生把舊劍磨亮了還回來。",
						},
					},
					{
						"id": "power_resonance",
						"label": "放出滿身殺意，與古仙共振",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["power"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 3},
							],
							"log": "你不跪不求，只把一身淬鍊到極處的殺意緩緩放出。符紋劇烈震顫，像是被喚醒的舊識——古仙的入定意念與你的鋒芒對撞、相認，臨去前替你的劍意又添了一層厚度。",
						},
					},
					{
						"id": "leave",
						"label": "斂步默禮，繞陣而行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你退到符紋之外，朝陣心默默一禮，貼著遺址的邊緣繞了過去。腳底那道呼吸般的震動送了你一程才淡去——修行人不擾修行人，這是道上最老的規矩。"},
					},
				],
			},
			"nodes": {
				"node_meditation": {
					"prompt": "你閉上眼，把注意力沉到腳底——震動有節律，一長，一短，竟與你的呼吸隱隱呼應。這位仙人入定千年，此刻仍在以一種你不懂的方式修行，而你正站在他的吐納之間。",
					"choices": [
						{
							"id": "sync_breath",
							"label": "調勻氣息，與他同頻吐納",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "permanent_power", "amount": 1},
									{"kind": "heal", "amount": 8},
								],
								"log": "你調勻呼吸，一寸寸貼上那個古老的節律。合上的剎那，識海輕輕一震，某道招式自行拆開、重組，比你自己練十年拆得更乾淨。睜眼時天色已換，你的傷口也在那一吸一吐間養好了大半。",
							},
						},
						{
							"id": "take_jade",
							"label": "取走外圍一塊刻紋玉",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "gold", "amount": 15},
								],
								"log": "你看準最外圍那塊已脫離陣勢的刻紋玉，雙手請起，朝陣心深深一拜。震動沒有變化——他不在意，或者，這本就是留給看得懂分寸之人的。玉入懷中微溫，像一聲不出口的「拿去吧」。",
							},
						},
					],
				},
			},
		},
	},
	# ── PAL1 原著素材 ──────────────────────────────────────────────
	"spirit_clan_ruins": {
		"title": "靈族遺跡",
		"flavor": "石壁上刻著流動如水的符文，散發著非人間的溫柔氣息——這是靈族的文字。",
		"character_flavors": {
			"li_xiaoyao": "逍遙認出了石壁上的那些字——不是因為他看過，而是因為他在某個人身上見過類似的東西。靈兒。那些流動的符文，和靈兒說話時手上無意識劃出的靈氣軌跡，有幾分相似。他下意識喃喃出口她的名字，然後摸了摸鼻子，站在石壁前看了很久，什麼都沒說。",
			"zhao_linger": "靈兒把手掌平貼上石壁，符文在掌心下微微發熱，像是在呼吸。她把額頭也輕輕靠了上去，石面涼而符文熱，一冷一熱地貼著她的臉。眼淚從眼角流下來，沿著臉頰滴在石台上，她沒有躲，就讓它流，讓那個觸感替她說出了那些說不完的話：「母親……你們的根，在這裡。」",
			"lin_yueru": "月如打量著符文，試圖以林家堡所學的符法知識加以解讀，但沒有成功——這是她從未接觸過的文字體系。她想到了靈兒，心中對這個溫柔的靈族少女又多了幾分敬意：帶著這樣龐大而陌生的傳承，還能走得如此平靜，不是一件容易的事。",
			"anu": "阿奴看著石壁，表情沒有太大變化。南詔和靈族的記載幾乎沒有交疊，但苗疆的古老傳說裡有一句話：『大地的另一面，住著會說天語的人。』她一直以為那只是傳說。而眼前的符文，讓她覺得，也許那傳說並非空穴來風。",
		},
		"heal": 10, "gain_cost": 7, "power": 2, "power_label": "引靈",
		"observe_text": "你細看遺址。牆上有些字符你似乎認得，又似乎不認得——那是靈族最古老的書寫方式，已經失傳千年。一塊石板上刻著一句完整的句子：「我們選擇沉默，是為了不讓恨意延續。」這個遺址的主人，做了一個比戰鬥更艱難的決定。",
		"observe_effects": [{"kind": "max_hp", "amount": 2}, {"kind": "power", "amount": 1}],
		"choices": ["heal", "gain_card", "power", "upgrade", "observe", "leave"],
		"character_outcomes": {
			"zhao_linger": {
				"heal": "靈兒把雙手平貼在石壁上，符文的溫度透過指尖傳入。一個她從未見過、但血脈裡明確認識的女子——她的曾祖母——彷彿就站在她身後，把溫熱的手掌覆在她的傷口上。「孩子，妳走了這麼遠。」那聲音輕柔地說。靈兒沒有回頭，只是讓眼淚靜靜地流，整個人在這份隔了百代的擁抱裡，慢慢復原。",
				"gain_card": "靈兒在石壁前靜立。符文一道道亮起，組成一個她從未學過、但完全看得懂的咒術——這是她族人留給後人的遺贈，只有純正血脈才能讀取。咒術名為「歸真」，是讓靈氣回歸本源的純淨之法，她接住了它，覺得手掌都暖了起來。"
			}
		},
		"outcomes": {
			"heal": "靈族符文中有一股溫柔的力量滲出，如同掌心捧著月光，傷口悄然癒合。那股力量輕巧而持久，讓你想起某個溫柔的存在，還在某個遙遠的地方守護著你。",
			"gain_card": "符文在指尖微微顫動，一道靈族的術法輪廓悄悄映入腦海，輕巧而深邃。那招式不像是攻擊，更像是某種對話——和天地的對話。",
			"power": "你以靈族的冥想之法調息，意念與靈氣在體內流轉，劍意無形中更加圓融有力。離開時，你覺得自己的每一口呼吸，都比以前更踏實了幾分。",
			"upgrade": "靈族文字中藏著精煉招式的竅門，你沉思良久，某道招式的最後一個謬誤消失了。那一刻，你感到有什麼東西在很遠的地方，輕輕點了點頭。"
		},
		"tree": {
			"root": {
				"prompt": "風穿過坍塌的石廊，帶來一股近乎水汽的清涼。石壁上的符文流動如水，一筆一畫都不像人間的字——溫柔，卻沉重得壓人。指尖還沒碰上，符文已自己亮了一線，像是認得你血裡的某樣東西，又像是在問：你來，是為了記得，還是為了取走？",
				"choices": [
					{
						"id": "listen",
						"label": "收手垂目，靜聽符文低語",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 12},
								{"kind": "max_hp", "amount": 2},
							],
							"log": "你閉目靜聽，符文的溫度順著呼吸滲入。傷口悄然合攏，胸口像被一隻看不見的手攏住——不索取，只是給予。",
						},
					},
					{
						"id": "force_channel",
						"label": "不等它應允，按掌強引靈氣",
						"kind_hint": "gamble",
						"hide_badge": true,
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "max_hp", "amount": 3},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 9},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
							},
							"log": "你不等符文同意，逕自把掌心按上石壁——靈氣猛然倒灌，是接納，還是排斥，要看你配不配。",
						},
					},
					{
						"id": "poison_rubbing",
						"label": "放蠱沿紋爬行，拓走符文祕密",
						"kind_hint": "mixed",
						"requires": {"deck_archetype": ["poison"]},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "damage", "amount": 4},
							],
							"log": "你放出細蠱沿符文爬行，用毒液把整道紋路拓了下來。蠱蟲灼傷了你的指尖，但符文的祕密，已經爬進了你的招式裡。",
						},
					},
					{
						"id": "zhao_homecoming",
						"label": "（趙靈兒）以血脈歸宗",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"], "not_event_flag": "spirit_clan_blessed"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 12},
								{"kind": "max_hp", "amount": 5},
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "set_flag", "flag": "spirit_clan_blessed"},
							],
							"log": "靈兒雙手貼壁，符文一道道亮起，認出了她血裡的東西。曾祖母的聲音輕輕響起：「孩子，妳回來了。」整支隊伍都被這份隔了百代的暖意包覆。",
						},
					},
					{
						"id": "read_inscription",
						"label": "細讀石板上的完整句子",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inscription",
					},
					{
						"id": "leave",
						"label": "不驚動，繞行離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向石壁深深一禮，沒有伸手。有些東西，不屬於你，就不該碰。"},
					},
				],
			},
			"nodes": {
				"node_inscription": {
					"prompt": "你拂去石板上的塵，半行古字終於連成一句：「我們選擇沉默，是為了不讓恨意延續。」石壁深處傳來一聲極輕的嘆息——這曾被黑苗血洗、滅了滿門的一族，臨終留下的不是咒怨，而是一道叫後來者放下的訓誡。石板背後，隱約嵌著一塊溫潤的靈玉。",
					"choices": [
						{
							"id": "honor_silence",
							"label": "領會這份克制，靜坐一夜",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "heal", "amount": 8},
								],
								"log": "你在石壁前靜坐一夜。隔日離開時，劍意沉了幾分，殺意卻淡了幾分——原來放下，也是一種力量。",
							},
						},
						{
							"id": "pry_jade",
							"label": "撬下石板背後的靈玉帶走",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "gain_curse", "curse_id": "yao_zhai"},
								],
								"log": "你撬下那塊溫潤的靈玉。石壁在你身後黯了下去，符文的溫柔不見了，只剩一股說不清的涼意，從此跟著你。",
							},
						},
					],
				},
			},
		},
	},
	"baiyue_altar": {
		"title": "拜月教壇",
		"flavor": "廢棄的祭壇殘留著令人不安的血痕，焚香的氣味無法掩蓋腐敗的底味。牆上的拜月教符文在月光下詭異地泛光。",
		"character_flavors": {
			"li_xiaoyao": "逍遙的背脊在看見拜月符文的一瞬間冷了一下。他知道拜月教——這個名字和他的一段記憶有關，那段記憶讓他到現在還覺得說不出口。他站在廢棄的祭壇前，把那份複雜壓下去，只是冷靜地判斷：這裡的符文殘留，到底有多少是陷阱，有多少是機緣。",
			"zhao_linger": "那份力量向她試探，細密地梳過她的靈氣邊界，像是有眼睛在她的外衣之下，細細地打量。靈兒緊緊收束自己的氣息，雙手抱臂，不是因為冷，而是因為那個被剝開、被查看的感覺讓她不舒服。她在廢棄的祭壇前站直，告訴自己：讓它看，看不進去的，就是邊界。",
			"lin_yueru": "月如的手在劍柄上握得緊了幾分。拜月教的名字她聽過——父親林天南在她出發前最後的叮囑裡提到了它，語氣沉重，要她遇見了遠走，不要正面對抗。她不打算完全聽從，但她也不愚蠢——先確認沒有還在活動的拜月教徒，才踏入祭壇。",
			"anu": "阿奴在苗疆聽說過拜月教的傳聞：他們追求的，是某種通過獻祭獲得的極端力量。她圍繞祭壇走了一圈，用蠱術探查殘留的力量性質——確實扭曲，但也確實強大。她看著那些符文，心裡權衡著這份力量的代價，知道這世上沒有白拿的東西。",
		},
		"heal": 0, "gain_cost": 5, "power": 3, "power_label": "邪法",
		"taint_damage": 6,
		"observe_text": "你謹慎地環視四周。祭壇中央有一個用血畫成的環，環裡缺了一塊，像是儀式進行到一半被人打斷。地上散落幾片帶字的黃色符紙，字跡都是反書——這是拜月教刻意製造的失序儀軌。你判斷：此處留有殘餘邪力，但已無守護術，貿然汲取會反噬，破除卻能取得一點代價可控的力量。",
		"observe_effects": [{"kind": "damage", "amount": 3}, {"kind": "gold", "amount": 8}],
		"choices": ["approach", "observe", "leave"],
		"branch_labels": {
			"approach": ["踏入祭壇", "走入這個邪氣未散的儀軌之中"]
		},
		"sub_choices": {
			"approach": ["gain_card", "tainted_power", "remove"]
		},
		"sub_flavors": {
			"approach": "你跨入血環之內。腳底傳來一陣陣低沉的脈動，符文在月光下隱隱發燙。你必須選擇要做的事——抄錄符文、汲取邪力，或乾脆破除這個儀軌。"
		},
		"character_outcomes": {
			"zhao_linger": {
				"remove": "靈兒在血環中央站立，靈族的天然血脈讓符紋在她靠近時微微顫抖、退讓。她舉起雙手，將拜月邪符一片片燒成灰燼——這是她該做的事，她的族人為了阻止這一切付出了多少代價，此刻她替他們收尾。心中某道久積的鬱結也隨符灰一同散去。"
			}
		},
		"outcomes": {
			"gain_card": "符文在你取閱的瞬間炸裂，一道扭曲卻有效的術法烙印在你的掌心。那招式有效，但你不確定，用的時候，用的究竟是你自己的力量，還是別的什麼。",
			"tainted_power": "邪法湧入，招式的鋒銳瞬間倍增——代價是胸口一陣灼燒，像是有什麼東西趁機咬了你一口，嚐了嚐你的生機，然後滿意地退去，留下一個印記。",
			"remove": "你出手破除了一道符文。某道阻礙自身的舊有招式在符光消散中一同化去，心中忽然乾淨了——只是這乾淨，是用一片廢墟換來的。"
		},
		"tree": {
			"root": {
				"prompt": "腐味先撲上來，焚香壓不住底下那股甜膩的血腥。月光斜照進廢殿，地上一圈血環畫得張狂，卻缺了一塊，像被人臨陣斬斷；黃符上的字全是反書，在光裡幽幽泛綠。拜月教的儀軌——你只差半步就踏進去。它仍餓著，等的就是一個肯走進來的人。",
				"choices": [
					{
						"id": "step_inside",
						"label": "壓下寒意，跨進血環",
						"kind_hint": "mixed",
						"next": "node_inside",
					},
					{
						"id": "observe_circle",
						"label": "蹲下，細辨那道缺口的形狀",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_complete",
					},
					{
						"id": "zhao_dispel",
						"label": "（趙靈兒）以靈族秘法從外圍破除",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 8},
								{"kind": "max_hp", "amount": 3},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "靈兒以靈族指訣連點符紋。整座祭壇的邪氣在她血脈中柔柔散去——這不是覆滅，是替它畫上一個遲到了百年的句點。",
						},
					},
					{
						"id": "gu_devour_evil",
						"label": "驅蠱上前，噬食壇上邪力",
						"kind_hint": "mixed",
						"requires": {"deck_archetype": ["poison"]},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "damage", "amount": 4},
							],
							"log": "你放出毒蠱去噬食那團邪力。蠱蟲吞下扭曲的妖氣，撐脹得發亮，回頭時竟帶回了一道把邪力煉為己用的法門——只是有一隻反咬了你一口。",
						},
					},
					{
						"id": "lowhp_channel_evil",
						"label": "重傷將死，索性強引邪力續命",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.35},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "heal", "amount": 22},
									{"kind": "permanent_power", "amount": 2},
								],
								"lose_effects": [
									{"kind": "max_hp", "amount": -5},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
							},
							"log": "你已沒有退路，乾脆把掌心按上血環，任那股邪力倒灌進殘破的身子——拿命博一線生機，反噬與重生，只在一瞬。",
						},
					},
					{
						"id": "leave",
						"label": "不碰這口血盤，繞道而行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你退出血環外緣，把月光下泛綠的符文留在身後。走出廢殿好遠，那股甜膩的腥味才從鼻腔裡散去——有些便宜，貪不得。"},
					},
				],
			},
			"nodes": {
				"node_inside": {
					"prompt": "腳一落進血環，腳底便傳來低沉的脈動，像踩在某種還在呼吸的東西背上。四周符文應和著燙起來，反書的字句湊到眼角，催著你伸手。抄它、吸它、還是毀它——它不在乎你選哪個，只在乎你終於肯動手。",
					"choices": [
						{
							"id": "copy_runes",
							"label": "憑記性，把符文一筆筆描下",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.5,
									"win_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 6},
										{"kind": "gain_curse", "curse_id": "xie_yin"},
									],
								},
								"log": "你蹲下身，憑記憶把符文一筆一畫抄入隨身的紙卷——當你寫到第三道時，符紙忽然燙起來。",
							},
						},
						{
							"id": "draw_evil",
							"label": "按掌血環，把邪力灌進經脈",
							"kind_hint": "punish",
							"outcome": {
								"kind": "punish",
								"effects": [
									{"kind": "max_hp", "amount": -5},
									{"kind": "permanent_power", "amount": 3},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
								"log": "你以掌心按上血環中央。邪氣沿著經脈灌入——是力量，也是印記。你知道從此這條路只能走下去，再也不回頭。",
							},
						},
						{
							"id": "purify",
							"label": "一劍挑破中心符文，斷了它",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 5},
									{"kind": "lose_card", "mode": "random"},
								],
								"log": "你以劍尖挑破中心符文。整個血環在一聲悶響中崩解——胸中某道舊習也隨之碎裂，乾淨得令人微微失重。",
							},
						},
					],
				},
				"node_complete": {
					"prompt": "你蹲低細看，指尖才碰到缺口的邊，背上寒毛就全立了起來——那缺的一塊，分明是個蜷縮的人形。儀軌只差最後一筆：一條活生生的人命。它一直缺著，不是沒人畫完，是沒人敢補。",
					"choices": [
						{
							"id": "fill_with_own_blood",
							"label": "割掌，以自己的血補全那一筆",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "baiyue_guard",
									"enemy_hp_mult": 1.2,
									"victory_effects": [
										{"kind": "gain_relic_pool", "pool": "rare"},
										{"kind": "permanent_power", "amount": 3},
									],
									"defeat_effects": [
										{"kind": "max_hp", "amount": -8},
										{"kind": "gain_curse", "curse_id": "xie_yin"},
									],
								},
								"log": "你割破掌心，血珠落入缺口——整座祭壇活了過來。一道身影從血環中央升起，朝你走來。",
							},
						},
						{
							"id": "fill_with_old_blood",
							"label": "尋來陶罐舊祭血，瞞天過海",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
								],
								"log": "你在祭壇後翻出一個陶罐——裡面是早年的祭血，黏稠卻仍帶血腥。你用這罐血補上缺口，符文亮起、又熄滅。你沒留下印記。",
							},
						},
					],
				},
			},
		},
	},
	"tavern_acquaintance": {
		"title": "酒館舊識",
		"flavor": "熟悉的酒香飄來，掌櫃正在擦著杯子。看見你走進來，他只是點點頭，像是見過無數次一樣。",
		"character_flavors": {
			"li_xiaoyao": "逍遙一走進酒館，鼻子就先放鬆了。熟悉的酒香、熱食的氣味、人聲的嘈雜——這和餘杭的小客棧沒什麼兩樣，讓他的肩膀不自覺地鬆下來。掌櫃看見他，點了個頭，動作和外婆看見常客時一模一樣。有些東西是相通的，走到哪裡都一樣。",
			"zhao_linger": "靈兒在酒館裡坐定，過了一會兒，感到有人在看她。是角落的一個年輕人，視線一觸即縮，但不到片刻又飄回來，有些僵，有些難以置信。她假裝沒有注意到，端起茶盞喝了一口，但嘴角忍不住微微上揚了——被這樣直白地看著，說不上舒不舒服，只是很難完全不在意。",
			"lin_yueru": "月如在酒館裡環顧一圈，選了一個背靠牆壁、正對門口的位置坐下——林家堡的訓練讓她在任何場合都保持警覺。但這個酒館氣氛平和，掌櫃面善，她判斷沒有威脅，才允許自己點了一碗熱湯，靠著椅背，這是她難得的片刻放鬆。",
			"anu": "阿奴推開酒館的門，裡面的人看了她一眼，又看了她一眼。她習慣了——苗疆裝束在中原總是引人注目，她早已不在意了。她在角落找了個僻靜的位置，把斗笠壓低，叫了一杯最便宜的酒，然後靜靜地聽著四周的話語，從中篩選有用的信息。",
		},
		"heal": 18, "gain_cost": 6, "power": 1, "power_label": "聽聞",
		"observe_text": "你細看酒館裡的人。靠窗坐著一個老劍客，劍橫於桌邊，眼神空——他在等什麼人，等了很久。角落有兩個商旅在交頭接耳，談的是最近某條商路被截的事。掌櫃擦杯子的手法很穩，是練過的——他可能不只是掌櫃，這個酒館，可能是某個門派的隱秘聯絡點。",
		"observe_effects": [{"kind": "gold", "amount": 8}, {"kind": "heal", "amount": 4}],
		"choices": ["heal", "upgrade", "power", "observe", "leave"],
		"character_outcomes": {
			"li_xiaoyao": {
				"heal": "掌櫃端來那碗熱湯時，逍遙鼻子立刻酸了——是外婆煮給他喝過上百次的同樣味道：花雕加薑、配上一點橙皮。他低頭喝湯，喝到一半，眼眶有點熱，趕緊用袖子擦了擦：「沒事沒事，就是辣眼睛。」掌櫃哼了一聲，沒拆穿他。"
			},
			"zhao_linger": {
				"heal": "靈兒回到角落坐下，那個年輕人遠遠地給她遞了個杯——是當年餘杭某個小店的特製花茶。她沒有喝，只是接過，向他輕輕點了個頭。陌生人之間能傳遞的善意，原來可以這樣輕，這樣不打擾，像是一片葉子，剛好飄到她的杯邊。"
			},
			"lin_yueru": {
				"upgrade": "月如向老劍客敬酒，得到的回應比她預期的多——老人放下酒杯，用兩根手指在桌上比劃了一個劍式。「林家堡？你父親林天南是我師侄。」他說，「他當年的這一招，我替他改過。你要不要試試？」月如的手停在酒杯邊，沒有立刻回應，但她的眼神已經告訴了老人答案。"
			},
			"anu": {
				"power": "阿奴坐在角落聽商旅閒談，他們講到南疆某條山路，最近常有蠱師出沒。她的耳尖動了一下——是家鄉那邊的事。她沒有插話，只是把這些訊息記在心裡。離開時，她在桌上留下一個小小的銀鈴，是苗疆人傳遞「我聽到了」的信物，希望某個聽得懂的人能收下。"
			}
		},
		"outcomes": {
			"heal": "掌櫃端來一碗熱湯，不說話，就那樣放在你面前。喝完，渾身的疲憊比預期輕了許多——有時候，不問緣由的善意，是最好的藥。",
			"upgrade": "你向角落的老劍客敬了一杯酒。他點頭，低聲說了半句話——你手中那道招式從此不同了。你不知道他是誰，他也沒有說，但那半句話，你記住了。",
			"power": "你傾耳聽著旅客談論路上的遭遇，某個細節讓你想起一種早被遺忘的應變之道。有時候，最有用的東西，藏在最普通的話語裡。"
		},
		"tree": {
			"root": {
				"prompt": "酒香混著熱湯的暖氣先漫過來，像餘杭客棧後堂的味道。掌櫃頭也沒抬，擦杯的手卻穩得不像生意人，只朝你點了下頭，彷彿你早來過千百回。靠窗一個老劍客橫劍枯坐，眼神空得在等人；角落兩個商旅交頭接耳，壓著嗓子說某條商路被截了。",
				"choices": [
					{
						"id": "hot_soup",
						"label": "卸下行囊，要一碗熱湯",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "heal", "amount": 16}],
							"log": "掌櫃端來一碗熱湯，不問緣由。喝完，渾身疲憊輕了大半——有時候，不問緣由的善意，是最好的藥。",
						},
					},
					{
						"id": "toast_swordsman",
						"label": "敬老劍客一壺酒，求教劍術",
						"kind_hint": "mixed",
						"requires": {"min_gold": 10},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gold", "amount": -10},
								{"kind": "upgrade_random"},
							],
							"log": "你買酒敬那老人。他放下杯子，用兩指在桌上比劃了一個劍式——你手中某道招式，從此不同了。一壺酒，換一句點撥，值。",
						},
					},
					{
						"id": "buy_rumor",
						"label": "湊近商旅打聽路上消息",
						"kind_hint": "gamble",
						"hide_badge": true,
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.6,
								"win_effects": [
									{"kind": "gold", "amount": 18},
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 6}]},
								],
								"lose_effects": [
									{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
									{"kind": "set_flag", "flag": "marked_by_bandits"},
								],
							},
							"log": "你壓低聲音問起那條被截的商路。話題很有用——但鄰桌一個耳朵，也悄悄轉向了你。",
						},
					},
					{
						"id": "lin_family_name",
						"label": "（林月如）向老劍客報上林家堡家門",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "upgrade_random"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "「林家堡？你父親林天南是我師侄。」老人笑了，「他當年那一招，我替他改過。」他俯身把那一改傳給了月如——是長輩對晚輩，不必言謝的那種給予。",
						},
					},
					{
						"id": "fox_repays",
						"label": "角落那個眼熟的少女向你走來",
						"kind_hint": "reward",
						"requires": {"event_flag": "fox_spared", "not_event_flag": "fox_repaid"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 10},
								{"kind": "gain_potion"},
								{"kind": "set_flag", "flag": "fox_repaid"},
							],
							"log": "一個眼熟的少女在你桌邊坐下——金色的瞳孔，是隱龍窟裡你放走的那隻狐。「我說過會還這份情。」她推來一壺溫好的酒和一包妖丹，又悄悄沒入人群。江湖很大，善意卻記得回來。",
						},
					},
					{
						"id": "read_room",
						"label": "盯著掌櫃那雙太穩的手看",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_keeper",
					},
					{
						"id": "leave",
						"label": "把錢壓在桌上，喝完便走",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你把幾文錢壓在杯底，起身推門。掌櫃仍只是點了下頭，像送別一個明天還會回來的人。酒館的暖意留在背後，路還很長。"},
					},
				],
			},
			"nodes": {
				"node_keeper": {
					"prompt": "你越看越肯定：那擦杯的手腕翻轉，根本是握過刀的人才有的穩。掌櫃終於抬眼，目光在你臉上停了一瞬——這酒館哪是尋常生意，是哪個門派埋在江湖裡的暗樁。他不問你，只等你先開口；報得出暗記，這碗湯就不只是湯。",
					"choices": [
						{
							"id": "give_sign",
							"label": "賭一把，比出半懂的暗記",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.5,
									"win_effects": [
										{"kind": "gain_relic_pool", "pool": "uncommon"},
										{"kind": "heal", "amount": 6},
									],
									"lose_effects": [
										{"kind": "gold", "amount": -8},
									],
								},
								"log": "你比了個半懂不懂的手勢。掌櫃擦杯的手停了一停，眼神往你手指上一掃——這一瞬，他在心裡認你、還是把你當成了找錯門的外人？",
							},
						},
						{
							"id": "stay_quiet",
							"label": "看破不說破，安靜喝湯",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gold", "amount": 8},
									{"kind": "heal", "amount": 4},
								],
								"log": "你什麼都沒問，喝完湯結帳。掌櫃多找了你幾文錢，算是謝你的識趣。",
							},
						},
					],
				},
			},
		},
	},
	"sword_tomb": {
		"title": "劍冢英靈",
		"flavor": "枯草間插著無數斷劍，每一把都指向同一個方向。刀氣猶在，卻沒有殺意——像是守護，而非威脅。",
		"character_flavors": {
			"li_xiaoyao": "逍遙在劍冢裡走得很慢，腳步放輕了，不敢打擾那些沉默的斷劍。這些劍都指著同一個方向，像是還在守護著什麼。他伸出手，在距離某柄斷劍幾寸的地方停下——感到了一種說不清楚的沉重，像是有人握著他的手，不讓他碰。",
			"zhao_linger": "靈兒走在劍冢裡，感到那些英靈的視線在她背上集中。不是惡意，是守護——但她仍不由自主地挺直了背、放輕了步伐，像是不想在那些人面前失禮。她雙手合十行禮，低聲說：「你們的心意，我感受到了。」走出劍冢時，她才發現自己一直沒有呼出那口氣，現在才慢慢吐出來。",
			"lin_yueru": "月如在劍冢中站立，感到了一種久違的、只有在真正的劍者之間才存在的共鳴。這些斷劍的主人，曾經也是像她一樣持劍而行的人；他們最後選擇把劍插在這裡，而不是帶走——那是一種怎樣的心情？她彎腰，認真地看著每一把劍。",
			"anu": "阿奴不太懂得劍的意義，但她懂得守護。苗疆的女巫也有她們自己的守護之物，埋在土地裡，代代相傳。她走在劍冢中，感受那些刀氣的質地——不是殺氣，是護持之意，和蠱術中「守護之蠱」的氣息有幾分相似，讓她意外地感到了一種親近感。",
		},
		"heal": 0, "gain_cost": 6, "power": 3, "power_label": "承志",
		"observe_text": "你仔細看那些斷劍。它們插的方向並非雜亂——劍尖全部指向北方某個遙遠的點，那是中原劍道的源頭之一。每一把劍上都刻著名字，有的姓氏你認得，有的已經風化模糊。最讓你動容的是其中一柄劍鞘上刻著「未竟」二字，像是劍主臨終前最後的心意——他知道自己走不到，但希望後人能替他走完。",
		"observe_effects": [{"kind": "power", "amount": 2}],
		"choices": ["power", "upgrade", "gain_card", "observe", "leave"],
		"character_outcomes": {
			"lin_yueru": {
				"gain_card": "月如蹲在劍冢中央，仔細看著那些斷劍上的姓氏——她認出了好幾個，是林家堡歷代的遺名。父親林天南曾對她說：「劍冢不是墓，是接力的起點。」她在父親提過的那柄劍前跪下，雙手取劍——一道前輩留下的劍意化作劍譜流入她的心中，那是只有林家堡弟子才能接收到的傳承。"
			}
		},
		"outcomes": {
			"power": "你在劍冢間站立片刻。那些英靈的殺伐意志悄悄從劍身傳入，填滿了你招式裡每一個空隙——那是別人用一生走出來的，此刻，傳到你的手上。",
			"upgrade": "某柄斷劍的裂縫上刻著一段心法，如同那位劍客最後的遺言。你用它修正了自己招式中的瑕疵，同時也想起了那個人，最後獨自插劍於此的模樣。",
			"gain_card": "你從劍冢拔出一柄斷劍，指尖傳來一套陌生的劍法輪廓，隨即融入了你的招式記憶。那劍冢因此少了一把劍，你希望它原來的主人，不會介意。"
		},
		"tree": {
			"root": {
				"prompt": "風過枯草，無數斷劍從土裡斜插而出，發出極輕的嗡鳴。劍尖竟齊齊指向北方——將軍塚的方向，中原劍道的源頭。刀氣猶在，卻不見半分殺意，只像一群還沒走完路的人，把劍立在這裡，朝著去不成的遠方守望。冢的最深處，一柄鞘上刻著「未竟」二字的斷劍，比其餘的劍嗡鳴得更急。",
				"choices": [
					{
						"id": "pray",
						"label": "垂手默立，向滿冢英靈致意",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 6},
							],
							"log": "你在劍冢間默立良久。千百道沉默的意志順著劍身滲入，不多不少，剛好填滿你招式裡的一道空隙。它們沒有挽留你，也沒有囑託——有些路，本就只能各走各的。",
						},
					},
					{
						"id": "seek_unfinished",
						"label": "走向那柄嗡鳴不止的「未竟」之劍",
						"kind_hint": "neutral",
						"next": "node_unfinished",
					},
					{
						"id": "leave",
						"label": "抱拳一禮，不取分毫而去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向滿冢斷劍抱拳一禮，一把也沒碰。走出枯草地時，那片嗡鳴漸漸低了下去，像在點頭——它們守望的方向，終究不是你的方向。"},
					},
				],
			},
			"nodes": {
				"node_unfinished": {
					"prompt": "你撥開枯草蹲下。劍鞘上只刻了兩字：「未竟」，筆畫深得像用盡最後一口氣鑿進去的。你伸手才及劍柄，半空忽然凝起一道半透明的劍影——是這滿冢劍意所聚的劍靈，橫劍擋在你與那柄斷劍之間，無聲卻分明地宣告：想接他未竟的志，先證明你接得起。",
					"choices": [
						{
							"id": "accept_trial",
							"label": "拔劍應戰，向劍靈證明你配得上",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "trial_swordshade",
									"enemy_hp_mult": 1.0,
									"victory_effects": [
										{"kind": "set_flag", "flag": "tomb_trial_passed"},
										{"kind": "heal", "amount": 6},
									],
									"defeat_effects": [
										{"kind": "permanent_power", "amount": -1},
									],
									"next_on_victory": "node_inheritance",
								},
								"log": "你不退反進，拔劍迎上那道劍影。劍靈似乎笑了——它要的本就是這一步。冢中千百柄斷劍同時嗡鳴，為這一場試煉作證。",
							},
						},
						{
							"id": "take_scabbard_jade",
							"label": "避開劍影，只摳走鞘上那塊玉飾",
							"kind_hint": "mixed",
							"hide_badge": true,
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "permanent_power", "amount": -1},
								],
								"log": "你側身讓過劍影，伸指摳下劍鞘上那塊玉飾揣進懷裡。劍靈沒有追擊，只是緩緩散去——它認得貪心，也記得貪心的人。玉飾入手冰涼，你卻莫名不敢回頭。",
							},
						},
						{
							"id": "bow_out",
							"label": "自知火候未到，鄭重一禮退開",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 8},
								],
								"log": "你收手，退後一步，向劍靈與那柄斷劍鄭重一禮。劍影微微側鋒，算是還禮。知進退，本也是劍者的一課——你帶著這份清明離開，心境沉靜了幾分。",
							},
						},
					],
				},
				"node_inheritance": {
					"prompt": "劍靈的鋒芒一寸寸斂去，化作一縷暖光融入「未竟」之劍。它認可了你。那柄斷劍的嗡鳴轉為溫潤，鞘上「未竟」二字微微發亮——百年前那位劍主沒能走完的路，此刻正把它的全部，朝你敞開。",
					"choices": [
						{
							"id": "carry_on",
							"label": "握劍立誓：「我替你走完。」",
							"kind_hint": "reward",
							"requires": {"event_flag": "tomb_trial_passed"},
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "character"},
									{"kind": "max_hp", "amount": 4},
									{"kind": "permanent_power", "amount": 2},
								],
								"log": "你握緊那柄「未竟」之劍，輕聲應了一句：「我替你走。」劍身一震，像是卸下了百年的重，把畢生的劍法與那未竟的執念，盡數托付給了你。從今往後，你的劍裡多了一個人的份量。",
							},
						},
						{
							"id": "lin_inherit",
							"label": "（林月如）認出這是林家堡遺劍，跪取家傳",
							"kind_hint": "reward",
							"requires": {"character": ["lin_yueru"], "event_flag": "tomb_trial_passed", "not_event_flag": "lin_tomb_heir"},
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "character"},
									{"kind": "permanent_power", "amount": 3},
									{"kind": "set_flag", "flag": "lin_tomb_heir"},
								],
								"log": "通過試煉的剎那，月如才看清「未竟」鞘上那行小字——是林家堡某位早逝的先輩。父親林天南說過：「劍冢不是墓，是接力的起點。」她紅著眼跪下取劍，一道只有林家堡血脈能承的劍意奔流入心。這一回，換她替他走完。",
							},
						},
					],
				},
			},
		},
	},
	"miao_healer": {
		"title": "苗疆藥師",
		"flavor": "草棚內藥材懸掛成排，一位苗疆老藥師坐在角落，目光精準地在你身上掃了一圈，未言先知。",
		"character_flavors": {
			"li_xiaoyao": "逍遙看見那一排排懸掛的藥材，鬆了一口氣——有藥師，意味著有得救的機會。老藥師打量他的方式讓他想起了外婆看診時的神情，眼神銳利，但帶著一種不動聲色的善意。「前輩，我身上有幾處舊傷，比較麻煩的那種。」他覺得直接說最好。",
			"zhao_linger": "老藥師不說話，只是抬手示意靈兒伸腕。他的指尖冷而準確，按上她的脈搏就不動了，靜靜地讀。靈兒坐著，看著那雙滿是藥材染色的老手握著自己細白的手腕，想說什麼，卻忍住了。她的脈動是真實的，她的血在他指下流著，這讓她覺得有些暴露，又說不清為什麼反而覺得安心。",
			"lin_yueru": "月如進了草棚，打量了老藥師一眼——藥材的排列有條有理，配伍邏輯清晰，是正統的藥理，不是旁門左道。林家堡的弟子也學過基礎藥理；她決定信任這位老藥師，把身上幾處沒有處理好的舊傷一一列出，語氣像是向師傅匯報功課。",
			"anu": "阿奴一走進草棚，就覺得熟悉——那些藥材的氣味，有一半以上是苗疆的。她看向老藥師，帶著一絲意外：中原的藥師，為什麼會有這麼多苗疆草藥？老藥師好像感應到了她的疑惑，用緩慢的苗語說了一個詞——是苗疆用來稱呼旅者的詞，意思是「走遠的人」。",
		},
		"heal": 12, "gain_cost": 5, "power": 1, "power_label": "疏脈",
		"observe_text": "你打量草棚的擺設。藥材分成兩堆：靠門口那一排是常見中草藥，按照中原藥理的「君臣佐使」排列；靠角落那一排卻是苗疆草藥，按照南疆「五行相生」的方式擺放——這位老藥師同時精通兩派藥理。牆角還掛著一個褪色的布包，上面繡著南疆某個小村的圖騰，估計他年輕時曾在那裡學藝多年。",
		"observe_effects": [{"kind": "gain_potion"}, {"kind": "heal", "amount": 4}],
		"choices": ["heal", "remove", "power", "observe", "leave"],
		"character_outcomes": {
			"anu": {
				"heal": "阿奴用苗語向老藥師低聲說了一個地名——那是她出生的村落。老藥師抬頭看了她一眼，眼神有了微妙的變化，輕輕地點了點頭。他取出了一個塵封的小木盒，裡面是一顆苗疆才有的「歸鄉丹」。「這是當年你們村的老巫師交給我的，說有一天會有同鄉的孩子路過。」阿奴接過藥丸，喉嚨有些緊，但她沒有哭——她只是深深地行了一個苗疆的大禮。"
			}
		},
		"outcomes": {
			"heal": "藥師不說廢話，只是遞上一帖藥——入口苦，但熱意從丹田蔓延，傷口比預期癒合得更快。你把空藥包放下，覺得那個沉默的老人，其實是個很溫暖的人。",
			"remove": "藥師看著你的手，指出了某道招式中的根本問題，然後讓你親手將它燒掉。你看著那頁功法化為灰燼，心裡有一點捨不得，但也有一點，像是終於放下了什麼。",
			"power": "藥師以針法疏通了你的幾處穴道，濁氣散盡，招式的流轉比過去順了幾分。離開草棚時，你覺得自己的每一個動作，都比進來之前更流暢了，像是什麼東西鬆開了。"
		},
		"tree": {
			"root": {
				"prompt": "推開草簾，滿棚藥香撲面，苦裡裹著一絲南疆才有的辛甜。一排排藥材懸成簾幕，角落坐著個苗疆老藥師，眼皮也沒抬，指尖卻已點了點你站立的方向——「左肩的舊傷，陰雨天疼吧。」他先你一步把話說了，像早等著你來。",
				"choices": [
					{
						"id": "treat",
						"label": "伸出手腕，請他診那道舊傷",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "heal", "amount": 14}],
							"log": "藥師不說廢話，遞上一帖藥。入口苦，熱意卻從丹田蔓延，傷口癒合得比預期快。",
						},
					},
					{
						"id": "buy_battle_pill",
						"label": "掏出銅錢，求一帖臨陣救命藥",
						"kind_hint": "mixed",
						"requires": {"min_gold": 12, "has_potion_slot": true},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gold", "amount": -12},
								{"kind": "gain_potion"},
							],
							"log": "藥師取來幾味草藥，當著你的面研磨封瓶。「臨陣再服。」他把藥瓶推給你，收下銅錢，神色淡淡。",
						},
					},
					{
						"id": "acupuncture_purge",
						"label": "求他下針，挑掉一道礙根的招",
						"kind_hint": "reward",
						"requires": {"min_deck_size": 7},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "lose_card", "mode": "random"},
								{"kind": "heal", "amount": 6},
							],
							"log": "藥師指出你某道招式「有礙根基」，讓你親手把它燒了。看著功法化灰，心裡捨不得，卻也輕了。",
						},
					},
					{
						"id": "anu_kin",
						"label": "（阿奴）以苗語報出家鄉村名",
						"kind_hint": "reward",
						"requires": {"character": ["anu"], "not_event_flag": "miao_kin"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 10},
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "set_flag", "flag": "miao_kin"},
							],
							"log": "阿奴低聲報出出生的村落。老藥師眼神一變，取出塵封的木盒：「當年你們村的老巫師交給我的，說會有同鄉的孩子路過。」她深深行了一個苗疆大禮。",
						},
					},
					{
						"id": "inspect_shelves",
						"label": "留意那兩排擺法迥異的藥材",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_shelves",
					},
					{
						"id": "leave",
						"label": "拱手謝過，不勞他費神",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向老藥師拱手謝過，退出草棚。他只在你身後淡淡丟了句：「左肩，記得避寒。」藥香黏在衣袖上，跟了你一路。"},
					},
				],
			},
			"nodes": {
				"node_shelves": {
					"prompt": "你順著藥架看過去，越看越不對：靠門那排按中原「君臣佐使」分得規整，靠角落那排卻是苗疆「五行相生」的擺法，兩派藥理同居一棚。角落還掛著個褪色舊布包，繡的是南疆某個小村的圖騰——這老人年輕時，分明在苗疆待過很久。",
					"choices": [
						{
							"id": "learn_pharmacology",
							"label": "執弟子禮，請他講透兩派藥理",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 4},
									{"kind": "heal", "amount": 4},
								],
								"log": "老藥師難得多話，把兩派調理之道講了大半個時辰。你記下的不只是藥方，還有一副更耐操的身子。",
							},
						},
						{
							"id": "steal_herb",
							"label": "趁他轉身，伸手摸走那味稀藥",
							"kind_hint": "gamble",
							"hide_badge": true,
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.5,
									"win_effects": [
										{"kind": "gain_potion"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 6},
										{"kind": "set_flag", "flag": "healer_grudge"},
									],
								},
								"log": "你的手探向那味掛在最高處的稀藥，指尖剛勾住繩結——老藥師背對著你研藥的手，停了，又動了。他究竟是真沒瞧見，還是早把後路都算進了藥方裡？",
							},
						},
					],
				},
			},
		},
	},
	"shilipo_sword_god": {
		"title": "十里坡劍神",
		"flavor": "一名少年正不厭其煩地對著空氣揮舞木劍，身形顯稚嫩，意氣卻出奇地專注。「只要練上一萬次，就算是蜂王也打得倒！」他擦了擦汗，向你請教劍術的關隘。",
		"character_flavors": {
			"li_xiaoyao": "逍遙一眼認出了那股傻勁——對一件事反覆練習、不管多難都不放棄的傻勁，他在鏡子裡也見過。少年揮出木劍的姿勢很糟糕，但氣勢出奇地認真，讓逍遙不由得想起了自己剛學御劍術時的樣子，那時候他也覺得只要夠拼就能打倒一切。",
			"zhao_linger": "靈兒走上前，輕聲說：「你的方向是對的，我看著你。」少年猛地一僵，木劍差點掉了，轉過頭來，臉已經紅到了耳根。那種紅讓靈兒想笑，她沒有克制，就笑了出來，溫柔而真誠。少年更紅了，連說話都斷斷續續。她故意沒有移開視線，因為這種讓人局促的感覺有些奇特，帶著一點小小的愉悅。",
			"lin_yueru": "月如在一旁看了少年揮了幾下劍，很快就看出問題所在：腕力不穩，重心太高，起手式有個根本性的錯誤。她走上前，沒有廢話，直接說：「你的第一式錯了，讓我示範。」少年一臉不服氣，但還是把木劍收了回來，靜靜地聽。",
			"anu": "阿奴在一旁站著，看著那個少年一遍一遍地揮劍。她不懂劍術，但她懂得重複——在苗疆，學蠱術的孩子要把每一個手訣練上幾千遍，才能在需要的時候讓身體自動反應。這個少年在做的事，和她當年學蠱術沒有什麼本質上的不同。",
		},
		"heal": 0, "gain_cost": 6, "power": 2, "power_label": "共鳴",
		"observe_text": "你從遠處靜靜看了片刻。少年揮劍時呼吸短促、腕力不穩，但每一劍下落的軌跡都很穩定——這不是天賦，這是反覆練到刻進骨頭的執著。你想起一句話：「劍仙不問師承，問人是否肯死磕。」這個少年值得指點。",
		"observe_effects": [{"kind": "power", "amount": 1}, {"kind": "heal", "amount": 2}],
		"choices": ["upgrade", "power", "remove", "gain_card", "observe", "leave"],
		"choice_filters": {
			"gain_card": {"if_character": ["lin_yueru"]}
		},
		"outcomes": {
			"upgrade": "你指點了少年的木劍姿勢。見你如此傾囊相授，少年的純真劍意反倒啟發了你——手中某個招式的瑕疵盡除。有時候，最好的老師，是一個問出了你從未想過的問題的學生。",
			"power": "你與少年一同切磋。木劍相交的清脆聲中，那股對劍道最純粹的執著感染了你，體內氣息更添英銳之氣。走時，少年向你揮手，你揮了揮手，覺得今天是個好日子。",
			"remove": "少年看著你的劍招，天真地問：『大俠，你這招是不是有點多餘？』一語驚醒夢中人。你靜心內省，斬斷了招式中累贅的旁枝末節——能說出這句話的人，才是真正看見了的人。",
			"gain_card": "月如以林家堡大小姐的身份正式教導少年起手式。少年眼神發亮，把每一個動作都看入眼裡。臨別時，他鞠了個深躬，從懷中取出一卷家傳的劍譜殘頁回贈：「這是我祖父留下的，但他說我練不來這一招。大姐姐，你應該用得上。」她接過殘頁，意外地從中讀出了一道新的劍意。"
		},
		"tree": {
			"root": {
				"prompt": "蟬聲鋪滿整條山道，木劍破風的「咻、咻」聲卻一下一下蓋過了它。十里坡的烈日下，一名少年汗濕了半邊衣裳，仍對著空氣一劍接一劍地劈，姿勢笨拙得像在趕蒼蠅。見你停步，他咧嘴一笑，把劍往肩上一扛：「大俠你瞧好了——只要練上一萬次，就算是蜂王，我也照打不誤！」",
				"choices": [
					{
						"id": "spar",
						"label": "捲起袖子，陪他過三十招",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "power", "amount": 1},
								{"kind": "heal", "amount": 3},
							],
							"log": "木劍對木劍，清脆的「篤、篤」在山道上彈來彈去。少年招招漏洞，卻招招拼命，三十招下來臉漲得通紅還不肯停。你忽然在他汗淋淋的眼神裡，看見了自己出師前那個對著草靶傻練的下午。「再來一趟！」他喊。你笑著應了。",
						},
					},
					{
						"id": "fix_form",
						"label": "按住他的腕，糾正起手式",
						"kind_hint": "reward",
						"next": "node_teach",
					},
					{
						"id": "naive_question",
						"label": "蹲下來，聽他天真地發問",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "upgrade_random"},
							],
							"log": "「大俠，你這招繞那麼大一圈，是不是有點多餘呀？」少年眨著眼，問得理所當然。你張口想駁，話到嘴邊卻噎住了——他說對了。蟬聲裡你愣了好一會兒，某道練了多年、自以為精妙的招式，從這個午後起，再無一絲冗餘。",
						},
					},
					{
						"id": "observe_grit",
						"label": "退開幾步，看他每一劍的軌跡",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 5},
							],
							"log": "你退到樹蔭裡，靜靜看了一炷香。少年呼吸越來越短，腕力一抖一抖，可每一劍落下的那道弧線卻穩得分毫不差——這不是天分，是把同一個動作練到刻進骨頭裡的笨功夫。你心頭一震：劍仙從不問師承，只問你肯不肯死磕。看著看著，自己那把劍也沉了下來。",
						},
					},
					{
						"id": "lin_teach",
						"label": "（林月如）擺出大小姐架勢，正經傳藝",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "rare"},
								{"kind": "heal", "amount": 5},
							],
							"log": "「林家堡的起手式，看好了，只示範一次。」月如劍鋒一抖，整套架勢行雲流水，少年看得眼都不眨。臨別，他從懷裡掏出一卷發黃的劍譜殘頁，雙手奉上：「祖父說我這輩子練不來這招……大姐姐，您用得上。」她接過殘頁，指尖一觸那墨痕，當夜便讀出了一道從未見過的劍意。",
						},
					},
					{
						"id": "ten_thousand_drill",
						"label": "陪他練到天亮，一劍不停",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "permanent_power", "amount": 3},
								{"kind": "damage", "amount": 8},
								{"kind": "max_hp", "amount": -3},
							],
							"log": "日頭落了又升，木劍揮到指縫滲血、虎口開裂。少年牙關咬得發白，你也咬到發白——誰都不肯先停手。晨光鋪上山道時，兩人喉頭一甜，各自嘔了口血，那道劍意卻在這一夜裡，硬生生刻進了骨頭。他撐著膝蓋朝你拜了三拜：「大俠，我懂了。」你扶著樹幹，半晌才直起腰。",
						},
					},
					{
						"id": "leave",
						"label": "拍拍他的肩，含笑作別",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你拍了拍他汗濕的肩，拱手轉身。山道走出老遠，那「咻、咻」的揮劍聲還一下一下地追著你，比蟬鳴清楚，比山風執拗。你沒回頭，只是嘴角揚了揚——十里坡上，又多了一個不肯認輸的傻子。"},
					},
				],
			},
			"nodes": {
				"node_teach": {
					"prompt": "你一按他的手腕，少年立刻僵住，乖乖把木劍收回胸前，眼睛瞪得圓圓的，連呼吸都放輕了，生怕漏聽一個字。陽光透過樹葉灑在他臉上，那神情你太熟悉了——是肯把一切都信進去的年紀。",
					"choices": [
						{
							"id": "teach_basics",
							"label": "從怎麼握劍，一步步教起",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "power", "amount": 2},
									{"kind": "gold", "amount": 10},
								],
								"log": "握劍、立樁、起手、出鞘——你一招一招拆開了教，少年認真得連蚊子叮在脖子上都不敢拍。教到天邊燒起晚霞，他忽然從懷裡摸出僅有的幾枚銅板，紅著臉硬塞進你手裡：「這是拜師費！」你本想推辭，看他那倔樣，到底沒推。收下了，比收什麼都重。",
							},
						},
						{
							"id": "teach_heart",
							"label": "跟他說說「劍意」這回事",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "max_hp", "amount": -2},
								],
								"log": "你說了一段連自己都只半懂的話——劍意、初心，還有「練劍練到最後，練的其實是自己」。少年似懂非懂地點著頭。話一出口，你心口卻空了一塊，像把壓箱的東西交了出去。直到走在歸途的暮色裡，你才驀地明白：方才那番話，原來是說給當年的自己聽的。",
							},
						},
					],
				},
			},
		},
	},
	"drunk_swordsman": {
		"title": "醉臥劍仙",
		"flavor": "石階旁躺著一名渾身酒氣的邋遢道士，腰間橫著個斑駁的朱漆葫蘆，正半醉半醒地嘟囔著：「酒……給我酒……沒有好酒，渾身沒勁……」",
		"character_flavors": {
			"li_xiaoyao": "逍遙在道士身旁停下，嗅了嗅那股酒氣——是好酒，比他在餘杭客棧裡喝過的大多數都濃，帶著一種玄妙的底味，像是歲月沉澱出來的，而不只是單純的釀造。「前輩，」他蹲下去，「你手裡那個葫蘆……是什麼酒？」他覺得這是最重要的問題。",
			"zhao_linger": "靈兒蹲下來，湊近了些。道士半睜開一隻眼，打量了她片刻，嘴裡含含糊糊地說了幾個字。靈兒沒聽清，再靠近一點——「好看……」他說，然後又閉上了眼。靈兒愣了一下，緩緩站起身，沒料到這一句，胸口有什麼東西跳了一下，說不清是被看見的意外，還是別的什麼，只是在原地站了片刻，才繼續往前走。",
			"lin_yueru": "月如看著道士，心裡有些不以為然——她從小被訓練保持清醒，對沉迷酒色的修道者沒有好感。但當她靠近時，那股酒氣中隱隱透出的劍意讓她愣了一下：那是真正的劍道，不是表演，是刻在靈魂深處的東西，哪怕醉了也藏不住。",
			"anu": "阿奴蹲在道士身旁，聞了聞那個葫蘆的氣味。酒裡有藥，不是毒，是某種南方的靈草配伍，讓這個酒能讓人暫時不怕痛——她認識這個配方，苗疆的某些老巫師也用過類似的法子。她沒有說話，只是把這件事記在心裡，繼續打量這個奇怪的道士。",
		},
		"heal": 8, "gain_cost": 5, "power": 3, "power_label": "共飲", "taint_damage": 6,
		"observe_text": "你蹲在道士身旁，仔細嗅了嗅葫蘆的氣味。酒色澤深而帶金，藥味隱於酒香之後——是用蜀地野山楂與南方靈草釀製的丹方，連葫蘆口的木塞都用上了千年陳年桑木。道士懷裡那把劍刻著古樸劍紋，劍鞘磨損的方向只有真正以劍為生的人才會有。這位邋遢道人絕非普通酒鬼。",
		"observe_effects": [{"kind": "heal", "amount": 8}, {"kind": "gold", "amount": 3}],
		"choices": ["approach", "observe", "leave"],
		"branch_labels": {
			"approach": ["上前攀談", "與這位醉漢直接交談"]
		},
		"sub_choices": {
			"approach": ["tainted_power", "heal", "gain_card"]
		},
		"sub_flavors": {
			"approach": "你蹲下身，與道士對話。他似醉非醉，半睜著眼端詳你，眼神比想像中清明。「先說好，老子的酒不是隨便人都能喝的。要試試？還是只想旁聽幾句？」他舉起葫蘆對你晃了晃，朱漆斑駁的瓶身上倒映著火光。"
		},
		"character_outcomes": {
			"li_xiaoyao": {
				"tainted_power": "「來，這口給你嚐。」道士遞過葫蘆。逍遙仰頭就灌——他從小在外婆的客棧長大，酒量本不弱，但這酒像活的，下喉嚨的瞬間就在體內燒起來。他咳了三聲，眼淚都被嗆出來，再睜眼時，看見道士笑得露出兩顆缺牙：「小子，你體內這口劍仙之氣可以煉，但你得先學會醉。」逍遙抹了抹嘴角的血，搶過葫蘆再喝一口：「來啊。」"
			}
		},
		"outcomes": {
			"tainted_power": "你搶過葫蘆灌了一口，喉嚨如烈火灼燒，忍不住劇烈咳嗽，生機受損——但一股狂亂難抑的酒意在體內橫衝直撞，出招更添三分狂氣。那感覺讓你有點明白，為什麼這個道士寧願一直醉著。",
			"heal": "你退在一旁，看他醉語。清冽的酒香混著松針味，竟讓你的心跳平復，體內的隱疾在平穩的呼吸中有些許好轉。有時候，最好的藥，不是藥，是旁觀別人的放肆。",
			"gain_card": "你趁他半醉，遞去一壺清茶。他砸砸嘴，醉醺醺地吐出幾句玄妙的口訣，一道新招式在你心頭成型。為此你熬神耗思，氣血翻湧——但那幾句話，值得。"
		},
		"tree": {
			"root": {
				"prompt": "未見其人，先撲來一股酒氣，沖得人眼睛發酸。石階上仰躺著個邋遢道士，鬚髮糾結，腰間橫著只磨得發白的朱漆葫蘆。他閉著眼，喉間咕噥得含混：「酒……給我酒……沒好酒，這身骨頭就提不起勁……」袍角下，一柄古劍若隱若現，劍鞘的磨損偏向一處，像被同一個動作摩挲了千百遍。",
				"choices": [
					{
						"id": "share_drink",
						"label": "二話不說，搶過葫蘆灌一口",
						"kind_hint": "mixed",
						"next": "node_drink",
					},
					{
						"id": "offer_tea",
						"label": "遞上一壺熱茶，陪他坐坐",
						"kind_hint": "reward",
						"requires": {"min_gold": 10},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "uncommon"},
								{"kind": "gold", "amount": -10},
							],
							"log": "你蹲下身，把方才在鎮上沽的熱茶遞過去。他眯著眼端詳你半晌，接過抿了一口，砸砸嘴：「茶？也罷，醉裡偷個醒。」醉醺醺地，他竟順口吐出一段抑揚頓挫的口訣。你闔眼凝神聽著，那幾句像有重量，一字一字落進心裡，一道招式便悄然成形。",
						},
					},
					{
						"id": "watch_silent",
						"label": "什麼也不說，挨著他坐下",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 8},
								{"kind": "max_hp", "amount": 1},
							],
							"log": "你在他身旁靜靜坐了一炷香。山風送來松針的清苦，混進那縷醇厚酒香裡。他時而囈語，時而沒來由地笑出聲，活得肆意又坦蕩。看著看著，你的呼吸竟也跟著平了下來，鬱在胸口多日的悶氣，不知何時散了。原來世上最好的藥，是看一個人活得這樣不管不顧。",
						},
					},
					{
						"id": "observe_master",
						"label": "瞇眼細看他袍下那柄古劍",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_recognize",
					},
					{
						"id": "lxy_kindred",
						"label": "（李逍遙）越看越眼熟，索性湊近端詳",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "逍遙蹲下來盯著看了半天——這副邋遢眉眼、這身洗不掉的酒癮、這只磨白的破葫蘆，越看越像餘杭城外那個傳說裡「醉裡藏劍」的怪道人。他心口莫名一熱，正要開口，道士忽地睜眼，渾濁的眼底竟有一線寒光一閃即逝，旋即笑得豁了牙：「臭小子，老子等的就是你這張臉。」他仰頭灌酒，順手在逍遙肩上一拍，一段御劍口訣便如醉話般落進耳裡。逍遙怔住——這聲「等你」，他往後會記很久。",
						},
					},
					{
						"id": "sword_offer",
						"label": "默運一身劍意，請他掌掌眼",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["attack"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "upgrade_random"},
							],
							"log": "你不發一語，緩緩將滿身劍意凝於指尖。一直裝醉的道士眼皮忽然一掀，那點朦朧渾濁瞬間褪盡，露出深不見底的清明：「唔，有點意思。」他懶洋洋地伸出兩指，在你劍脊上「叮、叮、叮」彈了三下——輕得像撥弄琴弦，可你連日苦練都沒察覺的三處破綻，竟應聲消散。指尖收回時，他又闔上眼打起鼾，彷彿方才那一瞬從未存在。",
						},
					},
					{
						"id": "leave",
						"label": "拱手致意，繞過他趕路",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你拱了拱手，繞過那攤酒氣繼續上路。身後悠悠飄來幾句含混的醉語，尾音卻押著奇妙的節律，像是某套劍訣的口訣，又像只是醉漢的胡話。你沒回頭——有些緣分，錯過了，便是錯過了。"},
					},
				],
			},
			"nodes": {
				"node_drink": {
					"prompt": "葫蘆一傾，那酒像一條燒紅的鐵線直墜喉底，五臟六腑霎時燃了起來，你嗆得眼淚奪眶。道士聞聲半睜開眼，像撿了個寶似的笑開：「好個不要命的！小子，你這口劍仙之氣是塊好料，可以煉——但要煉它，你得先學會醉。醉了，劍才活。」",
					"choices": [
						{
							"id": "drink_more",
							"label": "抹掉嘴角的血，再灌一口",
							"kind_hint": "punish",
							"outcome": {
								"kind": "punish",
								"effects": [
									{"kind": "damage", "amount": 6},
									{"kind": "permanent_power", "amount": 3},
									{"kind": "gain_curse", "curse_id": "jiu_zui"},
								],
								"log": "你拿手背抹掉嘴角的血，仰頭又是一口。酒意在經脈裡橫衝直撞，劍意被攪得一同狂奔，整個人飄得幾乎要御風而起。道士在旁拍腿大笑：「對嘍，這才像話！」這份力量是真的——可那勾住喉嚨、再也放不下葫蘆的渴，也是真的。",
							},
						},
						{
							"id": "pace_self",
							"label": "閉眼按住，引酒意緩走經脈",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "heal", "amount": 5},
								],
								"log": "你闔上眼，沉住氣，引那股狂亂酒意順著經脈一寸寸緩行，不貪多，不冒進。道士斜眼看著，難得地沒插科打諢，只在你睜眼時，極輕地點了點頭：「曉得收，才走得遠。」這一點頭，比一葫蘆酒還受用。",
							},
						},
					],
				},
				"node_recognize": {
					"prompt": "你俯身細看——那柄長劍鏽跡斑斑，劍身卻刻著一道道古樸劍紋，劍鞘只在出鞘的方向磨得發亮，那是真正以劍為命的人才會留下的痕。你心頭一凜，想起江湖盛傳的酒劍仙：他從不收徒，只在醉中替「有緣人」點上一筆，而那一筆，往往勝過旁人十年苦修。",
					"choices": [
						{
							"id": "kneel_request",
							"label": "撩袍深揖，懇請賜教一招",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你撩袍跪地，深深一揖：「前輩，請賜教。」道士噗哧笑出聲，搖搖晃晃站起身，醉態可掬地隨手比劃了一式。那劍勢看似東倒西歪、毫無章法，落在你眼裡卻字字千鈞——一招之間，藏著他半生的劍道。你看在眼裡，刻進心裡，勝過讀爛十本劍譜。他收勢又一屁股坐回石階：「夠了，多了你也接不住。」",
							},
						},
						{
							"id": "steal_glance",
							"label": "悄悄默記那道劍意便走",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.45,
									"win_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 10},
										{"kind": "gain_curse", "curse_id": "jiu_zui"},
									],
								},
								"log": "你不驚動他，只把全副心神鎖在那柄古劍的紋路上，想憑記性偷下這份劍意。指尖剛要描摹，道士的眼倏地睜開，醉意盡褪，那一瞥比出鞘的劍還要冷利：「偷學，也得看你接不接得住。」話音未落，一股無形劍氣已壓上你的眉心。",
							},
						},
					],
				},
			},
		},
	},
	"yinlong_cave": {
		"title": "隱龍窟幽怨",
		"flavor": "陰森的洞窟深處，隱約傳來女子幽怨的低泣。走近一看，一名狐面半人身的少女正縮在角落，瑟瑟發抖，懇求你不要傷害她的族民。",
		"character_flavors": {
			"li_xiaoyao": "逍遙聽見哭聲，腳步不自覺地慢了下來。他不怕妖，但哭聲讓他放不下腳步——尤其是那種帶著恐懼的哭聲，讓他想起了某一個他永遠不願意再回想的夜晚。他深吸一口氣，走入洞窟深處，手放在劍柄上，但沒有拔出來。",
			"zhao_linger": "洞窟深處的狐面少女第一眼看見靈兒，本能地往後縮了一下，然後又慢慢地向前靠。靈兒蹲下來，和她平視。少女終於鼓起勇氣抓住了她的袖子——小小的手，緊緊的，體溫比人類高，微微燙。靈兒讓她抓著，沒有抽開，只是把另一隻手輕輕覆在她的手背上。那個顫抖漸漸小了。",
			"lin_yueru": "月如進入洞窟，劍已半出鞘。但當她看見洞窟深處的狐面少女，頓了一下，緩緩把劍放回鞘中——對方是妖，但那個慌亂和恐懼，她看得出不是假裝的。她交叉著手臂，在距離少女幾步的地方停下：「說清楚，你想要什麼。」",
			"anu": "阿奴在洞口感應了一下裡面的氣息——妖族，而且還未成年，力量不足以構成威脅。她走進去，在狐面少女面前蹲下，用她在苗疆學會的幾句妖族方言低聲問了一句：「你族人呢？」少女看見她，哭泣聲小了幾分，好像感到了某種意想不到的親近感。",
		},
		"heal": 12, "gain_cost": 6, "power": 0, "pact_max_hp_cost": 6, "pact_power": 3, "power_label": "奪丹",
		"observe_text": "你不動聲色地觀察少女的神情。她瞳孔仍是妖族特徵的金色，但眼神之中沒有殺意，只有恐懼與絕望。她身後的洞穴牆壁上有幾抹陳舊血漬，旁邊散落著一個破碎的木雕——是她族人的圖騰，被人砸碎在地。你心中有了答案：這不是埋伏，這是悲劇現場的最後倖存者。",
		"observe_effects": [{"kind": "heal_party", "amount": 3}, {"kind": "gold", "amount": 5}],
		"choices": ["approach", "observe", "leave"],
		"branch_labels": {
			"approach": ["走入洞窟", "靠近這名瑟瑟發抖的少女"]
		},
		"sub_choices": {
			"approach": ["heal", "pact", "gain_card"]
		},
		"sub_flavors": {
			"approach": "你慢慢走入洞窟深處。少女抬頭看你，淚水沿著狐面流下。她沒有抵抗，也沒有逃跑，只是抓著自己殘破的衣袖，等你決定她的命運——是放她離去、奪取她的元神為己用，還是逼她交出族藏？"
		},
		"outcomes": {
			"heal": "你收起武器，示意她離去。她感激地向你行禮，臨走前留下一縷溫和的療癒妖光，撫平了你身上的傷痛。那道妖光輕巧，像是少女留下的最後一份心意，帶著真誠的謝意。",
			"pact": "你要求她獻出靈魂本源。她咬牙點頭，一縷冰冷徹骨的妖丹元神融入你的胸口。那份損失是真實的，是永久的——但妖法帶來的破壞力卻讓招式更加致命，冰冷而有效。",
			"gain_card": "你冷酷地逼問寶藏下落。她驚恐地拋出一卷古老的地底殘卷，隨即化作煙霧遁走。為了破解殘卷上的妖族心法，你付出了不少心神與氣血，但那卷殘卷確實有幾分價值。"
		},
		"tree": {
			"root": {
				"prompt": "洞窟陰冷，水滴聲一下一下敲在石上，深處卻夾著一縷壓抑的女子低泣。循聲走近，火光照出一個狐面半人身的少女縮在角落，金瞳裡盛滿恐懼，卻沒有半分殺意。她抱緊殘破的衣袖往石壁裡退：「別……別傷我的族人。」你的手按上了劍柄，又遲遲沒拔。",
				"choices": [
					{
						"id": "spare",
						"label": "收起武器，放她離去",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 12},
								{"kind": "set_flag", "flag": "fox_spared"},
							],
							"log": "你收起武器，示意她走。她感激地行禮，臨走留下一縷溫和妖光，撫平你的傷。她記住了你的臉——也許某天，會還這份情。",
						},
					},
					{
						"id": "devour_pill",
						"label": "逼她交出妖丹，奪她元神",
						"kind_hint": "punish",
						"hide_badge": true,
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "max_hp", "amount": -6},
								{"kind": "permanent_power", "amount": 3},
								{"kind": "set_flag", "flag": "fox_slain"},
							],
							"log": "你要她獻出本源。一縷冰冷妖丹融入胸口——力量是真的，那份永久的折損也是真的。她化煙之前看了你一眼，那眼神你大概一輩子忘不掉。",
						},
					},
					{
						"id": "interrogate",
						"label": "沉下臉，逼問族藏下落",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 7},
								],
							},
							"log": "你冷聲逼問。她驚恐地拋出一卷地底殘卷便化煙遁走——殘卷上的妖族心法艱澀難解，你能不能參透，是另一回事。",
						},
					},
					{
						"id": "anu_soothe",
						"label": "（阿奴）以妖族方言安撫她",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 8},
								{"kind": "gain_potion"},
								{"kind": "set_flag", "flag": "fox_spared"},
							],
							"log": "阿奴蹲下，用苗疆學來的妖族話低聲問她族人何在。少女哭聲漸歇，從懷裡取出一枚溫熱的療傷妖丹塞給她，又指了指洞外一條安全的小徑。",
						},
					},
					{
						"id": "inspect_cave",
						"label": "先看清她身後那面洞壁",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_tragedy",
					},
					{
						"id": "leave",
						"label": "當作沒看見，退出洞窟",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你默默退出洞窟，把那團顫抖的影子留在黑暗裡。有些事，不沾手，也是一種選擇。"},
					},
				],
			},
			"nodes": {
				"node_tragedy": {
					"prompt": "火光往石壁一抬，你的心沉了下去：壁上一道道陳舊血漬已乾成黑褐，腳邊散著個被人砸碎的木雕——那是她族人的圖騰。這不是埋伏，這是一場屠戮過後的廢墟，而她，是唯一沒被殺乾淨的那一個。少女順著你的目光看去，抖得更厲害了。",
					"choices": [
						{
							"id": "protect",
							"label": "替她收殮圖騰，護送出谷",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 4},
									{"kind": "heal", "amount": 8},
									{"kind": "set_flag", "flag": "fox_spared"},
								],
								"log": "你拼起碎裂的圖騰，護著她走出幽谷。分別時她沒有說話，只把額頭抵了抵你的手背——妖族最鄭重的謝禮。",
							},
						},
						{
							"id": "loot_remains",
							"label": "在屍骸旁翻撿值錢遺物",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "gold", "amount": 20},
									{"kind": "gain_curse", "curse_id": "yao_zhai"},
								],
								"log": "你在血漬旁翻出幾件值錢的遺物揣走。少女沒有阻止，只是看著你——那目光黏在你身上，化成一縷怎麼也甩不掉的涼意。",
							},
						},
					],
				},
			},
		},
	},
	"yangzhou_officer": {
		"title": "揚州府緝盜",
		"flavor": "揚州城內人聲鼎沸，一個蒙面黑影與你擦身而過，一個沉甸甸的包袱掉在你腳邊。此時官差已在後方大喊：「站住！」",
		"character_flavors": {
			"li_xiaoyao": "逍遙低頭看著腳邊那個包袱，又抬頭看向喊著「站住」的官差，內心迅速地計算了一下局勢。他記得餘杭的縣老爺——那種人見著嫌疑犯從不多問，就算你說了真相，他也不一定信。但他更記得，看客已經不少了，而他需要在下一刻做出決定。",
			"zhao_linger": "官差追過來，抬眼一看，腳步在靈兒身上停了一秒。她看見他愣住，嘴張了張，沒立刻說話——那一秒足夠她開口了。她語氣平靜，解釋得清楚，聲音溫而穩，讓那個年輕官差回了神。她心知肚明那半秒發生了什麼，也知道自己利用了它，只是把那個念頭輕輕壓下去，先把眼前的事情解決。",
			"lin_yueru": "月如把包袱踢了一腳，確認了它的重量——不輕，裡面有些值錢的東西。她用餘光掃了一眼官差，再掃了一眼遠處消失的黑影，心裡做了個判斷：這是別人的麻煩，但已經變成她的麻煩了。好，那就用林家堡的方式解決——乾脆，清楚，不拖泥帶水。",
			"anu": "阿奴看著那個包袱，沒有動。她見過太多這樣的局面：有人逃跑，有人追，有人被夾在中間不明不白地受牽連。在苗疆，她通常選擇消失得比任何人都快。但她現在不在苗疆，官差的腳步聲越來越近，她必須在接下來的一個呼吸裡做出決定。",
		},
		"heal": 0, "gain_cost": 0, "power": 2, "power_label": "分贓", "gamble_win_power": 4, "gamble_lose_damage": 8,
		"observe_text": "你不急著動包袱，先看了一眼追上來的官差。年輕，制服整齊但鞋底沾著新泥——是真正在跑案子的，不是擺架子的。他的目光鎖定的不是你，是包袱本身。你判斷：這個官差該怕的不是「抓不到嫌犯」，是「抓到了無法交差」。事情可以談。",
		"observe_effects": [{"kind": "gold", "amount": 15}],
		"choices": ["gamble", "upgrade", "remove", "observe", "leave"],
		"outcomes": {
			"gamble_win": "你悄悄收起包袱，將官差引向別處。事後打開包袱，裡面有一些療傷靈藥，還有一卷珍貴的戰鬥身法，你功力大增。你決定不去想那個包袱的來歷，有些事情，不知道反而更自在。",
			"gamble_lose": "你正要收起包袱，卻被追上的官差人贓並獲！一陣混亂的衝突中，你被一棍重重擊中，狼狽逃脫，包袱也在混亂中被沒收。你跑遠了才停下來，沉默了片刻，繼續上路。",
			"upgrade": "你高喊一聲，順手指明了黑影的逃跑方向。捕快向你抱拳致謝，並給予短暫的武學指點，讓你的招式更為熟練洗鍊。做了正確的事，有時候不只是心安，還有意外的收穫。",
			"remove": "你一腳將包袱踢開，雙手一攤撇清關係。看著那包袱上沾染的血跡，你頓時心境空靈，拂去了一身雜念——有些東西，碰了沒好處，不碰，才是真正的聰明。"
		},
		"tree": {
			"root": {
				"prompt": "揚州街市叫賣聲震天，魚腥混著脂粉氣撲鼻。一個蒙面黑影貼著你肩膀竄過，「咚」地一聲，沉甸甸的包袱落在你腳邊。後頭一個年輕官差紅著臉追來，扯著嗓子喊：「站住——別動那包袱！」他眼裡比起捉賊，更像是怕回去沒法向府衙交差。你只剩一個呼吸的工夫。",
				"choices": [
					{
						"id": "snatch_and_run",
						"label": "抄起包袱，撒腿就鑽巷子",
						"kind_hint": "mixed",
						"next": "node_flee",
					},
					{
						"id": "hand_over",
						"label": "拾起包袱，迎上去還官差",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 12},
								{"kind": "upgrade_random"},
							],
							"log": "你抱起包袱迎上去：「人是往那邊跑了。」捕快接過包袱抱拳致意，順帶指點了你幾招——做了該做的事，心安還連帶了實惠。",
						},
					},
					{
						"id": "kick_away",
						"label": "一腳踢開包袱，兩手一攤",
						"kind_hint": "neutral",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "lose_card", "mode": "random"},
							],
							"log": "你一腳將包袱踢開，雙手一攤。捕快沒看清來歷，揮揮手讓你走——背上某道執念也跟著卸下。",
						},
					},
					{
						"id": "observe_chase",
						"label": "蹲下細認蒙面人留下的足跡",
						"kind_hint": "battle",
						"requires": {"observe_token": true},
						"next": "node_chase",
					},
					{
						"id": "anu_track",
						"label": "（阿奴）以蠱術追蹤包袱主人",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "gold", "amount": 15},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "阿奴從袋裡放出一隻追蠱，順著血味直追到一間暗巷的酒窖——裡面藏的東西比包袱還值錢。",
						},
					},
					{
						"id": "intimidate_private",
						"label": "亮出一身殺氣，逼官差私下了結",
						"kind_hint": "mixed",
						"requires": {"deck_archetype": ["power"]},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gold", "amount": 20},
								{"kind": "set_flag", "flag": "yamen_grudge"},
							],
							"log": "你不閃不避，只把一身殺氣緩緩壓向那年輕官差。他額角滲汗，到底是識相收了「辛苦費」放你走——只是他把你的臉，牢牢記在了心裡。",
						},
					},
					{
						"id": "leave",
						"label": "低頭裝沒看見，徑直走過",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你低頭快步穿過人群，腳尖差點絆上那包袱也沒回頭。年輕官差從你身旁急掠而過，呼喝聲很快被市聲淹沒——揚州城的麻煩，多得很，犯不著沾上一樁。"},
					},
				],
			},
			"nodes": {
				"node_flee": {
					"prompt": "包袱一入手就沉，你拐進窄巷狂奔。身後那年輕官差竟咬得很緊，皮靴踏在青石上的聲音越追越近，還夾著一句近乎哀求的喊：「交出來，我不為難你！」前頭一個分岔——鑽人潮，還是上屋頂。",
					"choices": [
						{
							"id": "into_crowd",
							"label": "貼緊包袱，鑽進攢動人潮",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.55,
									"win_effects": [
										{"kind": "gold", "amount": 25},
										{"kind": "gain_card_pool", "pool": "uncommon"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 6},
										{"kind": "gold", "amount": -15},
										{"kind": "gain_curse", "curse_id": "tong_ji"},
									],
								},
								"log": "你低頭鑽進人群，把包袱貼在懷裡——人群是最好的掩體，也是最壞的陷阱。",
							},
						},
						{
							"id": "rooftop",
							"label": "縱身上瓦，從屋脊上甩開他",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "bandit",
									"enemy_hp_mult": 1.1,
									"victory_effects": [
										{"kind": "gold", "amount": 30},
										{"kind": "gain_card_pool", "pool": "rare"},
										{"kind": "gain_curse", "curse_id": "tong_ji"},
									],
									"defeat_effects": [
										{"kind": "gold", "amount": -20},
										{"kind": "lose_card", "mode": "random"},
									],
								},
								"log": "你縱身躍上屋瓦。揚州捕頭也不甘示弱，腳尖一點跟著上來——這場追逐要在屋頂結束。",
							},
						},
					],
				},
				"node_chase": {
					"prompt": "你撥開包袱一角，指尖沾到的不是塵土，是還沒乾透的血。那蒙面人不是尋常扒手——逃得太有章法，專往暗巷死角鑽。這趟若不追個明白，這口黑鍋遲早扣回自己頭上。你抬腳追了上去。",
					"choices": [
						{
							"id": "interrogate",
							"label": "搶身攔在他去路上，喝問來歷",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "bandit",
									"enemy_hp_mult": 0.9,
									"victory_effects": [
										{"kind": "gain_relic_pool", "pool": "rare"},
										{"kind": "gold", "amount": 15},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 10},
										{"kind": "gold", "amount": -10},
									],
								},
								"log": "你縱身一躍，落在他的去路。對方反手拔出一柄短匕——這人比想像中難纏。",
							},
						},
						{
							"id": "let_him_go",
							"label": "收住腳步，放他一條生路",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.4,
									"win_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 8},
										{"kind": "gold", "amount": -10},
									],
								},
								"log": "你停下腳步，朝他點了點頭。他怔住，最後也朝你點了點頭——這次的放，是賭他下次的還。",
							},
						},
					],
				},
			},
		},
	},
	"lingmiao": {
		"title": "靈廟顯靈",
		"flavor": "路旁矗立著一座飽經風霜的古靈廟。廟堂正中，一盞油燈的火焰無風自動，在幽暗中散發著柔和的金光。傳說此廟能以靈符超渡亡魂、喚回生機。",
		"character_flavors": {
			"li_xiaoyao": "逍遙在廟門前站了很久。那盞無風自動的油燈讓他想起了師父講過的一個傳說，說有些廟宇是天地的節點，連著生死兩界。他向來不迷信，但今天他願意相信這個說法——因為此刻，他確實想要能有什麼奇蹟發生。他拍了拍衣襟，整了整姿態，走入廟中。",
			"zhao_linger": "靈兒祈完，火焰向她的方向微微傾倒，像是靠近。她把指尖伸過去，讓火舌輕輕貼上指腹——是暖，不是燙，細膩得像一個小心翼翼的吻。她閉上眼睛，在那片暖裡待了片刻，沒有人看見她此刻的神情，只有火焰知道，它看著她，很仔細，很溫柔。",
			"lin_yueru": "月如在靈廟前整了整衣領，做了個端正的行禮。她不是個很有宗教虔誠的人，但她相信因果。今天，她的祈求是讓倒下的人能夠再站起來。她抬頭看著廟中的神像，眼神平靜，但手被握成了拳頭，指節微微泛白。",
			"anu": "阿奴在廟門口停了很久，最後還是走了進去。苗疆的靈廟和中原的不同，但敬神的心意是一樣的。她沒有跪拜，只是站在燈前，把她手心的一滴血抹在燈火旁的石台上——那是苗疆求靈最誠心的方式，獻上自己的一滴生血，換取神明的回應。",
		},
		"heal": 16, "gain_cost": 0, "power": 0, "power_label": "求力",
		"revive_amount": 30,
		"observe_text": "你細看那盞無風自動的油燈。燈芯上凝著一滴未墜的金光，是某個極虔誠的祈求剛在這裡完成過。神像基座有極淺的水跡——有人在此跪拜時掉了眼淚，這個眼淚還沒乾。這座靈廟是真有靈，但它的「靈」依賴造訪者的真心。",
		"observe_effects": [{"kind": "heal", "amount": 6}, {"kind": "max_hp", "amount": 1}],
		"choices": ["revive", "heal", "upgrade", "observe", "leave"],
		"outcomes": {
			"revive": "你恭敬地在廟前上香叩頭。那盞油燈的火光突然大盛，化作一道暖流穿透虛空——倒下的同伴在金光中緩緩睜開雙眼，生機已然回返。廟中的靜默讓你覺得，這個奇蹟，是真的。",
			"heal": "你在廟前靜坐調息。靈廟的古意與香火在你周身流轉，積累的傷勢在不知不覺間悄然癒合。起身時，你向那盞油燈低低地點了個頭，算是道謝。",
			"upgrade": "廟牆上刻有先人留下的武學銘文，辭藻古奧難辨。你凝神反覆推敲，終於在某處豁然貫通，一門招式因此更加精進。廟外的風輕輕吹過，像是有人在說：你想清楚了。"
		},
		"tree": {
			"root": {
				"prompt": "陳年香灰的氣味先滲出門縫。推門進去，廟堂空無一人，正中一盞油燈卻無風自動，火舌穩穩地立著，把斑駁的神像鍍上一層柔金。傳說這類古廟是天地節點，連著生死兩界，能超渡亡魂、喚回生機——可它靈不靈，全看跪在燈前的人，是不是真心。",
				"choices": [
					{
						"id": "pray_revive",
						"label": "上香叩首，為倒下的同伴祈命",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "revive", "amount": 30}],
							"log": "你恭敬上香叩頭。油燈火光突然大盛，化作暖流穿透虛空——倒下的同伴在金光中緩緩睜眼，生機回返。",
						},
					},
					{
						"id": "rest_pray",
						"label": "在燈前盤膝，靜坐調息",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "heal", "amount": 16}],
							"log": "你在廟前靜坐。靈廟古意與香火在周身流轉，傷勢悄然癒合。起身時，你向那盞油燈低低點了個頭。",
						},
					},
					{
						"id": "blood_offering",
						"label": "獻一滴生血，向神明求力",
						"kind_hint": "gamble",
						"hide_badge": true,
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.55,
								"win_effects": [
									{"kind": "permanent_power", "amount": 3},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 8},
									{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
								],
							},
							"log": "你刺破指尖，把一滴血抹在燈火旁的石台上。火焰猛地一縮——神明，到底收不收這份心意？",
						},
					},
					{
						"id": "lxy_legend",
						"label": "（李逍遙）想起師父說的生死節點傳說，誠心祈願",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "revive", "amount": 24},
								{"kind": "heal", "amount": 8},
							],
							"log": "逍遙想起師父講過：有些廟宇是天地節點，連著生死兩界。他平時不信，今天願意信一次。油燈金光大盛——倒下的同伴在暖流中睜開了眼。",
						},
					},
					{
						"id": "decipher_wall",
						"label": "湊近廟牆，推敲那行武學銘文",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inscription",
					},
					{
						"id": "lowhp_burn_life",
						"label": "燃自身精血，向神明換一線生機",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.4},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.6,
								"win_effects": [
									{"kind": "heal", "amount": 24},
									{"kind": "permanent_power", "amount": 1},
								],
								"lose_effects": [
									{"kind": "max_hp", "amount": -3},
								],
							},
							"log": "你已是重傷之身，索性燃起一縷精血供於燈前——拿命換命，看神明肯不肯收。",
						},
					},
					{
						"id": "leave",
						"label": "合掌一禮，不求不擾",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向油燈合掌一禮，什麼也沒求，退出了靈廟。那盞燈在你身後依舊無風自動，火光不增不減——它不勉強人留下心願，也從不催促趕路的人。"},
					},
				],
			},
			"nodes": {
				"node_inscription": {
					"prompt": "你湊近廟牆細辨，餘光卻先落在神像基座上——那裡有兩道極淺的水痕，還沒乾透，是不久前有人跪在這裡，淚一滴一滴掉下來留的。牆上的銘文古奧難讀，可那段心法的筆意，竟和地上那點淚一樣，讀著讀著就讓人胸口發熱。",
					"choices": [
						{
							"id": "comprehend",
							"label": "閉息凝神，參透這段銘文",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "heal", "amount": 6},
								],
								"log": "你反覆推敲，某處豁然貫通，一門招式因此精進。廟外風過，像是有人說：你想清楚了。",
							},
						},
						{
							"id": "pray_for_other",
							"label": "替那位流淚的人補上一炷香",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal_party", "amount": 8},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你替那個素不相識的人補了一炷香。油燈的金光柔和地漫開，像是替你們兩個都還了願。",
							},
						},
					],
				},
			},
		},
	},
	"xianling_shrine": {
		"title": "仙靈島水月宮",
		"flavor": "穿過桃花瘴，一座縹緲的宮殿坐落在蓮花池中央。池畔置有一尊女媧神像，四周白蓮盛開，靈氣升騰。",
		"character_flavors": {
			"li_xiaoyao": "逍遙穿過桃花瘴，第一眼看見那座宮殿時，愣了足足有三秒鐘。「這是……真的嗎？」他揉了揉眼睛，宮殿還在，蓮花還在，連那尊女媧神像都是真的。他走近，感覺有什麼熟悉的東西在周圍的空氣裡——那種感覺讓他有點說不出話，只能站在那裡靜靜地深呼吸。",
			"zhao_linger": "靈兒走到蓮花池邊，脫下外袍，輕輕踏入水中。水是溫的，漫過腳踝，漫過膝蓋，裙擺在水面浮起，像白色的蓮瓣。月光從宮頂透下來，落在她的肩膀上，落在水面，落在她沒入水中的那半截身體上。她閉上眼睛，把雙臂張開，以靈族歸宗的姿態在蓮池中站立，任憑那溫柔的水繞著她轉。",
			"lin_yueru": "月如走進水月宮，謹慎地觀察四周。這裡的靈氣純淨得不像人間，但也沒有威脅的氣息。她在蓮花池旁站立，覺得這個地方讓她的劍心意外地靜——林家堡教她『靜中求銳』，但很少有地方能真正讓她做到這一點。水月宮，是其中之一。",
			"anu": "阿奴在宮門前停住，感受著那四面湧來的靈氣——這裡不是苗疆，不是她熟悉的任何地方，但那份溫柔讓她意外地放鬆了。她在女媧神像前坐下，沒有祈求，只是坐著，讓那靈氣流過，讓那溫柔暫時填滿她平時不允許自己去感受的那些空缺。",
		},
		"heal": 20, "gain_cost": 4, "power": 3, "power_label": "歸宗",
		"observe_text": "你在水月宮中靜立，四面靈氣如蓮葉露珠，柔和不侵。神像基座刻著三行細小的篆字：「水德潤萬物，月光照孤魂，靈族不孤。」這是女媧後裔留給後人的話。蓮池中央有一塊溫潤的玉璧，看起來只有特定血脈才能取下——它對普通修者是普通的玉，對靈族卻是傳承的信物。",
		"observe_effects": [{"kind": "max_hp", "amount": 2}, {"kind": "power", "amount": 1}],
		"choices": ["heal", "upgrade", "view_deck", "gain_card", "observe", "leave"],
		"choice_filters": {
			"gain_card": {"if_character": ["zhao_linger"]}
		},
		"character_outcomes": {
			"zhao_linger": {
				"gain_card": "靈兒在女媧神像前跪下，雙手合十——她的血脈與此處的靈氣產生了共鳴。蓮池中央的玉璧自行浮起，緩緩飄到她手中。玉璧裡封著一道祖母留下的水靈神術，靈兒第一次清晰地感應到了她血脈中流著的、那段一直被隱藏的歷史。她沒有哭，也沒有笑，只是把玉璧緊緊抱在懷裡，像是抱著一個終於找到的自己。"
			}
		},
		"outcomes": {
			"heal": "你掬起一捧溫潤的蓮池仙水服下，仙氣滌盪全身，長久累積的內傷與疲憊一掃而空。走出水月宮時，你覺得自己好像重新開始了，比任何休息都要徹底。",
			"upgrade": "神像旁的石壁上刻著若隱若現的心法殘篇。你駐足靜思，一門困擾你許久的招式在此刻豁然開朗，臻至圓滿之境。你在水月宮裡待了很久，捨不得離去。"
		},
		"tree": {
			"root": {
				"prompt": "桃花瘴散開，眼前豁然一亮：水月宮浮在蓮池正中，白蓮無聲盛放，靈氣自水面緩緩升騰，涼得人心頭一靜。池畔那尊女媧神像低眉垂目，香火卻早斷了——黑苗血洗仙靈島後，這裡再無人煙。劫餘的聖地，只剩白蓮替它守著。",
				"choices": [
					{
						"id": "drink_water",
						"label": "俯身掬一捧蓮池仙水飲下",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 20},
								{"kind": "max_hp", "amount": 2},
							],
							"log": "仙氣滌盪全身，長久累積的內傷與疲憊一掃而空。走出水月宮時，你覺得自己像是重新開始了。",
						},
					},
					{
						"id": "meditate_wall",
						"label": "駐足神像旁，參悟那篇心法殘篇",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "upgrade_random"}],
							"log": "石壁殘篇若隱若現。你駐足靜思，一門困擾許久的招式豁然開朗，臻至圓滿。你在宮裡待了很久，捨不得離去。",
						},
					},
					{
						"id": "zhao_jade",
						"label": "（趙靈兒）以血脈取蓮池玉璧",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"], "not_event_flag": "nuwa_jade"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "max_hp", "amount": 6},
								{"kind": "set_flag", "flag": "nuwa_jade"},
							],
							"log": "靈兒跪在神像前，血脈與靈氣共鳴。蓮池中央的玉璧自行浮起飄入她掌中——裡頭封著祖母留下的水靈神術。她把玉璧緊抱在懷裡，像抱著一個終於找到的自己。",
						},
					},
					{
						"id": "read_steles",
						"label": "蹲到神像基座前，細辨那行篆字",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_steles",
					},
					{
						"id": "leave",
						"label": "不取一物，向聖地合掌而退",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你在女媧神像前合掌一禮，什麼也沒取，沿著蓮葉鋪成的水徑悄悄退出。身後白蓮輕輕一晃，蓮香一直送你到桃花瘴外——劫後的清淨，留給後來真正需要它的人。"},
					},
				],
			},
			"nodes": {
				"node_steles": {
					"prompt": "你拭去基座上的水霧，三行細篆漸漸清晰：「水德潤萬物，月光照孤魂，靈族不孤。」最後三字刻得格外用力，像是滅門前有人含淚立下的遺言。蓮池正中靜靜浮著一塊溫潤玉璧——在尋常修者眼裡只是塊好玉，唯有對得上血脈的人，才喚得動它。",
					"choices": [
						{
							"id": "absorb_water_virtue",
							"label": "以「水德」之意靜養悟道",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal_party", "amount": 10},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你照著「潤萬物」之意吐納，靈氣如蓮葉露珠般滋養全隊。離去時，每個人的步子都輕了。",
							},
						},
						{
							"id": "grab_jade",
							"label": "不管血脈對不對，伸手強取玉璧",
							"kind_hint": "gamble",
							"hide_badge": true,
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.4,
									"win_effects": [
										{"kind": "gain_relic_pool", "pool": "rare"},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 6},
									],
								},
								"log": "你伸手去取那塊玉璧——它認血脈，而你的血，未必對得上。靈氣在指尖盤旋，是允許，還是拒絕？",
							},
						},
					],
				},
			},
		},
	},
	"flower_spirit": {
		"title": "花妖魅影",
		"flavor": "山道旁飄來一縷幽甜的花香，濃得讓人腦子不清醒。霧中走出一個女子，笑意溫柔，衣袖間落著不知名的花瓣。",
		"character_flavors": {
			"li_xiaoyao": "那女子從霧裡走出來，一步一步，花香越來越濃，讓逍遙的腦子有點轉不過來。他盯著看了一會兒——確實好看，好看得有點不像真的，好比劍靈從來不承認自己好看那種好看。他拼命讓自己清醒，想起劍靈說過的話：最危險的妖，都長著最好看的臉。但那女子已笑著走近了一步，手腕上的花瓣抖落幾片，落在他腳邊。",
		},
		"heal": 10, "gain_cost": 6, "power": 2, "power_label": "識妖",
		"observe_text": "你忍住花香的魅惑，細看女子。她的指尖確實是長指甲——但仔細看，那是花瓣與真實指甲交織的妖體。她的眼神中沒有惡意，只有一種空虛的飢渴，像是她不是想害你，只是必須這麼做。或許她也曾經是某個普通女子，只是被某個更深的東西捲入了這個輪迴。",
		"observe_effects": [{"kind": "heal", "amount": 5}, {"kind": "power", "amount": 1}],
		"choices": ["fight", "gain_card", "heal", "observe", "leave"],
		"outcomes": {
			"fight_win": "你斬破迷香幻陣，花妖現出原形，最終不敵跌落。散落的花瓣裡藏著幾件寶物，全被你收入囊中。",
			"gain_card": "你假裝中了迷術，趁花妖放鬆警惕時，把她的一縷靈術輕輕偷了過來。等你回頭，她已消失，只留下滿地落花——和一道嶄新的術法輪廓，在你腦中慢慢成形。",
			"heal": "你拔腿就跑，狼狽地把花香甩在身後。跑遠了才發現，那香氣雖然迷魂，倒也有幾分療癒之效——胸口幾處舊傷，不知何時輕了幾分。"
		},
		"tree": {
			"root": {
				"prompt": "山道轉角，一縷幽甜花香先纏上來，濃得讓人太陽穴發脹、念頭發黏。薄霧裡走出一個女子，笑意溫柔得近乎哀傷，衣袖一抖，落下幾片不知名的花瓣。她的目光卻不在你臉上——直直膠在你的喉間，像彩依那樣修了千年的妖也未必有的、一種空了的飢餓。她又近了一步。",
				"choices": [
					{
						"id": "resist_incense",
						"label": "咬破舌尖屏息對抗",
						"kind_hint": "mixed",
						"next": "node_resist",
					},
					{
						"id": "feign_charm",
						"label": "佯作著迷，反手偷她一縷術",
						"kind_hint": "gamble",
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "power", "amount": 1},
								],
								"lose_effects": [
									{"kind": "max_hp", "amount": -5},
									{"kind": "gain_curse", "curse_id": "hua_zhai"},
								],
							},
							"log": "你閉眼任花香纏住，等她探過手時——指尖一勾，反手取了一縷術法。她瞳孔縮了一下，不確定到底誰被誰偷了。",
						},
					},
					{
						"id": "observe_pity",
						"label": "頂著花香，看進她空了的眼底",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_pity",
					},
					{
						"id": "lin_seal",
						"label": "（林月如）以林家堡正派劍法封她",
						"kind_hint": "battle",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "battle",
							"battle": {
								"enemy_id": "flower_spirit",
								"enemy_hp_mult": 0.6,
								"victory_effects": [
									{"kind": "gain_card_pool", "pool": "character"},
									{"kind": "heal", "amount": 5},
								],
								"defeat_effects": [
									{"kind": "damage", "amount": 8},
								],
							},
							"log": "月如踏出半步，劍尖點在花妖咽喉前一寸。她用林家堡最簡單的封魔式——『以正鎖邪』，連花香都被劍意逼退三尺。",
						},
					},
					{
						"id": "poison_counter",
						"label": "放蠱反制她的迷香",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["poison"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "gold", "amount": 12},
							],
							"log": "你不慌不忙放出隨身的毒蠱。蠱毒對上花妖的迷香，是毒攻毒——她的香氣一寸寸被噬空，最後反倒乖乖獻出了一道煉香的祕法，只求你把蠱收回去。",
						},
					},
					{
						"id": "flee",
						"label": "屏住氣，頭也不回衝出花霧",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "heal", "amount": 5},
								{"kind": "gold", "amount": -10},
							],
							"log": "你頭也不回地衝出花霧。狼狽是狼狽，倒也保住了清醒——只是奔逃中掉了幾枚銅錢。",
						},
					},
				],
			},
			"nodes": {
				"node_resist": {
					"prompt": "舌尖一痛，血腥味把昏沉沖開一線，迷香的霧也跟著淡了一瞬。就這一瞬你看清了：她「指尖」是花瓣與骨爪絞纏而成的妖體，溫柔的笑底下，那雙眼空得發慌，直勾勾鎖著你的咽喉——她不殺你，就活不下去。",
					"choices": [
						{
							"id": "draw_sword",
							"label": "趁霧裂的一瞬，拔劍直取",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "flower_spirit",
									"enemy_hp_mult": 1.0,
									"victory_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
										{"kind": "gold", "amount": 20},
										{"kind": "heal", "amount": 5},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 15},
										{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 2}]},
									],
								},
								"log": "你毫不遲疑拔劍——花香依舊在腦中糾纏，但劍意比花香更純。",
							},
						},
						{
							"id": "seal_censer",
							"label": "一指封死她腰間那只小香爐",
							"kind_hint": "gamble",
							"outcome": {
								"kind": "gamble",
								"gamble": {
									"win_chance": 0.55,
									"win_effects": [
										{"kind": "gain_relic_pool", "pool": "uncommon"},
										{"kind": "heal", "amount": 8},
									],
									"lose_effects": [
										{"kind": "damage", "amount": 8},
										{"kind": "max_hp", "amount": -2},
									],
								},
								"log": "你看出花香源頭——她腰間有一只迷你香爐。手指疾如蝶翼，朝那一點封下。",
							},
						},
					],
				},
				"node_pity": {
					"prompt": "你迎著花香看進她眼底，那點空虛的飢渴底下，竟有一絲不甘——殺意不像出於本意，倒像有個更深、更冷的東西藏在她身後，借她的手取人性命。她曾經，多半也只是個會在山道採花的普通女子。她的唇動了動，沒出聲，像在求你，又像在求自己別動手。",
					"choices": [
						{
							"id": "purify_qi",
							"label": "不拔劍，渡她一縷清淨靈氣",
							"kind_hint": "reward",
							"requires": {"max_power": 5},
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 12},
									{"kind": "gain_relic_pool", "pool": "common"},
								],
								"log": "你閉眼渡氣。她在你的清氣裡僵住，緩緩跪下——花瓣一片片從她身上落盡。她朝你拜了一拜，化作清風散去。",
							},
						},
						{
							"id": "mercy_strike",
							"label": "舉劍，給她一個乾淨的解脫",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "flower_spirit",
									"enemy_hp_mult": 0.7,
									"victory_effects": [
										{"kind": "power", "amount": 3},
										{"kind": "max_hp", "amount": 3},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 6},
									],
								},
								"log": "她沒有抵抗，只是看著你舉起劍。你深吸一口氣——『願妳下一世，不再如此。』",
							},
						},
					],
				},
			},
		},
	},
	"flower_thief": {
		"title": "採花賊當道",
		"flavor": "一個油頭粉面的惡徒擋住去路，目光輕薄地在你身上遊走，笑得讓人作嘔。",
		"character_flavors": {
			"zhao_linger": "採花賊一臉諂媚地擋住去路，眼神從靈兒臉上滑到腳尖，再從腳尖緩緩滑回來，像是在盤點什麼物件。靈兒沒有躲閃，只是把靈力悄悄聚在指尖，臉上帶著一點對方讀不懂的微笑，等他再走近一步，再近一點——這個笑不是溫柔，是在等他犯傻。",
			"lin_yueru": "採花賊看見月如便撲了上來，一臉歹意。然而還沒碰到衣角，劍鞘就橫在他咽喉前——月如沒有拔劍，只用鞘。她覺得這個人不值得出劍。「下一次，」她說，聲音極平，「我就不用鞘了。」那人僵在原地，連眼皮都不敢眨。",
			"anu": "採花賊對阿奴的苗疆裝束好奇多於歹意，伸手要摸她的頭飾。阿奴沒有說話，只是把袖口裡一個小東西捏在掌心，讓他看見了一眼——那是一隻活的肥蠱，正在她掌心緩緩爬動。採花賊立刻後退三步，轉身消失在叢林裡，連逃跑的腳步聲都帶著哭腔。",
		},
		"heal": 8, "gain_cost": 5, "power": 2, "power_label": "教訓惡徒",
		"observe_text": "你淡淡打量這個惡徒。他不是真正的高手——衣服華麗但姿勢散亂，是被人慣壞的某個地方少爺。他的腰間沒帶武器，但鞋底磨損嚴重，是逃跑能力很強的那種。打他不會有挑戰，只會弄髒手；他真正的麻煩，是他背後可能有某個富戶在罩著。",
		"observe_effects": [{"kind": "gold", "amount": 12}],
		"choices": ["power", "gain_card", "heal", "observe", "leave"],
		"outcomes": {
			"power": "那惡徒被揍得半死，倒在路邊哀號。你踩著他走過去，憤恨在丹田化成了氣力，此後出手多了一分不需要解釋的狠。有些道理，只有這樣才說得清楚。",
			"gain_card": "你搜了搜那傢伙落荒而逃時丟下的包袱，意外翻到一卷偷來的功法殘頁。字跡已舊，招式卻管用，算是讓那個廢物稍微值了一點。",
			"heal": "你讓那惡徒落荒而逃，退到安靜的地方，讓積在胸口的憤恨緩緩散開。怒氣有時候也是藥——幾處舊傷在那股熱意中，意外地好了幾分。"
		},
		"tree": {
			"root": {
				"prompt": "一股廉價脂粉味先飄過來，嗆得人皺眉。油頭粉面的採花賊斜倚在路口，目光輕薄地在你身上爬了一圈，咧嘴一笑，露出鑲金的牙。他身手鬆垮，分明不是高手，腰桿卻挺得理直氣壯——這副蘇州城少爺的做派，背後多半有富戶罩著。「小娘子，賞個臉？」",
				"choices": [
					{
						"id": "beat",
						"label": "二話不說，把他揍趴在地",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "set_flag", "flag": "thief_backer_grudge"},
							],
							"log": "你把他揍得倒在路邊哀號。憤恨在丹田化成氣力，出手多了一分狠——但他臨走前那句「我家老爺不會放過你」，你也聽見了。",
						},
					},
					{
						"id": "shake_down",
						"label": "揪住衣領，抖光他身上的贓款",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "gold", "amount": 22}],
							"log": "你一把揪住他的衣領。他連滾帶爬地掏出一包銀錢往你懷裡塞，連頭都不敢抬。",
						},
					},
					{
						"id": "anu_gu_scare",
						"label": "（阿奴）亮出掌心的肥蠱嚇退他",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 8},
								{"kind": "gold", "amount": 10},
							],
							"log": "阿奴掌心一隻活蠱緩緩爬動。採花賊嚇得連退三步，丟下錢袋連哭帶逃地鑽進叢林——連逃跑的腳步都帶著哭腔。",
						},
					},
					{
						"id": "size_him_up",
						"label": "按住火氣，先把這廝看個透",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_backer",
					},
					{
						"id": "leave",
						"label": "連眼角都懶得給，繞道而行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你連眼角都沒分給他，逕自繞了過去。他在背後扯著嗓子罵了幾句難聽話，腳卻像釘在地上，到底不敢追上來——欺軟怕硬的東西，從來只敢對著背影叫囂。"},
					},
				],
			},
			"nodes": {
				"node_backer": {
					"prompt": "你冷眼一掃，全看明白了：綢衫華貴卻姿勢散亂，是被嬌慣壞的某地少爺；腰間不佩兵器，鞋底卻磨得極薄——逃命的本事練得比誰都熟。揍他髒手、不揍憋屈，可真正棘手的，是他唾沫橫飛抬出來的那位「老爺」，背後罩著他的富戶。",
					"choices": [
						{
							"id": "send_message",
							"label": "放他回去傳話，給富戶一個警告",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gold", "amount": 12},
									{"kind": "heal", "amount": 4},
								],
								"log": "你只取了他身上的錢，讓他滾回去傳話。乾淨俐落，不留首尾——這條路上，名聲有時比銀錢還管用。",
							},
						},
						{
							"id": "force_confession",
							"label": "逼他吐出背後主子的名號",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "lecher_thief",
									"enemy_hp_mult": 1.0,
									"victory_effects": [
										{"kind": "gold", "amount": 25},
										{"kind": "gain_relic_pool", "pool": "uncommon"},
									],
									"defeat_effects": [
										{"kind": "gold", "amount": -10},
									],
								},
								"log": "你逼問主子是誰。他色厲內荏地吹了個唿哨——叢林裡竄出他真正的打手，看來這廝也不是全然的軟腳蝦。",
							},
						},
					],
				},
			},
		},
	},
	# ── PAL1 名場面（角色情感深度互動） ─────────────────────────────────
	"jianling_whisper": {
		"title": "劍靈低語",
		"flavor": "腰間劍鞘忽然微微震動，像是劍中有什麼在試圖說話。你低頭凝視劍身——一抹紅光在劍面上一閃即逝，似有似無，像個害羞又驕傲的影子。",
		"character_flavors": {
			"li_xiaoyao": "「喂！」一個熟悉到讓他心裡某處立刻揪一下的聲音在他耳邊響起，「敢把我留在劍裡這麼多天不理人？膽子越來越大了啊，李逍遙。」逍遙的腳步停住，連呼吸都頓了一下。他沒抬頭，怕自己一抬頭就會做出什麼蠢事。「……抱歉。」他終於說，聲音比想像中還要啞一點。劍中那道紅光顫了顫，半天才憋出一句：「哼，知錯就好。」",
			"zhao_linger": "靈兒感應到劍中那縷紅光，眨了眨眼。那不是惡意，是某種強烈的、固執的、屬於另一個女子的存在。她蹲下，輕輕觸了一下劍身：「你好，我是靈兒。我能感受到你。你是這把劍裡的靈嗎？」劍中那縷紅光定了定，似乎沒料到自己被認出來，許久才回了個淡淡的閃爍。",
			"lin_yueru": "月如停下腳步，劍意微微一凜——那不是敵意，是另一道劍靈在向她致敬。她認真地把佩劍橫在胸前，回了一個劍者之禮：「林家堡弟子月如，向前輩問好。」劍中紅光微微一晃，像是被這個正式的禮數逗笑了，回了個輕快的閃爍。",
			"anu": "阿奴感應到劍中那縷紅光的瞬間，本能地把手放在自己的蠱袋上——是一個沒見過的靈體。但那個靈體沒有惡意，只是在等待什麼，等待某個她不認識的人。阿奴鬆開了蠱袋，安靜地等著，沒有打擾。",
		},
		"heal": 0, "gain_cost": 0, "power": 3, "power_label": "劍意共鳴",
		"observe_text": "你細細感受那縷紅光的氣息。它有人類女子的執拗與委屈，也有劍靈獨有的飄逸與孤獨。她在劍中存在了不知多久，等的人或許並不是你。但她願意對你開口，已經是莫大的善意。",
		"observe_effects": [{"kind": "power", "amount": 2}],
		"choices": ["power", "upgrade", "observe", "leave"],
		"choice_filters": {
			"upgrade": {"if_character": ["li_xiaoyao"]}
		},
		"character_outcomes": {
			"li_xiaoyao": {
				"power": "「想要我認真陪你用劍，那你也要認真。」紅光在他眼前緩緩盤旋一圈，最後輕輕落回劍鞘。一股熟悉到讓人鼻酸的劍意湧入丹田——這是他學御劍術時，第一次真正『感受到劍』的那種感覺，原來，她從來都在。",
				"upgrade": "「你那招根本不對。」她在他耳邊不耐煩地說，「劍尖朝這個角度才對，腕力要再收一點。」逍遙照做了，那道一直練不到滿意的招式在這一次出手中圓融通透——他想起來了，當年也是她這樣，一招一招地，把他從一個沒出師的笨蛋帶成了真正會劍的人。"
			}
		},
		"outcomes": {
			"power": "劍中紅光化作一道細細的光圈，繞著你的右手轉了一圈，留下一道劍意的印記。離去前，她沒有說再見，只是又閃了一下——像是告訴你，她還會在。",
			"upgrade": "那道劍靈靜靜地在劍中為你梳理一道招式的紋路。你不太明白她為什麼願意幫一個陌生人，但你接住了那份善意，把它收進你的劍中，好好地用。"
		},
		"tree": {
			"root": {
				"prompt": "夜深露重，腰間劍鞘忽然輕輕一顫，貼著皮膚傳來一絲幾不可察的暖。你低頭，劍面上有一抹紅光一閃即逝，倔強又帶著幾分嬌氣，像個躲在影子裡偷看你的人。劍中那道靈似乎守著一場很長的等待，等的人未必是你，卻偏偏選在此刻，對你輕輕開了口。",
				"choices": [
					{
						"id": "listen",
						"label": "屏息側耳，聽她想說什麼",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "permanent_power", "amount": 2}],
							"log": "那縷紅光緩緩浮出劍鞘，化作一道細細的光圈，繞著你握劍的右手轉了一圈，溫溫地，像有人替你理了理袖口。一道清亮的劍意順勢沉入腕底。她始終沒說再見，臨了只又閃了一下——那一閃彷彿在說：別怕，我還在，我一直都在。",
						},
					},
					{
						"id": "sword_dialogue",
						"label": "拔劍出鞘，以劍意與她應和",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["attack"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 4},
							],
							"log": "你不說話，只將劍橫於胸前，運起滿身劍意相邀。紅光像被點著了似的霍然亮起，沿著劍脊雀躍游走，與你的劍意一來一往。同道相逢，勝過千言——她痛痛快快地，把一式從未外傳的劍法拆給了你看。劍鳴聲裡，你彷彿聽見一聲沒忍住的、爽朗的輕笑。",
						},
					},
					{
						"id": "lxy_apology",
						"label": "（李逍遙）認出那聲音，啞著嗓子賠罪",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"], "not_event_flag": "sword_spirit_bond"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "upgrade_random"},
								{"kind": "heal", "amount": 10},
								{"kind": "set_flag", "flag": "sword_spirit_bond"},
							],
							"log": "「好你個李逍遙，把我擱在劍裡這麼多天，當沒這個人？」那聲音一響，逍遙整個人僵在原地，喉頭像被什麼堵住。他不敢抬頭，怕一抬頭就忍不住。半晌，才啞著嗓子吐出兩個字：「……對不住。」紅光顫了又顫，憋了好久，才悶悶回一句：「哼，知錯就好。」那一刻，熟悉到讓人鼻尖發酸的劍意重新湧進丹田——原來這一路，她從來沒走遠，只是不吭聲地，替他擋著風。",
						},
					},
					{
						"id": "sense_her",
						"label": "閉目凝神，細辨那縷紅光的來歷",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_waiting",
					},
					{
						"id": "leave",
						"label": "不去叨擾，輕輕把劍推回鞘中",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你沒多問，只把劍輕輕送回鞘裡，動作放得很慢，怕驚著她。劍面的紅光一點點黯下去，像是鬆了口氣，又像是把一句到嘴邊的話，重新嚥了回去。鞘合的那聲輕響，聽著竟有些不捨。"},
					},
				],
			},
			"nodes": {
				"node_waiting": {
					"prompt": "你閉目細辨，那縷氣息裡有人間女子才有的執拗與委屈，也有劍靈獨有的飄逸與蕭索。她在這方寸劍鞘裡，已等了不知多少個春秋——等的那個人，分明不是你。可她仍肯對你閃這一下，已是極大的善意。一念至此，你心頭莫名一酸。",
					"choices": [
						{
							"id": "wait_with_her",
							"label": "什麼也不問，坐下來陪她等",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 3},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你什麼也沒做，就在原地坐了下來，陪那縷紅光一同望著遠處的路。風吹過，星子移了位，她要等的人始終沒來。可她沒有怨，反倒把一身本事悄悄分了些給你，像在謝你這份不問緣由的陪伴。臨別她閃了閃，那光裡，第一次有了暖意。",
							},
						},
						{
							"id": "drain_her",
							"label": "趁她出神，強奪那道劍意",
							"kind_hint": "punish",
							"hide_badge": true,
							"outcome": {
								"kind": "punish",
								"effects": [
									{"kind": "permanent_power", "amount": 3},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
								"log": "趁她望著遠路出神，你猛地運勁，強行將那道劍意攫入掌中。紅光霎時劇烈翻騰、明滅不定，那閃動的節律亂得像一個人被最不該背叛她的人背叛了，無聲地哭。力量到手了——可那股徹骨的冷意也隨之住進你的劍裡，往後每一次出鞘，劍鳴都帶著一絲怨。",
							},
						},
					],
				},
			},
		},
	},
	# 自創內容（非 PAL1 正史）：阿七為阿奴胞弟，PAL1 無此角色。
	# 依 CLAUDE.md「PAL1 素材不足才自創」原則：阿奴在 PAL1 缺少家族向支線，
	# 此事件補足其親情敘事，祖母（聖姑）為正史角色，阿七為原創。
	"aqi_reunion": {
		"title": "阿七的笛聲",
		"flavor": "山道彼端傳來悠遠的苗笛聲，調子陌生卻熟悉。穿著與你同一族紋路的少年正坐在岩石上吹笛，看見來人，把笛子放下，微微笑了。",
		"character_flavors": {
			"li_xiaoyao": "逍遙聽見那個笛聲，不知為何停下了腳步。聲音不刺耳，但帶著一種他沒聽過的調子——像是訴說，又像是召喚。坐在岩石上的少年放下笛子，看了逍遙一眼，眼神平和但帶著一點探問。逍遙抱了抱拳：「打擾了。」",
			"zhao_linger": "靈兒聽見笛聲，本能地放慢了腳步。那聲音很乾淨，沒有惡意，但有一種強烈的『屬於某個地方』的氣息——不屬於這裡。少年看見她，輕輕點了個頭，繼續吹了兩句，才把笛子放下。靈兒覺得，他在等的人，可能就是她身旁那個。",
			"lin_yueru": "月如停下，警戒地打量那個少年。但對方沒有敵意，只是吹著笛，眼神平靜。林家堡教過她認識各地方的服飾——少年身上是南疆的紋路，和她身邊那個沉默的同伴是同一族。她退到一旁，把這個場合留給該說話的人。",
			"anu": "阿奴聽見笛聲的瞬間，整個人僵了一下。那是她族裡的『歸笛』——只有當部族需要喚回遠行的人時，才會吹響。她快步走近，看見坐在岩石上的少年抬頭，眼神和她記憶中那個小她兩歲的弟弟阿七一模一樣。「阿七。」她叫他，聲音輕得像怕驚醒一個夢。少年笑了，把笛子收起：「姐姐，你比我想的，瘦了。」",
		},
		"heal": 15, "gain_cost": 5, "power": 2, "power_label": "族脈",
		"observe_text": "你不動聲色地觀察少年。他坐姿端正，雙手粗糙但乾淨——是經過長時間勞動的手。笛子用的是苗疆深山才有的玉竹，竹節上刻著一個小小的「七」字。他在等人，等的時間夠久，腳邊的草都被他坐扁了一圈。",
		"observe_effects": [{"kind": "heal_party", "amount": 4}],
		"choices": ["heal", "gain_card", "observe", "leave"],
		"choice_filters": {
			"gain_card": {"if_character": ["anu"]}
		},
		"character_outcomes": {
			"anu": {
				"heal": "阿七從懷裡取出一個用苗繡布包著的小東西。「祖母讓我給你的。」是一塊她小時候戴過的玉佩，碎了，被人用紅線細細地穿成了新的形狀。阿奴接過，緊緊握在掌心。淚水在眼眶裡轉了一圈，最後沒有掉下來——她已經很久沒有讓自己哭過了。但這份溫熱，沿著她的心，悄悄止住了多年的疲倦。",
				"gain_card": "阿七從背後解下一個布囊：「姐姐，這是族裡最厲害的蠱師寫的『歸蠱訣』。祖母說，妳走得太遠，必須把家裡的東西帶在身上，這樣才不會把自己弄丟。」阿奴接過那卷殘譜，蹲下來，從小到大第一次當著別人的面，慢慢地哭了。哭完站起來，她已經把家裝進了自己的劍裡。"
			}
		},
		"outcomes": {
			"heal": "少年遞給你一帖南疆的療傷藥草，氣味陌生卻有效。「我姐姐讓我給的，」他說，「她說會路過這裡的人，多半是值得幫的。」你不知道他姐姐是誰，但你向他道了謝。",
			"gain_card": "少年從懷裡取出一卷殘破的紙頁。「我姐讓我帶著的，說會用到。」你接過殘頁，發現上面是一套你從未見過的南疆心法。少年沒有再說什麼，只是吹了一段笛，繼續等他的人。"
		},
		"tree": {
			"root": {
				"prompt": "山風裡飄來一縷悠遠的苗笛，調子陌生，卻像鉤子似的勾住了腳步，叫人莫名鼻酸。轉過山坳，一名身著南疆紋飾的少年盤腿坐在岩石上，玉竹笛橫在唇邊。見有人來，他從容地擱下笛子，朝你淺淺一笑——那笑容裡有種等了很久很久的安靜。",
				"choices": [
					{
						"id": "ask",
						"label": "走近些，問他在等什麼人",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "heal", "amount": 12}],
							"log": "少年沒答你等的是誰，只從竹簍裡摸出一帖南疆草藥，藥香清苦得陌生。「我姐姐交代的，」他把藥遞來，眼睛望向遠路，「她說會打這條道上經過的，多半是值得搭把手的人。」你接過道謝，終究沒問出他姐姐的名字——可那名字，彷彿就在某個你認識的人身上。",
						},
					},
					{
						"id": "anu_reunion",
						"label": "（阿奴）笛聲一響，認出了那是阿七",
						"kind_hint": "reward",
						"requires": {"character": ["anu"], "not_event_flag": "anu_family_reunion"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 12},
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "set_flag", "flag": "anu_family_reunion"},
							],
							"log": "那調子阿奴一聽就僵住了——是族裡的「歸笛」，只在喚遠行的人回家時才吹。她快步上前，看清岩石上那張臉，眼眶一下子就熱了：「阿七……」聲音輕得像怕碰碎一個夢。少年回頭笑了：「姐姐，你比我想的瘦了。」他從懷裡掏出祖母託付的「歸蠱訣」雙手奉上。阿奴蹲下身，這輩子頭一回當著外人的面，無聲地哭了，肩膀一抽一抽。哭完抹乾眼睛站起來，她已經把整個家，悄悄裝進了懷裡。",
						},
					},
					{
						"id": "listen_flute",
						"label": "不出聲，聽他把這段笛吹完",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_flute",
					},
					{
						"id": "leave",
						"label": "頷首致意，把這段等待留給他",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你朝少年點了點頭，沒去打聽什麼，把這方山岩留給他和他要等的人。才走出幾步，笛聲又在身後悠悠揚起，一聲一聲，像替遠方某個遲歸的人，固執地守著一個說好的約。"},
					},
				],
			},
			"nodes": {
				"node_flute": {
					"prompt": "你停下腳步，靜靜聽。那笛是苗疆深山才有的玉竹所制，竹節上刻著一個小小的「七」字。少年坐得筆直，一雙手粗糙卻乾淨，是常年勞作又愛惜自己的手。他在這兒等的時間想必極久——腳邊一圈青草，都被坐得伏倒了。",
					"choices": [
						{
							"id": "share_road",
							"label": "坐到他身旁，講講路上的見聞",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal_party", "amount": 6},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你在他身旁坐下，把這一路的風霜揀著說了些。少年托腮聽得入神，眼睛亮晶晶的，彷彿那些遠方也是他想去的地方。臨別，他往你手裡塞了一小包南疆藥粉：「給往後路過的人。」山風吹涼了暮色，那份不設防的善意，卻比任何藥都暖。",
							},
						},
						{
							"id": "buy_flute_song",
							"label": "討教這段「歸笛」的調子",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "colorless"},
								],
								"log": "少年把笛子遞過來，一句一句不厭其煩地教。調子起初拗口，吹順了卻有種說不出的牽掛纏在裡頭。「會吹這支笛的人，」他望著遠處的山口輕聲說，「走到天涯海角，也記得回家的路。」你把這段旋律吹進了心裡，也悄悄揉進了自己的招式。往後每逢出手，氣息深處都像有人在喚你回頭。",
							},
						},
					],
				},
			},
		},
	},
	"tangyu_sparring": {
		"title": "石壁前的少年",
		"flavor": "山道旁的石壁前，一個瘦弱的少年正在揮舞著一把比他高一截的青釭劍，姿勢笨拙到讓人想笑，但每一劍都認真得要命。他見你停步，露出了一個倔強的笑容：「能否賜教一二？」",
		"character_flavors": {
			"li_xiaoyao": "逍遙看見那個少年的瞬間，心裡有一絲奇怪的熟悉感——這個臉，這個眼神，他像是見過。少年抱劍行禮，姿勢正確但僵硬，明顯是還沒練熟。逍遙也回了一禮：「你叫什麼名字？」少年抬頭，眼睛亮得像兩顆星星：「我叫……唐鈺！前輩，請賜教！」",
			"zhao_linger": "靈兒看著那個少年，覺得他身上有一種讓她說不清的熟悉感——不是相識，是某種隱約的、屬於命運的聯繫。她沒有出手，只是溫柔地看著他練劍：「你的姿勢需要再放鬆一點。劍不是用力握的，是用心扶的。」少年聽得認真，眼睛眨都不眨。",
			"lin_yueru": "月如看著少年揮劍，立刻看出他的問題——根基不錯，但動作太僵，像是被某個嚴格的師父逼著練的。她走上前，沒有廢話，直接示範了正確的起手式：「跟我做。」少年僵硬地照做了，月如看著他的眼神，意外地溫和了幾分——這是個會認真的孩子。",
			"anu": "阿奴看著那個少年，覺得他和自己有一點相像——都是被某個無形的力量推著往前走的人。她沒有說話，只是蹲在一旁，看著他練劍。少年揮了幾劍，回頭看她：「妳……不嫌我笨？」阿奴搖頭：「不笨。練到了，就是真的。」少年笑了，比之前更認真地揮了下一劍。",
		},
		"heal": 0, "gain_cost": 6, "power": 3, "power_label": "切磋",
		"observe_text": "你細看少年的姿態。他的青釭劍是好劍，但對他來說太重——這把劍應該是別人留給他的，而不是他自己挑的。他堅持用這把劍，是因為某種情感上的原因，而不是實用考量。他的劍意很乾淨，沒有殺氣，只有一種「想要變強來保護什麼」的純粹。",
		"observe_effects": [{"kind": "power", "amount": 2}, {"kind": "heal", "amount": 3}],
		"choices": ["power", "upgrade", "gain_card", "observe", "leave"],
		"character_outcomes": {
			"li_xiaoyao": {
				"power": "逍遙與少年對招了三十回合。少年的劍法稚嫩，但每一劍都帶著一種他似曾相識的固執。逍遙忽然懂了——這個眼神他見過，這個劍意他用過。「你叫唐鈺對吧？」他停下劍，「記住你今天的這一招——這是我師父教我的時候，反過來教給我的東西。」"
			}
		},
		"outcomes": {
			"power": "你與少年切磋一場。他的劍意還在萌芽，但勝負之間，那份純粹的鬥志反而讓你血脈共鳴，丹田裡多了幾分當初剛入劍道時的銳意。離別時，他向你深深一禮，連名字都沒問。",
			"upgrade": "你指點少年的劍法。少年認真地聽，當你示範到第三次時，他忽然反問你一個你也沒想過的問題——你愣了一下，那一刻，你自己手裡某道招式的瑕疵，竟在這個少年笨拙的問題裡，自己揭露了。",
			"gain_card": "你陪少年練劍直到天黑。臨別時，他從懷裡取出一卷殘破的劍譜：「這是我祖父給我的，但我練不來。前輩拿著吧，總比留在我手裡浪費好。」你接過那卷劍譜，覺得這個少年比他自己以為的，要珍貴得多。"
		},
		"tree": {
			"root": {
				"prompt": "石壁前一聲又一聲的劍嘯，又急又拙。一名瘦弱少年雙手攥著一柄高過他半頭的青釭劍，咬牙劈、刺、收，劍身沉得幾乎要把他拖倒，他卻一招也不肯偷懶。汗珠順著下頷滴在石上。聽見你的腳步，他猛地立直身子，臉漲得通紅，亮著兩眼磕磕巴巴：「前輩……能、能否賜教一二？」",
				"choices": [
					{
						"id": "spar_thirty",
						"label": "拔劍應戰，陪他過三十招",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "power", "amount": 2},
								{"kind": "heal", "amount": 3},
							],
							"log": "三十招打下來，少年劍劍露怯卻劍劍不退，被你震得虎口發麻仍咬牙再上。他那份毫無雜質的鬥志，竟燒得你血脈也跟著滾燙。收劍時，你怔了一怔——丹田裡，竟尋回了幾分當年剛摸到劍道門檻時、那種天不怕地不怕的銳氣。「好小子。」你笑著拍了拍他的頭。",
						},
					},
					{
						"id": "correct_form",
						"label": "扶正他的握姿，從頭指點",
						"kind_hint": "reward",
						"next": "node_lesson",
					},
					{
						"id": "observe_sword",
						"label": "目光落在那柄青釭劍上，細看",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_legacy",
					},
					{
						"id": "lxy_recognize",
						"label": "（李逍遙）那雙眼睛，看得他心頭一動",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "劍光交錯間，逍遙忽然看呆了——這倔強、這不肯認輸、這把命都豁出去的傻勁，分明是當年那個在十里坡對著草靶死磕的自己。他收劍按住少年的肩：「你叫唐鈺，對吧？記住你今天這一招。」少年茫然點頭。逍遙嗓子有些發緊：「這是我師父教我時，反過來教會我的東西——練劍練到後來，練的是心。」少年似懂非懂地重重點頭。逍遙笑了，眼眶卻有點熱：「往後別再亂揮，那把劍，配得上你。」",
						},
					},
					{
						"id": "lin_correct",
						"label": "（林月如）板起臉，示範林家堡的起手式",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "upgrade_random"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "月如不多話，劍尖一引，乾淨俐落地擺了個正確的起手式：「看好，跟我做。」少年僵著手腳照搬，歪歪扭扭。月如本要斥他，看著那張認真到發顫的小臉，語氣不自覺軟了下來：「你有底子，可別逞強去扛不該扛的劍。」一句話出口，連她自己一直卡著的某道招式，也跟著鬆開了死結。",
						},
					},
					{
						"id": "true_exchange",
						"label": "收起輕視，與他來一場真刀真劍",
						"kind_hint": "reward",
						"requires": {"deck_archetype": ["attack"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "upgrade_random"},
							],
							"log": "你收起那點居高臨下，鄭重地拔劍相向。少年的劍稚嫩漏洞百出，可正因你不肯敷衍，反倒被逼著把自己的劍意一層層攤開、一處處重審——原來教人，從來都是在磨自己。一場酣暢淋漓的對劍下來，你那道纏了多時、始終不通的招式，竟在汗水裡豁然開竅。",
						},
					},
					{
						"id": "take_his_sword",
						"label": "伸手，強奪他祖傳的青釭劍",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "gain_relic_pool", "pool": "rare"},
								{"kind": "gain_curse", "curse_id": "tong_ji"},
								{"kind": "gold", "amount": -15},
							],
							"log": "你冷冷拋下一句：「這把劍對你太重。」少年身子一僵，嘴唇咬得發白，到底還是顫著手把青釭劍奉了過來，隨即猛地背過身去。山風裡，你聽見他極力壓著、卻仍漏出來的抽噎。劍入掌中沉甸甸的，你的手心竟也滲出冷汗。江湖上從此多了一筆關於你的閒話——你說服自己不在乎，可那哽咽的背影，會在某些夜裡找上門來。",
						},
					},
					{
						"id": "leave",
						"label": "拱手婉拒，留他自己去磨",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你含笑拱手婉拒，轉身上路。山道走遠了，石壁前那一聲聲劍嘯仍倔強地追著你，不快、不巧，卻一下都不肯停。你心想：這樣的孩子，不必誰來教，遲早也是要成器的。"},
					},
				],
			},
			"nodes": {
				"node_lesson": {
					"prompt": "你一伸手扶正他的腕，少年立刻把青釭劍收到胸前，挺直腰桿，連喘氣都放輕了，那雙眼睛直勾勾望著你，生怕漏看一個動作。日影偏西，他臉上的汗未乾，神情卻虔誠得像在聽一句天機。",
					"choices": [
						{
							"id": "teach_grip",
							"label": "從怎麼握劍，一招招教起",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "power", "amount": 2},
									{"kind": "gold", "amount": 12},
								],
								"log": "握劍、立樁、起手、收勢——你一招一招拆開了教，少年認真得連大氣都不敢喘。教到夕陽沉下山脊，他忽然從懷裡摸出僅有的幾枚銅板，紅著臉硬塞進你掌心：「這是拜師費！」你看他那股不容推拒的倔勁，到底收下了。不為錢，是不想辜負這份鄭重。",
							},
						},
						{
							"id": "teach_humility",
							"label": "勸他：別硬扛這把太重的劍",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "heal", "amount": 5},
								],
								"log": "你按住他發抖的手腕，輕聲說：「這把劍此刻對你太重。可等你的劍意夠了，它自然就輕了。」少年愣了好一會兒，眼裡的執拗慢慢化開，鄭重點頭。話說出口，你心頭也一鬆——原來自己手裡那道始終逞強的招式，早該放下這份沉甸甸的執念了。",
							},
						},
					],
				},
				"node_legacy": {
					"prompt": "你的目光在那柄青釭劍上停住——劍紋古樸，鋒芒內斂，是把難得的好劍，卻明顯壓得這瘦弱少年喘不過氣。這劍不是他挑的，是有人留給他的。他寧可被它拖累也死攥不放，分明是為了某個不肯說出口的人。少年察覺你在看劍，下意識把它往懷裡攏了攏。",
					"choices": [
						{
							"id": "ask_origin",
							"label": "輕聲問起這把劍的來歷",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "max_hp", "amount": 2},
								],
								"log": "「這是我祖父留下的。」少年低下頭，聲音細了下去。他斷斷續續講完那段家事，你聽著，半晌沒能出聲——這世上終究沒人能替另一個人扛起他的劍，可你能告訴他，怎樣讓自己配得上這柄劍。臨別，他從劍鞘夾層裡鄭重掏出半卷泛黃的舊劍譜，雙手奉上：「前輩，這個您拿著吧——它跟著我，會生鏽的。」",
							},
						},
						{
							"id": "spar_serious",
							"label": "成全他，認真打一場",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "bandit",
									"enemy_hp_mult": 0.7,
									"victory_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
										{"kind": "permanent_power", "amount": 2},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 6},
									],
								},
								"log": "少年抹去額角的汗，咬著牙抬眼：「請前輩……盡全力。」他雙手吃力地舉起那柄青釭劍，劍尖卻穩穩指向你。這一場他輸定了，他也知道——可他要堂堂正正、傾盡所有地輸一次。你心頭一震，深吸口氣，斂去笑意，認真了起來。這份鄭重，值得你拿出真本事相待。",
							},
						},
					],
				},
			},
		},
	},
	# PAL1 名場面：蘇州城林家比武招親擂台。林天南為女兒林月如招親，逍遙誤上擂台勝月如。
	"bijian_zhaoqin": {
		"title": "比武招親",
		"flavor": "蘇州城最熱鬧的街口搭起了高高的擂台，紅綢招展。台下人聲鼎沸——南武林盟主林天南為掌上明珠林月如擺下比武招親之局，台上紅衣女子按劍而立，神情睥睨，至今無一人能在她劍下走過十招。",
		"character_flavors": {
			"li_xiaoyao": "逍遙本是被人群推搡著擠上前，誰知腳下一絆，竟一頭栽上了擂台。台上紅衣女子冷冷拔劍：「既上了台，便接招吧！」逍遙叫苦不迭——他根本沒想招親，可這劍已經刺到了眼前。",
			"lin_yueru": "月如立在自家擺的擂台上，看著台下那群眼冒紅光、卻沒一個入得了眼的男子，只覺索然無味。父親要她招親，她偏要打得這些人落花流水——她林月如的夫君，得先勝得了她的劍。",
			"zhao_linger": "靈兒被人潮推著擠到擂台前，仰頭望著那位颯爽的紅衣女子，眼裡滿是按捺不住的好奇。這般明媚、張揚、半點不肯收斂鋒芒的女子，是她在仙靈島水月宮裡，那些溫婉嫻靜的姊妹中從未見過的。姥姥從前說，人各有命，各有各的活法。靈兒看著台上飛揚的劍光，輕聲對自己說：原來一個女子，也可以這樣理直氣壯地，要強。她忽然有點羨慕，也有點嚮往。",
			"anu": "阿奴本對這招親的喧鬧提不起半點興致——苗疆人擇偶，看的是誰能在山林裡活得久，不是誰劍使得漂亮。可台上那女子的劍法到底讓她多看了好幾眼：快、狠、準，每一招都奔著要害去，不留半分虛架子，是個真正在生死邊上練出來的會家子。她蹲在人群外緣，嚼著一根草莖，難得地評了一句：「這個，可以做朋友。」打得真的人，從不騙人。",
		},
		"heal": 0, "gain_cost": 6, "power": 2, "power_label": "較量",
		"observe_text": "你在台下細看那紅衣女子的劍法。她出手凌厲卻不失章法，是名門正派的根基，招式間偶爾露出的嬌縱與不耐，又透著大小姐的脾性。這是個高傲卻磊落的對手——勝她不能靠陰招，只能靠真本事。",
		"observe_effects": [{"kind": "power", "amount": 1}, {"kind": "heal", "amount": 3}],
		"choices": ["power", "gain_card", "observe", "leave"],
		"outcomes": {
			"power": "你躍上擂台與紅衣女子交手。她的劍快而剛烈，逼得你全力應對，一場酣鬥下來雖未分高下，你的劍意卻在這勢均力敵的較量中精進了幾分。",
			"gain_card": "你與台上女子鬥了數十回合，她忽然收劍而笑：「你這路數有點意思。」言罷將自家一式劍法拆解與你看——你竟在這場比武裡，悟得了一招新的劍術。",
		},
		"tree": {
			"root": {
				"prompt": "鑼鼓喧天，紅綢漫卷，蘇州城最熱鬧的街口擠得水洩不通。高台上一名紅衣女子按劍而立，下頷微揚，眼神睥睨眾生——台下漢子已被她連挑了七八個，沒一個走得過十招。她劍尖一抖，挑落最後一人的佩巾，朗聲一笑：「還有誰，要上來討教？」聲音清脆，藏著三分挑釁、七分無趣。",
				"choices": [
					{
						"id": "challenge",
						"label": "縱身躍上擂台，接她這一問",
						"kind_hint": "battle",
						"next": "node_duel",
					},
					{
						"id": "watch_learn",
						"label": "擠在台下，把她的劍看個分明",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "power", "amount": 1},
								{"kind": "gain_card_pool", "pool": "uncommon"},
							],
							"log": "你抱臂立在台下，把那紅衣女子的每一起手、每一收勢都看進眼裡。劍勢凌厲卻處處合乎章法，是林家堡正派的根基。看著看著，那套名門劍法的脈絡在你心裡一點點亮了起來——不必上台討那頓打，你也悄悄偷得了一手。",
						},
					},
					{
						"id": "lxy_stumble",
						"label": "（李逍遙）被人群一擠，稀里糊塗摔上台",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "max_hp", "amount": 3},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "人群一擁，逍遙腳下一絆，整個人狼狽栽上擂台。還沒站穩，月如的劍已刺到鼻尖：「既上了台，便接招！」他連聲叫苦——根本沒想招親啊！慌亂中胡亂一揮，那招歪七扭八的御劍術竟「噹」地盪開了她的劍，台下登時哄然叫好。月如愣在原地，又驚又惱，臉頰莫名泛起一點紅：「你……你叫什麼名字？」她沒察覺自己問得急了些。一場誤打誤撞，就此結下一段啼笑皆非、卻誰也賴不掉的緣。",
						},
					},
					{
						"id": "lyr_on_stage",
						"label": "（林月如）這擂台正是我擺的，打個痛快",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "upgrade_random"},
							],
							"log": "紅綢翻飛，月如將台下那群眼冒紅光的庸手一個個挑落擂台，劍勢酣暢得連她自己都暢快。爹要她招親，她偏要打到所有人都明白：能站到林月如身邊的，唯有先勝得了她這柄劍的人。一場盡興廝殺，劍法又利了三分。只是夜深收劍時，她望著空蕩蕩的台子，心底竟莫名空了一塊——彷彿在等一個還沒出現、卻該出現的人。她自己也說不上來。",
						},
					},
					{
						"id": "leave",
						"label": "湊個熱鬧，看罷便走",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你夾在人潮裡看了一陣，台上紅衣翻飛、劍光凜凜，惹得滿街喝采。你搖頭笑了笑——這般高傲的姑娘，誰娶得了？擠出人群繼續趕路，鑼鼓聲在身後漸遠。"},
					},
				],
			},
			"nodes": {
				"node_duel": {
					"prompt": "你足尖一點，輕巧落上擂台。紅衣女子眼睛霎時一亮，方才那股懶洋洋的無趣一掃而空：「喲，總算來了個瞧著像樣的。」她手腕一轉，挽出個漂亮的劍花，紅綢般的衣袖獵獵作響，話音未落人已欺身而至。",
					"choices": [
						{
							"id": "fight_fair",
							"label": "不退半步，正面接下她的劍",
							"kind_hint": "battle",
							"outcome": {
								"kind": "battle",
								"battle": {
									"enemy_id": "sword_spirit",
									"enemy_hp_mult": 0.8,
									"victory_effects": [
										{"kind": "gain_card_pool", "pool": "rare"},
										{"kind": "permanent_power", "amount": 2},
									],
									"defeat_effects": [
										{"kind": "damage", "amount": 8},
									],
								},
								"log": "她的劍又快又烈，招招不留情面，逼得你連連硬接，火星四濺。你索性提起全副本事相迎——這姑娘最瞧不起的便是敷衍，要贏她，唯有在劍上見真章。台下喝采如雷，她唇角竟揚起一抹久違的笑：「好！這才有點意思！」",
							},
						},
						{
							"id": "yield_gracefully",
							"label": "鬥到酣處，收劍抱拳服輸",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "power", "amount": 1},
									{"kind": "heal", "amount": 4},
								],
								"log": "鬥到酣處，你忽然撤步收劍，抱拳一揖：「姑娘劍法高明，在下甘拜下風。」她劍尖頓在半空，一時竟有些怔——分明還能再打，你卻給足了她顏面。她哼了一聲別過臉去，耳根卻悄悄紅了，眼底那分睥睨化作了實打實的認可。一場切磋，劍上、心裡，兩個人都有所得。",
							},
						},
					],
				},
			},
		},
	},
	# PAL1 名場面：彩依（蝶妖）為救書生劉晉元，散盡千年道行的「蝶戀」典故。
	# 毒娘子（蜘蛛精）在正史由李逍遙、林月如所斬，此處作 callback 而非開戰。
	"caiyi_butterfly": {
		"title": "蝶戀",
		"flavor": "破舊宅院飄出花草藥香。一名素衣女子正將剛採的奇花投入藥爐，煎著一鍋『百花仙釀』；屋內床上躺著個面色青黑、氣息微弱的書生。女子抬頭，眼神溫柔卻藏著化不開的疲憊。",
		"character_flavors": {
			"li_xiaoyao": "逍遙一進門就怔住了——這眉眼，是劉府的丫鬟！當初在劉家莊，這姑娘端茶遞水、寸步不離那位病弱的劉公子。原來她從未離開過。逍遙鼻子一酸，默默走過去，往藥爐裡添了把柴火。",
			"zhao_linger": "靈兒一眼便看出那女子並非凡人——她的影子，在火光裡是一對舒展的蝶翼。同為非人之身，靈兒心頭一軟。她輕聲開口：「姊姊，他……值得妳這樣嗎？」女子只是笑，沒答。",
			"lin_yueru": "月如的目光落在書生脖頸的青黑紋路上，臉色一沉——那是纏魂絲，毒娘子的手筆。她握緊了劍：這隻蜘蛛精，她與逍遙曾經交過手。女子卻搖頭：「斬了她，他便再無解藥了。」月如沉默。",
			"anu": "藥香裡有一縷『活』的氣息，阿奴的眉頭立刻皺了起來。她湊近書生，用骨針挑起一絲青黑的毒絲端詳——這毒會認主、會反噬，和苗疆某些最毒的蠱同源。她蹲下身：「這毒……我見過類似的。」",
		},
		"heal": 10, "gain_cost": 6, "power": 1, "power_label": "憐心",
		"observe_text": "你借著煎藥的火光細看。女子每投一味藥，指尖都微微發顫——她在用自己的元氣餵那鍋仙釀。她的影子落在牆上，竟是一對緩緩開合的蝶翼。她是隻千年蝶妖，為了一個救過她命的書生，散盡道行也甘願。她察覺你的目光，並不躲避，只輕聲說：『我這條命，本就是他給的。』",
		"observe_effects": [{"kind": "heal", "amount": 6}, {"kind": "power", "amount": 1}],
		"choices": ["heal", "gain_card", "observe", "leave"],
		"outcomes": {
			"heal": "你上山替她採齊缺的幾味奇花。女子煎出新一鍋仙釀，書生的氣息穩了些。她對你深深一禮，藥香沁入你自己的舊傷，竟也緩和了幾分。",
			"gain_card": "你陪她守了大半夜的爐火。臨別，她往你掌心塞了半卷《百花譜》：『我用不上多久了……你帶著吧。』那一筆一畫，是用一個將盡之人的溫柔寫成的。"
		},
		"tree": {
			"root": {
				"prompt": "破院裡飄著化不開的花草藥香，藥爐咕嘟咕嘟翻著。素衣女子跪坐爐前，將剛採的奇花一味味投入鼎中，煎著那鍋傳說中的「百花仙釀」；床上躺著個面色青黑、氣息游絲的書生。她抬眼看你，那眼神溫柔得近乎透明，只剩疼惜，半分也沒留給自己。每投一味藥，她的指尖都在發顫。",
				"choices": [
					{
						"id": "gather_herbs",
						"label": "二話不說，上山替她採齊藥草",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 8},
								{"kind": "gain_card_pool", "pool": "common"},
							],
							"log": "你翻遍幾道山谷，把缺的奇花異草一一採齊送回。女子接過，眼眶微紅，又煎出新一鍋仙釀，書生臉上的青黑肉眼可見地褪了一分。她起身對你深深一禮，垂首間鬢角竟落下一片極淡的、近乎透明的鱗粉。那縷溫熱藥香漫進你身上的舊傷，連日的倦意也悄悄散了。",
						},
					},
					{
						"id": "share_vitality",
						"label": "渡一縷真氣，替書生壓住毒勢",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "max_hp", "amount": -4},
								{"kind": "permanent_power", "amount": 2},
							],
							"log": "你按上書生冰涼的手腕，渡出一縷真氣護住他將熄的心脈。你自己虛了幾分，眼角餘光卻瞥見那女子望著你，眼裡有種旁人讀不懂的瞭然。那一刻你忽然懂了她——有些力量，正是在毫無保留地給出去之後，才真正變得強大。",
						},
					},
					{
						"id": "observe_truth",
						"label": "藉著火光，細看那女子的來歷",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_truth",
					},
					{
						"id": "lxy_recall",
						"label": "（李逍遙）想起劉府那位寸步不離的丫鬟",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 12},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "逍遙認出她了——這眉眼，分明是劉府裡那個端茶遞水、寸步不離劉公子的丫鬟。原來她從沒走，原來那從來不是主僕之情。他鼻頭一酸，什麼也問不出口，只默默走過去往爐裡添了把柴，陪她守了一整夜。火光映著她漸漸淡去的輪廓，他把這份情義牢牢記下——人能為一個人傾盡所有到這般地步，他也想，做那樣的人。天明時，他的劍意沉了，心也靜了。",
						},
					},
					{
						"id": "zhao_unbind",
						"label": "（趙靈兒）以靈族秘法為書生鬆解纏魂絲",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal_party", "amount": 10},
							],
							"log": "靈兒指尖靈光流轉，覆上書生脖頸，那一根根青黑的纏魂絲竟一寸寸鬆開、化作輕煙。女子睜大了眼，望著她，聲音發顫：「你……也不是凡人。」靈兒輕輕搖頭，沒說自己是女媧後裔，只回她一個瞭然而溫柔的笑——同是為情甘願捨身的人，何必說破。她把這份溫柔，原封不動地還給了她。",
						},
					},
					{
						"id": "lin_recall",
						"label": "（林月如）認出這是毒娘子的纏魂絲",
						"kind_hint": "mixed",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_relic_pool", "pool": "uncommon"},
								{"kind": "next_battle_buff", "effects": [{"kind": "power", "amount": 1}]},
							],
							"log": "月如的目光落在書生脖頸那道青黑紋路上——纏魂絲，毒娘子的手筆。她與逍遙曾在蘇州城外與那隻蜘蛛精交過手，此刻握劍的指節都白了。可她到底沒衝出去尋仇：斬了毒娘子，這書生便連最後一線解藥都斷了。她深吸一口氣，把這口惡氣狠狠壓進劍裡，留待真正該出手的那一日。彩依望著她，輕輕道了聲謝。",
						},
					},
					{
						"id": "anu_analyze",
						"label": "（阿奴）以苗疆毒術剖析纏魂絲",
						"kind_hint": "mixed",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 6},
							],
							"log": "阿奴用骨針挑起一絲青黑毒絲，湊到鼻尖嗅了嗅——這毒會認主、會反噬，和苗疆最毒的幾種蠱同源。她不動聲色地調了一帖解毒散摻進仙釀，書生的青黑褪了一分。女子怔怔望著她：「妳……懂這個。」阿奴點頭，難得地沒有跳脫，只是輕輕說：「毒和情，到了最深處，有時候是同一種東西——都讓人甘願痛。」",
						},
					},
					{
						"id": "siphon_butterfly",
						"label": "趁她虛弱，奪她千年道行",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "permanent_power", "amount": 3},
								{"kind": "max_hp", "amount": -8},
								{"kind": "gain_curse", "curse_id": "yao_zhai"},
							],
							"log": "你抬手，點向她身後那對虛淡的蝶影。彩依回過頭，眼裡先是一震，隨即化作一片你看不懂的釋然——她沒躲，連手都沒抬，只低聲說了句：「也好，省得我親手熬到燈枯。」一縷千年蝶翼真元順著指尖湧入你丹田，鋒利、冰冷、帶著花的餘香。爐火「啪」地爆了個花，床上的書生長長吐出一口氣，臉色竟轉了紅潤——他活了。而身後再無半點聲息。你拿了力量走出破院，回頭時，藥爐邊只剩一地細碎的、再不會飛起的彩色鱗粉。她到死都沒告訴他，那鍋藥是用什麼換的。",
						},
					},
					{
						"id": "leave",
						"label": "不去攪擾這份癡心，悄然退出",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你沒有出聲，怕驚擾了這一屋子的癡與痛，只輕手輕腳退了出去，替她們把門掩上。藥香追著你飄出老遠，久久不散，像一句沒能說完的話。你忽然明白，有些深情，旁人連旁觀的資格都該斂著。"},
					},
				],
			},
			"nodes": {
				"node_truth": {
					"prompt": "火光一跳，照清了那道落在牆上的影子——竟是一對緩緩開合的蝶翼。她是修行千年的蝶妖彩依。當年那書生救過她一命，如今她要散盡整整千年的道行，換他區區十年陽壽。她迎上你的目光，並不躲閃，只是極輕地笑了笑，彷彿你撞破的，不過是一樁早已認了的命。",
					"choices": [
						{
							"id": "keep_secret",
							"label": "什麼都不問，替她守住這秘密",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_potion", "potion_id": "baihua_xianniang"},
									{"kind": "heal_party", "amount": 6},
								],
								"log": "你點了點頭，把湧到嘴邊的問題全嚥了回去——有些事，知道了便該替人收好。彩依眼裡漾起一絲感激，轉身往你掌心塞了一只溫熱的瓷瓶，是她親手煎的百花仙釀：「路上……或許用得著。我，是用不上多久了。」她說得很輕，輕得像怕你聽見。",
							},
						},
						{
							"id": "ask_worth",
							"label": "輕聲問她：這樣，值得嗎",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"log": "她沒有立刻答，只是望著床上那張漸漸回暖的臉，望了很久很久，才轉過頭，笑得溫柔又坦然：「千年道行，換他十年陽壽……你說值不值？可若教我再選一回，我還是會這樣選。」爐火映著她近乎透明的側臉。那一刻你像被什麼狠狠撞中了胸口，半晌說不出話——往後你的招式裡，悄悄多了一分不顧自身、義無反顧的決絕。",
							},
						},
					],
				},
			},
		},
	},
	"jiang_waner_grief": {
		"title": "婉兒之死",
		"flavor": "破敗的茅屋裡躺著一具年輕女子的遺體，眉目清秀，身上有拜月教施加的邪術痕跡。一塊染血的玉佩在她手中緊握，刻著「婉」字。地上散落幾頁血書，字跡顫抖卻清晰。",
		"character_flavors": {
			"li_xiaoyao": "逍遙站在茅屋門口，沒有立刻進去。屋裡那具遺體年輕得讓他心裡發冷——她連二十歲都不到。他深吸了一口氣，走進去，蹲在她身旁，把她攥得發白的手指輕輕分開，取下那塊玉佩。「對不起，」他低聲說，「我來晚了。」",
			"zhao_linger": "靈兒看見那具遺體的瞬間，呼吸停了一下。對方身上的拜月邪術痕跡，和靈族遭遇的、和母親告訴她的、那段她不願再回想的記憶——一模一樣。她跪在女子身旁，雙手合十，眼淚無聲地落在拜月符紋的灰燼上。「對不起，妹妹。」她說，聲音輕得像怕吵醒她，「但你的仇，我替你記下了。」",
			"lin_yueru": "月如站在茅屋中央，靜靜地讀完那幾頁血書。寫的是一個普通女子被拜月教選中為祭品的過程——沒有英雄救美，沒有奇蹟，只有一個年輕生命被緩慢殺死的真相。月如把血書折好，放進懷裡。她不是會輕易說承諾的人，但這一次，她在心裡發了一個誓。",
			"anu": "阿奴蹲在女子身旁，用蠱術感應她生前的氣息——還殘留著苗疆才有的某種草藥味道。這個女子曾用過南疆的解毒藥，但顯然不夠。阿奴從袋裡取出一個小小的銀鈴，輕輕放在女子手心：「在苗疆，這代表你已經安息。」她低聲說，「對不起，這是我能給你的全部。」",
		},
		"heal": 0, "gain_cost": 0, "power": 3, "power_label": "立誓",
		"observe_text": "你細讀那幾頁血書。婉兒並非普通村女——她是某個拜月教叛逃者的妹妹，被當作報復的對象帶到這裡，緩慢地用作儀式祭品。她最後的一頁寫著：「無論誰看到這封信，我求你一件事：替我告訴拜月教的人，他們最終的祭壇上會有人替我，把他們的血一起灑下去。」字跡到這裡突然中斷。",
		"observe_effects": [{"kind": "damage", "amount": 2}, {"kind": "power", "amount": 3}],
		"choices": ["power", "remove", "observe", "leave"],
		"choice_filters": {
			"remove": {"if_character": ["zhao_linger"]}
		},
		"character_outcomes": {
			"zhao_linger": {
				"power": "靈兒把婉兒的玉佩貼在自己胸口，閉上眼睛。一股冷冽卻堅定的力量從玉佩中流入她的血脈——這不是拜月邪術，這是一個女子用生命換來的、要看見拜月教滅亡的執念。靈兒睜開眼，眼神比任何時候都銳利。「我答應你，婉兒。」",
				"remove": "靈兒在女子身旁靜坐良久，用靈族的儀式為她超渡。儀式進行到一半時，靈兒體內某種一直纏繞著她的、對拜月教的恐懼忽然鬆動了——她終於明白，她不是受害者的延續，她是要終結這一切的人。心中某道一直影響她出招的猶豫，在這個下午徹底斬斷。"
			}
		},
		"outcomes": {
			"power": "你在婉兒身旁立下一個無聲的誓言。怒氣與哀痛在丹田裡凝成一股不退的銳意——以後你出手，會帶著她沒能活下去的那份份量。",
			"remove": "你在女子身旁靜坐，為她做一場簡單的告別。出來時，胸中某種一直壓著你的雜念變淡了——你終於明白，有些事情不能用慣性對待，必須做出取捨。"
		},
		"tree": {
			"root": {
				"prompt": "推開茅屋門，一股淡淡的血腥混著黴味撲面而來。一名年輕女子伏在草蓆上，身子尚未冷透，眉目本是清秀，此刻卻凝著拜月教邪術留下的青灰痕。她手裡死死攥著一塊染血玉佩，刻著一個「婉」字。身旁散著幾頁血書，字跡顫抖，卻一筆一畫寫得異常清晰，像是怕後來人看不懂。屋裡靜得只剩你自己的心跳。",
				"choices": [
					{
						"id": "read_blood_letter",
						"label": "蹲下身，把那幾頁血書讀完",
						"kind_hint": "reward",
						"next": "node_read",
					},
					{
						"id": "take_jade",
						"label": "輕輕掰開她的手，取下玉佩",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_relic_pool", "pool": "uncommon"},
								{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 3}]},
							],
							"log": "你一根一根掰開她攥得發白的手指，取下那塊還帶著餘溫的玉佩。它落進掌心，沉甸甸的——那重量不只是玉，是一個還沒來得及好好活過的人，把她全部沒能說完的話、沒能走完的路，悄悄壓進了你手裡。你握緊它，喉頭發堵：「我帶你走。」",
						},
					},
					{
						"id": "observe_clue",
						"label": "湊近，細看血書中斷的那一筆",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_clue",
					},
					{
						"id": "lxy_cover",
						"label": "（李逍遙）撕下衣襟，為她蓋上",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "heal", "amount": 10},
							],
							"log": "逍遙在門口站了好一會兒才走進去，蹲下身，默默撕下半幅衣襟，輕輕替她蓋住那張太過年輕的臉。他不知道她叫什麼、從哪來，可他心裡清楚得發疼——這樣的事，不該再有第二樁。「對不住，我來晚了。」他低聲說。起身時，他的劍意比方才更沉、更穩，像替誰多扛了一份。",
						},
					},
					{
						"id": "leave_silent",
						"label": "別過臉，當作沒看見地退出去",
						"kind_hint": "punish",
						"outcome": {
							"kind": "punish",
							"effects": [
								{"kind": "permanent_power", "amount": -1},
							],
							"log": "你別開眼，告訴自己這不關你的事，轉身退了出去。門在身後合上，可那雙攥著玉佩的手，那寫到一半的血書，卻像針一樣扎進你心裡。腳步比進門時沉了許多。沒人會記得你來過這裡——可有些目光一旦躲開了，往後便要在夢裡，一遍一遍地還。",
						},
					},
				],
			},
			"nodes": {
				"node_read": {
					"prompt": "一頁頁讀下去，你的手越來越冷。她叫婉兒，是拜月教叛逃者的妹妹，被擄來當作報復的祭品，一日一日地、緩慢地耗盡了性命。沒有英雄，沒有奇蹟，只有一個人清醒地走向死亡。最後一句寫到一半，墨色驟然中斷——「無論誰看到這封信，我求你……」",
					"choices": [
						{
							"id": "vow_revenge",
							"label": "按血為印，替她把那句話接完",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 3},
								],
								"log": "你蘸了她未乾的血，在那句話的斷處，沉沉按下一枚指印。她沒能寫完的請求，從今日起，由你的劍替她一筆一筆寫完。怒意與哀痛在丹田裡凝成一股不退的鋒芒，劍意如鋼，再無一絲遲疑。「我記下了，婉兒。」你低聲說。屋外，風起了。",
							},
						},
						{
							"id": "zhao_send_off",
							"label": "（趙靈兒）合掌，以靈族祭禮為她引魂",
							"kind_hint": "reward",
							"requires": {"character": ["zhao_linger"]},
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 5},
									{"kind": "gain_card_pool", "pool": "character"},
								],
								"log": "靈兒跪在婉兒身旁，合十低誦靈族引魂的禱詞，淚水無聲落在那片拜月符紋的灰燼上。婉兒身上的邪術痕，和母親告訴過她的、靈族遭逢的劫難一模一樣。儀式行到一半，那道盤踞在她心底多年、對拜月教的恐懼竟如潮水般退去——她終於明白，自己不是受害者的延續，她是要親手終結這一切的人。「安息吧，妹妹，」她輕聲說，「剩下的，交給我。」",
							},
						},
						{
							"id": "anu_farewell",
							"label": "（阿奴）取出銀鈴，行苗疆的送別禮",
							"kind_hint": "reward",
							"requires": {"character": ["anu"]},
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal_party", "amount": 15},
									{"kind": "gain_potion"},
								],
								"log": "阿奴蹲下身，用蠱術輕輕探了探女子殘留的氣息——還纏著一縷南疆草藥味，她生前掙扎過，只是不夠。阿奴從蠱袋裡取出一枚小小的銀鈴，放進她冰涼的掌心：「在苗疆，這代表你已經到家了。」鈴聲清清地響了一聲，散在屋裡。全隊都覺得緊繃的胸口，悄悄鬆了一寸。「對不起，這是我能給你的全部。」",
							},
						},
					],
				},
				"node_clue": {
					"prompt": "你湊近細看那中斷的一筆——血墨拖出一道明顯的傾斜，不是力竭，是她臨終前用盡最後一絲氣力，刻意把筆尖拽向了北方。北方，正是拜月教祭壇的方位。她至死都在替後來人指路。",
					"choices": [
						{
							"id": "remember_direction",
							"label": "把這方位記死在心裡",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "next_battle_buff", "effects": [{"kind": "power", "amount": 2}]},
									{"kind": "gold", "amount": 15},
								],
								"log": "你蘸了她未乾的血，把那個方位一筆筆畫在自己的內襟上，貼著心口。下一場該尋的仇家在哪裡，你已經清清楚楚。臨走，你朝那道傾斜的筆跡深深一揖——你不只記下了路，也記下了是誰，用最後一口氣替你指的路。",
							},
						},
						{
							"id": "burn_letter",
							"label": "點一把火，燒了血書讓她安息",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "lose_card", "mode": "random"},
								],
								"log": "你在她身旁拾柴點起一小堆火。血書一頁一頁卷曲、焦黑、化成灰燼，那些慘痛的字句隨煙散去，不必再留人間給她添一重重負。火光裡，你胸中某道一直纏著你、放不下的執念，也跟著一同燒化了。她該走得乾乾淨淨。你看著最後一頁化盡，輕聲道：「路，我替你記著了。安心去吧。」",
							},
						},
					],
				},
			},
		},
	},
	# ── Event Redesign（Phase 4）：稀有奇遇——能重塑整場 run 的大機緣 ──
	# rarity "rare"：MapGenerator 對其降權（event_pick_weight=1，common 為 5），
	# 遇到一次能改寫整場走向，給玩家「這趟撞上了不得了的東西」的記憶點。
	"shushan_vault": {
		"title": "蜀山秘府",
		"rarity": "rare",
		"flavor": "山壁裂開一道僅容一人的縫，縫後別有洞天——蜀山前輩封存的秘府。蟠桃醞的酒香、鎮府法寶的靈光、一方刻滿劍訣的石壁，靜靜等了不知多少年。",
		"character_flavors": {
			"li_xiaoyao": "逍遙鑽進石縫，倒抽一口氣。這氣派，這劍訣，這滿室不散的酒香——他幾乎立刻想起了師父那只朱漆酒葫蘆。「蜀山……」他喃喃。師父說過蜀山有秘府，藏著走遠了的前輩留下的東西。原來不是吹牛。",
			"zhao_linger": "靈兒踏入秘府，靈氣純淨得讓她心安。她認得這種氣息——是真正修道之人窮盡一生淬鍊出來的東西，不帶半分妖邪。她在石壁前輕輕行禮，低聲說：「晚輩叨擾了。」",
			"lin_yueru": "月如環視秘府，呼吸都放輕了。石壁上的劍訣層次分明、氣象萬千，是她從未見過的高度。她握緊劍柄，心跳得有些快——這是一個劍者畢生難遇的機緣，她不能錯過，也不敢輕慢。",
			"anu": "阿奴在秘府門口猶豫了一下才走進去。中原修道之人的地方，本與她無關；但那滿室的靈光裡，有一種跨越族別的厚重，讓她肅然。她沒有貿然伸手，先繞著秘府走了一圈，確認這份機緣不是陷阱。",
		},
		"heal": 0, "gain_cost": 0, "power": 0, "power_label": "悟道",
		"observe_text": "你細看秘府全貌。蟠桃醞的酒缸封著紅泥，喝下能令一身招式脫胎換骨，卻也要折損幾分元氣；鎮府處供著一件靈光內斂的法寶；石壁劍訣的盡頭刻著一行字：『以命驗道者，得失皆己。』這是一座只渡有緣、不渡貪心的秘府。",
		"observe_effects": [{"kind": "heal", "amount": 10}, {"kind": "max_hp", "amount": 3}],
		"choices": ["observe", "leave"],
		"outcomes": {},
		"tree": {
			"root": {
				"prompt": "石縫之後豁然開朗，一座沉睡了不知幾百年的蜀山秘府在你眼前展開。劍意凝成的霧氣浮在半空，連呼吸都帶著歲月的厚重。三樣機緣靜靜並陳：一缸封著紅泥、酒香醺人的蟠桃醞，一件靈光內斂、隱隱搏動的鎮府法寶，一壁直通天際、密刻劍訣的青石。崖頂落下一行古字，是先人留話：「此府只渡有緣，不渡貪心。」三選其一——你心跳如鼓，知道自己撞上了畢生難遇的造化。",
				"choices": [
					{
						"id": "drink_peach_wine",
						"label": "飲下蟠桃醞，全副招式脫胎換骨",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "upgrade_all"},
								{"kind": "max_hp", "amount": -5},
							],
							"log": "你揭開紅泥，酒香轟然撲面，一缸蟠桃醞仰頭灌下。烈酒入腹即化作一道滾燙靈流，奔湧過四肢百骸，胸中每一道招式都被它沖刷、淬鍊、擦得透亮如新。代價是真元被這一通脫胎換骨折去了幾分，可你睜眼時，分明覺得自己已不是入府前的那個人了。這一缸酒，值。",
						},
					},
					{
						"id": "take_treasure",
						"label": "向供台一禮，請走鎮府法寶",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_relic_pool", "pool": "rare"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "你整了整衣襟，向供台鄭重一禮，這才雙手捧起那件法寶。觸手的剎那，它內斂的靈光忽然一盛，順著你的指節暖暖滲入，像沉睡多年的舊識終於等到了人，認下了新的主人。你能感到，它在你掌心極輕地、極熟稔地搏動了一下。",
						},
					},
					{
						"id": "stake_life",
						"label": "以命驗道：盤坐劍訣之下整整三日",
						"kind_hint": "gamble",
						"hide_badge": true,
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.5,
								"win_effects": [
									{"kind": "permanent_power", "amount": 3},
									{"kind": "max_hp", "amount": 10},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 14},
									{"kind": "gain_curse", "curse_id": "xie_yin"},
								],
							},
							"log": "你盤膝坐定於通天劍訣之下，咬牙引那滔天劍意灌入經脈。劍氣如萬刃同時刮過骨血，痛得你幾度幾乎昏厥，又幾度被那磅礴的道意托起。三日三夜，水米未進。這一坐，是破繭成蝶、就此窺見天道，還是經脈寸斷、走火入魔——全看你這條命，配不配得上這壁劍訣。",
						},
					},
					{
						"id": "lxy_shushan_lineage",
						"label": "（李逍遙）吐出師父傳的御劍術，叩問秘府",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"], "not_event_flag": "shushan_recognized"},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 2},
								{"kind": "heal", "amount": 8},
								{"kind": "set_flag", "flag": "shushan_recognized"},
							],
							"log": "逍遙不取那三樣寶物，只閉目運起師父當年在餘杭城外傳他的御劍術，劍意輕輕一吐。霎時間，滿壁沉睡的劍訣竟如星河被點亮，齊齊轟然回應——這座蜀山秘府，認得這一縷氣！逍遙怔在原地，鼻頭驟然一酸：原來師父那個整日醉醺醺、拎著破酒葫蘆胡鬧的老頭，從把第一式御劍術塞給他的那天起，就早已把他算進了這條傳承裡。他從沒說，可這滿壁劍光替他說了。一道清越的御劍真意順著劍尖流回丹田，像師父隔著歲月，又拍了拍他的肩。",
						},
					},
					{
						"id": "study_wall",
						"label": "拾級而上，細讀劍訣的盡頭",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_wall",
					},
					{
						"id": "lowhp_blood_pact",
						"label": "拚著重傷，割掌以血引動鎮府靈光",
						"kind_hint": "gamble",
						"hide_badge": true,
						"requires": {"hp_below": 0.4},
						"outcome": {
							"kind": "gamble",
							"gamble": {
								"win_chance": 0.6,
								"win_effects": [
									{"kind": "gain_relic_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 2},
								],
								"lose_effects": [
									{"kind": "damage", "amount": 6},
								],
							},
							"log": "你已是強弩之末，傷上加傷未必扛得住。可機緣當前，你索性一咬牙劃破掌心，將溫熱的血按上鎮府法寶——以這條早已搖搖欲墜的命為注，賭一賭這座古府，肯不肯在絕境裡拉你最後一把。靈光在血色中緩緩睜開了眼。",
						},
					},
					{
						"id": "leave",
						"label": "分毫不取，向秘府深深三拜而退",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 8},
							],
							"log": "你環視這滿室造化，終究向秘府深深三拜，一樣都不曾伸手，便靜靜退了出去。就在轉身的剎那，那壁劍訣的靈光忽然柔和一閃，彷彿一位看不見的前輩頷首而笑，劍意如羽，在你眉心輕輕一點。一股清明自天靈灌下——原來這座只渡有緣的古府，最不渡的便是貪心；不貪者，反而得了它最深的一份饋贈。",
						},
					},
				],
			},
			"nodes": {
				"node_wall": {
					"prompt": "你拾級而上，指尖循著一行行劍訣摸到盡頭，那裡並列著兩個遒勁古字。一是「傳」——將畢生所學傾囊託付給有緣後人；一是「藏」——於險絕處留一手不外傳的保命後著。先人把畢生抉擇凝在這兩字裡，等一個讀得懂的人來取。你呼吸一窒——只能擇其一。",
					"choices": [
						{
							"id": "inherit_all",
							"label": "承「傳」字訣，盡得真傳",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 2},
								],
								"log": "你依「傳」字訣運氣一周天，剎那間，前輩窮盡一生的劍意如江河決堤、自天靈灌頂而下，浩浩蕩蕩奔過全身。你咬牙接住了這份沉甸甸的託付，渾身大汗淋漓，胸中卻憑空多出一道前所未見、足以開碑裂石的殺招。你對著石壁長揖到地——這份傳承，你接下了。",
							},
						},
						{
							"id": "learn_guard",
							"label": "習「藏」字訣，留一手保命後著",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "max_hp", "amount": 8},
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 10}]},
								],
								"log": "你沉心記下那一手「藏」字後著。它不顯山露水，不爭一時之快，卻能在命懸一線、退無可退的關頭，硬生生替你扛住那致命的一擊。你忽然懂了——這是前輩用畢生踩過的險路、吃過的虧換來的，他把那塊最要緊的踏腳石，悄悄留給了後來人。",
							},
						},
					],
				},
			},
		},
	},
}

static func for_variant(variant: String) -> Dictionary:
	return VARIANTS.get(variant, VARIANTS["shrine"]) as Dictionary

static func flavor_for(event_data: Dictionary, character_id: String) -> String:
	var char_flavors: Dictionary = event_data.get("character_flavors", {}) as Dictionary
	if char_flavors.has(character_id):
		return String(char_flavors[character_id])
	return String(event_data.get("flavor", ""))

static func rest_heal_for(max_hp: int) -> int:
	return max(1, int(ceil(max_hp * REST_HEAL_PERCENT)))

# Event Redesign（Phase 4）：事件稀有度。未標記者預設 "common"。
# "rare" 事件能重塑整場 run，地圖選池對其降權（MapGenerator.event_pick_weight）。
static func rarity_of(variant: String) -> String:
	var ed: Dictionary = VARIANTS.get(variant, {}) as Dictionary
	return String(ed.get("rarity", "common"))
