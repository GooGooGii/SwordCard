extends SceneTree

# ════════════════════════════════════════════════════════════════════════
# Full-run AI playtest simulator（診斷用，不在 CI、不 assert）
#
#   godot --headless --path . -s scripts/run_simulator.gd
#
# 目的：用「會玩的啟發式 AI」跑完整一趟 run（地圖選路→戰鬥→獎勵抽卡→
#       事件→商店→休息→遺物），跨多趟統計，揭露隨機 AI / 單場測試看不到的：
#   1. 怪物在「聰明出牌」下到底有多弱（vs 既有 random AI baseline）
#   2. run 的滾雪球複利（HP 帶傷續戰 + 牌組成長 + 遺物疊加）
#
# 報告分兩部分：
#   Part A — Smart-AI 單場（滿血）：每個敵人/boss 的勝率、平均回合、平均掉血%
#            並列出 random baseline 對照，直接回答「怪太弱嗎」。
#   Part B — 全 run（帶傷續戰 + 成長）：每角色清關率、平均到達層數、結算 HP%。
#
# 刻意簡化（報告會標注）：
#   - 地圖選路：每列用啟發式挑 1 個節點（缺血優先 rest、其餘 battle/event/shop）
#   - 事件：用 EventRunner 走訪，挑 EV 最佳且非自殺的選項；只結算常見 effect kinds
#   - 商店：買得起就買最高分卡/遺物，必要時移一張基礎牌
#   - 不模擬藥水主動使用（保守，等於低估玩家強度）
# ════════════════════════════════════════════════════════════════════════

const RUNS_PER_CHAR: int = 40          # Part B：每角色跑幾趟完整 run
const BATTLE_TRIALS: int = 40          # Part A：每個敵人單場試幾次
const MAX_TURNS_NORMAL: int = 30
const MAX_TURNS_BOSS: int = 30

func _initialize() -> void:
	var characters: Array[CharacterData] = GameData.characters()
	print("# SwordCard 全 run AI 平衡報告")
	print("")
	print("> Smart-AI 啟發式出牌；Part A 滿血單場、Part B 帶傷續戰+成長。")
	print("> RUNS_PER_CHAR=%d, BATTLE_TRIALS=%d" % [RUNS_PER_CHAR, BATTLE_TRIALS])
	print("")
	_report_single_battle(characters)
	_report_full_runs(characters)
	quit(0)

# ─────────────────────────────────────────────────────────────────────────
# Part A — Smart-AI 單場（滿血）
# ─────────────────────────────────────────────────────────────────────────
func _report_single_battle(characters: Array[CharacterData]) -> void:
	print("## Part A — Smart-AI 單場勝率（滿血，起始牌組）")
	print("")
	print("格式：勝率%% · 平均回合 · 平均掉血%%（random baseline 勝率%%）")
	print("")
	# 收集 act 1–5 一般敵人代表 + boss
	var targets: Array[Dictionary] = []
	for act: int in range(1, 6):
		for e: EnemyData in GameData.enemies_for_act(act):
			targets.append({"enemy": e, "act": act, "boss": false})
		targets.append({"enemy": GameData.boss_for_act(act), "act": act, "boss": true})
	var header: String = "| 敵人 (HP) |"
	var sep: String = "|---|"
	for c: CharacterData in characters:
		header += " %s |" % c.display_name
		sep += "---|"
	print(header)
	print(sep)
	for t: Dictionary in targets:
		var enemy: EnemyData = t["enemy"] as EnemyData
		var tag: String = "★" if bool(t["boss"]) else ""
		var row: String = "| %s%s (%d) |" % [tag, enemy.display_name, enemy.max_hp]
		for c: CharacterData in characters:
			var smart: Dictionary = _battle_stats(c, enemy, true)
			var rnd: Dictionary = _battle_stats(c, enemy, false)
			var flag: String = ""
			if int(smart["win"]) >= 95 and not bool(t["boss"]):
				flag = " ⚠弱"
			row += " %d%%·%.0ft·%d%% (%d%%)%s |" % [
				int(smart["win"]), float(smart["turns"]), int(smart["hp_lost"]),
				int(rnd["win"]), flag]
		print(row)
	print("")

func _battle_stats(character: CharacterData, enemy_template: EnemyData, smart: bool) -> Dictionary:
	var wins: int = 0
	var turn_sum: float = 0.0
	var hp_lost_sum: float = 0.0
	for trial: int in range(BATTLE_TRIALS):
		seed(trial * 7919 + hash(character.id) * 17 + hash(enemy_template.id) * 31 + (5 if smart else 0))
		var rs: RunState = RunState.new()
		rs.init_for(character)
		var bc: BattleController = BattleController.new()
		bc.setup(rs, character, enemy_template.clone())
		var max_t: int = MAX_TURNS_BOSS if Ascension.is_boss_id(enemy_template.id) else MAX_TURNS_NORMAL
		var res: Dictionary = _run_battle(bc, max_t, smart)
		if bool(res["victory"]):
			wins += 1
			turn_sum += float(res["turns"])
			hp_lost_sum += float(res["hp_lost_pct"])
	var win_rate: int = int(round(100.0 * float(wins) / float(BATTLE_TRIALS)))
	return {
		"win": win_rate,
		"turns": (turn_sum / float(wins)) if wins > 0 else 0.0,
		"hp_lost": int(round(hp_lost_sum / float(max(1, wins)))),
	}

# ─────────────────────────────────────────────────────────────────────────
# Part B — 全 run（帶傷續戰 + 成長）
# ─────────────────────────────────────────────────────────────────────────
func _report_full_runs(characters: Array[CharacterData]) -> void:
	print("## Part B — Smart-AI 全 run（帶傷續戰、牌組成長、遺物/事件/商店）")
	print("")
	print("| 角色 | 清關率(過act5 boss) | 平均到達層 | 平均結算HP%% | 死因分布 |")
	print("|---|---|---|---|---|")
	for c: CharacterData in characters:
		var clears: int = 0
		var floor_sum: int = 0
		var hp_sum: float = 0.0
		var death_by: Dictionary = {}  # enemy_id → count
		for run_i: int in range(RUNS_PER_CHAR):
			seed(run_i * 104729 + hash(c.id) * 13)
			var res: Dictionary = _simulate_full_run(c)
			if bool(res["cleared"]):
				clears += 1
			floor_sum += int(res["floors"])
			hp_sum += float(res["final_hp_pct"])
			var dk: String = String(res.get("death_to", ""))
			if not dk.is_empty():
				death_by[dk] = int(death_by.get(dk, 0)) + 1
		var clear_rate: int = int(round(100.0 * float(clears) / float(RUNS_PER_CHAR)))
		var avg_floor: float = float(floor_sum) / float(RUNS_PER_CHAR)
		var avg_hp: int = int(round(hp_sum / float(RUNS_PER_CHAR)))
		# 死因 top-2
		var death_keys: Array = death_by.keys()
		death_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(death_by[a]) > int(death_by[b]))
		var death_str: String = ""
		for i: int in range(min(2, death_keys.size())):
			death_str += "%s×%d " % [String(death_keys[i]), int(death_by[death_keys[i]])]
		if death_str.is_empty():
			death_str = "—"
		print("| %s | %d%% | %.1f | %d%% | %s |" % [c.display_name, clear_rate, avg_floor, avg_hp, death_str])
	print("")
	print("> ⚠弱 = 滿血單場 smart-AI 勝率 ≥95%%（一般怪）；清關率偏高代表整體偏易。")

func _simulate_full_run(leader: CharacterData) -> Dictionary:
	var rs: RunState = RunState.new()
	rs.init_for(leader)
	var floors: int = 0
	var death_to: String = ""
	for act: int in range(1, 6):
		rs.act = act
		rs.encounter_index = 0
		var enc: Array[Array] = _gen_map(rs)
		for row: Array in enc:
			if (row as Array).is_empty():
				continue
			var node: Dictionary = _pick_node(row as Array, rs)
			var node_type: String = String(node.get("type", "battle"))
			floors += 1
			if node_type == "battle" or node_type == "boss":
				var enemies: Array[EnemyData] = _node_enemies(node)
				var bc: BattleController = BattleController.new()
				bc.setup(rs, leader, enemies)
				var res: Dictionary = _run_battle(bc, MAX_TURNS_BOSS, true)
				_sync_hp_back(bc, rs)
				if not bool(res["victory"]):
					death_to = enemies[0].id if not enemies.is_empty() else "?"
					return {"cleared": false, "floors": floors, "final_hp_pct": _hp_pct(rs), "death_to": death_to}
				_post_battle_rewards(rs, enemies, node_type == "boss")
			elif node_type == "event":
				_resolve_event_node(rs, String(node.get("event_variant", "")))
			elif node_type == "shop":
				_resolve_shop(rs)
			elif node_type == "rest":
				_resolve_rest(rs)
			rs.encounter_index += 1
	return {"cleared": true, "floors": floors, "final_hp_pct": _hp_pct(rs), "death_to": ""}

# ─────────────────────────────────────────────────────────────────────────
# 戰鬥核心：smart 或 random 出牌
# ─────────────────────────────────────────────────────────────────────────
func _run_battle(bc: BattleController, max_turns: int, smart: bool) -> Dictionary:
	var start_hp: int = _party_hp(bc.run_state)
	var start_max: int = _party_max_hp(bc.run_state)
	var turns: int = 0
	for _turn: int in range(max_turns):
		turns += 1
		bc.start_turn()
		if bc.is_battle_over():
			break
		if smart:
			_smart_turn(bc)
		else:
			_random_turn(bc)
		if bc.is_battle_over():
			break
		var actions: Array = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(actions)
		if bc.is_battle_over():
			break
	var victory: bool = bc.is_victory()
	var end_hp: int = _party_hp_state(bc)
	var hp_lost_pct: float = 0.0
	if start_max > 0:
		hp_lost_pct = clamp(100.0 * float(start_hp - end_hp) / float(start_max), 0.0, 100.0)
	return {"victory": victory, "turns": turns, "hp_lost_pct": hp_lost_pct}

func _random_turn(bc: BattleController) -> void:
	for _attempt: int in range(30):
		if bc.is_battle_over():
			return
		var affordable: Array[CardData] = []
		for card: CardData in bc.deck.hand:
			if bc.effective_card_cost(card) <= int(bc.state["energy"]):
				affordable.append(card)
		if affordable.is_empty():
			return
		var chosen: CardData = affordable[randi() % affordable.size()]
		var played: Dictionary = bc.play_card(chosen)
		if not bool(played.get("affordable", false)):
			return

func _smart_turn(bc: BattleController) -> void:
	for _attempt: int in range(40):
		if bc.is_battle_over():
			return
		# 多敵：先把 active 敵切到最佳單體目標（最低 HP 可擊殺者優先）
		_focus_best_enemy(bc)
		var best_card: CardData = null
		var best_score: float = 0.01
		for card: CardData in bc.deck.hand:
			if bc.effective_card_cost(card) > int(bc.state["energy"]):
				continue
			var s: float = _score_card(card, bc)
			if s > best_score:
				best_score = s
				best_card = card
		if best_card == null:
			return  # 沒有正分牌可打 → 結束回合
		var played: Dictionary = bc.play_card(best_card)
		if not bool(played.get("affordable", false)):
			return

# 把 active 敵切到「能一擊打死的最低 HP 敵」，否則切到最低 HP 敵（集火）
func _focus_best_enemy(bc: BattleController) -> void:
	var enemies: Array = bc.state.get("enemies", []) as Array
	if enemies.size() <= 1:
		return
	var best_idx: int = int(bc.state.get("active_enemy_index", 0))
	var best_hp: int = 1 << 30
	for i: int in range(enemies.size()):
		var slot: Dictionary = enemies[i] as Dictionary
		var hp: int = int(slot.get("hp", 0))
		if hp <= 0:
			continue
		if hp < best_hp:
			best_hp = hp
			best_idx = i
	bc.set_active_enemy(best_idx)

# 卡片啟發式評分（越高越想打）。粗略反映「會玩的人」的優先序。
func _score_card(card: CardData, bc: BattleController) -> float:
	var st: Dictionary = bc.state
	var enemy_hp: int = int(st.get("enemy_hp", 0))
	var enemy_block: int = int(st.get("enemy_block", 0))
	var enemy_vuln: int = int(st.get("enemy_vulnerable", 0))
	var player_hp: int = int(st.get("player_hp", 0))
	var player_max: int = int(st.get("player_max_hp", 1))
	var player_block: int = int(st.get("player_block", 0))
	var alive_enemies: int = _alive_enemy_count(bc)
	var incoming: int = _predicted_incoming(bc)
	var score: float = 0.0
	for eff: Dictionary in card.effects:
		var kind: String = String(eff.get("kind", ""))
		var amount: int = int(eff.get("amount", 0))
		var hits: int = max(1, int(eff.get("hits", 1)))
		match kind:
			"damage":
				var dmg: float = _effective_damage(amount, st) * hits
				score += dmg
				if dmg >= float(enemy_hp + enemy_block):
					score += 1000.0  # 致命一擊，最高優先
			"damage_all":
				var per: float = _effective_damage(amount, st) * hits
				score += per * float(max(1, alive_enemies)) * 0.9
			"block":
				# 只有在敵人威脅 > 現有 block 時才有價值；過量 block 低分
				var need: int = max(0, incoming - player_block)
				score += float(min(amount, need)) * 1.2
				if incoming > player_hp:
					score += 60.0  # 會被打死 → 格擋變超高優先
			"vulnerable":
				score += float(amount) * 6.0 if enemy_vuln == 0 else float(amount) * 2.0
			"weak":
				score += float(amount) * 5.0
			"poison", "poison_all":
				score += float(amount) * float(hits) * 3.0
			"heal":
				var deficit: int = player_max - player_hp
				score += float(min(amount, deficit)) * 1.0
			"power":
				score += 14.0  # 能力牌：盡早鋪
			"draw":
				score += float(amount) * 4.0
			"energy":
				score += float(amount) * 6.0
			"thorns":
				score += float(amount) * 3.0
			_:
				score += float(amount) * 0.5
	# 能量效率：高 cost 但低分的牌略降
	return score

func _effective_damage(base: int, st: Dictionary) -> float:
	var dmg: float = float(base + int(st.get("player_power", 0)) - int(st.get("player_weak", 0)))
	dmg += float(st.get("damage_out_bonus", 0))
	if int(st.get("enemy_vulnerable", 0)) > 0:
		dmg *= 1.5
	return max(0.0, dmg)

func _predicted_incoming(bc: BattleController) -> int:
	# 粗估這回合敵人會打多少（看每個活敵的 intent）
	var total: int = 0
	var enemies: Array = bc.state.get("enemies", []) as Array
	for i: int in range(enemies.size()):
		var slot: Dictionary = enemies[i] as Dictionary
		if int(slot.get("hp", 0)) <= 0:
			continue
		var act: Dictionary = bc._action_for_enemy(i)
		for eff: Dictionary in (act.get("effects", []) as Array):
			if String(eff.get("kind", "")) == "damage":
				var raw: int = int(eff.get("amount", 0))
				raw = max(0, raw - int(slot.get("weak", 0)) * 0)  # weak 影響在 resolver；粗估略過
				total += raw
	return total

func _alive_enemy_count(bc: BattleController) -> int:
	var n: int = 0
	for slot_v: Variant in (bc.state.get("enemies", []) as Array):
		if int((slot_v as Dictionary).get("hp", 0)) > 0:
			n += 1
	return n

# ─────────────────────────────────────────────────────────────────────────
# 全 run：地圖、選路、獎勵、事件、商店、休息
# ─────────────────────────────────────────────────────────────────────────
func _gen_map(rs: RunState) -> Array[Array]:
	var act_enemies: Array[EnemyData] = GameData.enemies_for_act(rs.act)
	var act_boss: Array[EnemyData] = [GameData.boss_for_act(rs.act)]
	var char_ids: Array[String] = []
	for c: CharacterData in rs.characters:
		char_ids.append(c.id)
	return MapGenerator.generate(act_enemies, act_boss, char_ids, rs.act)

# 選路啟發式：缺血優先 rest；錢多且非滿血優先 shop；其餘優先 event > battle
func _pick_node(row: Array, rs: RunState) -> Dictionary:
	var hp_pct: float = _hp_pct(rs)
	var by_type: Dictionary = {}
	for n_v: Variant in row:
		var n: Dictionary = n_v as Dictionary
		by_type[String(n.get("type", "battle"))] = n
	if by_type.has("boss"):
		return by_type["boss"]
	if hp_pct < 55.0 and by_type.has("rest"):
		return by_type["rest"]
	if rs.gold >= 150 and by_type.has("shop"):
		return by_type["shop"]
	if by_type.has("event"):
		return by_type["event"]
	if by_type.has("rest") and hp_pct < 80.0:
		return by_type["rest"]
	# 預設挑第一個
	return row[0] as Dictionary

func _node_enemies(node: Dictionary) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	if node.has("enemies"):
		for e_v: Variant in (node["enemies"] as Array):
			if e_v is EnemyData:
				out.append(e_v as EnemyData)
	elif node.has("enemy") and node["enemy"] is EnemyData:
		out.append(node["enemy"] as EnemyData)
	return out

func _post_battle_rewards(rs: RunState, enemies: Array[EnemyData], is_boss: bool) -> void:
	# gold
	var gold: int = 0
	for e: EnemyData in enemies:
		if not e.is_summoned:
			gold += _gold_for(rs, e, is_boss)
	rs.gold += gold
	# exp / level
	_grant_exp(rs, is_boss)
	# 卡片獎勵抽取（boss 偏稀有）
	_draft_card(rs, is_boss)
	# 遺物：boss 必得 1、一般 25%
	if is_boss:
		_grant_relic(rs, true)
	elif randf() < 0.25:
		_grant_relic(rs, false)

func _gold_for(rs: RunState, enemy: EnemyData, is_boss: bool) -> int:
	var base: int = 0
	if is_boss:
		match rs.act:
			1: base = 80
			2: base = 120
			3: base = 160
			4: base = 200
			_: base = 250
	else:
		base = 18 + rs.act * 8 + rs.encounter_index * 3
	return max(0, int(round(float(base) * Ascension.gold_multiplier(rs.ascension_level))))

func _grant_exp(rs: RunState, is_boss: bool) -> void:
	var exp_gain: int = LevelSystem.battle_exp(is_boss, rs.encounter_index)
	for i: int in range(rs.characters.size()):
		if rs.character_hps[i] <= 0:
			continue
		rs.character_exps[i] += exp_gain
		var old_lv: int = rs.character_levels[i]
		var new_lv: int = LevelSystem.level_from_exp(rs.character_exps[i])
		if new_lv <= old_lv:
			continue
		rs.character_levels[i] = new_lv
		for lv: int in range(old_lv + 1, new_lv + 1):
			for card: CardData in LevelSystem.unlock_cards_for(rs.characters[i].id, lv):
				(rs.character_decks[i] as Array).append(card.clone())

func _draft_card(rs: RunState, boss: bool) -> void:
	var pool: Array[CardData] = []
	var seen: Array[String] = []
	for card: CardData in rs.characters[0].reward_pool:
		if not seen.has(card.id):
			seen.append(card.id)
			pool.append(card.clone())
	if pool.is_empty():
		return
	pool.shuffle()
	# boss：偏稀有排序
	if boss:
		pool.sort_custom(func(a: CardData, b: CardData) -> bool:
			return _rarity_rank(a.rarity) > _rarity_rank(b.rarity))
	var choices: Array[CardData] = []
	for i: int in range(min(3, pool.size())):
		choices.append(pool[i])
	# 挑最高分卡（用一個粗略 deck-value：傷害/格擋/能力權重）
	var best: CardData = null
	var best_v: float = 0.0
	for c: CardData in choices:
		var v: float = _card_draft_value(c)
		if v > best_v:
			best_v = v
			best = c
	# 牌組過大且都低分 → 跳過（控牌）
	var deck_size: int = (rs.character_decks[0] as Array).size()
	if best != null and (best_v >= 8.0 or deck_size < 14):
		(rs.character_decks[0] as Array).append(best.clone())

func _card_draft_value(card: CardData) -> float:
	var v: float = 0.0
	for eff: Dictionary in card.effects:
		var k: String = String(eff.get("kind", ""))
		var amt: float = float(int(eff.get("amount", 0))) * float(max(1, int(eff.get("hits", 1))))
		match k:
			"damage", "damage_all": v += amt
			"block": v += amt * 0.8
			"vulnerable", "weak": v += amt * 4.0
			"poison", "poison_all": v += amt * 2.5
			"power": v += 12.0
			"draw", "energy": v += amt * 5.0
			_: v += amt * 0.6
	v += _rarity_rank(card.rarity) * 2.0
	return v

func _rarity_rank(r: String) -> int:
	match r:
		"rare": return 3
		"uncommon": return 2
		"common": return 1
		_: return 0

func _grant_relic(rs: RunState, boss: bool) -> void:
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not rs.has_relic(r.id):
			pool.append(r)
	if boss:
		for a: RelicData in RelicCatalog.artifacts():
			if not rs.has_relic(a.id):
				pool.append(a)
	if pool.is_empty():
		return
	rs.add_relic(pool[randi() % pool.size()].clone())

func _resolve_event_node(rs: RunState, variant: String) -> void:
	var ed: Dictionary = EventData.for_variant(variant)
	if not EventRunner.has_tree(ed):
		# legacy：保守取一個療傷/增益（用 heal 欄位）
		var heal: int = int(ed.get("heal", 0))
		_heal_party(rs, heal)
		return
	# tree：從 root 走，挑「EV 最佳且非自殺」的葉節點（不消耗 observe、不選 punish/battle）
	var ctx: Dictionary = EventRunner.build_context(
		rs.characters[0].id, rs.gold, rs.character_power_bonus[0], 0, _relic_ids(rs),
		(rs.character_decks[0] as Array).size())
	var node: Dictionary = EventRunner.get_node(ed, EventRunner.ROOT_ID)
	var hops: int = 0
	while hops < 4:
		hops += 1
		var visible: Array = EventRunner.visible_choices(node, ctx)
		if visible.is_empty():
			return
		# 偏好：有 outcome 的 reward 葉節點；否則跟著 next 往下
		var chosen: Dictionary = {}
		var best_v: float = -1e9
		for ch_v: Variant in visible:
			var ch: Dictionary = ch_v as Dictionary
			var kind: String = EventRunner.leaf_kind(ch)
			var v: float = _event_choice_value(ch, kind)
			if v > best_v:
				best_v = v
				chosen = ch
		if chosen.is_empty():
			return
		if EventRunner.is_leaf(chosen):
			_apply_event_effects(rs, (chosen["outcome"] as Dictionary).get("effects", []) as Array)
			return
		if chosen.has("next"):
			node = EventRunner.get_node(ed, String(chosen["next"]))
		else:
			return

func _event_choice_value(choice: Dictionary, kind: String) -> float:
	# 啟發式：reward 高、neutral 0、mixed 中、gamble 中低、punish/battle 避免
	match kind:
		"reward": return 100.0
		"mixed": return 30.0
		"gamble": return 15.0
		"neutral": return 5.0
		"battle": return -50.0
		"punish": return -100.0
		_: return 0.0

func _apply_event_effects(rs: RunState, effects: Array) -> void:
	for e_v: Variant in effects:
		var e: Dictionary = e_v as Dictionary
		var k: String = String(e.get("kind", ""))
		var amt: int = int(e.get("amount", 0))
		match k:
			"heal": _heal_party(rs, amt)
			"heal_party": _heal_party(rs, amt)
			"max_hp":
				for i: int in range(rs.character_max_hps.size()):
					rs.character_max_hps[i] = max(1, rs.character_max_hps[i] + amt)
					if amt > 0:
						rs.character_hps[i] += amt
					rs.character_hps[i] = min(rs.character_hps[i], rs.character_max_hps[i])
			"gold": rs.gold = max(0, rs.gold + amt)
			"power", "permanent_power":
				for i: int in range(rs.character_power_bonus.size()):
					rs.character_power_bonus[i] += amt
			"damage": _heal_party(rs, -amt)
			"gain_relic_pool": _grant_relic(rs, false)
			"gain_card_pool": _draft_card(rs, false)
			# gain_curse / lose_card / next_battle_buff：簡化略過

func _resolve_shop(rs: RunState) -> void:
	# 買得起的最高分卡（從主角商店池）+ 偶爾移一張基礎牌
	var inv: Array[Dictionary] = ShopInventory.build(rs.characters[0], false)
	# 依分數高到低買，直到錢不夠或買 2 張
	var bought: int = 0
	inv.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _card_draft_value(a["card"] as CardData) > _card_draft_value(b["card"] as CardData))
	for entry: Dictionary in inv:
		if bought >= 2:
			break
		var card: CardData = entry["card"] as CardData
		var price: int = int(entry.get("price", ShopInventory.price_of(card, false)))
		if rs.gold >= price and _card_draft_value(card) >= 8.0:
			rs.gold -= price
			(rs.character_decks[0] as Array).append(card.clone())
			bought += 1
	# 移基礎牌（去蕪存菁）：錢還夠且牌組大
	if rs.gold >= 75 and (rs.character_decks[0] as Array).size() > 10:
		var deck: Array = rs.character_decks[0] as Array
		for i: int in range(deck.size()):
			var c: CardData = deck[i] as CardData
			if c.rarity == "basic" and c.card_type == "attack":
				deck.remove_at(i)
				rs.gold -= 75
				break

func _resolve_rest(rs: RunState) -> void:
	# 缺血 → 回 30% max；否則升級一張未升級牌
	if _hp_pct(rs) < 65.0:
		for i: int in range(rs.character_hps.size()):
			if rs.character_hps[i] <= 0:
				continue
			var heal: int = int(round(float(rs.character_max_hps[i]) * 0.3))
			rs.character_hps[i] = min(rs.character_max_hps[i], rs.character_hps[i] + heal)
	else:
		var deck: Array = rs.character_decks[0] as Array
		for i: int in range(deck.size()):
			var c: CardData = deck[i] as CardData
			if not c.upgraded:
				deck[i] = c.upgraded_copy()
				break

# ─────────────────────────────────────────────────────────────────────────
# 小工具
# ─────────────────────────────────────────────────────────────────────────
func _sync_hp_back(bc: BattleController, rs: RunState) -> void:
	var players: Array = bc.state.get("players", []) as Array
	for i: int in range(min(players.size(), rs.character_hps.size())):
		rs.character_hps[i] = max(0, int((players[i] as Dictionary).get("hp", 0)))

func _heal_party(rs: RunState, amount: int) -> void:
	for i: int in range(rs.character_hps.size()):
		if rs.character_hps[i] <= 0:
			continue
		rs.character_hps[i] = clamp(rs.character_hps[i] + amount, 0, rs.character_max_hps[i])

func _party_hp(rs: RunState) -> int:
	var s: int = 0
	for h: int in rs.character_hps:
		s += max(0, h)
	return s

func _party_max_hp(rs: RunState) -> int:
	var s: int = 0
	for h: int in rs.character_max_hps:
		s += h
	return s

func _party_hp_state(bc: BattleController) -> int:
	var s: int = 0
	for p_v: Variant in (bc.state.get("players", []) as Array):
		s += max(0, int((p_v as Dictionary).get("hp", 0)))
	return s

func _hp_pct(rs: RunState) -> float:
	var mx: int = _party_max_hp(rs)
	if mx <= 0:
		return 0.0
	return 100.0 * float(_party_hp(rs)) / float(mx)

func _relic_ids(rs: RunState) -> Array:
	var ids: Array = []
	for r: RelicData in rs.relics:
		ids.append(r.id)
	return ids
