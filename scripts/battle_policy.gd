class_name BattlePolicy
extends RefCounted

# 平衡測試共用的「會玩的」出牌啟發式（取代 smoke test 的隨機出牌）。
# 直接操作 BattleController（零視圖轉換），每次呼叫回傳「當下最佳動作」，
# 呼叫端套用後再問下一個，直到回傳 end。
#
# 決策優先序（與 ai_run_engine 的 view 版 policy 同精神，資料來源改為真實 state）：
#   1. 毒引爆時機（能斬殺才炸 / 無引擎落袋為安 / 超量變現）
#   2. 致命威脅：能殺威脅源就殺，否則疊最大格擋
#   3. 集火斬殺（含 AOE 多殺評估）
#   4. 重擊將至先擋
#   5. 低血先用治療牌
#   6. 發展型（能力/抽牌/能量）安全時早放
#   7. 疊毒 → 最大輸出（≥2 敵時 AOE 總傷優先）→ 保底出牌
#
# 完全 deterministic（不用 randi；同 seed 同 deck 同敵 → 同決策序列），
# 平衡 regression 的可重現性不變。
#
# 回傳格式：
#   {"kind": "play", "card": CardData, "target": int}  target=-1 表示不需指定敵人
#   {"kind": "end"}

static func next_action(bc) -> Dictionary:
	var s: Dictionary = bc.state
	var energy: int = int(s.get("energy", 0))
	var hp: int = int(s.get("player_hp", 1))
	var block: int = int(s.get("player_block", 0))
	var max_hp: int = int(s.get("player_max_hp", 1))

	# ── 敵情 ──
	var enemies: Array = s.get("enemies", []) as Array
	var alive: Array = []  # {idx, ehp, poison, threat}
	var incoming: int = 0
	for i: int in range(enemies.size()):
		var slot: Dictionary = enemies[i] as Dictionary
		if int(slot.get("hp", 0)) <= 0:
			continue
		var action: Dictionary = bc._action_for_enemy(i)
		var threat: int = 0
		if not action.is_empty():
			threat = int(CardFormat.predict_enemy_damage(action, s).get("dealt", 0))
		alive.append({
			"idx": i,
			"ehp": int(slot.get("hp", 0)) + int(slot.get("block", 0)),
			"poison": int(slot.get("poison", 0)),
			"threat": threat,
		})
		incoming += threat
	if alive.is_empty():
		return {"kind": "end"}

	# ── 手牌分類（只看負擔得起的；preview 已含 power/weak/vuln 修正）──
	var attacks: Array = []   # {card, dmg, aoe, cost}
	var blocks: Array = []    # {card, val}
	var heals: Array = []     # {card, val, cost}
	var poisons: Array = []   # {card, val}
	var bursts: Array = []    # {card}
	var engines: Array = []   # {card, cost} 能力/抽牌/能量
	var debuffs: Array = []   # {card} 純 debuff（弱/破綻/控制）——要在攻擊「之前」打（破綻 1.5× 才吃得到）
	for card: CardData in bc.deck.hand:
		var cost: int = bc.effective_card_cost(card)
		if cost > energy:
			continue
		var dmg: int = 0
		var aoe: bool = false
		var blk: int = 0
		var heal_v: int = 0
		var poi: int = 0
		for p: Dictionary in CardFormat.live_effect_previews(card, s):
			var v: int = int(p["value"]) * max(1, int(p["hits"]))
			match String(p["label"]):
				"傷害": dmg += v
				"護體": blk += v
				"治療": heal_v += v
				"蠱毒": poi += v
		var has_burst: bool = false
		var is_engine: bool = card.card_type == "power"
		var is_debuff: bool = false
		for effect: Dictionary in card.effects:
			var kind: String = String(effect.get("kind", ""))
			if kind == "poison_burst":
				has_burst = true
			if kind.ends_with("_all") and kind.begins_with("damage"):
				aoe = true
			if kind in ["draw", "energy", "draw_on_attack", "draw_on_skill", "power", "power_per_turn", "next_attack_mult", "spawn_top_tokens", "upgrade_hand"]:
				is_engine = true
			if kind in ["weak", "weak_all", "vulnerable", "vulnerable_all", "stun", "silence", "berserk"]:
				is_debuff = true
		if has_burst:
			bursts.append({"card": card})
		if dmg > 0:
			attacks.append({"card": card, "dmg": dmg, "aoe": aoe, "cost": cost})
		if blk > 0:
			blocks.append({"card": card, "val": blk})
		if heal_v > 0:
			heals.append({"card": card, "val": heal_v, "cost": cost})
		if poi > 0 and dmg == 0:
			poisons.append({"card": card, "val": poi})
		if is_engine and dmg == 0 and blk == 0:
			engines.append({"card": card, "cost": cost})
		elif is_debuff and dmg == 0 and blk == 0 and poi == 0:
			debuffs.append({"card": card})

	# ── 集火目標：可斬殺者優先（挑 ehp 最高的可斬殺者=賺最多），否則威脅最高 ──
	var best_single: Dictionary = {}
	for a: Variant in attacks:
		if best_single.is_empty() or int((a as Dictionary)["dmg"]) > int(best_single["dmg"]):
			best_single = a as Dictionary
	var best_dmg: int = int(best_single.get("dmg", 0))
	var focus: Dictionary = {}
	var focus_killable: bool = false
	for e: Variant in alive:
		var ed: Dictionary = e as Dictionary
		if best_dmg >= int(ed["ehp"]):
			if not focus_killable or int(ed["ehp"]) > int(focus.get("ehp", 0)):
				focus = ed
				focus_killable = true
	if not focus_killable:
		for e: Variant in alive:
			var ed: Dictionary = e as Dictionary
			if focus.is_empty() or int(ed["threat"]) > int(focus.get("threat", -1)):
				focus = ed
	var focus_idx: int = int(focus.get("idx", 0))

	var lethal: bool = incoming > hp + block
	var heavy: bool = incoming >= int(max_hp * 0.33)
	var has_poison_engine: bool = int(s.get("poison_per_turn", 0)) > 0

	# 1. 毒引爆
	if not bursts.is_empty():
		var burst_dmg: int = int(focus.get("poison", 0)) * 3
		var overstacked: bool = int(focus.get("poison", 0)) >= (18 if has_poison_engine else 10)
		if burst_dmg >= int(focus.get("ehp", 1)) or overstacked:
			return {"kind": "play", "card": (bursts[0] as Dictionary)["card"], "target": focus_idx}
	# 2. 致命威脅：殺得掉威脅源就殺，否則最大格擋
	if lethal:
		if focus_killable and not best_single.is_empty():
			return {"kind": "play", "card": best_single["card"], "target": focus_idx}
		if not blocks.is_empty():
			return {"kind": "play", "card": (_max_by(blocks, "val"))["card"], "target": -1}
	# 3. 集火斬殺
	if focus_killable and not best_single.is_empty():
		return {"kind": "play", "card": best_single["card"], "target": focus_idx}
	# 4. 重擊將至先擋（擋到夠為止）
	if heavy and block < incoming and not blocks.is_empty():
		return {"kind": "play", "card": (_max_by(blocks, "val"))["card"], "target": -1}
	# 5. 低血（<50%）用治療牌
	if hp < int(max_hp * 0.5) and not heals.is_empty():
		return {"kind": "play", "card": (heals[0] as Dictionary)["card"], "target": -1}
	# 6. 發展型早放（無致命威脅時滾雪球；便宜的先）
	if not engines.is_empty():
		return {"kind": "play", "card": (_min_by(engines, "cost"))["card"], "target": -1}
	# 7. 疊毒
	if not poisons.is_empty():
		return {"kind": "play", "card": (_max_by(poisons, "val"))["card"], "target": focus_idx}
	# 7.5 純 debuff（弱/破綻/控制）在攻擊之前打：破綻先上、後續攻擊吃 1.5×；
	#     focus 已有 ≥2 層 debuff 就不再疊（邊際遞減，省牌打輸出）
	if not debuffs.is_empty() and not attacks.is_empty():
		var focus_layers: int = 0
		for i: int in range(enemies.size()):
			var slot2: Dictionary = enemies[i] as Dictionary
			if i == focus_idx:
				focus_layers = int(slot2.get("weak", 0)) + int(slot2.get("vulnerable", 0))
		if focus_layers < 2:
			return {"kind": "play", "card": (debuffs[0] as Dictionary)["card"], "target": focus_idx}
	# 8. 最大輸出：≥2 敵時 AOE 以「總傷 = 單體傷 × 敵數」比較
	if not attacks.is_empty():
		var best: Dictionary = {}
		var best_score: int = -1
		for a: Variant in attacks:
			var ad: Dictionary = a as Dictionary
			var score: int = int(ad["dmg"]) * (alive.size() if bool(ad["aoe"]) else 1)
			if score > best_score:
				best_score = score
				best = ad
		return {"kind": "play", "card": best["card"], "target": focus_idx}
	# 9. 沒攻擊可打 → 把格擋疊掉（避免擱置資源）
	if not blocks.is_empty():
		return {"kind": "play", "card": (blocks[0] as Dictionary)["card"], "target": -1}
	# 10. 保底：任何打得起的牌
	for card: CardData in bc.deck.hand:
		if bc.effective_card_cost(card) <= energy:
			var target: int = focus_idx if CardFormat.requires_enemy_target(card) else -1
			return {"kind": "play", "card": card, "target": target}
	return {"kind": "end"}

static func _max_by(arr: Array, key: String) -> Dictionary:
	var best: Dictionary = arr[0] as Dictionary
	for v: Variant in arr:
		if int((v as Dictionary).get(key, 0)) > int(best.get(key, 0)):
			best = v as Dictionary
	return best

static func _min_by(arr: Array, key: String) -> Dictionary:
	var best: Dictionary = arr[0] as Dictionary
	for v: Variant in arr:
		if int((v as Dictionary).get(key, 0)) < int(best.get(key, 0)):
			best = v as Dictionary
	return best
