class_name MapGenerator
extends RefCounted

const EVENT_VARIANTS: Array[String] = ["shrine", "spring", "talisman_cache", "treasure_chest", "ancestor_relic", "wandering_sage", "moonlit_pool", "broken_temple", "yokai_pact", "forgotten_altar", "ancient_battlefield", "alchemy_furnace", "ghost_forest", "immortal_ruins", "spirit_clan_ruins", "baiyue_altar", "tavern_acquaintance", "sword_tomb", "miao_healer", "shilipo_sword_god", "drunk_swordsman", "yinlong_cave", "yangzhou_officer", "xianling_shrine", "lingmiao", "flower_thief", "flower_spirit",
	# PAL1 名場面（角色情感深度）
	"jianling_whisper", "aqi_reunion", "tangyu_sparring", "jiang_waner_grief", "caiyi_butterfly",
	"bijian_zhaoqin",
	# Event Redesign Phase 4：稀有奇遇（event_pick_weight 對其降權）
	"shushan_vault"]
const ELITE_BASE_CHANCE: float = 0.30  # 中段每列出現精英的基礎機率（A1 起每級 +0.25）
const FEMALE_ONLY_VARIANTS: Array[String] = ["flower_thief"]
const MALE_ONLY_VARIANTS: Array[String] = ["flower_spirit"]
const FEMALE_CHARACTER_IDS: Array[String] = ["zhao_linger", "lin_yueru", "anu"]
const MALE_CHARACTER_IDS: Array[String] = ["li_xiaoyao"]
const BLACK_SHOP_CHANCE: float = 0.25
const MIN_SHOPS_PER_MAP: int = 2       # 每張地圖至少要有的商店節點數
const MERCHANT_EVENT_CHANCE: float = 0.18  # 奇遇節點其實是行腳商人（進入後開商店）的機率
# 每幕普通戰鬥節點的敵人數量加權表。count 為從 pool 中抽取的敵人數。
const ACT_ENCOUNTERS: Dictionary = {
	1: [{"count": 1, "weight": 4}, {"count": 2, "weight": 1}],
	2: [{"count": 1, "weight": 3}, {"count": 2, "weight": 2}],
	3: [{"count": 1, "weight": 2}, {"count": 2, "weight": 3}],
	4: [{"count": 1, "weight": 1}, {"count": 2, "weight": 3}, {"count": 3, "weight": 1}],
	5: [{"count": 1, "weight": 1}, {"count": 2, "weight": 2}, {"count": 3, "weight": 2}],
	6: [{"count": 1, "weight": 1}, {"count": 2, "weight": 2}, {"count": 3, "weight": 3}],
	7: [{"count": 1, "weight": 1}, {"count": 2, "weight": 2}, {"count": 3, "weight": 3}],
	8: [{"count": 2, "weight": 2}, {"count": 3, "weight": 3}],
}
const MIN_NORMAL_ROW_COUNT: int = 9
const MAX_NORMAL_ROW_COUNT: int = 11
const MIN_ROW_OPTIONS: int = 3
const MAX_ROW_OPTIONS: int = 6
const SECONDARY_SPECIAL_TYPES: Array[String] = ["event", "rest", "shop"]
const EXTRA_SPECIAL_TYPES: Array[String] = ["battle", "event", "rest", "shop"]

static func _has_female_character(character_ids: Array[String]) -> bool:
	for id: String in character_ids:
		if FEMALE_CHARACTER_IDS.has(id):
			return true
	return false

static func _has_male_character(character_ids: Array[String]) -> bool:
	for id: String in character_ids:
		if MALE_CHARACTER_IDS.has(id):
			return true
	return false

# Event Redesign（Phase 4）：依稀有度加權挑事件。rare 事件權重 1，common 權重 5，
# 讓「能重塑整場 run」的稀有奇遇不常出現、遇到時更有記憶點。
static func event_pick_weight(variant: String) -> int:
	match EventData.rarity_of(variant):
		"rare":
			return 1
		"uncommon":
			return 3
		_:
			return 5

static func _pick_event_variant(event_pool: Array[String]) -> String:
	if event_pool.is_empty():
		return "shrine"
	var total: int = 0
	for v: String in event_pool:
		total += event_pick_weight(v)
	if total <= 0:
		return event_pool[randi_range(0, event_pool.size() - 1)]
	var roll: int = randi_range(0, total - 1)
	for v: String in event_pool:
		roll -= event_pick_weight(v)
		if roll < 0:
			return v
	return event_pool[event_pool.size() - 1]

static func _build_event_pool(has_female: bool, has_male: bool) -> Array[String]:
	var pool: Array[String] = []
	for v: String in EVENT_VARIANTS:
		if FEMALE_ONLY_VARIANTS.has(v) and not has_female:
			continue
		if MALE_ONLY_VARIANTS.has(v) and not has_male:
			continue
		pool.append(v)
	return pool

static func choose_enemies_for_act(act: int, pool: Array[EnemyData]) -> Array[EnemyData]:
	if pool.is_empty():
		return []
	var table: Array = (ACT_ENCOUNTERS.get(act, ACT_ENCOUNTERS[1])) as Array
	var total_weight: int = 0
	for entry: Variant in table:
		total_weight += int((entry as Dictionary).get("weight", 1))
	var roll: int = randi_range(0, max(0, total_weight - 1))
	var count: int = 1
	var acc: int = 0
	for entry: Variant in table:
		acc += int((entry as Dictionary).get("weight", 1))
		if roll < acc:
			count = int((entry as Dictionary).get("count", 1))
			break
	count = min(count, pool.size())
	var shuffled: Array[EnemyData] = pool.duplicate()
	shuffled.shuffle()
	var result: Array[EnemyData] = []
	for i: int in range(count):
		result.append((shuffled[i] as EnemyData).clone())
	# 群怪：若選中的怪有 swarm_size，整組換成 N 隻同類（如鼠妖成群），上限 3
	for e: EnemyData in result:
		if e.swarm_size > 1:
			var n: int = min(e.swarm_size, 3)
			var swarm: Array[EnemyData] = []
			for _i: int in range(n):
				swarm.append(e.clone())
			return swarm
	return result

static func generate(normal_enemies: Array[EnemyData], bosses: Array[EnemyData], character_ids: Array[String] = [], act: int = 1, elite_enemies: Array[EnemyData] = [], ascension: int = 0) -> Array[Array]:
	var has_female: bool = _has_female_character(character_ids)
	var has_male: bool = _has_male_character(character_ids)
	var event_pool: Array[String] = _build_event_pool(has_female, has_male)
	var choices: Array[Array] = []
	var normal_row_count: int = randi_range(MIN_NORMAL_ROW_COUNT, MAX_NORMAL_ROW_COUNT)
	var allow_elite: bool = not elite_enemies.is_empty()
	for row_index: int in range(normal_row_count):
		var row: Array[Dictionary] = []
		var row_size: int = randi_range(MIN_ROW_OPTIONS, MAX_ROW_OPTIONS)
		var node_types: Array[String] = _build_row_types(row_index, normal_row_count, row_size)
		if allow_elite:
			_inject_elite(node_types, row_index, normal_row_count, ascension)
		for node_index: int in range(row_size):
			var node_type: String = String(node_types[node_index])
			row.append(_make_map_node(node_type, node_index, normal_enemies, event_pool, act, elite_enemies))
		choices.append(row)
	if not bosses.is_empty():
		var chosen_boss: EnemyData = bosses[randi() % bosses.size()]
		var boss_row: Array[Dictionary] = []
		boss_row.append({"type": "boss", "enemy": chosen_boss.clone(), "index": 0, "connects": []})
		choices.append(boss_row)
	_add_random_map_connections(choices)
	_enforce_shop_rules(choices, event_pool)
	return choices

# 商店規則（連線建立後執行）：
# 1. 不要兩個商店節點串連（前後列有直接連線）→ 下游商店降級為奇遇。
# 2. 每張地圖至少 MIN_SHOPS_PER_MAP 個商店 → 不足時把 battle/event 節點轉成商店
#    （避開與既有商店相鄰的位置，維持規則 1）。
static func _enforce_shop_rules(choices: Array[Array], event_pool: Array[String]) -> void:
	# 規則 1：拆掉 shop→shop 串連
	for row_index: int in range(choices.size() - 1):
		var row: Array = choices[row_index]
		var next_row: Array = choices[row_index + 1]
		for node_v: Variant in row:
			var node: Dictionary = node_v as Dictionary
			if String(node.get("type", "")) != "shop":
				continue
			for j_v: Variant in (node["connects"] as Array):
				var j: int = int(j_v)
				if j < 0 or j >= next_row.size():
					continue
				var nxt: Dictionary = next_row[j] as Dictionary
				if String(nxt.get("type", "")) == "shop":
					nxt["type"] = "event"
					nxt.erase("black_market")
					nxt["event_variant"] = _pick_event_variant(event_pool)
	# 規則 2：補足最少商店數
	var shop_count: int = 0
	for row_v: Variant in choices:
		for node_v2: Variant in (row_v as Array):
			if String((node_v2 as Dictionary).get("type", "")) == "shop":
				shop_count += 1
	if shop_count >= MIN_SHOPS_PER_MAP:
		return
	var candidates: Array = []  # [row_index, node_index]
	for row_index2: int in range(1, choices.size()):  # 第一列維持全戰鬥
		var row2: Array = choices[row_index2]
		for ni: int in range(row2.size()):
			var t: String = String((row2[ni] as Dictionary).get("type", ""))
			if t == "battle" or t == "event":
				candidates.append([row_index2, ni])
	candidates.shuffle()
	while shop_count < MIN_SHOPS_PER_MAP and not candidates.is_empty():
		var pick: Array = candidates.pop_back() as Array
		var r_i: int = int(pick[0])
		var n_i: int = int(pick[1])
		if _adjacent_to_shop(choices, r_i, n_i):
			continue  # 轉了會跟既有商店串連 → 換下一個候選
		var node2: Dictionary = (choices[r_i] as Array)[n_i] as Dictionary
		node2["type"] = "shop"
		node2.erase("enemies")
		node2.erase("is_elite")
		node2.erase("event_variant")
		node2.erase("merchant_event")
		node2["black_market"] = randf() < BLACK_SHOP_CHANCE
		shop_count += 1

# 該位置若轉成商店，是否會與既有商店「串連」（上一列有商店連入、或本節點連出到商店）
static func _adjacent_to_shop(choices: Array[Array], row_index: int, node_index: int) -> bool:
	var node: Dictionary = (choices[row_index] as Array)[node_index] as Dictionary
	# 連出：本節點 connects 指到的下一列節點
	if row_index + 1 < choices.size():
		var next_row: Array = choices[row_index + 1]
		for j_v: Variant in (node.get("connects", []) as Array):
			var j: int = int(j_v)
			if j >= 0 and j < next_row.size() and String((next_row[j] as Dictionary).get("type", "")) == "shop":
				return true
	# 連入：上一列任一商店的 connects 含本節點
	if row_index - 1 >= 0:
		for prev_v: Variant in (choices[row_index - 1] as Array):
			var prev: Dictionary = prev_v as Dictionary
			if String(prev.get("type", "")) != "shop":
				continue
			for j_v2: Variant in (prev.get("connects", []) as Array):
				if int(j_v2) == node_index:
					return true
	return false

static func _build_row_types(row_index: int, total_rows: int, row_size: int) -> Array[String]:
	var node_types: Array[String] = []
	for _i: int in range(row_size):
		node_types.append("battle")
	if row_index == 0:
		return node_types

	# 強制戰鬥列：每 3 列有一列（%3==1）整列皆戰鬥，任何路徑都繞不過去。
	# 搭配 rest 列（%3==0）→ 節奏成「戰鬥 / 事件 / 休息」循環，事件不再霸佔多數列，
	# 也杜絕「專挑事件節點直奔 Boss、只打一兩場」的走法。
	if row_index % 3 == 1:
		return node_types

	var special_budget: int = 1
	if row_size >= 5:
		special_budget += 1
	if row_size >= 6 and randf() < 0.35:
		special_budget += 1
	if row_index >= total_rows - 2:
		special_budget = max(1, special_budget - 1)

	var insert_slots: Array[int] = []
	for slot: int in range(row_size):
		insert_slots.append(slot)
	insert_slots.shuffle()

	var special_types: Array[String] = []
	special_types.append("rest" if row_index % 3 == 0 else "event")
	if special_budget >= 2:
		var secondary_pool: Array[String] = SECONDARY_SPECIAL_TYPES.duplicate()
		secondary_pool.shuffle()
		special_types.append(secondary_pool[0])
	if special_budget >= 3:
		var extra_pool: Array[String] = EXTRA_SPECIAL_TYPES.duplicate()
		extra_pool.shuffle()
		special_types.append(extra_pool[0])

	var applied_specials: int = min(special_budget, min(special_types.size(), insert_slots.size()))
	for special_index: int in range(applied_specials):
		node_types[insert_slots[special_index]] = special_types[special_index]

	node_types.shuffle()
	return node_types

# 中段列把一個 battle slot 換成 elite（A1 起機率提升）。第一列與 boss 前一列不放。
static func _inject_elite(node_types: Array[String], row_index: int, total_rows: int, ascension: int) -> void:
	if row_index < 1 or row_index >= total_rows - 1:
		return
	var chance: float = ELITE_BASE_CHANCE + 0.25 * float(Ascension.elite_frequency_bonus(ascension))
	if randf() >= chance:
		return
	var battle_slots: Array[int] = []
	for i: int in range(node_types.size()):
		if node_types[i] == "battle":
			battle_slots.append(i)
	if battle_slots.is_empty():
		return
	node_types[battle_slots[randi() % battle_slots.size()]] = "elite"

static func _make_map_node(node_type: String, node_index: int, normal_enemies: Array[EnemyData], event_pool: Array[String] = EVENT_VARIANTS, act: int = 1, elite_enemies: Array[EnemyData] = []) -> Dictionary:
	var node_data: Dictionary = {
		"type": node_type,
		"index": node_index,
		"connects": []
	}
	if node_type == "battle":
		node_data["enemies"] = choose_enemies_for_act(act, normal_enemies)
	elif node_type == "elite":
		# 精英 = 1 隻該幕高血敵人（強化由 Ascension elite tier 倍率在開戰時套用）
		var src: Array[EnemyData] = elite_enemies if not elite_enemies.is_empty() else normal_enemies
		var elite_node: Array[EnemyData] = []
		if not src.is_empty():
			elite_node.append((src[randi() % src.size()] as EnemyData).clone())
		node_data["enemies"] = elite_node
		node_data["is_elite"] = true
	elif node_type == "event":
		node_data["event_variant"] = _pick_event_variant(event_pool)
		# 規則 3：奇遇節點有機率其實是「行腳商人」——地圖上仍顯示奇遇，
		# 走進去才發現是商店（驚喜性質；不計入最少商店數、不受串連限制）。
		if randf() < MERCHANT_EVENT_CHANCE:
			node_data["merchant_event"] = true
			node_data["black_market"] = randf() < BLACK_SHOP_CHANCE
	elif node_type == "shop":
		node_data["black_market"] = randf() < BLACK_SHOP_CHANCE
	return node_data

static func _add_random_map_connections(choices: Array[Array]) -> void:
	# 樹狀連線：每個節點先連到「比例位置最接近」的下一列節點（primary），
	# 由於 primary 隨 i 單調遞增，本身就不會交叉。然後可選擇加一條 secondary
	# 到鄰居節點，加之前用 _will_cross 守門。最後補齊孤兒（沒 incoming 的 next 節點）。
	for row_index: int in range(choices.size() - 1):
		var row: Array = choices[row_index]
		var next_row: Array = choices[row_index + 1]
		var n_cur: int = row.size()
		var n_next: int = next_row.size()
		# 重置 connects
		for node_variant: Variant in row:
			var empty_connects: Array[int] = []
			(node_variant as Dictionary)["connects"] = empty_connects
		if n_cur == 0 or n_next == 0:
			continue
		# Phase 1: 每個 cur 節點 i 連到比例位置對應的 next 節點 primary_j。
		# primary_j 隨 i 單調遞增 → 無交叉。
		for i: int in range(n_cur):
			var ratio: float = 0.5 if n_cur <= 1 else float(i) / float(n_cur - 1)
			var primary_j: int = 0 if n_next <= 1 else int(round(ratio * float(n_next - 1)))
			var c1: Array[int] = (row[i] as Dictionary)["connects"]
			c1.append(primary_j)
		# Phase 2: 每個 cur 節點有 45% 機率多連一條 secondary（鄰居 ±1），需通過 cross check
		for i: int in range(n_cur):
			if randf() >= 0.45:
				continue
			var primary_arr: Array[int] = (row[i] as Dictionary)["connects"]
			if primary_arr.is_empty():
				continue
			var pj: int = primary_arr[0]
			var candidates: Array[int] = []
			if pj > 0:
				candidates.append(pj - 1)
			if pj < n_next - 1:
				candidates.append(pj + 1)
			candidates.shuffle()
			for cand: int in candidates:
				if not _will_cross(row, i, cand):
					if not primary_arr.has(cand):
						primary_arr.append(cand)
					break
		# Phase 3: 確保每個 next 節點都有 incoming（補孤兒）
		var has_incoming: Array[bool] = []
		for _j: int in range(n_next):
			has_incoming.append(false)
		for node_variant2: Variant in row:
			for j_v: Variant in ((node_variant2 as Dictionary)["connects"] as Array):
				has_incoming[int(j_v)] = true
		for j: int in range(n_next):
			if has_incoming[j]:
				continue
			# 找比例位置最近的 cur 節點，能不交叉就接上；不行就試 ±1
			var y: float = 0.5 if n_next <= 1 else float(j) / float(n_next - 1)
			var nearest_i: int = 0 if n_cur <= 1 else int(round(y * float(n_cur - 1)))
			var tries: Array[int] = [nearest_i]
			if nearest_i > 0:
				tries.append(nearest_i - 1)
			if nearest_i < n_cur - 1:
				tries.append(nearest_i + 1)
			for cand_i: int in tries:
				if _will_cross(row, cand_i, j):
					continue
				var cand_arr: Array[int] = (row[cand_i] as Dictionary)["connects"]
				if not cand_arr.has(j):
					cand_arr.append(j)
				has_incoming[j] = true
				break
		# Sort each row's connects
		for node_variant3: Variant in row:
			var final_arr: Array[int] = (node_variant3 as Dictionary)["connects"]
			final_arr.sort()

# 連線 candidate_i → candidate_j 是否會與其他已存在的邊交叉
# 規則：i' < candidate_i 的所有邊 j' 必須 <= candidate_j；i' > candidate_i 必須 >= candidate_j
static func _will_cross(row: Array, candidate_i: int, candidate_j: int) -> bool:
	for i2: int in range(row.size()):
		if i2 == candidate_i:
			continue
		var edges: Array = (row[i2] as Dictionary)["connects"] as Array
		if edges.is_empty():
			continue
		if i2 < candidate_i:
			for j2_v: Variant in edges:
				if int(j2_v) > candidate_j:
					return true
		else:
			for j2_v: Variant in edges:
				if int(j2_v) < candidate_j:
					return true
	return false
