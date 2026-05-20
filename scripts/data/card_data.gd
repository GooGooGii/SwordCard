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
@export var upgraded: bool = false
@export var art_path: String = ""

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
	copy.upgraded = upgraded
	copy.art_path = art_path
	return copy

func display_title() -> String:
	if upgraded:
		return "%s+" % display_name
	return display_name

func display_description() -> String:
	if upgraded:
		return "%s\n已升級：數值效果強化。" % description
	return description

func upgraded_copy() -> CardData:
	var copy: CardData = clone()
	copy.upgraded = true
	copy.effects.clear()
	for effect: Dictionary in effects:
		var upgraded_effect: Dictionary = effect.duplicate(true)
		var kind: String = String(upgraded_effect.get("kind", ""))
		if upgraded_effect.has("amount") and _should_upgrade_amount(kind):
			upgraded_effect["amount"] = _upgraded_amount(kind, int(upgraded_effect["amount"]))
		copy.effects.append(upgraded_effect)
	return copy

func _should_upgrade_amount(kind: String) -> bool:
	return kind in [
		"damage",
		"block",
		"heal",
		"poison",
		"weak",
		"vulnerable",
		"draw",
		"energy",
		"power",
		"consume_energy_damage",
		"poison_burst"
	]

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"owner": owner,
		"cost": cost,
		"card_type": card_type,
		"description": description,
		"rarity": rarity,
		"effects": effects.duplicate(true),
		"upgraded": upgraded,
		"art_path": art_path
	}

static func from_dict(data: Dictionary) -> CardData:
	var card: CardData = CardData.new()
	card.id = String(data.get("id", ""))
	card.display_name = String(data.get("display_name", ""))
	card.owner = String(data.get("owner", ""))
	card.cost = int(data.get("cost", 1))
	card.card_type = String(data.get("card_type", "attack"))
	card.description = String(data.get("description", ""))
	card.rarity = String(data.get("rarity", "basic"))
	card.upgraded = bool(data.get("upgraded", false))
	card.art_path = String(data.get("art_path", ""))
	var raw_effects: Array = data.get("effects", []) as Array
	var typed_effects: Array[Dictionary] = []
	for entry: Variant in raw_effects:
		if entry is Dictionary:
			typed_effects.append((entry as Dictionary).duplicate(true))
	card.effects = typed_effects
	return card

func _upgraded_amount(kind: String, amount: int) -> int:
	match kind:
		"draw", "energy", "vulnerable":
			return amount + 1
		"weak", "poison", "power":
			return amount + 1
		"consume_energy_damage", "poison_burst":
			return amount + 2
		_:
			return amount + max(1, int(ceil(amount * 0.25)))
