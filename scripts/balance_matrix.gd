extends SceneTree

# Diagnostic-only：跑 4 角色 × 全部敵人/boss 矩陣，random AI、固定 seed。
# 不在 CI、不 assert，只 print markdown tables 給 dev 看。
#
# 用法：godot --headless --path . -s scripts/balance_matrix.gd

const TRIALS: int = 50  # 比 smoke test 多，降低 RNG 雜訊

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()

	# 1) 角色 vs 一般敵人（每個 act 第一個敵人代表，20 回合上限）
	print("\n## 一般敵人勝率矩陣（20 回合上限，%d trials/cell）" % TRIALS)
	print("")
	var normal_enemies: Array[EnemyData] = []
	for act in range(1, 6):
		var pool := GameData.enemies_for_act(act)
		for e in pool:
			normal_enemies.append(e)
	_print_matrix(characters, normal_enemies, 20)

	# 2) 角色 vs boss（10 回合上限，雙向偵測「速贏率」）
	print("\n## Boss 速贏率矩陣（10 回合上限，%d trials/cell）" % TRIALS)
	print("")
	var bosses: Array[EnemyData] = []
	for act in range(1, 6):
		bosses.append(GameData.boss_for_act(act))
	_print_matrix(characters, bosses, 10)

	# 3) 角色 vs boss（20 回合上限，看完整勝率）
	print("\n## Boss 完整勝率矩陣（20 回合上限，%d trials/cell）" % TRIALS)
	print("")
	_print_matrix(characters, bosses, 20)

	# 4) 分級成長：每個等級對應幕 boss 的勝率（反映真實玩家經歷）
	print("\n## 分級牌組對應幕 boss 勝率矩陣（20 回合上限，%d trials/cell）" % TRIALS)
	print("Lv5→act2 / Lv10→act3 / Lv15→act4 / Lv20→act5；牌組 = starting + 所有 Lv≤N unlock")
	print("")
	_print_leveled_matrix(characters)

	# 5) 起始牌組組成統計
	print("\n## 起始牌組稀有度與類型分布")
	print("")
	for character: CharacterData in characters:
		_print_deck_summary(character)

	quit(0)

func _print_leveled_matrix(characters: Array[CharacterData]) -> void:
	var levels: Array[int] = [5, 10, 15, 20]
	var acts: Dictionary = {5: 2, 10: 3, 15: 4, 20: 5}
	# Header
	var header: String = "| Lv → boss \\ 角色 |"
	var sep: String = "|---|"
	for c in characters:
		header += " %s |" % c.display_name
		sep += "---|"
	print(header)
	print(sep)
	for lv: int in levels:
		var act: int = int(acts[lv])
		var boss: EnemyData = GameData.boss_for_act(act)
		var row: String = "| Lv%d → %s (HP %d) |" % [lv, boss.display_name, boss.max_hp]
		for character: CharacterData in characters:
			var deck: Array[CardData] = _leveled_deck(character, lv)
			var wr: int = _win_rate_with_deck(character, boss, 20, deck)
			row += " %d%%%s |" % [wr, _marker(wr, 20)]
		print(row)

func _leveled_deck(character: CharacterData, level: int) -> Array[CardData]:
	var deck: Array[CardData] = []
	for card: CardData in character.starting_deck:
		deck.append(card)
	for unlock: CardData in LevelSystem.all_unlocked_cards(character.id, level):
		deck.append(unlock)
	return deck

func _win_rate_with_deck(character: CharacterData, enemy: EnemyData, turn_limit: int, deck: Array[CardData]) -> int:
	var wins: int = 0
	for trial: int in range(TRIALS):
		seed(trial * 7919 + hash(character.id) * 17 + hash(enemy.id) * 31)
		if _simulate_with_deck(character, enemy, turn_limit, deck):
			wins += 1
	return int(round(100.0 * float(wins) / float(TRIALS)))

func _simulate_with_deck(character: CharacterData, enemy_template: EnemyData, max_turns: int, deck: Array[CardData]) -> bool:
	var run_state: RunState = RunState.new()
	run_state.init_for(character)
	run_state.deck = deck
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

func _print_matrix(characters: Array[CharacterData], targets: Array[EnemyData], turn_limit: int) -> void:
	# Header
	var header: String = "| 敵人 \\ 角色 |"
	var sep: String = "|---|"
	for c in characters:
		header += " %s |" % c.display_name
		sep += "---|"
	print(header)
	print(sep)
	for enemy: EnemyData in targets:
		var row: String = "| %s (HP %d) |" % [enemy.display_name, enemy.max_hp]
		for character: CharacterData in characters:
			var wr: int = _win_rate(character, enemy, turn_limit)
			row += " %d%%%s |" % [wr, _marker(wr, turn_limit)]
		print(row)

func _marker(win_rate: int, turn_limit: int) -> String:
	# 標記異常：太簡單（≥95%）或太難（≤30%）
	if turn_limit >= 20:
		if win_rate >= 95: return " ✓"
		if win_rate <= 30: return " ⚠"
		if win_rate <= 60: return " ↓"
	else:  # 10-turn speed test，期望中段差異
		if win_rate >= 95: return " ✓✓"  # 速贏（OP）
		if win_rate <= 10: return " ✗"   # 打不過
	return ""

func _win_rate(character: CharacterData, enemy_template: EnemyData, turn_limit: int) -> int:
	var wins: int = 0
	for trial: int in range(TRIALS):
		seed(trial * 7919 + hash(character.id) * 17 + hash(enemy_template.id) * 31)
		if _simulate(character, enemy_template, turn_limit):
			wins += 1
	return int(round(100.0 * float(wins) / float(TRIALS)))

func _simulate(character: CharacterData, enemy_template: EnemyData, max_turns: int) -> bool:
	var run_state: RunState = RunState.new()
	run_state.init_for(character)
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

func _print_deck_summary(character: CharacterData) -> void:
	var by_rarity: Dictionary = {"basic": 0, "uncommon": 0, "rare": 0}
	var by_type: Dictionary = {"attack": 0, "skill": 0, "power": 0}
	var total_dmg: int = 0
	var total_block: int = 0
	for card: CardData in character.starting_deck:
		var r: String = String(card.rarity) if not String(card.rarity).is_empty() else "basic"
		by_rarity[r] = int(by_rarity.get(r, 0)) + 1
		by_type[card.card_type] = int(by_type.get(card.card_type, 0)) + 1
		for eff: Dictionary in card.effects:
			match String(eff.get("kind", "")):
				"damage":
					total_dmg += int(eff.get("amount", 0))
				"block":
					total_block += int(eff.get("amount", 0))
	print("- **%s** (HP %d, %d 張)：basic %d / uncommon %d / rare %d；attack %d / skill %d / power %d；總傷 %d / 總護 %d" % [
		character.display_name, character.max_hp, character.starting_deck.size(),
		int(by_rarity["basic"]), int(by_rarity["uncommon"]), int(by_rarity["rare"]),
		int(by_type["attack"]), int(by_type["skill"]), int(by_type["power"]),
		total_dmg, total_block
	])
