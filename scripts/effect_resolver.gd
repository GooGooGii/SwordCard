class_name EffectResolver
extends RefCounted

func resolve_card(card: CardData, state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	for effect in card.effects:
		log_lines.append_array(_resolve_effect(effect, state))
	return log_lines

func resolve_effects_list(effects: Array, state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	for effect: Dictionary in effects:
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
	var group: Array = state.get("enemy_group", []) as Array
	if not group.is_empty():
		for eg_v: Variant in group:
			var eg: Dictionary = eg_v as Dictionary
			if int(eg["hp"]) <= 0 or int(eg["poison"]) <= 0:
				continue
			eg["hp"] = max(0, int(eg["hp"]) - int(eg["poison"]))
			log_lines.append("%s 中毒造成 %d 點傷害。" % [String(eg["name"]), int(eg["poison"])])
			eg["poison"] = max(0, int(eg["poison"]) - 1)
	else:
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
				if int(state["player_vulnerable"]) > 0:
					modified = int(ceil(modified * 1.5))
				modified = max(0, modified - int(state.get("damage_taken_reduction", 0)))
				var blocked: int = min(int(state["player_block"]), modified)
				state["player_block"] = int(state["player_block"]) - blocked
				state["player_hp"] = max(0, int(state["player_hp"]) - (modified - blocked))
				log_lines.append("%s 攻擊，造成 %d 點傷害。" % [state["enemy_name"], modified - blocked])
			else:
				var modified: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
				if int(state["enemy_vulnerable"]) > 0:
					modified = int(ceil(modified * 1.5))
				var blocked: int = min(int(state["enemy_block"]), modified)
				state["enemy_block"] = int(state["enemy_block"]) - blocked
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
				log_lines.append("造成 %d 點傷害。" % (modified - blocked))
		"damage_all":
			var base: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
			var group: Array = state.get("enemy_group", []) as Array
			var hit_count: int = 0
			for eg_v: Variant in group:
				var eg: Dictionary = eg_v as Dictionary
				if int(eg["hp"]) <= 0:
					continue
				var dmg: int = base
				if int(eg["vulnerable"]) > 0:
					dmg = int(ceil(dmg * 1.5))
				var blocked: int = min(int(eg["block"]), dmg)
				eg["block"] = int(eg["block"]) - blocked
				eg["hp"] = max(0, int(eg["hp"]) - (dmg - blocked))
				log_lines.append("%s 受到 %d 點傷害。" % [String(eg["name"]), dmg - blocked])
				hit_count += 1
			if hit_count == 0:
				# fallback: single enemy aliases
				var modified: int = base
				if int(state["enemy_vulnerable"]) > 0:
					modified = int(ceil(modified * 1.5))
				var blocked: int = min(int(state["enemy_block"]), modified)
				state["enemy_block"] = int(state["enemy_block"]) - blocked
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
				log_lines.append("造成 %d 點傷害（全體）。" % (modified - blocked))
		"block":
			if from_enemy:
				state["enemy_block"] = int(state["enemy_block"]) + amount
				log_lines.append("%s 獲得 %d 點護體。" % [state["enemy_name"], amount])
			else:
				var actual_block: int = amount + int(state.get("block_bonus", 0))
				state["player_block"] = int(state["player_block"]) + actual_block
				log_lines.append("獲得 %d 點護體。" % actual_block)
		"heal":
			var actual_heal: int = amount + int(state.get("heal_bonus", 0))
			state["player_hp"] = min(int(state["player_max_hp"]), int(state["player_hp"]) + actual_heal)
			log_lines.append("回復 %d 點生命。" % actual_heal)
		"poison":
			if from_enemy:
				state["player_poison"] = int(state["player_poison"]) + amount
				log_lines.append("被施加 %d 層蠱毒。" % amount)
			else:
				var poison_amount: int = amount + int(state.get("poison_bonus", 0))
				state["enemy_poison"] = int(state["enemy_poison"]) + poison_amount
				log_lines.append("施加 %d 層蠱毒。" % poison_amount)
		"poison_all":
			var pa: int = amount + int(state.get("poison_bonus", 0))
			var group: Array = state.get("enemy_group", []) as Array
			var hit_count: int = 0
			for eg_v: Variant in group:
				var eg: Dictionary = eg_v as Dictionary
				if int(eg["hp"]) <= 0:
					continue
				eg["poison"] = int(eg["poison"]) + pa
				hit_count += 1
			if hit_count > 0:
				log_lines.append("對所有敵人施加 %d 層蠱毒。" % pa)
			else:
				state["enemy_poison"] = int(state["enemy_poison"]) + pa
				log_lines.append("施加 %d 層蠱毒。" % pa)
		"weak":
			if from_enemy:
				state["player_weak"] = int(state["player_weak"]) + amount
				log_lines.append("你受到 %d 層虛弱。" % amount)
			else:
				state["enemy_weak"] = int(state["enemy_weak"]) + amount
				log_lines.append("敵人受到 %d 層虛弱。" % amount)
		"weak_all":
			var group: Array = state.get("enemy_group", []) as Array
			var hit_count: int = 0
			for eg_v: Variant in group:
				var eg: Dictionary = eg_v as Dictionary
				if int(eg["hp"]) <= 0:
					continue
				eg["weak"] = int(eg["weak"]) + amount
				hit_count += 1
			if hit_count > 0:
				log_lines.append("對所有敵人施加 %d 層虛弱。" % amount)
			else:
				state["enemy_weak"] = int(state["enemy_weak"]) + amount
				log_lines.append("敵人受到 %d 層虛弱。" % amount)
		"vulnerable":
			if from_enemy:
				state["player_vulnerable"] = int(state["player_vulnerable"]) + amount
				log_lines.append("你受到 %d 層破綻。" % amount)
			else:
				state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) + amount
				log_lines.append("敵人受到 %d 層破綻。" % amount)
		"vulnerable_all":
			var group: Array = state.get("enemy_group", []) as Array
			var hit_count: int = 0
			for eg_v: Variant in group:
				var eg: Dictionary = eg_v as Dictionary
				if int(eg["hp"]) <= 0:
					continue
				eg["vulnerable"] = int(eg["vulnerable"]) + amount
				hit_count += 1
			if hit_count > 0:
				log_lines.append("對所有敵人施加 %d 層破綻。" % amount)
			else:
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
			var damage: int = max(0, amount * spent - int(state["player_weak"]))
			if int(state["enemy_vulnerable"]) > 0:
				damage = int(ceil(damage * 1.5))
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - damage)
			log_lines.append("耗盡靈力，造成 %d 點傷害。" % damage)
		"poison_burst":
			var burst: int = int(state["enemy_poison"]) * amount
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - burst)
			state["enemy_poison"] = 0
			log_lines.append("引爆蠱毒，造成 %d 點傷害。" % burst)
		"revive":
			# 救回第一個倒下的後排同伴；amount = 復活後的 HP（封頂於 max_hp）
			# 若沒有倒下同伴 → 改回復 active 同等量 HP（不至於完全廢卡）
			var players: Array = state.get("players", []) as Array
			var active_idx: int = int(state.get("active_player_index", 0))
			var revived_idx: int = -1
			for i: int in range(players.size()):
				if i == active_idx:
					continue
				var p: Dictionary = players[i] as Dictionary
				if int(p["hp"]) <= 0:
					p["hp"] = min(int(p["max_hp"]), amount)
					revived_idx = i
					break
			if revived_idx >= 0:
				var name: String = String((players[revived_idx] as Dictionary)["name"])
				log_lines.append("救回 %s（+%d HP）。" % [name, amount])
			else:
				# 沒人倒下 → fallback：當 heal 用
				var actual_heal: int = amount + int(state.get("heal_bonus", 0))
				state["player_hp"] = min(int(state["player_max_hp"]), int(state["player_hp"]) + actual_heal)
				log_lines.append("無人需救，改回復 %d 點生命。" % actual_heal)
		"status_amp_damage":
			# 追加傷害 = amount × (enemy_weak + enemy_vulnerable 層數)
			var stacks: int = int(state["enemy_weak"]) + int(state["enemy_vulnerable"])
			var bonus: int = amount * stacks + int(state.get("damage_out_bonus", 0))
			if bonus > 0:
				var blocked: int = min(int(state["enemy_block"]), bonus)
				state["enemy_block"] = int(state["enemy_block"]) - blocked
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (bonus - blocked))
				log_lines.append("狀態加成（%d 層），追加 %d 點傷害。" % [stacks, bonus - blocked])
		"cure_poison":
			state["player_poison"] = 0
			log_lines.append("蠱毒已全數清除。")
		"steal":
			if from_enemy:
				pass
			else:
				var loot_table: Array = state.get("enemy_loot_table", []) as Array
				if loot_table.is_empty():
					log_lines.append("（對方身上空無一物。）")
				else:
					var item: Dictionary = (loot_table[randi() % loot_table.size()] as Dictionary).duplicate()
					state["steal_result"] = item
					log_lines.append("偷到了%s！" % String(item.get("display_name", "某物")))
	return log_lines
