class_name BattleController
extends RefCounted

const HAND_SIZE: int = 5
const BASE_TURN_ENERGY: int = 3
const BENCH_HEAL_PER_TURN: int = 2
const MAX_ENEMIES_PER_BATTLE: int = 3

# Boss 進入 phase 2 時觸發，main.gd 接收後播放變身動畫
# 參數：new_name = state["enemy_name"]（phase_2_display_name 或 fallback 原名）
signal phase_transitioned(new_name: String)

var run_state: RunState
# Multi-Enemy Mode：戰場可有 1–3 敵人（boss 戰開場 1，可召出小怪）
# 舊 `enemy` 為 getter，指向 active enemy；state["enemy_*"] 為 alias 同步到 active slot
var enemies: Array[EnemyData] = []
var enemy_action_indices: Array[int] = []  # 每敵獨立 action 輪替
var enemy_phased: Array[bool] = []          # 每敵獨立 phase_2 旗標
var decks: Array[DeckManager] = []  # 每個角色一份；舊 `deck` 屬性指向 active
var resolver: EffectResolver
var state: Dictionary = {}
var battle_log: Array[String] = []

# 向後相容 getter — 指向 active enemy
var enemy: EnemyData:
	get:
		var idx: int = _active_enemy_index()
		return enemies[idx] if idx >= 0 and idx < enemies.size() else null

# 向後相容 getter/setter — 對應 active enemy 的 action_index
var action_index: int:
	get:
		var idx: int = _active_enemy_index()
		return enemy_action_indices[idx] if idx >= 0 and idx < enemy_action_indices.size() else 0
	set(value):
		var idx: int = _active_enemy_index()
		if idx >= 0 and idx < enemy_action_indices.size():
			enemy_action_indices[idx] = value

# 向後相容 getter/setter — 對應 active enemy 的 phased 旗標
var phased: bool:
	get:
		var idx: int = _active_enemy_index()
		return enemy_phased[idx] if idx >= 0 and idx < enemy_phased.size() else false
	set(value):
		var idx: int = _active_enemy_index()
		if idx >= 0 and idx < enemy_phased.size():
			enemy_phased[idx] = value

func _active_enemy_index() -> int:
	return int(state.get("active_enemy_index", 0))

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

func setup(rs: RunState, _legacy_character: CharacterData, chosen_enemy: Variant) -> void:
	# chosen_enemy 可為單一 EnemyData（向後相容）或 Array[EnemyData]（多敵戰場）
	run_state = rs
	enemies.clear()
	enemy_action_indices.clear()
	enemy_phased.clear()
	if chosen_enemy is EnemyData:
		enemies.append((chosen_enemy as EnemyData).clone())
	elif chosen_enemy is Array:
		for e: Variant in (chosen_enemy as Array):
			if e is EnemyData:
				enemies.append((e as EnemyData).clone())
	assert(not enemies.is_empty(), "BattleController.setup requires at least 1 enemy")
	for _i: int in range(enemies.size()):
		enemy_action_indices.append(0)
		enemy_phased.append(false)
	resolver = EffectResolver.new()
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
	# 多敵 slot 陣列
	var enemy_slots: Array[Dictionary] = []
	for e: EnemyData in enemies:
		enemy_slots.append({
			"id": e.id,
			"name": e.display_name,
			"max_hp": e.max_hp,
			"hp": e.max_hp,
			"block": 0,
			"poison": 0,
			"weak": 0,
			"vulnerable": 0,
			"loot_table": GameData.loot_table_for(e.id),
		})
	state = {
		"players": players,
		"active_player_index": clamp(run_state.active_character_index, 0, max(0, party_size - 1)),
		"switched_this_turn": false,
		"per_turn_energy": per_turn_energy,
		# Multi-enemy state
		"enemies": enemy_slots,
		"active_enemy_index": 0,
		# 以下 enemy_* 是 alias，從 enemies[active_enemy_index] 複製出來
		"enemy_name": enemy_slots[0]["name"],
		"enemy_max_hp": enemy_slots[0]["max_hp"],
		"enemy_hp": enemy_slots[0]["hp"],
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"enemy_loot_table": enemy_slots[0]["loot_table"],
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
		"card_played_counts": {},
		"last_attacker_index": 0,  # 林月如反擊指向的敵人
		"steal_result": {}
	}
	# 若 active 死了（舊存檔載入後可能發生），自動跳到第一個活的
	if not _is_active_alive():
		_force_switch_to_first_alive(false)
	_sync_active_to_state()
	_apply_relic_modifiers()
	_apply_party_battle_start_passives()
	_fire_relic_triggers("battle_start")

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

# 多敵 alias 同步：enemies[active_enemy_index] → state["enemy_*"]
# 在 set_active_enemy() 切換後、AOE 效果結算後呼叫
func _sync_active_enemy_to_state() -> void:
	var idx: int = _active_enemy_index()
	var enemy_slots: Array = state.get("enemies", []) as Array
	if idx < 0 or idx >= enemy_slots.size():
		return
	var slot: Dictionary = enemy_slots[idx] as Dictionary
	state["enemy_name"] = slot["name"]
	state["enemy_max_hp"] = slot["max_hp"]
	state["enemy_hp"] = slot["hp"]
	state["enemy_block"] = slot["block"]
	state["enemy_poison"] = slot["poison"]
	state["enemy_weak"] = slot["weak"]
	state["enemy_vulnerable"] = slot["vulnerable"]
	state["enemy_loot_table"] = slot["loot_table"]

# 把 state["enemy_*"] 寫回 enemies[active_enemy_index] slot
# 在單體 effect（damage/poison/weak/vulnerable 等）結算後呼叫
func _sync_state_to_active_enemy() -> void:
	var idx: int = _active_enemy_index()
	var enemy_slots: Array = state.get("enemies", []) as Array
	if idx < 0 or idx >= enemy_slots.size():
		return
	var slot: Dictionary = enemy_slots[idx] as Dictionary
	slot["hp"] = int(state.get("enemy_hp", slot["hp"]))
	slot["block"] = int(state.get("enemy_block", slot["block"]))
	slot["poison"] = int(state.get("enemy_poison", slot["poison"]))
	slot["weak"] = int(state.get("enemy_weak", slot["weak"]))
	slot["vulnerable"] = int(state.get("enemy_vulnerable", slot["vulnerable"]))
	# name / max_hp / loot_table 不變

# 玩家主動切換 active enemy（drag-to-play / click portrait 觸發）
func set_active_enemy(new_index: int) -> bool:
	var enemy_slots: Array = state.get("enemies", []) as Array
	if new_index < 0 or new_index >= enemy_slots.size():
		return false
	if int((enemy_slots[new_index] as Dictionary)["hp"]) <= 0:
		return false  # 不能 active 已死敵
	if new_index == _active_enemy_index():
		return false  # 已是 active
	_sync_state_to_active_enemy()  # 寫回舊 active
	state["active_enemy_index"] = new_index
	_sync_active_enemy_to_state()  # 加載新 active
	return true

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
	# 全部敵人 HP <= 0 才算勝（含召喚物）
	var enemy_slots: Array = state.get("enemies", []) as Array
	if enemy_slots.is_empty():
		return false
	for slot_v: Variant in enemy_slots:
		if int((slot_v as Dictionary)["hp"]) > 0:
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
	# 向後相容：回傳 active 敵的下一招
	return _action_for_enemy(_active_enemy_index())

func _action_for_enemy(idx: int) -> Dictionary:
	if idx < 0 or idx >= enemies.size():
		return {}
	var e: EnemyData = enemies[idx]
	var active_actions: Array[Dictionary] = e.phase_2_actions if (enemy_phased[idx] and not e.phase_2_actions.is_empty()) else e.actions
	if active_actions.is_empty():
		return {}
	return active_actions[enemy_action_indices[idx] % active_actions.size()]

func _enemy_display_name() -> String:
	return _enemy_display_name_for(_active_enemy_index())

func _enemy_display_name_for(idx: int) -> String:
	if idx < 0 or idx >= enemies.size():
		return ""
	var e: EnemyData = enemies[idx]
	if enemy_phased[idx] and not e.phase_2_display_name.is_empty():
		return e.phase_2_display_name
	return e.display_name

# 每敵獨立 phase 2 切換（AOE 後可能多敵同時跨 50% HP）
func _check_phase_transition() -> void:
	# 確保 active slot 反映最新 alias（單體 damage 後 alias 已更新但 slot 還沒）
	_sync_state_to_active_enemy()
	for i: int in range(enemies.size()):
		var e: EnemyData = enemies[i]
		if enemy_phased[i] or e.phase_2_actions.is_empty():
			continue
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if int(slot["hp"]) <= 0:
			continue  # 死敵不切 phase
		if int(slot["hp"]) * 2 < int(slot["max_hp"]):
			enemy_phased[i] = true
			enemy_action_indices[i] = 0
			var phase_2_name: String = e.phase_2_display_name
			var emit_name: String
			if not phase_2_name.is_empty():
				slot["name"] = phase_2_name
				if i == _active_enemy_index():
					state["enemy_name"] = phase_2_name
				add_log("%s 吟咒撕裂虛空，召出 %s 現世！" % [e.display_name, phase_2_name])
				emit_name = phase_2_name
			else:
				add_log("%s 怒色暴漲，招式變換！" % e.display_name)
				emit_name = e.display_name
			phase_transitioned.emit(emit_name)

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
	# Event Branching P4：curse 滯留效果在 tick 之後跑 — 新加的 poison 留到下回合 tick
	if int(state["turn"]) == 1:
		_apply_curse_retention("battle_start")
	_apply_curse_retention("turn_start")
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

# Event Branching P4：掃 active 角色的整副 deck（draw + hand + discard + exhausted）
# 對所有 curse 套用對應 trigger 的滯留 effects。trigger ∈ {"turn_start", "battle_start"}.
func _apply_curse_retention(trigger: String) -> void:
	if deck == null:
		return
	var pools: Array = [deck.draw_pile, deck.hand, deck.discard_pile, deck.exhausted_pile]
	for pool_v: Variant in pools:
		var pool: Array = pool_v as Array
		for card_v: Variant in pool:
			var card: CardData = card_v as CardData
			if not CurseCatalog.is_curse(card):
				continue
			var retention: Dictionary = CurseCatalog.retention_for(card)
			if String(retention.get("trigger", "")) != trigger:
				continue
			for eff_v: Variant in (retention.get("effects", []) as Array):
				_apply_curse_effect(eff_v as Dictionary, card.display_name)

# 一個 curse 滯留 effect 套到 state（player_* slot）
func _apply_curse_effect(effect: Dictionary, curse_name: String) -> void:
	var kind: String = String(effect.get("kind", ""))
	var amount: int = int(effect.get("amount", 0))
	match kind:
		"damage_self":
			# 詛咒傷害不可被 block 抵擋（直接扣 HP），最低 1
			state["player_hp"] = max(1, int(state["player_hp"]) - amount)
			add_log("「%s」滯留：-%d 生命。" % [curse_name, amount])
		"weak_self":
			state["player_weak"] = int(state["player_weak"]) + amount
			add_log("「%s」滯留：虛弱 +%d。" % [curse_name, amount])
		"vulnerable_self":
			state["player_vulnerable"] = int(state["player_vulnerable"]) + amount
			add_log("「%s」滯留：破綻 +%d。" % [curse_name, amount])
		"poison_self":
			state["player_poison"] = int(state["player_poison"]) + amount
			add_log("「%s」滯留：蠱毒 +%d。" % [curse_name, amount])
		"energy_drain_chance":
			var chance: float = float(effect.get("chance", 0.5))
			if randf() < chance:
				state["energy"] = max(0, int(state["energy"]) - amount)
				add_log("「%s」滯留：靈力 -%d。" % [curse_name, amount])

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
	# Event Branching P4：curse 不可主動打
	if CurseCatalog.is_curse(card):
		add_log("「%s」是詛咒，不可打出。" % card.display_title())
		return {"affordable": false, "curse_blocked": true}
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
	_sync_state_to_active_enemy()  # 單體敵人 effects 寫回 active slot
	_check_active_enemy_death()  # active 敵被打死 → 自動換到下一個活敵
	return {"affordable": true, "before_card": before_card, "ended": is_battle_over()}

# active 敵 HP <= 0 時，自動切換 active 到第一個活敵
func _check_active_enemy_death() -> void:
	var enemy_slots: Array = state.get("enemies", []) as Array
	var idx: int = _active_enemy_index()
	if idx < 0 or idx >= enemy_slots.size():
		return
	if int((enemy_slots[idx] as Dictionary)["hp"]) > 0:
		return  # active 還活著
	# 找下一個活敵
	for i: int in range(enemy_slots.size()):
		if int((enemy_slots[i] as Dictionary)["hp"]) > 0:
			state["active_enemy_index"] = i
			_sync_active_enemy_to_state()
			return
	# 全部死光 → is_victory 會處理

func begin_enemy_phase() -> Array[Dictionary]:
	# Multi-Enemy 模式：每隻活敵各預備一招，回傳陣列（死敵 = empty dict）
	# 1v1 退化情況：array size == 1
	_fire_relic_triggers("turn_end")
	if deck != null:
		deck.discard_hand()
	if int(state["player_weak"]) > 0:
		state["player_weak"] = int(state["player_weak"]) - 1
	if int(state["player_vulnerable"]) > 0:
		state["player_vulnerable"] = int(state["player_vulnerable"]) - 1
	_sync_state_to_active()
	var actions: Array[Dictionary] = []
	for i: int in range(enemies.size()):
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if int(slot["hp"]) <= 0:
			actions.append({})  # 死敵跳過
			continue
		var action: Dictionary = _action_for_enemy(i)
		enemy_action_indices[i] = enemy_action_indices[i] + 1
		actions.append(action)
		add_log("%s 準備施放：%s。" % [_enemy_display_name_for(i), String(action.get("intent", ""))])
	return actions

func resolve_enemy_phase(actions: Variant) -> Dictionary:
	# 向後相容：actions 可為 Array[Dictionary]（multi-enemy）或單一 Dictionary（legacy 1v1 caller）
	var action_list: Array[Dictionary] = []
	if actions is Dictionary:
		action_list.append(actions as Dictionary)
	elif actions is Array:
		for a: Variant in (actions as Array):
			action_list.append((a as Dictionary) if a is Dictionary else {})
	var before_enemy: Dictionary = snapshot_state()
	var saved_active: int = _active_enemy_index()
	for i: int in range(action_list.size()):
		var action: Dictionary = action_list[i]
		if action.is_empty():
			continue
		if i >= state["enemies"].size():
			break
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if int(slot["hp"]) <= 0:
			continue
		# 切 active 到 i，讓 enemy_weak / enemy_block alias 反映該敵
		if i != _active_enemy_index():
			_sync_state_to_active_enemy()
			state["active_enemy_index"] = i
			_sync_active_enemy_to_state()
		add_log("%s：%s。" % [_enemy_display_name_for(i), String(action.get("intent", ""))])
		add_logs(resolver.resolve_enemy_action(action, state))
		_sync_state_to_active_enemy()
		# 林月如反擊指向最後一個對玩家造成傷害的敵人
		if CardFormat.action_has_damage(action):
			state["last_attacker_index"] = i
		# 處理該敵 action 內的召喚請求
		_process_pending_summons(i)
		# 玩家若被打死，戰鬥結束，不繼續處理後面敵人
		if is_defeat():
			break
	# 還原 active：若 saved 還活著切回；否則找第一個活敵
	var enemy_slots: Array = state.get("enemies", []) as Array
	if saved_active < enemy_slots.size() and int((enemy_slots[saved_active] as Dictionary)["hp"]) > 0:
		if saved_active != _active_enemy_index():
			_sync_state_to_active_enemy()
			state["active_enemy_index"] = saved_active
			_sync_active_enemy_to_state()
	else:
		_check_active_enemy_death()
	_sync_state_to_active()
	if not _is_active_alive() and not is_defeat():
		_force_switch_to_first_alive(true)
	return {"before_enemy": before_enemy, "ended": is_battle_over()}

# 召喚機制：EffectResolver 的 "summon" effect 會把請求加進 state["pending_summons"]
# 在每隻敵人的 action 結算完後呼叫此函式處理
func _process_pending_summons(caster_idx: int) -> void:
	var pending: Array = state.get("pending_summons", []) as Array
	if pending.is_empty():
		return
	for req_v: Variant in pending:
		var req: Dictionary = req_v as Dictionary
		var id: String = String(req.get("id", ""))
		# 若未指定 id，從 caster.summon_pool 隨機抽
		if id.is_empty() and caster_idx >= 0 and caster_idx < enemies.size():
			var pool: Array[String] = enemies[caster_idx].summon_pool
			if not pool.is_empty():
				id = pool[randi() % pool.size()]
		if not id.is_empty():
			spawn_enemy(id)
	state["pending_summons"] = []

# 召喚新敵到戰場。回傳成功與否；戰場 >= MAX_ENEMIES_PER_BATTLE 或 id 未知 → false
func spawn_enemy(enemy_id: String) -> bool:
	if enemies.size() >= MAX_ENEMIES_PER_BATTLE:
		add_log("戰場已滿，召喚未成。")
		return false
	var template: EnemyData = GameData.enemy_by_id(enemy_id)
	if template == null:
		push_warning("BattleController.spawn_enemy: unknown enemy id '%s'" % enemy_id)
		return false
	var clone: EnemyData = template.clone()
	enemies.append(clone)
	enemy_action_indices.append(0)
	enemy_phased.append(false)
	var slot: Dictionary = {
		"id": clone.id,
		"name": clone.display_name,
		"max_hp": clone.max_hp,
		"hp": clone.max_hp,
		"block": 0,
		"poison": 0,
		"weak": 0,
		"vulnerable": 0,
		"loot_table": GameData.loot_table_for(clone.id),
	}
	(state["enemies"] as Array).append(slot)
	add_log("召出 %s！" % clone.display_name)
	return true

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
			"self_power":
				# 戰鬥開場給該角色 +amount power（攻擊牌傷害 +amount）
				var p: Dictionary = players[i] as Dictionary
				p["power"] = int(p["power"]) + amount
				if i == _active_index():
					state["player_power"] = p["power"]
				add_log("%s被動：戰鬥開始攻擊提升 %d。" % [c.display_name, amount])
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

func _apply_stolen_item(item: Dictionary) -> void:
	var item_type: String = String(item.get("type", ""))
	match item_type:
		"gold":
			var amount: int = int(item.get("amount", 0))
			run_state.gold += amount
			add_log("【飛龍探雲手】獲得 %s。" % item.get("display_name", "銅錢"))
		"potion":
			if run_state.potions.size() < RunState.MAX_POTION_SLOTS:
				var potion_id: String = String(item.get("potion_id", ""))
				var potion: Dictionary = PotionCatalog.by_id(potion_id)
				if not potion.is_empty():
					run_state.potions.append(potion)
					add_log("【飛龍探雲手】獲得 %s（已存入藥格）。" % item.get("display_name", "藥品"))
				else:
					add_log("【飛龍探雲手】偷取失敗（藥品資料遺失）。")
			else:
				add_log("【飛龍探雲手】藥格已滿，%s 無法攜帶。" % item.get("display_name", "藥品"))

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
