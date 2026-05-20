extends SceneTree

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()
	var enemies: Array[EnemyData] = GameData.enemies()
	assert(characters.size() == 4)
	assert(enemies.size() >= 6)
	for character: CharacterData in characters:
		assert(character.display_name.length() > 0)
		assert(character.max_hp > 0)
		assert(character.starting_deck.size() >= 5)
		assert(character.reward_pool.size() >= 5)
		for reward_card: CardData in character.reward_pool:
			assert(ResourceLoader.exists(reward_card.art_path))
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
			"player_vulnerable": 0,
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
		state["player_weak"] = 2
		state["enemy_hp"] = enemy.max_hp
		var weak_test_card: CardData = GameData.make_card("weak_test", "虛弱測試", character.display_name, 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}])
		resolver.resolve_card(weak_test_card, state)
		assert(int(state["enemy_hp"]) == enemy.max_hp - 8)
		state["player_weak"] = 0
		state["enemy_hp"] = enemy.max_hp
		for card: CardData in drawn:
			resolver.resolve_card(card, state)
		resolver.resolve_enemy_action(enemy.actions[0], state)
		var first_card: CardData = character.starting_deck[0]
		var upgraded_card: CardData = first_card.upgraded_copy()
		assert(upgraded_card.upgraded)
		assert(upgraded_card.display_title().ends_with("+"))
		assert(upgraded_card.effects.size() == first_card.effects.size())
	var bosses: Array[EnemyData] = GameData.bosses()
	assert(enemies.size() >= 6)
	assert(bosses.size() >= 1)
	for boss: EnemyData in bosses:
		assert(boss.max_hp >= 60)
		assert(boss.actions.size() >= 3)
	var map_layer: MapLinkLayer = MapLinkLayer.new()
	map_layer.set_segments([{"from": Vector2.ZERO, "to": Vector2(10, 10), "active": true}])
	assert(map_layer.segments.size() == 1)
	map_layer.free()
	print("SwordCard smoke test passed.")
	quit(0)
