extends SceneTree

# ════════════════════════════════════════════════════════════════════════
# 「我親自玩阿奴」—— 把人類會用的毒龜流打法寫成 pilot，headless 跑全 run。
#   godot --headless --path . -s scripts/play_anu.gd
#
# 阿奴毒龜流打法（StS Silent / Noxious Fumes 流）：
#   1. 開場立刻鋪毒引擎（蠱瘴瀰漫）
#   2. 看敵人意圖：會被打痛就先格擋 / 上虛弱（龜）
#   3. 其餘手牌全拿去疊毒（萬蟻 > 三屍 > 百足 > 毒針 > 毒霧 > 御蜂）
#   4. 爆炸蠱「留著」—— 毒疊到 ≥10 層或能一擊致命才引爆
#   5. 多敵：集火最低血、毒引擎本身是 poison_all
#
# 印出第 1 趟的逐回合 log（看打法），再跑 N 趟給可信清關率。
# ════════════════════════════════════════════════════════════════════════

const RUNS: int = 30
const MAX_TURNS: int = 30
const VERBOSE_RUN: int = 0  # 第幾趟印詳細 log

var _log_this_run: bool = false

func _initialize() -> void:
	var anu: CharacterData = null
	for c: CharacterData in GameData.characters():
		if c.id == "anu":
			anu = c
			break
	if anu == null:
		print("找不到阿奴")
		quit(1)
		return
	print("# 阿奴毒龜流 pilot — 親自操刀全 run")
	print("")
	var clears: int = 0
	var floor_sum: int = 0
	var death_by: Dictionary = {}
	for run_i: int in range(RUNS):
		seed(run_i * 2237 + 91)
		_log_this_run = (run_i == VERBOSE_RUN)
		if _log_this_run:
			print("## 詳細 log（第 %d 趟）" % (run_i + 1))
			print("")
		var res: Dictionary = _play_run(anu)
		if bool(res["cleared"]):
			clears += 1
		floor_sum += int(res["floors"])
		var dk: String = String(res.get("death_to", ""))
		if not dk.is_empty():
			death_by[dk] = int(death_by.get(dk, 0)) + 1
		if _log_this_run:
			print("")
			var verdict: String = "★ 通關！" if bool(res["cleared"]) else ("✗ 倒在第 %d 層（%s）" % [int(res["floors"]), String(res.get("death_to", "?"))])
			print("→ %s 最終 HP %d%%" % [verdict, int(res["final_hp_pct"])])
			print("")
	print("## 30 趟總結")
	print("")
	print("- 清關率：**%d%%**（%d / %d）" % [int(round(100.0 * float(clears) / float(RUNS))), clears, RUNS])
	print("- 平均到達層：%.1f" % (float(floor_sum) / float(RUNS)))
	var death_keys: Array = death_by.keys()
	death_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return int(death_by[a]) > int(death_by[b]))
	var ds: String = ""
	for i: int in range(min(3, death_keys.size())):
		ds += "%s×%d  " % [String(death_keys[i]), int(death_by[death_keys[i]])]
	print("- 主要死因：%s" % (ds if not ds.is_empty() else "—（全通關）"))
	quit(0)

# ─────────────────────────────────────────────────────────────────────────
func _play_run(anu: CharacterData) -> Dictionary:
	var rs: RunState = RunState.new()
	rs.init_for(anu)
	var floors: int = 0
	for act: int in range(1, 6):
		rs.act = act
		rs.encounter_index = 0
		var enc: Array[Array] = _gen_map(rs)
		for row: Array in enc:
			if (row as Array).is_empty():
				continue
			var node: Dictionary = _pick_node(row as Array, rs)
			var ntype: String = String(node.get("type", "battle"))
			floors += 1
			if ntype == "battle" or ntype == "boss":
				var enemies: Array[EnemyData] = _node_enemies(node)
				var bc: BattleController = BattleController.new()
				bc.setup(rs, anu, enemies)
				if _log_this_run:
					var names: Array[String] = []
					for e: EnemyData in enemies:
						names.append("%s(HP%d)" % [e.display_name, e.max_hp])
					print("### 第 %d 層 %s：%s" % [floors, "BOSS" if ntype == "boss" else "戰鬥", "、".join(names)])
				var won: bool = _fight(bc)
				_sync_hp_back(bc, rs)
				if not won:
					return {"cleared": false, "floors": floors, "final_hp_pct": _hp_pct(rs), "death_to": (enemies[0].id if not enemies.is_empty() else "?")}
				_rewards(rs, enemies, ntype == "boss")
				if _log_this_run:
					print("   ✓ 勝。HP %d/%d，銅錢 %d，牌組 %d 張" % [rs.character_hps[0], rs.character_max_hps[0], rs.gold, (rs.character_decks[0] as Array).size()])
			elif ntype == "event":
				_heal_party(rs, int(EventData.for_variant(String(node.get("event_variant",""))).get("heal", 0)))
			elif ntype == "rest":
				_rest(rs)
				if _log_this_run:
					print("### 第 %d 層 休息 → HP %d/%d" % [floors, rs.character_hps[0], rs.character_max_hps[0]])
			elif ntype == "shop":
				_shop(rs)
			rs.encounter_index += 1
	return {"cleared": true, "floors": floors, "final_hp_pct": _hp_pct(rs), "death_to": ""}

# ─────────────────────────────────────────────────────────────────────────
# 戰鬥：毒龜流 pilot
func _fight(bc: BattleController) -> bool:
	for _t: int in range(MAX_TURNS):
		bc.start_turn()
		if bc.is_battle_over():
			break
		if _log_this_run:
			print("   ── 第 %d 回合（HP %d，能量 %d）──" % [int(bc.state["turn"]), int(bc.state["player_hp"]), int(bc.state["energy"])])
		for _step: int in range(40):
			if bc.is_battle_over():
				break
			_focus_lowest(bc)
			var card: CardData = _pick(bc)
			if card == null:
				break
			var pre_hp: int = int(bc.state["enemy_hp"])
			var played: Dictionary = bc.play_card(card)
			if not bool(played.get("affordable", false)):
				break
			if _log_this_run:
				print("      打出「%s」%s" % [card.display_name, _card_note(card, bc, pre_hp)])
		if bc.is_battle_over():
			break
		var actions: Array = bc.begin_enemy_phase()
		bc.resolve_enemy_phase(actions)
		if bc.is_battle_over():
			break
	return bc.is_victory()

func _card_note(card: CardData, bc: BattleController, pre_enemy_hp: int) -> String:
	var post: int = int(bc.state["enemy_hp"])
	if post < pre_enemy_hp:
		return "（敵 -%d → HP %d）" % [pre_enemy_hp - post, post]
	return ""

# 毒龜流選牌：依優先序回傳要打的牌（null = 結束回合）
func _pick(bc: BattleController) -> CardData:
	var st: Dictionary = bc.state
	var energy: int = int(st["energy"])
	var enemy_hp: int = int(st["enemy_hp"])
	var enemy_block: int = int(st["enemy_block"])
	var poison: int = int(st["enemy_poison"])
	var hp: int = int(st["player_hp"])
	var block: int = int(st["player_block"])
	var incoming: int = _incoming(bc)
	var threatened: bool = (incoming - block) > int(0.35 * float(hp))

	var engine: CardData = null
	var lethal_burst: CardData = null
	var ready_burst: CardData = null
	var best_block: CardData = null
	var best_block_amt: int = 0
	var best_weak: CardData = null
	var best_poison: CardData = null
	var best_poison_amt: int = 0
	var best_dmg: CardData = null
	var best_dmg_amt: int = 0
	var heal_card: CardData = null

	for card: CardData in bc.deck.hand:
		if bc.effective_card_cost(card) > energy:
			continue
		var kinds: Dictionary = _kinds(card)
		if kinds.has("poison_engine") and int(st.get("poison_per_turn", 0)) == 0:
			engine = card
		if kinds.has("poison_burst"):
			var per: int = int(kinds["poison_burst"])
			if poison * per >= enemy_hp + enemy_block:
				lethal_burst = card
			elif poison >= 10:
				ready_burst = card
		if kinds.has("block") and int(kinds["block"]) > best_block_amt:
			best_block_amt = int(kinds["block"]); best_block = card
		if kinds.has("weak") and best_weak == null:
			best_weak = card
		if (kinds.has("poison") or kinds.has("poison_all")) and int(kinds.get("poison", kinds.get("poison_all", 0))) > best_poison_amt:
			best_poison_amt = int(kinds.get("poison", kinds.get("poison_all", 0))); best_poison = card
		if (kinds.has("damage") or kinds.has("damage_all")) and int(kinds.get("damage", kinds.get("damage_all", 0))) > best_dmg_amt:
			best_dmg_amt = int(kinds.get("damage", kinds.get("damage_all", 0))); best_dmg = card
		if kinds.has("heal") and heal_card == null:
			heal_card = card

	# 1. 開場鋪毒引擎
	if engine != null:
		return engine
	# 2. 能一擊毒爆致命 → 引爆
	if lethal_burst != null:
		return lethal_burst
	# 3. 會被打痛 → 先龜（格擋 > 虛弱 > 治療）
	if threatened:
		if best_block != null:
			return best_block
		if best_weak != null:
			return best_weak
		if heal_card != null and hp < int(0.4 * float(int(st["player_max_hp"]))):
			return heal_card
	# 4. 毒疊夠了 → 引爆
	if ready_burst != null:
		return ready_burst
	# 5. 繼續疊毒
	if best_poison != null:
		return best_poison
	# 6. 補刀傷害
	if best_dmg != null:
		return best_dmg
	# 7. 還有虛弱沒上、且能省命就上
	if best_weak != null and incoming > 0:
		return best_weak
	return null

func _kinds(card: CardData) -> Dictionary:
	var d: Dictionary = {}
	for eff: Dictionary in card.effects:
		d[String(eff.get("kind", ""))] = int(eff.get("amount", 0))
	return d

func _incoming(bc: BattleController) -> int:
	var total: int = 0
	var enemies: Array = bc.state.get("enemies", []) as Array
	for i: int in range(enemies.size()):
		if int((enemies[i] as Dictionary).get("hp", 0)) <= 0:
			continue
		for eff: Dictionary in (bc._action_for_enemy(i).get("effects", []) as Array):
			if String(eff.get("kind", "")) == "damage":
				total += int(eff.get("amount", 0))
	return total

func _focus_lowest(bc: BattleController) -> void:
	var enemies: Array = bc.state.get("enemies", []) as Array
	if enemies.size() <= 1:
		return
	var idx: int = int(bc.state.get("active_enemy_index", 0))
	var lo: int = 1 << 30
	for i: int in range(enemies.size()):
		var h: int = int((enemies[i] as Dictionary).get("hp", 0))
		if h > 0 and h < lo:
			lo = h; idx = i
	bc.set_active_enemy(idx)

# ─────────────────────────────────────────────────────────────────────────
# 精簡 meta（與 run_simulator 的高手檔同等）
func _gen_map(rs: RunState) -> Array[Array]:
	var char_ids: Array[String] = []
	for c: CharacterData in rs.characters:
		char_ids.append(c.id)
	return MapGenerator.generate(GameData.enemies_for_act(rs.act), [GameData.boss_for_act(rs.act)], char_ids, rs.act)

func _pick_node(row: Array, rs: RunState) -> Dictionary:
	var by_type: Dictionary = {}
	for n_v: Variant in row:
		by_type[String((n_v as Dictionary).get("type", "battle"))] = n_v as Dictionary
	if by_type.has("boss"):
		return by_type["boss"]
	if _hp_pct(rs) < 65.0 and by_type.has("rest"):
		return by_type["rest"]
	if rs.gold >= 150 and by_type.has("shop"):
		return by_type["shop"]
	if by_type.has("event"):
		return by_type["event"]
	if by_type.has("rest") and _hp_pct(rs) < 80.0:
		return by_type["rest"]
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

func _rewards(rs: RunState, enemies: Array[EnemyData], is_boss: bool) -> void:
	var base: int = (200 if is_boss else 18 + rs.act * 8)
	rs.gold += base
	var exp_gain: int = LevelSystem.battle_exp(is_boss, rs.encounter_index)
	rs.character_exps[0] += exp_gain
	var old_lv: int = rs.character_levels[0]
	var new_lv: int = LevelSystem.level_from_exp(rs.character_exps[0])
	if new_lv > old_lv:
		rs.character_levels[0] = new_lv
		for lv: int in range(old_lv + 1, new_lv + 1):
			for card: CardData in LevelSystem.unlock_cards_for("anu", lv):
				(rs.character_decks[0] as Array).append(card.clone())
	# 抽獎勵卡：偏好毒/能力/控場
	_draft(rs, is_boss)

func _draft(rs: RunState, boss: bool) -> void:
	var pool: Array[CardData] = []
	var seen: Array[String] = []
	for card: CardData in rs.characters[0].reward_pool:
		if not seen.has(card.id):
			seen.append(card.id); pool.append(card.clone())
	if pool.is_empty():
		return
	pool.shuffle()
	var best: CardData = null
	var best_v: float = 0.0
	for c: CardData in pool.slice(0, 3):
		var v: float = _draft_value(c)
		if v > best_v:
			best_v = v; best = c
	if best != null and (best_v >= 8.0 or (rs.character_decks[0] as Array).size() < 14):
		(rs.character_decks[0] as Array).append(best.clone())

func _draft_value(card: CardData) -> float:
	var v: float = 0.0
	for eff: Dictionary in card.effects:
		var amt: float = float(int(eff.get("amount", 0)))
		match String(eff.get("kind", "")):
			"poison_engine": v += 40.0
			"poison_burst": v += 30.0
			"poison", "poison_all": v += amt * 3.0
			"weak", "vulnerable": v += amt * 4.0
			"block": v += amt * 0.8
			"damage", "damage_all": v += amt
			"power", "draw": v += 10.0
			_: v += amt * 0.5
	return v

func _rest(rs: RunState) -> void:
	if _hp_pct(rs) < 70.0:
		for i: int in range(rs.character_hps.size()):
			if rs.character_hps[i] > 0:
				rs.character_hps[i] = min(rs.character_max_hps[i], rs.character_hps[i] + int(round(float(rs.character_max_hps[i]) * 0.3)))
	else:
		var deck: Array = rs.character_decks[0] as Array
		for i: int in range(deck.size()):
			if not (deck[i] as CardData).upgraded:
				deck[i] = (deck[i] as CardData).upgraded_copy()
				break

func _shop(rs: RunState) -> void:
	var inv: Array[Dictionary] = ShopInventory.build(rs.characters[0], false)
	inv.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _draft_value(a["card"] as CardData) > _draft_value(b["card"] as CardData))
	for entry: Dictionary in inv:
		var card: CardData = entry["card"] as CardData
		var price: int = int(entry.get("price", 50))
		if rs.gold >= price and _draft_value(card) >= 8.0:
			rs.gold -= price
			(rs.character_decks[0] as Array).append(card.clone())
			break

# ─────────────────────────────────────────────────────────────────────────
func _sync_hp_back(bc: BattleController, rs: RunState) -> void:
	var players: Array = bc.state.get("players", []) as Array
	if players.size() > 0:
		rs.character_hps[0] = max(0, int((players[0] as Dictionary).get("hp", 0)))

func _heal_party(rs: RunState, amount: int) -> void:
	if amount == 0:
		return
	for i: int in range(rs.character_hps.size()):
		if rs.character_hps[i] > 0:
			rs.character_hps[i] = clamp(rs.character_hps[i] + amount, 0, rs.character_max_hps[i])

func _hp_pct(rs: RunState) -> float:
	var mx: int = 0
	var hp: int = 0
	for i: int in range(rs.character_hps.size()):
		mx += rs.character_max_hps[i]
		hp += max(0, rs.character_hps[i])
	return 0.0 if mx <= 0 else 100.0 * float(hp) / float(mx)
