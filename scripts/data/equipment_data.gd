class_name EquipmentData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var slot: String = "accessory"   # "weapon" | "armor" | "accessory"
@export_multiline var description: String = ""
@export var rarity: String = "common"    # common | uncommon | rare | artifact
@export var owner: String = ""           # "" = 通用；角色 id = 專武
@export var effects: Array[Dictionary] = []
@export var price: int = 100

func clone() -> EquipmentData:
	var copy: EquipmentData = EquipmentData.new()
	copy.id = id
	copy.display_name = display_name
	copy.slot = slot
	copy.description = description
	copy.rarity = rarity
	copy.owner = owner
	copy.effects = effects.duplicate(true)
	copy.price = price
	return copy

func rarity_display() -> String:
	match rarity:
		"uncommon": return "精良"
		"rare":     return "稀有"
		"artifact": return "神器"
	return "普通"

func slot_display() -> String:
	match slot:
		"weapon":    return "武器"
		"armor":     return "防具"
		"accessory": return "飾品"
	return slot
