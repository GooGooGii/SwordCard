class_name RunState
extends RefCounted

const STARTING_GOLD: int = 45

# Party (1–3 角色) — characters[0] 是隊長、永久不變
var characters: Array[CharacterData] = []
var character_hps: Array[int] = []
var character_max_hps: Array[int] = []
var character_power_bonus: Array[int] = []
var character_decks: Array = []  # Array of Array[CardData] — GDScript 不易宣告巢狀 typed
var active_character_index: int = 0
var character_levels: Array[int] = []   # 每人等級（初始 1，上限 50）
var character_exps: Array[int] = []     # 每人累積經驗值

# 全隊共用的 run 狀態
var act: int = 1
var gold: int = 0
var encounter_index: int = 0
var encounter_choices: Array[Array] = []
var chosen_map_path: Array[int] = []
var pending_rest_heal: int = 0
var current_shop_inventory: Array[Dictionary] = []
var current_shop_potions: Array[Dictionary] = []
var current_shop_is_black: bool = false
var current_shop_relic_ids: Array[String] = []  # 本商店販售的遺物 id（最多 3 種，買掉後移除）
var current_shop_relic_sold_ids: Array[String] = []  # 本商店已售出的遺物 id
var current_shop_node_index: int = -1      # 已開出貨架的 encounter_index；-1 = 尚未開店
var shop_remove_used: bool = false         # 本商店削牌服務是否用過
var shop_upgrade_used: bool = false        # 本商店強化服務是否用過
var current_event_variant: String = "shrine"
var relics: Array[RelicData] = []
var potions: Array[Dictionary] = []   # max MAX_POTION_SLOTS 元素，每個是 PotionCatalog 的一筆
var ascension_level: int = 0
var map_seed: int = 0

# Event Branching (Phase 5+6)
# observe_tokens：全 run 限定的「觀察」資源。起始 3，每幕 boss 勝利 +1，遺物「慧眼」+2 起始。
# next_battle_buffs：下次戰鬥開場注入的 effect 列表（effect kind=next_battle_buff 用）。
# 戰鬥 start_turn 時消費並清空。儲存格式：[{kind:"energy",amount:1}, {kind:"block",amount:5}, ...]
var observe_tokens: int = 3
var next_battle_buffs: Array[Dictionary] = []
# Event Redesign (Phase 3)：跨事件的長尾旗標。記錄「欠某人人情 / 結了梁子 / 撿了某詛咒 /
# 與某妖立契」等，供後續事件的 requires.event_flag / not_event_flag 檢定，做回訪與後果。
# 純加欄位，舊存檔 from_dict 用 data.get("event_flags", {}) 後援，不升 SAVE_VERSION。
var event_flags: Dictionary = {}
# 幕間字卡：已看過開場字卡的最大幕數（純加欄位，舊存檔 default 0 = 下次進地圖補看當幕字卡）
var act_intro_seen: int = 0
# pending_event_return：若非空表示當前進行的戰鬥是事件樹觸發的，戰鬥結束時要
# 結算 victory_effects / defeat_effects 並回地圖，而非走標準 victory 流程。
# 結構：{victory_effects: Array, defeat_effects: Array}
# 不存檔（戰鬥中途離開不保留 in-flight 事件戰鬥）
var pending_event_return: Dictionary = {}

const MAX_POTION_SLOTS: int = 3
# 有效藥格 = 基礎 - Ascension A11 懲罰（至少 1）
func effective_potion_slots() -> int:
	return max(1, MAX_POTION_SLOTS - Ascension.potion_slot_penalty(ascension_level))
const OBSERVE_TOKEN_START: int = 3
const OBSERVE_TOKEN_BOSS_REWARD: int = 1

# Convenience aliases — 對應 active character。讓單角色時期的 main.gd 程式碼幾乎不用改。
var character: CharacterData:
	get:
		if characters.is_empty() or active_character_index >= characters.size():
			return null
		return characters[active_character_index]
	set(value):
		if value == null:
			characters = []
			return
		if characters.is_empty():
			characters.append(value)
			active_character_index = 0
		else:
			characters[active_character_index] = value

var hp: int:
	get:
		if character_hps.is_empty() or active_character_index >= character_hps.size():
			return 0
		return character_hps[active_character_index]
	set(value):
		if active_character_index < character_hps.size():
			character_hps[active_character_index] = value

var max_hp: int:
	get:
		if character_max_hps.is_empty() or active_character_index >= character_max_hps.size():
			return 0
		return character_max_hps[active_character_index]
	set(value):
		if active_character_index < character_max_hps.size():
			character_max_hps[active_character_index] = value

var power_bonus: int:
	get:
		if character_power_bonus.is_empty() or active_character_index >= character_power_bonus.size():
			return 0
		return character_power_bonus[active_character_index]
	set(value):
		if active_character_index < character_power_bonus.size():
			character_power_bonus[active_character_index] = value

var deck: Array[CardData]:
	get:
		if character_decks.is_empty() or active_character_index >= character_decks.size():
			var empty: Array[CardData] = []
			return empty
		return character_decks[active_character_index] as Array[CardData]
	set(value):
		if active_character_index < character_decks.size():
			character_decks[active_character_index] = value

func init_for(chars: Variant) -> void:
	# 接受單 CharacterData（沿用舊呼叫）或 Array[CharacterData]
	var party: Array[CharacterData] = []
	if chars is CharacterData:
		party.append(chars as CharacterData)
	elif chars is Array:
		for c_v: Variant in (chars as Array):
			if c_v is CharacterData:
				party.append(c_v as CharacterData)
	if party.is_empty():
		push_warning("RunState.init_for: empty party")
		return
	characters.clear()
	character_hps.clear()
	character_max_hps.clear()
	character_power_bonus.clear()
	character_decks.clear()
	active_character_index = 0
	character_levels.clear()
	character_exps.clear()
	for c: CharacterData in party:
		characters.append(c)
		character_hps.append(c.max_hp)
		character_max_hps.append(c.max_hp)
		character_power_bonus.append(0)
		character_levels.append(1)
		character_exps.append(0)
		var deck_copy: Array[CardData] = []
		for card: CardData in c.starting_deck:
			deck_copy.append(card.clone())
		character_decks.append(deck_copy)
	act = 1
	gold = STARTING_GOLD
	encounter_index = 0
	encounter_choices = []
	chosen_map_path = []
	pending_rest_heal = 0
	current_shop_inventory = []
	current_shop_potions = []
	current_shop_is_black = false
	current_shop_relic_ids = []
	current_shop_relic_sold_ids = []
	current_shop_node_index = -1
	shop_remove_used = false
	shop_upgrade_used = false
	current_event_variant = "shrine"
	relics.clear()
	potions.clear()
	observe_tokens = OBSERVE_TOKEN_START
	next_battle_buffs.clear()
	pending_event_return = {}
	event_flags = {}
	act_intro_seen = 0
	# 每人各拿自己的 starter weapon
	for c: CharacterData in party:
		var weapons: Array[RelicData] = RelicCatalog.weapons_for_character(c.id)
		if not weapons.is_empty():
			add_relic(weapons[0])

func add_relic(relic: RelicData) -> void:
	if relic == null:
		return
	for existing: RelicData in relics:
		if existing.id == relic.id:
			return  # 不重複拿
	relics.append(relic.clone())
	_apply_acquire_triggers(relic)

func has_relic(relic_id: String) -> bool:
	for r: RelicData in relics:
		if r.id == relic_id:
			return true
	return false

func aggregate_permanent(kind: String) -> int:
	var total: int = 0
	for r: RelicData in relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == kind:
					total += int(e.get("amount", 0))
	return total

func _apply_acquire_triggers(relic: RelicData) -> void:
	for t: Dictionary in relic.triggers:
		if String(t.get("trigger", "")) != "acquire":
			continue
		for e: Dictionary in (t.get("effects", []) as Array):
			var kind: String = String(e.get("kind", ""))
			var amount: int = int(e.get("amount", 0))
			match kind:
				"gold_bonus":
					gold += amount
				"max_hp_bonus":
					# MVP: 只給隊長
					if not character_max_hps.is_empty():
						character_max_hps[0] += amount
						character_hps[0] += amount

func heal(amount: int) -> void:
	# 對 active 角色補血（rest_node / event 的原本語意：補當前玩家）
	if active_character_index >= character_hps.size():
		return
	character_hps[active_character_index] = min(character_max_hps[active_character_index], character_hps[active_character_index] + amount)

func take_damage(amount: int, minimum: int = 1) -> void:
	if active_character_index >= character_hps.size():
		return
	character_hps[active_character_index] = max(minimum, character_hps[active_character_index] - amount)

func sync_hp_from_battle(battle_hp: int) -> void:
	if active_character_index < character_hps.size():
		character_hps[active_character_index] = battle_hp

func is_all_dead() -> bool:
	for h: int in character_hps:
		if h > 0:
			return false
	return true

func alive_character_indices() -> Array[int]:
	var result: Array[int] = []
	for i: int in range(character_hps.size()):
		if character_hps[i] > 0:
			result.append(i)
	return result

func to_dict() -> Dictionary:
	var character_ids: Array[String] = []
	for c: CharacterData in characters:
		character_ids.append(c.id)
	var character_decks_data: Array = []
	for cdeck_v: Variant in character_decks:
		var cdeck: Array = cdeck_v as Array
		var deck_data: Array[Dictionary] = []
		for card: CardData in cdeck:
			deck_data.append(card.to_dict())
		character_decks_data.append(deck_data)
	var relics_data: Array[Dictionary] = []
	for r: RelicData in relics:
		relics_data.append(r.to_dict())
	return {
		"version": 3,
		"act": act,
		"character_ids": character_ids,
		"character_hps": character_hps.duplicate(),
		"character_max_hps": character_max_hps.duplicate(),
		"character_power_bonus": character_power_bonus.duplicate(),
		"character_decks": character_decks_data,
		"active_character_index": active_character_index,
		"character_levels": character_levels.duplicate(),
		"character_exps": character_exps.duplicate(),
		"gold": gold,
		"encounter_index": encounter_index,
		"encounter_choices": _serialize_choices(),
		"chosen_map_path": chosen_map_path.duplicate(),
		"pending_rest_heal": pending_rest_heal,
		"current_shop_inventory": _serialize_shop_inventory(),
		"current_shop_potions": current_shop_potions.duplicate(true),
		"current_shop_is_black": current_shop_is_black,
		"current_shop_relic_ids": current_shop_relic_ids.duplicate(),
		"current_shop_relic_sold_ids": current_shop_relic_sold_ids.duplicate(),
		"current_shop_node_index": current_shop_node_index,
		"shop_remove_used": shop_remove_used,
		"shop_upgrade_used": shop_upgrade_used,
		"current_event_variant": current_event_variant,
		"relics": relics_data,
		"potions": potions.duplicate(),
		"ascension_level": ascension_level,
		"map_seed": map_seed,
		"observe_tokens": observe_tokens,
		"next_battle_buffs": next_battle_buffs.duplicate(),
		"event_flags": event_flags.duplicate(true),
		"act_intro_seen": act_intro_seen,
	}

func from_dict(data: Dictionary, available_characters: Array[CharacterData]) -> bool:
	# SaveManager.migrate 之後 data 必有 character_ids
	var character_ids_v: Variant = data.get("character_ids", null)
	if character_ids_v == null:
		push_warning("RunState.from_dict: missing character_ids — did SaveManager.migrate run?")
		return false
	var ids: Array = character_ids_v as Array
	characters.clear()
	for id_v: Variant in ids:
		var char_id: String = String(id_v)
		if char_id.is_empty():
			return false
		var found: CharacterData = null
		for candidate: CharacterData in available_characters:
			if candidate.id == char_id:
				found = candidate.clone()
				break
		if found == null:
			return false
		characters.append(found)
	character_hps.clear()
	for h_v: Variant in (data.get("character_hps", []) as Array):
		character_hps.append(int(h_v))
	while character_hps.size() < characters.size():
		character_hps.append(characters[character_hps.size()].max_hp)
	character_max_hps.clear()
	for h_v: Variant in (data.get("character_max_hps", []) as Array):
		character_max_hps.append(int(h_v))
	while character_max_hps.size() < characters.size():
		character_max_hps.append(characters[character_max_hps.size()].max_hp)
	character_power_bonus.clear()
	for h_v: Variant in (data.get("character_power_bonus", []) as Array):
		character_power_bonus.append(int(h_v))
	while character_power_bonus.size() < characters.size():
		character_power_bonus.append(0)
	character_decks.clear()
	for cdeck_v: Variant in (data.get("character_decks", []) as Array):
		var cdeck_in: Array = cdeck_v as Array
		var typed_deck: Array[CardData] = []
		for card_v: Variant in cdeck_in:
			if card_v is Dictionary:
				typed_deck.append(CardData.from_dict(card_v as Dictionary))
		character_decks.append(typed_deck)
	while character_decks.size() < characters.size():
		var empty_deck: Array[CardData] = []
		character_decks.append(empty_deck)
	active_character_index = clamp(int(data.get("active_character_index", 0)), 0, max(0, characters.size() - 1))
	character_levels.clear()
	for lv_v: Variant in (data.get("character_levels", []) as Array):
		character_levels.append(int(lv_v))
	while character_levels.size() < characters.size():
		character_levels.append(1)
	character_exps.clear()
	for exp_v: Variant in (data.get("character_exps", []) as Array):
		character_exps.append(int(exp_v))
	while character_exps.size() < characters.size():
		character_exps.append(0)
	gold = int(data.get("gold", 0))
	encounter_index = int(data.get("encounter_index", 0))
	encounter_choices = _deserialize_choices(data.get("encounter_choices", []) as Array, int(data.get("act", 1)), int(data.get("map_seed", 0)))
	chosen_map_path.clear()
	for entry: Variant in (data.get("chosen_map_path", []) as Array):
		chosen_map_path.append(int(entry))
	pending_rest_heal = int(data.get("pending_rest_heal", 0))
	current_shop_inventory = _deserialize_shop_inventory(data.get("current_shop_inventory", []) as Array)
	current_shop_potions = []
	for p_v: Variant in (data.get("current_shop_potions", []) as Array):
		if p_v is Dictionary:
			current_shop_potions.append((p_v as Dictionary).duplicate(true))
	current_shop_is_black = bool(data.get("current_shop_is_black", false))
	current_shop_relic_ids = []
	for rid_v: Variant in (data.get("current_shop_relic_ids", []) as Array):
		current_shop_relic_ids.append(String(rid_v))
	current_shop_relic_sold_ids = []
	for rid_v: Variant in (data.get("current_shop_relic_sold_ids", []) as Array):
		current_shop_relic_sold_ids.append(String(rid_v))
	# 舊存檔相容：單一 current_shop_relic_id → 併入清單
	var legacy_rid: String = String(data.get("current_shop_relic_id", ""))
	if not legacy_rid.is_empty() and not current_shop_relic_ids.has(legacy_rid):
		current_shop_relic_ids.append(legacy_rid)
	current_shop_node_index = int(data.get("current_shop_node_index", -1))
	shop_remove_used = bool(data.get("shop_remove_used", false))
	shop_upgrade_used = bool(data.get("shop_upgrade_used", false))
	current_event_variant = String(data.get("current_event_variant", "shrine"))
	relics.clear()
	for relic_data: Variant in (data.get("relics", []) as Array):
		if relic_data is Dictionary:
			relics.append(RelicData.from_dict(relic_data as Dictionary))
	potions.clear()
	for p_v: Variant in (data.get("potions", []) as Array):
		if p_v is Dictionary:
			potions.append(p_v as Dictionary)
	ascension_level = int(data.get("ascension_level", 0))
	map_seed = int(data.get("map_seed", 0))
	act = int(data.get("act", 1))
	# Event Branching：舊存檔無欄位 → fallback 起始值 / 空陣列
	observe_tokens = int(data.get("observe_tokens", OBSERVE_TOKEN_START))
	next_battle_buffs.clear()
	for buff_v: Variant in (data.get("next_battle_buffs", []) as Array):
		if buff_v is Dictionary:
			next_battle_buffs.append(buff_v as Dictionary)
	event_flags = (data.get("event_flags", {}) as Dictionary).duplicate(true)
	act_intro_seen = int(data.get("act_intro_seen", 0))
	return true

# Event Redesign：設定 / 查詢長尾旗標。value 預設 true，亦可存數值（例如人情次數）。
func set_event_flag(flag: String, value: Variant = true) -> void:
	if flag.is_empty():
		return
	event_flags[flag] = value

func has_event_flag(flag: String) -> bool:
	return event_flags.has(flag) and bool(event_flags[flag])

# Event Redesign：判定 active 角色牌組的主導原型，給 requires.deck_archetype 用。
# 回傳 "poison" / "block" / "power" / "attack" 之一，或 ""（無明顯主導）。
# 規則：統計各原型 effect 出現的卡數，最高者需 >= 3 張且 >= 次高 +1 才算主導。
func deck_archetype() -> String:
	var d: Array[CardData] = deck
	if d.size() < 4:
		return ""
	var counts: Dictionary = {"poison": 0, "block": 0, "power": 0, "attack": 0}
	for card: CardData in d:
		if card == null:
			continue
		var seen: Dictionary = {}
		for e: Dictionary in card.effects:
			var k: String = String(e.get("kind", ""))
			if k.begins_with("poison"):
				seen["poison"] = true
			elif k.begins_with("block"):
				seen["block"] = true
			elif k == "power":
				seen["power"] = true
			elif k == "damage" or k == "damage_all" or k == "consume_energy_damage" or k == "poison_burst":
				seen["attack"] = true
		for key: String in seen:
			counts[key] = int(counts[key]) + 1
	var best: String = ""
	var best_n: int = 0
	var second_n: int = 0
	for key: String in counts:
		var n: int = int(counts[key])
		if n > best_n:
			second_n = best_n
			best_n = n
			best = key
		elif n > second_n:
			second_n = n
	if best_n >= 3 and best_n >= second_n + 1:
		return best
	return ""

# Event Branching：消費 1 個 observe token。回傳是否成功（0 token 時 false）
func consume_observe_token() -> bool:
	if observe_tokens <= 0:
		return false
	observe_tokens -= 1
	return true

# Event Branching：補充 observe token（boss 勝利 / 特定 event）
func grant_observe_tokens(amount: int = 1) -> void:
	if amount <= 0:
		return
	observe_tokens += amount

# Event Branching：把 effects 加入下場戰鬥開場 buff queue
# 戰鬥 start_turn 時 BattleController 應消費這個列表並清空
func queue_next_battle_buff(effects: Array) -> void:
	for e_v: Variant in effects:
		if e_v is Dictionary:
			next_battle_buffs.append(e_v as Dictionary)

# Event Branching：取出並清空 next_battle_buffs（戰鬥開場呼叫）
func consume_next_battle_buffs() -> Array[Dictionary]:
	var out: Array[Dictionary] = next_battle_buffs.duplicate()
	next_battle_buffs.clear()
	return out

func _serialize_choices() -> Array:
	var rows_out: Array = []
	for row: Array in encounter_choices:
		var row_out: Array = []
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_out: Dictionary = {
				"type": node_data.get("type", "battle"),
				"index": node_data.get("index", 0),
				"connects": (node_data.get("connects", []) as Array).duplicate()
			}
			if node_data.has("event_variant"):
				node_out["event_variant"] = node_data["event_variant"]
			if node_data.has("black_market"):
				node_out["black_market"] = node_data["black_market"]
			# 敵人以 id 序列化（讀檔用 GameData.enemy_by_id 重建完整模板，
			# 避免 to_dict 漏 summon_pool 等欄位）。boss = 單數 enemy；戰鬥 = 複數 enemies。
			if node_data.has("enemy") and node_data["enemy"] is EnemyData:
				node_out["enemy_id"] = (node_data["enemy"] as EnemyData).id
			if node_data.has("enemies"):
				var enemy_ids: Array = []
				for e_v: Variant in (node_data["enemies"] as Array):
					if e_v is EnemyData:
						enemy_ids.append((e_v as EnemyData).id)
				node_out["enemy_ids"] = enemy_ids
			row_out.append(node_out)
		rows_out.append(row_out)
	return rows_out

func _deserialize_choices(rows_in: Array, act_for_fallback: int = 1, map_seed_for_fallback: int = 0) -> Array[Array]:
	# 舊壞檔 fallback 才會動到全域 RNG：第一次 fallback 時用決定性 seed（map_seed+act），
	# 確保同一存檔每次讀檔重生的敵人一致；結尾 randomize() 還原非決定性 RNG。
	# 新存檔（敵人已用 id 保存）完全不走 fallback，不碰全域 RNG。
	var used_fallback: bool = false
	var rows_out: Array[Array] = []
	for row_variant: Variant in rows_in:
		var row_in: Array = row_variant as Array
		var row_out: Array[Dictionary] = []
		for node_variant: Variant in row_in:
			var node_data: Dictionary = node_variant as Dictionary
			var node_type: String = String(node_data.get("type", "battle"))
			var node_out: Dictionary = {
				"type": node_type,
				"index": int(node_data.get("index", 0)),
				"connects": []
			}
			var connects_in: Array = node_data.get("connects", []) as Array
			var connects_out: Array[int] = []
			for c: Variant in connects_in:
				connects_out.append(int(c))
			node_out["connects"] = connects_out
			if node_data.has("event_variant"):
				node_out["event_variant"] = String(node_data["event_variant"])
			if node_data.has("black_market"):
				node_out["black_market"] = bool(node_data["black_market"])
			# boss 單敵：新版用 enemy_id；舊版相容 enemy（完整 dict）
			if node_data.has("enemy_id"):
				var be: EnemyData = GameData.enemy_by_id(String(node_data["enemy_id"]))
				if be != null:
					node_out["enemy"] = be.clone()
			elif node_data.has("enemy"):
				node_out["enemy"] = EnemyData.from_dict(node_data["enemy"] as Dictionary)
			# 戰鬥多敵：新版用 enemy_ids；舊版相容 enemies（完整 dict）
			if node_data.has("enemy_ids"):
				var arr: Array[EnemyData] = []
				for id_v: Variant in (node_data["enemy_ids"] as Array):
					var e: EnemyData = GameData.enemy_by_id(String(id_v))
					if e != null:
						arr.append(e.clone())
				node_out["enemies"] = arr
			elif node_data.has("enemies"):
				var arr2: Array[EnemyData] = []
				for e_v: Variant in (node_data["enemies"] as Array):
					arr2.append(EnemyData.from_dict(e_v as Dictionary))
				node_out["enemies"] = arr2
			# 舊壞檔修復：戰鬥節點完全沒有敵人資料（多敵上線前的存檔丟了 enemies）
			# → 用該幕的遭遇表重生一組（決定性 seed，每次讀檔一致）。原本的確切敵人
			# 當初未寫入存檔、物理上無法還原；新存檔不會走到這條路徑（敵人已用 id 保存）。
			if node_type == "battle" and not node_out.has("enemies"):
				if not used_fallback:
					seed(map_seed_for_fallback + act_for_fallback)
					used_fallback = true
				node_out["enemies"] = MapGenerator.choose_enemies_for_act(
					act_for_fallback, GameData.enemies_for_act(act_for_fallback))
			if node_type == "boss" and not node_out.has("enemy"):
				if not used_fallback:
					seed(map_seed_for_fallback + act_for_fallback)
					used_fallback = true
				node_out["enemy"] = GameData.boss_for_act(act_for_fallback).clone()
			row_out.append(node_out)
		rows_out.append(row_out)
	# 還原非決定性 RNG（避免讀檔後的戰鬥/獎勵變成固定序列）
	if used_fallback:
		randomize()
	return rows_out

func _serialize_shop_inventory() -> Array:
	var inventory_out: Array = []
	for item: Dictionary in current_shop_inventory:
		var card: CardData = item.get("card") as CardData
		inventory_out.append({
			"card": card.to_dict() if card != null else {},
			"price": int(item.get("price", 0)),
			"sold": bool(item.get("sold", false))
		})
	return inventory_out

func _deserialize_shop_inventory(inventory_in: Array) -> Array[Dictionary]:
	var inventory_out: Array[Dictionary] = []
	for item_variant: Variant in inventory_in:
		var item: Dictionary = item_variant as Dictionary
		var card_dict: Dictionary = item.get("card", {}) as Dictionary
		inventory_out.append({
			"card": CardData.from_dict(card_dict),
			"price": int(item.get("price", 0)),
			"sold": bool(item.get("sold", false))
		})
	return inventory_out
