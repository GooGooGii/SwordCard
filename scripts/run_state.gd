class_name RunState
extends RefCounted

const STARTING_GOLD: int = 45

var character: CharacterData
var hp: int = 0
var max_hp: int = 0
var gold: int = 0
var power_bonus: int = 0
var deck: Array[CardData] = []

var encounter_index: int = 0
var encounter_choices: Array[Array] = []
var chosen_map_path: Array[int] = []

var pending_rest_heal: int = 0
var current_shop_inventory: Array[Dictionary] = []
var current_shop_is_black: bool = false
var current_event_variant: String = "shrine"

func init_for(chosen: CharacterData) -> void:
	character = chosen
	max_hp = chosen.max_hp
	hp = chosen.max_hp
	gold = STARTING_GOLD
	power_bonus = 0
	deck.clear()
	for card: CardData in chosen.starting_deck:
		deck.append(card.clone())
	encounter_index = 0
	encounter_choices = []
	chosen_map_path = []
	pending_rest_heal = 0
	current_shop_inventory = []
	current_shop_is_black = false
	current_event_variant = "shrine"

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func take_damage(amount: int, minimum: int = 1) -> void:
	hp = max(minimum, hp - amount)

func sync_hp_from_battle(battle_hp: int) -> void:
	hp = battle_hp
