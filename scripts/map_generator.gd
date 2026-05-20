class_name MapGenerator
extends RefCounted

const EVENT_VARIANTS: Array[String] = ["shrine", "spring", "talisman_cache", "treasure_chest", "ancestor_relic"]
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
		normal_enemies.shuffle()
		node_data["enemy"] = normal_enemies[0].clone()
	elif node_type == "event":
		node_data["event_variant"] = EVENT_VARIANTS[randi_range(0, EVENT_VARIANTS.size() - 1)]
	elif node_type == "shop":
		node_data["black_market"] = randf() < BLACK_SHOP_CHANCE
	return node_data

static func _add_random_map_connections(choices: Array[Array]) -> void:
	for row_index: int in range(choices.size() - 1):
		var row: Array = choices[row_index]
		var next_row: Array = choices[row_index + 1]
		var incoming: Dictionary = {}
		for next_index: int in range(next_row.size()):
			incoming[next_index] = 0
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var targets: Array[int] = []
			if next_row.size() == 1:
				targets.append(0)
			else:
				var node_index: int = int(node_data.get("index", 0))
				var candidate_indices: Array[int] = []
				for offset: int in [-1, 0, 1]:
					var target_index: int = int(clamp(node_index + offset, 0, next_row.size() - 1))
					if not candidate_indices.has(target_index):
						candidate_indices.append(target_index)
				candidate_indices.shuffle()
				var link_count: int = 1 + randi_range(0, 1)
				for i: int in range(min(link_count, candidate_indices.size())):
					targets.append(candidate_indices[i])
			targets.sort()
			node_data["connects"] = targets
			for target: int in targets:
				incoming[target] = int(incoming[target]) + 1
		for next_index_variant: Variant in incoming.keys():
			var next_index: int = int(next_index_variant)
			if int(incoming[next_index]) > 0:
				continue
			var source_index: int = randi_range(0, row.size() - 1)
			var source_node: Dictionary = row[source_index] as Dictionary
			var connects: Array = source_node.get("connects", []) as Array
			if not connects.has(next_index):
				connects.append(next_index)
				connects.sort()
				source_node["connects"] = connects
