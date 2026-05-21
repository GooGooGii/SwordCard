class_name BattleController
extends RefCounted

const HAND_SIZE: int = 5
const TURN_ENERGY: int = 3

var run_state: RunState
var character: CharacterData
var enemy: EnemyData
var deck: DeckManager
var resolver: EffectResolver
var state: Dictionary = {}
var action_index: int = 0
var battle_log: Array[String] = []
var phased: bool = false  # Boss HP 跌破 50% 後切換到 phase_2_actions

func setup(rs: RunState, chosen_character: CharacterData, chosen_enemy: EnemyData) -> void:
	run_state = rs
	character = chosen_character
	enemy = chosen_enemy.clone()
	deck = DeckManager.new()
	resolver = EffectResolver.new()
	deck.setup(run_state.deck)
	action_index = 0
	phased = false
	battle_log.clear()
	state = {
		"player_name": character.display_name,
		"player_max_hp": character.max_hp,
		"player_hp": run_state.hp,
		"player_block": 0,
		"player_poison": 0,
		"player_weak": 0,
		"player_vulnerable": 0,
		"player_power": run_state.power_bonus,
		"enemy_name": enemy.display_name,
		"enemy_max_hp": enemy.max_hp,
		"enemy_hp": enemy.max_hp,
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"energy": TURN_ENERGY,
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
	_apply_relic_modifiers()
	_apply_battle_start_passive()
	_fire_relic_triggers("battle_start")

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
	return int(state["enemy_hp"]) <= 0

func is_defeat() -> bool:
	return int(state["player_hp"]) <= 0

func is_battle_over() -> bool:
	return is_victory() or is_defeat()

func complete_victory() -> void:
	run_state.sync_hp_from_battle(int(state["player_hp"]))

func next_enemy_action() -> Dictionary:
	var active: Array[Dictionary] = enemy.phase_2_actions if (phased and not enemy.phase_2_actions.is_empty()) else enemy.actions
	return active[action_index % active.size()]

func _check_phase_transition() -> void:
	if phased or enemy.phase_2_actions.is_empty():
		return
	if int(state["enemy_hp"]) * 2 < int(state["enemy_max_hp"]):
		phased = true
		action_index = 0
		add_log("%s 怒色暴漲，招式變換！" % enemy.display_name)

func effective_card_cost(card: CardData) -> int:
	var passive: Dictionary = character.passive_by_trigger("first_attack_cost")
	if not passive.is_empty() and card.card_type == "attack" and not bool(state.get("li_discount_used", false)):
		return max(0, card.cost - int(passive.get("amount", 0)))
	return card.cost

func start_turn() -> Dictionary:
	state["turn"] = int(state["turn"]) + 1
	state["energy"] = TURN_ENERGY
	# Block carry-over (玄武魂)
	state["player_block"] = int(state.get("next_turn_block", 0))
	state["next_turn_block"] = 0
	state["enemy_block"] = 0
	state["pending_draw"] = 0
	state["lin_block_used"] = false
	if int(state["enemy_vulnerable"]) > 0:
		state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	if int(state["enemy_weak"]) > 0:
		state["enemy_weak"] = int(state["enemy_weak"]) - 1
	var before_tick: Dictionary = snapshot_state()
	add_logs(resolver.tick_statuses(state))
	if is_battle_over():
		return {"before_tick": before_tick, "ended": true}
	_fire_relic_triggers("turn_start")
	var draw_count: int = HAND_SIZE + int(state.get("draw_next_turn_bonus", 0))
	state["draw_next_turn_bonus"] = 0
	deck.draw(draw_count)
	add_log("第 %d 回合開始，抽 %d 張牌。" % [int(state["turn"]), draw_count])
	return {"before_tick": before_tick, "ended": false}

func play_card(card: CardData) -> Dictionary:
	var cost: int = effective_card_cost(card)
	if int(state["energy"]) < cost:
		add_log("靈力不足，無法施放 %s。" % card.display_title())
		return {"affordable": false}
	state["energy"] = int(state["energy"]) - cost
	if not character.passive_by_trigger("first_attack_cost").is_empty() and card.card_type == "attack" and not bool(state["li_discount_used"]):
		state["li_discount_used"] = true
	add_log("施放 %s。" % card.display_title())
	var before_card: Dictionary = snapshot_state()
	add_logs(resolver.resolve_card(card, state))
	_check_phase_transition()
	_apply_card_play_passive(card)
	_fire_relic_triggers("card_played", {
		"card_type": card.card_type,
		"card_cost": card.cost,
		"card_effects": card.effects
	})
	deck.discard_card(card)
	if int(state["pending_draw"]) > 0:
		deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0
	return {"affordable": true, "before_card": before_card, "ended": is_battle_over()}

func begin_enemy_phase() -> Dictionary:
	_fire_relic_triggers("turn_end")
	deck.discard_hand()
	if int(state["player_weak"]) > 0:
		state["player_weak"] = int(state["player_weak"]) - 1
	if int(state["player_vulnerable"]) > 0:
		state["player_vulnerable"] = int(state["player_vulnerable"]) - 1
	var action: Dictionary = next_enemy_action()
	action_index = action_index + 1
	add_log("%s 準備施放：%s。" % [enemy.display_name, String(action["intent"])])
	return action

func resolve_enemy_phase(action: Dictionary) -> Dictionary:
	add_log("%s：%s。" % [enemy.display_name, String(action["intent"])])
	var before_enemy: Dictionary = snapshot_state()
	add_logs(resolver.resolve_enemy_action(action, state))
	return {"before_enemy": before_enemy, "ended": is_battle_over()}

func passive_status_text() -> String:
	if state.is_empty():
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

func _apply_battle_start_passive() -> void:
	var passive: Dictionary = character.passive_by_trigger("battle_start")
	if passive.is_empty():
		return
	var kind: String = String(passive.get("kind", ""))
	var amount: int = int(passive.get("amount", 0))
	match kind:
		"self_heal":
			state["player_hp"] = min(character.max_hp, int(state["player_hp"]) + amount)
			run_state.sync_hp_from_battle(int(state["player_hp"]))
			add_log("%s被動：戰鬥開始回復 %d 點生命。" % [character.display_name, amount])
		"enemy_poison":
			state["enemy_poison"] = int(state["enemy_poison"]) + amount
			add_log("%s被動：敵人開場受到 %d 層蠱毒。" % [character.display_name, amount])

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
				run_state.sync_hp_from_battle(int(state["player_hp"]))
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
