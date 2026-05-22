class_name RunState
extends RefCounted

const STARTING_GOLD: int = 45

# Party (1–3 角色) — characters[0] 是隊長、永久不變
var characters: Array[CharacterData] = []
var character_hps: Array[int] = []
var character_max_hps: Array[int] = []
var character_power_bonus: Array[int] = []
var character_decks: Array = []  # Array of Array[CardData] — GDScript 不易宣告巢狀 typed
var active_character_index: int = 0

# 全隊共用的 run 狀態
var act: int = 1
var gold: int = 0
var encounter_index: int = 0
var encounter_choices: Array[Array] = []
var chosen_map_path: Array[int] = []
var pending_rest_heal: int = 0
var current_shop_inventory: Array[Dictionary] = []
var current_shop_is_black: bool = false
var current_event_variant: String = "shrine"
var relics: Array[RelicData] = []
var ascension_level: int = 0
var map_seed: int = 0

# Convenience aliases — 對應 active character。讓單角色時期的 main.gd 程式碼幾乎不用改。
var character: CharacterData:
	get:
		if characters.is_empty() or active_character_index >= characters.size():
			return null
		return characters[active_character_index]
	set(value):
		if value == null:
			characters = []
			return
		if characters.is_empty():
			characters.append(value)
			active_character_index = 0
		else:
			characters[active_character_index] = value

var hp: int:
	get:
		if character_hps.is_empty() or active_character_index >= character_hps.size():
			return 0
		return character_hps[active_character_index]
	set(value):
		if active_character_index < character_hps.size():
			character_hps[active_character_index] = value

var max_hp: int:
	get:
		if character_max_hps.is_empty() or active_character_index >= character_max_hps.size():
			return 0
		return character_max_hps[active_character_index]
	set(value):
		if active_character_index < character_max_hps.size():
			character_max_hps[active_character_index] = value

var power_bonus: int:
	get:
		if character_power_bonus.is_empty() or active_character_index >= character_power_bonus.size():
			return 0
		return character_power_bonus[active_character_index]
	set(value):
		if active_character_index < character_power_bonus.size():
			character_power_bonus[active_character_index] = value

var deck: Array[CardData]:
	get:
		if character_decks.is_empty() or active_character_index >= character_decks.size():
			var empty: Array[CardData] = []
			return empty
		return character_decks[active_character_index] as Array[CardData]
	set(value):
		if active_character_index < character_decks.size():
			character_decks[active_character_index] = value

func init_for(chars: Variant) -> void:
	# 接受單 CharacterData（沿用舊呼叫）或 Array[CharacterData]
	var party: Array[CharacterData] = []
	if chars is CharacterData:
		party.append(chars as CharacterData)
	elif chars is Array:
		for c_v: Variant in (chars as Array):
			if c_v is CharacterData:
				party.append(c_v as CharacterData)
	if party.is_empty():
		push_warning("RunState.init_for: empty party")
		return
	characters.clear()
	character_hps.clear()
	character_max_hps.clear()
	character_power_bonus.clear()
	character_decks.clear()
	active_character_index = 0
	for c: CharacterData in party:
		characters.append(c)
		character_hps.append(c.max_hp)
		character_max_hps.append(c.max_hp)
		character_power_bonus.append(0)
		var deck_copy: Array[CardData] = []
		for card: CardData in c.starting_deck:
			deck_copy.append(card.clone())
		character_decks.append(deck_copy)
	act = 1
	gold = STARTING_GOLD
	encounter_index = 0
	encounter_choices = []
	chosen_map_path = []
	pending_rest_heal = 0
	current_shop_inventory = []
	current_shop_is_black = false
	current_event_variant = "shrine"
	relics.clear()
	# 每人各拿自己的 starter weapon
	for c: CharacterData in party:
		var weapons: Array[RelicData] = RelicCatalog.weapons_for_character(c.id)
		if not weapons.is_empty():
			add_relic(weapons[0])

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
					# MVP: 只給隊長
					if not character_max_hps.is_empty():
						character_max_hps[0] += amount
						character_hps[0] += amount

func heal(amount: int) -> void:
	# 對 active 角色補血（rest_node / event 的原本語意：補當前玩家）
	if active_character_index >= character_hps.size():
		return
	character_hps[active_character_index] = min(character_max_hps[active_character_index], character_hps[active_character_index] + amount)

func take_damage(amount: int, minimum: int = 1) -> void:
	if active_character_index >= character_hps.size():
		return
	character_hps[active_character_index] = max(minimum, character_hps[active_character_index] - amount)

func sync_hp_from_battle(battle_hp: int) -> void:
	if active_character_index < character_hps.size():
		character_hps[active_character_index] = battle_hp

func is_all_dead() -> bool:
	for h: int in character_hps:
		if h > 0:
			return false
	return true

func alive_character_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in range(character_hps.size()):
		if character_hps[i] > 0:
			result.append(i)
	return result

func to_dict() -> Dictionary:
	var character_ids: Array[String] = []
	for c: CharacterData in characters:
		character_ids.append(c.id)
	var character_decks_data: Array = []
	for cdeck_v: Variant in character_decks:
		var cdeck: Array = cdeck_v as Array
		var deck_data: Array[Dictionary] = []
		for card: CardData in cdeck:
			deck_data.append(card.to_dict())
		character_decks_data.append(deck_data)
	var relics_data: Array[Dictionary] = []
	for r: RelicData in relics:
		relics_data.append(r.to_dict())
	return {
		"version": 3,
		"act": act,
		"character_ids": character_ids,
		"character_hps": character_hps.duplicate(),
		"character_max_hps": character_max_hps.duplicate(),
		"character_power_bonus": character_power_bonus.duplicate(),
		"character_decks": character_decks_data,
		"active_character_index": active_character_index,
		"gold": gold,
		"encounter_index": encounter_index,
		"encounter_choices": _serialize_choices(),
		"chosen_map_path": chosen_map_path.duplicate(),
		"pending_rest_heal": pending_rest_heal,
		"current_shop_inventory": _serialize_shop_inventory(),
		"current_shop_is_black": current_shop_is_black,
		"current_event_variant": current_event_variant,
		"relics": relics_data,
		"ascension_level": ascension_level,
		"map_seed": map_seed
	}

func from_dict(data: Dictionary, available_characters: Array[CharacterData]) -> bool:
	# SaveManager.migrate 之後 data 必有 character_ids
	var character_ids_v: Variant = data.get("character_ids", null)
	if character_ids_v == null:
		push_warning("RunState.from_dict: missing character_ids — did SaveManager.migrate run?")
		return false
	var ids: Array = character_ids_v as Array
	characters.clear()
	for id_v: Variant in ids:
		var char_id: String = String(id_v)
		if char_id.is_empty():
			return false
		var found: CharacterData = null
		for candidate: CharacterData in available_characters:
			if candidate.id == char_id:
				found = candidate.clone()
				break
		if found == null:
			return false
		characters.append(found)
	character_hps.clear()
	for h_v: Variant in (data.get("character_hps", []) as Array):
		character_hps.append(int(h_v))
	while character_hps.size() < characters.size():
		character_hps.append(characters[character_hps.size()].max_hp)
	character_max_hps.clear()
	for h_v: Variant in (data.get("character_max_hps", []) as Array):
		character_max_hps.append(int(h_v))
	while character_max_hps.size() < characters.size():
		character_max_hps.append(characters[character_max_hps.size()].max_hp)
	character_power_bonus.clear()
	for h_v: Variant in (data.get("character_power_bonus", []) as Array):
		character_power_bonus.append(int(h_v))
	while character_power_bonus.size() < characters.size():
		character_power_bonus.append(0)
	character_decks.clear()
	for cdeck_v: Variant in (data.get("character_decks", []) as Array):
		var cdeck_in: Array = cdeck_v as Array
		var typed_deck: Array[CardData] = []
		for card_v: Variant in cdeck_in:
			if card_v is Dictionary:
				typed_deck.append(CardData.from_dict(card_v as Dictionary))
		character_decks.append(typed_deck)
	while character_decks.size() < characters.size():
		var empty_deck: Array[CardData] = []
		character_decks.append(empty_deck)
	active_character_index = clamp(int(data.get("active_character_index", 0)), 0, max(0, characters.size() - 1))
	gold = int(data.get("gold", 0))
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
	map_seed = int(data.get("map_seed", 0))
	act = int(data.get("act", 1))
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
