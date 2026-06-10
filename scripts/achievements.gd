class_name Achievements
extends RefCounted

# 成就系統（IMPROVEMENT_PLAN P2-7）：首批 30 條，全部用「現成資料」判定
# （Bestiary / Ascension / RunHistory / RunState / 戰鬥 state），不為成就加新統計欄位。
# 需要新統計的（累計總傷害、單回合爆發…）列第二批，之後再說。
# 解鎖紀錄存 user://achievements.cfg（跨 run，同 Bestiary 模式）。

const PATH: String = "user://achievements.cfg"
const SECTION: String = "unlocked"

# ctx 由呼叫端組：
#   kind: "battle_victory"（每場戰鬥勝利後）/ "run_victory"（通關）/ "run_end"（含戰敗）
#   run_state: RunState（可 null）
#   battle: BattleController（battle_victory 時帶，可 null）
static func definitions() -> Array[Dictionary]:
	return [
		# ── 里程碑（跨 run 持久資料）──
		{"id": "first_victory",  "title": "初戰告捷",   "desc": "完成第一次通關。"},
		{"id": "li_victory",     "title": "御劍乘風",   "desc": "以李逍遙為隊長通關。"},
		{"id": "zhao_victory",   "title": "靈兒的旅程", "desc": "以趙靈兒為隊長通關。"},
		{"id": "lin_victory",    "title": "林家堡之光", "desc": "以林月如為隊長通關。"},
		{"id": "anu_victory",    "title": "蠱仙娃娃",   "desc": "以阿奴為隊長通關。"},
		{"id": "trio_victory",   "title": "三人同行",   "desc": "以滿編三人隊通關。"},
		{"id": "solo_victory",   "title": "孤膽劍俠",   "desc": "單人通關。"},
		{"id": "a5_clear",       "title": "嶄露頭角",   "desc": "通過難度 A5。"},
		{"id": "a10_clear",      "title": "漸入佳境",   "desc": "通過難度 A10。"},
		{"id": "a20_clear",      "title": "登峰造極",   "desc": "通過難度 A20。"},
		{"id": "bestiary_20",    "title": "識妖錄",     "desc": "敵將圖鑑收錄 20 種。"},
		{"id": "bestiary_50",    "title": "萬妖譜",     "desc": "敵將圖鑑收錄 50 種。"},
		{"id": "kills_100",      "title": "百戰沙場",   "desc": "累計擊敗 100 名敵人。"},
		{"id": "boss_hunter",    "title": "屠魔錄",     "desc": "九大頭目各擊敗至少一次。"},
		{"id": "veteran_10",     "title": "老江湖",     "desc": "征途錄累計 10 輪冒險。"},
		# ── 通關時的 run 狀態 ──
		{"id": "rich_victory",   "title": "富甲一方",   "desc": "通關時持有 400 枚以上銅錢。"},
		{"id": "poor_victory",   "title": "兩袖清風",   "desc": "通關時銅錢不足 20 枚。"},
		{"id": "lean_deck",      "title": "精兵簡政",   "desc": "通關時全隊牌組合計不超過 18 張。"},
		{"id": "relic_14",       "title": "法寶滿堂",   "desc": "通關時持有 14 件以上遺物。"},
		{"id": "level_20",       "title": "爐火純青",   "desc": "通關時任一角色等級達 20。"},
		{"id": "fox_karma",      "title": "狐緣善果",   "desc": "放走狐女並通關。"},
		{"id": "jade_light",     "title": "女媧遺澤",   "desc": "持女媧玉通關。"},
		{"id": "full_potions",   "title": "有備無患",   "desc": "通關時藥格全滿。"},
		# ── 單場戰鬥勝利時 ──
		{"id": "triple_kill",    "title": "一網打盡",   "desc": "單場戰鬥擊敗三名敵人。"},
		{"id": "untouched",      "title": "全身而退",   "desc": "戰鬥勝利時當前角色滿血。"},
		{"id": "last_stand",     "title": "背水一戰",   "desc": "全隊僅剩一人存活時取得勝利（三人隊）。"},
		{"id": "poison_15",      "title": "萬毒攻心",   "desc": "敵人身上疊到 15 層蠱毒並取勝。"},
		{"id": "fortress_30",    "title": "銅牆鐵壁",   "desc": "戰鬥勝利時護體達 30。"},
		{"id": "power_10",       "title": "氣貫長虹",   "desc": "戰鬥勝利時攻擊力加成達 10。"},
		{"id": "double_boss",    "title": "雙王伏誅",   "desc": "在 A20 的雙頭目戰中取勝。"},
	]

static func is_unlocked(id: String) -> bool:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PATH) != OK:
		return false
	return cfg.has_section_key(SECTION, id)

static func unlocked_all() -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var out: Dictionary = {}
	if cfg.load(PATH) != OK or not cfg.has_section(SECTION):
		return out
	for key: String in cfg.get_section_keys(SECTION):
		out[key] = String(cfg.get_value(SECTION, key, ""))
	return out

static func _unlock(id: String) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value(SECTION, id, Time.get_datetime_string_from_system())
	cfg.save(PATH)

# 走一輪所有未解鎖成就 → 回傳本次新解鎖的定義（給 toast 用）
static func check_all(ctx: Dictionary) -> Array[Dictionary]:
	var newly: Array[Dictionary] = []
	var unlocked: Dictionary = unlocked_all()
	for define: Dictionary in definitions():
		var id: String = String(define["id"])
		if unlocked.has(id):
			continue
		if _is_met(id, ctx):
			_unlock(id)
			newly.append(define)
	return newly

static func _is_met(id: String, ctx: Dictionary) -> bool:
	var kind: String = String(ctx.get("kind", "any"))
	var rs = ctx.get("run_state", null)
	var battle = ctx.get("battle", null)
	match id:
		# ── 持久資料（任何觸發點都可判）──
		"first_victory":
			return RunHistory.summary()["wins"] >= 1
		"li_victory", "zhao_victory", "lin_victory", "anu_victory":
			var char_id: String = id.trim_suffix("_victory")
			if char_id == "li": char_id = "li_xiaoyao"
			elif char_id == "zhao": char_id = "zhao_linger"
			elif char_id == "lin": char_id = "lin_yueru"
			for e_v: Variant in RunHistory.load_all():
				var e: Dictionary = e_v as Dictionary
				var chars: Array = e.get("characters", []) as Array
				if bool(e.get("victory", false)) and not chars.is_empty() and String(chars[0]) == char_id:
					return true
			return false
		"trio_victory", "solo_victory":
			var want_size: int = 3 if id == "trio_victory" else 1
			for e_v: Variant in RunHistory.load_all():
				var e: Dictionary = e_v as Dictionary
				if bool(e.get("victory", false)) and (e.get("characters", []) as Array).size() == want_size:
					return true
			return false
		"a5_clear":
			return Ascension.get_unlocked_max() >= 6
		"a10_clear":
			return Ascension.get_unlocked_max() >= 11
		"a20_clear":
			return Ascension.get_unlocked_max() >= 21
		"bestiary_20":
			return Bestiary.load_all().size() >= 20
		"bestiary_50":
			return Bestiary.load_all().size() >= 50
		"kills_100":
			var total: int = 0
			for v: Variant in Bestiary.load_all().values():
				total += int(v)
			return total >= 100
		"boss_hunter":
			var boss_ids: Array[String] = []
			boss_ids.append_array(Ascension.BOSS_IDS)
			for extra: String in ["miao_chieftain", "tomb_general", "zhenyu_mingwang"]:
				if not boss_ids.has(extra):
					boss_ids.append(extra)
			for b: String in boss_ids:
				if not Bestiary.is_defeated(b):
					return false
			return true
		"veteran_10":
			return RunHistory.load_all().size() >= 10
		# ── 通關當下的 run 狀態 ──
		"rich_victory":
			return kind == "run_victory" and rs != null and rs.gold >= 400
		"poor_victory":
			return kind == "run_victory" and rs != null and rs.gold < 20
		"lean_deck":
			if kind != "run_victory" or rs == null:
				return false
			var n: int = 0
			for deck_v in rs.character_decks:
				n += (deck_v as Array).size()
			return n <= 18
		"relic_14":
			return kind == "run_victory" and rs != null and rs.relics.size() >= 14
		"level_20":
			if kind != "run_victory" or rs == null:
				return false
			for lv in rs.character_levels:
				if int(lv) >= 20:
					return true
			return false
		"fox_karma":
			return kind == "run_victory" and rs != null and rs.has_event_flag("fox_spared")
		"jade_light":
			return kind == "run_victory" and rs != null and rs.has_event_flag("nuwa_jade")
		"full_potions":
			return kind == "run_victory" and rs != null and rs.potions.size() >= rs.effective_potion_slots()
		# ── 單場戰鬥勝利當下 ──
		"triple_kill":
			return kind == "battle_victory" and battle != null and battle.enemies.size() >= 3
		"untouched":
			if kind != "battle_victory" or battle == null:
				return false
			return int(battle.state.get("player_hp", 0)) >= int(battle.state.get("player_max_hp", 1))
		"last_stand":
			if kind != "battle_victory" or battle == null:
				return false
			var players: Array = battle.state.get("players", []) as Array
			if players.size() < 3:
				return false
			var alive: int = 0
			for p_v: Variant in players:
				if int((p_v as Dictionary).get("hp", 0)) > 0:
					alive += 1
			return alive == 1
		"poison_15":
			if kind != "battle_victory" or battle == null:
				return false
			for slot_v: Variant in (battle.state.get("enemies", []) as Array):
				if int((slot_v as Dictionary).get("poison", 0)) >= 15:
					return true
			return false
		"fortress_30":
			return kind == "battle_victory" and battle != null and int(battle.state.get("player_block", 0)) >= 30
		"power_10":
			return kind == "battle_victory" and battle != null and int(battle.state.get("player_power", 0)) >= 10
		"double_boss":
			if kind != "battle_victory" or battle == null:
				return false
			var boss_count: int = 0
			for e in battle.enemies:
				if Ascension.is_boss_id(e.id):
					boss_count += 1
			return boss_count >= 2
	return false

static func clear_all() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("achievements.cfg")
