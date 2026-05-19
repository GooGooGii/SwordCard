extends SceneTree

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()
	var enemies: Array[EnemyData] = GameData.enemies()
	assert(characters.size() == 4)
	assert(enemies.size() >= 4)
	for character: CharacterData in characters:
		assert(character.display_name.length() > 0)
		assert(character.max_hp > 0)
		assert(character.starting_deck.size() >= 5)
		assert(character.reward_pool.size() >= 3)
		var deck: DeckManager = DeckManager.new()
		deck.setup(character.starting_deck)
		var drawn: Array[CardData] = deck.draw(5)
		assert(drawn.size() == 5)
		var enemy: EnemyData = enemies[0].clone()
		var state: Dictionary = {
			"player_name": character.display_name,
			"player_max_hp": character.max_hp,
			"player_hp": character.max_hp,
			"player_block": 0,
			"player_poison": 0,
			"player_weak": 0,
			"player_power": 0,
			"enemy_name": enemy.display_name,
			"enemy_max_hp": enemy.max_hp,
			"enemy_hp": enemy.max_hp,
			"enemy_block": 0,
			"enemy_poison": 0,
			"enemy_weak": 0,
			"enemy_vulnerable": 0,
			"energy": 99,
			"pending_draw": 0,
			"turn": 1,
			"li_discount_used": false,
			"lin_block_used": false
		}
		var resolver: EffectResolver = EffectResolver.new()
		for card: CardData in drawn:
			resolver.resolve_card(card, state)
		resolver.resolve_enemy_action(enemy.actions[0], state)
		var first_card: CardData = character.starting_deck[0]
		var upgraded_card: CardData = first_card.upgraded_copy()
		assert(upgraded_card.upgraded)
		assert(upgraded_card.display_title().ends_with("+"))
		assert(upgraded_card.effects.size() == first_card.effects.size())
	var normal_count: int = 0
	var boss_count: int = 0
	for enemy: EnemyData in enemies:
		if enemy.id == "moon_worshipper":
			boss_count = boss_count + 1
		else:
			normal_count = normal_count + 1
	assert(normal_count >= 3)
	assert(boss_count == 1)
	print("SwordCard smoke test passed.")
	quit(0)
