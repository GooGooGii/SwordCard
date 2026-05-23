class_name ShopInventory
extends RefCounted

const NORMAL_LIMIT: int = 5
const BLACK_LIMIT: int = 4
const BASE_PRICE: int = 26
const UNCOMMON_PRICE: int = 38
const RARE_PRICE: int = 56
const UPGRADE_PRICE_BONUS: int = 16
const BLACK_PRICE_MULTIPLIER: float = 1.25
const BLACK_PRICE_FLAT_BONUS: int = 12
const SALE_CHANCE: float = 0.35
const SALE_DISCOUNT: float = 0.5

static func build(character: CharacterData, is_black_shop: bool) -> Array[Dictionary]:
	var pool: Array[CardData] = _black_pool(character) if is_black_shop else _normal_pool(character)
	var limit: int = BLACK_LIMIT if is_black_shop else NORMAL_LIMIT
	var inventory: Array[Dictionary] = []
	for i: int in range(min(limit, pool.size())):
		var card: CardData = pool[i].clone()
		if is_black_shop and not card.upgraded:
			card = card.upgraded_copy()
		inventory.append({"card": card, "price": price_of(card, is_black_shop), "on_sale": false})
	if not is_black_shop and inventory.size() > 0 and randf() < SALE_CHANCE:
		var sale_idx: int = randi() % inventory.size()
		inventory[sale_idx]["price"] = max(5, int(inventory[sale_idx]["price"] * (1.0 - SALE_DISCOUNT)))
		inventory[sale_idx]["on_sale"] = true
	return inventory

static func price_of(card: CardData, is_black_shop: bool) -> int:
	var base_price: int = BASE_PRICE
	match card.rarity:
		"uncommon":
			base_price = UNCOMMON_PRICE
		"rare":
			base_price = RARE_PRICE
	if card.upgraded:
		base_price = base_price + UPGRADE_PRICE_BONUS
	if is_black_shop:
		return int(ceil(base_price * BLACK_PRICE_MULTIPLIER)) + BLACK_PRICE_FLAT_BONUS
	return base_price

static func _normal_pool(character: CharacterData) -> Array[CardData]:
	var pool: Array[CardData] = []
	var used_ids: Array[String] = []
	for card: CardData in character.reward_pool:
		if not used_ids.has(card.id):
			used_ids.append(card.id)
			pool.append(card.clone())
	pool.shuffle()
	return pool

static func _black_pool(character: CharacterData) -> Array[CardData]:
	var rare_cards: Array[CardData] = []
	var uncommon_cards: Array[CardData] = []
	var basic_cards: Array[CardData] = []
	for card: CardData in _character_card_pool(character):
		match card.rarity:
			"rare":
				rare_cards.append(card.clone())
			"uncommon":
				uncommon_cards.append(card.clone())
			_:
				basic_cards.append(card.clone())
	rare_cards.shuffle()
	uncommon_cards.shuffle()
	basic_cards.shuffle()
	var pool: Array[CardData] = []
	pool.append_array(rare_cards)
	pool.append_array(uncommon_cards)
	pool.append_array(basic_cards)
	return pool

static func _character_card_pool(character: CharacterData) -> Array[CardData]:
	var pool: Array[CardData] = []
	var used_ids: Array[String] = []
	var sources: Array = [character.starting_deck, character.reward_pool]
	for source: Array in sources:
		for card: CardData in source:
			if not used_ids.has(card.id):
				used_ids.append(card.id)
				pool.append(card.clone())
	return pool
