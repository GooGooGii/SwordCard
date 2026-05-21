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
	_test_save_round_trip(characters)
	_test_save_manager_cycle(characters)
	_test_battle_status_stacking(characters[0], enemies[0])
	print("SwordCard smoke test passed.")
	quit(0)

func _test_save_round_trip(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	state.gold = 123
	state.encounter_index = 4
	state.pending_rest_heal = 7
	state.current_shop_is_black = true
	state.current_event_variant = "ruins"
	var dict: Dictionary = state.to_dict()
	var text: String = JSON.stringify(dict)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "round-trip JSON parse failed")
	var restored: RunState = RunState.new()
	assert(restored.from_dict(parsed as Dictionary, characters), "from_dict rejected valid save")
	assert(restored.gold == 123, "gold mismatch")
	assert(restored.encounter_index == 4, "encounter_index mismatch")
	assert(restored.pending_rest_heal == 7, "pending_rest_heal mismatch")
	assert(restored.current_shop_is_black == true, "current_shop_is_black mismatch")
	assert(restored.current_event_variant == "ruins", "current_event_variant mismatch")
	assert(restored.character.id == state.character.id, "character_id mismatch")
	assert(restored.deck.size() == state.deck.size(), "deck size mismatch")
	assert(restored.relics.size() == state.relics.size(), "relics size mismatch")

func _test_save_manager_cycle(characters: Array[CharacterData]) -> void:
	SaveManager.clear()
	var state: RunState = RunState.new()
	state.init_for(characters[1])
	state.gold = 999
	assert(SaveManager.save(state), "SaveManager.save failed")
	assert(SaveManager.has_save(), "save file missing after save")
	var loaded: Dictionary = SaveManager.load_save()
	assert(int(loaded.get("gold", 0)) == 999, "loaded gold mismatch")
	assert(int(loaded.get("save_version", 0)) == SaveManager.SAVE_VERSION, "save_version not stamped")
	var restored: RunState = RunState.new()
	assert(restored.from_dict(loaded, characters), "SaveManager round-trip from_dict failed")
	assert(restored.character.id == characters[1].id, "character mismatch after SaveManager cycle")
	SaveManager.clear()

func _test_battle_status_stacking(character: CharacterData, enemy_template: EnemyData) -> void:
	var enemy: EnemyData = enemy_template.clone()
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
		"enemy_poison": 3,
		"enemy_weak": 0,
		"enemy_vulnerable": 2,
		"energy": 99,
		"pending_draw": 0,
		"turn": 1,
		"li_discount_used": false,
		"lin_block_used": false
	}
	var resolver: EffectResolver = EffectResolver.new()
	# 破綻 +50%：10 點傷害應變成 15
	var vuln_card: CardData = GameData.make_card("vuln_test", "破綻測試", character.display_name, 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}])
	var hp_before: int = int(state["enemy_hp"])
	resolver.resolve_card(vuln_card, state)
	var hp_after: int = int(state["enemy_hp"])
	assert(hp_before - hp_after == 15, "vulnerable damage multiplier broken: lost %d expected 15" % (hp_before - hp_after))
	# 護甲吸收：給敵人 8 block，5 點傷害應全擋
	state["enemy_block"] = 8
	state["enemy_vulnerable"] = 0
	var small_card: CardData = GameData.make_card("block_test", "格擋測試", character.display_name, 1, "attack", "造成 5 點傷害。", [{"kind": "damage", "amount": 5}])
	hp_before = int(state["enemy_hp"])
	resolver.resolve_card(small_card, state)
	assert(int(state["enemy_hp"]) == hp_before, "block didn't absorb full damage")
	assert(int(state["enemy_block"]) == 3, "block remainder wrong: %d expected 3" % int(state["enemy_block"]))
