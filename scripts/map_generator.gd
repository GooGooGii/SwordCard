class_name MapGenerator
extends RefCounted

const EVENT_VARIANTS: Array[String] = ["shrine", "spring", "talisman_cache", "treasure_chest", "ancestor_relic", "wandering_sage", "moonlit_pool", "broken_temple", "yokai_pact", "forgotten_altar", "ancient_battlefield", "alchemy_furnace", "ghost_forest", "immortal_ruins", "spirit_clan_ruins", "baiyue_altar", "tavern_acquaintance", "sword_tomb", "miao_healer", "shilipo_sword_god", "drunk_swordsman", "yinlong_cave", "yangzhou_officer", "xianling_shrine"]
const BLACK_SHOP_CHANCE: float = 0.25
const MIN_NORMAL_ROW_COUNT: int = 9
const MAX_NORMAL_ROW_COUNT: int = 11
const MIN_ROW_OPTIONS: int = 3
const MAX_ROW_OPTIONS: int = 6
const SECONDARY_SPECIAL_TYPES: Array[String] = ["event", "rest", "shop"]
const EXTRA_SPECIAL_TYPES: Array[String] = ["battle", "event", "rest", "shop"]

static func generate(normal_enemies: Array[EnemyData], bosses: Array[EnemyData]) -> Array[Array]:
	var choices: Array[Array] = []
	var normal_row_count: int = randi_range(MIN_NORMAL_ROW_COUNT, MAX_NORMAL_ROW_COUNT)
	for row_index: int in range(normal_row_count):
		var row: Array[Dictionary] = []
		var row_size: int = randi_range(MIN_ROW_OPTIONS, MAX_ROW_OPTIONS)
		var node_types: Array[String] = _build_row_types(row_index, normal_row_count, row_size)
		for node_index: int in range(row_size):
			var node_type: String = String(node_types[node_index])
			row.append(_make_map_node(node_type, node_index, normal_enemies))
		choices.append(row)
	if not bosses.is_empty():
		var chosen_boss: EnemyData = bosses[randi() % bosses.size()]
		var boss_row: Array[Dictionary] = []
		boss_row.append({"type": "boss", "enemy": chosen_boss.clone(), "index": 0, "connects": []})
		choices.append(boss_row)
	_add_random_map_connections(choices)
	return choices

static func _build_row_types(row_index: int, total_rows: int, row_size: int) -> Array[String]:
	var node_types: Array[String] = []
	for _i: int in range(row_size):
		node_types.append("battle")
	if row_index == 0:
		return node_types

	var special_budget: int = 1
	if row_size >= 4:
		special_budget += 1
	if row_size >= 6 or (row_size >= 5 and randf() < 0.55):
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

static func _make_map_node(node_type: String, node_index: int, normal_enemies: Array[EnemyData]) -> Dictionary:
	var node_data: Dictionary = {
		"type": node_type,
		"index": node_index,
		"connects": []
	}
	if node_type == "battle":
		var pool: Array[EnemyData] = normal_enemies.duplicate()
		pool.shuffle()
		node_data["enemy"] = pool[0].clone()
	elif node_type == "event":
		node_data["event_variant"] = EVENT_VARIANTS[randi_range(0, EVENT_VARIANTS.size() - 1)]
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
