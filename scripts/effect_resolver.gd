class_name EffectResolver
extends RefCounted

func resolve_card(card: CardData, state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	for effect in card.effects:
		log_lines.append_array(_resolve_effect(effect, state))
	return log_lines

func resolve_enemy_action(action: Dictionary, state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	var effects: Array = action.get("effects", []) as Array
	for effect: Dictionary in effects:
		log_lines.append_array(_resolve_effect(effect, state, true))
	return log_lines

func tick_statuses(state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	if int(state["enemy_poison"]) > 0:
		state["enemy_hp"] = max(0, int(state["enemy_hp"]) - int(state["enemy_poison"]))
		log_lines.append("中毒造成 %d 點傷害。" % int(state["enemy_poison"]))
		state["enemy_poison"] = max(0, int(state["enemy_poison"]) - 1)
	if int(state["player_poison"]) > 0:
		state["player_hp"] = max(0, int(state["player_hp"]) - int(state["player_poison"]))
		log_lines.append("你受到 %d 點蠱毒傷害。" % int(state["player_poison"]))
		state["player_poison"] = max(0, int(state["player_poison"]) - 1)
	return log_lines

func _resolve_effect(effect: Dictionary, state: Dictionary, from_enemy: bool = false) -> Array[String]:
	var log_lines: Array[String] = []
	var kind: String = String(effect.get("kind", ""))
	var amount: int = int(effect.get("amount", 0))
	match kind:
		"damage":
			if from_enemy:
				var modified: int = max(0, amount - int(state["enemy_weak"]))
				var blocked: int = min(int(state["player_block"]), modified)
				state["player_block"] = int(state["player_block"]) - blocked
				state["player_hp"] = max(0, int(state["player_hp"]) - (modified - blocked))
				log_lines.append("%s 攻擊，造成 %d 點傷害。" % [state["enemy_name"], modified - blocked])
			else:
				var modified: int = amount + int(state["player_power"])
				if int(state["enemy_vulnerable"]) > 0:
					modified = int(ceil(modified * 1.5))
				var blocked: int = min(int(state["enemy_block"]), modified)
				state["enemy_block"] = int(state["enemy_block"]) - blocked
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
				log_lines.append("造成 %d 點傷害。" % (modified - blocked))
		"block":
			if from_enemy:
				state["enemy_block"] = int(state["enemy_block"]) + amount
				log_lines.append("%s 獲得 %d 點護體。" % [state["enemy_name"], amount])
			else:
				var bonus: int = int(state.get("player_block_bonus", 0))
				state["player_block"] = int(state["player_block"]) + amount + bonus
				log_lines.append("獲得 %d 點護體。" % (amount + bonus))
		"heal":
			state["player_hp"] = min(int(state["player_max_hp"]), int(state["player_hp"]) + amount)
			log_lines.append("回復 %d 點生命。" % amount)
		"poison":
			if from_enemy:
				state["player_poison"] = int(state["player_poison"]) + amount
				log_lines.append("被施加 %d 層蠱毒。" % amount)
			else:
				state["enemy_poison"] = int(state["enemy_poison"]) + amount
				log_lines.append("施加 %d 層蠱毒。" % amount)
		"weak":
			if from_enemy:
				state["player_weak"] = int(state["player_weak"]) + amount
				log_lines.append("你受到 %d 層虛弱。" % amount)
			else:
				state["enemy_weak"] = int(state["enemy_weak"]) + amount
				log_lines.append("敵人受到 %d 層虛弱。" % amount)
		"vulnerable":
			state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) + amount
			log_lines.append("敵人受到 %d 層破綻。" % amount)
		"draw":
			state["pending_draw"] = int(state["pending_draw"]) + amount
			log_lines.append("抽 %d 張牌。" % amount)
		"energy":
			state["energy"] = int(state["energy"]) + amount
			log_lines.append("回復 %d 點靈力。" % amount)
		"self_damage":
			state["player_hp"] = max(0, int(state["player_hp"]) - amount)
			log_lines.append("自身承受 %d 點反噬。" % amount)
		"power":
			state["player_power"] = int(state["player_power"]) + amount
			log_lines.append("本場戰鬥傷害提升 %d。" % amount)
		"consume_energy_damage":
			var spent: int = int(state["energy"])
			state["energy"] = 0
			var damage: int = amount * spent
			if int(state["enemy_vulnerable"]) > 0:
				damage = int(ceil(damage * 1.5))
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - damage)
			log_lines.append("耗盡靈力，造成 %d 點傷害。" % damage)
		"poison_burst":
			var burst: int = int(state["enemy_poison"]) * amount
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - burst)
			state["enemy_poison"] = 0
			log_lines.append("引爆蠱毒，造成 %d 點傷害。" % burst)
	return log_lines
