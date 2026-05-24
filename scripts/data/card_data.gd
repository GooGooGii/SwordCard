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
@export var gold_cost: int = 0

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
	copy.gold_cost = gold_cost
	return copy

func display_title() -> String:
	if upgraded:
		return "%s+" % display_name
	return display_name

func display_description() -> String:
	return description

func upgraded_copy() -> CardData:
	var copy: CardData = clone()
	copy.upgraded = true
	copy.effects.clear()
	var replacements: Dictionary = {}  # old_amount -> new_amount
	for effect: Dictionary in effects:
		var upgraded_effect: Dictionary = effect.duplicate(true)
		var kind: String = String(upgraded_effect.get("kind", ""))
		if upgraded_effect.has("amount") and _should_upgrade_amount(kind):
			var old_amount: int = int(upgraded_effect["amount"])
			upgraded_effect["amount"] = _upgraded_amount(kind, old_amount)
			var new_amount: int = int(upgraded_effect["amount"])
			if old_amount != new_amount:
				replacements[old_amount] = new_amount
		copy.effects.append(upgraded_effect)
	# Update description text to match upgraded effect amounts.
	# Sort descending so e.g. "14" is replaced before "4", avoiding partial substitutions.
	var desc: String = description
	var sorted_keys: Array = replacements.keys()
	sorted_keys.sort()
	sorted_keys.reverse()
	for old_amount: int in sorted_keys:
		desc = _replace_number_in_desc(desc, old_amount, replacements[old_amount])
	copy.description = desc
	return copy

# Replace every standalone occurrence of old_val with new_val in text.
# "Standalone" means not adjacent to another digit (word-boundary for numbers).
static func _replace_number_in_desc(text: String, old_val: int, new_val: int) -> String:
	var old_str: String = str(old_val)
	var new_str: String = str(new_val)
	var result: String = ""
	var i: int = 0
	while i < text.length():
		if i + old_str.length() <= text.length() and text.substr(i, old_str.length()) == old_str:
			var before_ok: bool = i == 0 or not _is_ascii_digit(text.unicode_at(i - 1))
			var after_ok: bool = (i + old_str.length() >= text.length()) \
				or not _is_ascii_digit(text.unicode_at(i + old_str.length()))
			if before_ok and after_ok:
				result += new_str
				i += old_str.length()
				continue
		result += text[i]
		i += 1
	return result

static func _is_ascii_digit(char_code: int) -> bool:
	return char_code >= 48 and char_code <= 57  # '0'..'9'

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
		"poison_burst",
		"revive"
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
		"art_path": art_path,
		"gold_cost": gold_cost
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
	card.gold_cost = int(data.get("gold_cost", 0))
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
