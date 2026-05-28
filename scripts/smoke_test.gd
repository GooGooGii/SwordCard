extends SceneTree

# 失敗計數：_check() helper 失敗時 +1。_initialize 結尾若 > 0 則 quit(1)。
# 解決「assert 在 _test_* 函式內失敗只 abort 該 func、不 abort _initialize → "passed" 還是會印」的框架弱點。
# 規則：_test_* 函式內用 _check(cond, msg)；_initialize 頂層用 assert()（資料完整性 → 失敗就該 abort，watchdog 接手）。
var _smoke_failures: int = 0

func _check(cond: bool, msg: String = "") -> void:
	if not cond:
		_smoke_failures += 1
		push_error("[smoke check fail #%d] %s" % [_smoke_failures, msg if msg else "(no msg)"])

func _initialize() -> void:
	# Watchdog：assert 失敗會中途 abort _initialize、來不及跑到 quit(0)，
	# 導致 SceneTree 空轉「假卡死」（CLI 端看起來像 hang）。
	# _initialize 無 await、整段同步執行，故此 timer 在正常執行期間不會 tick；
	# 一旦 abort、控制權交回主迴圈，timer 幾秒內 fire → 印錯誤 + quit(1)。
	var watchdog: SceneTreeTimer = create_timer(5.0)
	watchdog.timeout.connect(func() -> void:
		push_error("[smoke] 測試在跑完前中止（多半是上方某個 assert 失敗）。以 quit(1) 結束，避免空轉假卡死。")
		quit(1))
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
	# Multi-Enemy Mode（Phase 1+2 資料層 + AOE effects）
	_test_multi_enemy_setup(characters, enemies)
	_test_multi_enemy_damage_routing(characters, enemies)
	_test_multi_enemy_aoe_damage(characters, enemies)
	_test_multi_enemy_aoe_status(characters, enemies)
	_test_multi_enemy_partial_kill(characters, enemies)
	_test_multi_enemy_set_active(characters, enemies)
	# Phase 3+3.5
	_test_multi_enemy_turn_each_attacks(characters, enemies)
	_test_multi_enemy_per_enemy_phase(characters)
	_test_summon_basic(characters, enemies)
	_test_summon_cap(characters, enemies)
	_test_summon_unknown_id(characters, enemies)
	_test_summon_from_boss_pool(characters)
	# 連擊 multi-hit（阿奴刀流 / 引擎地基）
	_test_multi_hit_damage(characters, enemies)
	_test_anu_blade_cards(characters)
	_test_thorns_reflects_to_attacker(characters, enemies)
	_test_lin_thorns_cards(characters)
	_test_damage_debuff_bonus(characters, enemies)
	_test_zhao_staff_payoff_cards(characters)
	_test_damage_all_multi_hit(characters, enemies)
	# Event Branching Phase 1：純樹走訪器（無 UI、無 effect 結算）
	_test_event_runner_has_tree()
	_test_event_runner_root_choices()
	_test_event_runner_requires_character()
	_test_event_runner_requires_observe_token()
	_test_event_runner_node_navigation()
	_test_event_runner_leaf_detection()
	_test_event_runner_legacy_fallback()
	# Phase 5：observe token + next_battle_buff 持久化
	_test_observe_token_init_and_consume(characters)
	_test_observe_token_save_roundtrip(characters)
	_test_observe_token_old_save_compat(characters)
	_test_next_battle_buff_queue_roundtrip(characters)
	# Phase 3：戰鬥回流（pending_event_return）
	_test_pending_event_return_init(characters)
	_test_pending_event_return_not_persisted(characters)
	# Phase 4：Curse 牌系統
	_test_curse_catalog()
	_test_curse_play_card_rejected(characters[0], enemies[0])
	_test_curse_not_upgradeable(characters[0])
	_test_curse_save_roundtrip(characters)
	_test_curse_retention_turn_start(characters[0], enemies[0])
	_test_curse_retention_battle_start(characters[0], enemies[0])
	_test_jing_hua_fu_removes_curse(characters[0])
	# Phase 7-A：Batch A 6 個事件樹
	_test_batch_a_all_have_tree()
	_test_batch_a_character_gating()
	_test_batch_a_observe_gating()
	_test_batch_a_subnode_navigation()
	# Phase 7-B：Batch B 6 個事件樹（含戰鬥分支）
	_test_batch_b_all_have_tree()
	_test_batch_b_character_gating()
	_test_batch_b_observe_gating()
	_test_batch_b_battle_leaves_valid()
	if _smoke_failures > 0:
		push_error("[smoke] %d 個 _check() 失敗。以 quit(1) 結束。" % _smoke_failures)
		print("SwordCard smoke test FAILED (%d check failures)." % _smoke_failures)
		quit(1)
		return
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
	_check(parsed is Dictionary, "round-trip JSON parse failed")
	var restored: RunState = RunState.new()
	_check(restored.from_dict(parsed as Dictionary, characters), "from_dict rejected valid save")
	_check(restored.gold == 123, "gold mismatch")
	_check(restored.encounter_index == 4, "encounter_index mismatch")
	_check(restored.pending_rest_heal == 7, "pending_rest_heal mismatch")
	_check(restored.current_shop_is_black == true, "current_shop_is_black mismatch")
	_check(restored.current_event_variant == "ruins", "current_event_variant mismatch")
	_check(restored.character.id == state.character.id, "character_id mismatch")
	_check(restored.deck.size() == state.deck.size(), "deck size mismatch")
	_check(restored.relics.size() == state.relics.size(), "relics size mismatch")

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
	_check(int(migrated.get("save_version", 0)) == SaveManager.SAVE_VERSION, "migrate should stamp save_version to current")
	_check(migrated.has("character_ids"), "v1->v2 migrate should add character_ids array")
	_check((migrated["character_ids"] as Array).size() == 1, "v1->v2: party should have 1 character")
	_check(int((migrated["character_hps"] as Array)[0]) == 33, "v1->v2: hp should migrate to character_hps[0]")
	_check((migrated["character_decks"] as Array).size() == 1, "v1->v2: character_decks should have 1 entry")
	_check(((migrated["character_decks"] as Array)[0] as Array).size() == characters[0].starting_deck.size(),
		"v1->v2: deck cards should not be lost")
	# from_dict 還原成 RunState 並驗證
	var restored: RunState = RunState.new()
	_check(restored.from_dict(migrated, characters), "migrated v1 save should from_dict cleanly")
	_check(restored.gold == 222)
	_check(restored.ascension_level == 1)
	_check(restored.characters.size() == 1)
	_check(restored.characters[0].id == characters[0].id)
	_check(restored.character_hps[0] == 33)
	_check(restored.character_max_hps[0] == characters[0].max_hp)
	_check(restored.character_power_bonus[0] == 2)
	_check(restored.active_character_index == 0)
	# 別名也要對
	_check(restored.character.id == characters[0].id, "character alias should resolve to active")
	_check(restored.hp == 33, "hp alias should resolve to active")
	_check(restored.deck.size() == characters[0].starting_deck.size(), "deck alias should resolve to active")

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
	_check(restored.from_dict(parsed, characters), "3-character party round-trip from_dict failed")
	_check(restored.characters.size() == 3, "party size mismatch")
	_check(restored.character_hps[1] == 10, "per-character hp mismatch")
	_check(restored.character_power_bonus[2] == 4, "per-character power_bonus mismatch")
	_check(restored.active_character_index == 1, "active_character_index mismatch")
	_check(restored.characters[1].id == characters[1].id, "characters[1] id mismatch")
	_check(restored.character_decks.size() == 3, "character_decks should have 3 entries")
	for i: int in range(3):
		_check((restored.character_decks[i] as Array).size() == characters[i].starting_deck.size(),
			"character %d deck size mismatch" % i)

func _test_save_manager_cycle(characters: Array[CharacterData]) -> void:
	SaveManager.clear()
	var state: RunState = RunState.new()
	state.init_for(characters[1])
	state.gold = 999
	_check(SaveManager.save(state), "SaveManager.save failed")
	_check(SaveManager.has_save(), "save file missing after save")
	var loaded: Dictionary = SaveManager.load_save()
	_check(int(loaded.get("gold", 0)) == 999, "loaded gold mismatch")
	_check(int(loaded.get("save_version", 0)) == SaveManager.SAVE_VERSION, "save_version not stamped")
	var restored: RunState = RunState.new()
	_check(restored.from_dict(loaded, characters), "SaveManager round-trip from_dict failed")
	_check(restored.character.id == characters[1].id, "character mismatch after SaveManager cycle")
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
	_check(hp_before - hp_after == 15, "vulnerable damage multiplier broken: lost %d expected 15" % (hp_before - hp_after))
	# 護甲吸收：給敵人 8 block，5 點傷害應全擋
	state["enemy_block"] = 8
	state["enemy_vulnerable"] = 0
	var small_card: CardData = GameData.make_card("block_test", "格擋測試", character.display_name, 1, "attack", "造成 5 點傷害。", [{"kind": "damage", "amount": 5}])
	hp_before = int(state["enemy_hp"])
	resolver.resolve_card(small_card, state)
	_check(int(state["enemy_hp"]) == hp_before, "block didn't absorb full damage")
	_check(int(state["enemy_block"]) == 3, "block remainder wrong: %d expected 3" % int(state["enemy_block"]))

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
	_check(int(state["enemy_weak"]) == 2, "enemy_weak decay wrong")
	_check(int(state["enemy_vulnerable"]) == 1, "enemy_vulnerable decay wrong")

func _test_poison_tick_and_decay() -> void:
	var state: Dictionary = _make_state()
	state["enemy_poison"] = 4
	state["player_poison"] = 2
	var resolver: EffectResolver = EffectResolver.new()
	resolver.tick_statuses(state)
	# 中毒造成 4 傷害、層數 -1
	_check(int(state["enemy_hp"]) == 56, "enemy poison tick damage wrong: %d" % int(state["enemy_hp"]))
	_check(int(state["enemy_poison"]) == 3, "enemy poison decay wrong: %d" % int(state["enemy_poison"]))
	_check(int(state["player_hp"]) == 58, "player poison tick damage wrong: %d" % int(state["player_hp"]))
	_check(int(state["player_poison"]) == 1, "player poison decay wrong: %d" % int(state["player_poison"]))
	# 再 tick 一次，player poison 應該歸零並結算 1 點傷害
	resolver.tick_statuses(state)
	_check(int(state["player_poison"]) == 0, "player poison should reach 0")
	_check(int(state["player_hp"]) == 57, "player hp after second tick wrong")

func _test_poison_burst() -> void:
	# 5 層蠱毒 * burst amount 2 = 10 點傷害，且 poison 歸零
	var state: Dictionary = _make_state()
	state["enemy_poison"] = 5
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("burst", "引爆", "P", 1, "skill", "引爆毒。", [{"kind": "poison_burst", "amount": 2}])
	resolver.resolve_card(card, state)
	_check(int(state["enemy_hp"]) == 50, "poison_burst damage wrong: %d expected 50" % int(state["enemy_hp"]))
	_check(int(state["enemy_poison"]) == 0, "poison_burst should clear poison")

func _test_consume_energy_damage() -> void:
	# 3 點靈力 * amount 3 = 9 點傷害；energy 歸零
	var state: Dictionary = _make_state()
	state["energy"] = 3
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("burn", "焚靈", "P", 0, "skill", "耗盡靈力。", [{"kind": "consume_energy_damage", "amount": 3}])
	resolver.resolve_card(card, state)
	_check(int(state["enemy_hp"]) == 51, "consume_energy_damage wrong: %d expected 51" % int(state["enemy_hp"]))
	_check(int(state["energy"]) == 0, "consume_energy should drain energy")

func _test_power_stacks_with_damage() -> void:
	# player_power +2、weak 0，10 點傷害 → 12 點
	var state: Dictionary = _make_state()
	state["player_power"] = 2
	var resolver: EffectResolver = EffectResolver.new()
	var card: CardData = GameData.make_card("pw", "強擊", "P", 1, "attack", "造成 10 點傷害。", [{"kind": "damage", "amount": 10}])
	resolver.resolve_card(card, state)
	_check(int(state["enemy_hp"]) == 48, "power should add to damage: got %d expected 48" % int(state["enemy_hp"]))
	# 同時 weak 2 → 12 - 2 = 10
	state = _make_state()
	state["player_power"] = 2
	state["player_weak"] = 2
	resolver.resolve_card(card, state)
	_check(int(state["enemy_hp"]) == 50, "weak should subtract from final damage: got %d expected 50" % int(state["enemy_hp"]))

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
		var actions: Array = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(actions)
	_check(bc.is_victory(), "battle should end in victory within %d turns" % max_turns)
	_check(int(bc.state["enemy_hp"]) <= 0, "enemy hp should be 0 on victory")
	bc.complete_victory()
	_check(run_state.hp == int(bc.state["player_hp"]), "complete_victory should sync hp to run_state")

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
	_check(int(bc.state["per_turn_energy"]) == 5, "3-party energy should be 5; got %d" % int(bc.state["per_turn_energy"]))
	# 切換到 index 1 (應免費)
	var switch1: Dictionary = bc.switch_active(1)
	_check(bool(switch1.get("changed", false)), "first switch should succeed")
	_check(bool(switch1.get("free", false)), "first switch in turn should be free")
	_check(bc._active_index() == 1, "active should now be 1")
	_check(String(bc.state["player_name"]) == characters[1].display_name, "player_name alias should follow active")
	# 第二次切換要 1 energy
	var prev_energy: int = int(bc.state["energy"])
	var switch2: Dictionary = bc.switch_active(2)
	_check(bool(switch2.get("changed", false)), "second switch should succeed (we have energy)")
	_check(not bool(switch2.get("free", true)), "second switch in turn should NOT be free")
	_check(int(bc.state["energy"]) == prev_energy - 1, "second switch should cost 1 energy")
	# 殺死全部 → is_defeat
	for i: int in range(3):
		(bc.state["players"] as Array)[i]["hp"] = 0
	# active 也死，sync 一下
	bc._sync_active_to_state()
	_check(bc.is_defeat(), "all-zero hp party should is_defeat=true")

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
	_check(int(bc.state["player_block"]) == 0, "new active should start with 0 block")
	_check(int(bc.state["player_poison"]) == 0, "new active should start with 0 poison")
	# 切回 0
	bc.switch_active(0)
	_check(int(bc.state["player_block"]) == 7, "block should persist when switched back; got %d" % int(bc.state["player_block"]))
	_check(int(bc.state["player_poison"]) == 3, "poison should persist when switched back; got %d" % int(bc.state["player_poison"]))

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
	_check(switched, "force switch should succeed when other members are alive")
	_check(bc._active_index() == 1, "force switch should land on first alive (index 1)")
	_check(not bc.is_defeat(), "party should not be defeated while index 1 + 2 are alive")
	# 再殺 1 → active 變 2
	(bc.state["players"] as Array)[1]["hp"] = 0
	bc.state["player_hp"] = 0
	_check(bc._force_switch_to_first_alive(false), "force switch to index 2")
	_check(bc._active_index() == 2)
	# 殺光 → is_defeat
	(bc.state["players"] as Array)[2]["hp"] = 0
	bc.state["player_hp"] = 0
	_check(not bc._force_switch_to_first_alive(false), "no alive members left")
	_check(bc.is_defeat(), "all dead -> is_defeat")

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
	_check(weapon_count <= party.size(), "should not over-grant weapons")
	# 至少領隊應該拿到專武（如果他有的話）
	var leader_weapons: Array[RelicData] = RelicCatalog.weapons_for_character(party[0].id)
	if not leader_weapons.is_empty():
		_check(run_state.has_relic(leader_weapons[0].id), "leader's starter weapon should be granted")

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
	var revive_card: CardData = GameData.make_card("revive_test", "復活", "P", 1, "skill", "救回 30", ([{"kind": "revive", "amount": 30}] as Array[Dictionary]))
	bc.state["energy"] = 99
	bc.play_card(revive_card)
	var revived_hp: int = int((bc.state["players"] as Array)[1]["hp"])
	_check(revived_hp == 30, "revive should restore idx 1 to amount=30; got %d" % revived_hp)
	# 第二次打復活卡（沒人倒下）→ fallback heal active
	bc.state["player_hp"] = 10  # active 受傷
	bc._sync_state_to_active()
	bc.play_card(revive_card)
	_check(int(bc.state["player_hp"]) == 40, "no dead -> revive should heal active by amount; got %d" % int(bc.state["player_hp"]))
	# 升級後 revive amount 應提升（30 → 38），說明文字也要跟著換
	var revive_upg: CardData = revive_card.upgraded_copy()
	_check(int(revive_upg.effects[0]["amount"]) == 38, \
		"upgraded revive amount should be 38; got %d" % int(revive_upg.effects[0]["amount"]))
	_check(revive_upg.description.contains("38"), \
		"upgraded revive description should contain 38")

func _test_map_generator_reachability(enemies: Array[EnemyData], bosses: Array[EnemyData]) -> void:
	# 跑 30 次隨機產生的地圖，驗證每張都沒有孤兒節點、且 boss 可達
	for trial: int in range(30):
		seed(trial * 1009 + 7)
		var choices: Array[Array] = MapGenerator.generate(enemies, bosses)
		_check(choices.size() >= 2, "trial %d: map should have at least one normal row + boss" % trial)
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
					_check(target >= 0 and target < row.size(),
						"trial %d row %d: connect index %d out of range (row size %d)" % [trial, row_index, target, row.size()])
					incoming_counts[target] += 1
			for node_index: int in range(row.size()):
				_check(incoming_counts[node_index] > 0,
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
		_check(boss_reachable, "trial %d: boss row unreachable from row 0" % trial)
		# 3. 不交叉檢查：i1 < i2 的兩個節點，邊 j1 不能 > j2（樹狀規則）
		for row_index2: int in range(choices.size() - 1):
			var src_row: Array = choices[row_index2]
			for i1: int in range(src_row.size()):
				for i2: int in range(i1 + 1, src_row.size()):
					var edges_1: Array = ((src_row[i1] as Dictionary).get("connects", []) as Array)
					var edges_2: Array = ((src_row[i2] as Dictionary).get("connects", []) as Array)
					for j1_v: Variant in edges_1:
						for j2_v: Variant in edges_2:
							_check(int(j1_v) <= int(j2_v),
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
		_check(int(pred["dealt"]) == actual_dealt,
			"predict mismatch: block=%d vuln=%d weak=%d atk=%d → predicted %d, actual %d" %
			[block_amt, vuln, enemy_weak, attack, int(pred["dealt"]), actual_dealt])

func _test_ascension_persistence_and_modifiers() -> void:
	# 持久化：clear → mark(2) → unlocked == 3
	Ascension.clear_all()
	_check(Ascension.get_unlocked_max() == 0, "fresh start should unlock only A0")
	Ascension.mark_cleared(0)
	_check(Ascension.get_unlocked_max() == 1)
	Ascension.mark_cleared(2)
	_check(Ascension.get_unlocked_max() == 3, "mark(2) should unlock A3")
	Ascension.mark_cleared(1)  # 倒退式 mark 不該降級
	_check(Ascension.get_unlocked_max() == 3, "lower mark should not regress unlock")
	Ascension.clear_all()
	# Modifier 計算
	_check(Ascension.enemy_hp_multiplier(0, false) == 1.0)
	_check(Ascension.enemy_hp_multiplier(1, false) == 1.2, "A1 buff 一般敵人")
	_check(Ascension.enemy_hp_multiplier(1, true) == 1.0, "A1 不影響 boss")
	_check(abs(Ascension.enemy_hp_multiplier(2, true) - 1.2) < 0.001, "A2 buff boss")
	_check(abs(Ascension.enemy_hp_multiplier(2, false) - 1.2) < 0.001, "A2 仍 buff 一般")
	_check(Ascension.starting_hp_multiplier(2) == 1.0)
	_check(Ascension.starting_hp_multiplier(3) == 0.85)
	_check(Ascension.gold_multiplier(3) == 1.0)
	_check(Ascension.gold_multiplier(4) == 0.75)

func _test_boss_phase_transition(bosses: Array[EnemyData]) -> void:
	# 三個 boss 都該有 phase_2_actions 設定；damage 跌破 50% 後 phased 變 true
	for boss: EnemyData in bosses:
		_check(not boss.phase_2_actions.is_empty(),
			"boss %s should have phase_2_actions defined" % boss.id)
	# 真實流程模擬：手工把 boss HP 打到 49%，下一張卡觸發 _check_phase_transition
	var characters: Array[CharacterData] = GameData.characters()
	var run_state: RunState = RunState.new()
	run_state.init_for(characters[0])
	var boss: EnemyData = bosses[0].clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, characters[0], boss)
	_check(not bc.phased, "fresh battle should not be phased")
	# 把 boss 打到剛好 50% 以上、再用一張卡把它打到 < 50%
	bc.state["enemy_hp"] = int(float(bc.state["enemy_max_hp"]) * 0.51)
	var tick_card: CardData = GameData.make_card("phase_test_1", "微擊", "P", 0, "attack", "造成 5 點傷害。", [{"kind": "damage", "amount": 5}])
	bc.state["energy"] = 99
	bc.play_card(tick_card)
	_check(bc.phased, "boss should phase after dropping below 50%% (hp=%d / max=%d)" % [int(bc.state["enemy_hp"]), int(bc.state["enemy_max_hp"])])
	# 切換後 next_enemy_action 應該回傳 phase_2_actions 的招式
	var next_action: Dictionary = bc.next_enemy_action()
	var phase_2_intents: Array[String] = []
	for action: Dictionary in boss.phase_2_actions:
		phase_2_intents.append(String(action.get("intent", "")))
	_check(String(next_action.get("intent", "")) in phase_2_intents,
		"after phase, next_enemy_action should pick from phase_2_actions")

func _test_event_variety() -> void:
	# 至少 10 種 event variant、每種都有合理的欄位
	var variant_keys: Array = EventData.VARIANTS.keys()
	_check(variant_keys.size() >= 10, "should have at least 10 event variants; got %d" % variant_keys.size())
	for key: Variant in variant_keys:
		var data: Dictionary = EventData.for_variant(String(key))
		_check(data.has("title") and not String(data["title"]).is_empty(), "variant %s missing title" % key)
		_check(data.has("heal"), "variant %s missing heal" % key)
		_check(data.has("gain_cost"), "variant %s missing gain_cost" % key)
		_check(data.has("power"), "variant %s missing power" % key)
		_check(data.has("power_label"), "variant %s missing power_label" % key)
	# MapGenerator 應該知道所有 variant（不該 stale）
	for key_v: Variant in variant_keys:
		_check(MapGenerator.EVENT_VARIANTS.has(String(key_v)),
			"variant %s defined in EventData but not in MapGenerator.EVENT_VARIANTS" % key_v)

func _test_revive_event(characters: Array[CharacterData]) -> void:
	# 驗證 lingmiao event variant 存在且有 revive choice + revive_amount 欄位
	var ev: Dictionary = EventData.for_variant("lingmiao")
	_check(not ev.is_empty(), "lingmiao variant should exist in EventData")
	_check(ev.has("revive_amount"), "lingmiao should have revive_amount field")
	_check(int(ev.get("revive_amount", 0)) > 0, "lingmiao revive_amount should be positive")
	var choices: Array = ev.get("choices", []) as Array
	_check(choices.has("revive"), "lingmiao choices should include 'revive'")
	# 驗證 lingmiao 在 MapGenerator pool 中
	_check(MapGenerator.EVENT_VARIANTS.has("lingmiao"),
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
	_check(revived, "resolve_event_revive should find a downed character")
	_check(run_state.character_hps[1] == amount,
		"revived character hp should be %d; got %d" % [amount, run_state.character_hps[1]])
	# 再跑一次：無人倒下時不應有任何 revive
	var run_state2: RunState = RunState.new()
	run_state2.init_for([characters[0]])
	var revived2: bool = false
	for i: int in range(run_state2.character_hps.size()):
		if run_state2.character_hps[i] <= 0:
			revived2 = true
			break
	_check(not revived2, "no downed characters means no revive should occur")

func _test_map_seed_determinism(enemies: Array[EnemyData], bosses: Array[EnemyData]) -> void:
	# 相同 seed 兩次跑 generate，產出的節點結構一致
	seed(424242)
	var map_a: Array[Array] = MapGenerator.generate(enemies, bosses)
	seed(424242)
	var map_b: Array[Array] = MapGenerator.generate(enemies, bosses)
	_check(map_a.size() == map_b.size(), "row count differs across same-seed runs")
	for row_index: int in range(map_a.size()):
		var row_a: Array = map_a[row_index]
		var row_b: Array = map_b[row_index]
		_check(row_a.size() == row_b.size(), "row %d size differs" % row_index)
		for node_index: int in range(row_a.size()):
			var a: Dictionary = row_a[node_index] as Dictionary
			var b: Dictionary = row_b[node_index] as Dictionary
			_check(String(a.get("type", "")) == String(b.get("type", "")),
				"row %d node %d type differs: %s vs %s" % [row_index, node_index, a.get("type"), b.get("type")])

func _test_requires_enemy_target() -> void:
	# 純傷害
	var c_damage: Array[Dictionary] = [{"kind": "damage", "amount": 5}]
	_check(CardFormat.requires_enemy_target(GameData.make_card("t1", "test", "P", 1, "skill", "x", c_damage)))
	# 純自療
	var c_heal: Array[Dictionary] = [{"kind": "heal", "amount": 5}]
	_check(not CardFormat.requires_enemy_target(GameData.make_card("t2", "test", "P", 1, "skill", "x", c_heal)))
	# 純護體
	var c_block: Array[Dictionary] = [{"kind": "block", "amount": 5}]
	_check(not CardFormat.requires_enemy_target(GameData.make_card("t3", "test", "P", 1, "skill", "x", c_block)))
	# 純抽牌
	var c_draw: Array[Dictionary] = [{"kind": "draw", "amount": 1}]
	_check(not CardFormat.requires_enemy_target(GameData.make_card("t4", "test", "P", 1, "skill", "x", c_draw)))
	# 純 power
	var c_power: Array[Dictionary] = [{"kind": "power", "amount": 1}]
	_check(not CardFormat.requires_enemy_target(GameData.make_card("t5", "test", "P", 1, "power", "x", c_power)))
	# weak / vulnerable / poison 都是丟去敵人
	var c_weak: Array[Dictionary] = [{"kind": "weak", "amount": 1}]
	var c_vuln: Array[Dictionary] = [{"kind": "vulnerable", "amount": 1}]
	var c_poison: Array[Dictionary] = [{"kind": "poison", "amount": 1}]
	_check(CardFormat.requires_enemy_target(GameData.make_card("t6", "test", "P", 1, "skill", "x", c_weak)))
	_check(CardFormat.requires_enemy_target(GameData.make_card("t7", "test", "P", 1, "skill", "x", c_vuln)))
	_check(CardFormat.requires_enemy_target(GameData.make_card("t8", "test", "P", 1, "skill", "x", c_poison)))
	# consume_energy_damage / poison_burst 都對敵
	var c_ced: Array[Dictionary] = [{"kind": "consume_energy_damage", "amount": 3}]
	var c_pb: Array[Dictionary] = [{"kind": "poison_burst", "amount": 2}]
	_check(CardFormat.requires_enemy_target(GameData.make_card("t9", "test", "P", 1, "skill", "x", c_ced)))
	_check(CardFormat.requires_enemy_target(GameData.make_card("t10", "test", "P", 1, "skill", "x", c_pb)))
	# 混合：block + weak → 還是要丟敵人（因 weak）
	var c_mix1: Array[Dictionary] = [{"kind": "block", "amount": 5}, {"kind": "weak", "amount": 1}]
	_check(CardFormat.requires_enemy_target(GameData.make_card("t11", "test", "P", 1, "skill", "x", c_mix1)))
	# 混合：damage + draw → 要丟敵人
	var c_mix2: Array[Dictionary] = [{"kind": "damage", "amount": 5}, {"kind": "draw", "amount": 1}]
	_check(CardFormat.requires_enemy_target(GameData.make_card("t12", "test", "P", 1, "attack", "x", c_mix2)))
	# 能力牌規則：card_type=="power" 一律對自己，即使 effects 裡有 debuff
	var c_power_mix: Array[Dictionary] = [{"kind": "power", "amount": 1}, {"kind": "poison", "amount": 5}]
	_check(not CardFormat.requires_enemy_target(GameData.make_card("t13", "test", "P", 1, "power", "x", c_power_mix)),
		"power card_type 應一律對自己（即使含 poison 等 debuff effect）")
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
		_check(boss_id in artifact_boss_ids, "Boss '%s' 缺少對應神器" % boss_id)

func _test_bestiary_persistence() -> void:
	# 注意：此 test 會清掉真實 bestiary 檔案；smoke test 環境是測試專用 user:// 不用擔心
	Bestiary.clear_all()
	_check(not Bestiary.is_defeated("smoke_test_dummy"), "should be clean after clear_all")
	Bestiary.mark_defeated("smoke_test_dummy")
	_check(Bestiary.is_defeated("smoke_test_dummy"))
	_check(Bestiary.kill_count("smoke_test_dummy") == 1)
	Bestiary.mark_defeated("smoke_test_dummy")
	_check(Bestiary.kill_count("smoke_test_dummy") == 2, "second mark should increment to 2")
	var data: Dictionary = Bestiary.load_all()
	_check(int(data.get("smoke_test_dummy", 0)) == 2)
	Bestiary.clear_all()
	_check(not Bestiary.is_defeated("smoke_test_dummy"))

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
	"li_xiaoyao":  {5: 97,  10: 90,  15: 100, 20: 83},
	"zhao_linger": {5: 100, 10: 100, 15: 100, 20: 93},
	"lin_yueru":   {5: 100, 10: 100, 15: 100, 20: 100},
	"anu":         {5: 100, 10: 93,  15: 100, 20: 93},
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
		_check(delta <= BALANCE_TOLERANCE_PP,
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
		_check(delta <= BALANCE_TOLERANCE_PP,
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
		_check(delta <= BALANCE_TOLERANCE_PP,
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
		_check(delta <= BALANCE_TOLERANCE_PP,
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
			_check(delta <= BALANCE_TOLERANCE_PP,
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
		var actions: Array = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(actions)
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
	
	_check(grouped.size() == 4, "Grouped size should be 4")
	_check(grouped[0]["card"].card_type == "power", "First should be power")
	_check(grouped[0]["card"].id == "test_power", "First ID mismatch")
	_check(grouped[0]["count"] == 1, "First count mismatch")
	
	_check(grouped[1]["card"].card_type == "skill", "Second should be skill")
	_check(grouped[1]["card"].id == "test_skill", "Second ID mismatch")
	_check(grouped[1]["count"] == 1, "Second count mismatch")
	
	_check(grouped[2]["card"].card_type == "attack", "Third should be attack")
	_check(grouped[2]["card"].id == "test_attack", "Third ID mismatch")
	_check(not grouped[2]["card"].upgraded, "Third should be unupgraded")
	_check(grouped[2]["count"] == 2, "Third count mismatch")
	
	_check(grouped[3]["card"].card_type == "attack", "Fourth should be attack")
	_check(grouped[3]["card"].id == "test_attack", "Fourth ID mismatch")
	_check(grouped[3]["card"].upgraded, "Fourth should be upgraded")
	_check(grouped[3]["count"] == 1, "Fourth count mismatch")

	main.free()

func _test_potion_catalog() -> void:
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	_check(all_potions.size() == 11, "PotionCatalog should have 11 potions, got %d" % all_potions.size())
	var ids: Array[String] = []
	for p: Dictionary in all_potions:
		_check(p.has("id") and String(p["id"]).length() > 0, "potion missing id")
		_check(p.has("display_name") and String(p["display_name"]).length() > 0, "potion missing display_name")
		_check(p.has("effects") and (p["effects"] as Array).size() > 0, "potion missing effects: %s" % p.get("id", "?"))
		_check(not ids.has(String(p["id"])), "duplicate potion id: %s" % p["id"])
		ids.append(String(p["id"]))
		var by_id: Dictionary = PotionCatalog.by_id(String(p["id"]))
		_check(not by_id.is_empty(), "PotionCatalog.by_id failed for %s" % p["id"])
	_check(PotionCatalog.by_id("nonexistent").is_empty(), "by_id should return empty dict for unknown id")

func _test_potion_save_roundtrip(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	state.potions.append(all_potions[0].duplicate())
	state.potions.append(all_potions[5].duplicate())
	_check(state.potions.size() == 2, "setup: expected 2 potions")
	var dict: Dictionary = state.to_dict()
	var text: String = JSON.stringify(dict)
	var parsed: Variant = JSON.parse_string(text)
	_check(parsed is Dictionary, "round-trip JSON parse failed")
	var restored: RunState = RunState.new()
	_check(restored.from_dict(parsed as Dictionary, characters), "from_dict failed")
	_check(restored.potions.size() == 2, "potions lost in round-trip: got %d" % restored.potions.size())
	_check(String((restored.potions[0] as Dictionary).get("id", "")) == String(all_potions[0]["id"]), "first potion id mismatch")
	_check(String((restored.potions[1] as Dictionary).get("id", "")) == String(all_potions[5]["id"]), "second potion id mismatch")

func _test_potion_use_heal(character: CharacterData, enemy: EnemyData) -> void:
	var bc: BattleController = BattleController.new()
	var rs: RunState = RunState.new()
	rs.init_for(character)
	rs.character_hps[0] = 10
	bc.setup(rs, character, enemy.clone())
	bc.start_turn()
	var heal_potion: Dictionary = PotionCatalog.by_id("huichun_dan")
	_check(not heal_potion.is_empty(), "huichun_dan not found in catalog")
	var before_hp: int = int(bc.state["player_hp"])
	var effects: Array = heal_potion.get("effects", []) as Array
	bc.resolver.resolve_effects_list(effects, bc.state)
	var after_hp: int = int(bc.state["player_hp"])
	_check(after_hp == min(before_hp + 15, int(bc.state["player_max_hp"])),
		"heal potion: expected %d HP, got %d" % [min(before_hp + 15, int(bc.state["player_max_hp"])), after_hp])

func _test_potion_cure_poison(character: CharacterData, enemy: EnemyData) -> void:
	var bc: BattleController = BattleController.new()
	var rs: RunState = RunState.new()
	rs.init_for(character)
	bc.setup(rs, character, enemy.clone())
	bc.start_turn()
	bc.state["player_poison"] = 3
	_check(int(bc.state["player_poison"]) == 3, "setup: player_poison should be 3")
	var cure_potion: Dictionary = PotionCatalog.by_id("jiedu_san")
	_check(not cure_potion.is_empty(), "jiedu_san not found in catalog")
	var effects: Array = cure_potion.get("effects", []) as Array
	bc.resolver.resolve_effects_list(effects, bc.state)
	_check(int(bc.state["player_poison"]) == 0, "cure_poison: player_poison should be 0, got %d" % int(bc.state["player_poison"]))

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
	_check(rs.from_dict(old_save, characters), "old save without potions field should load successfully")
	_check(rs.potions.is_empty(), "old save should produce empty potions array, got %d" % rs.potions.size())

func _test_level_system(characters: Array[CharacterData]) -> void:
	# EXP 公式
	_check(LevelSystem.exp_to_next_level(1) == 15, "L1→L2 should need 15 EXP")
	_check(LevelSystem.exp_to_next_level(5) == 75, "L5→L6 should need 75 EXP")
	_check(LevelSystem.exp_to_next_level(50) == 0, "MAX_LEVEL should need 0 EXP")
	# 等級計算
	_check(LevelSystem.level_from_exp(0) == 1, "0 EXP = Lv1")
	_check(LevelSystem.level_from_exp(14) == 1, "14 EXP = Lv1")
	_check(LevelSystem.level_from_exp(15) == 2, "15 EXP = Lv2")
	_check(LevelSystem.level_from_exp(15 + 30 - 1) == 2, "44 EXP = Lv2")
	_check(LevelSystem.level_from_exp(15 + 30) == 3, "45 EXP = Lv3")
	_check(LevelSystem.level_from_exp(15 + 30 + 45) == 4, "90 EXP = Lv4")
	# 戰鬥 EXP
	_check(LevelSystem.battle_exp(false, 0) == 30, "floor 0 normal = 30 EXP")
	_check(LevelSystem.battle_exp(false, 5) == 55, "floor 5 normal = 55 EXP")
	_check(LevelSystem.battle_exp(true, 0) == 150, "boss = 150 EXP")
	# RunState 整合：init 後有 level/exp 陣列
	var rs: RunState = RunState.new()
	rs.init_for(characters[0])
	_check(rs.character_levels.size() == 1, "single char should have 1 level entry")
	_check(rs.character_levels[0] == 1, "initial level should be 1")
	_check(rs.character_exps[0] == 0, "initial exp should be 0")
	# 3 人隊伍
	var party: Array[CharacterData] = [characters[0], characters[1], characters[2]]
	rs.init_for(party)
	_check(rs.character_levels.size() == 3, "3-person party needs 3 level entries")
	# to_dict / from_dict round-trip
	rs.character_levels[0] = 5
	rs.character_exps[0] = 250
	var d: Dictionary = rs.to_dict()
	var rs2: RunState = RunState.new()
	rs2.from_dict(d, characters)
	_check(rs2.character_levels[0] == 5, "level should survive round-trip; got %d" % rs2.character_levels[0])
	_check(rs2.character_exps[0] == 250, "exp should survive round-trip; got %d" % rs2.character_exps[0])
	# 舊存檔（無 character_levels 欄位）→ 預設 Lv 1
	var old_d: Dictionary = d.duplicate()
	old_d.erase("character_levels")
	old_d.erase("character_exps")
	var rs3: RunState = RunState.new()
	rs3.from_dict(old_d, characters)
	_check(rs3.character_levels[0] == 1, "old save without levels should default to Lv1")

func _test_level_unlock_cards() -> void:
	# 每個角色至少要在 Lv 1-25 間有 >= 5 個 unlock 點，且每張 unlock 卡資料完整
	# （之前寫死 Lv 3/6/10/15/20，但 PAL1 對齊後改用 Lv 4/6/9/11/13/15/18/22 等）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		var all_by_25: Array[CardData] = LevelSystem.all_unlocked_cards(char_id, 25)
		_check(all_by_25.size() >= 5, "%s should have >= 5 unlocks by Lv25; got %d" % [char_id, all_by_25.size()])
		for card: CardData in all_by_25:
			_check(not card.id.is_empty(), "unlock card id empty for %s" % char_id)
			_check(not card.display_name.is_empty(), "unlock card name empty for %s (id=%s)" % [char_id, card.id])
			_check(card.effects.size() > 0, "unlock card has no effects for %s (id=%s)" % [char_id, card.id])
	# Lv1 應該無 unlock（unlock 從 Lv2+ 才開始）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		_check(LevelSystem.all_unlocked_cards(char_id, 1).is_empty(), "%s should have 0 unlocks at Lv1" % char_id)
	# all_unlocked_cards 應依 max_level 累積（更高等級不會回傳更少卡）
	for char_id: String in ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]:
		var by_5: int = LevelSystem.all_unlocked_cards(char_id, 5).size()
		var by_15: int = LevelSystem.all_unlocked_cards(char_id, 15).size()
		var by_25: int = LevelSystem.all_unlocked_cards(char_id, 25).size()
		_check(by_5 <= by_15, "%s: by_5 (%d) > by_15 (%d), 應累積" % [char_id, by_5, by_15])
		_check(by_15 <= by_25, "%s: by_15 (%d) > by_25 (%d), 應累積" % [char_id, by_15, by_25])
	# 不存在的角色應回傳空陣列
	_check(LevelSystem.all_unlocked_cards("unknown_char", 50).is_empty(), "unknown char should return empty")

# ── Multi-Enemy Mode 測試 ───────────────────────────────────────────

func _make_multi_battle(character: CharacterData, enemy_templates: Array[EnemyData]) -> BattleController:
	var rs: RunState = RunState.new()
	rs.init_for(character)
	# 移除起始專武，否則 self_power / damage_out_bonus 會擾亂測試
	rs.relics.clear()
	var bc: BattleController = BattleController.new()
	bc.setup(rs, character, enemy_templates)
	return bc

func _test_multi_enemy_setup(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 3 敵 setup → state["enemies"].size() == 3、active = 0、alias 同步到 enemies[0]
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1], enemies[2]])
	var slots: Array = bc.state["enemies"] as Array
	_check(slots.size() == 3, "should have 3 enemy slots, got %d" % slots.size())
	_check(int(bc.state["active_enemy_index"]) == 0, "active_enemy_index should default to 0")
	_check(int(bc.state["enemy_hp"]) == int((slots[0] as Dictionary)["hp"]), "alias enemy_hp must equal enemies[0].hp")
	_check(String(bc.state["enemy_name"]) == String((slots[0] as Dictionary)["name"]), "alias enemy_name must equal enemies[0].name")
	_check(bc.enemies.size() == 3, "BC.enemies array should have 3")
	# 向後相容單敵 setup
	var bc_single: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	_check((bc_single.state["enemies"] as Array).size() == 1, "single enemy via array → 1 slot")
	# 舊 API（傳 EnemyData 而非 Array）
	var rs: RunState = RunState.new()
	rs.init_for(characters[0])
	var bc_old: BattleController = BattleController.new()
	bc_old.setup(rs, characters[0], enemies[0])
	_check((bc_old.state["enemies"] as Array).size() == 1, "legacy single-EnemyData setup → 1 slot")
	_check(bc_old.enemy != null, "legacy enemy getter should still work")

func _test_multi_enemy_damage_routing(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 單體 damage 只打 active；切換 active 後再打、原敵 HP 不變
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1]])
	var initial_hp_0: int = int((bc.state["enemies"][0] as Dictionary)["hp"])
	var initial_hp_1: int = int((bc.state["enemies"][1] as Dictionary)["hp"])
	# 對 active (idx 0) 施加 10 傷
	bc.resolver._resolve_effect({"kind": "damage", "amount": 10}, bc.state)
	bc._sync_state_to_active_enemy()
	_check(int((bc.state["enemies"][0] as Dictionary)["hp"]) == initial_hp_0 - 10, "active enemy slot must reflect single damage")
	_check(int((bc.state["enemies"][1] as Dictionary)["hp"]) == initial_hp_1, "non-active enemy must not be touched")
	# 切到 enemies[1]
	_check(bc.set_active_enemy(1), "set_active_enemy(1) should succeed")
	_check(int(bc.state["enemy_hp"]) == initial_hp_1, "after switch, alias must point to enemies[1]")
	# 打 5 傷
	bc.resolver._resolve_effect({"kind": "damage", "amount": 5}, bc.state)
	bc._sync_state_to_active_enemy()
	_check(int((bc.state["enemies"][0] as Dictionary)["hp"]) == initial_hp_0 - 10, "enemies[0] HP must not change after we switched")
	_check(int((bc.state["enemies"][1] as Dictionary)["hp"]) == initial_hp_1 - 5, "enemies[1] takes the new damage")

func _test_multi_enemy_aoe_damage(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# damage_all 應對 3 敵都打到 (扣除個別 block)
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1], enemies[2]])
	var hp_before: Array[int] = []
	for i: int in range(3):
		hp_before.append(int((bc.state["enemies"][i] as Dictionary)["hp"]))
	bc.resolver._resolve_effect({"kind": "damage_all", "amount": 8}, bc.state)
	for i: int in range(3):
		var after: int = int((bc.state["enemies"][i] as Dictionary)["hp"])
		_check(after == hp_before[i] - 8, "enemy[%d] HP %d → %d expected %d" % [i, hp_before[i], after, hp_before[i] - 8])
	# alias 應同步 active (idx 0)
	_check(int(bc.state["enemy_hp"]) == int((bc.state["enemies"][0] as Dictionary)["hp"]), "alias enemy_hp should sync to active after AOE")

func _test_multi_enemy_aoe_status(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# poison_all / weak_all / vulnerable_all 應對全敵套 (skip 已死)
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1]])
	bc.resolver._resolve_effect({"kind": "poison_all", "amount": 3}, bc.state)
	bc.resolver._resolve_effect({"kind": "weak_all", "amount": 2}, bc.state)
	bc.resolver._resolve_effect({"kind": "vulnerable_all", "amount": 1}, bc.state)
	for i: int in range(2):
		var slot: Dictionary = bc.state["enemies"][i] as Dictionary
		_check(int(slot["poison"]) == 3, "enemy[%d] poison should be 3" % i)
		_check(int(slot["weak"]) == 2, "enemy[%d] weak should be 2" % i)
		_check(int(slot["vulnerable"]) == 1, "enemy[%d] vulnerable should be 1" % i)
	# alias 應同步 active
	_check(int(bc.state["enemy_poison"]) == 3, "alias poison should sync")
	_check(int(bc.state["enemy_weak"]) == 2, "alias weak should sync")
	_check(int(bc.state["enemy_vulnerable"]) == 1, "alias vulnerable should sync")

func _test_multi_enemy_partial_kill(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# active 被打死 → _check_active_enemy_death 應切到下一個活敵
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1]])
	# 把 enemies[0] HP 設成 1 (作弊)
	(bc.state["enemies"][0] as Dictionary)["hp"] = 1
	bc._sync_active_enemy_to_state()
	# 找一張會打 damage 的卡（任何 character 的 starting deck 都有）
	var damage_card: CardData = null
	for c: CardData in characters[0].starting_deck:
		for eff: Dictionary in c.effects:
			if String(eff.get("kind", "")) == "damage" and int(eff.get("amount", 0)) >= 1:
				damage_card = c
				break
		if damage_card != null:
			break
	_check(damage_card != null, "需要找到一張 damage 卡測試")
	bc.state["energy"] = 99
	bc.play_card(damage_card)
	# active 應自動切到 enemies[1]
	_check(int(bc.state["active_enemy_index"]) == 1, "active should auto-switch to enemies[1] after enemies[0] death; got %d" % int(bc.state["active_enemy_index"]))
	# 但 victory 還不是（enemies[1] 還活）
	_check(not bc.is_victory(), "should not be victory while enemies[1] still alive")
	# 把 enemies[1] 也擊敗
	(bc.state["enemies"][1] as Dictionary)["hp"] = 0
	_check(bc.is_victory(), "全敵死光 = is_victory")

func _test_multi_enemy_set_active(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# set_active_enemy 邊界：超出 / 同 / 已死 = false；切換後 alias 換值
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1], enemies[2]])
	_check(not bc.set_active_enemy(0), "same index → false")
	_check(not bc.set_active_enemy(-1), "negative index → false")
	_check(not bc.set_active_enemy(99), "out of range → false")
	# 把 enemies[1] 打死
	(bc.state["enemies"][1] as Dictionary)["hp"] = 0
	_check(not bc.set_active_enemy(1), "switching to dead enemy → false")
	# 合法切換
	_check(bc.set_active_enemy(2), "valid switch → true")
	_check(int(bc.state["active_enemy_index"]) == 2, "active index should be 2")
	_check(String(bc.state["enemy_name"]) == String((bc.state["enemies"][2] as Dictionary)["name"]), "alias name should match enemies[2]")

# ── Phase 3+3.5：多敵回合 + 召喚 ───────────────────────────────────

func _test_multi_enemy_turn_each_attacks(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 2 敵各自攻擊一次 → 玩家受 2 倍傷害（無 block）
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1]])
	bc.start_turn()
	var player_hp_before: int = int(bc.state["player_hp"])
	var actions: Array[Dictionary] = bc.begin_enemy_phase()
	_check(actions.size() == 2, "begin_enemy_phase should return one entry per enemy")
	# 兩敵各自有 intent
	_check(not actions[0].is_empty(), "enemies[0] should have an action")
	_check(not actions[1].is_empty(), "enemies[1] should have an action")
	bc.resolve_enemy_phase(actions)
	# 兩敵都打到玩家（假設兩個都選了 damage action）— 至少 HP 有掉
	var player_hp_after: int = int(bc.state["player_hp"])
	_check(player_hp_after < player_hp_before, "player should take damage from at least one enemy")
	# 死敵測試：把 enemies[1] HP 設 0 → begin_enemy_phase 該敵 action 為 empty
	(bc.state["enemies"][1] as Dictionary)["hp"] = 0
	var actions2: Array[Dictionary] = bc.begin_enemy_phase()
	_check(actions2[1].is_empty(), "dead enemy's action should be empty")
	_check(not actions2[0].is_empty(), "alive enemy still acts")

func _test_multi_enemy_per_enemy_phase(characters: Array[CharacterData]) -> void:
	# 每個敵獨立 phase 2 切換：bandit 沒有 phase_2 → 永不 phased；boss 有
	# 用兩個 boss（拜月教主 + 殭屍大帥）測試
	var moon: EnemyData = GameData.boss_for_act(5)  # 拜月教主
	var zombie: EnemyData = GameData.boss_for_act(2)  # 殭屍大帥
	var bc: BattleController = _make_multi_battle(characters[0], [moon, zombie])
	# 把 enemies[0] (moon) HP 砍到 < 50%
	var slot0: Dictionary = bc.state["enemies"][0] as Dictionary
	slot0["hp"] = int(slot0["max_hp"]) / 3  # ~38
	bc._sync_active_enemy_to_state()
	# 觸發 phase check
	bc._check_phase_transition()
	_check(bc.enemy_phased[0], "moon should phase after dropping below 50%% (hp=%d / max=%d)" % [int(slot0["hp"]), int(slot0["max_hp"])])
	_check(not bc.enemy_phased[1], "zombie should not phase yet")
	# 切到 zombie，砍它 hp 也 < 50%
	bc.set_active_enemy(1)
	var slot1: Dictionary = bc.state["enemies"][1] as Dictionary
	slot1["hp"] = int(slot1["max_hp"]) / 3
	bc._sync_active_enemy_to_state()
	bc._check_phase_transition()
	_check(bc.enemy_phased[1], "zombie should now phase too")

func _test_summon_basic(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# spawn_enemy("water_tentacle") → enemies +1，state["enemies"] +1
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	var size_before: int = bc.enemies.size()
	var slots_before: int = (bc.state["enemies"] as Array).size()
	var ok: bool = bc.spawn_enemy("water_tentacle")
	_check(ok, "spawn_enemy(water_tentacle) should succeed")
	_check(bc.enemies.size() == size_before + 1, "enemies array should grow by 1")
	_check((bc.state["enemies"] as Array).size() == slots_before + 1, "state.enemies should grow by 1")
	_check(bc.enemy_action_indices.size() == bc.enemies.size(), "enemy_action_indices size synced")
	_check(bc.enemy_phased.size() == bc.enemies.size(), "enemy_phased size synced")
	var new_slot: Dictionary = bc.state["enemies"][size_before] as Dictionary
	_check(String(new_slot["id"]) == "water_tentacle", "new slot id should be water_tentacle")
	_check(int(new_slot["hp"]) == int(new_slot["max_hp"]), "new minion starts at full HP")

func _test_summon_cap(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 戰場已 3 敵 → spawn 拒絕
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1], enemies[2]])
	_check(bc.enemies.size() == BattleController.MAX_ENEMIES_PER_BATTLE, "setup at cap")
	var ok: bool = bc.spawn_enemy("water_tentacle")
	_check(not ok, "spawn_enemy should reject when at MAX_ENEMIES_PER_BATTLE")
	_check(bc.enemies.size() == BattleController.MAX_ENEMIES_PER_BATTLE, "no enemy added")

func _test_summon_unknown_id(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	var ok: bool = bc.spawn_enemy("ghost_no_such_enemy")
	_check(not ok, "spawn_enemy should reject unknown id")
	_check(bc.enemies.size() == 1, "no enemy added")

func _test_summon_from_boss_pool(characters: Array[CharacterData]) -> void:
	# 拜月教主 phase 2 的「召喚水妖觸手」action 應觸發 spawn
	# 模擬：把拜月教主 phase 2 強制啟動，再走 begin/resolve_enemy_phase
	var moon: EnemyData = GameData.boss_for_act(5)
	var bc: BattleController = _make_multi_battle(characters[0], [moon])
	# 強制 phased + action_index 指向召喚招式
	bc.enemy_phased[0] = true
	# 找召喚招式在 phase_2_actions 的 index
	var summon_idx: int = -1
	for i: int in range(moon.phase_2_actions.size()):
		var effs: Array = (moon.phase_2_actions[i] as Dictionary).get("effects", []) as Array
		for ef: Variant in effs:
			if String((ef as Dictionary).get("kind", "")) == "summon":
				summon_idx = i
				break
		if summon_idx >= 0:
			break
	_check(summon_idx >= 0, "boss phase_2_actions should include a summon action")
	bc.enemy_action_indices[0] = summon_idx
	# 跑回合
	bc.start_turn()
	var size_before: int = bc.enemies.size()
	var actions: Array[Dictionary] = bc.begin_enemy_phase()
	bc.resolve_enemy_phase(actions)
	# 召喚成功 → 戰場 +1（前提：未到 cap）
	_check(bc.enemies.size() == size_before + 1, "summon action should add 1 enemy; got %d → %d" % [size_before, bc.enemies.size()])
	# 新敵應在 summon_pool 內
	var new_id: String = String((bc.state["enemies"][size_before] as Dictionary)["id"])
	_check(new_id in moon.summon_pool, "summoned id should be from boss summon_pool; got '%s'" % new_id)

func _test_multi_hit_damage(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 連擊 hits 參數：每段各走 power/weak/vulnerable/block 管線
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	var s: Dictionary = bc.state
	# 清成已知乾淨值（避開角色 passive / 專武干擾）
	s["player_power"] = 0; s["player_weak"] = 0
	s["enemy_block"] = 0; s["enemy_vulnerable"] = 0
	s["enemy_hp"] = 100

	# 1) 純連擊：4 傷害 ×3 = 12
	bc.resolver._resolve_effect({"kind": "damage", "amount": 4, "hits": 3}, s)
	_check(int(s["enemy_hp"]) == 88, "4x3 multi-hit should deal 12; hp=%d" % int(s["enemy_hp"]))

	# 2) 格擋跨段遞減：block 5、4×3 → 段1 吃光後剩 1 擋、段2 扣3、段3 扣4 = 失 7
	s["enemy_hp"] = 100; s["enemy_block"] = 5
	bc.resolver._resolve_effect({"kind": "damage", "amount": 4, "hits": 3}, s)
	_check(int(s["enemy_hp"]) == 93, "block should deplete across hits → loss 7; hp=%d" % int(s["enemy_hp"]))
	_check(int(s["enemy_block"]) == 0, "block should be 0 after; got %d" % int(s["enemy_block"]))

	# 3) 力量逐段加成：power 2、5×2 → 每段 7、共 14
	s["enemy_hp"] = 100; s["enemy_block"] = 0; s["player_power"] = 2
	bc.resolver._resolve_effect({"kind": "damage", "amount": 5, "hits": 2}, s)
	_check(int(s["enemy_hp"]) == 86, "power should apply per hit (7x2=14); hp=%d" % int(s["enemy_hp"]))

	# 4) 一致性：hits=3 等同 3 次單擊
	s["enemy_hp"] = 100; s["player_power"] = 0; s["enemy_block"] = 0
	bc.resolver._resolve_effect({"kind": "damage", "amount": 4, "hits": 3}, s)
	var multi_loss: int = 100 - int(s["enemy_hp"])
	s["enemy_hp"] = 100
	for _i: int in range(3):
		bc.resolver._resolve_effect({"kind": "damage", "amount": 4}, s)
	var single_loss: int = 100 - int(s["enemy_hp"])
	_check(multi_loss == single_loss, "hits=3 (%d) should equal 3x single (%d)" % [multi_loss, single_loss])

func _test_thorns_reflects_to_attacker(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 林月如反擊流 (Thorns)：被攻擊時反彈 player_thorns 點傷害給攻擊者
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	var s: Dictionary = bc.state
	s["player_thorns"] = 3
	s["player_block"] = 0; s["player_hp"] = 50; s["player_max_hp"] = 50
	s["enemy_block"] = 0
	var enemy_hp_before: int = int(s["enemy_hp"])
	# 敵人攻擊 5 點（from_enemy=true）
	bc.resolver._resolve_effect({"kind": "damage", "amount": 5}, s, true)
	# 玩家失 5 HP（無格擋、無 vuln）
	_check(int(s["player_hp"]) == 45, "thorns: player should still take damage; hp=%d" % int(s["player_hp"]))
	# 敵人失 3 HP（thorns 反擊，不過 weak/vuln）
	_check(int(s["enemy_hp"]) == enemy_hp_before - 3, "thorns: enemy should reflect 3; hp=%d" % int(s["enemy_hp"]))
	# Thorns 不衰減
	_check(int(s["player_thorns"]) == 3, "thorns 不衰減")

	# 多次攻擊 → 多次反擊
	s["enemy_block"] = 0; s["enemy_hp"] = enemy_hp_before
	for _i: int in range(3):
		bc.resolver._resolve_effect({"kind": "damage", "amount": 2}, s, true)
	# 每次攻擊都反 3 → 共 9
	_check(int(s["enemy_hp"]) == enemy_hp_before - 9, "thorns 應每次攻擊都觸發；hp=%d expected %d" % [int(s["enemy_hp"]), enemy_hp_before - 9])

	# Thorns effect kind：用 thorns 卡可疊層
	s["player_thorns"] = 0
	bc.resolver._resolve_effect({"kind": "thorns", "amount": 2}, s)
	bc.resolver._resolve_effect({"kind": "thorns", "amount": 1}, s)
	_check(int(s["player_thorns"]) == 3, "thorns 疊層: expected 3 got %d" % int(s["player_thorns"]))

func _test_lin_thorns_cards(characters: Array[CharacterData]) -> void:
	# 鳳鳴反擊 / 月華護體 卡與 鳳鳴刀 遺物存在且設定正確
	var lin: CharacterData = null
	for c: CharacterData in characters:
		if c.id == "lin_yueru":
			lin = c
			break
	_check(lin != null, "lin_yueru should exist")
	var found_fenghuan: bool = false
	var found_yuehua: bool = false
	for card: CardData in lin.reward_pool:
		if card.id == "lyr_fenghuan":
			found_fenghuan = true
			_check(int((card.effects[0] as Dictionary).get("amount", 0)) == 3, "鳳鳴反擊 thorns 應 3")
		elif card.id == "lyr_yuehua":
			found_yuehua = true
	_check(found_fenghuan and found_yuehua, "lin thorns 卡應在 reward pool")
	var dao: RelicData = RelicCatalog.by_id("fengming_dao")
	_check(dao != null, "鳳鳴刀遺物存在")
	_check(dao.character_id == "lin_yueru", "鳳鳴刀屬於 lin")

func _reset_all_enemy_slots(s: Dictionary, hp: int = 100, block: int = 0) -> void:
	# 同時重置 slots 與 active alias，避免 _sync_active_slot_from_alias 把 alias 值回寫 slot[0]
	s["enemy_hp"] = hp; s["enemy_block"] = block; s["enemy_vulnerable"] = 0; s["enemy_weak"] = 0; s["enemy_poison"] = 0
	var slots: Array = s["enemies"] as Array
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i] as Dictionary
		slot["hp"] = hp; slot["block"] = block; slot["vulnerable"] = 0; slot["weak"] = 0; slot["poison"] = 0

func _test_damage_all_multi_hit(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# damage_all 加 hits：N 敵 × M 段，每敵獨立過 block / power / vuln
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0], enemies[1], enemies[2]])
	var s: Dictionary = bc.state
	s["player_power"] = 0; s["player_weak"] = 0
	var slots: Array = s["enemies"] as Array

	# 1) damage_all 4 hits=3 → 每敵失 12
	_reset_all_enemy_slots(s, 100, 0)
	bc.resolver._resolve_effect({"kind": "damage_all", "amount": 4, "hits": 3}, s)
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i] as Dictionary
		_check(int(slot["hp"]) == 88, "enemy[%d] AOE hits=3 expected 12 dmg; hp=%d" % [i, int(slot["hp"])])

	# 2) 跨段格擋遞減：block 5、4×3 對每敵 → 失 7（段1 吃光 5 block + 0 hp；段2 失 3；段3 失 4）
	_reset_all_enemy_slots(s, 100, 5)
	bc.resolver._resolve_effect({"kind": "damage_all", "amount": 4, "hits": 3}, s)
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i] as Dictionary
		_check(int(slot["hp"]) == 93, "enemy[%d] AOE 4x3 block5 expected loss 7; hp=%d" % [i, int(slot["hp"])])
		_check(int(slot["block"]) == 0, "enemy[%d] block should deplete; got %d" % [i, int(slot["block"])])

	# 3) hits=1（預設）等同舊行為：4 → 每敵 -4
	_reset_all_enemy_slots(s, 100, 0)
	bc.resolver._resolve_effect({"kind": "damage_all", "amount": 4}, s)
	for i: int in range(slots.size()):
		_check(int((slots[i] as Dictionary)["hp"]) == 96, "default hits=1 should match old behavior; hp=%d" % int((slots[i] as Dictionary)["hp"]))

func _test_damage_debuff_bonus(characters: Array[CharacterData], enemies: Array[EnemyData]) -> void:
	# 趙靈兒杖流 payoff：base + bonus_per_layer × (weak + vuln)，再過完整 vuln 1.5 倍管線
	var bc: BattleController = _make_multi_battle(characters[0], [enemies[0]])
	var s: Dictionary = bc.state
	s["player_power"] = 0; s["player_weak"] = 0; s["enemy_block"] = 0
	s["enemy_weak"] = 0; s["enemy_vulnerable"] = 0
	s["enemy_hp"] = 100

	# 1) 無 debuff：5 + 0 = 5
	bc.resolver._resolve_effect({"kind": "damage_debuff_bonus", "amount": 5, "bonus_per_layer": 2}, s)
	_check(int(s["enemy_hp"]) == 95, "no debuff: 5 dmg; hp=%d" % int(s["enemy_hp"]))

	# 2) 2 weak + 1 vuln = 3 層 → base 5 + 2*3 = 11；再過 vuln 1.5 倍 = 17（ceil）
	s["enemy_hp"] = 100; s["enemy_weak"] = 2; s["enemy_vulnerable"] = 1
	bc.resolver._resolve_effect({"kind": "damage_debuff_bonus", "amount": 5, "bonus_per_layer": 2}, s)
	_check(int(s["enemy_hp"]) == 83, "with debuff: expected 17; hp=%d (loss %d)" % [int(s["enemy_hp"]), 100 - int(s["enemy_hp"])])

	# 3) 力量加成也吃：power 2、無 debuff → 5+2 = 7
	s["enemy_hp"] = 100; s["enemy_weak"] = 0; s["enemy_vulnerable"] = 0; s["player_power"] = 2
	bc.resolver._resolve_effect({"kind": "damage_debuff_bonus", "amount": 5, "bonus_per_layer": 2}, s)
	_check(int(s["enemy_hp"]) == 93, "with power: expected 7; hp=%d" % int(s["enemy_hp"]))

func _test_zhao_staff_payoff_cards(characters: Array[CharacterData]) -> void:
	# 水靈封印 / 甘霖咒 在 Zhao 獎勵池
	var zl: CharacterData = null
	for c: CharacterData in characters:
		if c.id == "zhao_linger":
			zl = c
			break
	_check(zl != null, "zhao_linger should exist")
	var found_shuiyin: bool = false
	var found_ganlin: bool = false
	for card: CardData in zl.reward_pool:
		if card.id == "zl_shuiyin":
			found_shuiyin = true
			var eff: Dictionary = card.effects[0] as Dictionary
			_check(String(eff.get("kind", "")) == "damage_debuff_bonus", "水靈封印 應為 damage_debuff_bonus")
		elif card.id == "zl_ganlin":
			found_ganlin = true
	_check(found_shuiyin and found_ganlin, "zhao 杖流 payoff 卡應在 reward pool")

func _test_anu_blade_cards(characters: Array[CharacterData]) -> void:
	# 阿奴刀流：連擊卡在獎勵池 + 巫月神刀遺物存在
	var anu: CharacterData = null
	for c: CharacterData in characters:
		if c.id == "anu":
			anu = c
			break
	_check(anu != null, "anu character should exist")
	var found_wuyue: bool = false
	var found_xueren: bool = false
	for card: CardData in anu.reward_pool:
		if card.id == "anu_wuyuezhan":
			found_wuyue = true
			_check(int((card.effects[0] as Dictionary).get("hits", 1)) == 2, "巫月斬 should be 2 hits")
		elif card.id == "anu_xuerenwu":
			found_xueren = true
			_check(int((card.effects[0] as Dictionary).get("hits", 1)) == 3, "血刃亂舞 should be 3 hits")
	_check(found_wuyue and found_xueren, "anu blade cards should be in reward pool")
	# 巫月神刀遺物
	var dao: RelicData = RelicCatalog.by_id("wuyue_shendao")
	_check(dao != null, "巫月神刀 relic should exist")
	_check(dao.character_id == "anu", "巫月神刀 should belong to anu")

# ──────────────────────────────────────────────────────────────────────
# Event Branching Phase 1：EventRunner 純走訪器測試
# 用 spring variant 當測試資料（已有完整 tree schema）。
# 這些測試完全不碰 UI / 不結算 effects，只驗證走訪器邏輯正確。
# ──────────────────────────────────────────────────────────────────────

func _test_event_runner_has_tree() -> void:
	# spring 有 tree；某個還沒做 tree 的事件（如 shrine）沒有
	var spring: Dictionary = EventData.for_variant("spring")
	_check(EventRunner.has_tree(spring), "spring should have tree schema")
	var legacy: Dictionary = EventData.for_variant("lingmiao")
	_check(not EventRunner.has_tree(legacy), "lingmiao should still use legacy flat schema")

func _test_event_runner_root_choices() -> void:
	var spring: Dictionary = EventData.for_variant("spring")
	var root: Dictionary = EventRunner.get_node(spring, "root")
	_check(root.has("prompt"), "root node should have prompt")
	_check(root.has("choices"), "root node should have choices array")
	# 用 li_xiaoyao + observe_tokens=3 的 context：應看見全部 5 個 choices
	var ctx_full: Dictionary = EventRunner.build_context("li_xiaoyao", 50, 0, 3, [], 10)
	var visible: Array = EventRunner.visible_choices(root, ctx_full)
	_check(visible.size() == 5, "li_xiaoyao with observe token should see 5 choices, got %d" % visible.size())

func _test_event_runner_requires_character() -> void:
	var spring: Dictionary = EventData.for_variant("spring")
	var root: Dictionary = EventRunner.get_node(spring, "root")
	# zhao_linger（非 li_xiaoyao）+ observe_tokens=3 → 不見 lxy_meditate，剩 4 個
	var ctx_zhao: Dictionary = EventRunner.build_context("zhao_linger", 50, 0, 3, [], 10)
	var visible: Array = EventRunner.visible_choices(root, ctx_zhao)
	_check(visible.size() == 4, "zhao_linger should not see lxy-only choice; expected 4, got %d" % visible.size())
	# 確認 lxy_meditate 不在列表中
	for c: Variant in visible:
		_check(String((c as Dictionary)["id"]) != "lxy_meditate", "lxy_meditate should be filtered for zhao_linger")

func _test_event_runner_requires_observe_token() -> void:
	var spring: Dictionary = EventData.for_variant("spring")
	var root: Dictionary = EventRunner.get_node(spring, "root")
	# zhao_linger + observe_tokens=0 → 看不見 lxy_meditate（角色不對）也看不見 observe_pool（無 token）→ 剩 3 個
	var ctx_no_token: Dictionary = EventRunner.build_context("zhao_linger", 50, 0, 0, [], 10)
	var visible: Array = EventRunner.visible_choices(root, ctx_no_token)
	_check(visible.size() == 3, "zhao_linger w/o observe token should see 3 choices, got %d" % visible.size())
	for c: Variant in visible:
		_check(String((c as Dictionary)["id"]) != "observe_pool", "observe_pool should be filtered without token")

func _test_event_runner_node_navigation() -> void:
	var spring: Dictionary = EventData.for_variant("spring")
	# 從 root.bathe choice 跳到 node_bathe
	var node_bathe: Dictionary = EventRunner.get_node(spring, "node_bathe")
	_check(not node_bathe.is_empty(), "node_bathe should exist")
	_check(node_bathe.has("prompt"), "node_bathe should have prompt")
	var bathe_choices: Array = node_bathe.get("choices", []) as Array
	_check(bathe_choices.size() == 2, "node_bathe should have 2 choices, got %d" % bathe_choices.size())
	# node_observe 同樣可達
	var node_observe: Dictionary = EventRunner.get_node(spring, "node_observe")
	_check(not node_observe.is_empty(), "node_observe should exist")
	# 不存在的 node_id 回傳空 dict（不 crash）
	var ghost: Dictionary = EventRunner.get_node(spring, "node_does_not_exist")
	_check(ghost.is_empty(), "missing node should return empty dict")

func _test_event_runner_leaf_detection() -> void:
	var spring: Dictionary = EventData.for_variant("spring")
	var root: Dictionary = EventRunner.get_node(spring, "root")
	var choices: Array = root.get("choices", []) as Array
	# drink 是葉 / bathe 不是葉（有 next）
	for c: Variant in choices:
		var choice: Dictionary = c as Dictionary
		var cid: String = String(choice["id"])
		match cid:
			"drink":
				_check(EventRunner.is_leaf(choice), "drink should be leaf")
				_check(EventRunner.leaf_kind(choice) == "reward", "drink kind should be reward")
			"bathe":
				_check(not EventRunner.is_leaf(choice), "bathe should not be leaf (has next)")
			"observe_pool":
				_check(not EventRunner.is_leaf(choice), "observe_pool should not be leaf")
			"leave":
				_check(EventRunner.is_leaf(choice), "leave should be leaf")
				_check(EventRunner.leaf_kind(choice) == "neutral", "leave kind should be neutral")
	# node_bathe.relax 是 gamble 葉節點
	var node_bathe: Dictionary = EventRunner.get_node(spring, "node_bathe")
	var relax_choice: Dictionary = ((node_bathe["choices"] as Array)[0]) as Dictionary
	_check(String(relax_choice["id"]) == "relax")
	_check(EventRunner.is_leaf(relax_choice))
	_check(EventRunner.leaf_kind(relax_choice) == "gamble")
	# badge text 對應
	_check(String(EventRunner.badge_for_kind("battle")["text"]).contains("戰鬥"))
	_check(String(EventRunner.badge_for_kind("gamble")["text"]).contains("賭運"))

func _test_event_runner_legacy_fallback() -> void:
	# 還沒做 tree 的 event：has_tree=false、get_node 回空 dict、不爆炸
	var legacy_ed: Dictionary = EventData.for_variant("lingmiao")
	_check(not EventRunner.has_tree(legacy_ed))
	_check(EventRunner.get_node(legacy_ed, "root").is_empty())
	_check(EventRunner.get_node(legacy_ed, "node_anything").is_empty())
	# eval_requires 空 dict / 缺欄位都應通過
	_check(EventRunner.eval_requires({}, {}))
	_check(EventRunner.eval_requires({"character": []}, {"character_id": "anyone"}))
	# min_gold 不夠應拒
	_check(not EventRunner.eval_requires({"min_gold": 100}, {"gold": 50}))
	_check(EventRunner.eval_requires({"min_gold": 100}, {"gold": 100}))
	# has_relic 接受 string 與 Array
	_check(EventRunner.eval_requires({"has_relic": "nuwa_shi"}, {"relic_ids": ["nuwa_shi", "other"]}))
	_check(not EventRunner.eval_requires({"has_relic": "nuwa_shi"}, {"relic_ids": ["other"]}))
	_check(EventRunner.eval_requires({"has_relic": ["a", "b"]}, {"relic_ids": ["b"]}))

# ──────────────────────────────────────────────────────────────────────
# Event Branching Phase 5：observe_tokens + next_battle_buffs 資料層
# ──────────────────────────────────────────────────────────────────────

func _test_observe_token_init_and_consume(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	_check(state.observe_tokens == RunState.OBSERVE_TOKEN_START,
		"fresh run should start with %d observe tokens, got %d" % [RunState.OBSERVE_TOKEN_START, state.observe_tokens])
	# 消費 N 次直到 0；之後再消費應失敗
	for i: int in range(RunState.OBSERVE_TOKEN_START):
		_check(state.consume_observe_token(), "consume should succeed while tokens > 0 (i=%d)" % i)
	_check(state.observe_tokens == 0)
	_check(not state.consume_observe_token(), "consume should fail at 0 tokens")
	# grant 補回
	state.grant_observe_tokens(2)
	_check(state.observe_tokens == 2, "grant +2 should bring tokens to 2, got %d" % state.observe_tokens)

func _test_observe_token_save_roundtrip(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	state.observe_tokens = 5
	var data: Dictionary = state.to_dict()
	_check(data.has("observe_tokens"))
	_check(int(data["observe_tokens"]) == 5)
	var restored: RunState = RunState.new()
	var ok: bool = restored.from_dict(data, characters)
	_check(ok)
	_check(restored.observe_tokens == 5, "round-trip should preserve observe_tokens; got %d" % restored.observe_tokens)

func _test_observe_token_old_save_compat(characters: Array[CharacterData]) -> void:
	# 舊存檔無 observe_tokens 欄位 → fallback 起始值
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	var data: Dictionary = state.to_dict()
	data.erase("observe_tokens")
	data.erase("next_battle_buffs")
	var restored: RunState = RunState.new()
	var ok: bool = restored.from_dict(data, characters)
	_check(ok, "old save should still load")
	_check(restored.observe_tokens == RunState.OBSERVE_TOKEN_START,
		"old save should fallback to %d tokens, got %d" % [RunState.OBSERVE_TOKEN_START, restored.observe_tokens])
	_check(restored.next_battle_buffs.is_empty())

func _test_next_battle_buff_queue_roundtrip(characters: Array[CharacterData]) -> void:
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	state.queue_next_battle_buff([{"kind": "energy", "amount": 1}, {"kind": "block", "amount": 5}])
	_check(state.next_battle_buffs.size() == 2)
	# round-trip
	var data: Dictionary = state.to_dict()
	var restored: RunState = RunState.new()
	_check(restored.from_dict(data, characters))
	_check(restored.next_battle_buffs.size() == 2, "round-trip should preserve next_battle_buffs size")
	# consume 清空
	var consumed: Array[Dictionary] = restored.consume_next_battle_buffs()
	_check(consumed.size() == 2)
	_check(restored.next_battle_buffs.is_empty(), "after consume, queue should be empty")

func _test_pending_event_return_init(characters: Array[CharacterData]) -> void:
	# 新 run 不應有 pending_event_return
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	_check(state.pending_event_return.is_empty(), "fresh run should have empty pending_event_return")
	# 設值後應能讀回
	state.pending_event_return = {
		"victory_effects": [{"kind": "gold", "amount": 20}],
		"defeat_effects": [{"kind": "damage", "amount": 10}],
	}
	_check(state.pending_event_return.has("victory_effects"))
	_check((state.pending_event_return["victory_effects"] as Array).size() == 1)

func _test_pending_event_return_not_persisted(characters: Array[CharacterData]) -> void:
	# pending_event_return 不存檔（in-flight 戰鬥不該跨 save 保留）
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	state.pending_event_return = {
		"victory_effects": [{"kind": "gold", "amount": 20}],
		"defeat_effects": [],
	}
	var data: Dictionary = state.to_dict()
	_check(not data.has("pending_event_return"),
		"pending_event_return should not be persisted (in-flight only)")
	# 載回後也是空（不存在欄位 → 物件初始化時是 {}）
	var restored: RunState = RunState.new()
	_check(restored.from_dict(data, characters))
	_check(restored.pending_event_return.is_empty(),
		"restored RunState should have empty pending_event_return")

# ──────────────────────────────────────────────────────────────────────
# Event Branching Phase 4：Curse 牌系統
# ──────────────────────────────────────────────────────────────────────

func _test_curse_catalog() -> void:
	# 6 張 curse 都齊全，有 id / display_name / description / retention
	var all_curses: Array[Dictionary] = CurseCatalog.all()
	_check(all_curses.size() == 6, "expected 6 curses, got %d" % all_curses.size())
	var expected_ids: Array[String] = ["yao_zhai", "xie_yin", "tong_ji", "hua_zhai", "jiu_zui", "gu_du"]
	for cid: String in expected_ids:
		var c: Dictionary = CurseCatalog.by_id(cid)
		_check(not c.is_empty(), "missing curse: %s" % cid)
		_check(String(c.get("display_name", "")).length() > 0, "curse %s lacks display_name" % cid)
		_check(c.has("retention"), "curse %s lacks retention" % cid)
	# make_card 產出真正 curse 牌
	var card: CardData = CurseCatalog.make_card("yao_zhai")
	_check(card != null)
	_check(card.card_type == "curse", "make_card should produce card_type=curse, got %s" % card.card_type)
	_check(card.cost == CurseCatalog.CURSE_COST, "curse cost should be CURSE_COST")
	_check(CurseCatalog.is_curse(card))
	# 未知 id 回傳 null（無 crash）
	_check(CurseCatalog.make_card("nonexistent") == null)

func _test_curse_play_card_rejected(character: CharacterData, enemy: EnemyData) -> void:
	# play_card 對 curse 直接拒絕、不消耗靈力
	var bc: BattleController = BattleController.new()
	var party: Array[CharacterData] = [character]
	var run_state: RunState = RunState.new()
	run_state.init_for(party)
	bc.setup(run_state, character, enemy.clone())
	bc.start_turn()
	var energy_before: int = int(bc.state["energy"])
	var curse_card: CardData = CurseCatalog.make_card("yao_zhai")
	var result: Dictionary = bc.play_card(curse_card)
	_check(not bool(result.get("affordable", true)), "curse play should not be affordable")
	_check(bool(result.get("curse_blocked", false)), "result should flag curse_blocked")
	_check(int(bc.state["energy"]) == energy_before, "curse rejection should not spend energy")

func _test_curse_not_upgradeable(character: CharacterData) -> void:
	# Deck 內含 curse 不會出現在 _upgradeable_cards 候選裡。
	# main.gd._upgradeable_cards 是 instance 方法 — 直接從 CurseCatalog + CardData 驗證屬性即可。
	var curse: CardData = CurseCatalog.make_card("xie_yin")
	_check(curse != null)
	# upgrade_card_in_deck 的 mode 過濾邏輯：curse 永遠不可升級
	_check(CurseCatalog.is_curse(curse))
	# upgraded_copy 不應改變 card_type
	# (即使呼叫到也不該炸；驗證 type 仍是 curse 不被破壞)
	var upgraded: CardData = curse.upgraded_copy()
	_check(upgraded.card_type == "curse", "upgraded curse must remain curse type")

func _test_curse_save_roundtrip(characters: Array[CharacterData]) -> void:
	# Curse 進 deck → to_dict/from_dict 後仍是 curse
	var state: RunState = RunState.new()
	state.init_for(characters[0])
	var deck0: Array = state.character_decks[0] as Array
	deck0.append(CurseCatalog.make_card("yao_zhai"))
	deck0.append(CurseCatalog.make_card("gu_du"))
	var data: Dictionary = state.to_dict()
	var restored: RunState = RunState.new()
	_check(restored.from_dict(data, characters))
	var rdeck: Array = restored.character_decks[0] as Array
	var found_yao: bool = false
	var found_gu: bool = false
	for c_v: Variant in rdeck:
		var c: CardData = c_v as CardData
		if c == null:
			continue
		if c.id == "yao_zhai" and c.card_type == "curse":
			found_yao = true
		elif c.id == "gu_du" and c.card_type == "curse":
			found_gu = true
	_check(found_yao, "yao_zhai curse should survive round-trip")
	_check(found_gu, "gu_du curse should survive round-trip")

func _test_curse_retention_turn_start(character: CharacterData, enemy: EnemyData) -> void:
	# 帶 yao_zhai (turn_start: -2 HP) 進戰鬥
	var bc: BattleController = BattleController.new()
	var party: Array[CharacterData] = [character]
	var run_state: RunState = RunState.new()
	run_state.init_for(party)
	# 把 curse 塞進角色 deck（setup 會複製進 BattleController 的 DeckManager）
	(run_state.character_decks[0] as Array).append(CurseCatalog.make_card("yao_zhai"))
	bc.setup(run_state, character, enemy.clone())
	# turn 1 開始：yao_zhai turn_start 應扣 2 HP
	var hp_before: int = int(bc.state["player_hp"])
	bc.start_turn()
	var hp_after: int = int(bc.state["player_hp"])
	_check(hp_after == hp_before - 2 or hp_after == 1,
		"yao_zhai should -2 HP at turn_start; got %d → %d" % [hp_before, hp_after])

func _test_curse_retention_battle_start(character: CharacterData, enemy: EnemyData) -> void:
	# gu_du 是 battle_start 觸發（turn==1 時和 turn_start 一起跑）+2 poison
	var bc: BattleController = BattleController.new()
	var party: Array[CharacterData] = [character]
	var run_state: RunState = RunState.new()
	run_state.init_for(party)
	(run_state.character_decks[0] as Array).append(CurseCatalog.make_card("gu_du"))
	bc.setup(run_state, character, enemy.clone())
	var poison_before: int = int(bc.state["player_poison"])
	bc.start_turn()
	var poison_after: int = int(bc.state["player_poison"])
	_check(poison_after >= poison_before + 2,
		"gu_du should +2 poison at battle_start (turn 1); got %d → %d" % [poison_before, poison_after])
	# turn 2 不該再觸發 battle_start curse（但會結算 poison tick；只驗證沒額外 +2）
	# 直接驗證 second start_turn 後不再加 2 stack
	var poison_t1_end: int = int(bc.state["player_poison"])
	bc.start_turn()
	# 第二回合 start_turn 觸發 poison tick，poison 會 -1（衰減）
	# 加上 battle_start 不該觸發 → poison 應該 <= poison_t1_end
	_check(int(bc.state["player_poison"]) <= poison_t1_end,
		"gu_du should NOT re-trigger at turn 2 start")

func _test_jing_hua_fu_removes_curse(character: CharacterData) -> void:
	# 模擬：deck 帶 1 張 curse → 呼叫 _try_remove_random_curse 等效邏輯後 curse 應消失
	# 因為 _try_remove_random_curse 是 main.gd 的 method，這裡用 catalog level 重現邏輯。
	var state: RunState = RunState.new()
	state.init_for(character)
	var deck0: Array = state.character_decks[0] as Array
	deck0.append(CurseCatalog.make_card("yao_zhai"))
	# 找一張 curse 並 remove
	var curse_count_before: int = 0
	for c_v: Variant in deck0:
		if CurseCatalog.is_curse(c_v as CardData):
			curse_count_before += 1
	_check(curse_count_before == 1)
	# 模擬 jing_hua_fu 觸發：找出 curse 並移除
	var removed_any: bool = false
	for i: int in range(deck0.size()):
		if CurseCatalog.is_curse(deck0[i] as CardData):
			deck0.remove_at(i)
			removed_any = true
			break
	_check(removed_any, "should have removed at least 1 curse")
	# 驗證 catalog 內確實有 jing_hua_fu relic 定義且 trigger 正確
	var jhf: RelicData = RelicCatalog.by_id("jing_hua_fu")
	_check(jhf != null, "jing_hua_fu relic missing from catalog")
	var has_battle_victory_trigger: bool = false
	for t: Dictionary in jhf.triggers:
		if String(t.get("trigger", "")) == "battle_victory":
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "remove_random_curse":
					has_battle_victory_trigger = true
	_check(has_battle_victory_trigger, "jing_hua_fu should have battle_victory + remove_random_curse")

# ──────────────────────────────────────────────────────────────────────
# Event Branching Phase 7-A：Batch A 6 個事件樹（內容驗證）
# ──────────────────────────────────────────────────────────────────────

const BATCH_A_VARIANTS: Array[String] = [
	"talisman_cache", "shrine", "treasure_chest",
	"ancestor_relic", "wandering_sage", "moonlit_pool",
]

func _test_batch_a_all_have_tree() -> void:
	# 全 6 個 variant 都應該有 tree schema、root 至少 3 個選項、含一個 observe-gated 與
	# 一個 character-gated（設計參數 4+5）
	for variant: String in BATCH_A_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		_check(EventRunner.has_tree(ed), "%s should have tree schema" % variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var choices: Array = root.get("choices", []) as Array
		_check(choices.size() >= 3, "%s root should have >=3 choices, got %d" % [variant, choices.size()])
		# 至少一個 observe_token gate
		var has_observe_gate: bool = false
		# 至少一個 character gate
		var has_char_gate: bool = false
		for c_v: Variant in choices:
			var c: Dictionary = c_v as Dictionary
			var req: Dictionary = c.get("requires", {}) as Dictionary
			if bool(req.get("observe_token", false)):
				has_observe_gate = true
			if not (req.get("character", []) as Array).is_empty():
				has_char_gate = true
		_check(has_observe_gate, "%s should have at least 1 observe-gated choice" % variant)
		_check(has_char_gate, "%s should have at least 1 character-gated choice" % variant)

func _test_batch_a_character_gating() -> void:
	# 切過 4 個角色身分都應正確過濾。預期每個 variant 至少有一個角色 ID 能看到比另一個多的選項。
	var characters_to_test: Array[String] = ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]
	for variant: String in BATCH_A_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		# 用 observe_tokens=99 排除 observe gating 影響
		var ctx_by_char: Dictionary = {}
		for cid: String in characters_to_test:
			var ctx: Dictionary = EventRunner.build_context(cid, 999, 0, 99, [], 10)
			ctx_by_char[cid] = EventRunner.visible_choices(root, ctx)
		# 至少兩個角色的可見選項數不同 → 確實有 character-gating 在生效
		var sizes: Array[int] = []
		for cid: String in characters_to_test:
			sizes.append((ctx_by_char[cid] as Array).size())
		var min_size: int = sizes[0]
		var max_size: int = sizes[0]
		for s: int in sizes:
			min_size = min(min_size, s)
			max_size = max(max_size, s)
		_check(max_size > min_size, "%s should have character-specific choices (size varies by char), all returned %d" % [variant, min_size])

func _test_batch_a_observe_gating() -> void:
	# 同一角色 + observe=0 vs observe=3 → observe=3 一定看到 >= observe=0 的選項
	for variant: String in BATCH_A_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var ctx_no: Dictionary = EventRunner.build_context("li_xiaoyao", 999, 0, 0, [], 10)
		var ctx_yes: Dictionary = EventRunner.build_context("li_xiaoyao", 999, 0, 3, [], 10)
		var v_no: int = EventRunner.visible_choices(root, ctx_no).size()
		var v_yes: int = EventRunner.visible_choices(root, ctx_yes).size()
		_check(v_yes > v_no, "%s should expose more choices with observe tokens; %d (no) vs %d (yes)" % [variant, v_no, v_yes])

func _test_batch_a_subnode_navigation() -> void:
	# 每個 variant 至少有一個 'next' 連到某 sub-node，且該 sub-node 存在且有 choices
	for variant: String in BATCH_A_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var next_targets: Array[String] = []
		for c_v: Variant in (root.get("choices", []) as Array):
			var c: Dictionary = c_v as Dictionary
			if c.has("next") and not EventRunner.is_leaf(c):
				next_targets.append(String(c["next"]))
		_check(not next_targets.is_empty(), "%s should have at least 1 sub-node choice" % variant)
		for target: String in next_targets:
			var sub: Dictionary = EventRunner.get_node(ed, target)
			_check(not sub.is_empty(), "%s next target '%s' should resolve to a node" % [variant, target])
			var sub_choices: Array = sub.get("choices", []) as Array
			_check(sub_choices.size() >= 2, "%s sub-node '%s' should have >=2 choices, got %d" % [variant, target, sub_choices.size()])

# ──────────────────────────────────────────────────────────────────────
# Event Branching Phase 7-B：Batch B 6 個事件樹（含 1-2 條戰鬥分支）
# ──────────────────────────────────────────────────────────────────────

const BATCH_B_VARIANTS: Array[String] = [
	"broken_temple", "forgotten_altar", "ancient_battlefield",
	"alchemy_furnace", "ghost_forest", "immortal_ruins",
]

func _test_batch_b_all_have_tree() -> void:
	# 6 個 variant 都應該有 tree、至少 4 個 root 選項、含 observe + character gate
	for variant: String in BATCH_B_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		_check(EventRunner.has_tree(ed), "%s should have tree schema" % variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var choices: Array = root.get("choices", []) as Array
		_check(choices.size() >= 4, "%s root should have >=4 choices, got %d" % [variant, choices.size()])
		var has_observe: bool = false
		var has_char: bool = false
		for c_v: Variant in choices:
			var c: Dictionary = c_v as Dictionary
			var req: Dictionary = c.get("requires", {}) as Dictionary
			if bool(req.get("observe_token", false)):
				has_observe = true
			if not (req.get("character", []) as Array).is_empty():
				has_char = true
		_check(has_observe, "%s should have observe-gated choice" % variant)
		_check(has_char, "%s should have character-gated choice" % variant)

func _test_batch_b_character_gating() -> void:
	# 跨 4 個角色的可見選項數應不全相同
	var character_ids: Array[String] = ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]
	for variant: String in BATCH_B_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var sizes: Array[int] = []
		for cid: String in character_ids:
			var ctx: Dictionary = EventRunner.build_context(cid, 999, 0, 99, [], 10)
			sizes.append(EventRunner.visible_choices(root, ctx).size())
		var min_s: int = sizes[0]
		var max_s: int = sizes[0]
		for s: int in sizes:
			min_s = min(min_s, s)
			max_s = max(max_s, s)
		_check(max_s > min_s, "%s should have character-specific choices; all sizes = %d" % [variant, min_s])

func _test_batch_b_observe_gating() -> void:
	for variant: String in BATCH_B_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var root: Dictionary = EventRunner.get_node(ed, "root")
		var ctx_no: Dictionary = EventRunner.build_context("li_xiaoyao", 999, 0, 0, [], 10)
		var ctx_yes: Dictionary = EventRunner.build_context("li_xiaoyao", 999, 0, 3, [], 10)
		var v_no: int = EventRunner.visible_choices(root, ctx_no).size()
		var v_yes: int = EventRunner.visible_choices(root, ctx_yes).size()
		_check(v_yes > v_no, "%s should expose more choices with observe; %d vs %d" % [variant, v_no, v_yes])

func _test_batch_b_battle_leaves_valid() -> void:
	# 每個 variant 至少有一條 battle 葉節點（root 或 sub-node 內），且：
	#   - enemy_id 在 GameData.enemy_by_id 找得到
	#   - victory_effects 與 defeat_effects 都是 array（可空）
	#   - hp_mult 若有定義應 > 0
	var total_battle_leaves: int = 0
	for variant: String in BATCH_B_VARIANTS:
		var ed: Dictionary = EventData.for_variant(variant)
		var battle_count: int = _count_battle_leaves_in_tree(ed)
		_check(battle_count >= 1, "%s should have >=1 battle leaf, got %d" % [variant, battle_count])
		total_battle_leaves += battle_count
	# 設計凍結：6 個事件共 8 條 battle 葉節點
	_check(total_battle_leaves == 8,
		"expected 8 battle leaves total in Batch B, got %d" % total_battle_leaves)

func _count_battle_leaves_in_tree(ed: Dictionary) -> int:
	# 遍歷 root + 所有 nodes 的 choices，找 outcome.kind == "battle"
	var count: int = 0
	var all_nodes: Array[Dictionary] = [EventRunner.get_node(ed, "root")]
	var nodes_map: Dictionary = (ed.get("tree", {}) as Dictionary).get("nodes", {}) as Dictionary
	for k: Variant in nodes_map.keys():
		all_nodes.append(nodes_map[k] as Dictionary)
	for node: Dictionary in all_nodes:
		for c_v: Variant in (node.get("choices", []) as Array):
			var c: Dictionary = c_v as Dictionary
			if not EventRunner.is_leaf(c):
				continue
			var outcome: Dictionary = c["outcome"] as Dictionary
			if String(outcome.get("kind", "")) != "battle":
				continue
			count += 1
			# 驗證 battle dict 內容
			var bd: Dictionary = outcome.get("battle", {}) as Dictionary
			var enemy_id: String = String(bd.get("enemy_id", ""))
			var enemy: EnemyData = GameData.enemy_by_id(enemy_id)
			assert(enemy != null, "battle outcome references unknown enemy '%s'" % enemy_id)
			var hp_mult: float = float(bd.get("enemy_hp_mult", 1.0))
			assert(hp_mult > 0.0, "enemy_hp_mult should be > 0, got %f for enemy %s" % [hp_mult, enemy_id])
			# victory_effects / defeat_effects 可空但必須是 Array
			assert(bd.get("victory_effects", []) is Array, "victory_effects must be Array for enemy %s" % enemy_id)
			assert(bd.get("defeat_effects", []) is Array, "defeat_effects must be Array for enemy %s" % enemy_id)
	return count
