class_name CharacterData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 70
@export_multiline var battle_style: String = ""
@export var portrait_path: String = ""
@export var starting_deck: Array[CardData] = []
@export var reward_pool: Array[CardData] = []
@export var passives: Array[Dictionary] = []

func clone() -> CharacterData:
	var copy: CharacterData = CharacterData.new()
	copy.id = id
	copy.display_name = display_name
	copy.max_hp = max_hp
	copy.battle_style = battle_style
	copy.portrait_path = portrait_path
	copy.starting_deck = []
	for card in starting_deck:
		copy.starting_deck.append(card.clone())
	copy.reward_pool = []
	for card in reward_pool:
		copy.reward_pool.append(card.clone())
	copy.passives = passives.duplicate(true)
	return copy

func passive_by_trigger(trigger: String) -> Dictionary:
	for passive: Dictionary in passives:
		if String(passive.get("trigger", "")) == trigger:
			return passive
	return {}
