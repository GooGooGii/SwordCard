class_name CardData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var owner: String = ""
@export var cost: int = 1
@export var card_type: String = "attack"
@export_multiline var description: String = ""
@export var rarity: String = "basic"
@export var effects: Array[Dictionary] = []

func clone() -> CardData:
	var copy: CardData = CardData.new()
	copy.id = id
	copy.display_name = display_name
	copy.owner = owner
	copy.cost = cost
	copy.card_type = card_type
	copy.description = description
	copy.rarity = rarity
	copy.effects = effects.duplicate(true)
	return copy
