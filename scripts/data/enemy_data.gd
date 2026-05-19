class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 60
@export var actions: Array[Dictionary] = []

func clone() -> EnemyData:
	var copy: EnemyData = EnemyData.new()
	copy.id = id
	copy.display_name = display_name
	copy.max_hp = max_hp
	copy.actions = actions.duplicate(true)
	return copy
