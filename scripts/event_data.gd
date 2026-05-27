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
				"prompt": "山壁後一眼清泉，水氣溫潤。你蹲下身——",
				"choices": [
					{
						"id": "drink",
						"label": "掬水而飲",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 12},
								{"kind": "next_battle_buff", "effects": [{"kind": "energy", "amount": 1}]},
							],
							"log": "清冽入喉，靈氣自丹田緩緩升起。下一場戰鬥開場將多 1 點靈力。",
						},
					},
					{
						"id": "bathe",
						"label": "入水沐浴",
						"kind_hint": "mixed",
						"next": "node_bathe",
					},
					{
						"id": "observe_pool",
						"label": "觀察泉底",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_observe",
					},
					{
						"id": "lxy_meditate",
						"label": "以「以身合水」打坐",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 10},
							],
							"log": "逍遙想起師叔的話，泉水的靈氣順著經脈走了一圈。",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向泉水拱手，繼續前行。"},
					},
				],
			},
			"nodes": {
				"node_bathe": {
					"prompt": "水深及腰，你閉眼浸入——感到水底有什麼在動。",
					"choices": [
						{
							"id": "relax",
							"label": "繼續放鬆",
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
								"log": "你閉眼放鬆，把自己交給泉靈。",
							},
						},
						{
							"id": "alert",
							"label": "立刻起身警戒",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 6},
									{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 5}]},
								],
								"log": "你及時起身，泉靈也識相不再試探。",
							},
						},
					],
				},
				"node_observe": {
					"prompt": "水底沉著一塊磨平的玉，刻著上古符紋。",
					"choices": [
						{
							"id": "take_jade",
							"label": "取玉",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "gold", "amount": 5},
								],
								"log": "玉入手心，溫潤微熱。",
							},
						},
						{
							"id": "leave_jade",
							"label": "留下不取",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 8},
									{"kind": "power", "amount": 1},
								],
								"log": "你把玉留在泉底，泉靈在心中低語一句感謝。",
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
			"lin_yueru": "月如拔出佩劍，在符匣周圍確認了一圈。靈劍山莊的規矩是：不明之物，先查再動。符文層次分明，出自行家，靈光的溫度也比預期穩定——這是某個認真修道之人留下的遺物，並非陷阱。她把劍收回，蹲下身來。",
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
				"prompt": "破舊符匣半埋土中，靈光未散。鎖鏈鏽蝕，但禁制尚在。",
				"choices": [
					{
						"id": "force_open",
						"label": "強拆禁制取物",
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
							"log": "你伸手抓向鎖鏈——",
						},
					},
					{
						"id": "slow_unfold",
						"label": "順著符紋緩拆",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "next_battle_buff", "effects": [{"kind": "block", "amount": 5}]},
								{"kind": "heal", "amount": 6},
							],
							"log": "符匣在你手中慢慢解開，溫熱的靈氣裹住你的傷口。",
						},
					},
					{
						"id": "observe_runes",
						"label": "觀察符紋",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inspect",
					},
					{
						"id": "zhao_lineage",
						"label": "以靈族文字辨識來歷",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 1},
								{"kind": "max_hp", "amount": 3},
							],
							"log": "靈兒讀出符匣是上代修者的遺贈，溫熱沿指尖流入。",
						},
					},
					{
						"id": "leave",
						"label": "不動，離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向符匣輕輕拱手，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_inspect": {
					"prompt": "符紋背面有極淡字跡：『貪者反噬』。",
					"choices": [
						{
							"id": "take_potion_only",
							"label": "只取藥包不動符",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_potion"},
									{"kind": "gold", "amount": 8},
								],
								"log": "你只取走藥包，符紋繼續沉睡。",
							},
						},
						{
							"id": "erase_warning",
							"label": "抹除『貪者反噬』四字後再開",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"log": "四字隨指輕抹散去，符匣應聲而開。",
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
				"prompt": "石壁間浮現微光，前人留下的靈痕，無戰意只有純粹的存在感。",
				"choices": [
					{
						"id": "stand_quietly",
						"label": "趨前靜立感應",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 8},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "靈痕的溫度在心口慢慢散開。",
						},
					},
					{
						"id": "siphon",
						"label": "試圖汲取靈痕",
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
							"log": "你伸手往光暈中央按下——",
						},
					},
					{
						"id": "meditate",
						"label": "在靈痕前打坐悟法",
						"kind_hint": "reward",
						"next": "node_meditate",
					},
					{
						"id": "observe_origin",
						"label": "觀察光痕來歷",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_origin",
					},
					{
						"id": "lin_salute",
						"label": "以靈劍山莊禮數行劍致敬",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 4},
							],
							"log": "月如的劍意與壁上殘光共鳴，前輩似乎滿意地點了點頭。",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向石壁低頭一禮，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_meditate": {
					"prompt": "閉目片刻，靈光在識海中組成一段心法殘篇。",
					"choices": [
						{
							"id": "ascend",
							"label": "跟隨心法升華某招",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "heal", "amount": 4},
								],
								"log": "識海一震，那道招式自行重組。",
							},
						},
						{
							"id": "memorize",
							"label": "把心法純粹記下不練",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "common"},
									{"kind": "gold", "amount": 5},
								],
								"log": "你只是記住，不去動。心法在你掌中安靜得像一隻入睡的小獸。",
							},
						},
					],
				},
				"node_origin": {
					"prompt": "光痕的氣息與你熟悉的東西呼應——這位前輩，或與你有源頭關係。",
					"choices": [
						{
							"id": "kneel",
							"label": "跪拜致意",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你深深一拜，光暈為你停留片刻才再次隱回石壁。",
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
								"log": "你抱拳致謝，沒有收下這份贈與。光暈卻悄悄替你護了一段路。",
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
			"lin_yueru": "月如蹲下來仔細打量機關的結構。靈劍山莊有一門功課叫做「識陣」，專門研究各類禁制與機關——這個鎖扣的設計很紮實，出自武林之人，不是妖物。她嘴角微微一動：解開這種機關，正是她拿手的事。",
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
				"prompt": "倒塌的木箱半埋落葉，鎖鏈鏽蝕但機關未解。",
				"choices": [
					{
						"id": "pry",
						"label": "直接撬開",
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
							"log": "你一刀挑開鎖扣——",
						},
					},
					{
						"id": "careful",
						"label": "用劍鞘小心觸發機關",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 15},
								{"kind": "gain_potion"},
							],
							"log": "鎖扣應聲而開，毒針只挑斷了劍鞘上一根線。",
						},
					},
					{
						"id": "observe_trap",
						"label": "觀察機關",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_trap",
					},
					{
						"id": "anu_disarm",
						"label": "以骨針反向解蠱毒機關",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 25},
								{"kind": "gain_potion"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "阿奴認出毒針配方是苗疆親戚的手筆，骨針一挑，毒針反封自身。",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你掂了掂這個箱子，覺得不如不開。"},
					},
				],
			},
			"nodes": {
				"node_trap": {
					"prompt": "金屬絲在箱蓋下繃緊——這是毒針機關，但設計者留了給識者的旁路。",
					"choices": [
						{
							"id": "bypass",
							"label": "走旁路安全開鎖",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gold", "amount": 20},
									{"kind": "gain_card_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 5},
								],
								"log": "你順著旁路解開鎖扣，毒針從另一側無聲彈過。",
							},
						},
						{
							"id": "trigger_grab",
							"label": "故意觸發毒針後翻箱",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "damage", "amount": 6},
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "gold", "amount": 10},
								],
								"log": "你受了毒針一刺，但箱底壓著一件不打眼的好物。",
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
			"li_xiaoyao": "逍遙在祭壇前站了一會兒，背脊有些發涼——骨殖雖只剩殘片，靈氣卻出奇地強烈，像是有一雙看不見的眼睛正在打量他。「好啦好啦，我很尊敬你們……」他小聲咕噥，把師叔教過的致敬之禮依稀想了起來，做了個半吊子的行禮。",
			"zhao_linger": "靈兒在祭壇前緩緩跪下。低頭念咒語的時候，散開的青絲貼著臉頰垂落，她顧不上撥開，任由那縷髮絲掃過頸側——涼涼的，像是先靈伸出了一根指尖。她念完之後，才把那縷頭髮輕輕攏到耳後，在空曠的祭壇裡，覺得這個動作有些孤單。",
			"lin_yueru": "月如肅然行禮，同時暗自打量那縷靈氣的品質——純粹、強烈，是武人留下的意志，而非妖物的殘存。靈劍山莊山後的供奉之地，她見過類似的氣息，但這裡的更古老，更凝重，像是某個在戰場上完成了使命的靈魂。",
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
				"prompt": "古老祭壇上一具尚未化盡的骨殖，靈氣濃郁。蜷縮坐化之姿，旁有三朵乾枯小白花。",
				"choices": [
					{
						"id": "venerate",
						"label": "虔誠供奉 + 行禮",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 10},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "先靈似乎輕輕點了個頭。",
						},
					},
					{
						"id": "extract_bone",
						"label": "取走骨殖殘片煉化",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "max_hp", "amount": -3},
								{"kind": "permanent_power", "amount": 3},
							],
							"log": "你感到先靈在你體內留下了一道無形的眼神，從此每次出手，他都看著。",
						},
					},
					{
						"id": "observe_legacy",
						"label": "觀察骨殖姿勢",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_legacy",
					},
					{
						"id": "lin_lineage",
						"label": "以靈劍山莊弟子禮認師",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 1},
							],
							"log": "月如跪下時聽見了一個從未見過的聲音輕喚她的名字，那是父親也未曾提起的師伯。",
						},
					},
					{
						"id": "leave",
						"label": "不打擾，繞行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向骨殖低頭一禮，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_legacy": {
					"prompt": "骨殖周圍刻有極小的字：『接得住者，即吾傳人』。",
					"choices": [
						{
							"id": "kneel_accept",
							"label": "跪受傳承",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 2},
								],
								"log": "你跪下接住這份傳承，胸口微微一熱。",
							},
						},
						{
							"id": "decline_take_flowers",
							"label": "婉拒，只取走三朵乾花作念想",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "common"},
									{"kind": "heal", "amount": 8},
									{"kind": "max_hp", "amount": 2},
								],
								"log": "你把三朵乾花輕輕收進胸口的暗袋。",
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
				"prompt": "竹笠下白髮垂胸的老者煮著粗茶。他抬眼掃過你，不發一語。",
				"choices": [
					{
						"id": "seek_teaching",
						"label": "拱手求教",
						"kind_hint": "reward",
						"next": "node_teach",
					},
					{
						"id": "silent_sit",
						"label": "沉默對坐",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [{"kind": "permanent_power", "amount": 2}],
							"log": "老者最後只說了一句：「你的劍會找到答案。」",
						},
					},
					{
						"id": "observe_master",
						"label": "觀察老者來歷",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_recognize",
					},
					{
						"id": "lxy_uncle",
						"label": "問師叔下落",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 10},
							],
							"log": "老者眯眼笑了：「酒劍仙啊……他欠我三壺酒，你見著了替我討。」",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向老者拱手，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_teach": {
					"prompt": "老者放下茶杯，慢慢說：『我能教你三樣，你只能挑一樣。』",
					"choices": [
						{
							"id": "heal_lesson",
							"label": "求療傷之術",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 18},
									{"kind": "max_hp", "amount": 2},
								],
								"log": "老者拈起草葉一貼，涼意透入。",
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
								"log": "老者只說了半句話，你便悟透了剩下那半句。",
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
								"log": "老者將你心頭一道雜念投入爐火，煙散無痕。",
							},
						},
					],
				},
				"node_recognize": {
					"prompt": "你細看老者煮茶的動作——精準到像練過幾十年的招式。他是高人。",
					"choices": [
						{
							"id": "apprentice",
							"label": "拜為一日之師",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "permanent_power", "amount": 1},
									{"kind": "next_battle_buff", "effects": [{"kind": "energy", "amount": 1}]},
								],
								"log": "老者收下你這一拜，把一道罕見的心法說與你聽。",
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
								"log": "老者收下酒，向你抬了抬竹笠。你回頭時，他已不在那裡。",
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
			"lin_yueru": "潭面如鏡，映出比天空更清晰的星辰。月如看著那個倒影中的自己，難得在無人的地方卸下了幾分防備——靈劍山莊的大小姐不能示弱，但月光下的這個倒影，只是個想把父親接回家的女兒。她把那個念頭壓了下去，挺直了脊背。",
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
				"prompt": "夜色凝在潭面，倒映出比山更深的星辰。傳說潭水能洗去俗血，也能引出舊傷。",
				"choices": [
					{
						"id": "bathe",
						"label": "沐月療養",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 15},
								{"kind": "max_hp", "amount": 2},
							],
							"log": "月光滲入水中，你的舊傷如紙浸軟、輕輕化開。",
						},
					},
					{
						"id": "drink",
						"label": "仰天飲一口潭水",
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
							"log": "潭水有兩面——對著光是淨化，對著陰是引誘。",
						},
					},
					{
						"id": "observe_moons",
						"label": "觀察潭中倒影",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_double_moon",
					},
					{
						"id": "zhao_lineage",
						"label": "以靈族水德沐浴歸宗",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal", "amount": 20},
								{"kind": "max_hp", "amount": 5},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "靈兒踏入潭中，月光把水映成銀白，那一刻她聽見了母親的聲音。",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向潭面拱了拱手，留下這份古意給下一個有緣人。"},
					},
				],
			},
			"nodes": {
				"node_double_moon": {
					"prompt": "水中映出的不是天上那輪，是更古老更圓滿的雙月——某個失落仙派的修行之地。",
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
								"log": "雙月之印在你眉心一點即逝，留下一件不屬於這個時代的物事。",
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
								"log": "你坐到月偏才起身，雙腳發麻，胸中卻異常清明。",
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
			"lin_yueru": "月如沒有遲疑，直接走進了廟中。廢棄的山神廟對靈劍山莊的弟子而言是常見的野外歇腳之地，她比任何人都清楚這種地方的靈氣殘留既有危險，也有機緣。她蹲下來取出暗紅符紙仔細查看——字跡不是她所認識的任何一派法脈。",
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
				"prompt": "山神泥像剝落大半，神龕底壓著一道暗紅符紙，墨色仍鮮。",
				"choices": [
					{
						"id": "tear_seal",
						"label": "撕下符紙",
						"kind_hint": "mixed",
						"next": "node_seal",
					},
					{
						"id": "search_shrine",
						"label": "翻找神龕底",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gold", "amount": 18},
								{"kind": "gain_potion"},
							],
							"log": "你從神龕底拖出半個布包，裡面是行旅人留下的乾糧與藥草。",
						},
					},
					{
						"id": "observe_recent",
						"label": "觀察符紙痕跡",
						"kind_hint": "battle",
						"requires": {"observe_token": true},
						"next": "node_recent",
					},
					{
						"id": "anu_purify",
						"label": "以蠱術反解殘符",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "permanent_power", "amount": 1},
								{"kind": "heal", "amount": 5},
							],
							"log": "阿奴用骨針反向書寫，符紙無聲化灰，邪意盡散。",
						},
					},
					{
						"id": "leave",
						"label": "退出廟外",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你決定不淌這趟渾水，退出廟門。"},
					},
				],
			},
			"nodes": {
				"node_seal": {
					"prompt": "符紙在指間發燙，墨字緩緩浮起——這不只是裝飾。",
					"choices": [
						{
							"id": "burn",
							"label": "燒掉破除",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 1},
									{"kind": "gold", "amount": 8},
								],
								"log": "符紙化為一縷青煙，廟中突然安靜了下來。",
							},
						},
						{
							"id": "keep",
							"label": "收入囊中",
							"kind_hint": "mixed",
							"outcome": {
								"kind": "mixed",
								"effects": [
									{"kind": "gain_curse", "curse_id": "xie_yin"},
									{"kind": "gain_card_pool", "pool": "evil"},
								],
								"log": "符紙在你懷裡發出極輕的脈動，像有什麼在低聲笑你的選擇。",
							},
						},
					],
				},
				"node_recent": {
					"prompt": "符紙背面有極淡指印，是個剛入門的修者。你決定等他回來。",
					"choices": [
						{
							"id": "ambush",
							"label": "守株待兔",
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
								"log": "你藏身樑後。半個時辰後，廟門咿呀一聲——",
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
			"lin_yueru": "月如手按劍柄，警惕地打量著黑霧中的身影。靈劍山莊有一句話：見妖不殺，非懦，是智——但也有另一句：與妖立契，非勇，是愚。她深知這道理，但那妖女說的條件確實讓她心動了一瞬，而她最討厭自己被心動。她沉默著，沒有立刻回應。",
			"anu": "阿奴見過苗疆的妖，也和幾個性情溫和的山妖做過交易。但黑霧裡這個不同——她的氣息太涼，不是自然生長的妖，更像是刻意塑造出來的。阿奴沒有動，只是靜靜地打量著對方，等著看她葫蘆裡賣的是什麼藥。",
		},
		"heal": 0, "gain_cost": 4, "power": 4, "power_label": "立契",
		"pact_max_hp_cost": 8, "pact_power": 4,
		"observe_text": "你細細打量這個自稱要與你交易的妖女。她的瞳孔縱裂，瓜子臉看似溫柔，但嘴角扯動的弧度過於精準——是學過人類面部表情的妖物。她身後的黑霧裡有極細的鏈條，像是有什麼東西把她拴在這個位置——她並非自由的存在，這個交易，可能不只是給你力量、收你血肉這麼單純。她在等的，或許是替她解開那條鏈子的人。",
		"observe_effects": [{"kind": "damage", "amount": 2}, {"kind": "gold", "amount": 5}],
		"choices": ["gain_card", "pact", "observe", "leave"],
		"outcomes": {
			"gain_card": "黑霧中遞來一卷黑色符紙，術法的輪廓燒灼在指尖，讓你不舒服卻難以拒絕。那招式有效，但總讓你覺得，它來自某個你最好不要深究的地方。",
			"pact": "妖女抬手，一縷黑絲穿過你的胸口。你感到生機被悄悄抽走一縷，那份損失是真實的，是永久的——但那股力量確實也湧了進來，像一把借來的刀，鋒利，卻不完全屬於你。"
		}
	},
	"forgotten_altar": {
		"title": "棄祭壇",
		"flavor": "風吹過破爛的供品。香爐裡還有一炷未滅的香，灰燼下隱約有字跡。",
		"character_flavors": {
			"li_xiaoyao": "那炷香燒了大半，灰燼細細的一條，像是在用最後的力氣站著。逍遙湊近看見香灰下隱約有字跡，忍不住輕輕吹開——不是法術，更像是留言，是一個普通人感謝神明保佑的心意，歪歪扭扭的字，讓他愣了一下。",
			"zhao_linger": "靈兒在冷石上跪下，裙擺在石板上鋪開。她跪了很久，久到石板的涼意透過薄薄的料子滲進了膝蓋。但她沒有起身，只是靜靜地讓那份涼意蔓延，讓它提醒她：她是真實的，她在這裡，她的祈求是真的。點燃備用香的時候，她的指尖略帶顫抖，不是因為寒冷。",
			"lin_yueru": "月如打量著廢棄的祭壇，目光落在那炷未滅的香上。靈劍山莊從不輕視神明——父親林天南說：『劍者，也是人，人者，也要敬天地。』月如在祭壇前做了個簡單的行禮，才去查看那些殘留的符跡。",
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
				"prompt": "神龕角落藏一個小布包，香爐裡還有一炷未滅的香。",
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
							"log": "香煙繞身，全隊體內一陣溫熱。",
						},
					},
					{
						"id": "take_bundle",
						"label": "取走布包離開",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "gold", "amount": 10},
								{"kind": "next_battle_buff", "effects": [{"kind": "weak", "amount": 1}]},
							],
							"log": "你拿走布包。離開時，背上有一道淡淡的視線跟了你幾步。",
						},
					},
					{
						"id": "observe_inscription",
						"label": "觀察神龕底刻字",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_inscription",
					},
					{
						"id": "disturb_incense",
						"label": "擾動香爐召喚守靈",
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
							"log": "香爐應聲而倒，一道劍光自神龕之後直撲你面門——",
						},
					},
					{
						"id": "zhao_superdu",
						"label": "以靈族超渡禮為母子兩魂解結",
						"kind_hint": "reward",
						"requires": {"character": ["zhao_linger"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal_party", "amount": 10},
							],
							"log": "靈兒念完最後一句咒文，香煙化作一個輕薄的人形，向她拱手散去。",
						},
					},
					{
						"id": "leave",
						"label": "離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你在祭壇前一禮，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_inscription": {
					"prompt": "神龕底刻著『願後來者亦能在此片刻平靜』。香灰下還有一封七十年前的母親留言。",
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
								"log": "你輕聲念完那封信，香爐中的火苗安靜地搖了一下。",
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
								"log": "你只是將信折好放回原處。離開時，神龕底似乎多了一件給有緣人的小物。",
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
			"lin_yueru": "月如在古戰場中走得很慢，眼神認真地打量每一面旌旗、每一把插在土裡的折斷武器。靈劍山莊藏有一部《古戰史》，記載各個時期武林的血戰始末——這個戰場的規模，有幾分像書中某一頁的記載。她彎腰拾起一枚殘破鐵甲片，放在掌心看了一會兒。",
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
				"prompt": "乾涸血土上插著無數殘旌，風過時像有人低鳴。",
				"choices": [
					{
						"id": "pickup_banner",
						"label": "撿起旌旗碎片祭英靈",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "heal", "amount": 5},
							],
							"log": "千年的鐵血沿著你的手腕緩緩流入心口。",
						},
					},
					{
						"id": "summon_souls",
						"label": "試圖喚醒亡靈聽其遺言",
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
							"log": "你大喝一聲祭起殘旌——一個披甲身影自土中升起。",
						},
					},
					{
						"id": "observe_unfinished",
						"label": "觀察殘劍刻字",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_unfinished",
					},
					{
						"id": "lin_lineage",
						"label": "辨認旌旗為靈劍山莊歷代遺名",
						"kind_hint": "reward",
						"requires": {"character": ["lin_yueru"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 2},
							],
							"log": "月如在父親提過的那柄劍前跪下，雙手取劍——一道前輩劍意流入她心中。",
						},
					},
					{
						"id": "wraith_duel",
						"label": "與遺地之鬼對搏奪魂",
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
							"log": "你拔劍直指土心。地底有什麼回應了你——",
						},
					},
					{
						"id": "leave",
						"label": "默禮離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你向戰場深深一禮，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_unfinished": {
					"prompt": "某柄斷劍刻著『未竟』二字——劍主臨終的遺願。",
					"choices": [
						{
							"id": "carry_will",
							"label": "拾起斷劍承志",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_card_pool", "pool": "rare"},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你把斷劍別在腰間，許了一個無聲的諾言。",
							},
						},
						{
							"id": "incense_for_him",
							"label": "為他補插一柱香",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "heal", "amount": 8},
								],
								"log": "香煙繞著斷劍打了一個圈，最後落在你的肩頭。",
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
			"lin_yueru": "月如看著爐火，想起了靈劍山莊後山的煉器房——那裡常年爐火不熄，用來磨礪劍刃而非煉藥，但那熱氣蒸騰的感覺如出一轍。靈劍山莊的弟子從小就在高溫和壓力中鍛煉意志。她走近爐子，用劍尖挑起那張藥方，仔細查看。",
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
				"prompt": "青石台上爐子還燒著，藥香混著焦味。爐口殘留半粒未完成的丹。",
				"choices": [
					{
						"id": "swallow_half_pill",
						"label": "服下半粒丹",
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
							"log": "你嚥下半粒丹——",
						},
					},
					{
						"id": "complete_refine",
						"label": "嘗試完成煉丹",
						"kind_hint": "battle",
						"next": "node_refine",
					},
					{
						"id": "observe_secret",
						"label": "觀察爐口殘氣",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_secret",
					},
					{
						"id": "anu_refit",
						"label": "辨認九味藥配方為苗疆配伍",
						"kind_hint": "reward",
						"requires": {"character": ["anu"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_potion"},
								{"kind": "gain_potion"},
								{"kind": "gain_card_pool", "pool": "character"},
							],
							"log": "阿奴聞出最關鍵那兩味是南疆毒草，重新配比，一爐成丹。",
						},
					},
					{
						"id": "leave",
						"label": "不碰，離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你深吸一口藥香，繼續上路。"},
					},
				],
			},
			"nodes": {
				"node_refine": {
					"prompt": "你照爐壁上的『煉魂篇』殘卷補火——焰光突起，爐底似有什麼被驚動。",
					"choices": [
						{
							"id": "push_fire",
							"label": "強行續火",
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
								"log": "爐中一縷火靈幻化現形！",
							},
						},
						{
							"id": "pull_back",
							"label": "退火收功",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_potion"},
									{"kind": "permanent_power", "amount": 1},
								],
								"log": "你迅速抽手，火靈未及成形便沉回爐底，留下一粒成丹。",
							},
						},
					],
				},
				"node_secret": {
					"prompt": "前主人嘗試的是『以己為材』的煉魂之術，他可能沒走出這裡。",
					"choices": [
						{
							"id": "collect_remains",
							"label": "收殮前主人遺物",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "max_hp", "amount": 3},
								],
								"log": "你在爐邊找到一塊未化盡的骨片，鄭重地收了起來。",
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
								"log": "殘卷化為紙灰，你心中某道執念也跟著鬆動。",
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
			"lin_yueru": "月如把手按在劍上，穩步走入霧林。靈劍山莊有一門功課叫做「亂境心法」，訓練弟子在視覺干擾下保持平衡的心態——這片霧林，對她而言更像一道考驗，而非一場威脅。越深入，她的心跳反而越清晰有力，像是劍心在此刻得到了磨礪。",
			"anu": "阿奴在霧林裡走得很安靜，幾乎沒有腳步聲。她從小在南詔的密林中長大，習慣了和各種存在共處——那些在彼端注視你的眼睛，不見得都是惡意的，有些只是好奇，有些只是寂寞。她輕聲用苗語問了一句：「你們想要什麼？」",
		},
		"heal": 0, "gain_cost": 3, "power": 5, "power_label": "借膽",
		"gamble_win_power": 5, "gamble_lose_damage": 10,
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
				"prompt": "霧林深處樹影晃動，有什麼在彼端注視著你。",
				"choices": [
					{
						"id": "quick_cross",
						"label": "加快腳步穿越",
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
							"log": "你壓低身形快步穿越，霧中目光緊隨——",
						},
					},
					{
						"id": "brave_charge",
						"label": "借膽硬闖",
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
							"log": "霧中浮出一隻金瞳狐影撲來——",
						},
					},
					{
						"id": "observe_directions",
						"label": "觀察霧中眼睛分佈",
						"kind_hint": "reward",
						"requires": {"observe_token": true},
						"next": "node_directions",
					},
					{
						"id": "lxy_sword_guide",
						"label": "以劍靈感應指路",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "heal", "amount": 8},
							],
							"log": "「往這邊走。」劍靈在他腦中冷冷地說，「別再亂晃了你。」",
						},
					},
					{
						"id": "leave",
						"label": "退回原路",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你決定不冒險，從原路退出霧林。"},
					},
				],
			},
			"nodes": {
				"node_directions": {
					"prompt": "北方氣息平和、南方一棵老樹高處有捕食者。你看清了。",
					"choices": [
						{
							"id": "north_safe",
							"label": "走北線安全脫困",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "heal", "amount": 10},
									{"kind": "gold", "amount": 8},
								],
								"log": "你沿著北線走出霧林。陽光重新落到肩上。",
							},
						},
						{
							"id": "south_ambush",
							"label": "走南線伏擊那隻怪物",
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
								"log": "你繞到老樹下方，第一劍刺向那雙黃眼——",
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
			"li_xiaoyao": "逍遙站在符紋上，腳底傳來的震動讓他想起了師叔說過的話：『仙人不是傳說，只是走遠了而已。』他努力回想那句話的語氣，不像是開玩笑，更像是在說一件親眼見過的事。他低下頭，看著腳下那些褪色的符紋，想像著它們曾經燃亮的樣子。",
			"zhao_linger": "靈兒踩上符紋，震動從腳底傳入，沿著腿骨一路上升，抵達腰脊，又繼續往上——一種非常細微、卻無法忽視的顫動，讓她閉上眼睛，站定不動。她站了很久，讓那振動慢慢流遍全身，在心裡問它：你們，和我的先人，是否認識？它再次震動，像是回答，也像是一個久違了的擁抱，終於抵達。",
			"lin_yueru": "月如踩著符紋，感受腳底那微微的震動。靈劍山莊藏書閣裡有幾卷殘篇，記載了仙人遺址的探訪規矩：不強行汲取，不輕易破壞，只是感受。她深吸一口氣，放開了對力量的主動追求，讓那些古意自然地流過自己，像水過石縫。",
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
				"gain_card": "逍遙踩上符紋的瞬間，腳底傳來的震動和他學御劍術第一年的某次冥想相似——那是師叔指導他「以身合天」的那一晚。符紋認得他這個血脈中的劍仙之氣。一道精煉版的「仙風雲體術」在他腦中徐徐展開，這不是新東西，是這位仙人替他把已有的招式擦得更亮了一些。"
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
				"prompt": "地上符紋雖褪色，踩上仍有微微震動——這位仙人未走，只是入定。",
				"choices": [
					{
						"id": "accept_legacy",
						"label": "跪受傳承",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "permanent_power", "amount": 2},
								{"kind": "max_hp", "amount": 3},
								{"kind": "gain_card_pool", "pool": "rare"},
							],
							"log": "你跪在符紋中央，一道古老的意念輕拂你的眉心。",
						},
					},
					{
						"id": "invade_inner",
						"label": "闖入內陣強奪法",
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
							"log": "守陣餘魂自地下浮起——",
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
						"label": "以「仙風雲體術」入陣共鳴",
						"kind_hint": "reward",
						"requires": {"character": ["li_xiaoyao"]},
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "gain_card_pool", "pool": "character"},
								{"kind": "permanent_power", "amount": 2},
								{"kind": "max_hp", "amount": 3},
							],
							"log": "符紋認出他的血脈，把一道精煉版的招式直接刻進他的識海。",
						},
					},
					{
						"id": "leave",
						"label": "默禮繞行",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你不打擾這位前輩的修行，繞道而過。"},
					},
				],
			},
			"nodes": {
				"node_meditation": {
					"prompt": "震動的頻率呼應你的呼吸——這位仙人此刻在以一種你不懂的方式『仍在修行』。",
					"choices": [
						{
							"id": "sync_breath",
							"label": "同步呼吸感悟",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "upgrade_random"},
									{"kind": "permanent_power", "amount": 1},
									{"kind": "heal", "amount": 8},
								],
								"log": "你閉目調息與符紋同頻，某道招式自行重組。",
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
								"log": "你只取走最外圍那塊不影響陣勢的玉，留下深拜一禮。",
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
			"lin_yueru": "月如打量著符文，試圖以靈劍山莊所學的符法知識加以解讀，但沒有成功——這是她從未接觸過的文字體系。她想到了靈兒，心中對這個溫柔的靈族少女又多了幾分敬意：帶著這樣龐大而陌生的傳承，還能走得如此平靜，不是一件容易的事。",
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
		}
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
		}
	},
	"tavern_acquaintance": {
		"title": "酒館舊識",
		"flavor": "熟悉的酒香飄來，掌櫃正在擦著杯子。看見你走進來，他只是點點頭，像是見過無數次一樣。",
		"character_flavors": {
			"li_xiaoyao": "逍遙一走進酒館，鼻子就先放鬆了。熟悉的酒香、熱食的氣味、人聲的嘈雜——這和餘杭的小客棧沒什麼兩樣，讓他的肩膀不自覺地鬆下來。掌櫃看見他，點了個頭，動作和外婆看見常客時一模一樣。有些東西是相通的，走到哪裡都一樣。",
			"zhao_linger": "靈兒在酒館裡坐定，過了一會兒，感到有人在看她。是角落的一個年輕人，視線一觸即縮，但不到片刻又飄回來，有些僵，有些難以置信。她假裝沒有注意到，端起茶盞喝了一口，但嘴角忍不住微微上揚了——被這樣直白地看著，說不上舒不舒服，只是很難完全不在意。",
			"lin_yueru": "月如在酒館裡環顧一圈，選了一個背靠牆壁、正對門口的位置坐下——靈劍山莊的訓練讓她在任何場合都保持警覺。但這個酒館氣氛平和，掌櫃面善，她判斷沒有威脅，才允許自己點了一碗熱湯，靠著椅背，這是她難得的片刻放鬆。",
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
				"upgrade": "月如向老劍客敬酒，得到的回應比她預期的多——老人放下酒杯，用兩根手指在桌上比劃了一個劍式。「靈劍山莊？你父親林天南是我師侄。」他說，「他當年的這一招，我替他改過。你要不要試試？」月如的手停在酒杯邊，沒有立刻回應，但她的眼神已經告訴了老人答案。"
			},
			"anu": {
				"power": "阿奴坐在角落聽商旅閒談，他們講到南疆某條山路，最近常有蠱師出沒。她的耳尖動了一下——是家鄉那邊的事。她沒有插話，只是把這些訊息記在心裡。離開時，她在桌上留下一個小小的銀鈴，是苗疆人傳遞「我聽到了」的信物，希望某個聽得懂的人能收下。"
			}
		},
		"outcomes": {
			"heal": "掌櫃端來一碗熱湯，不說話，就那樣放在你面前。喝完，渾身的疲憊比預期輕了許多——有時候，不問緣由的善意，是最好的藥。",
			"upgrade": "你向角落的老劍客敬了一杯酒。他點頭，低聲說了半句話——你手中那道招式從此不同了。你不知道他是誰，他也沒有說，但那半句話，你記住了。",
			"power": "你傾耳聽著旅客談論路上的遭遇，某個細節讓你想起一種早被遺忘的應變之道。有時候，最有用的東西，藏在最普通的話語裡。"
		}
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
		"heal": 0, "gain_cost": 6, "power": 4, "power_label": "承志",
		"observe_text": "你仔細看那些斷劍。它們插的方向並非雜亂——劍尖全部指向北方某個遙遠的點，那是中原劍道的源頭之一。每一把劍上都刻著名字，有的姓氏你認得，有的已經風化模糊。最讓你動容的是其中一柄劍鞘上刻著「未竟」二字，像是劍主臨終前最後的心意——他知道自己走不到，但希望後人能替他走完。",
		"observe_effects": [{"kind": "power", "amount": 2}],
		"choices": ["power", "upgrade", "gain_card", "observe", "leave"],
		"character_outcomes": {
			"lin_yueru": {
				"gain_card": "月如蹲在劍冢中央，仔細看著那些斷劍上的姓氏——她認出了好幾個，是靈劍山莊歷代的遺名。父親林天南曾對她說：「劍冢不是墓，是接力的起點。」她在父親提過的那柄劍前跪下，雙手取劍——一道前輩留下的劍意化作劍譜流入她的心中，那是只有山莊弟子才能接收到的傳承。"
			}
		},
		"outcomes": {
			"power": "你在劍冢間站立片刻。那些英靈的殺伐意志悄悄從劍身傳入，填滿了你招式裡每一個空隙——那是別人用一生走出來的，此刻，傳到你的手上。",
			"upgrade": "某柄斷劍的裂縫上刻著一段心法，如同那位劍客最後的遺言。你用它修正了自己招式中的瑕疵，同時也想起了那個人，最後獨自插劍於此的模樣。",
			"gain_card": "你從劍冢拔出一柄斷劍，指尖傳來一套陌生的劍法輪廓，隨即融入了你的招式記憶。那劍冢因此少了一把劍，你希望它原來的主人，不會介意。"
		}
	},
	"miao_healer": {
		"title": "苗疆藥師",
		"flavor": "草棚內藥材懸掛成排，一位苗疆老藥師坐在角落，目光精準地在你身上掃了一圈，未言先知。",
		"character_flavors": {
			"li_xiaoyao": "逍遙看見那一排排懸掛的藥材，鬆了一口氣——有藥師，意味著有得救的機會。老藥師打量他的方式讓他想起了外婆看診時的神情，眼神銳利，但帶著一種不動聲色的善意。「前輩，我身上有幾處舊傷，比較麻煩的那種。」他覺得直接說最好。",
			"zhao_linger": "老藥師不說話，只是抬手示意靈兒伸腕。他的指尖冷而準確，按上她的脈搏就不動了，靜靜地讀。靈兒坐著，看著那雙滿是藥材染色的老手握著自己細白的手腕，想說什麼，卻忍住了。她的脈動是真實的，她的血在他指下流著，這讓她覺得有些暴露，又說不清為什麼反而覺得安心。",
			"lin_yueru": "月如進了草棚，打量了老藥師一眼——藥材的排列有條有理，配伍邏輯清晰，是正統的藥理，不是旁門左道。靈劍山莊的弟子也學過基礎藥理；她決定信任這位老藥師，把身上幾處沒有處理好的舊傷一一列出，語氣像是向師傅匯報功課。",
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
		}
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
			"gain_card": "月如以靈劍山莊大小姐的身份正式教導少年起手式。少年眼神發亮，把每一個動作都看入眼裡。臨別時，他鞠了個深躬，從懷中取出一卷家傳的劍譜殘頁回贈：「這是我祖父留下的，但他說我練不來這一招。大姐姐，你應該用得上。」她接過殘頁，意外地從中讀出了一道新的劍意。"
		}
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
		}
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
		}
	},
	"yangzhou_officer": {
		"title": "揚州府緝盜",
		"flavor": "揚州城內人聲鼎沸，一個蒙面黑影與你擦身而過，一個沉甸甸的包袱掉在你腳邊。此時官差已在後方大喊：「站住！」",
		"character_flavors": {
			"li_xiaoyao": "逍遙低頭看著腳邊那個包袱，又抬頭看向喊著「站住」的官差，內心迅速地計算了一下局勢。他記得餘杭的縣老爺——那種人見著嫌疑犯從不多問，就算你說了真相，他也不一定信。但他更記得，看客已經不少了，而他需要在下一刻做出決定。",
			"zhao_linger": "官差追過來，抬眼一看，腳步在靈兒身上停了一秒。她看見他愣住，嘴張了張，沒立刻說話——那一秒足夠她開口了。她語氣平靜，解釋得清楚，聲音溫而穩，讓那個年輕官差回了神。她心知肚明那半秒發生了什麼，也知道自己利用了它，只是把那個念頭輕輕壓下去，先把眼前的事情解決。",
			"lin_yueru": "月如把包袱踢了一腳，確認了它的重量——不輕，裡面有些值錢的東西。她用餘光掃了一眼官差，再掃了一眼遠處消失的黑影，心裡做了個判斷：這是別人的麻煩，但已經變成她的麻煩了。好，那就用靈劍山莊的方式解決——乾脆，清楚，不拖泥帶水。",
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
		}
	},
	"lingmiao": {
		"title": "靈廟顯靈",
		"flavor": "路旁矗立著一座飽經風霜的古靈廟。廟堂正中，一盞油燈的火焰無風自動，在幽暗中散發著柔和的金光。傳說此廟能以靈符超渡亡魂、喚回生機。",
		"character_flavors": {
			"li_xiaoyao": "逍遙在廟門前站了很久。那盞無風自動的油燈讓他想起了師叔講過的一個傳說，說有些廟宇是天地的節點，連著生死兩界。他向來不迷信，但今天他願意相信這個說法——因為此刻，他確實想要能有什麼奇蹟發生。他拍了拍衣襟，整了整姿態，走入廟中。",
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
		}
	},
	"xianling_shrine": {
		"title": "仙靈島水月宮",
		"flavor": "穿過桃花瘴，一座縹緲的宮殿坐落在蓮花池中央。池畔置有一尊女媧神像，四周白蓮盛開，靈氣升騰。",
		"character_flavors": {
			"li_xiaoyao": "逍遙穿過桃花瘴，第一眼看見那座宮殿時，愣了足足有三秒鐘。「這是……真的嗎？」他揉了揉眼睛，宮殿還在，蓮花還在，連那尊女媧神像都是真的。他走近，感覺有什麼熟悉的東西在周圍的空氣裡——那種感覺讓他有點說不出話，只能站在那裡靜靜地深呼吸。",
			"zhao_linger": "靈兒走到蓮花池邊，脫下外袍，輕輕踏入水中。水是溫的，漫過腳踝，漫過膝蓋，裙擺在水面浮起，像白色的蓮瓣。月光從宮頂透下來，落在她的肩膀上，落在水面，落在她沒入水中的那半截身體上。她閉上眼睛，把雙臂張開，以靈族歸宗的姿態在蓮池中站立，任憑那溫柔的水繞著她轉。",
			"lin_yueru": "月如走進水月宮，謹慎地觀察四周。這裡的靈氣純淨得不像人間，但也沒有威脅的氣息。她在蓮花池旁站立，覺得這個地方讓她的劍心意外地靜——靈劍山莊教她『靜中求銳』，但很少有地方能真正讓她做到這一點。水月宮，是其中之一。",
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
		}
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
		}
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
		}
	},
	# ── PAL1 名場面（角色情感深度互動） ─────────────────────────────────
	"jianling_whisper": {
		"title": "劍靈低語",
		"flavor": "腰間劍鞘忽然微微震動，像是劍中有什麼在試圖說話。你低頭凝視劍身——一抹紅光在劍面上一閃即逝，似有似無，像個害羞又驕傲的影子。",
		"character_flavors": {
			"li_xiaoyao": "「喂！」一個熟悉到讓他心裡某處立刻揪一下的聲音在他耳邊響起，「敢把我留在劍裡這麼多天不理人？膽子越來越大了啊，李逍遙。」逍遙的腳步停住，連呼吸都頓了一下。他沒抬頭，怕自己一抬頭就會做出什麼蠢事。「……抱歉。」他終於說，聲音比想像中還要啞一點。劍中那道紅光顫了顫，半天才憋出一句：「哼，知錯就好。」",
			"zhao_linger": "靈兒感應到劍中那縷紅光，眨了眨眼。那不是惡意，是某種強烈的、固執的、屬於另一個女子的存在。她蹲下，輕輕觸了一下劍身：「你好，我是靈兒。我能感受到你。你是這把劍裡的靈嗎？」劍中那縷紅光定了定，似乎沒料到自己被認出來，許久才回了個淡淡的閃爍。",
			"lin_yueru": "月如停下腳步，劍意微微一凜——那不是敵意，是另一道劍靈在向她致敬。她認真地把佩劍橫在胸前，回了一個劍者之禮：「林靈劍山莊弟子月如，向前輩問好。」劍中紅光微微一晃，像是被這個正式的禮數逗笑了，回了個輕快的閃爍。",
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
		}
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
			"lin_yueru": "月如停下，警戒地打量那個少年。但對方沒有敵意，只是吹著笛，眼神平靜。靈劍山莊教過她認識各地方的服飾——少年身上是南疆的紋路，和她身邊那個沉默的同伴是同一族。她退到一旁，把這個場合留給該說話的人。",
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
		}
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
				"power": "逍遙與少年對招了三十回合。少年的劍法稚嫩，但每一劍都帶著一種他似曾相識的固執。逍遙忽然懂了——這個眼神他見過，這個劍意他用過。「你叫唐鈺對吧？」他停下劍，「記住你今天的這一招——這是我師叔教我的時候，反過來教給我的東西。」"
			}
		},
		"outcomes": {
			"power": "你與少年切磋一場。他的劍意還在萌芽，但勝負之間，那份純粹的鬥志反而讓你血脈共鳴，丹田裡多了幾分當初剛入劍道時的銳意。離別時，他向你深深一禮，連名字都沒問。",
			"upgrade": "你指點少年的劍法。少年認真地聽，當你示範到第三次時，他忽然反問你一個你也沒想過的問題——你愣了一下，那一刻，你自己手裡某道招式的瑕疵，竟在這個少年笨拙的問題裡，自己揭露了。",
			"gain_card": "你陪少年練劍直到天黑。臨別時，他從懷裡取出一卷殘破的劍譜：「這是我祖父給我的，但我練不來。前輩拿著吧，總比留在我手裡浪費好。」你接過那卷劍譜，覺得這個少年比他自己以為的，要珍貴得多。"
		}
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
				"prompt": "素衣女子守著藥爐與床榻。書生命懸一線，她的眼神卻只有溫柔，沒有半分為自己打算的意思。你能做些什麼？",
				"choices": [
					{
						"id": "gather_herbs",
						"label": "上山替她採齊草藥",
						"kind_hint": "reward",
						"outcome": {
							"kind": "reward",
							"effects": [
								{"kind": "heal_party", "amount": 8},
								{"kind": "gain_card_pool", "pool": "common"},
							],
							"log": "你跑遍山谷採回奇花異草。女子煎出新一鍋仙釀，書生的青黑褪了一分。她對你深深一禮，那縷藥香也替你撫平了倦意。",
						},
					},
					{
						"id": "share_vitality",
						"label": "分一縷真氣助壓毒性",
						"kind_hint": "mixed",
						"outcome": {
							"kind": "mixed",
							"effects": [
								{"kind": "max_hp", "amount": -4},
								{"kind": "permanent_power", "amount": 2},
							],
							"log": "你渡出一縷真氣護住書生心脈。你虛了幾分，卻像看懂了什麼——有些力量，是給出去之後才更強的。",
						},
					},
					{
						"id": "observe_truth",
						"label": "細看那女子的來歷",
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
							"log": "逍遙默默替她守了一夜爐火。他幫不上更多，但他記得這份情義——人能為人做到這一步，他也想成為那樣的人。心境通透，劍意更沉。",
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
							"log": "靈兒指尖靈光流轉，纏魂絲一寸寸鬆開。女子睜大眼：『你……也不是凡人。』靈兒笑了笑，沒說自己是誰，只把這份溫柔還給了她。",
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
							"log": "月如想起那隻蜘蛛精，眼神一冷。她沒有去尋仇——因為斬了毒娘子，書生便再無解藥。她把這口氣壓進劍裡，留待真正該出手的時候。",
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
							"log": "阿奴調了一帖苗疆解毒散摻進仙釀，書生的青黑褪了一分。女子怔怔看著她：『妳……懂這個。』阿奴點頭：『毒和情，有時候是同一種東西。』",
						},
					},
					{
						"id": "leave",
						"label": "不打擾，悄然離去",
						"kind_hint": "neutral",
						"outcome": {"kind": "neutral", "effects": [], "log": "你沒有打擾這一屋的執念，輕輕退了出去。藥香在身後久久不散。"},
					},
				],
			},
			"nodes": {
				"node_truth": {
					"prompt": "火光照清了真相——女子的影子是一對蝶翼。她是千年蝶妖彩依，為救曾搭救她的書生，甘願散盡道行、換他十年陽壽。她迎著你的目光，並不躲避。",
					"choices": [
						{
							"id": "keep_secret",
							"label": "替她守住這個秘密",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "gain_relic_pool", "pool": "uncommon"},
									{"kind": "heal_party", "amount": 6},
								],
								"log": "你點點頭，什麼都沒問。彩依眼裡閃過感激，往你手裡塞了一小瓶仙釀：『路上……或許用得著。』",
							},
						},
						{
							"id": "ask_worth",
							"label": "問她：「值得嗎？」",
							"kind_hint": "reward",
							"outcome": {
								"kind": "reward",
								"effects": [
									{"kind": "permanent_power", "amount": 2},
									{"kind": "gain_card_pool", "pool": "uncommon"},
								],
								"log": "她想了很久，笑了：『千年修行，換他十年陽壽——若再選一次，我還是會這樣選。』那一刻你像被什麼擊中，招式裡多了一分不顧自身的決絕。",
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
		"heal": 0, "gain_cost": 0, "power": 4, "power_label": "立誓",
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
		}
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
