class_name BattleController
extends RefCounted

const HAND_SIZE: int = 5
const BASE_TURN_ENERGY: int = 3
const SWITCH_IN_BLOCK: int = 2  # P3-11：切人上場護體（鼓勵主動切人）
const PARTY_ENEMY_HP_STEP: float = 0.85  # P2-10→2026-06-30：每多 1 名隊員敵 HP +85%（原 0.35 仍「免費勝利」=duo/trio 100%）

# 幕間難度縮放（2026-07-09 難度反曲線修正）：run log 實測幕 1-2 boss 有張力（4 回合、掉 ~25 HP），
# 幕 3 起玩家成長超車、boss 常 0-1 回合零傷被斬。幕 3 起敵人 HP / 傷害隨幕數線性拉陡；
# 前兩幕不動（新手體驗不變）。與 party / Ascension 倍率相乘疊加。傷害走既有 enemy_damage_mult
# 管線（EffectResolver 與 CardFormat.predict_enemy_damage 都吃它，意圖預測不失真）。
const ACT_SCALE_FROM_ACT: int = 3    # 從第幾幕開始縮放
const ACT_HP_STEP: float = 0.12      # 每幕敵 HP +12%（幕 8 ×1.72）
const ACT_DMG_STEP: float = 0.05     # 每幕敵傷 +5%（幕 8 ×1.30）

static func act_enemy_hp_mult(act: int) -> float:
	return 1.0 + ACT_HP_STEP * max(0, act - ACT_SCALE_FROM_ACT + 1)

static func act_enemy_dmg_mult(act: int) -> float:
	return 1.0 + ACT_DMG_STEP * max(0, act - ACT_SCALE_FROM_ACT + 1)
const BENCH_HEAL_PER_TURN: int = 1  # 2026-06-30：後排回血 2→1，削組隊「免費續航」（tempo 才是白給瓶頸，非血池）
const MAX_ENEMIES_PER_BATTLE: int = 3
const FEMALE_CHARACTER_IDS: Array[String] = ["zhao_linger", "lin_yueru", "anu"]

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
	# P2-10 組隊白給修正：能量 3+(n-1) → 3+(n-1)/2（2人3、3人4）。
	# 2026-06-30：拔 trio +1 能量試過 → trio 100%→7%（能量 cliff 太粗、duo 不受影響）= 過度修正，
	# 故能量公式保留，改用單一 HP step 旋鈕（見 PARTY_ENEMY_HP_STEP）把 duo/trio 一起壓回有敗場。
	var per_turn_energy: int = BASE_TURN_ENERGY + max(0, party_size - 1) / 2
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
			"is_female": c.id in FEMALE_CHARACTER_IDS,  # 淫賊偷內衣判定
		})
	# 多敵 slot 陣列。
	# P2-10 組隊難度補正：多人隊（能量+1/人、後排回血、切人迴避）實測 vs 中段 boss
	# 勝率 100%（單人最高 83%）= 白給；敵 HP 按隊伍人數補正拉回張力（2 人 ×1.2、3 人 ×1.4）。
	var party_hp_mult: float = 1.0 + PARTY_ENEMY_HP_STEP * max(0, party_size - 1)
	var act_hp_mult: float = act_enemy_hp_mult(run_state.act)  # 幕間縮放（幕 1-2 為 1.0）
	var enemy_slots: Array[Dictionary] = []
	for e: EnemyData in enemies:
		var scaled_hp: int = max(1, int(round(e.max_hp * party_hp_mult * act_hp_mult)))
		enemy_slots.append({
			"id": e.id,
			"name": e.display_name,
			"max_hp": scaled_hp,
			"hp": scaled_hp,
			"block": 0,
			"poison": 0,
			"weak": 0,
			"vulnerable": 0,
			"stunned": 0,
			"silenced": 0,
			"berserk": 0,
			"strength": 0,
			"thorns": 0,
			"artifact": 0,
			"loot_table": GameData.loot_table_for(e.id),
		})
	var active_idx: int = 0
	for i: int in range(enemies.size()):
		if Ascension.is_boss_id(enemies[i].id):
			active_idx = i
			break
	# 機制型敵人開戰告示：把被動規則寫進戰鬥 log（玩家第一眼就知道這場的「題目」）
	for e: EnemyData in enemies:
		var passive_label: String = String(e.passive.get("label", ""))
		if not passive_label.is_empty():
			add_log("【%s】%s" % [e.display_name, passive_label])
	state = {
		"players": players,
		"active_player_index": clamp(run_state.active_character_index, 0, max(0, party_size - 1)),
		"switched_this_turn": false,
		"per_turn_energy": per_turn_energy,
		# Multi-enemy state
		"enemies": enemy_slots,
		"active_enemy_index": active_idx,
		# 以下 enemy_* 是 alias，從 enemies[active_enemy_index] 複製出來
		"enemy_name": enemy_slots[active_idx]["name"],
		"enemy_max_hp": enemy_slots[active_idx]["max_hp"],
		"enemy_hp": enemy_slots[active_idx]["hp"],
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"enemy_stunned": 0,
		"enemy_silenced": 0,
		"enemy_berserk": 0,
		"enemy_loot_table": enemy_slots[active_idx]["loot_table"],
		"energy": per_turn_energy,
		"pending_draw": 0,
		"pending_player_gold": 0,   # 賭棍輸了賞給玩家的銅錢，resolve_enemy_phase 後結算進 run_state
		"lecher_event": 0,          # 淫賊偷內衣演出觸發計數，main.gd 讀取後播動畫/彈窗並清零
		"lecher_stolen": [],        # 淫賊偷走的衣物清單（{name,desc}），擊敗後逐項歸還展示
		"lecher_last_garment": "",  # 最近偷走的一件，演出彈窗用
		"turn": 0,
		"li_discount_used": false,
		"lin_block_used": false,
		"player_artifact": 0,  # 護咒（Artifact）：每層擋掉敵人施加的一個負面狀態（含蠱毒），逐層消耗、不衰減
		"player_thorns": 0,  # 反擊（Thorns）：被攻擊時反彈 N 點傷害給攻擊者，不衰減
		"poison_per_turn": 0,  # 毒引擎（StS Noxious Fumes 式）：每回合開始對全體敵人施毒
		"draw_on_attack": 0,  # 御劍心訣（李）：每打出攻擊牌抽 N
		"draw_on_skill": 0,   # 靈息訣（趙）：每打出技能牌抽 N
		"poison_on_attack": 0,  # 蠱刃：攻擊無格擋敵人時每段施毒（damage / damage_all 讀取）
		"corpse_poison": false,  # 屍蠱：中毒敵人死亡時殘餘蠱毒隨機轉移給其他敵人
		"power_per_turn": 0,  # 靈犀訣（Demon Form）：每回合開始 +N 力量
		"block_per_turn": 0,  # 靈光普照（Metallicize）：每回合開始 +N 護體
		"thorns_per_turn": 0,  # 林家劍陣：每回合開始 +N 荊棘
		"end_turn_damage": 0,  # 五雷轟頂（Combust）：每回合「開始」對全體敵人造成 N 傷害（key 名沿用，結算在 start_turn）
		"next_attack_mult": 1,  # 蓄劍式（Vigor）：下一張攻擊傷害倍率（damage 路徑消耗）
		"block_per_attack": 0,  # 劍舞架式：每出一張攻擊牌獲得 N 護體（play_card 讀取）
		"upgrade_hand_pending": false,  # 臨陣磨槍：升級全手牌（play_card 執行）
		"copy_attack_pending": false,   # 御劍相承：複製手上攻擊牌（play_card 執行）
		"spawn_top_tokens": 0,          # 劍氣縱橫：生成劍氣 token 置於抽牌堆頂（play_card 執行）
		"damage_taken_reduction": 0,
		"damage_out_bonus": 0,
		"block_bonus": 0,
		"heal_bonus": 0,
		"poison_bonus": 0,
		"enemy_damage_mult": act_enemy_dmg_mult(run_state.act),  # 幕間縮放基底；Ascension A2-4 在 caller 疊乘
		"draw_next_turn_bonus": 0,
		"card_played_counts": {},
		"last_attacker_index": 0,  # 林月如反擊指向的敵人
		"player_weak_immune": false,       # 凝神玉（STS Ginger）：免疫敵方施加的虛弱
		"player_vulnerable_immune": false, # 金鐘罩（STS Turnip）：免疫敵方施加的破綻
		# 玩家控制狀態與免疫（行為端待 main.gd；狀態層與免疫已生效）
		"player_stunned": 0, "player_silenced": 0, "player_berserk": 0,
		"player_stun_immune": false,       # 金剛座：免疫暈眩
		"player_silence_immune": false,    # 通靈玉：免疫禁言
		"player_berserk_immune": false,    # 定魂珠：免疫瘋魔
		"steal_result": {},
		"next_card_double": 0,          # 複製丹：下一張(攻擊/技能)牌效果結算兩次
		"revive_charge": 0,             # 仙人遺蛻：瀕死時自動回復此值並存活（一次性）
		"free_cards_this_turn": false,  # 混元丹：本回合手牌費用全部視為 0
		"block_on_exhaust": 0,          # 無痛訣（Feel No Pain）：每消耗 1 張牌 +N 護體
		"draw_on_exhaust": 0,           # 噬牌訣（Dark Embrace）：每消耗 1 張牌抽 N
		"exhaust_hand_pending": 0       # 焚盡訣：消耗手牌其餘所有牌、每張對敵 N 傷（play_card 結算）
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
	state["enemy_stunned"] = slot.get("stunned", 0)
	state["enemy_silenced"] = slot.get("silenced", 0)
	state["enemy_berserk"] = slot.get("berserk", 0)
	state["enemy_strength"] = slot.get("strength", 0)
	state["enemy_thorns"] = slot.get("thorns", 0)
	state["enemy_artifact"] = slot.get("artifact", 0)
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
	slot["stunned"] = int(state.get("enemy_stunned", slot.get("stunned", 0)))
	slot["silenced"] = int(state.get("enemy_silenced", slot.get("silenced", 0)))
	slot["berserk"] = int(state.get("enemy_berserk", slot.get("berserk", 0)))
	slot["strength"] = int(state.get("enemy_strength", slot.get("strength", 0)))
	slot["thorns"] = int(state.get("enemy_thorns", slot.get("thorns", 0)))
	slot["artifact"] = int(state.get("enemy_artifact", slot.get("artifact", 0)))
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
	var fallen_idx: int = _active_index()  # 倒下的（舊 active），換人前先記下
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
				# PAL1 味：上場的隊友對倒下的同伴說一句反應台詞
				var line: String = _downed_reaction_line(i, fallen_idx)
				if not line.is_empty():
					add_log(line)
				add_log("%s 上場接戰！" % state["player_name"])
			return true
	return false

# 隊友倒下 → 換上場者的反應台詞（PAL1 角色情感）。reactor / fallen 為 characters index。
const DOWNED_REACTIONS: Dictionary = {
	"li_xiaoyao": {
		"lin_yueru": "李逍遙：月如！別嚇我……這筆帳，我跟他們算到底！",
		"zhao_linger": "李逍遙：靈兒！撐住，我這就來護著妳！",
		"anu": "李逍遙：阿奴！可惡，倒下的不該是妳！",
		"_default": "李逍遙：倒下一個就少一分勝算……都讓開，我頂上！",
	},
	"zhao_linger": {
		"li_xiaoyao": "趙靈兒：逍遙哥哥！不要——大家退後，剩下的交給我！",
		"_default": "趙靈兒：不能再有人倒下了……我來擋！",
	},
	"lin_yueru": {
		"li_xiaoyao": "林月如：傻瓜，怎麼能讓你先倒下！看我的！",
		"_default": "林月如：哼，倒下的退後，這裡有我林月如在！",
	},
	"anu": {
		"li_xiaoyao": "阿奴：逍遙哥哥別倒下呀！壞人……阿奴叫他們嚐嚐苗疆的毒！",
		"_default": "阿奴：你倒下了……這些壞人，阿奴用毒替你討回來。",
	},
}

func _downed_reaction_line(reactor_idx: int, fallen_idx: int) -> String:
	if run_state == null:
		return ""
	var chars: Array = run_state.characters
	if reactor_idx < 0 or reactor_idx >= chars.size() or fallen_idx < 0 or fallen_idx >= chars.size():
		return ""
	var reactor_id: String = chars[reactor_idx].id
	var fallen_id: String = chars[fallen_idx].id
	var table: Dictionary = DOWNED_REACTIONS.get(reactor_id, {}) as Dictionary
	if table.has(fallen_id):
		return String(table[fallen_id])
	return String(table.get("_default", ""))

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
	# P3-11 切人正向 hook：切入者 +2 護體（鼓勵主動運營切人，而非只在瀕死時逃命）
	state["player_block"] = int(state.get("player_block", 0)) + SWITCH_IN_BLOCK
	_sync_state_to_active()
	var cost_label: String = "" if was_free else "（耗 1 靈力）"
	add_log("換 %s 上場%s，獲得 %d 護體。" % [String(state["player_name"]), cost_label, SWITCH_IN_BLOCK])
	return {"changed": true, "free": was_free}

func add_log(line: String) -> void:
	battle_log.append(line)

func add_logs(lines: Array[String]) -> void:
	battle_log.append_array(lines)

func snapshot_state() -> Dictionary:
	# 多敵：逐敵快照 slot 狀態，讓 UI 能對每隻敵人各算 delta、把浮字飄到正確的頭上。
	var enemy_snaps: Array = []
	for slot_v: Variant in (state.get("enemies", []) as Array):
		var s: Dictionary = slot_v as Dictionary
		enemy_snaps.append({
			"hp": int(s.get("hp", 0)),
			"max_hp": int(s.get("max_hp", 1)),
			"block": int(s.get("block", 0)),
			"poison": int(s.get("poison", 0)),
			"weak": int(s.get("weak", 0)),
			"vulnerable": int(s.get("vulnerable", 0)),
			"stunned": int(s.get("stunned", 0)),
			"silenced": int(s.get("silenced", 0)),
			"berserk": int(s.get("berserk", 0)),
		})
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
		"enemy_vulnerable": int(state["enemy_vulnerable"]),
		"enemies": enemy_snaps,
	}

# ── RunLogger 逐事件記錄（僅在 RunLogger.is_active() 時有負擔；一般模擬 no-op）──
func _enemy_snap_list() -> Array:
	var out: Array = []
	var slots: Array = state.get("enemies", []) as Array
	for i: int in range(slots.size()):
		var s: Dictionary = slots[i] as Dictionary
		out.append({"name": _enemy_display_name_for(i), "hp": int(s.get("hp", 0)), "max_hp": int(s.get("max_hp", 1))})
	return out

func _log_turn_start() -> void:
	if not RunLogger.is_active():
		return
	var hand_names: Array = []
	if deck != null:
		for c_v: Variant in deck.hand:
			hand_names.append((c_v as CardData).display_title())
	RunLogger.log_event("battle", "turn_start", {
		"turn": int(state["turn"]), "energy": int(state["energy"]),
		"player_hp": int(state["player_hp"]), "player_max_hp": int(state.get("player_max_hp", 0)),
		"player_block": int(state["player_block"]),
		"active": _active_index(), "hand": hand_names, "enemies": _enemy_snap_list(),
	})

func _log_card_play(card: CardData, cost: int, before: Dictionary) -> void:
	if not RunLogger.is_active():
		return
	var after: Dictionary = snapshot_state()
	var eb: Array = before.get("enemies", []) as Array
	var ea: Array = after.get("enemies", []) as Array
	var dmg: Array = []
	var total: int = 0
	var statuses: Array = []
	for i: int in range(min(eb.size(), ea.size())):
		var d: int = int((eb[i] as Dictionary)["hp"]) - int((ea[i] as Dictionary)["hp"])
		dmg.append(d)
		if d > 0:
			total += d
		var st: Dictionary = {}
		for key: String in ["poison", "weak", "vulnerable", "stunned"]:
			var delta: int = int((ea[i] as Dictionary).get(key, 0)) - int((eb[i] as Dictionary).get(key, 0))
			if delta != 0:
				st[key] = delta
		if not st.is_empty():
			st["i"] = i
			statuses.append(st)
	RunLogger.log_event("battle", "play_card", {
		"turn": int(state["turn"]), "card": card.display_title(), "ctype": card.card_type, "cost": cost,
		"energy_after": int(state["energy"]),
		"dmg": dmg, "total_dmg": total,
		"block_gained": int(after["player_block"]) - int(before["player_block"]),
		"self_hp_delta": int(after["player_hp"]) - int(before["player_hp"]),
		"statuses": statuses, "enemies": _enemy_snap_list(), "ended": is_battle_over(),
	})

func _log_enemy_phase(before: Dictionary, actions: Array[Dictionary]) -> void:
	if not RunLogger.is_active():
		return
	var acts: Array = []
	for i: int in range(actions.size()):
		var a: Dictionary = actions[i]
		if a.is_empty():
			continue
		acts.append({"i": i, "name": _enemy_display_name_for(i), "intent": String(a.get("intent", ""))})
	RunLogger.log_event("battle", "enemy_action", {
		"turn": int(state["turn"]), "actions": acts,
		"player_hp_before": int(before.get("player_hp", 0)), "player_hp_after": int(state["player_hp"]),
		"player_hp_delta": int(state["player_hp"]) - int(before.get("player_hp", 0)),
		"player_block_after": int(state["player_block"]), "enemies": _enemy_snap_list(),
	})

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
	# 意圖鎖定：剛變身的敵人本回合仍出「變身前已預告的招」（意圖誠實性，見 _transition_enemy_phase）
	var afe_slots: Array = state.get("enemies", []) as Array
	if idx < afe_slots.size():
		var locked_v: Variant = (afe_slots[idx] as Dictionary).get("locked_action", null)
		if locked_v is Dictionary and not (locked_v as Dictionary).is_empty():
			return (locked_v as Dictionary).duplicate(true)
	var e: EnemyData = enemies[idx]
	var active_actions: Array[Dictionary] = e.phase_2_actions if (enemy_phased[idx] and not e.phase_2_actions.is_empty()) else e.actions
	if active_actions.is_empty():
		return {}
	# 大招：每 ultimate_every 個自身回合放一次（enemy_action_indices 為已出手次數，
	# +1 = 即將進行的這回合；命中倍數 → 改放大招，凌駕一般輪替）
	if e.ultimate_every > 0 and not e.ultimate_action.is_empty():
		if (enemy_action_indices[idx] + 1) % e.ultimate_every == 0:
			return e.ultimate_action
	# Ascension A17-19：招式更刁——改挑「傷害最高」的招式（而非照表輪替）
	var asc: int = run_state.ascension_level if run_state != null else 0
	var tier: String = "boss" if Ascension.is_boss_id(e.id) else ("elite" if bool(state.get("battle_is_elite", false)) else "normal")
	if Ascension.harder_movesets(asc, tier):
		var hardest: Dictionary = _highest_damage_action(active_actions)
		if not hardest.is_empty():
			return hardest
	return active_actions[enemy_action_indices[idx] % active_actions.size()]

# 回傳招式組中「總傷害最高」的一招；若全無傷害招式回傳空（呼叫端退回輪替）。
func _highest_damage_action(actions: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = {}
	var best_dmg: int = 0
	for a: Dictionary in actions:
		var dmg: int = 0
		for eff: Dictionary in (a.get("effects", []) as Array):
			var k: String = String(eff.get("kind", ""))
			if k == "damage" or k == "damage_all":
				dmg += int(eff.get("amount", 0)) * max(1, int(eff.get("hits", 1)))
		if dmg > best_dmg:
			best_dmg = dmg
			best = a
	return best

# 禁言過濾：移除招式中所有「法術」效果，只保留純攻擊（傷害）。
# 法術 = 傷害以外的一切（格擋/異常/控制/強化/治療/召喚…），被禁言時全數封印。
# 純法術招（過濾後無傷害）→ 回傳 {}，呼叫端視為「無法出招」。
# 攻擊+異常複合招 → 只留傷害、附帶效果（毒/弱/破綻/格擋等）全部消失。
const SILENCE_KEEP_KINDS: Array[String] = ["damage", "damage_all"]
func silence_filtered_action(action: Dictionary) -> Dictionary:
	if action.is_empty():
		return {}
	var kept: Array = []
	for e_v: Variant in (action.get("effects", []) as Array):
		if String((e_v as Dictionary).get("kind", "")) in SILENCE_KEEP_KINDS:
			kept.append(e_v)
	if kept.is_empty():
		return {}
	var filtered: Dictionary = action.duplicate(true)
	filtered["effects"] = kept
	return filtered

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
	_enforce_phase_gate()
	for i: int in range(enemies.size()):
		var e: EnemyData = enemies[i]
		if enemy_phased[i] or e.phase_2_actions.is_empty():
			continue
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if int(slot["hp"]) <= 0:
			continue  # 死敵不切 phase
		if int(slot["hp"]) * 2 < int(slot["max_hp"]):
			_transition_enemy_phase(i, e, slot)

# 執行第 i 敵的 phase 2 變身（共用：50% 跨線與 phase gate 致死攔截兩條路都走這裡）
func _transition_enemy_phase(i: int, e: EnemyData, slot: Dictionary) -> void:
	# 意圖誠實性（2026-07-10 玩家實測回饋）：玩家是照「變身前預告的意圖」算血出牌的——變身後
	# 若立刻改用未預告的 phase-2 招式攻擊，玩家無從預期就被打死。解法＝鎖定變身前已預告的那一招：
	# 變身當回合仍出「玩家看到的招」，phase-2 招式下回合起才登場（且經正常預告）。
	#（曾試「變身回合硬直不出手」：每場過半血白送玩家一回合，mid 基線 27%→87% 直接炸，棄用。）
	var telegraphed: Dictionary = _action_for_enemy(i)
	enemy_phased[i] = true
	enemy_action_indices[i] = 0
	if not telegraphed.is_empty():
		slot["locked_action"] = telegraphed.duplicate(true)
	# 平衡註記：意圖鎖定讓變身回合少打一記 phase-2 大招 → phase-2 boss 對競速局全面軟化
	#（mid 基線 li 27→73），屬「故意調整」——中段牆的高度不該由未預告的爆發撐起。
	# 基線已重觀測；後續要恢復牆高請調 phase-2 招式數值（誠實手段），不要回退鎖定。
	#（曾試「變身怒氣 +2 力量延遲生效」補償：競速局 boss 來不及入帳、長戰誤傷 duo 97→73，棄用。）
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

# Phase 2 不可跳過（2026-07-10 難度反曲線收尾）：未變身的 phase-2 boss 承受致死傷時
# HP 鎖 1 並「立即變身」，且掛上 slot["phase_guard"]——在敵人階段開始（含它的開場毒 tick）
# 之前不會死亡，保證 boss 至少有一次以新形態出手的機會（玩家仍可用暈眩/禁言封掉那次行動，
# 是合法反制）。爆發流照樣拿到門檻前的全額價值；打不出過量傷害的一般玩家完全無感。
# 不加 HP（尊重「接受爆發為獎勵」決策，BALANCE_REPORT §十）。
# 注意：本函式只攔「致死」。非致死的 50% 跨線變身仍只在玩家出牌/用藥時檢查（_check_phase_transition）——
# 敵人階段的毒 tick 跨線「不」提前變身，維持既有時序（石長老等機制 boss 依賴 phase 1 招式吃毒）。
func _enforce_phase_gate() -> void:
	_sync_state_to_active_enemy()
	var slots: Array = state.get("enemies", []) as Array
	var clamped_active: bool = false
	for i: int in range(mini(enemies.size(), slots.size())):
		var e: EnemyData = enemies[i]
		if e.phase_2_actions.is_empty():
			continue
		var slot: Dictionary = slots[i] as Dictionary
		if int(slot["hp"]) > 0:
			continue
		if enemy_phased[i] and not bool(slot.get("phase_guard", false)):
			continue  # 已變身且保護期已過 → 正常死亡
		slot["hp"] = 1
		add_log("%s 命懸一線，妖力迴光死守殘軀！" % String(slot["name"]))
		if not enemy_phased[i]:
			slot["phase_guard"] = true
			_transition_enemy_phase(i, e, slot)
		if i == _active_enemy_index():
			clamped_active = true
	if clamped_active:
		_sync_active_enemy_to_state()

# 分裂：HP 過半（首次）且戰場未滿時，召出 split_into 指定的分身（每隻只分裂一次）。
# 在 play_card 傷害後與 phase 檢查一起跑，所以斬到半血的瞬間就分裂。
func _check_split() -> void:
	_sync_state_to_active_enemy()
	for i: int in range(enemies.size()):
		var e: EnemyData = enemies[i]
		if e.split_into.is_empty():
			continue
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if bool(slot.get("split_done", false)) or int(slot["hp"]) <= 0:
			continue
		if int(slot["hp"]) * 2 >= int(slot["max_hp"]):
			continue  # 還沒過半
		slot["split_done"] = true
		add_log("%s 一分為二！" % _enemy_display_name_for(i))
		for _n: int in range(max(1, e.split_count)):
			if enemies.size() >= MAX_ENEMIES_PER_BATTLE:
				break
			spawn_enemy(e.split_into)

# 接續 boss（隱龍窟雙妖正史）：某敵死亡且設有 successor 時，滿血召出接續者。
# 在傷害結算後跑（與 split 並列）。successor 滿血登場 → is_victory 此時為 false，
# 戰鬥續打到接續者也倒下。每隻只接續一次（dead slot 標記 successor_done）。
func _check_successors() -> void:
	_sync_state_to_active_enemy()
	for i: int in range(enemies.size()):
		var e: EnemyData = enemies[i]
		if e.successor.is_empty():
			continue
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if bool(slot.get("successor_done", false)):
			continue
		if int(slot["hp"]) > 0:
			continue  # 還沒死
		slot["successor_done"] = true
		add_log("%s 倒下，%s 現身接續！" % [_enemy_display_name_for(i), GameData.enemy_by_id(e.successor).display_name if GameData.enemy_by_id(e.successor) != null else e.successor])
		spawn_enemy(e.successor, false)  # 接續 boss 非召喚物：照常掉落

func effective_card_cost(card: CardData) -> int:
	if bool(state.get("free_cards_this_turn", false)):
		return 0  # 混元丹：本回合所有牌 0 費
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
	# 持久能力引擎：每回合開始 +力量（靈犀訣）/ +護體（靈光普照）
	if int(state.get("power_per_turn", 0)) > 0:
		state["player_power"] = int(state["player_power"]) + int(state["power_per_turn"])
		add_log("靈犀訣：攻擊力 +%d。" % int(state["power_per_turn"]))
	if int(state.get("block_per_turn", 0)) > 0:
		state["player_block"] = int(state["player_block"]) + int(state["block_per_turn"])
		add_log("靈光普照：獲得 %d 護體。" % int(state["block_per_turn"]))
	if int(state.get("thorns_per_turn", 0)) > 0:
		state["player_thorns"] = int(state.get("player_thorns", 0)) + int(state["thorns_per_turn"])
		add_log("林家劍陣：荊棘 +%d。" % int(state["thorns_per_turn"]))
	# 敵人護體不在玩家回合開始清（那會在玩家攻擊前就把敵人剛防的護體抹掉、使敵人防守白費）。
	# 改在 begin_enemy_phase（敵人自己回合開始）清 → StS 規則：護體在「擁有者回合開始」清空。
	state["pending_draw"] = 0
	state["lin_block_used"] = false
	# 2026-06 平衡：李逍遙折扣改「戰鬥前 3 回合，每回合第一張攻擊 -1 費」
	state["li_discount_used"] = int(state["turn"]) > 3
	state["switched_this_turn"] = false
	state["cards_this_turn"] = 0  # 連打計數（華彩 combo_strike 用），每回合歸零
	state["free_cards_this_turn"] = false  # 混元丹效果僅持續使用的當回合
	if int(state["enemy_vulnerable"]) > 0:
		state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	if int(state["enemy_weak"]) > 0:
		state["enemy_weak"] = int(state["enemy_weak"]) - 1
	_apply_bench_heal()
	var before_tick: Dictionary = snapshot_state()
	# 玩家毒在自己回合開始 tick；敵人毒改到敵人階段開始 tick（見 begin_enemy_phase）
	add_logs(resolver.tick_player_statuses(state))
	# Event Branching P4：curse 滯留效果在 tick 之後跑 — 新加的 poison 留到下回合 tick
	if int(state["turn"]) == 1:
		_apply_curse_retention("battle_start")
	_apply_curse_retention("turn_start")
	_sync_state_to_active()
	if is_battle_over():
		return {"before_tick": before_tick, "ended": true}
	# 回合開始觸發「回合開始」遺物（朱雀火/白虎牙/麒麟火膽/妖蛇鱗印的直傷已從 turn_end 移來）。
	_fire_relic_triggers("turn_start")
	_sync_state_to_active_enemy()  # 遺物 enemy_damage 寫的是 alias → 先 commit 進 active slot
	# 五雷轟頂（原 end_turn_damage）：把「毒以外的循環雷傷」改在玩家回合開始結算，
	# 讓玩家一開場就看到敵人真實血量、不會在回合結束被隱性扣血而算錯殺傷。
	var ts_dmg: int = int(state.get("end_turn_damage", 0))
	if ts_dmg > 0:
		var ts_slots: Array = state.get("enemies", []) as Array
		var ts_hit: bool = false
		for ts_i: int in range(ts_slots.size()):
			var ts_slot: Dictionary = ts_slots[ts_i] as Dictionary
			if int(ts_slot["hp"]) <= 0:
				continue
			var ts_blocked: int = min(int(ts_slot.get("block", 0)), ts_dmg)
			ts_slot["block"] = int(ts_slot.get("block", 0)) - ts_blocked
			ts_slot["hp"] = max(0, int(ts_slot["hp"]) - (ts_dmg - ts_blocked))
			ts_hit = true
		if ts_hit:
			add_log("五雷轟頂：回合開始對全體敵人降下 %d 點雷傷！" % ts_dmg)
	_sync_active_enemy_to_state()  # slot→alias 刷新顯示
	_enforce_phase_gate()          # 回合開始的遺物直傷/五雷若致死 → 鎖 1 HP 並變身（不做一般 50% 檢查）
	_process_corpse_poison()       # 屍蠱：回合開始直傷打死的中毒敵殘餘毒轉移
	_check_successors()             # 接續 boss：回合開始蠱毒 tick 打死蛇妖男 → 狐妖女登場
	_check_active_enemy_death()     # active 敵被打死 → 換到下一個活敵
	_sync_state_to_active()
	if is_battle_over():            # 回合開始的傷害可能直接清場 → 勝利
		return {"before_tick": before_tick, "ended": true}
	var draw_count: int = HAND_SIZE + int(state.get("draw_next_turn_bonus", 0))
	state["draw_next_turn_bonus"] = 0
	if deck != null:
		deck.draw(draw_count)
	add_log("第 %d 回合開始，抽 %d 張牌。" % [int(state["turn"]), draw_count])
	_log_turn_start()
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
	# 複製丹（Duplication）：下一張攻擊/技能牌效果再結算一次
	if int(state.get("next_card_double", 0)) > 0 and (card.card_type == "attack" or card.card_type == "skill"):
		state["next_card_double"] = int(state["next_card_double"]) - 1
		add_log("複製丹：「%s」再次發動！" % card.display_title())
		add_logs(resolver.resolve_card(card, state))
	var steal: Dictionary = state.get("steal_result", {}) as Dictionary
	var stolen_item: Dictionary = {}
	if not steal.is_empty():
		stolen_item = steal.duplicate()
		state["steal_result"] = {}
		_apply_stolen_item(steal)
	_check_phase_transition()
	_check_split()
	_check_successors()  # 接續 boss：蛇妖男死 → 狐妖女登場（搶在 is_victory 判定之前）
	_apply_card_play_passive(card)
	_apply_enemy_passives_on_card(card)
	_fire_relic_triggers("card_played", {
		"card_type": card.card_type,
		"card_cost": card.cost,
		"card_effects": card.effects
	})
	# 連打計數（華彩 combo_strike）：先 +1，結算移到下方 alias 同步後（避免讀到未刷新的 active slot）。
	state["cards_this_turn"] = int(state.get("cards_this_turn", 0)) + 1
	# 劍舞架式：每出一張攻擊牌獲得護體
	if card.card_type == "attack" and int(state.get("block_per_attack", 0)) > 0:
		var bpa: int = int(state["block_per_attack"])
		state["player_block"] = int(state["player_block"]) + bpa
		add_log("劍舞架式：出招成勢，獲得 %d 護體。" % bpa)
	if deck != null:
		# 能力牌 STS 規則：打完本場消失（不進棄牌堆、不會再洗回手裡）；
		# power 增益已套到 player_power 持續整場，不需卡片本體留下。
		# exhaust 牌（共同牌等）同樣打完進消耗堆。
		if card.card_type == "power":
			deck.consume_card(card)
		elif card.exhaust:
			deck.exhaust_card(card)
			_on_card_exhausted()  # 消耗流 payoff（無痛訣 / 噬牌訣 / 消耗協同遺物）
		else:
			deck.discard_card(card)
	_process_deck_manipulation()  # 牌庫操作：升級全手牌 / 複製攻擊 / 生成劍氣置頂（此時打出的卡已離手）
	_process_exhaust_hand()  # 焚盡訣：消耗手牌其餘所有牌、依張數對敵造成傷害
	# 出牌引擎：御劍心訣（攻擊牌抽牌）/ 靈息訣（技能牌抽牌）。power 牌本身不觸發（它是 power 型）。
	if card.card_type == "attack" and int(state.get("draw_on_attack", 0)) > 0:
		state["pending_draw"] = int(state["pending_draw"]) + int(state["draw_on_attack"])
	elif card.card_type == "skill" and int(state.get("draw_on_skill", 0)) > 0:
		state["pending_draw"] = int(state["pending_draw"]) + int(state["draw_on_skill"])
	if int(state["pending_draw"]) > 0:
		if deck != null:
			deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0
	_sync_state_to_active()
	_sync_state_to_active_enemy()  # 單體敵人 effects 寫回 active slot
	# 連打引擎結算：此時 active slot 已從 alias 刷新，combo strike 讀 slots 才正確。
	_check_combo_strike()
	_process_corpse_poison()  # 屍蠱：剛被打死的中毒敵人殘餘毒轉移給活敵
	_check_active_enemy_death()  # active 敵被打死 → 自動換到下一個活敵
	_log_card_play(card, cost, before_card)
	return {"affordable": true, "before_card": before_card, "ended": is_battle_over(), "stolen_item": stolen_item}

# 消耗流 on-exhaust 觸發：每消耗 1 張牌 → 無痛訣(+護體) / 噬牌訣(抽牌) / 消耗協同遺物。
# 由 play_card 的 exhaust 分支與 _process_exhaust_hand 對每張被消耗的牌呼叫一次。
func _on_card_exhausted(count: int = 1) -> void:
	for _i: int in range(count):
		var b: int = int(state.get("block_on_exhaust", 0))
		if b > 0:
			state["player_block"] = int(state["player_block"]) + b
			add_log("無痛訣：消耗一張牌，獲得 %d 護體。" % b)
		var d: int = int(state.get("draw_on_exhaust", 0))
		if d > 0:
			state["pending_draw"] = int(state["pending_draw"]) + d
		_fire_relic_triggers("card_exhausted")

# 焚盡訣：消耗手牌其餘所有牌，每消耗 1 張對 active 敵造成 amount 傷害。
# resolver 的 exhaust_hand_damage effect 只設旗標（它無法存取 deck），實際消耗在這裡做。
func _process_exhaust_hand() -> void:
	var per_card: int = int(state.get("exhaust_hand_pending", 0))
	if per_card <= 0 or deck == null:
		return
	state["exhaust_hand_pending"] = 0
	var hand_copy: Array = deck.hand.duplicate()
	var n: int = hand_copy.size()
	for c_v: Variant in hand_copy:
		deck.exhaust_card(c_v as CardData)
		_on_card_exhausted()
	if n > 0:
		add_log("焚盡訣：燃盡 %d 張牌！" % n)
		add_logs(resolver._resolve_effect({"kind": "damage", "amount": per_card * n}, state))
	# 被消耗的牌可能觸發抽牌（噬牌訣），結算 pending_draw
	if int(state.get("pending_draw", 0)) > 0:
		deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0

# 仙人遺蛻：active 玩家瀕死（HP <= 0）時，若已備妥復活之力，回復並存活（一次性）。
# 在敵人 action 結算後呼叫，搶在 is_defeat / 強制換人之前。
func _check_player_revive() -> void:
	if int(state.get("player_hp", 1)) > 0:
		return
	var charge: int = int(state.get("revive_charge", 0))
	if charge <= 0:
		return
	state["revive_charge"] = 0
	state["player_hp"] = charge
	_sync_state_to_active()  # 寫回 active slot，避免 is_defeat 仍判定陣亡
	add_log("仙人遺蛻：瀕死之際靈光護身，回復 %d 生命！" % charge)

# active 敵 HP <= 0 時，自動切換 active 到第一個活敵
# 屍蠱：掃描剛死且仍帶蠱毒的敵人，把殘餘蠱毒隨機轉移給一個還活著的敵人（轉移後清零，只轉一次）。
# 由 play_card（傷害後）與 begin_enemy_phase（毒 tick 後）呼叫，僅在 state["corpse_poison"] 開啟時生效。
func _process_corpse_poison() -> void:
	if not bool(state.get("corpse_poison", false)):
		return
	var slots: Array = state.get("enemies", []) as Array
	var living: Array[int] = []
	for i: int in range(slots.size()):
		if int((slots[i] as Dictionary)["hp"]) > 0:
			living.append(i)
	if living.is_empty():
		return
	var moved: bool = false
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i] as Dictionary
		if int(slot["hp"]) <= 0 and int(slot.get("poison", 0)) > 0:
			var carried: int = int(slot["poison"])
			slot["poison"] = 0
			var t: int = living[randi() % living.size()]
			var tgt: Dictionary = slots[t] as Dictionary
			tgt["poison"] = int(tgt.get("poison", 0)) + carried
			add_log("屍蠱：%s 殘餘 %d 層蠱毒轉移給 %s！" % [String(slot["name"]), carried, String(tgt["name"])])
			moved = true
	if moved:
		_sync_active_enemy_to_state()

# 牌庫操作（Layer 4）：全自動目標（不需戰鬥內選牌 UI），打出的卡已離手後執行。
func _process_deck_manipulation() -> void:
	if deck == null:
		return
	# 臨陣磨槍：升級手上所有未升級的非詛咒牌（本場）
	if bool(state.get("upgrade_hand_pending", false)):
		state["upgrade_hand_pending"] = false
		var upgraded_n: int = 0
		for i: int in range(deck.hand.size()):
			var c: CardData = deck.hand[i]
			if not c.upgraded and c.card_type != "curse":
				deck.hand[i] = c.upgraded_copy()
				upgraded_n += 1
		if upgraded_n > 0:
			add_log("臨陣磨槍：手牌 %d 張全數升級！" % upgraded_n)
	# 御劍相承：複製手上第一張攻擊牌，加入手牌
	if bool(state.get("copy_attack_pending", false)):
		state["copy_attack_pending"] = false
		for c: CardData in deck.hand:
			if c.card_type == "attack":
				deck.hand.append(c.clone())
				add_log("御劍相承：複製【%s】。" % c.display_name)
				break
	# 劍氣縱橫：生成 N 道劍氣 token 置於抽牌堆頂（draw() 從尾端 pop，故 append = 置頂）
	var ntok: int = int(state.get("spawn_top_tokens", 0))
	if ntok > 0:
		state["spawn_top_tokens"] = 0
		for _i: int in range(ntok):
			deck.draw_pile.append(GameData.jianqi_token())
		add_log("劍氣縱橫：%d 道劍氣納入抽牌堆頂。" % ntok)

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

# 連打引擎（華彩 / Panache）：本回合出牌數達 threshold 倍數時，對全體活敵造成固定傷害。
func _check_combo_strike() -> void:
	var dmg: int = int(state.get("combo_strike_damage", 0))
	if dmg <= 0:
		return
	var threshold: int = max(1, int(state.get("combo_strike_threshold", 5)))
	if int(state.get("cards_this_turn", 0)) % threshold != 0:
		return
	var slots: Array = state.get("enemies", []) as Array
	var hit_any: bool = false
	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i] as Dictionary
		if int(slot["hp"]) <= 0:
			continue
		var blocked: int = min(int(slot.get("block", 0)), dmg)
		slot["block"] = int(slot.get("block", 0)) - blocked
		slot["hp"] = max(0, int(slot["hp"]) - (dmg - blocked))
		hit_any = true
	if hit_any:
		add_log("華彩劍意：連打成勢，對全體敵人造成 %d 點傷害！" % dmg)
		_sync_active_enemy_to_state()

func begin_enemy_phase() -> Array[Dictionary]:
	# Multi-Enemy 模式：每隻活敵各預備一招，回傳陣列（死敵 = empty dict）
	# 1v1 退化情況：array size == 1
	# StS 規則：護體在「擁有者回合開始」清空。敵人回合（此處）開始先清掉所有敵人上一輪殘留的
	# 護體，再由下方 passives（護持戰陣 aura）/ 各敵 block 招式補上新護體 → 新護體會留到玩家下回合、
	# 真正擋住玩家攻擊（修正：原本在 start_turn 清，導致敵人剛防的護體在玩家攻擊前就被抹掉、防守白費）。
	for clr_slot_v: Variant in (state["enemies"] as Array):
		(clr_slot_v as Dictionary)["block"] = 0
	state["enemy_block"] = 0
	# turn_end 遺物：保留「非直傷」效果（雷震子破綻、紫府符/雪魂符護體治療、引魂燈施毒、
	# 屍王符令施毒+回血、玄武魂護體保留）。直傷型（朱雀火/白虎牙/兩個神器）已改在 start_turn 結算。
	_fire_relic_triggers("turn_end")
	_apply_enemy_phase_passives()
	# 五雷轟頂的雷傷（end_turn_damage）已移至 start_turn（玩家回合開始）結算，此處不再扣血。
	if deck != null:
		deck.discard_hand()
	if int(state["player_weak"]) > 0:
		state["player_weak"] = int(state["player_weak"]) - 1
	if int(state["player_vulnerable"]) > 0:
		state["player_vulnerable"] = int(state["player_vulnerable"]) - 1
	# StS 時機：敵人毒在「出手前」tick → 致命毒可在它攻擊前殺死它（對毒流關鍵）。
	# 接著毒引擎（瘴蠱纏身）對全體敵人補毒，供下一輪 tick。
	add_logs(resolver.tick_enemy_statuses(state))
	var poison_engine: int = int(state.get("poison_per_turn", 0))
	if poison_engine > 0:
		add_logs(resolver.resolve_effects_list([{"kind": "poison_all", "amount": poison_engine}], state))
	_enforce_phase_gate()  # 毒 tick 致死 → 鎖 1 HP 並變身；非致死跨線不在此變身（見函式註解）
	# phase guard 到此為止：撐過玩家爆發回合＋開場毒 tick 後解除，boss 接著出手；
	# 之後（荊棘反噬、下回合傷害）皆可正常擊殺。
	for guard_slot_v: Variant in (state["enemies"] as Array):
		(guard_slot_v as Dictionary).erase("phase_guard")
	_process_corpse_poison()  # 屍蠱：毒死的敵人殘餘毒轉移給活敵
	_check_active_enemy_death()  # 毒死 active 敵 → 換到下一個活敵
	_sync_state_to_active()
	if is_victory():
		return []  # 全部敵人被毒死，無人出手
	var actions: Array[Dictionary] = []
	for i: int in range(enemies.size()):
		var slot: Dictionary = state["enemies"][i] as Dictionary
		if int(slot["hp"]) <= 0:
			actions.append({})  # 死敵跳過
			continue
		if int(slot.get("stunned", 0)) > 0:
			slot["stunned"] = int(slot["stunned"]) - 1  # 暈眩：消耗一層、跳過本回合出手
			slot.erase("locked_action")  # 被暈掉的預告招作廢；下回合起 phase-2 正常預告輪替
			actions.append({})
			add_log("%s 暈眩，無法行動！" % _enemy_display_name_for(i))
			continue
		var was_locked: bool = slot.has("locked_action")
		var action: Dictionary = _action_for_enemy(i)  # was_locked 時回傳鎖定的預告招
		if was_locked:
			slot.erase("locked_action")  # 預告招用掉；index 不推進，下回合從 phase-2 第一招開始
		# 禁言：過濾掉所有法術效果（異常/控制/強化/治療/召喚），只保留物理（攻擊/格擋）。
		# 純法術招 → 無法出招；攻擊+異常招 → 攻擊照常、附帶狀態消失。每被禁言回合消耗一層。
		if int(slot.get("silenced", 0)) > 0:
			slot["silenced"] = int(slot["silenced"]) - 1
			var orig_count: int = (action.get("effects", []) as Array).size()
			var filtered: Dictionary = silence_filtered_action(action)
			if filtered.is_empty():
				if not was_locked:
					enemy_action_indices[i] = enemy_action_indices[i] + 1
				actions.append({})
				add_log("%s 被禁言，法術無法施放！" % _enemy_display_name_for(i))
				continue
			if (filtered.get("effects", []) as Array).size() != orig_count:
				add_log("%s 被禁言，法術效果被封印，只能強攻！" % _enemy_display_name_for(i))
			action = filtered
		if not was_locked:
			enemy_action_indices[i] = enemy_action_indices[i] + 1
		actions.append(action)
		add_log("%s 準備施放：%s。" % [_enemy_display_name_for(i), String(action.get("intent", ""))])
	return actions

func resolve_enemy_phase(actions: Variant) -> Dictionary:
	# 向後相容：actions 可為 Array[Dictionary]（multi-enemy）或單一 Dictionary（legacy 1v1 caller）
	# UI 逐隻出手節奏走三段式 API：begin_enemy_resolution → resolve_one_enemy × N → finish_enemy_resolution
	# （main.gd 在每隻之間插動畫/浮字）；模擬器/測試維持本函式一次呼叫，行為相同。
	var action_list: Array[Dictionary] = []
	if actions is Dictionary:
		action_list.append(actions as Dictionary)
	elif actions is Array:
		for a: Variant in (actions as Array):
			action_list.append((a as Dictionary) if a is Dictionary else {})
	var ctx: Dictionary = begin_enemy_resolution()
	for i: int in range(action_list.size()):
		resolve_one_enemy(i, action_list[i])
		# 玩家若被打死，戰鬥結束，不繼續處理後面敵人
		if is_defeat():
			break
	return finish_enemy_resolution(ctx, action_list)

func begin_enemy_resolution() -> Dictionary:
	# 敵方結算前快照：before_enemy 給 UI 算 delta / RunLogger，saved_active 供結算後還原
	return {"before_enemy": snapshot_state(), "saved_active": _active_enemy_index()}

func resolve_one_enemy(i: int, action: Dictionary) -> void:
	# 結算第 i 隻敵人的一招。死敵 / 空 action（暈眩、被禁言封死）直接跳過。
	if action.is_empty():
		return
	if i >= (state["enemies"] as Array).size():
		return
	var slot: Dictionary = state["enemies"][i] as Dictionary
	if int(slot["hp"]) <= 0:
		return
	# 切 active 到 i，讓 enemy_weak / enemy_block alias 反映該敵
	if i != _active_enemy_index():
		_sync_state_to_active_enemy()
		state["active_enemy_index"] = i
		_sync_active_enemy_to_state()
	# 瘋魔：失控。25% 呆立不動；否則攻擊招隨機選目標（可能誤擊友軍敵人）
	if int(slot.get("berserk", 0)) > 0:
		slot["berserk"] = int(slot["berserk"]) - 1
		if randf() < 0.25:
			add_log("%s 瘋魔發作，呆立不動！" % _enemy_display_name_for(i))
			return
		if CardFormat.action_has_damage(action):
			var candidates: Array[int] = [-1]  # -1 = 玩家
			for j: int in range(state["enemies"].size()):
				if j != i and int((state["enemies"][j] as Dictionary)["hp"]) > 0:
					candidates.append(j)
			var pick: int = candidates[randi() % candidates.size()]
			if pick >= 0:
				_berserk_strike_enemy(action, i, pick)
				_process_pending_summons(i)
				return  # 誤擊友軍 → 不再打玩家
			# pick == -1 → 照常攻擊玩家（往下走正常流程）
	add_log("%s：%s。" % [_enemy_display_name_for(i), String(action.get("intent", ""))])
	add_logs(resolver.resolve_enemy_action(action, state))
	_sync_state_to_active_enemy()
	_check_player_revive()  # 仙人遺蛻：active 瀕死自動保命（搶在 is_defeat 之前）
	# 林月如反擊指向最後一個對玩家造成傷害的敵人
	if CardFormat.action_has_damage(action):
		state["last_attacker_index"] = i
	# 處理該敵 action 內的召喚請求
	_process_pending_summons(i)

func finish_enemy_resolution(ctx: Dictionary, action_list: Array[Dictionary]) -> Dictionary:
	var before_enemy: Dictionary = ctx["before_enemy"] as Dictionary
	var saved_active: int = int(ctx["saved_active"])
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
	# 賭棍輸掉賞給玩家的銅錢，結算進 run_state
	var won_gold: int = int(state.get("pending_player_gold", 0))
	if won_gold > 0:
		state["pending_player_gold"] = 0
		if run_state != null:
			run_state.gold += won_gold
		add_log("你從賭局贏得 %d 枚銅錢。" % won_gold)
	_log_enemy_phase(before_enemy, action_list)
	return {"before_enemy": before_enemy, "ended": is_battle_over()}

# 召喚機制：EffectResolver 的 "summon" effect 會把請求加進 state["pending_summons"]
# 在每隻敵人的 action 結算完後呼叫此函式處理
## 瘋魔誤擊：把 action 的傷害（damage / damage_all 總和）施加到指定友軍敵人 slot
func _berserk_strike_enemy(action: Dictionary, attacker_idx: int, target_idx: int) -> void:
	var enemy_slots: Array = state.get("enemies", []) as Array
	if target_idx < 0 or target_idx >= enemy_slots.size():
		return
	var tgt: Dictionary = enemy_slots[target_idx] as Dictionary
	var total: int = 0
	for ef_v: Variant in (action.get("effects", []) as Array):
		var ef: Dictionary = ef_v as Dictionary
		var k: String = String(ef.get("kind", ""))
		if k == "damage" or k == "damage_all":
			total += int(ef.get("amount", 0)) * max(1, int(ef.get("hits", 1)))
	if total <= 0:
		return
	var blocked: int = min(int(tgt.get("block", 0)), total)
	tgt["block"] = int(tgt.get("block", 0)) - blocked
	tgt["hp"] = max(0, int(tgt["hp"]) - (total - blocked))
	add_log("瘋魔！%s 失控攻擊了 %s，造成 %d 點傷害！" % [_enemy_display_name_for(attacker_idx), _enemy_display_name_for(target_idx), total - blocked])
	_sync_active_enemy_to_state()
	_check_active_enemy_death()

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
func spawn_enemy(enemy_id: String, mark_summoned: bool = true) -> bool:
	if enemies.size() >= MAX_ENEMIES_PER_BATTLE:
		add_log("戰場已滿，召喚未成。")
		return false
	var template: EnemyData = GameData.enemy_by_id(enemy_id)
	if template == null:
		push_warning("BattleController.spawn_enemy: unknown enemy id '%s'" % enemy_id)
		return false
	var clone: EnemyData = template.clone()
	# mark_summoned=false：接續 boss（如狐妖女）視為正規 boss，照常掉落 / 計入獎勵
	clone.is_summoned = mark_summoned
	enemies.append(clone)
	enemy_action_indices.append(0)
	enemy_phased.append(false)
	# 幕間縮放也套用到召喚物/接續 boss（如水魔獸）——否則終幕接續 boss 停留在未縮放數值。
	# 注意：party 倍率沿革上未套（召喚物本就設計為較弱），維持現狀不動。
	var spawn_hp: int = max(1, int(round(clone.max_hp * act_enemy_hp_mult(run_state.act if run_state != null else 1))))
	var slot: Dictionary = {
		"id": clone.id,
		"name": clone.display_name,
		"max_hp": spawn_hp,
		"hp": spawn_hp,
		"block": 0,
		"poison": 0,
		"weak": 0,
		"vulnerable": 0,
		"stunned": 0,
		"silenced": 0,
		"berserk": 0,
		"strength": 0,
		"thorns": 0,
		"artifact": 0,
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
	if filter.has("every_n"):
		# 每出 N 張（符合前面其他 filter 的）牌觸發一次。計數累積整場戰鬥。
		var n: int = max(1, int(filter["every_n"]))
		var ec: Dictionary = state.get("card_played_counts", {}) as Dictionary
		var ekey: String = "everyn_" + relic_id
		var tally: int = int(ec.get(ekey, 0)) + 1
		ec[ekey] = tally
		state["card_played_counts"] = ec
		if tally % n != 0:
			return false
	return true

func _apply_trigger_effects(effects: Array, relic_name: String) -> void:
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"self_heal":
				var actual: int = maxi(0, amount + int(state.get("heal_bonus", 0)))
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
			"self_thorns":
				state["player_thorns"] = int(state.get("player_thorns", 0)) + amount
				add_log("【%s】獲得 %d 點荊棘。" % [relic_name, amount])
			"self_artifact":
				state["player_artifact"] = int(state.get("player_artifact", 0)) + amount
				add_log("【%s】結起 %d 層護咒（擋負面狀態）。" % [relic_name, amount])
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
			"enemy_stun":
				state["enemy_stunned"] = int(state.get("enemy_stunned", 0)) + amount
				_sync_state_to_active_enemy()
				add_log("【%s】敵人暈眩 %d 回合。" % [relic_name, amount])
			"enemy_silence":
				state["enemy_silenced"] = int(state.get("enemy_silenced", 0)) + amount
				_sync_state_to_active_enemy()
				add_log("【%s】敵人被禁言 %d 回合。" % [relic_name, amount])
			"enemy_berserk":
				state["enemy_berserk"] = int(state.get("enemy_berserk", 0)) + amount
				_sync_state_to_active_enemy()
				add_log("【%s】敵人陷入瘋魔 %d 回合。" % [relic_name, amount])
			"immune_weak":
				state["player_weak_immune"] = true
				add_log("【%s】本場免疫虛弱。" % relic_name)
			"immune_vulnerable":
				state["player_vulnerable_immune"] = true
				add_log("【%s】本場免疫破綻。" % relic_name)
			"immune_stun":
				state["player_stun_immune"] = true
				add_log("【%s】本場免疫暈眩。" % relic_name)
			"immune_silence":
				state["player_silence_immune"] = true
				add_log("【%s】本場免疫禁言。" % relic_name)
			"immune_berserk":
				state["player_berserk_immune"] = true
				add_log("【%s】本場免疫瘋魔。" % relic_name)
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
			if run_state.potions.size() < run_state.effective_potion_slots():
				var potion_id: String = String(item.get("potion_id", ""))
				var potion: Dictionary = PotionCatalog.by_id(potion_id)
				if not potion.is_empty():
					run_state.potions.append(potion)
					add_log("【飛龍探雲手】獲得 %s（已存入藥格）。" % item.get("display_name", "藥品"))
				else:
					add_log("【飛龍探雲手】偷取失敗（藥品資料遺失）。")
			else:
				add_log("【飛龍探雲手】藥格已滿，選擇是否替換「%s」。" % item.get("display_name", "藥品"))

# 機制型敵人被動（敵方回合開始結算，2026-06-11 全幕鋪開）：
# - enrage_after {turns, amount}：倒數狂化——出手滿 N 次後一次性 +amount 力量
#   （蜂蛹孵化/殭屍王屍變/赤鬼王怨念沸騰）。意圖告示靠開戰 log + 狂化時 log。
# - ally_block_aura {amount}：護持光環——持有者活著時，其他活敵每回合 +amount 護體
#   （黑苗頭領號令/傀儡女絲線）。counterplay：先殺光環源，集火順序成為題目。
func _apply_enemy_phase_passives() -> void:
	var slots: Array = state.get("enemies", []) as Array
	for i: int in range(enemies.size()):
		if i >= slots.size():
			break
		var slot: Dictionary = slots[i] as Dictionary
		if int(slot.get("hp", 0)) <= 0:
			continue
		var pas: Dictionary = enemies[i].passive
		match String(pas.get("kind", "")):
			"enrage_after":
				if not bool(slot.get("enraged", false)) and enemy_action_indices[i] >= int(pas.get("turns", 3)):
					var amt: int = int(pas.get("amount", 5))
					slot["enraged"] = true
					slot["strength"] = int(slot.get("strength", 0)) + amt
					if i == _active_enemy_index():
						state["enemy_strength"] = int(state.get("enemy_strength", 0)) + amt
					add_log("%s %s" % [String(slot.get("name", "敵人")), String(pas.get("on_trigger", "狂化了！力量 +%d！" % amt))])
			"ally_block_aura":
				var aura: int = int(pas.get("amount", 4))
				var shielded: int = 0
				for j: int in range(slots.size()):
					if j == i:
						continue
					var ally: Dictionary = slots[j] as Dictionary
					if int(ally.get("hp", 0)) <= 0:
						continue
					ally["block"] = int(ally.get("block", 0)) + aura
					shielded += 1
				if shielded > 0:
					_sync_active_enemy_to_state()
					add_log("%s 護持戰陣：其他敵人各 +%d 護體。" % [String(slot.get("name", "敵人")), aura])

# 機制型敵人被動（2026-06-11 試點）：strength_on_player_skill ——
# 玩家每出一張「技能牌」，持有此被動的活敵 +N 力量（鎮獄明王「業鏡照心」）。
# 龜縮疊盾餵養它、攻擊牌不觸發 → 懲罰拖延，逼玩家換打法。
func _apply_enemy_passives_on_card(card: CardData) -> void:
	if card.card_type != "skill":
		return
	var slots: Array = state.get("enemies", []) as Array
	for i: int in range(enemies.size()):
		var pas: Dictionary = enemies[i].passive
		if String(pas.get("kind", "")) != "strength_on_player_skill":
			continue
		if i >= slots.size() or int((slots[i] as Dictionary).get("hp", 0)) <= 0:
			continue
		var amt: int = int(pas.get("amount", 1))
		var slot: Dictionary = slots[i] as Dictionary
		slot["strength"] = int(slot.get("strength", 0)) + amt
		if i == _active_enemy_index():
			state["enemy_strength"] = int(state.get("enemy_strength", 0)) + amt
		add_log("%s 業鏡照心：力量 +%d！" % [String(slot.get("name", "敵人")), amt])

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
