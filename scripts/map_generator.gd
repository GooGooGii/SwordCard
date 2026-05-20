class_name MapGenerator
extends RefCounted

const EVENT_VARIANTS: Array[String] = ["shrine", "spring", "talisman_cache"]
const MAP_ROWS: Array = [
	["battle", "battle", "battle"],
	["battle", "rest", "event", "shop"],
	["battle", "battle", "event", "shop", "rest"]
]
const BLACK_SHOP_CHANCE: float = 0.25

static func generate(enemies: Array[EnemyData]) -> Array[Array]:
	var choices: Array[Array] = []
	var normal_enemies: Array[EnemyData] = []
	var boss_enemy: EnemyData = null
	for enemy: EnemyData in enemies:
		if enemy.id == "moon_worshipper":
			boss_enemy = enemy
		else:
			normal_enemies.append(enemy)
	for row_index: int in range(MAP_ROWS.size()):
		var row: Array[Dictionary] = []
		var node_types: Array = (MAP_ROWS[row_index] as Array).duplicate()
		node_types.shuffle()
		for node_index: int in range(3):
			var node_type: String = String(node_types[node_index])
			row.append(_make_map_node(node_type, node_index, normal_enemies))
		choices.append(row)
	if boss_enemy != null:
		var boss_row: Array[Dictionary] = []
		boss_row.append({"type": "boss", "enemy": boss_enemy.clone(), "index": 0, "connects": []})
		choices.append(boss_row)
	_add_random_map_connections(choices)
	return choices

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
