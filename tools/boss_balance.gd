extends SceneTree
# Boss 強度比較器 — 把全 8 幕 boss 放在「同一把尺」下比強弱。
# 每個 boss 對 4 角色各跑固定 Lv 分級牌組 + BattlePolicy（聰明啟發式、deterministic）N 場，
# 算勝率；勝率越低 = 該 boss 越強（在固定玩家戰力下越難打）。
#   godot --headless --path . -s tools/boss_balance.gd
# 純讀取、不寫檔；看完即可。

const TRIALS: int = 30
const TURN_LIMIT: int = 25
const PLAYER_LEVEL: int = 15  # 固定玩家戰力（中後期分級牌組）作為比較基準

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()
	var boss_acts: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
	var results: Array[Dictionary] = []
	print("=== Boss 強度比較（玩家固定 Lv%d 分級牌組，%d 場/格，回合上限 %d）===" % [PLAYER_LEVEL, TRIALS, TURN_LIMIT])
	print("勝率越低 = boss 越強\n")
	for act: int in boss_acts:
		var boss: EnemyData = GameData.boss_for_act(act)
		var per_char: Dictionary = {}
		var total_wins: int = 0
		var total_games: int = 0
		for character: CharacterData in characters:
			var deck: Array[CardData] = _leveled_deck(character, PLAYER_LEVEL)
			var wins: int = 0
			for trial: int in range(TRIALS):
				seed(trial * 7919 + hash(character.id) * 17 + act * 31)
				if _simulate_battle(character, boss, deck):
					wins += 1
			var wr: int = int(round(100.0 * float(wins) / float(TRIALS)))
			per_char[character.id] = wr
			total_wins += wins
			total_games += TRIALS
		var avg: int = int(round(100.0 * float(total_wins) / float(total_games)))
		results.append({"act": act, "name": boss.display_name, "hp": boss.max_hp, "avg": avg, "per_char": per_char})
	# 依平均勝率排序（升冪 → 最強 boss 在最上）
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["avg"]) < int(b["avg"]))
	print("排名（最強 → 最弱）：")
	for i: int in range(results.size()):
		var r: Dictionary = results[i]
		var pc: Dictionary = r["per_char"]
		print("  #%d  第%d幕 %s (HP %d) — 平均勝率 %d%%   [李 %d / 趙 %d / 林 %d / 阿奴 %d]" % [
			i + 1, int(r["act"]), String(r["name"]), int(r["hp"]), int(r["avg"]),
			int(pc.get("li_xiaoyao", -1)), int(pc.get("zhao_linger", -1)),
			int(pc.get("lin_yueru", -1)), int(pc.get("anu", -1))])
	quit(0)

func _leveled_deck(character: CharacterData, level: int) -> Array[CardData]:
	var deck: Array[CardData] = []
	for card: CardData in character.starting_deck:
		deck.append(card)
	for unlock: CardData in LevelSystem.all_unlocked_cards(character.id, level):
		deck.append(unlock)
	return deck

func _simulate_battle(character: CharacterData, enemy_template: EnemyData, deck_override: Array[CardData]) -> bool:
	var run_state: RunState = RunState.new()
	run_state.init_for(character)
	if not deck_override.is_empty():
		run_state.deck = deck_override
	var enemy: EnemyData = enemy_template.clone()
	var bc: BattleController = BattleController.new()
	bc.setup(run_state, character, enemy)
	for _turn: int in range(TURN_LIMIT):
		bc.start_turn()
		if bc.is_battle_over():
			break
		_policy_play_out_turn(bc)
		if bc.is_battle_over():
			break
		bc.resolve_enemy_phase(bc.begin_enemy_phase())
	return bc.is_victory()

func _policy_play_out_turn(bc: BattleController) -> void:
	for _attempt: int in range(30):
		if bc.is_battle_over():
			return
		var act: Dictionary = BattlePolicy.next_action(bc)
		if String(act.get("kind", "end")) != "play":
			return
		var target: int = int(act.get("target", -1))
		if target >= 0:
			bc.set_active_enemy(target)
		var played: Dictionary = bc.play_card(act["card"] as CardData)
		if not bool(played.get("affordable", false)):
			return
