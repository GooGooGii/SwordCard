extends SceneTree
# P2-10 探針：掃不同「組隊敵 HP 補正」係數下的多人隊勝率（vs 中段 boss、10 回合限時）。
# setup 已內建 PARTY_ENEMY_HP_STEP；本工具在 setup 後對敵 HP 再乘 extra 係數，
# 模擬不同 step 值，找出讓 2/3 人隊落在 40-80% 帶的補正。
# 跑法：godot --headless --path . -s tools/party_probe.gd

const TRIALS: int = 30
# 掃描情境：能量削減 × HP step（setup 內建 step 0.2，extra 換算）
const SCENARIOS: Array = [
	{"label": "e-0 hp0.2", "energy_delta": 0, "step": 0.2},
	{"label": "e-1 hp0.2", "energy_delta": -1, "step": 0.2},
	{"label": "e-1 hp0.35", "energy_delta": -1, "step": 0.35},
	{"label": "e-2 hp0.2", "energy_delta": -2, "step": 0.2},
]

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()
	# 與 smoke 的 BALANCE_BASELINES_MID 同情境：石長老（centipede_lord）
	var mid_boss: EnemyData = GameData.enemy_by_id("centipede_lord")
	var combos: Dictionary = {
		"duo_li_anu": [characters[0], characters[3]],
		"trio_li_zhao_lin": [characters[0], characters[1], characters[2]],
	}
	print("party probe vs %s (HP %d), %d trials, 10-turn limit" % [mid_boss.display_name, mid_boss.max_hp, TRIALS])
	for scen_v: Variant in SCENARIOS:
		var scen: Dictionary = scen_v as Dictionary
		var step: float = float(scen["step"])
		var energy_delta: int = int(scen["energy_delta"])
		for combo_key: String in combos.keys():
			var party_untyped: Array = combos[combo_key]
			var party: Array[CharacterData] = []
			for c: Variant in party_untyped:
				party.append(c as CharacterData)
			var n: int = party.size()
			var extra: float = (1.0 + step * (n - 1)) / (1.0 + BattleController.PARTY_ENEMY_HP_STEP * (n - 1))
			var wins: int = 0
			for trial: int in range(TRIALS):
				seed(trial * 7919 + hash(combo_key) * 17)
				if _simulate(party, mid_boss, extra, energy_delta):
					wins += 1
			print("  [%s] %s: %d%%" % [String(scen["label"]), combo_key, int(round(100.0 * wins / TRIALS))])
	quit(0)

func _simulate(party: Array[CharacterData], enemy_template: EnemyData, extra_hp_mult: float, energy_delta: int = 0) -> bool:
	var rs: RunState = RunState.new()
	rs.init_for(party)
	var bc: BattleController = BattleController.new()
	bc.setup(rs, party[0], enemy_template.clone())
	for slot_v: Variant in (bc.state.get("enemies", []) as Array):
		var slot: Dictionary = slot_v as Dictionary
		var scaled: int = max(1, int(round(int(slot["max_hp"]) * extra_hp_mult)))
		slot["max_hp"] = scaled
		slot["hp"] = scaled
	bc._sync_active_enemy_to_state()
	if party.size() > 1 and energy_delta != 0:
		bc.state["per_turn_energy"] = max(BattleController.BASE_TURN_ENERGY, int(bc.state["per_turn_energy"]) + energy_delta)
	for _turn: int in range(10):
		bc.start_turn()
		if bc.is_battle_over():
			break
		var players: Array = bc.state.get("players", []) as Array
		var active_idx: int = int(bc.state.get("active_player_index", 0))
		if active_idx < players.size():
			var a: Dictionary = players[active_idx] as Dictionary
			var frac: float = float(int(a["hp"])) / max(1.0, float(int(a["max_hp"])))
			if frac < 0.3:
				var best: int = -1
				var best_frac: float = frac
				for i: int in range(players.size()):
					if i == active_idx:
						continue
					var s: Dictionary = players[i] as Dictionary
					if int(s["hp"]) <= 0:
						continue
					var f: float = float(int(s["hp"])) / max(1.0, float(int(s["max_hp"])))
					if f > best_frac:
						best_frac = f
						best = i
				if best >= 0:
					bc.switch_active(best)
		for _attempt: int in range(20):
			if bc.is_battle_over():
				break
			var affordable: Array[CardData] = []
			for card: CardData in bc.deck.hand:
				if bc.effective_card_cost(card) <= int(bc.state["energy"]):
					affordable.append(card)
			if affordable.is_empty():
				break
			if not bool(bc.play_card(affordable[randi() % affordable.size()]).get("affordable", false)):
				break
		if bc.is_battle_over():
			break
		bc.resolve_enemy_phase(bc.begin_enemy_phase())
	return bc.is_victory()
