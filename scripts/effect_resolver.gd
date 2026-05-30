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

# Multi-Enemy alias 同步：把 state["enemy_*"] 寫回 enemies[active_enemy_index] slot
# 多體效果（damage_all 等）前呼叫，確保 active slot 反映最新單體 effect 結果
func _sync_active_slot_from_alias(state: Dictionary) -> void:
	var slots: Array = state.get("enemies", []) as Array
	var idx: int = int(state.get("active_enemy_index", 0))
	if idx < 0 or idx >= slots.size():
		return
	var slot: Dictionary = slots[idx] as Dictionary
	slot["hp"] = int(state.get("enemy_hp", slot["hp"]))
	slot["block"] = int(state.get("enemy_block", slot["block"]))
	slot["poison"] = int(state.get("enemy_poison", slot["poison"]))
	slot["weak"] = int(state.get("enemy_weak", slot["weak"]))
	slot["vulnerable"] = int(state.get("enemy_vulnerable", slot["vulnerable"]))

# Multi-Enemy alias 同步：把 enemies[active_enemy_index] slot 寫到 state["enemy_*"] alias
# 多體效果結算後呼叫，讓後續單體 effect 看到正確 active 值
func _sync_alias_from_active_slot(state: Dictionary) -> void:
	var slots: Array = state.get("enemies", []) as Array
	var idx: int = int(state.get("active_enemy_index", 0))
	if idx < 0 or idx >= slots.size():
		return
	var slot: Dictionary = slots[idx] as Dictionary
	state["enemy_hp"] = int(slot["hp"])
	state["enemy_block"] = int(slot["block"])
	state["enemy_poison"] = int(slot["poison"])
	state["enemy_weak"] = int(slot["weak"])
	state["enemy_vulnerable"] = int(slot["vulnerable"])

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
				# Thorns 反擊：被攻擊時反彈 player_thorns 點傷害給攻擊者（不過 weak/vuln，
				# 直接扣血 / 透過 enemy_block）。每次 from_enemy damage 觸發一次。
				var thorns: int = int(state.get("player_thorns", 0))
				if thorns > 0:
					var t_blocked: int = min(int(state["enemy_block"]), thorns)
					state["enemy_block"] = int(state["enemy_block"]) - t_blocked
					state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (thorns - t_blocked))
					log_lines.append("荊棘反彈 %d 點傷害給 %s。" % [thorns - t_blocked, state["enemy_name"]])
			else:
				# 連擊：hits 可選，預設 1。每段各自走 power/weak/vulnerable/block 管線
				# （block 跨段遞減、vulnerable 為 >0 即 ×1.5 不逐段衰減，與單擊一致）。
				var hits: int = max(1, int(effect.get("hits", 1)))
				var total_dealt: int = 0
				for _h: int in range(hits):
					var modified: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
					if int(state["enemy_vulnerable"]) > 0:
						modified = int(ceil(modified * 1.5))
					var blocked: int = min(int(state["enemy_block"]), modified)
					state["enemy_block"] = int(state["enemy_block"]) - blocked
					state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
					total_dealt += modified - blocked
				if hits > 1:
					log_lines.append("連擊 %d 段，共造成 %d 點傷害。" % [hits, total_dealt])
				else:
					log_lines.append("造成 %d 點傷害。" % total_dealt)
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
		"heal_party":
			# 全隊活著的成員回血（PAL1 五氣朝元等全體治療對應）
			var party_heal: int = amount + int(state.get("heal_bonus", 0))
			var players: Array = state.get("players", []) as Array
			var healed_any: bool = false
			for p_v: Variant in players:
				var p: Dictionary = p_v as Dictionary
				if int(p["hp"]) > 0:
					p["hp"] = min(int(p["max_hp"]), int(p["hp"]) + party_heal)
					healed_any = true
			if healed_any:
				# 同步 active alias
				var idx: int = int(state.get("active_player_index", 0))
				if idx < players.size():
					state["player_hp"] = int((players[idx] as Dictionary)["hp"])
				log_lines.append("全隊回復 %d 點生命。" % party_heal)
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
		"thorns":
			# Thorns 荊棘反擊：被攻擊時反彈傷害（不衰減，跨回合保留）
			state["player_thorns"] = int(state.get("player_thorns", 0)) + amount
			log_lines.append("獲得 %d 點荊棘。" % amount)
		"damage_debuff_bonus":
			# 杖流 payoff：對 debuff 敵加傷。基礎 amount + bonus_per_layer × (weak + vuln 層數)
			# 計算 base 後走標準傷害管線（power/weak/vuln/block）。
			var bonus_per: int = int(effect.get("bonus_per_layer", 0))
			var layers: int = int(state["enemy_weak"]) + int(state["enemy_vulnerable"])
			var raw: int = amount + bonus_per * layers
			var modified: int = max(0, raw + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
			if int(state["enemy_vulnerable"]) > 0:
				modified = int(ceil(modified * 1.5))
			var blocked: int = min(int(state["enemy_block"]), modified)
			state["enemy_block"] = int(state["enemy_block"]) - blocked
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
			log_lines.append("debuff 加成 +%d，造成 %d 點傷害。" % [bonus_per * layers, modified - blocked])
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
		"damage_all":
			# 對全部活著的敵人各造成 amount 傷害 hits 次（套用 power / weak / vulnerable / block）
			# 每段對每敵都跑完整管線（block 跨段遞減、vulnerable 為 >0 ×1.5 不衰減）。
			_sync_active_slot_from_alias(state)
			var hits: int = max(1, int(effect.get("hits", 1)))
			var slots: Array = state.get("enemies", []) as Array
			var totals: Array[int] = []
			for _i: int in range(slots.size()):
				totals.append(0)
			for _h: int in range(hits):
				for i: int in range(slots.size()):
					var slot: Dictionary = slots[i] as Dictionary
					if int(slot["hp"]) <= 0:
						continue
					var modified: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
					if int(slot["vulnerable"]) > 0:
						modified = int(ceil(modified * 1.5))
					var blocked: int = min(int(slot["block"]), modified)
					slot["block"] = int(slot["block"]) - blocked
					slot["hp"] = max(0, int(slot["hp"]) - (modified - blocked))
					totals[i] = int(totals[i]) + (modified - blocked)
			for i: int in range(slots.size()):
				var slot: Dictionary = slots[i] as Dictionary
				if int(totals[i]) > 0:
					if hits > 1:
						log_lines.append("對 %s 連擊 %d 段，共 %d 點傷害。" % [String(slot["name"]), hits, int(totals[i])])
					else:
						log_lines.append("對 %s 造成 %d 點傷害。" % [String(slot["name"]), int(totals[i])])
			_sync_alias_from_active_slot(state)
		"poison_all":
			_sync_active_slot_from_alias(state)
			var poison_amount: int = amount + int(state.get("poison_bonus", 0))
			var slots: Array = state.get("enemies", []) as Array
			for i: int in range(slots.size()):
				var slot: Dictionary = slots[i] as Dictionary
				if int(slot["hp"]) <= 0:
					continue
				slot["poison"] = int(slot["poison"]) + poison_amount
				log_lines.append("對 %s 施加 %d 層蠱毒。" % [String(slot["name"]), poison_amount])
			_sync_alias_from_active_slot(state)
		"weak_all":
			_sync_active_slot_from_alias(state)
			var slots: Array = state.get("enemies", []) as Array
			for i: int in range(slots.size()):
				var slot: Dictionary = slots[i] as Dictionary
				if int(slot["hp"]) <= 0:
					continue
				slot["weak"] = int(slot["weak"]) + amount
				log_lines.append("%s 受到 %d 層虛弱。" % [String(slot["name"]), amount])
			_sync_alias_from_active_slot(state)
		"vulnerable_all":
			_sync_active_slot_from_alias(state)
			var slots: Array = state.get("enemies", []) as Array
			for i: int in range(slots.size()):
				var slot: Dictionary = slots[i] as Dictionary
				if int(slot["hp"]) <= 0:
					continue
				slot["vulnerable"] = int(slot["vulnerable"]) + amount
				log_lines.append("%s 受到 %d 層破綻。" % [String(slot["name"]), amount])
			_sync_alias_from_active_slot(state)
		"summon":
			# 由 enemy action 觸發：將召喚請求加進 pending list，
			# BattleController.resolve_enemy_phase 結算完該敵 action 後處理。
			# effect 可指定 enemy_id；未指定 → BC 從該敵的 summon_pool 隨機抽。
			var count: int = max(1, int(effect.get("count", 1)))
			var pending: Array = state.get("pending_summons", []) as Array
			for _i: int in range(count):
				pending.append({"id": String(effect.get("enemy_id", ""))})
			state["pending_summons"] = pending
			log_lines.append("施展召喚之術。")
		"cure_poison":
			state["player_poison"] = 0
			log_lines.append("蠱毒已全數清除。")
		"cure_debuff":
			# 清除自身全部負面狀態：虛弱、破綻、蠱毒
			# PAL1 「冰心訣 / 靈血咒」對應效果
			state["player_weak"] = 0
			state["player_vulnerable"] = 0
			state["player_poison"] = 0
			log_lines.append("負面狀態已清除。")
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
