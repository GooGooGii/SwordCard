class_name AiRunEngine
extends RefCounted

# ──────────────────────────────────────────────────────────────────────────
# AI-Agent-Driven Full-Run Balance Engine
# ---------------------------------------------------------------------------
# 一個「無 UI、可被外部一步步驅動」的 run 引擎。重用真實的底層系統
# （RunState / MapGenerator / BattleController / EffectResolver / 各 catalog），
# 把散在 main.gd UI handler 裡的決策「套用」邏輯在此最小重建（只動 RunState）。
#
# 核心是一個同步狀態機（不用 await，方便 smoke test 直接驅動）：
#   var view = engine.next_view()      # 取得當前決策點（kind/state/options）
#   if view["kind"] == "done": ...結束
#   engine.apply(choice)               # 套用我的決策、推進到下一個決策點
#
# tools/ai_run.gd 用檔案協定（_ai_view.json / _ai_cmd.json）把 view 丟給我、
# 讀回我的 choice；smoke_test 用內建啟發式 policy 直接同步跑完一場驗證不爛掉。
#
# 戰鬥 100% 用真實 BattleController（平衡問題的核心，零失真）。
# 獎勵 / 加護 / 休息 重用純生成器 + 在此重建 RunState 變更。
# 事件 / 商店：見對應 phase（Phase 4 起逐步擴充；初版以保守選項推進）。
# ──────────────────────────────────────────────────────────────────────────

var run_state: RunState
var transcript: Array = []          # 逐事件紀錄，run 結束輸出
var result: Dictionary = {}         # 終局摘要
var _selected_character: CharacterData   # 隊長（沿用 main.gd 的 selected_character 語意）

# 狀態機
var _phase: String = "init"         # init/boon/map/battle/boss_relic/reward/rest/event/shop/done
var battle: BattleController = null
var _ctx: Dictionary = {}           # phase-specific 暫存（reward cards、boss flag、event tree 位置…）
var _step_count: int = 0
const MAX_STEPS: int = 100000        # 跑飛防呆
# 啟發式 policy「心中想組成的牌組」目標張數，依流派而異（起始皆 12）：
# 速攻/多段要精簡（抽牌一致性）、引擎/續航流要厚一點（湊齊 win-con 需要更多牌）。
# 達標就略過獎勵保持精簡。實測：齊頭 18 張會餓死阿奴毒流（→0%）、卻大補李逍遙速攻。
const AUTO_TARGET_DECK_BY_ID: Dictionary = {
	"li_xiaoyao": 17,   # 力量+多段速攻：越精簡越穩定抽到連擊
	"zhao_linger": 18,  # 術法 AOE：中庸
	"lin_yueru": 26,    # 續航+反擊：偏好厚牌組（工具/防禦/反擊牌多多益善，實測精簡反而變弱）
	"anu": 23,          # 毒流引擎：需要多張毒源才能 ramp 起來
}
const AUTO_TARGET_DECK_DEFAULT: int = 18

# ──────────────────────────────────────────────────────────────────────────
# 建立 run（鏡像 main.gd start_run，去掉 UI / boon 畫面）
# ──────────────────────────────────────────────────────────────────────────
func setup(party_ids: Array, ascension: int = 0, run_seed: int = 0) -> void:
	var party: Array[CharacterData] = []
	for id_v: Variant in party_ids:
		var c: CharacterData = _character_by_id(String(id_v))
		if c != null:
			party.append(c.clone())
	assert(not party.is_empty(), "AiRunEngine.setup needs at least 1 valid character id")
	_selected_character = party[0]
	run_state = RunState.new()
	run_state.ascension_level = ascension
	var seed_for_run: int = run_seed if run_seed != 0 else randi()
	seed(seed_for_run)
	run_state.map_seed = seed_for_run
	run_state.init_for(party)
	var hp_mult: float = Ascension.starting_hp_multiplier(run_state.ascension_level)
	var hp_flat: int = Ascension.max_hp_flat_penalty(run_state.ascension_level)
	if hp_mult != 1.0 or hp_flat > 0:
		for i: int in range(run_state.character_max_hps.size()):
			var new_max: int = max(1, int(round(float(run_state.character_max_hps[i]) * hp_mult)) - hp_flat)
			run_state.character_max_hps[i] = new_max
			run_state.character_hps[i] = new_max
	# A10：開局帶 1 張詛咒（妖債）
	if Ascension.starts_cursed(run_state.ascension_level) and not run_state.character_decks.is_empty():
		(run_state.character_decks[0] as Array).append(CurseCatalog.make_card("yao_zhai"))
	run_state.encounter_choices = _make_encounter_choices()
	# 注意：不呼叫 randomize()。平衡測試要「同 seed 完全可重現」——保持 seeded RNG 串流貫穿
	# 整個 run（抽牌 / 敵人行動皆確定性），policy A/B 比較才乾淨。（real game 在 main.gd 才
	# randomize；此引擎僅供離線量測。）
	seed(seed_for_run)
	_phase = "boon"
	_ctx = {"boons": _make_boon_choices()}
	_log("run_start", {
		"party": party_ids.duplicate(),
		"ascension": ascension,
		"seed": seed_for_run,
	})

func _character_by_id(id: String) -> CharacterData:
	for c: CharacterData in GameData.characters():
		if c.id == id:
			return c
	return null

func _make_encounter_choices() -> Array[Array]:
	var act_enemies: Array[EnemyData] = GameData.enemies_for_act(run_state.act)
	var act_boss: Array[EnemyData] = []
	act_boss.append(GameData.boss_for_act(run_state.act))
	var char_ids: Array[String] = []
	for c: CharacterData in run_state.characters:
		char_ids.append(c.id)
	return MapGenerator.generate(act_enemies, act_boss, char_ids, run_state.act)

# ──────────────────────────────────────────────────────────────────────────
# 主驅動 API
# ──────────────────────────────────────────────────────────────────────────
func next_view() -> Dictionary:
	_step_count += 1
	if _step_count > MAX_STEPS:
		_finish(false, "max_steps_exceeded")
	match _phase:
		"boon":   return _view_boon()
		"map":    return _view_map()
		"battle": return _view_battle()
		"boss_relic": return _view_boss_relic()
		"reward": return _view_reward()
		"rest":   return _view_rest()
		"event":  return _view_event()
		"shop":   return _view_shop()
		"done":   return _view_done()
	return _view_done()

func apply(choice: Variant) -> void:
	match _phase:
		"boon":   _apply_boon_choice(choice)
		"map":    _apply_map_choice(choice)
		"battle": _apply_battle_choice(choice)
		"boss_relic": _apply_boss_relic_choice(choice)
		"reward": _apply_reward_choice(choice)
		"rest":   _apply_rest_choice(choice)
		"event":  _apply_event_choice(choice)
		"shop":   _apply_shop_choice(choice)
		_: pass

# ──────────────────────────────────────────────────────────────────────────
# 共用：run 上下文摘要（每個 view 都帶，給決策者全局視野）
# ──────────────────────────────────────────────────────────────────────────
func _run_context() -> Dictionary:
	var party: Array = []
	for i: int in range(run_state.characters.size()):
		party.append({
			"id": run_state.characters[i].id,
			"name": run_state.characters[i].display_name,
			"hp": run_state.character_hps[i],
			"max_hp": run_state.character_max_hps[i],
			"level": run_state.character_levels[i] if i < run_state.character_levels.size() else 1,
			"deck_size": (run_state.character_decks[i] as Array).size(),
		})
	var relic_names: Array = []
	for r: RelicData in run_state.relics:
		relic_names.append(r.display_name)
	var potion_names: Array = []
	for p: Dictionary in run_state.potions:
		potion_names.append(String(p.get("display_name", "?")))
	return {
		"act": run_state.act,
		"floor": run_state.encounter_index,
		"total_floors": run_state.encounter_choices.size(),
		"gold": run_state.gold,
		"ascension": run_state.ascension_level,
		"party": party,
		"relics": relic_names,
		"potions": potion_names,
		"observe_tokens": run_state.observe_tokens,
	}

# ──────────────────────────────────────────────────────────────────────────
# BOON（起始加護）
# ──────────────────────────────────────────────────────────────────────────
const BOON_POOL: Array[Dictionary] = [
	{"id": "extra_gold",      "name": "行囊充實",  "desc": "起始銅錢 +200。"},
	{"id": "extra_card",      "name": "多學一技",  "desc": "從主角技能池隨機習得 1 張招式。"},
	{"id": "random_relic",    "name": "機緣遺物",  "desc": "獲得 1 件隨機普通遺物。"},
	{"id": "remove_starter",  "name": "去蕪存菁",  "desc": "從主角起始牌組移除 1 張隨機基礎牌。"},
	{"id": "hp_up",           "name": "體魄強健",  "desc": "全隊最大 HP +12。"},
	{"id": "starting_potion", "name": "備藥出行",  "desc": "起始攜帶 1 瓶回春丹。"},
	{"id": "curse_relic",     "name": "禍福相依",  "desc": "接受 1 張詛咒，換 1 件稀有遺物。"},
]
const BOON_COUNT: int = 4

func _make_boon_choices() -> Array:
	var pool: Array = BOON_POOL.duplicate()
	pool.shuffle()
	var out: Array = []
	for i: int in range(min(BOON_COUNT, pool.size())):
		out.append(pool[i])
	return out

func _view_boon() -> Dictionary:
	var options: Array = []
	for b: Dictionary in (_ctx.get("boons", []) as Array):
		options.append({"id": b["id"], "label": b["name"], "detail": b["desc"]})
	options.append({"id": "skip", "label": "跳過", "detail": "不選加護。"})
	return {"kind": "boon", "phase_label": "起始加護", "run": _run_context(),
		"state": {}, "options": options}

func _apply_boon_choice(choice: Variant) -> void:
	var boon_id: String = _choice_id(choice)
	if boon_id != "skip" and not boon_id.is_empty():
		_apply_boon(boon_id)
	_log("boon", {"choice": boon_id})
	_phase = "map"

# 鏡像 main.gd:_apply_boon 的核心 RunState 變更（去掉 UI rewards 顯示）
func _apply_boon(boon_id: String) -> void:
	match boon_id:
		"extra_gold":
			run_state.gold += 200
		"extra_card":
			var pool: Array[CardData] = _selected_character.reward_pool.duplicate()
			if not pool.is_empty():
				pool.shuffle()
				(run_state.character_decks[0] as Array).append((pool[0] as CardData).clone())
		"random_relic":
			var rp: Array[RelicData] = []
			for r: RelicData in RelicCatalog.generals():
				if r.rarity == "common" and not run_state.has_relic(r.id):
					rp.append(r)
			if not rp.is_empty():
				rp.shuffle()
				run_state.add_relic(rp[0].clone())
		"remove_starter":
			var d: Array = run_state.character_decks[0] as Array
			var basics: Array[int] = []
			for i: int in range(d.size()):
				if (d[i] as CardData).rarity == "basic":
					basics.append(i)
			if not basics.is_empty():
				basics.shuffle()
				d.remove_at(basics[0])
		"hp_up":
			for i: int in range(run_state.characters.size()):
				run_state.character_max_hps[i] += 12
				run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + 12)
		"starting_potion":
			if run_state.potions.size() < run_state.effective_potion_slots():
				var h: Dictionary = PotionCatalog.by_id("huichun_dan")
				if not h.is_empty():
					run_state.potions.append(h.duplicate())
		"curse_relic":
			var all_curses: Array[String] = []
			for c: Dictionary in CurseCatalog.all():
				all_curses.append(String(c["id"]))
			if not all_curses.is_empty():
				all_curses.shuffle()
				var cc: CardData = CurseCatalog.make_card(all_curses[0])
				if cc != null:
					(run_state.character_decks[0] as Array).append(cc)
			var rare: Array[RelicData] = []
			for r2: RelicData in RelicCatalog.generals():
				if r2.rarity == "rare" and not run_state.has_relic(r2.id):
					rare.append(r2)
			if not rare.is_empty():
				rare.shuffle()
				run_state.add_relic(rare[0].clone())

# ──────────────────────────────────────────────────────────────────────────
# MAP（地圖選點）
# ──────────────────────────────────────────────────────────────────────────
func _selectable_nodes() -> Array:
	# 回傳當前 row 中、從上一個選擇連通可前往的節點（鏡像 _is_map_node_selectable）
	var row_index: int = run_state.encounter_index
	if row_index >= run_state.encounter_choices.size():
		return []
	var row: Array = run_state.encounter_choices[row_index]
	if row_index == 0:
		return row
	if run_state.chosen_map_path.size() < row_index:
		return []
	var prev_index: int = run_state.chosen_map_path[row_index - 1]
	var prev_row: Array = run_state.encounter_choices[row_index - 1]
	if prev_index < 0 or prev_index >= prev_row.size():
		return row  # 安全 fallback
	var connects: Array = (prev_row[prev_index] as Dictionary).get("connects", []) as Array
	var out: Array = []
	for node_v: Variant in row:
		var node: Dictionary = node_v as Dictionary
		if connects.has(int(node.get("index", -1))):
			out.append(node)
	return out if not out.is_empty() else row

func _node_label(node: Dictionary) -> String:
	var t: String = String(node.get("type", "battle"))
	match t:
		"battle":
			var es: Array = node.get("enemies", []) as Array
			var names: Array[String] = []
			for e_v: Variant in es:
				if e_v is EnemyData:
					names.append((e_v as EnemyData).display_name)
			return "戰鬥：" + "、".join(names)
		"boss":
			var be: EnemyData = node.get("enemy") as EnemyData
			return "Boss：" + (be.display_name if be != null else "?")
		"event":
			return "奇遇：" + String(node.get("event_variant", "?"))
		"shop":
			return "商店" + ("（黑市）" if bool(node.get("black_market", false)) else "")
		"rest":
			return "休息"
	return t

func _view_map() -> Dictionary:
	var nodes: Array = _selectable_nodes()
	var options: Array = []
	for node_v: Variant in nodes:
		var node: Dictionary = node_v as Dictionary
		var ec: int = (node.get("enemies", []) as Array).size()
		options.append({"id": int(node.get("index", 0)), "label": _node_label(node),
			"node_type": String(node.get("type", "battle")), "enemy_count": ec,
			"detail": "通往 " + str((node.get("connects", []) as Array))})
	return {"kind": "map", "phase_label": "選擇路線", "run": _run_context(),
		"state": {"row": run_state.encounter_index}, "options": options}

func _apply_map_choice(choice: Variant) -> void:
	var node_index: int = _choice_int(choice)
	# 記錄 chosen_map_path（鏡像 choose_route_node）
	if run_state.chosen_map_path.size() > run_state.encounter_index:
		run_state.chosen_map_path[run_state.encounter_index] = node_index
	else:
		while run_state.chosen_map_path.size() < run_state.encounter_index:
			run_state.chosen_map_path.append(-1)
		run_state.chosen_map_path.append(node_index)
	# 找到該節點
	var row: Array = run_state.encounter_choices[run_state.encounter_index]
	var node: Dictionary = {}
	for node_v: Variant in row:
		if int((node_v as Dictionary).get("index", -1)) == node_index:
			node = node_v as Dictionary
			break
	if node.is_empty():
		node = row[0] as Dictionary
	_log("map", {"row": run_state.encounter_index, "node": _node_label(node)})
	_enter_node(node)

func _enter_node(node: Dictionary) -> void:
	var t: String = String(node.get("type", "battle"))
	match t:
		"battle":
			_start_battle(node.get("enemies", []) as Array)
		"boss":
			_start_battle([node.get("enemy")])
		"rest":
			run_state.pending_rest_heal = EventData.rest_heal_for(_selected_character.max_hp)
			_phase = "rest"
		"event":
			run_state.current_event_variant = String(node.get("event_variant", "shrine"))
			_phase = "event"
		"shop":
			run_state.current_shop_is_black = bool(node.get("black_market", false))
			_open_shop()
			_phase = "shop"
		_:
			_advance_after_node()

# ──────────────────────────────────────────────────────────────────────────
# BATTLE（真實 BattleController）
# ──────────────────────────────────────────────────────────────────────────
func _start_battle(enemies_in: Array) -> void:
	var enemies: Array = enemies_in.duplicate()
	# miao_chieftain 特例：兩側加苗兵（鏡像 start_next_battle）
	if enemies.size() == 1 and enemies[0] is EnemyData and (enemies[0] as EnemyData).id == "miao_chieftain":
		enemies = [GameData.enemy_by_id("miao_soldier"), enemies[0], GameData.enemy_by_id("miao_soldier")]
	var is_boss: bool = false
	for e_v: Variant in enemies:
		if e_v is EnemyData and Ascension.is_boss_id((e_v as EnemyData).id):
			is_boss = true
			break
	# A20：雙 Boss
	if is_boss and Ascension.double_boss(run_state.ascension_level) and not enemies.is_empty():
		enemies.append((enemies[0] as EnemyData).clone())
	battle = BattleController.new()
	var typed: Array[EnemyData] = []
	for e_v: Variant in enemies:
		if e_v is EnemyData:
			typed.append(e_v as EnemyData)
	battle.setup(run_state, _selected_character, typed)
	var mult: float = Ascension.enemy_hp_multiplier(run_state.ascension_level, is_boss)
	if mult != 1.0:
		for slot_v: Variant in (battle.state.get("enemies", []) as Array):
			var slot: Dictionary = slot_v as Dictionary
			var sm: int = max(1, int(round(float(slot.get("max_hp", 0)) * mult)))
			slot["max_hp"] = sm
			slot["hp"] = sm
		battle._sync_active_enemy_to_state()
	battle.state["enemy_damage_mult"] = Ascension.enemy_damage_multiplier(run_state.ascension_level, "boss" if is_boss else "normal")
	_ctx = {"is_boss": is_boss, "turn": 0}
	battle.start_turn()
	_phase = "battle"
	_log("battle_start", {"enemies": _enemy_names(), "is_boss": is_boss})

func _enemy_names() -> Array:
	var out: Array = []
	for slot_v: Variant in (battle.state.get("enemies", []) as Array):
		out.append(String((slot_v as Dictionary).get("name", "?")))
	return out

func _view_battle() -> Dictionary:
	if battle.is_battle_over():
		return _resolve_battle_end()
	var s: Dictionary = battle.state
	# 玩家方
	var players: Array = []
	for p_v: Variant in (s.get("players", []) as Array):
		var p: Dictionary = p_v as Dictionary
		players.append({"name": p["name"], "hp": p["hp"], "max_hp": p["max_hp"],
			"block": p["block"], "poison": p["poison"], "weak": p["weak"],
			"vulnerable": p["vulnerable"], "power": p["power"]})
	# 敵方 + intent 預覽（非破壞性：_action_for_enemy 只讀）
	var enemies: Array = []
	for i: int in range((s.get("enemies", []) as Array).size()):
		var slot: Dictionary = (s["enemies"] as Array)[i] as Dictionary
		var alive: bool = int(slot["hp"]) > 0
		var action: Dictionary = battle._action_for_enemy(i) if alive else {}
		var pred: Dictionary = {}
		if not action.is_empty():
			pred = CardFormat.predict_enemy_damage(action, s)
		enemies.append({"idx": i, "name": slot["name"], "hp": slot["hp"], "max_hp": slot["max_hp"],
			"block": slot["block"], "poison": slot["poison"], "weak": slot["weak"],
			"vulnerable": slot["vulnerable"], "alive": alive,
			"intent": CardFormat.intent_badge(action) if not action.is_empty() else "",
			"intent_summary": CardFormat.enemy_action_effect_summary(action) if not action.is_empty() else "",
			"predicted_damage": pred.get("dealt", 0) if not pred.is_empty() else 0})
	# 手牌
	var hand: Array = []
	var dm: DeckManager = battle.deck
	for i: int in range(dm.hand.size()):
		var card: CardData = dm.hand[i]
		hand.append({"idx": i, "name": card.display_name, "cost": battle.effective_card_cost(card),
			"type": CardFormat.card_type_name(card.card_type), "desc": card.description,
			"needs_target": CardFormat.requires_enemy_target(card),
			"preview": CardFormat.live_preview_text(card, s)})
	# 合法動作
	var options: Array = []
	for c: Dictionary in hand:
		if int(c["cost"]) <= int(s.get("energy", 0)):
			options.append({"id": "play %d" % c["idx"], "label": "出牌：%s (耗%d)" % [c["name"], c["cost"]],
				"detail": c["desc"]})
	if run_state.characters.size() > 1:
		options.append({"id": "switch <idx>", "label": "換上場角色", "detail": "switch <隊伍index>"})
	for i: int in range(run_state.potions.size()):
		options.append({"id": "potion %d" % i, "label": "用藥：%s" % String(run_state.potions[i].get("display_name", "?")),
			"detail": String(run_state.potions[i].get("description", ""))})
	options.append({"id": "end", "label": "結束回合", "detail": "進入敵方行動"})
	return {"kind": "battle_turn", "phase_label": "戰鬥 第%d回合" % int(s.get("turn", 0)),
		"is_boss": bool(_ctx.get("is_boss", false)),
		"run": _run_context(),
		"state": {"energy": s.get("energy", 0), "draw_pile": dm.draw_pile.size(),
			"discard_pile": dm.discard_pile.size(), "players": players, "enemies": enemies,
			"active_player": s.get("active_player_index", 0), "hand": hand},
		"options": options}

func _apply_battle_choice(choice: Variant) -> void:
	var cmd: String = _choice_id(choice).strip_edges()
	var parts: PackedStringArray = cmd.split(" ", false)
	var verb: String = parts[0] if parts.size() > 0 else "end"
	match verb:
		"play":
			var hi: int = int(parts[1]) if parts.size() > 1 else 0
			var dm: DeckManager = battle.deck
			if hi < 0 or hi >= dm.hand.size():
				return
			var card: CardData = dm.hand[hi]
			if parts.size() > 2:
				battle.set_active_enemy(int(parts[2]))
			var res: Dictionary = battle.play_card(card)
			_log("play_card", {"card": card.display_name, "affordable": res.get("affordable", true)})
		"switch":
			var pi: int = int(parts[1]) if parts.size() > 1 else 0
			battle.switch_active(pi)
			_log("switch", {"to": pi})
		"potion":
			var si: int = int(parts[1]) if parts.size() > 1 else 0
			if si >= 0 and si < run_state.potions.size():
				var effects: Array = run_state.potions[si].get("effects", []) as Array
				battle.resolver.resolve_effects_list(effects, battle.state)
				_log("potion", {"potion": String(run_state.potions[si].get("display_name", "?"))})
				run_state.potions.remove_at(si)
		"end", _:
			var actions: Array = battle.begin_enemy_phase()
			battle.resolve_enemy_phase(actions)
			if not battle.is_battle_over():
				battle.start_turn()
				_ctx["turn"] = int(_ctx.get("turn", 0)) + 1
			_log("end_turn", {})

func _resolve_battle_end() -> Dictionary:
	# 事件樹觸發的戰鬥：勝負都不走標準流程，套 victory/defeat_effects 後回地圖（不結束 run）
	if bool(_ctx.get("event_battle", false)):
		var won: bool = battle.is_victory()
		if won:
			battle.complete_victory()
		var eff: Array = (_ctx.get("victory_effects", []) if won else _ctx.get("defeat_effects", [])) as Array
		var summary: String = _apply_event_effects(eff)
		_log("event_battle_end", {"victory": won, "result": summary})
		# 戰敗的事件戰鬥：若全隊 0 HP，給保底 1 HP（鏡像 main.gd event battle revive 語意）
		if run_state.is_all_dead():
			for i: int in range(run_state.character_hps.size()):
				run_state.character_hps[i] = max(1, run_state.character_hps[i])
		_advance_after_node()
		return next_view()
	if battle.is_victory():
		return _on_victory()
	else:
		# 全滅 → run 失敗
		_log("defeat", {"act": run_state.act, "floor": run_state.encounter_index})
		_finish(false, "party_wiped")
		return _view_done()

func _on_victory() -> Dictionary:
	battle.complete_victory()
	for e: EnemyData in battle.enemies:
		Bestiary.mark_defeated(e.id)
	_grant_battle_exp()
	# gold
	var gold_reward: int = 0
	for e: EnemyData in battle.enemies:
		if not e.is_summoned:
			gold_reward += _battle_gold_reward(e)
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) == "battle_victory":
				for e2: Dictionary in (t.get("effects", []) as Array):
					if String(e2.get("kind", "")) == "gold_bonus":
						gold_reward += int(e2.get("amount", 0))
	run_state.gold += gold_reward
	var was_boss: bool = false
	var boss_id: String = ""
	for e: EnemyData in battle.enemies:
		if Ascension.is_boss_id(e.id):
			was_boss = true
			boss_id = e.id
			break
	_log("victory", {"gold": gold_reward, "boss": was_boss})
	if was_boss:
		run_state.grant_observe_tokens(RunState.OBSERVE_TOKEN_BOSS_REWARD)
		_ctx = {"boss_relics": _make_boss_relic_choices(boss_id), "after_boss": true}
		_phase = "boss_relic"
		return _view_boss_relic()
	# 一般戰鬥：25% 掉遺物
	var dropped: RelicData = _try_random_relic_drop(0.25)
	if dropped != null:
		run_state.add_relic(dropped)
		_log("relic_drop", {"relic": dropped.display_name})
	# 藥品掉落 20%
	_maybe_potion_drop(0.2)
	# 卡牌獎勵
	_ctx = {"reward_cards": _make_reward_choices(false), "boss_card": false}
	_phase = "reward"
	return _view_reward()

func _grant_battle_exp() -> void:
	var is_boss: bool = false
	for e: EnemyData in battle.enemies:
		if Ascension.is_boss_id(e.id):
			is_boss = true
			break
	var exp_gain: int = LevelSystem.battle_exp(is_boss, run_state.encounter_index)
	for i: int in range(run_state.characters.size()):
		if run_state.character_hps[i] <= 0:
			continue
		run_state.character_exps[i] += exp_gain
		var new_lv: int = LevelSystem.level_from_exp(run_state.character_exps[i])
		if new_lv > run_state.character_levels[i]:
			run_state.character_levels[i] = new_lv

func _battle_gold_reward(enemy: EnemyData) -> int:
	var is_boss: bool = Ascension.is_boss_id(enemy.id)
	var base: int = 0
	if is_boss:
		match run_state.act:
			1: base = 80
			2: base = 120
			3: base = 160
			4: base = 200
			5: base = 250
			_: base = 80 + run_state.act * 40
	else:
		base = 18 + run_state.act * 8 + run_state.encounter_index * 3
	var gold_mult: float = Ascension.boss_gold_multiplier(run_state.ascension_level) if is_boss else 1.0
	return max(0, int(round(float(base) * gold_mult)))

func _try_random_relic_drop(chance: float) -> RelicData:
	if randf() >= chance:
		return null
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	if pool.is_empty():
		return null
	pool.shuffle()
	return pool[0].clone()

func _maybe_potion_drop(chance: float) -> void:
	if randf() >= chance:
		return
	if run_state.potions.size() >= run_state.effective_potion_slots():
		return
	var all_p: Array[Dictionary] = PotionCatalog.all()
	if all_p.is_empty():
		return
	run_state.potions.append((all_p[randi() % all_p.size()]).duplicate())

# ──────────────────────────────────────────────────────────────────────────
# BOSS RELIC（三選一）
# ──────────────────────────────────────────────────────────────────────────
func _make_boss_relic_choices(boss_id: String) -> Array:
	var choices: Array = []
	var seen: Array[String] = []
	for a: RelicData in RelicCatalog.artifacts():
		if a.boss_id == boss_id and not run_state.has_relic(a.id):
			choices.append(a.clone())
			seen.append(a.id)
			break
	var generals: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id) and not seen.has(r.id):
			generals.append(r)
	generals.shuffle()
	for r: RelicData in generals:
		if choices.size() >= 3:
			break
		choices.append(r.clone())
		seen.append(r.id)
	return choices

func _view_boss_relic() -> Dictionary:
	var options: Array = []
	for r_v: Variant in (_ctx.get("boss_relics", []) as Array):
		var r: RelicData = r_v as RelicData
		options.append({"id": r.id, "label": "遺物：%s" % r.display_name, "detail": r.description})
	options.append({"id": "skip", "label": "不拿", "detail": "略過遺物"})
	return {"kind": "boss_relic", "phase_label": "Boss 遺物三選一", "run": _run_context(),
		"state": {}, "options": options}

func _apply_boss_relic_choice(choice: Variant) -> void:
	var rid: String = _choice_id(choice)
	for r_v: Variant in (_ctx.get("boss_relics", []) as Array):
		var r: RelicData = r_v as RelicData
		if r.id == rid:
			run_state.add_relic(r)
			_log("boss_relic", {"relic": r.display_name})
			break
	# boss 之後給卡牌獎勵（高稀有）
	_maybe_potion_drop(0.6)
	_ctx = {"reward_cards": _make_reward_choices(true), "boss_card": true}
	_phase = "reward"

# ──────────────────────────────────────────────────────────────────────────
# CARD REWARD
# ──────────────────────────────────────────────────────────────────────────
func _make_reward_choices(boss_card: bool) -> Array:
	var pool: Array[CardData] = []
	var used: Array[String] = []
	for card: CardData in _selected_character.reward_pool:
		if not used.has(card.id):
			used.append(card.id)
			pool.append(card.clone())
	var ai: int = run_state.active_character_index
	if ai < run_state.character_levels.size() and ai < run_state.characters.size():
		for unlocked: CardData in LevelSystem.all_unlocked_cards(run_state.characters[ai].id, run_state.character_levels[ai]):
			if not used.has(unlocked.id):
				used.append(unlocked.id)
				pool.append(unlocked.clone())
	pool.shuffle()
	var count: int = 3
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) == "permanent":
				for e: Dictionary in (t.get("effects", []) as Array):
					if String(e.get("kind", "")) == "card_reward_count_bonus":
						count += int(e.get("amount", 0))
	if boss_card:
		var ordered: Array[CardData] = []
		for tier: String in ["rare", "uncommon", "common", "basic"]:
			for c: CardData in pool:
				if c.rarity == tier and not ordered.has(c):
					ordered.append(c)
		pool = ordered
	var rewards: Array = []
	for i: int in range(min(count, pool.size())):
		rewards.append(pool[i])
	if not boss_card and not rewards.is_empty() and randf() < 0.22:
		var cl: Array[CardData] = GameData.colorless_cards()
		if not cl.is_empty():
			rewards[randi() % rewards.size()] = (cl[randi() % cl.size()] as CardData).clone()
	return rewards

func _view_reward() -> Dictionary:
	var options: Array = []
	var cards: Array = _ctx.get("reward_cards", []) as Array
	for i: int in range(cards.size()):
		var c: CardData = cards[i] as CardData
		options.append({"id": i, "label": "%s [%s] 耗%d" % [c.display_name, CardFormat.card_rarity_name(c), c.cost],
			"detail": c.description, "rarity": c.rarity, "card_type": c.card_type, "cost": c.cost})
	options.append({"id": "skip", "label": "略過（不拿牌）", "detail": "保持牌組精簡"})
	return {"kind": "reward", "phase_label": "卡牌獎勵" + ("（Boss）" if bool(_ctx.get("boss_card", false)) else ""),
		"run": _run_context(), "state": {}, "options": options}

func _apply_reward_choice(choice: Variant) -> void:
	var cid: String = _choice_id(choice)
	if cid != "skip":
		var idx: int = _choice_int(choice)
		var cards: Array = _ctx.get("reward_cards", []) as Array
		if idx >= 0 and idx < cards.size():
			run_state.deck.append((cards[idx] as CardData).clone())
			_log("reward_card", {"card": (cards[idx] as CardData).display_name})
	else:
		_log("reward_card", {"card": "skip"})
	_advance_after_node()

# ──────────────────────────────────────────────────────────────────────────
# REST
# ──────────────────────────────────────────────────────────────────────────
func _upgradeable() -> Array:
	var out: Array = []
	for c: CardData in run_state.deck:
		if not c.upgraded and c.card_type != "curse":
			out.append(c)
	return out

func _view_rest() -> Dictionary:
	var options: Array = []
	options.append({"id": "heal", "label": "調息（回復 %d HP）" % run_state.pending_rest_heal, "detail": ""})
	var up: Array = _upgradeable()
	for i: int in range(up.size()):
		var c: CardData = up[i] as CardData
		options.append({"id": "upgrade %d" % i, "label": "打磨：%s" % c.display_name, "detail": c.description,
			"cost": c.cost, "card_type": c.card_type})
	return {"kind": "rest", "phase_label": "清修片刻", "run": _run_context(),
		"state": {"heal_amount": run_state.pending_rest_heal}, "options": options}

func _apply_rest_choice(choice: Variant) -> void:
	var cmd: String = _choice_id(choice).strip_edges()
	if cmd.begins_with("upgrade"):
		var parts: PackedStringArray = cmd.split(" ", false)
		var idx: int = int(parts[1]) if parts.size() > 1 else 0
		var up: Array = _upgradeable()
		if idx >= 0 and idx < up.size():
			var target: CardData = up[idx] as CardData
			var deck: Array[CardData] = run_state.deck
			for i: int in range(deck.size()):
				if deck[i] == target:
					deck[i] = target.upgraded_copy()
					break
			_log("rest", {"choice": "upgrade", "card": target.display_name})
	else:
		var bonus: int = 0
		for r: RelicData in run_state.relics:
			for t: Dictionary in r.triggers:
				if String(t.get("trigger", "")) == "permanent":
					for e: Dictionary in (t.get("effects", []) as Array):
						if String(e.get("kind", "")) == "rest_heal_bonus":
							bonus += int(e.get("amount", 0))
		run_state.heal(run_state.pending_rest_heal + bonus)
		_log("rest", {"choice": "heal", "amount": run_state.pending_rest_heal + bonus})
	run_state.pending_rest_heal = 0
	_advance_after_node()

# ──────────────────────────────────────────────────────────────────────────
# EVENT（事件樹 EventRunner + 舊扁平 schema fallback）
# ──────────────────────────────────────────────────────────────────────────
func _event_context() -> Dictionary:
	var relic_ids: Array = []
	for r: RelicData in run_state.relics:
		relic_ids.append(r.id)
	return EventRunner.build_context(
		_selected_character.id, run_state.gold, run_state.power_bonus,
		run_state.observe_tokens, relic_ids, run_state.deck.size())

func _view_event() -> Dictionary:
	var ed: Dictionary = EventData.for_variant(run_state.current_event_variant)
	if _ctx.get("variant", "") != run_state.current_event_variant:
		_ctx = {"variant": run_state.current_event_variant, "node_id": "root", "tree": EventRunner.has_tree(ed)}
	var options: Array = []
	var prompt: String = String(ed.get("flavor", ""))
	if bool(_ctx.get("tree", false)):
		var node: Dictionary = EventRunner.get_node(ed, String(_ctx.get("node_id", "root")))
		prompt = String(node.get("prompt", prompt))
		for ch_v: Variant in EventRunner.visible_choices(node, _event_context()):
			var ch: Dictionary = ch_v as Dictionary
			options.append({"id": String(ch.get("id", "")), "label": String(ch.get("label", "?")),
				"detail": EventRunner.badge_for_kind(EventRunner.leaf_kind(ch)).get("text", "")})
	else:
		# 舊扁平 schema
		for ck_v: Variant in (ed.get("choices", []) as Array):
			var ck: String = String(ck_v)
			options.append({"id": ck, "label": _flat_choice_label(ed, ck), "detail": ""})
	if options.is_empty():
		options.append({"id": "leave", "label": "離開", "detail": ""})
	return {"kind": "event", "phase_label": "奇遇：" + String(ed.get("title", run_state.current_event_variant)),
		"run": _run_context(),
		"state": {"variant": run_state.current_event_variant, "prompt": prompt, "node": _ctx.get("node_id", "root")},
		"options": options}

func _flat_choice_label(ed: Dictionary, key: String) -> String:
	match key:
		"heal": return "調息（回復 %d HP）" % int(ed.get("heal", 0))
		"gain_card": return "習藝（耗 %d HP 習得招式）" % int(ed.get("gain_cost", 0))
		"power": return "凝神（攻擊 +%d）" % int(ed.get("power", 0))
		"observe": return "觀察"
		"remove": return "去蕪（移除一張牌）"
		"upgrade": return "打磨（升級一張牌）"
		"leave": return "離開"
	return key

func _apply_event_choice(choice: Variant) -> void:
	var ed: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var cid: String = _choice_id(choice)
	if bool(_ctx.get("tree", false)):
		var node: Dictionary = EventRunner.get_node(ed, String(_ctx.get("node_id", "root")))
		var picked: Dictionary = {}
		for ch_v: Variant in EventRunner.visible_choices(node, _event_context()):
			if String((ch_v as Dictionary).get("id", "")) == cid:
				picked = ch_v as Dictionary
				break
		if picked.is_empty():
			_log("event", {"variant": run_state.current_event_variant, "choice": "leave_no_match"})
			_advance_after_node()
			return
		if bool((picked.get("requires", {}) as Dictionary).get("observe_token", false)):
			run_state.consume_observe_token()
		if picked.has("next") and not EventRunner.is_leaf(picked):
			_ctx["node_id"] = String(picked["next"])
			_log("event", {"variant": run_state.current_event_variant, "choice": cid, "next": _ctx["node_id"]})
			return  # 留在 event phase，下個 view 顯示子節點
		if EventRunner.is_leaf(picked):
			var outcome: Dictionary = picked["outcome"] as Dictionary
			_resolve_event_outcome(outcome, cid)
			return
		_advance_after_node()
	else:
		_apply_flat_event(ed, cid)

func _resolve_event_outcome(outcome: Dictionary, choice_id: String) -> void:
	var kind: String = String(outcome.get("kind", "neutral"))
	match kind:
		"gamble":
			var g: Dictionary = outcome.get("gamble", {}) as Dictionary
			var won: bool = randf() < float(g.get("win_chance", 0.5))
			var eff: Array = (g.get("win_effects", []) if won else g.get("lose_effects", [])) as Array
			var summary: String = _apply_event_effects(eff)
			_log("event", {"variant": run_state.current_event_variant, "choice": choice_id, "gamble_win": won, "result": summary})
			_advance_after_node()
		"battle":
			var bd: Dictionary = outcome.get("battle", {}) as Dictionary
			var enemy_id: String = String(bd.get("enemy_id", ""))
			var template: EnemyData = GameData.enemy_by_id(enemy_id)
			if template == null:
				var s: String = _apply_event_effects(bd.get("defeat_effects", []) as Array)
				_log("event", {"variant": run_state.current_event_variant, "choice": choice_id, "battle": "no_enemy", "result": s})
				_advance_after_node()
				return
			var clone: EnemyData = template.clone()
			var mult: float = float(bd.get("enemy_hp_mult", 1.0))
			if mult > 0.0 and not is_equal_approx(mult, 1.0):
				clone.max_hp = max(1, int(round(float(clone.max_hp) * mult)))
			_log("event", {"variant": run_state.current_event_variant, "choice": choice_id, "battle": enemy_id})
			_start_battle([clone])
			_ctx["event_battle"] = true
			_ctx["victory_effects"] = (bd.get("victory_effects", []) as Array).duplicate()
			_ctx["defeat_effects"] = (bd.get("defeat_effects", []) as Array).duplicate()
		_:
			var summary2: String = _apply_event_effects(outcome.get("effects", []) as Array)
			_log("event", {"variant": run_state.current_event_variant, "choice": choice_id, "kind": kind, "result": summary2})
			_advance_after_node()

func _apply_flat_event(ed: Dictionary, key: String) -> void:
	var summary: String = ""
	match key:
		"heal":
			run_state.heal(int(ed.get("heal", 0)))
			summary = "heal %d" % int(ed.get("heal", 0))
		"power":
			run_state.power_bonus += int(ed.get("power", 0))
			summary = "power %d" % int(ed.get("power", 0))
		"gain_card":
			var cost: int = int(ed.get("gain_cost", 0))
			run_state.take_damage(cost)
			var c: CardData = _pick_card_from_pool("any")
			if c != null:
				run_state.deck.append(c)
				summary = "gain_card %s (-%d HP)" % [c.display_name, cost]
		"observe":
			summary = _apply_event_effects(ed.get("observe_effects", [{"kind": "heal", "amount": 3}]) as Array)
		_:
			summary = "leave"
	_log("event", {"variant": run_state.current_event_variant, "choice": key, "result": summary})
	_advance_after_node()

# 結算事件 effects（鏡像 main.gd:_resolve_observe_effects，去掉 UI 確認 — 直接套用）
func _apply_event_effects(effects: Array) -> String:
	var parts: Array[String] = []
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry as Dictionary
		var kind: String = String(e.get("kind", ""))
		var amount: int = int(e.get("amount", 0))
		match kind:
			"heal":
				run_state.hp = min(run_state.max_hp, run_state.hp + amount); parts.append("heal %d" % amount)
			"damage":
				run_state.hp = max(1, run_state.hp - amount); parts.append("damage %d" % amount)
			"gold":
				run_state.gold = max(0, run_state.gold + amount); parts.append("gold %+d" % amount)
			"max_hp":
				run_state.max_hp = max(1, run_state.max_hp + amount)
				if amount > 0:
					run_state.hp = min(run_state.max_hp, run_state.hp + amount)
				else:
					run_state.hp = min(run_state.hp, run_state.max_hp)
				parts.append("max_hp %+d" % amount)
			"power", "permanent_power":
				run_state.power_bonus += amount; parts.append("power %+d" % amount)
			"heal_party":
				for i: int in range(run_state.character_hps.size()):
					if run_state.character_hps[i] > 0:
						run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + amount)
				parts.append("heal_party %d" % amount)
			"gain_potion":
				var chosen: Dictionary = {}
				var pid: String = String(e.get("potion_id", ""))
				if not pid.is_empty():
					chosen = PotionCatalog.by_id(pid)
				if chosen.is_empty():
					var pool: Array[Dictionary] = PotionCatalog.all()
					if not pool.is_empty():
						chosen = pool[randi() % pool.size()]
				if not chosen.is_empty() and run_state.potions.size() < run_state.effective_potion_slots():
					run_state.potions.append(chosen.duplicate())
					parts.append("potion %s" % String(chosen.get("display_name", "?")))
			"upgrade_random":
				var d: Array = run_state.character_decks[run_state.active_character_index] as Array
				var cand: Array[int] = []
				for i: int in range(d.size()):
					if not (d[i] as CardData).upgraded:
						cand.append(i)
				if not cand.is_empty():
					var pick: int = cand[randi() % cand.size()]
					d[pick] = (d[pick] as CardData).upgraded_copy()
					parts.append("upgrade_random")
			"next_battle_buff":
				var sub: Array = e.get("effects", []) as Array
				if not sub.is_empty():
					run_state.queue_next_battle_buff(sub); parts.append("next_battle_buff")
			"gain_relic_pool":
				var picked: RelicData = _pick_relic_from_pool(String(e.get("pool", "common")))
				if picked != null:
					run_state.add_relic(picked); parts.append("relic %s" % picked.display_name)
			"gain_card_pool":
				var added: CardData = _pick_card_from_pool(String(e.get("pool", "common")))
				if added != null:
					run_state.deck.append(added); parts.append("card %s" % added.display_name)
			"gain_curse":
				var cc: CardData = CurseCatalog.make_card(String(e.get("curse_id", "")))
				if cc != null:
					run_state.deck.append(cc); parts.append("curse %s" % cc.display_name)
			"lose_card":
				var d3: Array = run_state.character_decks[run_state.active_character_index] as Array
				if d3.size() > 5:
					var idx: int = randi() % d3.size()
					parts.append("lose %s" % (d3[idx] as CardData).display_name)
					d3.remove_at(idx)
	return "、".join(parts)

func _pick_relic_from_pool(pool_key: String) -> RelicData:
	var cand: Array[RelicData] = []
	for r: RelicData in RelicCatalog.all():
		if run_state.has_relic(r.id) or r.slot != "general":
			continue
		if r.rarity == pool_key:
			cand.append(r)
	if cand.is_empty():
		return null
	return cand[randi() % cand.size()].clone()

func _pick_card_from_pool(pool_key: String) -> CardData:
	if pool_key == "colorless" or randf() < 0.18:
		var cl: Array[CardData] = GameData.colorless_cards()
		if not cl.is_empty():
			return (cl[randi() % cl.size()] as CardData).clone()
	var pool: Array[CardData] = _selected_character.reward_pool
	if pool.is_empty():
		return null
	return (pool[randi() % pool.size()] as CardData).clone()

func _open_shop() -> void:
	if run_state.current_shop_node_index == run_state.encounter_index:
		return
	run_state.current_shop_node_index = run_state.encounter_index
	run_state.current_shop_inventory = ShopInventory.build(_selected_character, run_state.current_shop_is_black)
	run_state.current_shop_potions = ShopInventory.build_potions(run_state.current_shop_is_black)
	run_state.current_shop_relic_ids = _pick_shop_relic_ids(3)
	run_state.current_shop_relic_sold_ids = []
	run_state.shop_remove_used = false
	run_state.shop_upgrade_used = false
	_ctx = {"shop_sub": ""}

func _pick_shop_relic_ids(count: int) -> Array[String]:
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	pool.shuffle()
	var ids: Array[String] = []
	if run_state.current_shop_is_black:
		var weapons: Array[RelicData] = []
		for w: RelicData in RelicCatalog.weapons_for_character(_selected_character.id):
			if not run_state.has_relic(w.id):
				weapons.append(w)
		if not weapons.is_empty() and randf() < 0.3:
			ids.append(weapons[randi() % weapons.size()].id)
	for r: RelicData in pool:
		if ids.size() >= count:
			break
		if not ids.has(r.id):
			ids.append(r.id)
	return ids

func _relic_by_id(id: String) -> RelicData:
	for r: RelicData in RelicCatalog.all():
		if r.id == id:
			return r
	return null

func _shop_discount(base: int) -> int:
	var price: float = float(base) * Ascension.shop_price_multiplier(run_state.ascension_level)  # A16 漲價
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) == "permanent":
				for e: Dictionary in (t.get("effects", []) as Array):
					if String(e.get("kind", "")) == "shop_discount":
						price -= float(e.get("amount", 0))
	return max(10, int(round(price)))

func _shop_relic_price(relic: RelicData) -> int:
	var base: int = 70
	match relic.rarity:
		"uncommon": base = 95
		"rare": base = 130
		"legendary": base = 180
	if run_state.current_shop_is_black:
		base = int(base * 1.2)
	return _shop_discount(base)

func _view_shop() -> Dictionary:
	var sub: String = String(_ctx.get("shop_sub", ""))
	if sub == "remove":
		return _shop_card_picker("remove", "選一張牌移除")
	if sub == "upgrade":
		return _shop_card_picker("upgrade", "選一張牌升級")
	var options: Array = []
	var goods: Array = []
	# 卡牌
	for i: int in range(run_state.current_shop_inventory.size()):
		var item: Dictionary = run_state.current_shop_inventory[i]
		if bool(item.get("sold", false)):
			continue
		var card: CardData = item.get("card") as CardData
		var price: int = _shop_discount(int(item.get("price", 0)))
		goods.append({"slot": "card %d" % i, "name": card.display_name, "price": price, "kind": "card",
			"desc": card.description, "afford": run_state.gold >= price})
		if run_state.gold >= price:
			options.append({"id": "card %d" % i, "label": "買卡：%s (%d)" % [card.display_name, price], "detail": card.description})
	# 遺物
	for rid: String in run_state.current_shop_relic_ids:
		if run_state.current_shop_relic_sold_ids.has(rid):
			continue
		var relic: RelicData = _relic_by_id(rid)
		if relic == null:
			continue
		var rprice: int = _shop_relic_price(relic)
		goods.append({"slot": "relic %s" % rid, "name": relic.display_name, "price": rprice, "kind": "relic",
			"desc": relic.description, "afford": run_state.gold >= rprice})
		if run_state.gold >= rprice:
			options.append({"id": "relic %s" % rid, "label": "買遺物：%s (%d)" % [relic.display_name, rprice], "detail": relic.description})
	# 藥品
	for i: int in range(run_state.current_shop_potions.size()):
		var pitem: Dictionary = run_state.current_shop_potions[i]
		if bool(pitem.get("sold", false)):
			continue
		var pot: Dictionary = pitem.get("potion", pitem) as Dictionary
		var pprice: int = _shop_discount(int(pitem.get("price", 0)))
		var slot_free: bool = run_state.potions.size() < run_state.effective_potion_slots()
		goods.append({"slot": "potion %d" % i, "name": String(pot.get("display_name", "?")), "price": pprice,
			"kind": "potion", "desc": String(pot.get("description", "")), "afford": run_state.gold >= pprice and slot_free})
		if run_state.gold >= pprice and slot_free:
			options.append({"id": "potion %d" % i, "label": "買藥：%s (%d)" % [String(pot.get("display_name", "?")), pprice],
				"detail": String(pot.get("description", ""))})
	# 服務
	var remove_price: int = _shop_discount(75)
	var upgrade_price: int = _shop_discount(100)
	if not run_state.shop_remove_used and run_state.deck.size() > 5 and run_state.gold >= remove_price:
		options.append({"id": "remove", "label": "削牌服務 (%d)" % remove_price, "detail": "移除一張牌"})
	if not run_state.shop_upgrade_used and not _upgradeable().is_empty() and run_state.gold >= upgrade_price:
		options.append({"id": "upgrade", "label": "強化服務 (%d)" % upgrade_price, "detail": "升級一張牌"})
	options.append({"id": "leave", "label": "離開商店", "detail": "結束購物"})
	return {"kind": "shop", "phase_label": "商店" + ("（黑市）" if run_state.current_shop_is_black else ""),
		"run": _run_context(), "state": {"goods": goods, "remove_price": remove_price, "upgrade_price": upgrade_price},
		"options": options}

func _shop_card_picker(mode: String, label: String) -> Dictionary:
	var options: Array = []
	var cards: Array = (_upgradeable() if mode == "upgrade" else run_state.deck)
	for i: int in range(cards.size()):
		var c: CardData = cards[i] as CardData
		options.append({"id": "%s %d" % [mode, i], "label": "%s：%s" % [label, c.display_name], "detail": c.description})
	options.append({"id": "cancel", "label": "取消", "detail": "返回商店"})
	return {"kind": "shop", "phase_label": "商店 - " + label, "run": _run_context(),
		"state": {"sub": mode}, "options": options}

func _apply_shop_choice(choice: Variant) -> void:
	var cmd: String = _choice_id(choice).strip_edges()
	var parts: PackedStringArray = cmd.split(" ", false)
	var verb: String = parts[0] if parts.size() > 0 else "leave"
	match verb:
		"card":
			var i: int = int(parts[1]) if parts.size() > 1 else -1
			if i >= 0 and i < run_state.current_shop_inventory.size():
				var item: Dictionary = run_state.current_shop_inventory[i]
				var price: int = _shop_discount(int(item.get("price", 0)))
				if not bool(item.get("sold", false)) and run_state.gold >= price:
					run_state.gold -= price
					item["sold"] = true
					run_state.deck.append((item.get("card") as CardData).clone())
					_log("shop_buy", {"kind": "card", "name": (item.get("card") as CardData).display_name, "price": price})
		"relic":
			var rid: String = parts[1] if parts.size() > 1 else ""
			var relic: RelicData = _relic_by_id(rid)
			if relic != null and not run_state.current_shop_relic_sold_ids.has(rid):
				var rprice: int = _shop_relic_price(relic)
				if run_state.gold >= rprice:
					run_state.gold -= rprice
					run_state.add_relic(relic)
					run_state.current_shop_relic_sold_ids.append(rid)
					_log("shop_buy", {"kind": "relic", "name": relic.display_name, "price": rprice})
		"potion":
			var pi: int = int(parts[1]) if parts.size() > 1 else -1
			if pi >= 0 and pi < run_state.current_shop_potions.size():
				var pitem: Dictionary = run_state.current_shop_potions[pi]
				var pprice: int = _shop_discount(int(pitem.get("price", 0)))
				var pot: Dictionary = pitem.get("potion", pitem) as Dictionary
				if not bool(pitem.get("sold", false)) and run_state.gold >= pprice and run_state.potions.size() < run_state.effective_potion_slots():
					run_state.gold -= pprice
					pitem["sold"] = true
					run_state.potions.append(pot.duplicate())
					_log("shop_buy", {"kind": "potion", "name": String(pot.get("display_name", "?")), "price": pprice})
		"remove":
			if parts.size() > 1:
				var ri: int = int(parts[1])
				var deck: Array[CardData] = run_state.deck
				if ri >= 0 and ri < deck.size():
					var price: int = _shop_discount(75)
					if run_state.gold >= price:
						run_state.gold -= price
						run_state.shop_remove_used = true
						_log("shop_service", {"service": "remove", "card": deck[ri].display_name})
						deck.remove_at(ri)
				_ctx["shop_sub"] = ""
			else:
				_ctx["shop_sub"] = "remove"  # 進入選牌
		"upgrade":
			if parts.size() > 1:
				var ui: int = int(parts[1])
				var up: Array = _upgradeable()
				if ui >= 0 and ui < up.size():
					var price2: int = _shop_discount(100)
					if run_state.gold >= price2:
						run_state.gold -= price2
						run_state.shop_upgrade_used = true
						var target: CardData = up[ui] as CardData
						var deck2: Array[CardData] = run_state.deck
						for j: int in range(deck2.size()):
							if deck2[j] == target:
								deck2[j] = target.upgraded_copy()
								break
						_log("shop_service", {"service": "upgrade", "card": target.display_name})
				_ctx["shop_sub"] = ""
			else:
				_ctx["shop_sub"] = "upgrade"  # 進入選牌
		"cancel":
			_ctx["shop_sub"] = ""
		"leave", _:
			_log("shop", {"choice": "leave", "gold": run_state.gold})
			_advance_after_node()

# ──────────────────────────────────────────────────────────────────────────
# 推進 / 終局
# ──────────────────────────────────────────────────────────────────────────
func _advance_after_node() -> void:
	run_state.encounter_index += 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		if run_state.act < 8:
			_act_complete()
		else:
			_finish(true, "cleared_act_8")
			return
	_phase = "map" if _phase != "done" else "done"

func _act_complete() -> void:
	var act_heal: int = int(round(20 * Ascension.boss_heal_multiplier(run_state.ascension_level)))  # A5：過幕回血變少
	var completed: int = run_state.act
	for i: int in range(run_state.characters.size()):
		run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + act_heal)
	run_state.act = completed + 1
	run_state.encounter_index = 0
	run_state.current_shop_node_index = -1
	run_state.chosen_map_path.clear()
	run_state.encounter_choices = _make_encounter_choices()
	_log("act_complete", {"completed_act": completed, "next_act": run_state.act})

# agent 在 act_complete 暫停時選擇 stop → 提前結算（非戰敗，只是中止量測）。
func stop_early(reason: String = "agent_stopped") -> void:
	if _phase != "done":
		_finish(false, reason)

func _finish(victory: bool, reason: String) -> void:
	_phase = "done"
	var party: Array = []
	for i: int in range(run_state.characters.size()):
		party.append({"name": run_state.characters[i].display_name,
			"hp": run_state.character_hps[i], "max_hp": run_state.character_max_hps[i],
			"level": run_state.character_levels[i] if i < run_state.character_levels.size() else 1})
	result = {
		"victory": victory,
		"reason": reason,
		"final_act": run_state.act,
		"final_floor": run_state.encounter_index,
		"gold": run_state.gold,
		"ascension": run_state.ascension_level,
		"seed": run_state.map_seed,
		"party": party,
		"relics": _run_context()["relics"],
		"steps": _step_count,
	}
	_log("run_end", result)

func _view_done() -> Dictionary:
	return {"kind": "done", "phase_label": "結束", "run": _run_context(),
		"state": {}, "options": [], "terminal": true, "result": result}

# ──────────────────────────────────────────────────────────────────────────
# helpers
# ──────────────────────────────────────────────────────────────────────────
func _choice_id(choice: Variant) -> String:
	if choice is Dictionary:
		return String((choice as Dictionary).get("id", (choice as Dictionary).get("choice", "")))
	return str(choice)

func _choice_int(choice: Variant) -> int:
	var s: String = _choice_id(choice)
	if s.is_valid_int():
		return int(s)
	if choice is float or choice is int:
		return int(choice)
	return -1

func _log(event: String, data: Dictionary) -> void:
	transcript.append({"step": _step_count, "phase": _phase, "event": event, "data": data})

# ──────────────────────────────────────────────────────────────────────────
# 內建啟發式 policy（smoke test 與無人值守模式用；比隨機 AI 略聰明，但仍很粗淺）。
# 回傳給 apply() 的 choice 字串。手動模式不會用到這個。
# ──────────────────────────────────────────────────────────────────────────
# 取字串中某關鍵字後面緊接的整數（如 "傷害 26" → 26）；找不到回 -1。
static func _num_after(text: String, keyword: String) -> int:
	var idx: int = text.find(keyword)
	if idx < 0:
		return -1
	var rest: String = text.substr(idx + keyword.length())
	var num: String = ""
	for ch: String in rest:
		if ch >= "0" and ch <= "9":
			num += ch
		elif not num.is_empty():
			break
	return int(num) if not num.is_empty() else -1

# 解析 preview 的「傷害」總值，含多段：CardFormat.live_preview_text 把多段寫成
# "傷害 V×H"（每段值×段數），單純 _num_after 只會讀到 V、漏掉 ×H → 嚴重低估多段攻擊、
# 害 focus_killable / atk_kill 誤判。這裡讀到該段內的所有數字（V 及可選 H）相乘回傳總傷。
static func _preview_total_damage(text: String) -> int:
	var idx: int = text.find("傷害")
	if idx < 0:
		return -1
	var rest: String = text.substr(idx + 2)  # "傷害".length() == 2
	var nums: Array[int] = []
	var cur: String = ""
	for ch: String in rest:
		if ch >= "0" and ch <= "9":
			cur += ch
			continue
		if not cur.is_empty():
			nums.append(int(cur))
			cur = ""
		if ch == "/":  # 進入下一個效果區段（" / " 分隔）→ 停止
			break
	if not cur.is_empty():
		nums.append(int(cur))
	if nums.is_empty():
		return -1
	return nums[0] * nums[1] if nums.size() >= 2 else nums[0]

# 改良啟發式 policy（取代原本「打第一張負擔得起的牌」）。逐 action 評估、回傳當下最佳動作；
# 由 auto 迴圈反覆呼叫直到本回合 end。重點：致命就擋、能殺就集火、阿奴疊毒留爆點、能力早放、
# 商店優先拿遺物、血低就補。
static func auto_choice(view: Dictionary) -> String:
	var kind: String = String(view.get("kind", ""))
	var options: Array = view.get("options", []) as Array
	var run: Dictionary = view.get("run", {}) as Dictionary
	var party: Array = run.get("party", []) as Array
	var p0: Dictionary = (party[0] if not party.is_empty() else {}) as Dictionary
	var hp_ratio: float = float(p0.get("hp", 1)) / max(1.0, float(p0.get("max_hp", 1)))
	var deck_size: int = int(p0.get("deck_size", 0))
	match kind:
		"battle_turn":
			return _auto_battle(view)
		"rest":
			# 血低（<60%）先補；血已很多就打磨牌。
			if hp_ratio < 0.6:
				return "heal"
			# 升級最常用 / CP 值最高的牌先（會玩的人習慣）：低費＝每回合常打、升級回報滾最多次；
			# 攻擊 / 能力（輸出 / 引擎）比技能更值得強化。挑分數最高的 upgrade 選項。
			var best_up: String = ""
			var best_up_score: int = -999
			for o_v: Variant in options:
				var o: Dictionary = o_v as Dictionary
				if not String(o.get("id", "")).begins_with("upgrade"):
					continue
				var score: int = 0
				match String(o.get("card_type", "")):
					"attack", "power": score += 2
					"skill": score += 1
				var ucost: int = int(o.get("cost", 2))
				if ucost <= 1: score += 2     # 低費常打，升級回報最多次
				elif ucost == 2: score += 1
				if score > best_up_score:
					best_up_score = score
					best_up = String(o.get("id", ""))
			return best_up if best_up != "" else "heal"
		"map":
			# 快死（<30%）→ 繞去休息（門檻壓低，避免避戰導致練不夠 / boss 前太弱）。
			if hp_ratio < 0.3:
				for o_v: Variant in options:
					if String((o_v as Dictionary).get("node_type", "")) == "rest":
						return str((o_v as Dictionary).get("id", 0))
			# 錢多（≥150，足夠買遺物）→ 優先走商店把遺物買光（會玩的人習慣；商店分支會逐件買光）。
			if int(run.get("gold", 0)) >= 150:
				for o_v: Variant in options:
					if String((o_v as Dictionary).get("node_type", "")) == "shop":
						return str((o_v as Dictionary).get("id", 0))
			# 否則正常推進取第一個節點。
			if not options.is_empty():
				return str((options[0] as Dictionary).get("id", 0))
			return "skip"
		"reward":
			# 真玩家會保持牌組精簡（牌少→更穩定抽到 win-con），不會每場都拿。
			# 達到目標張數就略過、保持精簡；未達標才拿（pool 已 shuffle → 無偏隨機選哪張）。
			# 註：別自作聰明挑「稀有」或「便宜攻擊」——實測都比隨機選差（per-character
			# win-con 判斷是啟發式做不到、得靠互動 agent 的事）。option 已附 rarity/card_type/cost。
			var target: int = int(AUTO_TARGET_DECK_BY_ID.get(String(p0.get("id", "")), AUTO_TARGET_DECK_DEFAULT))
			if deck_size >= target:
				return "skip"
			if not options.is_empty():
				return str((options[0] as Dictionary).get("id", "skip"))
			return "skip"
		"boon":
			var pref: Array = ["extra_card", "remove_starter", "starting_potion", "extra_gold"]
			for want: String in pref:
				for o_v: Variant in options:
					if String((o_v as Dictionary).get("id", "")) == want:
						return want
			if not options.is_empty():
				return str((options[0] as Dictionary).get("id", "skip"))
			return "skip"
		"boss_relic":
			if not options.is_empty():
				return str((options[0] as Dictionary).get("id", "skip"))
			return "skip"
		"shop":
			# 優先買遺物（純增益、不肥牌）
			for o_v: Variant in options:
				if String((o_v as Dictionary).get("id", "")).begins_with("relic "):
					return String((o_v as Dictionary).get("id", "leave"))
			# 血量偏低（<60%）→ 買一瓶補血藥備用（生存優先於擴牌）
			if hp_ratio < 0.6:
				for o_v: Variant in options:
					var o: Dictionary = o_v as Dictionary
					if not String(o.get("id", "")).begins_with("potion "):
						continue
					var info: String = String(o.get("detail", "")) + String(o.get("label", ""))
					if info.find("回復") >= 0 or info.find("生命") >= 0 or info.find("治療") >= 0:
						return String(o.get("id", "leave"))
			# 其次在牌組不太肥時買一張卡；否則離開
			if deck_size < 22:
				for o_v: Variant in options:
					if String((o_v as Dictionary).get("id", "")).begins_with("card "):
						return String((o_v as Dictionary).get("id", "leave"))
			return "leave"
		"event":
			# 取第一個選項（多為主要互動）
			if not options.is_empty():
				return str((options[0] as Dictionary).get("id", "leave"))
			return "leave"
	return "skip"

# 單一回合內的「下一個最佳動作」。
static func _auto_battle(view: Dictionary) -> String:
	var st: Dictionary = view.get("state", {}) as Dictionary
	var energy: int = int(st.get("energy", 0))
	var players: Array = st.get("players", []) as Array
	var ap: int = int(st.get("active_player", 0))
	var me: Dictionary = (players[ap] if ap < players.size() else {}) as Dictionary
	var hp: int = int(me.get("hp", 1))
	var block: int = int(me.get("block", 0))
	var max_hp: int = int(me.get("max_hp", 1))

	# 活著的敵人
	var enemies: Array = st.get("enemies", []) as Array
	var alive: Array = []
	for e_v: Variant in enemies:
		if bool((e_v as Dictionary).get("alive", false)):
			alive.append(e_v as Dictionary)
	var incoming: int = 0
	for e: Variant in alive:
		incoming += int((e as Dictionary).get("predicted_damage", 0))

	# 分類手牌（只看負擔得起的）
	var hand: Array = st.get("hand", []) as Array
	var blocks: Array = []   # {idx, val}
	var attacks: Array = []  # {idx, dmg, needs_target}
	var poisons: Array = []  # {idx, needs_target} 施毒牌
	var bursts: Array = []   # {idx, needs_target} 引爆牌
	var buffs: Array = []    # {idx} 能力/引擎/抽牌
	var heals_self: Array = []  # {idx}
	for c_v: Variant in hand:
		var c: Dictionary = c_v as Dictionary
		if int(c.get("cost", 99)) > energy:
			continue
		var idx: int = int(c.get("idx", 0))
		var ccost: int = int(c.get("cost", 0))
		var desc: String = String(c.get("desc", ""))
		var prev: String = String(c.get("preview", ""))
		var type: String = String(c.get("type", ""))
		var nt: bool = bool(c.get("needs_target", false))
		var is_burst: bool = desc.find("引爆") >= 0
		var is_poison: bool = (not is_burst) and (desc.find("蠱毒") >= 0 or prev.find("蠱毒") >= 0)
		var blk: int = _num_after(prev, "護體")
		var dmg: int = _preview_total_damage(prev)  # 多段攻擊算總傷（含 ×段數），勿用 _num_after 漏掉段數
		var heal: int = _num_after(prev, "治療")
		if is_burst:
			bursts.append({"idx": idx, "nt": nt})
		if is_poison:
			poisons.append({"idx": idx, "nt": nt})
		if blk > 0:
			blocks.append({"idx": idx, "val": blk})
		if heal > 0:
			heals_self.append({"idx": idx, "cost": ccost})
		if dmg > 0:
			attacks.append({"idx": idx, "dmg": dmg, "nt": nt, "cost": ccost})
		# 能力 / 引擎 / 抽牌 / 加能量 — 真正的「發展型」增益才早放（嚴格分類，避免誤殺攻擊牌）
		if type == "能力" or desc.find("每回合") >= 0 or desc.find("攻擊力") >= 0 or desc.find("力量") >= 0 \
				or desc.find("抽") >= 0 or desc.find("靈力") >= 0:
			buffs.append({"idx": idx})

	# 集火目標：先選「這回合打得死」的；否則威脅最高（predicted_damage）；否則血最少
	var best_atk_dmg: int = 0
	for a: Variant in attacks:
		best_atk_dmg = max(best_atk_dmg, int((a as Dictionary).get("dmg", 0)))
	var focus: int = -1
	var focus_killable: bool = false
	var best_threat: int = -1
	for e: Variant in alive:
		var ed: Dictionary = e as Dictionary
		var eidx: int = int(ed.get("idx", 0))
		var ehp: int = int(ed.get("hp", 0)) + int(ed.get("block", 0))
		if best_atk_dmg >= ehp and not focus_killable:
			focus = eidx; focus_killable = true
		var threat: int = int(ed.get("predicted_damage", 0))
		if not focus_killable:
			if threat > best_threat:
				best_threat = threat; focus = eidx
	if focus < 0 and not alive.is_empty():
		focus = int((alive[0] as Dictionary).get("idx", 0))

	# focus 敵人的毒層 + 有效 HP（給阿奴判斷引爆時機用）
	var focus_poison: int = 0
	var focus_ehp: int = 1 << 30
	var has_poison_engine: bool = int(st.get("poison_per_turn", 0)) > 0
	for e: Variant in alive:
		var ed0: Dictionary = e as Dictionary
		if int(ed0.get("idx", -1)) == focus:
			focus_poison = int(ed0.get("poison", 0))
			focus_ehp = int(ed0.get("hp", 0)) + int(ed0.get("block", 0))

	var lethal: bool = incoming > hp + block
	var heavy: bool = incoming >= int(max_hp * 0.33)
	var atk_kill: Dictionary = _max_by(attacks, "dmg") if not attacks.is_empty() else {}

	# ── 決策優先序 ──
	# 1. 引爆：毒流的關鍵在「讓毒滾起來持續 tick」，過早引爆會清空 DoT、自廢武功。
	#    只在以下情形才炸：(a) 引爆可斬殺 focus（毒層×3 ≥ 有效 HP）；
	#    (b) 沒有毒引擎且毒層偏高（無法持續補毒，落袋為安）；
	#    (c) 毒層極高、tick 邊際遞減（衰減 1/回合會浪費，直接變現）。
	#    有毒引擎時門檻拉很高，讓蠱瘴瀰漫每回合疊毒、毒層持續高檔 tick。
	if not bursts.is_empty():
		var burst_dmg: int = focus_poison * 3
		var burst_lethal: bool = burst_dmg >= focus_ehp
		var overstacked: bool = focus_poison >= (18 if has_poison_engine else 10)
		if burst_lethal or overstacked:
			var b: Dictionary = bursts[0]
			return "play %d %d" % [int(b["idx"]), focus] if bool(b["nt"]) else "play %d" % int(b["idx"])
	# 2. 致命威脅：能殺掉威脅源就先殺（除去傷害優於硬擋）→ 否則補血藥 → 否則疊滿格擋
	if lethal:
		if focus_killable and not atk_kill.is_empty():
			return "play %d %d" % [int(atk_kill["idx"]), focus] if bool(atk_kill["nt"]) else "play %d" % int(atk_kill["idx"])
		var pot: String = _auto_pick_potion(view, ["回復", "生命", "護體", "治療"])
		if pot != "":
			return pot
		if not blocks.is_empty():
			var bb: Dictionary = _max_by(blocks, "val")
			return "play %d" % int(bb["idx"])
	# 2.5 進攻藥只在 boss 戰用（雜兵浪費珍貴消耗品）：未斬殺前先用力量藥（沒力量時）/
	#     破綻藥（focus 還沒破綻時）放大整場輸出——越早用、整場受益越多。
	if bool(view.get("is_boss", false)) and not focus_killable:
		if int(me.get("power", 0)) < 3:
			var ppot: String = _auto_pick_potion(view, ["攻擊力", "傷害提升"])
			if ppot != "":
				return ppot
		var focus_vuln: int = 0
		for e: Variant in alive:
			if int((e as Dictionary).get("idx", -1)) == focus:
				focus_vuln = int((e as Dictionary).get("vulnerable", 0))
		if focus_vuln == 0:
			var vpot: String = _auto_pick_potion(view, ["破綻"])
			if vpot != "":
				return vpot
	# 3. 集火能殺 → 殺（減少下回合進場傷害）。
	#    但若這一擊就終結戰鬥（最後一隻、可斬殺），且回血後仍打得死、又沒滿血 →
	#    先用治療牌（靈血咒）回血再補刀：穩贏的最後一回合先把 HP 帶進下一場（會玩的人習慣）。
	if focus_killable and not atk_kill.is_empty():
		if alive.size() == 1 and hp < max_hp and not heals_self.is_empty():
			var hc: Dictionary = heals_self[0]
			if int(hc.get("cost", 0)) + int(atk_kill.get("cost", 0)) <= energy:
				return "play %d" % int(hc["idx"])
		return "play %d %d" % [int(atk_kill["idx"]), focus] if bool(atk_kill["nt"]) else "play %d" % int(atk_kill["idx"])
	# 4. 重擊將至 → 先擋（避免被打殘）
	if heavy and not blocks.is_empty():
		var bb2: Dictionary = _max_by(blocks, "val")
		return "play %d" % int(bb2["idx"])
	# 4.5 血量危險（<25%）且有補血藥 → 主動回血（緊急保命，不浪費）
	if hp < int(max_hp * 0.25):
		var hpot: String = _auto_pick_potion(view, ["回復", "生命", "治療"])
		if hpot != "":
			return hpot
	# 4.6 低血量（<50%）→ 用治療牌（靈血咒）回血續命，不硬撐到危險才補（會玩的人習慣）
	if hp < int(max_hp * 0.5) and not heals_self.is_empty():
		return "play %d" % int((heals_self[0] as Dictionary)["idx"])
	# 5. 發展型能力（力量 / 毒引擎 / 抽牌 / 加能量）— 安全時早放滾雪球
	if not buffs.is_empty():
		return "play %d" % int((buffs[0] as Dictionary)["idx"])
	# 6. 阿奴疊毒：對 focus 施毒讓毒滾起來
	if not poisons.is_empty():
		var ps: Dictionary = poisons[0]
		return "play %d %d" % [int(ps["idx"]), focus] if bool(ps["nt"]) else "play %d" % int(ps["idx"])
	# 7. 最大傷害攻擊打 focus
	if not attacks.is_empty():
		return "play %d %d" % [int(atk_kill["idx"]), focus] if bool(atk_kill["nt"]) else "play %d" % int(atk_kill["idx"])
	# 8. 還有格擋就擋（沒事做時的保底防禦）
	if not blocks.is_empty():
		return "play %d" % int((blocks[0] as Dictionary)["idx"])
	# 9. 保底：手上還有任何負擔得起的牌就打（避免擱置可用資源）
	for c_v: Variant in hand:
		var c: Dictionary = c_v as Dictionary
		if int(c.get("cost", 99)) <= energy:
			var cmd: String = "play %d" % int(c.get("idx", 0))
			if bool(c.get("needs_target", false)):
				cmd += " %d" % focus
			return cmd
	# 9.5 功能藥（最後手段，避免擱置）：能量耗盡但手牌還有牌想打 → 靈力藥解鎖；
	#     手牌將盡 → 抽牌藥（月魂草）續手。雜兵 / boss 皆可用（非珍貴進攻藥）。
	if energy == 0 and hand.size() > 0:
		var epot: String = _auto_pick_potion(view, ["靈力"])
		if epot != "":
			return epot
	if hand.size() <= 2 and int(st.get("draw_pile", 0)) > 0:
		var dpot: String = _auto_pick_potion(view, ["抽 "])
		if dpot != "":
			return dpot
	# 10. 沒有有效動作 → 結束回合
	return "end"

static func _max_by(arr: Array, key: String) -> Dictionary:
	var best: Dictionary = arr[0] as Dictionary
	for v: Variant in arr:
		if int((v as Dictionary).get(key, 0)) > int(best.get(key, 0)):
			best = v as Dictionary
	return best

# 從 battle view 的 options 找符合關鍵字的藥品動作（如補血），回傳 "potion i"；無則 ""。
static func _auto_pick_potion(view: Dictionary, keywords: Array) -> String:
	for o_v: Variant in (view.get("options", []) as Array):
		var o: Dictionary = o_v as Dictionary
		if not String(o.get("id", "")).begins_with("potion"):
			continue
		var detail: String = String(o.get("detail", "")) + String(o.get("label", ""))
		for k: Variant in keywords:
			if detail.find(String(k)) >= 0:
				return String(o.get("id", ""))
	return ""
