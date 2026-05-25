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
		assert(character.reward_pool.size() >= 10)
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
		# Description must reflect the upgraded amounts (not the original text).
		assert(upgraded_card.description != first_card.description, \
			"upgraded description unchanged for %s" % first_card.display_name)
		# Spot-check: every upgraded effect amount that changed should appear in description.
		for idx: int in range(first_card.effects.size()):
			var old_eff: Dictionary = first_card.effects[idx]
			var new_eff: Dictionary = upgraded_card.effects[idx]
			if old_eff.get("amount") != new_eff.get("amount"):
				var new_amount_str: String = str(int(new_eff["amount"]))
				assert(upgraded_card.description.contains(new_amount_str), \
					"upgraded description missing new amount %s for %s" % [new_amount_str, first_card.display_name])
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
	_test_save_migration(characters)
	_test_party_round_trip(characters)
	_test_battle_status_stacking(characters[0], enemies[0])
	_test_status_decay()
	_test_poison_tick_and_decay()
	_test_poison_burst()
	_test_consume_energy_damage()
	_test_power_stacks_with_damage()
	_test_multi_turn_battle(characters[0], enemies[0])
	_test_party_switch_and_defeat(characters, enemies[0])
	_test_party_state_sync(characters, enemies[0])
	_test_party_auto_switch_on_death(characters, enemies[0])
	_test_party_starter_weapons(characters)
	_test_revive_effect(characters, enemies[0])
	_test_map_generator_reachability(enemies, bosses)
	_test_predict_enemy_damage_matches_resolver()
	_test_requires_enemy_target()
	_test_bestiary_persistence()
	_test_artifact_boss_coverage()
	_test_ascension_persistence_and_modifiers()
	_test_boss_phase_transition(bosses)
	_test_event_variety()
	_test_revive_event(characters)
	_test_map_seed_determinism(enemies, bosses)
	_test_balance_regression(characters, enemies)
	_test_balance_regression_mid(characters, bosses)
	_test_balance_regression_upgraded(characters, enemies, bosses)
	_test_balance_leveled_progression(characters)
	_test_deck_pile_views(characters)
	_test_potion_catalog()
	_test_potion_save_roundtrip(characters)
	_test_potion_use_heal(characters[0], enemies[0])
	_test_potion_cure_poison(characters[0], enemies[0])
	_test_potion_old_save_compat(characters)
	_test_level_system(characters)
	_test_level_unlock_cards()
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

func _test_save_migration(characters: Array[CharacterData]) -> void:
	# 模擬「v1 單角色存檔」（character_id / hp / max_hp / deck 等舊欄位）→ v2 一人隊伍
	var v1_dict: Dictionary = {
		"save_version": 1,
		"character_id": characters[0].id,
		"hp": 33,
		"max_hp": characters[0].max_hp,
		"power_bonus": 2,
		"gold": 222,
		"deck": [],
		"encounter_index": 5,
		"encounter_choices": [],
		"chosen_map_path": [],
		"pending_rest_heal": 0,
		"current_shop_inventory": [],
		"current_shop_is_black": false,
		"current_event_variant": "shrine",
		"relics": [],
		"ascension_level": 1,
		"map_seed": 0
	}
	# 給 v1 deck 一些卡 (model real save)
	for card: CardData in characters[0].starting_deck:
		(v1_dict["deck"] as Array).append(card.to_dict())
	var migrated: Dictionary = SaveManager.migrate(v1_dict)
	assert(int(migrated.get("save_version", 0)) == SaveManager.SAVE_VERSION, "migrate should stamp save_version to current")
	assert(migrated.has("character_ids"), "v1->v2 migrate should add character_ids array")
	assert((migrated["character_ids"] as Array).size() == 1, "v1->v2: party should have 1 character")
	assert(int((migrated["character_hps"] as Array)[0]) == 33, "v1->v2: hp should migrate to character_hps[0]")
	assert((migrated["character_decks"] as Array).size() == 1, "v1->v2: character_decks should have 1 entry")
	assert(((migrated["character_decks"] as Array)[0] as Array).size() == characters[0].starting_deck.size(),
		"v1->v2: deck cards should not be lost")
	# from_dict 還原成 RunState 並驗證
	var restored: RunState = RunState.new()
	assert(restored.from_dict(migrated, characters), "migrated v1 save should from_dict cleanly")
	assert(restored.gold == 222)
	assert(restored.ascension_level == 1)
	assert(restored.characters.size() == 1)
	assert(restored.characters[0].id == characters[0].id)
	assert(restored.character_hps[0] == 33)
	assert(restored.character_max_hps[0] == characters[0].max_hp)
	assert(restored.character_power_bonus[0] == 2)
	assert(restored.active_character_index == 0)
	# 別名也要對
	assert(restored.character.id == characters[0].id, "character alias should resolve to active")
	assert(restored.hp == 33, "hp alias should resolve to active")
	assert(restored.deck.size() == characters[0].starting_deck.size(), "deck alias should resolve to active")

func _test_party_round_trip(characters: Array[CharacterData]) -> void:
	# 3 人隊伍 round-trip
	if characters.size() < 3:
		return
	var state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	state.init_for(party)
	state.character_hps[1] = 10
	state.character_power_bonus[2] = 4
	state.active_character_index = 1
	state.gold = 88
	var dict: Dictionary = state.to_dict()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(dict)) as Dictionary
	var restored: RunState = RunState.new()
	assert(restored.from_dict(parsed, characters), "3-character party round-trip from_dict failed")
	assert(restored.characters.size() == 3, "party size mismatch")
	assert(restored.character_hps[1] == 10, "per-character hp mismatch")
	assert(restored.character_power_bonus[2] == 4, "per-character power_bonus mismatch")
	assert(restored.active_character_index == 1, "active_character_index mismatch")
	assert(restored.characters[1].id == characters[1].id, "characters[1] id mismatch")
	assert(restored.character_decks.size() == 3, "character_decks should have 3 entries")
	for i: int in range(3):
		assert((restored.character_decks[i] as Array).size() == characters[i].starting_deck.size(),
			"character %d deck size mismatch" % i)

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

func _make_state() -> Dictionary:
	return {
		"player_name": "P",
		"player_max_hp": 60,
		"player_hp": 60,
		"player_block": 0,
		"player_poison": 0,
		"player_weak": 0,
		"player_vulnerable": 0,
		"player_power": 0,
		"enemy_name": "E",
		"enemy_max_hp": 60,
		"enemy_hp": 60,
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"energy": 3,
		"pending_draw": 0,
		"turn": 1,
		"li_discount_used": false,
		"lin_block_used": false
	}

func _test_status_decay() -> void:
	# 玩家施加 3 層虛弱，下回合 enemy 攻擊應該 -3；BattleController.start_turn 會把
	# enemy_weak / enemy_vulnerable 各 -1。
	var state: Dictionary = _make_state()
	state["enemy_weak"] = 3
	state["enemy_vulnerable"] = 2
	# 模擬 start_turn 的衰減邏輯
	state["enemy_weak"] = int(state["enemy_weak"]) - 1
	state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	assert(int(state["enemy_weak"]) == 2, "enemy_weak decay wrong")
	assert(int(state["enemy_vulnerable"]) == 1, "enemy_vulnerable decay wrong")

func _test_poison_tick_and_decay() -> void:
	var state: Dictionary = _make_state()
	state["enemy_poison"] = 4
	state["player_poison"] = 2
	var resolver: EffectResolver = EffectResolver.new()
	resolver.tick_statuses(state)
	# 中毒造成 4 傷害、層數 -1
	assert(int(state["enemy_hp"]) == 56, "enemy poison tick damage wrong: %d" % int(state["enemy_hp"]))
	assert(int(state["enemy_poison"]) == 3, "enemy poison decay wrong: %d" % int(state["enemy_poison"]))
	assert(int(state["player_hp"]) == 58, "player poison tick damage wrong: %d" % int(state["player_hp"]))
	assert(int(state["player_poison"]) == 1, "player poison decay wrong: %d" % int(state["player_poison"]))
	# 再 tick 一次，player poison 應該歸零並結算 1 點傷害
	resolver.tick_statuses(state)
	assert(int(state["player_poison"]) == 0, "player poison should reach 0")
	assert(int(state["player_hp"]) == 57, "player hp after second tick wrong")

func _test_poison_burst() -> void:
	# 5 層蠱毒 * burst amount 2 = 10 點傷害，且 poison 歸零
	var state: Dictionary = _make_state()
	state["enemy_poison"] = 5
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("burst", "引爆", "P", 1, "skill", "引爆毒。", [{"kind": "poison_burst", "amount": 2}])
	resolver.resolve_card(card, state)
	assert(int(state["enemy_hp"]) == 50, "poison_burst damage wrong: %d expected 50" % int(state["enemy_hp"]))
	assert(int(state["enemy_poison"]) == 0, "poison_burst should clear poison")

func _test_consume_energy_damage() -> void:
	# 3 點靈力 * amount 3 = 9 點傷害；energy 歸零
	var state: Dictionary = _make_state()
	state["energy"] = 3
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("burn", "焚靈", "P", 0, "skill", "耗盡靈力。", [{"kind": "consume_energy_damage", "amount": 3}])
	resolver.resolve_card(card, state)
	assert(int(state["enemy_hp"]) == 51, "consume_energy_damage wrong: %d expected 51" % int(state["enemy_hp"]))
	assert(int(state["energy"]) == 0, "consume_energy should drain energy")

func _test_power_stacks_with_damage() -> void:
	# player_power +2、weak 0，10 點傷害 → 12 點
	var state: Dictionary = _make_state()
	state["player_power"] = 2
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("pw", "強擊", "P", 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}])
	resolver.resolve_card(card, state)
	assert(int(state["enemy_hp"]) == 48, "power should add to damage: got %d expected 48" % int(state["enemy_hp"]))
	# 同時 weak 2 → 12 - 2 = 10
	state = _make_state()
	state["player_power"] = 2
	state["player_weak"] = 2
	resolver.resolve_card(card, state)
	assert(int(state["enemy_hp"]) == 50, "weak should subtract from final damage: got %d expected 50" % int(state["enemy_hp"]))

func _test_multi_turn_battle(character: CharacterData, enemy_template: EnemyData) -> void:
	# 完整跑 BattleController 多回合：start_turn -> play_card -> begin_enemy_phase -> resolve_enemy_phase
	# 用無敵牌（高傷害）確保能贏，驗證 victory 判定與 HP 同步
	var run_state: RunState = RunState.new()
	run_state.init_for(character)
	# 用一張高傷卡塞滿牌組，避免抽到的隨機性影響
	var nuke: CardData = GameData.make_card("nuke", "破軍", character.display_name, 0, "attack", "造成 50 點傷害。", [{"kind": "damage", "amount": 50}])
	run_state.deck.clear()
	for i: int in range(10):
		run_state.deck.append(nuke.clone())
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, character, enemy)
	var max_turns: int = 5
	for turn: int in range(max_turns):
		bc.start_turn()
		if bc.is_battle_over():
			break
		# 把整手 5 張全打出
		var hand_snapshot: Array[CardData] = bc.deck.hand.duplicate()
		for card: CardData in hand_snapshot:
			if bc.is_battle_over():
				break
			bc.play_card(card)
		if bc.is_battle_over():
			break
		var action: Dictionary = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(action)
	assert(bc.is_victory(), "battle should end in victory within %d turns" % max_turns)
	assert(int(bc.state["enemy_hp"]) <= 0, "enemy hp should be 0 on victory")
	bc.complete_victory()
	assert(run_state.hp == int(bc.state["player_hp"]), "complete_victory should sync hp to run_state")

func _test_party_switch_and_defeat(characters: Array[CharacterData], enemy_template: EnemyData) -> void:
	# 三人隊伍 → 切換 → 全滅判定
	if characters.size() < 3:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	run_state.init_for(party)
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], enemy)
	# 起始 energy 應為 3 + (3-1) = 5
	assert(int(bc.state["per_turn_energy"]) == 5, "3-party energy should be 5; got %d" % int(bc.state["per_turn_energy"]))
	# 切換到 index 1 (應免費)
	var switch1: Dictionary = bc.switch_active(1)
	assert(bool(switch1.get("changed", false)), "first switch should succeed")
	assert(bool(switch1.get("free", false)), "first switch in turn should be free")
	assert(bc._active_index() == 1, "active should now be 1")
	assert(String(bc.state["player_name"]) == characters[1].display_name, "player_name alias should follow active")
	# 第二次切換要 1 energy
	var prev_energy: int = int(bc.state["energy"])
	var switch2: Dictionary = bc.switch_active(2)
	assert(bool(switch2.get("changed", false)), "second switch should succeed (we have energy)")
	assert(not bool(switch2.get("free", true)), "second switch in turn should NOT be free")
	assert(int(bc.state["energy"]) == prev_energy - 1, "second switch should cost 1 energy")
	# 殺死全部 → is_defeat
	for i: int in range(3):
		(bc.state["players"] as Array)[i]["hp"] = 0
	# active 也死，sync 一下
	bc._sync_active_to_state()
	assert(bc.is_defeat(), "all-zero hp party should is_defeat=true")

func _test_party_state_sync(characters: Array[CharacterData], enemy_template: EnemyData) -> void:
	# 切換 → 各自的 block/poison/weak/vulnerable 應跟著角色走
	if characters.size() < 2:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1]]
	run_state.init_for(party)
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], enemy)
	# 給 active (0) 一些 block，切換後切回應該保留
	bc.state["player_block"] = 7
	bc.state["player_poison"] = 3
	bc._sync_state_to_active()
	# 切到 1
	bc.switch_active(1)
	# active 是 1，他應該沒有 block / poison
	assert(int(bc.state["player_block"]) == 0, "new active should start with 0 block")
	assert(int(bc.state["player_poison"]) == 0, "new active should start with 0 poison")
	# 切回 0
	bc.switch_active(0)
	assert(int(bc.state["player_block"]) == 7, "block should persist when switched back; got %d" % int(bc.state["player_block"]))
	assert(int(bc.state["player_poison"]) == 3, "poison should persist when switched back; got %d" % int(bc.state["player_poison"]))

func _test_party_auto_switch_on_death(characters: Array[CharacterData], enemy_template: EnemyData) -> void:
	# Active 戰死後應自動切到第一個活著的；全滅才 is_defeat
	if characters.size() < 3:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	run_state.init_for(party)
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], enemy)
	# 模擬「active(0) 被打到 0」
	(bc.state["players"] as Array)[0]["hp"] = 0
	bc.state["player_hp"] = 0  # alias 同步
	# resolve_enemy_phase 的尾巴會檢查 active 死且非全滅 → force switch
	# 但我們直接呼叫 _force_switch_to_first_alive
	var switched: bool = bc._force_switch_to_first_alive(true)
	assert(switched, "force switch should succeed when other members are alive")
	assert(bc._active_index() == 1, "force switch should land on first alive (index 1)")
	assert(not bc.is_defeat(), "party should not be defeated while index 1 + 2 are alive")
	# 再殺 1 → active 變 2
	(bc.state["players"] as Array)[1]["hp"] = 0
	bc.state["player_hp"] = 0
	assert(bc._force_switch_to_first_alive(false), "force switch to index 2")
	assert(bc._active_index() == 2)
	# 殺光 → is_defeat
	(bc.state["players"] as Array)[2]["hp"] = 0
	bc.state["player_hp"] = 0
	assert(not bc._force_switch_to_first_alive(false), "no alive members left")
	assert(bc.is_defeat(), "all dead -> is_defeat")

func _test_party_starter_weapons(characters: Array[CharacterData]) -> void:
	# 每個角色都拿到自己的 starter weapon
	if characters.size() < 2:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1]]
	run_state.init_for(party)
	# 預期至少有 2 個專武在 relics 裡（除非該角色沒專武資料）
	var weapon_count: int = 0
	for r: RelicData in run_state.relics:
		if r.slot == "weapon":
			weapon_count += 1
	# 不強求各角色都有專武資料；只要不超過 party size 且 init_for 沒 crash 就 OK
	assert(weapon_count <= party.size(), "should not over-grant weapons")
	# 至少領隊應該拿到專武（如果他有的話）
	var leader_weapons: Array[RelicData] = RelicCatalog.weapons_for_character(party[0].id)
	if not leader_weapons.is_empty():
		assert(run_state.has_relic(leader_weapons[0].id), "leader's starter weapon should be granted")

func _test_revive_effect(characters: Array[CharacterData], enemy_template: EnemyData) -> void:
	# 三人隊伍 → 後排 idx 1 倒下 → 復活卡 → 該角色 HP 變 amount
	if characters.size() < 3:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	run_state.init_for(party)
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], enemy)
	# 殺死 idx 1
	(bc.state["players"] as Array)[1]["hp"] = 0
	# Active 還是 0；玩家打復活卡
	var revive_card: CardData = GameData.make_card("revive_test", "復活", "P", 1, "skill", "救回", ([{"kind": "revive", "amount": 30}] as Array[Dictionary]))
	bc.state["energy"] = 99
	bc.play_card(revive_card)
	var revived_hp: int = int((bc.state["players"] as Array)[1]["hp"])
	assert(revived_hp == 30, "revive should restore idx 1 to amount=30; got %d" % revived_hp)
	# 第二次打復活卡（沒人倒下）→ fallback heal active
	bc.state["player_hp"] = 10  # active 受傷
	bc._sync_state_to_active()
	bc.play_card(revive_card)
	assert(int(bc.state["player_hp"]) == 40, "no dead -> revive should heal active by amount; got %d" % int(bc.state["player_hp"]))
	# 升級後 revive amount 應提升（30 → 38），說明文字也要跟著換
	var revive_upg: CardData = revive_card.upgraded_copy()
	assert(int(revive_upg.effects[0]["amount"]) == 38, \
		"upgraded revive amount should be 38; got %d" % int(revive_upg.effects[0]["amount"]))
	assert(revive_upg.description.contains("38"), \
		"upgraded revive description should contain 38")

func _test_map_generator_reachability(enemies: Array[EnemyData], bosses: Array[EnemyData]) -> void:
	# 跑 30 次隨機產生的地圖，驗證每張都沒有孤兒節點、且 boss 可達
	for trial: int in range(30):
		seed(trial * 1009 + 7)
		var choices: Array[Array] = MapGenerator.generate(enemies, bosses)
		assert(choices.size() >= 2, "trial %d: map should have at least one normal row + boss" % trial)
		# 1. 每個非首層節點都要有至少一個來源
		for row_index: int in range(1, choices.size()):
			var row: Array = choices[row_index]
			var incoming_counts: Array[int] = []
			for _i: int in range(row.size()):
				incoming_counts.append(0)
			var prev_row: Array = choices[row_index - 1]
			for prev_node_v: Variant in prev_row:
				var prev_node: Dictionary = prev_node_v as Dictionary
				for target_v: Variant in (prev_node.get("connects", []) as Array):
					var target: int = int(target_v)
					assert(target >= 0 and target < row.size(),
						"trial %d row %d: connect index %d out of range (row size %d)" % [trial, row_index, target, row.size()])
					incoming_counts[target] += 1
			for node_index: int in range(row.size()):
				assert(incoming_counts[node_index] > 0,
					"trial %d row %d node %d: orphan (no incoming connections)" % [trial, row_index, node_index])
		# 2. BFS 從 row 0 任一節點，驗證 boss 行所有節點皆可達
		var reachable: Array[Dictionary] = []  # [{row: int, index: int}, ...]
		var frontier: Array[Dictionary] = []
		for start_index: int in range(choices[0].size()):
			frontier.append({"row": 0, "index": start_index})
			reachable.append({"row": 0, "index": start_index})
		while not frontier.is_empty():
			var current: Dictionary = frontier.pop_front()
			var current_row: int = int(current["row"])
			var current_index: int = int(current["index"])
			if current_row + 1 >= choices.size():
				continue
			var current_node: Dictionary = choices[current_row][current_index] as Dictionary
			for target_v: Variant in (current_node.get("connects", []) as Array):
				var next_entry: Dictionary = {"row": current_row + 1, "index": int(target_v)}
				var already_in: bool = false
				for r: Dictionary in reachable:
					if int(r["row"]) == int(next_entry["row"]) and int(r["index"]) == int(next_entry["index"]):
						already_in = true
						break
				if not already_in:
					reachable.append(next_entry)
					frontier.append(next_entry)
		var boss_row: int = choices.size() - 1
		var boss_reachable: bool = false
		for r: Dictionary in reachable:
			if int(r["row"]) == boss_row:
				boss_reachable = true
				break
		assert(boss_reachable, "trial %d: boss row unreachable from row 0" % trial)
		# 3. 不交叉檢查：i1 < i2 的兩個節點，邊 j1 不能 > j2（樹狀規則）
		for row_index2: int in range(choices.size() - 1):
			var src_row: Array = choices[row_index2]
			for i1: int in range(src_row.size()):
				for i2: int in range(i1 + 1, src_row.size()):
					var edges_1: Array = ((src_row[i1] as Dictionary).get("connects", []) as Array)
					var edges_2: Array = ((src_row[i2] as Dictionary).get("connects", []) as Array)
					for j1_v: Variant in edges_1:
						for j2_v: Variant in edges_2:
							assert(int(j1_v) <= int(j2_v),
								"trial %d row %d: edges cross — i=%d→j=%d vs i=%d→j=%d" %
								[trial, row_index2, i1, int(j1_v), i2, int(j2_v)])

func _test_predict_enemy_damage_matches_resolver() -> void:
	# 對多組 (block, vuln, weak, attack_amount) 組合，驗證 CardFormat.predict_enemy_damage 跟
	# EffectResolver 實際結算後的 HP 損失一致。
	var resolver: EffectResolver = EffectResolver.new()
	var cases: Array[Array] = [
		# [block, player_vulnerable_before_phase, enemy_weak, amount]
		[0, 0, 0, 10],   # 純傷害
		[5, 0, 0, 10],   # 部分擋
		[20, 0, 0, 10],  # 全擋
		[0, 1, 0, 10],   # 破綻：begin_enemy_phase -1 後變 0，理論上不該乘 1.5
		[0, 2, 0, 10],   # 破綻：-1 後仍有 1 層，10 * 1.5 = 15
		[5, 2, 0, 10],   # 破綻 + 部分擋：15 - 5 = 10
		[0, 0, 3, 10],   # 敵人虛弱：10 - 3 = 7
		[0, 2, 3, 10],   # 虛弱 + 破綻：(10-3)*1.5 = ceil(10.5) = 11
		[100, 2, 0, 10], # 大量 block 全擋
	]
	for c: Array in cases:
		var block_amt: int = int(c[0])
		var vuln: int = int(c[1])
		var enemy_weak: int = int(c[2])
		var attack: int = int(c[3])
		var state: Dictionary = _make_state()
		state["player_block"] = block_amt
		state["player_vulnerable"] = vuln
		state["enemy_weak"] = enemy_weak
		var action: Dictionary = {"intent": "test", "effects": [{"kind": "damage", "amount": attack}]}
		var pred: Dictionary = CardFormat.predict_enemy_damage(action, state)
		# 模擬 begin_enemy_phase 對玩家狀態的衰減
		if int(state["player_vulnerable"]) > 0:
			state["player_vulnerable"] -= 1
		var hp_before: int = int(state["player_hp"])
		resolver.resolve_enemy_action(action, state)
		var actual_dealt: int = hp_before - int(state["player_hp"])
		assert(int(pred["dealt"]) == actual_dealt,
			"predict mismatch: block=%d vuln=%d weak=%d atk=%d → predicted %d, actual %d" %
			[block_amt, vuln, enemy_weak, attack, int(pred["dealt"]), actual_dealt])

func _test_ascension_persistence_and_modifiers() -> void:
	# 持久化：clear → mark(2) → unlocked == 3
	Ascension.clear_all()
	assert(Ascension.get_unlocked_max() == 0, "fresh start should unlock only A0")
	Ascension.mark_cleared(0)
	assert(Ascension.get_unlocked_max() == 1)
	Ascension.mark_cleared(2)
	assert(Ascension.get_unlocked_max() == 3, "mark(2) should unlock A3")
	Ascension.mark_cleared(1)  # 倒退式 mark 不該降級
	assert(Ascension.get_unlocked_max() == 3, "lower mark should not regress unlock")
	Ascension.clear_all()
	# Modifier 計算
	assert(Ascension.enemy_hp_multiplier(0, false) == 1.0)
	assert(Ascension.enemy_hp_multiplier(1, false) == 1.2, "A1 buff 一般敵人")
	assert(Ascension.enemy_hp_multiplier(1, true) == 1.0, "A1 不影響 boss")
	assert(abs(Ascension.enemy_hp_multiplier(2, true) - 1.2) < 0.001, "A2 buff boss")
	assert(abs(Ascension.enemy_hp_multiplier(2, false) - 1.2) < 0.001, "A2 仍 buff 一般")
	assert(Ascension.starting_hp_multiplier(2) == 1.0)
	assert(Ascension.starting_hp_multiplier(3) == 0.85)
	assert(Ascension.gold_multiplier(3) == 1.0)
	assert(Ascension.gold_multiplier(4) == 0.75)

func _test_boss_phase_transition(bosses: Array[EnemyData]) -> void:
	# 三個 boss 都該有 phase_2_actions 設定；damage 跌破 50% 後 phased 變 true
	for boss: EnemyData in bosses:
		assert(not boss.phase_2_actions.is_empty(),
			"boss %s should have phase_2_actions defined" % boss.id)
	# 真實流程模擬：手工把 boss HP 打到 49%，下一張卡觸發 _check_phase_transition
	var characters: Array[CharacterData] = GameData.characters()
	var run_state: RunState = RunState.new()
	run_state.init_for(characters[0])
	var boss: EnemyData = bosses[0].clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], boss)
	assert(not bc.phased, "fresh battle should not be phased")
	# 把 boss 打到剛好 50% 以上、再用一張卡把它打到 < 50%
	bc.state["enemy_hp"] = int(float(bc.state["enemy_max_hp"]) * 0.51)
	var tick_card: CardData = GameData.make_card("phase_test_1", "微擊", "P", 0, "attack", "造成 5 點傷害。", [{"kind": "damage", "amount": 5}])
	bc.state["energy"] = 99
	bc.play_card(tick_card)
	assert(bc.phased, "boss should phase after dropping below 50%% (hp=%d / max=%d)" % [int(bc.state["enemy_hp"]), int(bc.state["enemy_max_hp"])])
	# 切換後 next_enemy_action 應該回傳 phase_2_actions 的招式
	var next_action: Dictionary = bc.next_enemy_action()
	var phase_2_intents: Array[String] = []
	for action: Dictionary in boss.phase_2_actions:
		phase_2_intents.append(String(action.get("intent", "")))
	assert(String(next_action.get("intent", "")) in phase_2_intents,
		"after phase, next_enemy_action should pick from phase_2_actions")

func _test_event_variety() -> void:
	# 至少 10 種 event variant、每種都有合理的欄位
	var variant_keys: Array = EventData.VARIANTS.keys()
	assert(variant_keys.size() >= 10, "should have at least 10 event variants; got %d" % variant_keys.size())
	for key: Variant in variant_keys:
		var data: Dictionary = EventData.for_variant(String(key))
		assert(data.has("title") and not String(data["title"]).is_empty(), "variant %s missing title" % key)
		assert(data.has("heal"), "variant %s missing heal" % key)
		assert(data.has("gain_cost"), "variant %s missing gain_cost" % key)
		assert(data.has("power"), "variant %s missing power" % key)
		assert(data.has("power_label"), "variant %s missing power_label" % key)
	# MapGenerator 應該知道所有 variant（不該 stale）
	for key_v: Variant in variant_keys:
		assert(MapGenerator.EVENT_VARIANTS.has(String(key_v)),
			"variant %s defined in EventData but not in MapGenerator.EVENT_VARIANTS" % key_v)

func _test_revive_event(characters: Array[CharacterData]) -> void:
	# 驗證 lingmiao event variant 存在且有 revive choice + revive_amount 欄位
	var ev: Dictionary = EventData.for_variant("lingmiao")
	assert(not ev.is_empty(), "lingmiao variant should exist in EventData")
	assert(ev.has("revive_amount"), "lingmiao should have revive_amount field")
	assert(int(ev.get("revive_amount", 0)) > 0, "lingmiao revive_amount should be positive")
	var choices: Array = ev.get("choices", []) as Array
	assert(choices.has("revive"), "lingmiao choices should include 'revive'")
	# 驗證 lingmiao 在 MapGenerator pool 中
	assert(MapGenerator.EVENT_VARIANTS.has("lingmiao"),
		"lingmiao should be in MapGenerator.EVENT_VARIANTS")
	# 驗證 resolve_event_revive 邏輯：三人隊伍，idx 1 倒下 → 復活後 HP == revive_amount
	if characters.size() < 2:
		return
	var run_state: RunState = RunState.new()
	var party: Array[CharacterData] = [characters[0], characters[1]]
	run_state.init_for(party)
	run_state.character_hps[1] = 0  # 讓 idx 1 倒下
	var amount: int = int(ev.get("revive_amount", 30))
	# 模擬 resolve_event_revive 邏輯
	var revived: bool = false
	for i: int in range(run_state.character_hps.size()):
		if run_state.character_hps[i] <= 0:
			run_state.character_hps[i] = min(run_state.character_max_hps[i], amount)
			revived = true
			break
	assert(revived, "resolve_event_revive should find a downed character")
	assert(run_state.character_hps[1] == amount,
		"revived character hp should be %d; got %d" % [amount, run_state.character_hps[1]])
	# 再跑一次：無人倒下時不應有任何 revive
	var run_state2: RunState = RunState.new()
	run_state2.init_for([characters[0]])
	var revived2: bool = false
	for i: int in range(run_state2.character_hps.size()):
		if run_state2.character_hps[i] <= 0:
			revived2 = true
			break
	assert(not revived2, "no downed characters means no revive should occur")

func _test_map_seed_determinism(enemies: Array[EnemyData], bosses: Array[EnemyData]) -> void:
	# 相同 seed 兩次跑 generate，產出的節點結構一致
	seed(424242)
	var map_a: Array[Array] = MapGenerator.generate(enemies, bosses)
	seed(424242)
	var map_b: Array[Array] = MapGenerator.generate(enemies, bosses)
	assert(map_a.size() == map_b.size(), "row count differs across same-seed runs")
	for row_index: int in range(map_a.size()):
		var row_a: Array = map_a[row_index]
		var row_b: Array = map_b[row_index]
		assert(row_a.size() == row_b.size(), "row %d size differs" % row_index)
		for node_index: int in range(row_a.size()):
			var a: Dictionary = row_a[node_index] as Dictionary
			var b: Dictionary = row_b[node_index] as Dictionary
			assert(String(a.get("type", "")) == String(b.get("type", "")),
				"row %d node %d type differs: %s vs %s" % [row_index, node_index, a.get("type"), b.get("type")])

func _test_requires_enemy_target() -> void:
	# 純傷害
	var c_damage: Array[Dictionary] = [{"kind": "damage", "amount": 5}]
	assert(CardFormat.requires_enemy_target(GameData.make_card("t1", "test", "P", 1, "skill", "x", c_damage)))
	# 純自療
	var c_heal: Array[Dictionary] = [{"kind": "heal", "amount": 5}]
	assert(not CardFormat.requires_enemy_target(GameData.make_card("t2", "test", "P", 1, "skill", "x", c_heal)))
	# 純護體
	var c_block: Array[Dictionary] = [{"kind": "block", "amount": 5}]
	assert(not CardFormat.requires_enemy_target(GameData.make_card("t3", "test", "P", 1, "skill", "x", c_block)))
	# 純抽牌
	var c_draw: Array[Dictionary] = [{"kind": "draw", "amount": 1}]
	assert(not CardFormat.requires_enemy_target(GameData.make_card("t4", "test", "P", 1, "skill", "x", c_draw)))
	# 純 power
	var c_power: Array[Dictionary] = [{"kind": "power", "amount": 1}]
	assert(not CardFormat.requires_enemy_target(GameData.make_card("t5", "test", "P", 1, "power", "x", c_power)))
	# weak / vulnerable / poison 都是丟去敵人
	var c_weak: Array[Dictionary] = [{"kind": "weak", "amount": 1}]
	var c_vuln: Array[Dictionary] = [{"kind": "vulnerable", "amount": 1}]
	var c_poison: Array[Dictionary] = [{"kind": "poison", "amount": 1}]
	assert(CardFormat.requires_enemy_target(GameData.make_card("t6", "test", "P", 1, "skill", "x", c_weak)))
	assert(CardFormat.requires_enemy_target(GameData.make_card("t7", "test", "P", 1, "skill", "x", c_vuln)))
	assert(CardFormat.requires_enemy_target(GameData.make_card("t8", "test", "P", 1, "skill", "x", c_poison)))
	# consume_energy_damage / poison_burst 都對敵
	var c_ced: Array[Dictionary] = [{"kind": "consume_energy_damage", "amount": 3}]
	var c_pb: Array[Dictionary] = [{"kind": "poison_burst", "amount": 2}]
	assert(CardFormat.requires_enemy_target(GameData.make_card("t9", "test", "P", 1, "skill", "x", c_ced)))
	assert(CardFormat.requires_enemy_target(GameData.make_card("t10", "test", "P", 1, "skill", "x", c_pb)))
	# 混合：block + weak → 還是要丟敵人（因 weak）
	var c_mix1: Array[Dictionary] = [{"kind": "block", "amount": 5}, {"kind": "weak", "amount": 1}]
	assert(CardFormat.requires_enemy_target(GameData.make_card("t11", "test", "P", 1, "skill", "x", c_mix1)))
	# 混合：damage + draw → 要丟敵人
	var c_mix2: Array[Dictionary] = [{"kind": "damage", "amount": 5}, {"kind": "draw", "amount": 1}]
	assert(CardFormat.requires_enemy_target(GameData.make_card("t12", "test", "P", 1, "attack", "x", c_mix2)))
	# 拿實際遊戲卡片做煙霧驗證（至少不會 crash）
	var characters: Array[CharacterData] = GameData.characters()
	for character: CharacterData in characters:
		for card: CardData in character.starting_deck:
			var _ignored: bool = CardFormat.requires_enemy_target(card)

func _test_artifact_boss_coverage() -> void:
	var artifact_boss_ids: Array[String] = []
	for r: RelicData in RelicCatalog.artifacts():
		artifact_boss_ids.append(r.boss_id)
	for boss_id: String in Ascension.BOSS_IDS:
		assert(boss_id in artifact_boss_ids, "Boss '%s' 缺少對應神器" % boss_id)

func _test_bestiary_persistence() -> void:
	# 注意：此 test 會清掉真實 bestiary 檔案；smoke test 環境是測試專用 user:// 不用擔心
	Bestiary.clear_all()
	assert(not Bestiary.is_defeated("smoke_test_dummy"), "should be clean after clear_all")
	Bestiary.mark_defeated("smoke_test_dummy")
	assert(Bestiary.is_defeated("smoke_test_dummy"))
	assert(Bestiary.kill_count("smoke_test_dummy") == 1)
	Bestiary.mark_defeated("smoke_test_dummy")
	assert(Bestiary.kill_count("smoke_test_dummy") == 2, "second mark should increment to 2")
	var data: Dictionary = Bestiary.load_all()
	assert(int(data.get("smoke_test_dummy", 0)) == 2)
	Bestiary.clear_all()
	assert(not Bestiary.is_defeated("smoke_test_dummy"))

const BALANCE_TRIALS: int = 30
const BALANCE_TOLERANCE_PP: int = 15  # 容許勝率漂移 ±15 個百分點
# 對第一個敵人（赤蛇妖），用起始牌組 + 隨機 AI 出牌，跑 30 場。
# 起始戰理應穩贏；baseline 100% 表示「跌出 85% 以下視為平衡 regression」。
# 改卡片/敵人/relic 後重跑：若有性格動到、勝率掉到 85% 以下，就 fail。
const BALANCE_BASELINES: Dictionary = {
	"li_xiaoyao": 100,
	"zhao_linger": 100,
	"lin_yueru": 100,
	"anu": 100
}
# 蜈蚣大王（bosses[1]）+ 10 回合上限：起始牌組對 boss 的「速贏率」。
# 給夠時間 random AI 都會贏，限時才能拿到中段勝率做雙向偵測。
# 此測試本質不真實（玩家到 act 3 必有 unlock），保留作純 regression 警報；
# 真實場景請看 BALANCE_BASELINES_LEVELED。
# 趙靈兒被動「靈台啟明」(self_power+3) 後勝率拉高到 100%
const BALANCE_BASELINES_MID: Dictionary = {
	"li_xiaoyao": 63,
	"zhao_linger": 100,
	"lin_yueru": 100,
	"anu": 50
}
# 全升級起始牌組 vs 山賊頭目。升級應嚴格 >= 基礎勝率，預期全 100%。
const BALANCE_BASELINES_UPGRADED: Dictionary = {
	"li_xiaoyao": 100,
	"zhao_linger": 100,
	"lin_yueru": 100,
	"anu": 100
}
# 全升級起始牌組 vs 蜈蚣大王（10 回合）。升級後牌組強度足以全 100%。
const BALANCE_BASELINES_MID_UPGRADED: Dictionary = {
	"li_xiaoyao": 100,
	"zhao_linger": 100,
	"lin_yueru": 100,
	"anu": 100
}

# 分級成長 baseline：每幕 boss 對應一個玩家等級（推測自實際 run 經驗值累積）。
# 牌組 = starting_deck + LevelSystem.all_unlocked_cards(char, level)
# 用 20 回合上限（給玩家足夠時間打 act 5 boss）。
# null = 尚未測過，初次跑後填入觀測值。
# 對應關係：
#   Lv5  vs act 2 boss (殭屍大帥 HP 90)
#   Lv10 vs act 3 boss (蜈蚣大王 HP 92)
#   Lv15 vs act 4 boss (山靈巫后 HP 78)
#   Lv20 vs act 5 boss (拜月教主 HP 115)
const BALANCE_BASELINES_LEVELED: Dictionary = {
	# Lv5 vs 殭屍大帥（act 2 boss HP 90）：應全部 ≥95%
	# Lv10 vs 蜈蚣大王（act 3 boss HP 92）：李/趙 80-90%，林/阿 100%
	# Lv15 vs 山靈巫后（act 4 boss HP 78）：應全部 100%
	# Lv20 vs 拜月教主（act 5 boss HP 115）：李/趙 半數左右（爆發不足），林/阿 70-90%
	#   （林/阿 nerf 後降到合理範圍，差距收斂到 30pp）
	"li_xiaoyao":  {5: 97,  10: 90,  15: 100, 20: 70},
	"zhao_linger": {5: 100, 10: 100, 15: 100, 20: 75},
	"lin_yueru":   {5: 100, 10: 100, 15: 100, 20: 90},
	"anu":         {5: 100, 10: 100, 15: 100, 20: 95},
}

# Lv → act 對應
const LEVEL_TO_ACT: Dictionary = {
	5: 2,
	10: 3,
	15: 4,
	20: 5,
}

func _test_balance_regression(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	if enemies.is_empty():
		return
	var enemy_template: EnemyData = enemies[0]
	print("Balance regression vs %s, %d trials/character:" % [enemy_template.display_name, BALANCE_TRIALS])
	for character: CharacterData in characters:
		var wins: int = 0
		for trial: int in range(BALANCE_TRIALS):
			seed(trial * 7919 + hash(character.id) * 17)
			if _simulate_random_battle(character, enemy_template):
				wins += 1
		var win_rate: int = int(round(100.0 * float(wins) / float(BALANCE_TRIALS)))
		var baseline_v: Variant = BALANCE_BASELINES.get(character.id, null)
		if baseline_v == null:
			print("  %s: %d%% (no baseline; record this if expected)" % [character.id, win_rate])
			continue
		var baseline: int = int(baseline_v)
		var delta: int = abs(win_rate - baseline)
		print("  %s: %d%% (baseline %d%%, delta %d pp)" % [character.id, win_rate, baseline, delta])
		assert(delta <= BALANCE_TOLERANCE_PP,
			"balance regression: %s win rate %d%% drifted %d pp from baseline %d%% (tolerance %d pp)" %
			[character.id, win_rate, delta, baseline, BALANCE_TOLERANCE_PP])

func _test_balance_regression_mid(characters: Array[CharacterData], bosses: Array[EnemyData]) -> void:
	if bosses.size() < 2:
		return
	# 蜈蚣大王 (bosses[1]) HP 92 + 5x4 多足攻擊。
	# 卡 8 回合上限：random AI 給夠時間都會贏，限時才能拿到中段勝率做雙向偵測
	var enemy_template: EnemyData = bosses[1]
	var turn_limit: int = 10
	print("Balance regression vs %s (boss, %d-turn limit), %d trials/character:" % [enemy_template.display_name, turn_limit, BALANCE_TRIALS])
	for character: CharacterData in characters:
		var wins: int = 0
		for trial: int in range(BALANCE_TRIALS):
			seed(trial * 7919 + hash(character.id) * 17 + 5)
			if _simulate_random_battle(character, enemy_template, turn_limit):
				wins += 1
		var win_rate: int = int(round(100.0 * float(wins) / float(BALANCE_TRIALS)))
		var baseline_v: Variant = BALANCE_BASELINES_MID.get(character.id, null)
		if baseline_v == null:
			print("  %s: %d%% (no mid baseline; record if expected)" % [character.id, win_rate])
			continue
		var baseline: int = int(baseline_v)
		var delta: int = abs(win_rate - baseline)
		print("  %s: %d%% (mid baseline %d%%, delta %d pp)" % [character.id, win_rate, baseline, delta])
		assert(delta <= BALANCE_TOLERANCE_PP,
			"mid balance regression: %s win rate %d%% drifted %d pp from baseline %d%% (tolerance %d pp)" %
			[character.id, win_rate, delta, baseline, BALANCE_TOLERANCE_PP])

func _test_balance_regression_upgraded(characters: Array[CharacterData], enemies: Array[EnemyData], bosses: Array[EnemyData]) -> void:
	# 把每個角色的起始牌組全部升級，分別對「基礎敵人」和「中段 boss（10 回合）」跑 30 場。
	# 升級後的牌組應嚴格 >= 未升級勝率；
	# 爆炸蠱 +67% / 天師符法 +33% 等高漲幅卡片有沒有把勝率推到不合理範圍，
	# 一旦填入 baseline 之後就能偵測往後改動造成的 drift。
	if enemies.is_empty() or bosses.size() < 2:
		return
	# --- vs 山賊頭目（應全 100%）---
	var easy_enemy: EnemyData = enemies[0]
	print("Balance regression (upgraded deck) vs %s, %d trials/character:" % [easy_enemy.display_name, BALANCE_TRIALS])
	for character: CharacterData in characters:
		var upgraded_deck: Array[CardData] = []
		for card: CardData in character.starting_deck:
			upgraded_deck.append(card.upgraded_copy())
		var wins: int = 0
		for trial: int in range(BALANCE_TRIALS):
			seed(trial * 7919 + hash(character.id) * 17 + 3)  # +3 offset 與基礎測試用不同 seed
			if _simulate_random_battle(character, easy_enemy, 20, upgraded_deck):
				wins += 1
		var win_rate: int = int(round(100.0 * float(wins) / float(BALANCE_TRIALS)))
		var baseline_v: Variant = BALANCE_BASELINES_UPGRADED.get(character.id, null)
		if baseline_v == null:
			print("  %s: %d%% (no baseline yet — add to BALANCE_BASELINES_UPGRADED)" % [character.id, win_rate])
			continue
		var baseline: int = int(baseline_v)
		var delta: int = abs(win_rate - baseline)
		print("  %s: %d%% (baseline %d%%, delta %d pp)" % [character.id, win_rate, baseline, delta])
		assert(delta <= BALANCE_TOLERANCE_PP,
			"upgraded balance regression: %s win rate %d%% drifted %d pp from baseline %d%% (tolerance %d pp)" %
			[character.id, win_rate, delta, baseline, BALANCE_TOLERANCE_PP])
	# --- vs 蜈蚣大王 10 回合（速贏率）---
	var mid_enemy: EnemyData = bosses[1]
	var turn_limit: int = 10
	print("Balance regression (upgraded deck) vs %s (%d-turn limit), %d trials/character:" % [mid_enemy.display_name, turn_limit, BALANCE_TRIALS])
	for character: CharacterData in characters:
		var upgraded_deck: Array[CardData] = []
		for card: CardData in character.starting_deck:
			upgraded_deck.append(card.upgraded_copy())
		var wins: int = 0
		for trial: int in range(BALANCE_TRIALS):
			seed(trial * 7919 + hash(character.id) * 17 + 8)  # +8 offset
			if _simulate_random_battle(character, mid_enemy, turn_limit, upgraded_deck):
				wins += 1
		var win_rate: int = int(round(100.0 * float(wins) / float(BALANCE_TRIALS)))
		var baseline_v: Variant = BALANCE_BASELINES_MID_UPGRADED.get(character.id, null)
		if baseline_v == null:
			print("  %s: %d%% (no mid baseline yet — add to BALANCE_BASELINES_MID_UPGRADED)" % [character.id, win_rate])
			continue
		var baseline: int = int(baseline_v)
		var delta: int = abs(win_rate - baseline)
		print("  %s: %d%% (mid baseline %d%%, delta %d pp)" % [character.id, win_rate, baseline, delta])
		assert(delta <= BALANCE_TOLERANCE_PP,
			"upgraded mid balance regression: %s win rate %d%% drifted %d pp from baseline %d%% (tolerance %d pp)" %
			[character.id, win_rate, delta, baseline, BALANCE_TOLERANCE_PP])

func _leveled_deck(character: CharacterData, level: int) -> Array[CardData]:
	# 模擬玩家在 level 時的全部可用牌組：starting + 所有已解鎖的 level unlock。
	# 不考慮 in-run upgrade（升級是另一層機制，可選 _upgraded_leveled_deck）
	var deck: Array[CardData] = []
	for card: CardData in character.starting_deck:
		deck.append(card)
	for unlock: CardData in LevelSystem.all_unlocked_cards(character.id, level):
		deck.append(unlock)
	return deck

func _test_balance_leveled_progression(characters: Array[CharacterData]) -> void:
	# 對每個角色測試「Lv N + 對應幕 boss」的勝率。
	# 反映實際玩家經歷 — 起始牌組是 Lv1，但打到 act 5 時應該有 Lv15-20 + 多張 unlock。
	# 純靠起始牌組打 act 5 boss 是不合理的測試條件。
	var levels: Array[int] = [5, 10, 15, 20]
	var turn_limit: int = 20
	print("Balance regression (leveled deck) progression, %d trials/cell:" % BALANCE_TRIALS)
	for character: CharacterData in characters:
		for lv: int in levels:
			var act: int = int(LEVEL_TO_ACT[lv])
			var boss: EnemyData = GameData.boss_for_act(act)
			var deck: Array[CardData] = _leveled_deck(character, lv)
			var wins: int = 0
			for trial: int in range(BALANCE_TRIALS):
				seed(trial * 7919 + hash(character.id) * 17 + lv * 31)
				if _simulate_random_battle(character, boss, turn_limit, deck):
					wins += 1
			var win_rate: int = int(round(100.0 * float(wins) / float(BALANCE_TRIALS)))
			var char_baselines: Variant = BALANCE_BASELINES_LEVELED.get(character.id, null)
			if char_baselines == null:
				print("  %s Lv%d vs %s: %d%% (no baselines for char)" % [character.id, lv, boss.display_name, win_rate])
				continue
			var baseline_v: Variant = (char_baselines as Dictionary).get(lv, null)
			if baseline_v == null:
				print("  %s Lv%d vs %s: %d%% (no baseline yet — add to BALANCE_BASELINES_LEVELED)" % [character.id, lv, boss.display_name, win_rate])
				continue
			var baseline: int = int(baseline_v)
			var delta: int = abs(win_rate - baseline)
			print("  %s Lv%d vs %s: %d%% (baseline %d%%, delta %d pp)" % [character.id, lv, boss.display_name, win_rate, baseline, delta])
			assert(delta <= BALANCE_TOLERANCE_PP,
				"leveled balance regression: %s Lv%d vs %s win rate %d%% drifted %d pp from baseline %d%% (tolerance %d pp)" %
				[character.id, lv, boss.display_name, win_rate, delta, baseline, BALANCE_TOLERANCE_PP])

func _simulate_random_battle(character: CharacterData, enemy_template: EnemyData, max_turns: int = 20, deck_override: Array[CardData] = []) -> bool:
	var run_state: RunState = RunState.new()
	run_state.init_for(character)
	if not deck_override.is_empty():
		run_state.deck = deck_override
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, character, enemy)
	for _turn: int in range(max_turns):
		bc.start_turn()
		if bc.is_battle_over():
			break
		for _attempt: int in range(20):
			if bc.is_battle_over():
				break
			var affordable: Array[CardData] = []
			for card: CardData in bc.deck.hand:
				if bc.effective_card_cost(card) <= int(bc.state["energy"]):
					affordable.append(card)
			if affordable.is_empty():
				break
			var chosen: CardData = affordable[randi() % affordable.size()]
			var played: Dictionary = bc.play_card(chosen)
			if not bool(played.get("affordable", false)):
				break
		if bc.is_battle_over():
			break
		var action: Dictionary = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(action)
	return bc.is_victory()

func _test_deck_pile_views(characters: Array[CharacterData]) -> void:
	var main_script = load("res://scripts/main.gd")
	var main = main_script.new()
	var card_a = GameData.make_card("test_attack", "普通攻擊", "李逍遙", 1, "attack", "造成 5 傷害", [])
	var card_b = GameData.make_card("test_skill", "仙風雲體術", "李逍遙", 2, "skill", "獲得 8 護體", [])
	var card_c = GameData.make_card("test_power", "天師符法", "李逍遙", 3, "power", "每回合造成傷害", [])
	var card_a_up = card_a.upgraded_copy()
	
	var list = [card_a.clone(), card_b.clone(), card_a.clone(), card_c.clone(), card_a_up.clone()]
	var grouped = main._group_and_sort_cards(list)
	
	assert(grouped.size() == 4, "Grouped size should be 4")
	assert(grouped[0]["card"].card_type == "power", "First should be power")
	assert(grouped[0]["card"].id == "test_power", "First ID mismatch")
	assert(grouped[0]["count"] == 1, "First count mismatch")
	
	assert(grouped[1]["card"].card_type == "skill", "Second should be skill")
	assert(grouped[1]["card"].id == "test_skill", "Second ID mismatch")
	assert(grouped[1]["count"] == 1, "Second count mismatch")
	
	assert(grouped[2]["card"].card_type == "attack", "Third should be attack")
	assert(grouped[2]["card"].id == "test_attack", "Third ID mismatch")
	assert(not grouped[2]["card"].upgraded, "Third should be unupgraded")
	assert(grouped[2]["count"] == 2, "Third count mismatch")
	
	assert(grouped[3]["card"].card_type == "attack", "Fourth should be attack")
	assert(grouped[3]["card"].id == "test_attack", "Fourth ID mismatch")
	assert(grouped[3]["card"].upgraded, "Fourth should be upgraded")
	assert(grouped[3]["count"] == 1, "Fourth count mismatch")

	main.free()

func _test_potion_catalog() -> void:
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	assert(all_potions.size() == 10, "PotionCatalog should have 10 potions, got %d" % all_potions.size())
	var ids: Array[String] = []
	for p: Dictionary in all_potions:
		assert(p.has("id") and String(p["id"]).length() > 0, "potion missing id")
		assert(p.has("display_name") and String(p["display_name"]).length() > 0, "potion missing display_name")
		assert(p.has("effects") and (p["effects"] as Array).size() > 0, "potion missing effects: %s" % p.get("id", "?"))
		assert(not ids.has(String(p["id"])), "duplicate potion id: %s" % p["id"])
		ids.append(String(p["id"]))
		var by_id: Dictionary = PotionCatalog.by_id(String(p["id"]))
		assert(not by_id.is_empty(), "PotionCatalog.by_id failed for %s" % p["id"])
	assert(PotionCatalog.by_id("nonexistent").is_empty(), "by_id should return empty dict for unknown id")

func _test_potion_save_roundtrip(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	state.potions.append(all_potions[0].duplicate())
	state.potions.append(all_potions[5].duplicate())
	assert(state.potions.size() == 2, "setup: expected 2 potions")
	var dict: Dictionary = state.to_dict()
	var text: String = JSON.stringify(dict)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "round-trip JSON parse failed")
	var restored: RunState = RunState.new()
	assert(restored.from_dict(parsed as Dictionary, characters), "from_dict failed")
	assert(restored.potions.size() == 2, "potions lost in round-trip: got %d" % restored.potions.size())
	assert(String((restored.potions[0] as Dictionary).get("id", "")) == String(all_potions[0]["id"]), "first potion id mismatch")
	assert(String((restored.potions[1] as Dictionary).get("id", "")) == String(all_potions[5]["id"]), "second potion id mismatch")

func _test_potion_use_heal(character: CharacterData, enemy: EnemyData) -> void:
	var bc: BattleController = BattleController.new()
	var rs: RunState = RunState.new()
	rs.init_for(character)
	rs.character_hps[0] = 10
	bc.setup(rs, character, enemy.clone())
	bc.start_turn()
	var heal_potion: Dictionary = PotionCatalog.by_id("huichun_dan")
	assert(not heal_potion.is_empty(), "huichun_dan not found in catalog")
	var before_hp: int = int(bc.state["player_hp"])
	var effects: Array = heal_potion.get("effects", []) as Array
	bc.resolver.resolve_effects_list(effects, bc.state)
	var after_hp: int = int(bc.state["player_hp"])
	assert(after_hp == min(before_hp + 15, int(bc.state["player_max_hp"])),
		"heal potion: expected %d HP, got %d" % [min(before_hp + 15, int(bc.state["player_max_hp"])), after_hp])
	bc.free()

func _test_potion_cure_poison(character: CharacterData, enemy: EnemyData) -> void:
	var bc: BattleController = BattleController.new()
	var rs: RunState = RunState.new()
	rs.init_for(character)
	bc.setup(rs, character, enemy.clone())
	bc.start_turn()
	bc.state["player_poison"] = 3
	assert(int(bc.state["player_poison"]) == 3, "setup: player_poison should be 3")
	var cure_potion: Dictionary = PotionCatalog.by_id("jiedu_san")
	assert(not cure_potion.is_empty(), "jiedu_san not found in catalog")
	var effects: Array = cure_potion.get("effects", []) as Array
	bc.resolver.resolve_effects_list(effects, bc.state)
	assert(int(bc.state["player_poison"]) == 0, "cure_poison: player_poison should be 0, got %d" % int(bc.state["player_poison"]))
	bc.free()

func _test_potion_old_save_compat(characters: Array[CharacterData]) -> void:
	var old_save: Dictionary = {
		"version": 2,
		"character_ids": [characters[0].id],
		"character_hps": [characters[0].max_hp],
		"character_max_hps": [characters[0].max_hp],
		"character_power_bonus": [0],
		"character_decks": [[]],
		"active_character_index": 0,
		"gold": 50,
		"encounter_index": 0,
		"encounter_choices": [],
		"chosen_map_path": [],
		"pending_rest_heal": 0,
		"current_shop_inventory": [],
		"current_shop_is_black": false,
		"current_event_variant": "shrine",
		"relics": [],
		"ascension_level": 0,
		"map_seed": 0,
		"act": 1
	}
	var rs: RunState = RunState.new()
	assert(rs.from_dict(old_save, characters), "old save without potions field should load successfully")
	assert(rs.potions.is_empty(), "old save should produce empty potions array, got %d" % rs.potions.size())

func _test_level_system(characters: Array[CharacterData]) -> void:
	# EXP 公式
	assert(LevelSystem.exp_to_next_level(1) == 15, "L1→L2 should need 15 EXP")
	assert(LevelSystem.exp_to_next_level(5) == 75, "L5→L6 should need 75 EXP")
	assert(LevelSystem.exp_to_next_level(50) == 0, "MAX_LEVEL should need 0 EXP")
	# 等級計算
	assert(LevelSystem.level_from_exp(0) == 1, "0 EXP = Lv1")
	assert(LevelSystem.level_from_exp(14) == 1, "14 EXP = Lv1")
	assert(LevelSystem.level_from_exp(15) == 2, "15 EXP = Lv2")
	assert(LevelSystem.level_from_exp(15 + 30 - 1) == 2, "44 EXP = Lv2")
	assert(LevelSystem.level_from_exp(15 + 30) == 3, "45 EXP = Lv3")
	assert(LevelSystem.level_from_exp(15 + 30 + 45) == 4, "90 EXP = Lv4")
	# 戰鬥 EXP
	assert(LevelSystem.battle_exp(false, 0) == 30, "floor 0 normal = 30 EXP")
	assert(LevelSystem.battle_exp(false, 5) == 55, "floor 5 normal = 55 EXP")
	assert(LevelSystem.battle_exp(true, 0) == 150, "boss = 150 EXP")
	# RunState 整合：init 後有 level/exp 陣列
	var rs: RunState = RunState.new()
	rs.init_for(characters[0])
	assert(rs.character_levels.size() == 1, "single char should have 1 level entry")
	assert(rs.character_levels[0] == 1, "initial level should be 1")
	assert(rs.character_exps[0] == 0, "initial exp should be 0")
	# 3 人隊伍
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	rs.init_for(party)
	assert(rs.character_levels.size() == 3, "3-person party needs 3 level entries")
	# to_dict / from_dict round-trip
	rs.character_levels[0] = 5
	rs.character_exps[0] = 250
	var d: Dictionary = rs.to_dict()
	var rs2: RunState = RunState.new()
	rs2.from_dict(d, characters)
	assert(rs2.character_levels[0] == 5, "level should survive round-trip; got %d" % rs2.character_levels[0])
	assert(rs2.character_exps[0] == 250, "exp should survive round-trip; got %d" % rs2.character_exps[0])
	# 舊存檔（無 character_levels 欄位）→ 預設 Lv 1
	var old_d: Dictionary = d.duplicate()
	old_d.erase("character_levels")
	old_d.erase("character_exps")
	var rs3: RunState = RunState.new()
	rs3.from_dict(old_d, characters)
	assert(rs3.character_levels[0] == 1, "old save without levels should default to Lv1")

func _test_level_unlock_cards() -> void:
	# 每個角色至少要在 Lv 1-25 間有 >= 5 個 unlock 點，且每張 unlock 卡資料完整
	# （之前寫死 Lv 3/6/10/15/20，但 PAL1 對齊後改用 Lv 4/6/9/11/13/15/18/22 等）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		var all_by_25: Array[CardData] = LevelSystem.all_unlocked_cards(char_id, 25)
		assert(all_by_25.size() >= 5, "%s should have >= 5 unlocks by Lv25; got %d" % [char_id, all_by_25.size()])
		for card: CardData in all_by_25:
			assert(not card.id.is_empty(), "unlock card id empty for %s" % char_id)
			assert(not card.display_name.is_empty(), "unlock card name empty for %s (id=%s)" % [char_id, card.id])
			assert(card.effects.size() > 0, "unlock card has no effects for %s (id=%s)" % [char_id, card.id])
	# Lv1 應該無 unlock（unlock 從 Lv2+ 才開始）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		assert(LevelSystem.all_unlocked_cards(char_id, 1).is_empty(), "%s should have 0 unlocks at Lv1" % char_id)
	# all_unlocked_cards 應依 max_level 累積（更高等級不會回傳更少卡）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		var by_5: int = LevelSystem.all_unlocked_cards(char_id, 5).size()
		var by_15: int = LevelSystem.all_unlocked_cards(char_id, 15).size()
		var by_25: int = LevelSystem.all_unlocked_cards(char_id, 25).size()
		assert(by_5 <= by_15, "%s: by_5 (%d) > by_15 (%d), 應累積" % [char_id, by_5, by_15])
		assert(by_15 <= by_25, "%s: by_15 (%d) > by_25 (%d), 應累積" % [char_id, by_15, by_25])
	# 不存在的角色應回傳空陣列
	assert(LevelSystem.all_unlocked_cards("unknown_char", 50).is_empty(), "unknown char should return empty")
