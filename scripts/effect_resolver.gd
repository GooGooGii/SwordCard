class_name EffectResolver
extends RefCounted

# 淫賊偷竊的衣物清單（依序循環，確保每次偷到不同件）。擊敗後逐項作為戰利品歸還展示。
const LECHER_GARMENTS: Array[Dictionary] = [
	{"name": "繡花肚兜", "desc": "大紅軟緞所製、繡著並蒂蓮的貼身肚兜，邊角還縫著一只小香囊，餘香隱隱。"},
	{"name": "鴛鴦羅帕", "desc": "一方杭羅手帕，雙面繡鴛鴦戲水，是閨中女兒貼身收於袖中的私物。"},
	{"name": "藕色中衣", "desc": "藕荷色的細棉中衣，質地輕薄、領口滾著銀線，是襯在外袍之內的裡衣。"},
	{"name": "月白綾褲", "desc": "月白色軟綾長褲，褲腳束以同色綢帶，行動時如水波微漾。"},
	{"name": "雲紋裹胸", "desc": "繡有流雲暗紋的束胸抹胸，以四條細帶繫於背後，是女子最貼身的衣物之一。"},
	{"name": "青絲髮帶", "desc": "一條沾著髮香的湖綠髮帶，原本束著女主角的烏黑長髮，此刻竟落入賊手。"},
	{"name": "鮫綃輕紗", "desc": "傳說鮫人所織的輕紗披帛，薄如蟬翼、入水不濕，價值連城的貼身披紗。"},
	{"name": "蜀錦腰封", "desc": "一條織金蜀錦的腰封，束於腰間勾勒身形，內側還暗藏一只繡荷包。"},
]

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
	slot["stunned"] = int(state.get("enemy_stunned", slot.get("stunned", 0)))
	slot["silenced"] = int(state.get("enemy_silenced", slot.get("silenced", 0)))
	slot["berserk"] = int(state.get("enemy_berserk", slot.get("berserk", 0)))

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
	state["enemy_stunned"] = int(slot.get("stunned", 0))
	state["enemy_silenced"] = int(slot.get("silenced", 0))
	state["enemy_berserk"] = int(slot.get("berserk", 0))

# 向後相容：tick 敵 + 玩家 poison（smoke 單元測試與舊呼叫點用）。
# 遊戲實際流程改用分離時機：tick_enemy_statuses 在敵人階段開始、
# tick_player_statuses 在玩家回合開始（對齊 StS 毒在受害者回合開始 tick）。
func tick_statuses(state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	log_lines.append_array(tick_enemy_statuses(state))
	log_lines.append_array(tick_player_statuses(state))
	return log_lines

# tick 全體敵人 slot 的 poison（多敵 aware）。在敵人出手「之前」呼叫 →
# 致命毒可在敵人攻擊前殺死它（StS 行為，對毒流角色關鍵）。
# state 無 "enemies" slots（如 smoke _make_state）時退回 alias 單敵路徑。
func tick_enemy_statuses(state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	var slots: Array = state.get("enemies", []) as Array
	if slots.is_empty():
		if int(state.get("enemy_poison", 0)) > 0:
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - int(state["enemy_poison"]))
			log_lines.append("中毒造成 %d 點傷害。" % int(state["enemy_poison"]))
			state["enemy_poison"] = max(0, int(state["enemy_poison"]) - 1)
		return log_lines
	_sync_active_slot_from_alias(state)
	for slot_v: Variant in slots:
		var slot: Dictionary = slot_v as Dictionary
		if int(slot["hp"]) <= 0:
			continue
		var p: int = int(slot["poison"])
		if p > 0:
			slot["hp"] = max(0, int(slot["hp"]) - p)
			log_lines.append("%s 中毒受到 %d 點傷害。" % [String(slot["name"]), p])
			slot["poison"] = max(0, p - 1)
	_sync_alias_from_active_slot(state)
	return log_lines

# tick active 玩家 poison（玩家回合開始）。
func tick_player_statuses(state: Dictionary) -> Array[String]:
	var log_lines: Array[String] = []
	if int(state.get("player_poison", 0)) > 0:
		state["player_hp"] = max(0, int(state["player_hp"]) - int(state["player_poison"]))
		log_lines.append("你受到 %d 點蠱毒傷害。" % int(state["player_poison"]))
		state["player_poison"] = max(0, int(state["player_poison"]) - 1)
	return log_lines

# 敵方對玩家造成傷害的共用公式（含 ascension 倍率 / 虛弱 / 破綻 / 減傷 / 格擋；不含 thorns）。
# 回傳實際扣血量。供 damage(from_enemy)、gamble_attack、lecher_steal 等共用。
func _enemy_hit_player(state: Dictionary, raw: int) -> int:
	var dmg_mult: float = float(state.get("enemy_damage_mult", 1.0))
	if dmg_mult != 1.0:
		raw = int(round(raw * dmg_mult))
	var modified: int = max(0, raw - int(state["enemy_weak"]))
	if int(state["player_vulnerable"]) > 0:
		modified = int(ceil(modified * 1.5))
	modified = max(0, modified - int(state.get("damage_taken_reduction", 0)))
	var blocked: int = min(int(state["player_block"]), modified)
	state["player_block"] = int(state["player_block"]) - blocked
	var dealt: int = modified - blocked
	state["player_hp"] = max(0, int(state["player_hp"]) - dealt)
	return dealt

# 當前 active 玩家是否為女性（淫賊判定用）。slot 的 is_female 由 BattleController.setup 寫入。
func _active_player_is_female(state: Dictionary) -> bool:
	var players: Array = state.get("players", []) as Array
	var idx: int = int(state.get("active_player_index", 0))
	if idx >= 0 and idx < players.size():
		return bool((players[idx] as Dictionary).get("is_female", false))
	return false

func _resolve_effect(effect: Dictionary, state: Dictionary, from_enemy: bool = false) -> Array[String]:
	var log_lines: Array[String] = []
	var kind: String = String(effect.get("kind", ""))
	var amount: int = int(effect.get("amount", 0))
	match kind:
		"damage":
			if from_enemy:
				# Ascension A2-4：敵人傷害倍率（一般/精英/boss），在 weak/vuln 前先放大基礎傷
				var dmg_mult: float = float(state.get("enemy_damage_mult", 1.0))
				if dmg_mult != 1.0:
					amount = int(round(amount * dmg_mult))
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
				var poison_on_atk: int = int(state.get("poison_on_attack", 0))  # 蠱刃：攻擊無格擋敵人每段施毒
				var atk_poison_added: int = 0
				var na_mult: int = max(1, int(state.get("next_attack_mult", 1)))  # 蓄劍式：下一張攻擊傷害翻倍
				for _h: int in range(hits):
					var modified: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
					if int(state["enemy_vulnerable"]) > 0:
						modified = int(ceil(modified * 1.5))
					modified *= na_mult
					var unblocked: bool = int(state["enemy_block"]) <= 0  # 此段命中時敵人無格擋
					var blocked: int = min(int(state["enemy_block"]), modified)
					state["enemy_block"] = int(state["enemy_block"]) - blocked
					state["enemy_hp"] = max(0, int(state["enemy_hp"]) - (modified - blocked))
					total_dealt += modified - blocked
					if poison_on_atk > 0 and unblocked:
						state["enemy_poison"] = int(state["enemy_poison"]) + poison_on_atk
						atk_poison_added += poison_on_atk
				if na_mult > 1:
					state["next_attack_mult"] = 1  # 消耗蓄勢
				if hits > 1:
					log_lines.append("連擊 %d 段，共造成 %d 點傷害。" % [hits, total_dealt])
				else:
					log_lines.append("造成 %d 點傷害。" % total_dealt)
				if atk_poison_added > 0:
					log_lines.append("蠱刃淬煉：施加 %d 層蠱毒。" % atk_poison_added)
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
		"weak":
			if from_enemy:
				if bool(state.get("player_weak_immune", false)):
					log_lines.append("（凝神）免疫虛弱。")
				else:
					state["player_weak"] = int(state["player_weak"]) + amount
					log_lines.append("你受到 %d 層虛弱。" % amount)
			else:
				state["enemy_weak"] = int(state["enemy_weak"]) + amount
				log_lines.append("敵人受到 %d 層虛弱。" % amount)
		"vulnerable":
			if from_enemy:
				if bool(state.get("player_vulnerable_immune", false)):
					log_lines.append("（金鐘罩）免疫破綻。")
				else:
					state["player_vulnerable"] = int(state["player_vulnerable"]) + amount
					log_lines.append("你受到 %d 層破綻。" % amount)
			else:
				state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) + amount
				log_lines.append("敵人受到 %d 層破綻。" % amount)
		"stun":
			# 暈眩：接下來 amount 個回合無法行動
			if from_enemy:
				if bool(state.get("player_stun_immune", false)):
					log_lines.append("（金剛座）免疫暈眩。")
				else:
					state["player_stunned"] = int(state.get("player_stunned", 0)) + amount
					log_lines.append("你陷入暈眩，%d 回合無法行動！" % amount)
			else:
				state["enemy_stunned"] = int(state.get("enemy_stunned", 0)) + amount
				log_lines.append("敵人陷入暈眩，%d 回合無法行動！" % amount)
		"gamble_attack":
			# 賭棍：擲骰比大小。莊家（敵）點數大 → 攻擊命中（amount 傷害）；否則願賭服輸給玩家 gold 銅錢。
			var g_gold: int = int(effect.get("gold", 0))
			var e_roll: int = randi() % 6 + 1
			var p_roll: int = randi() % 6 + 1
			log_lines.append("%s 擲骰比大小——莊家 %d 點、你 %d 點。" % [state["enemy_name"], e_roll, p_roll])
			if e_roll > p_roll:
				var gdealt: int = _enemy_hit_player(state, amount)
				log_lines.append("莊家贏了！%s 出手造成 %d 點傷害。" % [state["enemy_name"], gdealt])
			else:
				state["pending_player_gold"] = int(state.get("pending_player_gold", 0)) + g_gold
				log_lines.append("你贏了！%s 願賭服輸，丟下 %d 枚銅錢。" % [state["enemy_name"], g_gold])
		"lecher_steal":
			# 淫賊：先小傷，再對女性主角「偷衣物」→ 必中、每次偷不同的一件 + 虛弱 + 觸發演出。
			var l_dmg: int = int(effect.get("damage", 0))
			var l_weak: int = int(effect.get("weak", max(1, amount)))
			if l_dmg > 0:
				var ldealt: int = _enemy_hit_player(state, l_dmg)
				log_lines.append("%s 偷襲，造成 %d 點傷害。" % [state["enemy_name"], ldealt])
			if _active_player_is_female(state):
				var stolen: Array = state.get("lecher_stolen", []) as Array
				# 依已偷件數循環取下一件，確保每次不同
				var garment: Dictionary = LECHER_GARMENTS[stolen.size() % LECHER_GARMENTS.size()]
				stolen.append(garment.duplicate())
				state["lecher_stolen"] = stolen
				state["lecher_event"] = int(state.get("lecher_event", 0)) + 1
				state["lecher_last_garment"] = String(garment.get("name", "衣物"))
				if not bool(state.get("player_weak_immune", false)):
					state["player_weak"] = int(state["player_weak"]) + l_weak
				log_lines.append("%s 身形一閃飛掠而過，竟偷走了「%s」！羞憤之下受到 %d 層虛弱。" % [state["enemy_name"], String(garment.get("name", "衣物")), l_weak])
			else:
				log_lines.append("%s 賊手撲空，這位可不是好惹的。" % state["enemy_name"])
		"stun_chance":
			# 機率暈眩（惡霸悶棍）。
			var s_chance: float = float(effect.get("chance", 0.3))
			if randf() < s_chance:
				if bool(state.get("player_stun_immune", false)):
					log_lines.append("（金剛座）免疫暈眩。")
				else:
					state["player_stunned"] = int(state.get("player_stunned", 0)) + max(1, amount)
					log_lines.append("一記悶棍正中要害，你被打暈，%d 回合無法行動！" % max(1, amount))
		"silence":
			# 禁言：接下來 amount 個回合無法施放法術（無傷害的招式）
			if from_enemy:
				if bool(state.get("player_silence_immune", false)):
					log_lines.append("（通靈玉）免疫禁言。")
				else:
					state["player_silenced"] = int(state.get("player_silenced", 0)) + amount
					log_lines.append("你被禁言，%d 回合無法施法！" % amount)
			else:
				state["enemy_silenced"] = int(state.get("enemy_silenced", 0)) + amount
				log_lines.append("敵人被禁言，%d 回合無法施法！" % amount)
		"berserk":
			# 瘋魔：接下來 amount 個回合失控（隨機目標、可能呆立）
			if from_enemy:
				if bool(state.get("player_berserk_immune", false)):
					log_lines.append("（定魂珠）免疫瘋魔。")
				else:
					state["player_berserk"] = int(state.get("player_berserk", 0)) + amount
					log_lines.append("你陷入瘋魔，%d 回合無法控制！" % amount)
			else:
				state["enemy_berserk"] = int(state.get("enemy_berserk", 0)) + amount
				log_lines.append("敵人陷入瘋魔，%d 回合無法控制！" % amount)
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
		"poison_engine":
			# 毒引擎（StS Noxious Fumes 式）：持久能力，每回合開始自動對全體敵人施毒。
			# 實際每回合施毒由 BattleController.start_turn 讀 state["poison_per_turn"] 執行。
			state["poison_per_turn"] = int(state.get("poison_per_turn", 0)) + amount
			log_lines.append("瘴蠱纏身：每回合開始對所有敵人施加 %d 層蠱毒。" % amount)
		"poison_on_attack":
			# 蠱刃（持久能力）：攻擊無格擋的敵人時每段施 amount 層蠱毒。
			# 實際施毒在 damage / damage_all 路徑讀 state["poison_on_attack"] 執行。
			state["poison_on_attack"] = int(state.get("poison_on_attack", 0)) + amount
			log_lines.append("蠱刃淬煉：攻擊無格擋的敵人時，每次攻擊施加 %d 層蠱毒。" % amount)
		"corpse_poison":
			# 屍蠱（持久能力）：中毒的敵人死亡時，殘餘蠱毒隨機轉移給另一個敵人。
			# 實際轉移在 BattleController._process_corpse_poison() 執行（需多敵 + RNG）。
			state["corpse_poison"] = true
			log_lines.append("蠱蟲寄屍：中毒的敵人死亡時，殘餘蠱毒將隨機轉移給其他敵人。")
		"poison_multiply":
			# 蠱毒催化（StS Catalyst 式）：使目標敵人現有蠱毒層數翻 amount 倍。
			var cur_poison: int = int(state["enemy_poison"])
			if cur_poison > 0:
				state["enemy_poison"] = cur_poison * amount
				log_lines.append("蠱毒催化：%s 的蠱毒翻為 %d 層。" % [state["enemy_name"], cur_poison * amount])
			else:
				log_lines.append("蠱毒催化：目標無蠱毒，無效。")
		"block_multiply":
			# 聚靈訣（StS Entrench 式）：當前護體翻 amount 倍。
			var cur_block: int = int(state["player_block"])
			if cur_block > 0:
				state["player_block"] = cur_block * amount
				log_lines.append("聚靈：護體翻為 %d 點。" % (cur_block * amount))
			else:
				log_lines.append("聚靈：目前無護體，無效。")
		"power_per_turn":
			# 靈犀訣（StS Demon Form 式）：持久能力，每回合開始 +amount 力量。
			# 實際每回合加力由 BattleController.start_turn 讀 state["power_per_turn"] 執行。
			state["power_per_turn"] = int(state.get("power_per_turn", 0)) + amount
			log_lines.append("靈犀訣：每回合開始攻擊力 +%d。" % amount)
		"block_per_turn":
			# 靈光普照（StS Metallicize 式）：持久能力，每回合開始得 amount 護體。
			state["block_per_turn"] = int(state.get("block_per_turn", 0)) + amount
			log_lines.append("靈光普照：每回合開始獲得 %d 護體。" % amount)
		"end_turn_damage_all":
			# 五雷轟頂（StS Combust 式）：持久能力，回合結束對全體敵人造成 amount 傷害。
			# 實際結算由 BattleController.begin_enemy_phase 讀 state["end_turn_damage"] 執行。
			state["end_turn_damage"] = int(state.get("end_turn_damage", 0)) + amount
			log_lines.append("五雷蓄勢：每回合結束對所有敵人降下 %d 點雷傷。" % amount)
		"next_attack_mult":
			# 蓄劍式（StS Setup/Vigor 式）：下一張攻擊牌傷害翻 amount 倍（由 damage 路徑消耗）。
			state["next_attack_mult"] = max(1, amount)
			log_lines.append("蓄劍式：下一張攻擊牌傷害變為 %d 倍。" % max(1, amount))
		"block_per_attack":
			# 劍舞架式（持久能力）：本場每出一張攻擊牌獲得 amount 護體。
			# 實際加護體由 BattleController.play_card 讀 state["block_per_attack"] 執行。
			state["block_per_attack"] = int(state.get("block_per_attack", 0)) + amount
			log_lines.append("劍舞架式：每出一張攻擊牌獲得 %d 護體。" % amount)
		"self_block_bonus":
			# 鐵骨樁（StS Dexterity 式）：本場每次獲得護體額外 +amount（block 效果讀 block_bonus）。
			state["block_bonus"] = int(state.get("block_bonus", 0)) + amount
			log_lines.append("鐵骨樁：每次獲得護體額外 +%d。" % amount)
		"upgrade_hand":
			# 臨陣磨槍（StS Armaments+ 式）：升級手上所有牌（本場）。由 BattleController 執行。
			state["upgrade_hand_pending"] = true
			log_lines.append("臨陣磨槍：手上所有牌升級。")
		"copy_attack":
			# 御劍相承（StS Dual Wield 式）：複製手上一張攻擊牌。由 BattleController 執行。
			state["copy_attack_pending"] = true
			log_lines.append("御劍相承：複製手上一張攻擊牌。")
		"spawn_top_tokens":
			# 劍氣縱橫（StS Shiv/置頂 式）：生成 amount 道「劍氣」置於抽牌堆頂。由 BattleController 執行。
			state["spawn_top_tokens"] = int(state.get("spawn_top_tokens", 0)) + amount
			log_lines.append("劍氣縱橫：%d 道劍氣納入抽牌堆頂。" % amount)
		"combo_strike":
			# 連打引擎（StS Panache 式）：持久能力，本回合每出 threshold 張牌對全體敵人造成傷害。
			# 實際計數與結算由 BattleController.play_card 讀 state["combo_strike_*"] 執行。
			state["combo_strike_damage"] = int(state.get("combo_strike_damage", 0)) + amount
			state["combo_strike_threshold"] = max(1, int(effect.get("threshold", 5)))
			log_lines.append("劍意如虹：本回合每出 %d 張牌，對全體敵人造成 %d 點傷害。" % [int(state["combo_strike_threshold"]), amount])
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
		"consume_energy_damage_all":
			var spent_all: int = int(state["energy"])
			state["energy"] = 0
			var base_all: int = max(0, amount * spent_all - int(state["player_weak"]))
			var ce_slots: Array = state.get("enemies", []) as Array
			if ce_slots.is_empty():
				var dmg_single: int = base_all
				if int(state["enemy_vulnerable"]) > 0:
					dmg_single = int(ceil(dmg_single * 1.5))
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - dmg_single)
				log_lines.append("耗盡靈力，造成 %d 點傷害。" % dmg_single)
			else:
				_sync_active_slot_from_alias(state)
				for ce_i: int in range(ce_slots.size()):
					var ce_slot: Dictionary = ce_slots[ce_i] as Dictionary
					if int(ce_slot["hp"]) <= 0:
						continue
					var ce_mod: int = base_all
					if int(ce_slot["vulnerable"]) > 0:
						ce_mod = int(ceil(ce_mod * 1.5))
					var ce_blk: int = min(int(ce_slot["block"]), ce_mod)
					ce_slot["block"] = int(ce_slot["block"]) - ce_blk
					ce_slot["hp"] = max(0, int(ce_slot["hp"]) - (ce_mod - ce_blk))
					log_lines.append("耗盡靈力，對 %s 造成 %d 點傷害。" % [String(ce_slot["name"]), ce_mod - ce_blk])
				_sync_alias_from_active_slot(state)
		"consume_energy_damage":
			var spent: int = int(state["energy"])
			state["energy"] = 0
			var damage: int = max(0, amount * spent - int(state["player_weak"]))
			if int(state["enemy_vulnerable"]) > 0:
				damage = int(ceil(damage * 1.5))
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - damage)
			log_lines.append("耗盡靈力，造成 %d 點傷害。" % damage)
		"poison_burst":
			# 引爆「全部」蠱毒（符合卡面「引爆全部蠱毒」）：對每隻中毒敵各引爆自己的毒層。
			# 多敵時是 AOE 清場利器；單敵時等同舊行為。無 slots（smoke）走 alias fallback。
			var burst_slots: Array = state.get("enemies", []) as Array
			if burst_slots.is_empty():
				var burst: int = int(state["enemy_poison"]) * amount
				state["enemy_hp"] = max(0, int(state["enemy_hp"]) - burst)
				state["enemy_poison"] = 0
				log_lines.append("引爆蠱毒，造成 %d 點傷害。" % burst)
			else:
				_sync_active_slot_from_alias(state)
				for slot_v: Variant in burst_slots:
					var slot: Dictionary = slot_v as Dictionary
					if int(slot["hp"]) <= 0:
						continue
					var p: int = int(slot["poison"])
					if p <= 0:
						continue
					var b: int = p * amount
					slot["hp"] = max(0, int(slot["hp"]) - b)
					slot["poison"] = 0
					log_lines.append("引爆 %s 的蠱毒，造成 %d 點傷害。" % [String(slot["name"]), b])
				_sync_alias_from_active_slot(state)
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
			var poison_on_atk_all: int = int(state.get("poison_on_attack", 0))  # 蠱刃：AOE 每段對無格擋敵人施毒
			var na_mult_all: int = max(1, int(state.get("next_attack_mult", 1)))  # 蓄劍式：下一張攻擊翻倍
			for _h: int in range(hits):
				for i: int in range(slots.size()):
					var slot: Dictionary = slots[i] as Dictionary
					if int(slot["hp"]) <= 0:
						continue
					var modified: int = max(0, amount + int(state["player_power"]) - int(state["player_weak"])) + int(state.get("damage_out_bonus", 0))
					if int(slot["vulnerable"]) > 0:
						modified = int(ceil(modified * 1.5))
					modified *= na_mult_all
					var unblocked: bool = int(slot["block"]) <= 0
					var blocked: int = min(int(slot["block"]), modified)
					slot["block"] = int(slot["block"]) - blocked
					slot["hp"] = max(0, int(slot["hp"]) - (modified - blocked))
					totals[i] = int(totals[i]) + (modified - blocked)
					if poison_on_atk_all > 0 and unblocked:
						slot["poison"] = int(slot["poison"]) + poison_on_atk_all
			if na_mult_all > 1:
				state["next_attack_mult"] = 1  # 消耗蓄勢
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
		"gain_curse_player":
			# 敵方施咒：把指定 curse 加入 pending list，由 main.gd 在 resolve_enemy_phase 後
			# 寫入 run_state.character_decks（避免 BattleController 直接依賴 RunState）。
			var curse_id: String = String(effect.get("curse_id", ""))
			if not curse_id.is_empty():
				var pending_curses: Array = state.get("pending_player_curses", []) as Array
				pending_curses.append(curse_id)
				state["pending_player_curses"] = pending_curses
				var curse_data: Dictionary = CurseCatalog.by_id(curse_id)
				var curse_name: String = String(curse_data.get("display_name", curse_id))
				log_lines.append("詛咒降臨：「%s」！" % curse_name)
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
					# 偷竊有 85% 的成功率
					if randf() < 0.15:
						log_lines.append("（出手未中，什麼也沒偷到。）")
					else:
						var idx: int = randi() % loot_table.size()
						var item: Dictionary = (loot_table[idx] as Dictionary).duplicate()
						loot_table.remove_at(idx)
						state["steal_result"] = item
						log_lines.append("偷到了%s！" % String(item.get("display_name", "某物")))
	return log_lines
