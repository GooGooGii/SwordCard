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
var relics: Array[RelicData] = []
var ascension_level: int = 0

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
	relics.clear()
	# 角色起始專武：每個角色第一把 weapon
	var starter_weapons: Array[RelicData] = RelicCatalog.weapons_for_character(chosen.id)
	if not starter_weapons.is_empty():
		add_relic(starter_weapons[0])

func add_relic(relic: RelicData) -> void:
	if relic == null:
		return
	for existing: RelicData in relics:
		if existing.id == relic.id:
			return  # 不重複拿
	relics.append(relic.clone())
	_apply_acquire_triggers(relic)

func has_relic(relic_id: String) -> bool:
	for r: RelicData in relics:
		if r.id == relic_id:
			return true
	return false

func aggregate_permanent(kind: String) -> int:
	var total: int = 0
	for r: RelicData in relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == kind:
					total += int(e.get("amount", 0))
	return total

func _apply_acquire_triggers(relic: RelicData) -> void:
	for t: Dictionary in relic.triggers:
		if String(t.get("trigger", "")) != "acquire":
			continue
		for e: Dictionary in (t.get("effects", []) as Array):
			var kind: String = String(e.get("kind", ""))
			var amount: int = int(e.get("amount", 0))
			match kind:
				"gold_bonus":
					gold += amount
				"max_hp_bonus":
					max_hp += amount
					hp += amount

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func take_damage(amount: int, minimum: int = 1) -> void:
	hp = max(minimum, hp - amount)

func sync_hp_from_battle(battle_hp: int) -> void:
	hp = battle_hp

func to_dict() -> Dictionary:
	var deck_data: Array[Dictionary] = []
	for card: CardData in deck:
		deck_data.append(card.to_dict())
	var relics_data: Array[Dictionary] = []
	for r: RelicData in relics:
		relics_data.append(r.to_dict())
	return {
		"version": 2,
		"character_id": character.id if character != null else "",
		"hp": hp,
		"max_hp": max_hp,
		"gold": gold,
		"power_bonus": power_bonus,
		"deck": deck_data,
		"encounter_index": encounter_index,
		"encounter_choices": _serialize_choices(),
		"chosen_map_path": chosen_map_path.duplicate(),
		"pending_rest_heal": pending_rest_heal,
		"current_shop_inventory": _serialize_shop_inventory(),
		"current_shop_is_black": current_shop_is_black,
		"current_event_variant": current_event_variant,
		"relics": relics_data,
		"ascension_level": ascension_level
	}

func from_dict(data: Dictionary, available_characters: Array[CharacterData]) -> bool:
	var char_id: String = String(data.get("character_id", ""))
	var found_character: CharacterData = null
	for candidate: CharacterData in available_characters:
		if candidate.id == char_id:
			found_character = candidate.clone()
			break
	if found_character == null:
		return false
	character = found_character
	max_hp = int(data.get("max_hp", found_character.max_hp))
	hp = int(data.get("hp", max_hp))
	gold = int(data.get("gold", 0))
	power_bonus = int(data.get("power_bonus", 0))
	deck.clear()
	for card_data: Variant in (data.get("deck", []) as Array):
		if card_data is Dictionary:
			deck.append(CardData.from_dict(card_data as Dictionary))
	encounter_index = int(data.get("encounter_index", 0))
	encounter_choices = _deserialize_choices(data.get("encounter_choices", []) as Array)
	chosen_map_path.clear()
	for entry: Variant in (data.get("chosen_map_path", []) as Array):
		chosen_map_path.append(int(entry))
	pending_rest_heal = int(data.get("pending_rest_heal", 0))
	current_shop_inventory = _deserialize_shop_inventory(data.get("current_shop_inventory", []) as Array)
	current_shop_is_black = bool(data.get("current_shop_is_black", false))
	current_event_variant = String(data.get("current_event_variant", "shrine"))
	relics.clear()
	for relic_data: Variant in (data.get("relics", []) as Array):
		if relic_data is Dictionary:
			relics.append(RelicData.from_dict(relic_data as Dictionary))
	ascension_level = int(data.get("ascension_level", 0))
	return true

func _serialize_choices() -> Array:
	var rows_out: Array = []
	for row: Array in encounter_choices:
		var row_out: Array = []
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_out: Dictionary = {
				"type": node_data.get("type", "battle"),
				"index": node_data.get("index", 0),
				"connects": (node_data.get("connects", []) as Array).duplicate()
			}
			if node_data.has("event_variant"):
				node_out["event_variant"] = node_data["event_variant"]
			if node_data.has("black_market"):
				node_out["black_market"] = node_data["black_market"]
			if node_data.has("enemy"):
				node_out["enemy"] = (node_data["enemy"] as EnemyData).to_dict()
			row_out.append(node_out)
		rows_out.append(row_out)
	return rows_out

func _deserialize_choices(rows_in: Array) -> Array[Array]:
	var rows_out: Array[Array] = []
	for row_variant: Variant in rows_in:
		var row_in: Array = row_variant as Array
		var row_out: Array[Dictionary] = []
		for node_variant: Variant in row_in:
			var node_data: Dictionary = node_variant as Dictionary
			var node_out: Dictionary = {
				"type": String(node_data.get("type", "battle")),
				"index": int(node_data.get("index", 0)),
				"connects": []
			}
			var connects_in: Array = node_data.get("connects", []) as Array
			var connects_out: Array[int] = []
			for c: Variant in connects_in:
				connects_out.append(int(c))
			node_out["connects"] = connects_out
			if node_data.has("event_variant"):
				node_out["event_variant"] = String(node_data["event_variant"])
			if node_data.has("black_market"):
				node_out["black_market"] = bool(node_data["black_market"])
			if node_data.has("enemy"):
				node_out["enemy"] = EnemyData.from_dict(node_data["enemy"] as Dictionary)
			row_out.append(node_out)
		rows_out.append(row_out)
	return rows_out

func _serialize_shop_inventory() -> Array:
	var inventory_out: Array = []
	for item: Dictionary in current_shop_inventory:
		var card: CardData = item.get("card") as CardData
		inventory_out.append({
			"card": card.to_dict() if card != null else {},
			"price": int(item.get("price", 0))
		})
	return inventory_out

func _deserialize_shop_inventory(inventory_in: Array) -> Array[Dictionary]:
	var inventory_out: Array[Dictionary] = []
	for item_variant: Variant in inventory_in:
		var item: Dictionary = item_variant as Dictionary
		var card_dict: Dictionary = item.get("card", {}) as Dictionary
		inventory_out.append({
			"card": CardData.from_dict(card_dict),
			"price": int(item.get("price", 0))
		})
	return inventory_out
