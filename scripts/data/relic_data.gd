class_name RelicData
extends Resource

# slot: "general" | "weapon" | "artifact"
# rarity: "common" | "uncommon" | "rare" | "legendary"
# triggers: Array of {trigger: String, effects: Array[Dictionary], filter: Dictionary (optional)}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: String = "common"
@export var slot: String = "general"
@export var character_id: String = ""  # only for "weapon" slot
@export var boss_id: String = ""  # only for "artifact" slot (drops from this boss)
@export var triggers: Array[Dictionary] = []
@export var icon_color: Color = Color("c8b46f")
@export var icon_shape: String = "diamond"  # diamond | circle | hex | star

func clone() -> RelicData:
	var copy: RelicData = RelicData.new()
	copy.id = id
	copy.display_name = display_name
	copy.description = description
	copy.rarity = rarity
	copy.slot = slot
	copy.character_id = character_id
	copy.boss_id = boss_id
	copy.triggers = triggers.duplicate(true)
	copy.icon_color = icon_color
	copy.icon_shape = icon_shape
	return copy

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"rarity": rarity,
		"slot": slot,
		"character_id": character_id,
		"boss_id": boss_id,
		"triggers": triggers.duplicate(true),
		"icon_color": [icon_color.r, icon_color.g, icon_color.b, icon_color.a],
		"icon_shape": icon_shape
	}

static func from_dict(data: Dictionary) -> RelicData:
	var r: RelicData = RelicData.new()
	r.id = String(data.get("id", ""))
	r.display_name = String(data.get("display_name", ""))
	r.description = String(data.get("description", ""))
	r.rarity = String(data.get("rarity", "common"))
	r.slot = String(data.get("slot", "general"))
	r.character_id = String(data.get("character_id", ""))
	r.boss_id = String(data.get("boss_id", ""))
	var raw_triggers: Array = data.get("triggers", []) as Array
	var typed_triggers: Array[Dictionary] = []
	for t: Variant in raw_triggers:
		if t is Dictionary:
			typed_triggers.append((t as Dictionary).duplicate(true))
	r.triggers = typed_triggers
	var c_data: Array = data.get("icon_color", []) as Array
	if c_data.size() >= 3:
		r.icon_color = Color(float(c_data[0]), float(c_data[1]), float(c_data[2]), float(c_data[3]) if c_data.size() >= 4 else 1.0)
	r.icon_shape = String(data.get("icon_shape", "diamond"))
	return r
