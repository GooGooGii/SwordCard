class_name BattleController
extends RefCounted

const HAND_SIZE: int = 5
const BASE_TURN_ENERGY: int = 3
const BENCH_HEAL_PER_TURN: int = 2

var run_state: RunState
var enemy: EnemyData
var decks: Array[DeckManager] = []  # 每個角色一份；舊 `deck` 屬性指向 active
var resolver: EffectResolver
var state: Dictionary = {}
var action_index: int = 0
var battle_log: Array[String] = []
var phased: bool = false  # Boss HP 跌破 50% 後切換到 phase_2_actions

# 向後相容：character / deck 永遠對應到目前 active player
var character: CharacterData:
	get:
		if run_state == null or run_state.characters.is_empty():
			return null
		var idx: int = _active_index()
		if idx >= run_state.characters.size():
			return null
		return run_state.characters[idx]

var deck: DeckManager:
	get:
		var idx: int = _active_index()
		if idx >= decks.size():
			return null
		return decks[idx]
	set(_value):
		pass  # 內部管理；外部不要直接寫

func _active_index() -> int:
	return int(state.get("active_player_index", 0))

func setup(rs: RunState, _legacy_character: CharacterData, enemies_input) -> void:
	var enemies: Array[EnemyData] = []
	if enemies_input is EnemyData:
		enemies.append((enemies_input as EnemyData).clone())
	else:
		for e_v: Variant in (enemies_input as Array):
			enemies.append((e_v as EnemyData).clone())
	run_state = rs
	enemy = enemies[0] if not enemies.is_empty() else EnemyData.new()
	resolver = EffectResolver.new()
	action_index = 0
	phased = false
	battle_log.clear()
	var party_size: int = run_state.characters.size()
	var per_turn_energy: int = BASE_TURN_ENERGY + max(0, party_size - 1)
	# 每個角色獨立 DeckManager
	decks.clear()
	for i: int in range(party_size):
		var dm: DeckManager = DeckManager.new()
		dm.setup(run_state.character_decks[i] as Array[CardData])
		decks.append(dm)
	# 每個角色的 state slot
	var players: Array[Dictionary] = []
	for i: int in range(party_size):
		var c: CharacterData = run_state.characters[i]
		players.append({
			"name": c.display_name,
			"max_hp": run_state.character_max_hps[i],
			"hp": run_state.character_hps[i],
			"block": 0,
			"poison": 0,
			"weak": 0,
			"vulnerable": 0,
			"power": run_state.character_power_bonus[i],
		})
	# 敵人群組
	var group_list: Array[Dictionary] = []
	for e_item: EnemyData in enemies:
		group_list.append({
			"id": e_item.id,
			"name": e_item.display_name,
			"hp": e_item.max_hp,
			"max_hp": e_item.max_hp,
			"block": 0,
			"poison": 0,
			"weak": 0,
			"vulnerable": 0,
			"portrait_path": e_item.portrait_path,
			"portrait_tint": e_item.portrait_tint,
			"action_index": 0,
			"phased": false,
			"loot_table": GameData.loot_table_for(e_item.id),
			"actions": e_item.actions.duplicate(true),
			"phase_2_actions": e_item.phase_2_actions.duplicate(true),
		})
	state = {
		"players": players,
		"active_player_index": clamp(run_state.active_character_index, 0, max(0, party_size - 1)),
		"switched_this_turn": false,
		"per_turn_energy": per_turn_energy,
		"enemy_group": group_list,
		"targeted_enemy_index": 0,
		"enemy_name": enemy.display_name,
		"enemy_max_hp": enemy.max_hp,
		"enemy_hp": enemy.max_hp,
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"energy": per_turn_energy,
		"pending_draw": 0,
		"turn": 0,
		"li_discount_used": false,
		"lin_block_used": false,
		"damage_taken_reduction": 0,
		"damage_out_bonus": 0,
		"block_bonus": 0,
		"heal_bonus": 0,
		"poison_bonus": 0,
		"draw_next_turn_bonus": 0,
		"card_played_counts": {}
	}
	# 若 active 死了（舊存檔載入後可能發生），自動跳到第一個活的
	if not _is_active_alive():
		_force_switch_to_first_alive(false)
	_sync_active_to_state()
	_apply_relic_modifiers()
	_apply_party_battle_start_passives()
	_fire_relic_triggers("battle_start")

# 把 enemy_group[targeted_enemy_index] 的資料投影到 state["enemy_*"] 平坦別名
func _sync_target_to_aliases() -> void:
	var idx: int = int(state.get("targeted_enemy_index", 0))
	var group: Array = state.get("enemy_group", []) as Array
	if group.is_empty() or idx >= group.size():
		return
	var eg: Dictionary = group[idx] as Dictionary
	state["enemy_name"] = eg["name"]
	state["enemy_hp"] = eg["hp"]
	state["enemy_max_hp"] = eg["max_hp"]
	state["enemy_block"] = eg["block"]
	state["enemy_poison"] = eg["poison"]
	state["enemy_weak"] = eg["weak"]
	state["enemy_vulnerable"] = eg["vulnerable"]
	state["enemy_loot_table"] = eg.get("loot_table", [])

# 把 state["enemy_*"] 平坦別名的結果寫回 enemy_group[targeted_enemy_index]
func _sync_aliases_to_target() -> void:
	var idx: int = int(state.get("targeted_enemy_index", 0))
	var group: Array = state.get("enemy_group", []) as Array
	if group.is_empty() or idx >= group.size():
		return
	var eg: Dictionary = group[idx] as Dictionary
	eg["hp"] = int(state.get("enemy_hp", 0))
	eg["max_hp"] = int(state.get("enemy_max_hp", 0))
	eg["block"] = int(state.get("enemy_block", 0))
	eg["poison"] = int(state.get("enemy_poison", 0))
	eg["weak"] = int(state.get("enemy_weak", 0))
	eg["vulnerable"] = int(state.get("enemy_vulnerable", 0))

# 設定目標敵人並同步別名（供 main.gd 點選切換目標）
func set_targeted_enemy(idx: int) -> void:
	var group: Array = state.get("enemy_group", []) as Array
	if idx < 0 or idx >= group.size():
		return
	if int((group[idx] as Dictionary)["hp"]) <= 0:
		return
	_sync_aliases_to_target()
	state["targeted_enemy_index"] = idx
	_sync_target_to_aliases()

# 把 active player slot 的欄位投影到 state["player_*"]，
# 讓 EffectResolver 的舊 key 路徑繼續適用
func _sync_active_to_state() -> void:
	var idx: int = _active_index()
	var players: Array = state.get("players", []) as Array
	if idx >= players.size():
		return
	var p: Dictionary = players[idx] as Dictionary
	state["player_name"] = p["name"]
	state["player_max_hp"] = p["max_hp"]
	state["player_hp"] = p["hp"]
	state["player_block"] = p["block"]
	state["player_poison"] = p["poison"]
	state["player_weak"] = p["weak"]
	state["player_vulnerable"] = p["vulnerable"]
	state["player_power"] = p["power"]

# 把 state["player_*"] 寫回 active player slot
func _sync_state_to_active() -> void:
	var idx: int = _active_index()
	var players: Array = state.get("players", []) as Array
	if idx >= players.size():
		return
	var p: Dictionary = players[idx] as Dictionary
	p["max_hp"] = int(state.get("player_max_hp", p["max_hp"]))
	p["hp"] = int(state.get("player_hp", p["hp"]))
	p["block"] = int(state.get("player_block", 0))
	p["poison"] = int(state.get("player_poison", 0))
	p["weak"] = int(state.get("player_weak", 0))
	p["vulnerable"] = int(state.get("player_vulnerable", 0))
	p["power"] = int(state.get("player_power", 0))

func _is_active_alive() -> bool:
	var idx: int = _active_index()
	var players: Array = state.get("players", []) as Array
	if idx >= players.size():
		return false
	return int((players[idx] as Dictionary)["hp"]) > 0

# 強制換到第一個活著的（active 戰死、battle_start 時 active 已死等）
# free=true 不收 energy
func _force_switch_to_first_alive(announce: bool = true) -> bool:
	var players: Array = state.get("players", []) as Array
	for i: int in range(players.size()):
		if i == _active_index():
			continue
		if int((players[i] as Dictionary)["hp"]) > 0:
			# 不要從 state 寫回（active 已經死，不再代表 player_* 為他的狀態）
			# 但要清掉舊 active 的 block / poison etc. 應該留在他自己的 slot
			_sync_state_to_active()
			state["active_player_index"] = i
			_sync_active_to_state()
			if i < decks.size():
				decks[i].draw(HAND_SIZE)
			if announce:
				add_log("%s 倒下，%s 上場！" % [String((players[_previous_active_index()] as Dictionary)["name"]) if false else "前一名角色", state["player_name"]])
				# 簡化 log：只說新人上場
				battle_log[-1] = "%s 上場接戰！" % state["player_name"]
			return true
	return false

# 沒被使用 (helper)
func _previous_active_index() -> int:
	return _active_index()

# 玩家主動切人
# 回傳 {changed: bool, free: bool, reason: String}
func switch_active(new_index: int) -> Dictionary:
	var current: int = _active_index()
	if new_index == current:
		return {"changed": false, "reason": "same"}
	var players: Array = state.get("players", []) as Array
	if new_index < 0 or new_index >= players.size():
		return {"changed": false, "reason": "invalid_index"}
	if int((players[new_index] as Dictionary)["hp"]) <= 0:
		return {"changed": false, "reason": "dead"}
	var was_free: bool = not bool(state.get("switched_this_turn", false))
	var cost: int = 0 if was_free else 1
	if int(state["energy"]) < cost:
		return {"changed": false, "reason": "no_energy"}
	state["energy"] = int(state["energy"]) - cost
	# 寫回當前 active 並棄手牌
	_sync_state_to_active()
	if current < decks.size():
		decks[current].discard_hand()
	state["active_player_index"] = new_index
	_sync_active_to_state()
	if new_index < decks.size():
		decks[new_index].draw(HAND_SIZE)
	state["switched_this_turn"] = true
	var cost_label: String = "" if was_free else "（耗 1 靈力）"
	add_log("換 %s 上場%s" % [String(state["player_name"]), cost_label])
	return {"changed": true, "free": was_free}

func add_log(line: String) -> void:
	battle_log.append(line)

func add_logs(lines: Array[String]) -> void:
	battle_log.append_array(lines)

func snapshot_state() -> Dictionary:
	return {
		"player_hp": int(state["player_hp"]),
		"player_block": int(state["player_block"]),
		"player_poison": int(state["player_poison"]),
		"player_weak": int(state["player_weak"]),
		"player_vulnerable": int(state["player_vulnerable"]),
		"enemy_hp": int(state["enemy_hp"]),
		"enemy_block": int(state["enemy_block"]),
		"enemy_poison": int(state["enemy_poison"]),
		"enemy_weak": int(state["enemy_weak"]),
		"enemy_vulnerable": int(state["enemy_vulnerable"])
	}

func is_victory() -> bool:
	var group: Array = state.get("enemy_group", []) as Array
	if group.is_empty():
		return int(state.get("enemy_hp", 0)) <= 0
	for eg_v: Variant in group:
		if int((eg_v as Dictionary)["hp"]) > 0:
			return false
	return true

func is_defeat() -> bool:
	var players: Array = state.get("players", []) as Array
	if players.is_empty():
		return int(state.get("player_hp", 0)) <= 0
	for p_v: Variant in players:
		if int((p_v as Dictionary)["hp"]) > 0:
			return false
	return true

func is_battle_over() -> bool:
	return is_victory() or is_defeat()

func complete_victory() -> void:
	# 同步所有角色 HP 回 run_state，包括 active 切換結果
	_sync_state_to_active()
	var players: Array = state.get("players", []) as Array
	for i: int in range(players.size()):
		if i >= run_state.character_hps.size():
			break
		run_state.character_hps[i] = int((players[i] as Dictionary)["hp"])
	run_state.active_character_index = _active_index()

func next_enemy_action() -> Dictionary:
	var group: Array = state.get("enemy_group", []) as Array
	var idx: int = int(state.get("targeted_enemy_index", 0))
	if not group.is_empty() and idx < group.size():
		var eg: Dictionary = group[idx] as Dictionary
		var ai: int = int(eg["action_index"])
		var acts: Array = []
		if bool(eg["phased"]) and not (eg["phase_2_actions"] as Array).is_empty():
			acts = eg["phase_2_actions"] as Array
		else:
			acts = eg["actions"] as Array
		if acts.is_empty():
			return {}
		return acts[ai % acts.size()] as Dictionary
	var active: Array[Dictionary] = enemy.phase_2_actions if (phased and not enemy.phase_2_actions.is_empty()) else enemy.actions
	return active[action_index % active.size()]

func _check_phase_transition() -> void:
	var idx: int = int(state.get("targeted_enemy_index", 0))
	_check_phase_transition_for(idx)
	# 同步 class-level phased 到 enemy[0] 保持向後相容
	var group: Array = state.get("enemy_group", []) as Array
	if not group.is_empty():
		phased = bool((group[0] as Dictionary)["phased"])

func _check_phase_transition_for(idx: int) -> void:
	var group: Array = state.get("enemy_group", []) as Array
	if group.is_empty() or idx >= group.size():
		if phased or enemy.phase_2_actions.is_empty():
			return
		if int(state["enemy_hp"]) * 2 < int(state["enemy_max_hp"]):
			phased = true
			action_index = 0
			add_log("%s 怒色暴漲，招式變換！" % enemy.display_name)
		return
	var eg: Dictionary = group[idx] as Dictionary
	if bool(eg["phased"]) or (eg["phase_2_actions"] as Array).is_empty():
		return
	if int(eg["hp"]) * 2 < int(eg["max_hp"]):
		eg["phased"] = true
		eg["action_index"] = 0
		add_log("%s 怒色暴漲，招式變換！" % String(eg["name"]))

func effective_card_cost(card: CardData) -> int:
	if character == null:
		return card.cost
	var passive: Dictionary = character.passive_by_trigger("first_attack_cost")
	if not passive.is_empty() and card.card_type == "attack" and not bool(state.get("li_discount_used", false)):
		return max(0, card.cost - int(passive.get("amount", 0)))
	return card.cost

func start_turn() -> Dictionary:
	state["turn"] = int(state["turn"]) + 1
	state["energy"] = int(state.get("per_turn_energy", BASE_TURN_ENERGY))
	# Block carry-over (玄武魂) — 套到 active player
	state["player_block"] = int(state.get("next_turn_block", 0))
	state["next_turn_block"] = 0
	state["enemy_block"] = 0
	state["pending_draw"] = 0
	state["lin_block_used"] = false
	state["switched_this_turn"] = false
	if int(state["enemy_vulnerable"]) > 0:
		state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	if int(state["enemy_weak"]) > 0:
		state["enemy_weak"] = int(state["enemy_weak"]) - 1
	_apply_bench_heal()
	var before_tick: Dictionary = snapshot_state()
	add_logs(resolver.tick_statuses(state))
	_sync_target_to_aliases()  # enemy_group 毒傷已更新，刷新平坦別名
	# 同時刷新 start_turn 裡的 enemy_vulnerable / weak 衰減（只對目標敵人；多敵每人各自衰減見 begin_enemy_phase_all）
	_sync_state_to_active()
	if is_battle_over():
		return {"before_tick": before_tick, "ended": true}
	_fire_relic_triggers("turn_start")
	var draw_count: int = HAND_SIZE + int(state.get("draw_next_turn_bonus", 0))
	state["draw_next_turn_bonus"] = 0
	if deck != null:
		deck.draw(draw_count)
	add_log("第 %d 回合開始，抽 %d 張牌。" % [int(state["turn"]), draw_count])
	return {"before_tick": before_tick, "ended": false}

func _apply_bench_heal() -> void:
	var players: Array = state.get("players", []) as Array
	var active: int = _active_index()
	for i: int in range(players.size()):
		if i == active:
			continue
		var p: Dictionary = players[i] as Dictionary
		var hp: int = int(p["hp"])
		var max_hp_v: int = int(p["max_hp"])
		if hp > 0 and hp < max_hp_v:
			p["hp"] = min(max_hp_v, hp + BENCH_HEAL_PER_TURN)

func play_card(card: CardData) -> Dictionary:
	var cost: int = effective_card_cost(card)
	if int(state["energy"]) < cost:
		add_log("靈力不足，無法施放 %s。" % card.display_title())
		return {"affordable": false}
	state["energy"] = int(state["energy"]) - cost
	if character != null and not character.passive_by_trigger("first_attack_cost").is_empty() and card.card_type == "attack" and not bool(state["li_discount_used"]):
		state["li_discount_used"] = true
	add_log("施放 %s。" % card.display_title())
	var before_card: Dictionary = snapshot_state()
	add_logs(resolver.resolve_card(card, state))
	_sync_aliases_to_target()  # 單體效果寫回 enemy_group
	var steal: Dictionary = state.get("steal_result", {}) as Dictionary
	if not steal.is_empty():
		state["steal_result"] = {}
		_apply_stolen_item(steal)
	_check_phase_transition()
	_apply_card_play_passive(card)
	_fire_relic_triggers("card_played", {
		"card_type": card.card_type,
		"card_cost": card.cost,
		"card_effects": card.effects
	})
	if deck != null:
		deck.discard_card(card)
	if int(state["pending_draw"]) > 0:
		if deck != null:
			deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0
	_sync_state_to_active()
	return {"affordable": true, "before_card": before_card, "ended": is_battle_over()}

func begin_enemy_phase() -> Dictionary:
	# 向後相容單敵版本（smoke test 用）
	var all_actions: Array[Dictionary] = begin_enemy_phase_all()
	if all_actions.is_empty():
		return {}
	return all_actions[0].get("action", {}) as Dictionary

func begin_enemy_phase_all() -> Array[Dictionary]:
	_fire_relic_triggers("turn_end")
	if deck != null:
		deck.discard_hand()
	if int(state["player_weak"]) > 0:
		state["player_weak"] = int(state["player_weak"]) - 1
	if int(state["player_vulnerable"]) > 0:
		state["player_vulnerable"] = int(state["player_vulnerable"]) - 1
	_sync_state_to_active()
	var action_list: Array[Dictionary] = []
	var group: Array = state.get("enemy_group", []) as Array
	for i: int in range(group.size()):
		var eg: Dictionary = group[i] as Dictionary
		if int(eg["hp"]) <= 0:
			continue
		# 回合開始：每個活著的敵人狀態衰減
		if int(eg["vulnerable"]) > 0:
			eg["vulnerable"] = int(eg["vulnerable"]) - 1
		if int(eg["weak"]) > 0:
			eg["weak"] = int(eg["weak"]) - 1
		var acts: Array = []
		if bool(eg["phased"]) and not (eg["phase_2_actions"] as Array).is_empty():
			acts = eg["phase_2_actions"] as Array
		else:
			acts = eg["actions"] as Array
		if acts.is_empty():
			continue
		var ai: int = int(eg["action_index"])
		var action: Dictionary = acts[ai % acts.size()] as Dictionary
		eg["action_index"] = ai + 1
		add_log("%s 準備施放：%s。" % [String(eg["name"]), String(action["intent"])])
		action_list.append({"enemy_index": i, "action": action, "enemy_name": String(eg["name"])})
	# 同步目標別名（vulnerable/weak 已衰減）
	_sync_target_to_aliases()
	return action_list

func resolve_single_enemy_action(enemy_index: int, action: Dictionary) -> Dictionary:
	state["targeted_enemy_index"] = enemy_index
	_sync_target_to_aliases()
	add_log("%s：%s。" % [state["enemy_name"], String(action["intent"])])
	var before_enemy: Dictionary = snapshot_state()
	add_logs(resolver.resolve_enemy_action(action, state))
	_sync_aliases_to_target()
	_check_phase_transition_for(enemy_index)
	_sync_state_to_active()
	if not _is_active_alive() and not is_defeat():
		_force_switch_to_first_alive(true)
	return {"before_enemy": before_enemy, "ended": is_battle_over()}

func resolve_enemy_phase(action: Dictionary) -> Dictionary:
	# 向後相容（smoke test 用）：以目前 targeted_enemy_index 解算
	var idx: int = int(state.get("targeted_enemy_index", 0))
	return resolve_single_enemy_action(idx, action)

func passive_status_text() -> String:
	if state.is_empty() or character == null:
		return ""
	for passive: Dictionary in character.passives:
		var status_label: String = String(passive.get("status_label", ""))
		if status_label.is_empty():
			continue
		var trigger: String = String(passive.get("trigger", ""))
		match trigger:
			"first_attack_cost":
				if not bool(state.get("li_discount_used", false)):
					return "被動：%s" % status_label
			"first_block_counter":
				if not bool(state.get("lin_block_used", false)):
					return "被動：%s" % status_label
	return ""

# MVP：套用所有隊員的 battle_start 被動。self_heal 套在該角色 slot 上，
# enemy_poison / 其他針對敵人的效果直接套 state
func _apply_party_battle_start_passives() -> void:
	var players: Array = state.get("players", []) as Array
	for i: int in range(players.size()):
		var c: CharacterData = run_state.characters[i] if i < run_state.characters.size() else null
		if c == null:
			continue
		var passive: Dictionary = c.passive_by_trigger("battle_start")
		if passive.is_empty():
			continue
		var kind: String = String(passive.get("kind", ""))
		var amount: int = int(passive.get("amount", 0))
		match kind:
			"self_heal":
				var p: Dictionary = players[i] as Dictionary
				p["hp"] = min(int(p["max_hp"]), int(p["hp"]) + amount)
				if i == _active_index():
					state["player_hp"] = p["hp"]
				add_log("%s被動：戰鬥開始回復 %d 點生命。" % [c.display_name, amount])
			"enemy_poison":
				state["enemy_poison"] = int(state["enemy_poison"]) + amount
				add_log("%s被動：敵人開場受到 %d 層蠱毒。" % [c.display_name, amount])

func _apply_relic_modifiers() -> void:
	if run_state == null:
		return
	for relic: RelicData in run_state.relics:
		for trigger: Dictionary in relic.triggers:
			if String(trigger.get("trigger", "")) != "passive_modifier":
				continue
			for effect: Dictionary in (trigger.get("effects", []) as Array):
				var kind: String = String(effect.get("kind", ""))
				var amount: int = int(effect.get("amount", 0))
				if state.has(kind):
					state[kind] = int(state[kind]) + amount

func _fire_relic_triggers(trigger_name: String, context: Dictionary = {}) -> void:
	if run_state == null:
		return
	for relic: RelicData in run_state.relics:
		for trigger: Dictionary in relic.triggers:
			if String(trigger.get("trigger", "")) != trigger_name:
				continue
			if not _trigger_filter_matches(trigger.get("filter", {}) as Dictionary, context, relic.id):
				continue
			_apply_trigger_effects(trigger.get("effects", []) as Array, relic.display_name)

func _trigger_filter_matches(filter: Dictionary, context: Dictionary, relic_id: String) -> bool:
	if filter.is_empty():
		return true
	if filter.has("card_type"):
		if String(context.get("card_type", "")) != String(filter["card_type"]):
			return false
	if filter.has("effect_has"):
		var has_kind: bool = false
		for e: Dictionary in (context.get("card_effects", []) as Array):
			if String(e.get("kind", "")) == String(filter["effect_has"]):
				has_kind = true
				break
		if not has_kind:
			return false
	if filter.has("cost_eq"):
		if int(context.get("card_cost", -1)) != int(filter["cost_eq"]):
			return false
	if filter.has("max_per_battle"):
		var counts: Dictionary = state.get("card_played_counts", {}) as Dictionary
		var key: String = "relic_" + relic_id
		var current: int = int(counts.get(key, 0))
		if current >= int(filter["max_per_battle"]):
			return false
		counts[key] = current + 1
		state["card_played_counts"] = counts
	return true

func _apply_trigger_effects(effects: Array, relic_name: String) -> void:
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"self_heal":
				var actual: int = amount + int(state.get("heal_bonus", 0))
				state["player_hp"] = min(int(state["player_max_hp"]), int(state["player_hp"]) + actual)
				_sync_state_to_active()
				add_log("【%s】回復 %d 生命。" % [relic_name, actual])
			"self_block":
				var actual_block: int = amount + int(state.get("block_bonus", 0))
				state["player_block"] = int(state["player_block"]) + actual_block
				add_log("【%s】獲得 %d 護體。" % [relic_name, actual_block])
			"self_energy":
				state["energy"] = int(state["energy"]) + amount
				add_log("【%s】回復 %d 靈力。" % [relic_name, amount])
			"self_draw":
				state["pending_draw"] = int(state["pending_draw"]) + amount
				add_log("【%s】抽 %d 張牌。" % [relic_name, amount])
			"self_draw_next_turn":
				state["draw_next_turn_bonus"] = int(state["draw_next_turn_bonus"]) + amount
				add_log("【%s】下回合多抽 %d 張。" % [relic_name, amount])
			"self_power":
				state["player_power"] = int(state["player_power"]) + amount
				add_log("【%s】傷害 +%d。" % [relic_name, amount])
			"enemy_damage":
				var dmg: int = amount + int(state.get("damage_out_bonus", 0))
				var blocked: int = min(int(state["enemy_block"]), dmg)
				state["enemy_block"] = int(state["enemy_block"]) - blocked
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (dmg - blocked))
				add_log("【%s】造成 %d 傷害。" % [relic_name, dmg - blocked])
			"enemy_poison":
				var poison_amount: int = amount + int(state.get("poison_bonus", 0))
				state["enemy_poison"] = int(state["enemy_poison"]) + poison_amount
				add_log("【%s】敵人 +%d 蠱毒。" % [relic_name, poison_amount])
			"enemy_weak":
				state["enemy_weak"] = int(state["enemy_weak"]) + amount
				add_log("【%s】敵人 +%d 虛弱。" % [relic_name, amount])
			"enemy_vulnerable":
				state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) + amount
				add_log("【%s】敵人 +%d 破綻。" % [relic_name, amount])
			"block_carry":
				state["next_turn_block"] = int(state.get("next_turn_block", 0)) + amount
				add_log("【%s】保留 %d 護體到下回合。" % [relic_name, amount])
			"poison_resonance":
				# 50% poison damage as direct damage
				var current_poison: int = int(state["enemy_poison"])
				var bonus_dmg: int = int(current_poison * 0.5)
				if bonus_dmg > 0:
					state["enemy_hp"] = max(0, int(state["enemy_hp"]) - bonus_dmg)
					add_log("【%s】蠱毒共鳴造成 %d 傷害。" % [relic_name, bonus_dmg])

func _apply_card_play_passive(card: CardData) -> void:
	if character == null:
		return
	var passive: Dictionary = character.passive_by_trigger("first_block_counter")
	if passive.is_empty():
		return
	if bool(state["lin_block_used"]):
		return
	for effect: Dictionary in card.effects:
		if String(effect.get("kind", "")) == "block":
			state["lin_block_used"] = true
			var amount: int = int(passive.get("amount", 0))
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - amount)
			add_log("%s被動：回身反擊造成 %d 點傷害。" % [character.display_name, amount])
			return
