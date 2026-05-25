class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 60
@export var portrait_path: String = ""
@export var actions: Array[Dictionary] = []
@export var phase_2_actions: Array[Dictionary] = []  # boss HP < 50% 切換到的招式組，空 = 不進入二階段
@export var phase_2_display_name: String = ""  # 進入 phase 2 時改顯示的名字（如「水魔獸」）；空 = 沿用 display_name
@export var phase_2_portrait_path: String = ""  # 進入 phase 2 時換的肖像；空 = 沿用 portrait_path
@export var phase_2_portrait_tint: Color = Color.WHITE  # phase 2 額外色調（Color.WHITE = 不變色）
@export var portrait_tint: Color = Color.WHITE

func clone() -> EnemyData:
	var copy: EnemyData = EnemyData.new()
	copy.id = id
	copy.display_name = display_name
	copy.max_hp = max_hp
	copy.portrait_path = portrait_path
	copy.actions = actions.duplicate(true)
	copy.phase_2_actions = phase_2_actions.duplicate(true)
	copy.phase_2_display_name = phase_2_display_name
	copy.phase_2_portrait_path = phase_2_portrait_path
	copy.phase_2_portrait_tint = phase_2_portrait_tint
	copy.portrait_tint = portrait_tint
	return copy

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"max_hp": max_hp,
		"portrait_path": portrait_path,
		"actions": actions.duplicate(true),
		"phase_2_actions": phase_2_actions.duplicate(true),
		"phase_2_display_name": phase_2_display_name,
		"phase_2_portrait_path": phase_2_portrait_path,
		"phase_2_portrait_tint": [phase_2_portrait_tint.r, phase_2_portrait_tint.g, phase_2_portrait_tint.b, phase_2_portrait_tint.a],
		"portrait_tint": [portrait_tint.r, portrait_tint.g, portrait_tint.b, portrait_tint.a]
	}

static func from_dict(data: Dictionary) -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = String(data.get("id", ""))
	enemy.display_name = String(data.get("display_name", ""))
	enemy.max_hp = int(data.get("max_hp", 60))
	enemy.portrait_path = String(data.get("portrait_path", ""))
	enemy.phase_2_display_name = String(data.get("phase_2_display_name", ""))
	enemy.phase_2_portrait_path = String(data.get("phase_2_portrait_path", ""))
	var p2_tint_data: Array = data.get("phase_2_portrait_tint", []) as Array
	if p2_tint_data.size() >= 3:
		enemy.phase_2_portrait_tint = Color(
			float(p2_tint_data[0]),
			float(p2_tint_data[1]),
			float(p2_tint_data[2]),
			float(p2_tint_data[3]) if p2_tint_data.size() >= 4 else 1.0
		)
	var raw_actions: Array = data.get("actions", []) as Array
	var typed_actions: Array[Dictionary] = []
	for entry: Variant in raw_actions:
		if entry is Dictionary:
			typed_actions.append((entry as Dictionary).duplicate(true))
	enemy.actions = typed_actions
	var raw_phase_2: Array = data.get("phase_2_actions", []) as Array
	var typed_phase_2: Array[Dictionary] = []
	for entry: Variant in raw_phase_2:
		if entry is Dictionary:
			typed_phase_2.append((entry as Dictionary).duplicate(true))
	enemy.phase_2_actions = typed_phase_2
	var tint_data: Array = data.get("portrait_tint", []) as Array
	if tint_data.size() >= 3:
		enemy.portrait_tint = Color(
			float(tint_data[0]),
			float(tint_data[1]),
			float(tint_data[2]),
			float(tint_data[3]) if tint_data.size() >= 4 else 1.0
		)
	return enemy
