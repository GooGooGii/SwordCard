class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 60
@export var portrait_path: String = ""
@export var actions: Array[Dictionary] = []
@export var portrait_tint: Color = Color.WHITE

func clone() -> EnemyData:
	var copy: EnemyData = EnemyData.new()
	copy.id = id
	copy.display_name = display_name
	copy.max_hp = max_hp
	copy.portrait_path = portrait_path
	copy.actions = actions.duplicate(true)
	copy.portrait_tint = portrait_tint
	return copy

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"max_hp": max_hp,
		"portrait_path": portrait_path,
		"actions": actions.duplicate(true),
		"portrait_tint": [portrait_tint.r, portrait_tint.g, portrait_tint.b, portrait_tint.a]
	}

static func from_dict(data: Dictionary) -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = String(data.get("id", ""))
	enemy.display_name = String(data.get("display_name", ""))
	enemy.max_hp = int(data.get("max_hp", 60))
	enemy.portrait_path = String(data.get("portrait_path", ""))
	var raw_actions: Array = data.get("actions", []) as Array
	var typed_actions: Array[Dictionary] = []
	for entry: Variant in raw_actions:
		if entry is Dictionary:
			typed_actions.append((entry as Dictionary).duplicate(true))
	enemy.actions = typed_actions
	var tint_data: Array = data.get("portrait_tint", []) as Array
	if tint_data.size() >= 3:
		enemy.portrait_tint = Color(
			float(tint_data[0]),
			float(tint_data[1]),
			float(tint_data[2]),
			float(tint_data[3]) if tint_data.size() >= 4 else 1.0
		)
	return enemy
