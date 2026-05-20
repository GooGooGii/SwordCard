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

func setup(rs: RunState, chosen_character: CharacterData, chosen_enemy: EnemyData) -> void:
	run_state = rs
	character = chosen_character
	enemy = chosen_enemy.clone()
	deck = DeckManager.new()
	resolver = EffectResolver.new()
	deck.setup(run_state.deck)
	action_index = 0
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
		"lin_block_used": false
	}
	_apply_battle_start_passive()

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
	return enemy.actions[action_index % enemy.actions.size()]

func effective_card_cost(card: CardData) -> int:
	var passive: Dictionary = character.passive_by_trigger("first_attack_cost")
	if not passive.is_empty() and card.card_type == "attack" and not bool(state.get("li_discount_used", false)):
		return max(0, card.cost - int(passive.get("amount", 0)))
	return card.cost

func start_turn() -> Dictionary:
	state["turn"] = int(state["turn"]) + 1
	state["energy"] = TURN_ENERGY
	state["player_block"] = 0
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
	deck.draw(HAND_SIZE)
	add_log("第 %d 回合開始，抽 %d 張牌。" % [int(state["turn"]), HAND_SIZE])
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
	_apply_card_play_passive(card)
	deck.discard_card(card)
	if int(state["pending_draw"]) > 0:
		deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0
	return {"affordable": true, "before_card": before_card, "ended": is_battle_over()}

func begin_enemy_phase() -> Dictionary:
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
