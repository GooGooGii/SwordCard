class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 60
@export var portrait_path: String = ""
@export var actions: Array[Dictionary] = []
@export var phase_2_actions: Array[Dictionary] = []  # boss HP < 50% 切換到的招式組，空 = 不進入二階段
@export var phase_2_display_name: String = ""  # 進入 phase 2 時改顯示的名字（如「水魔獸」）；空 = 沿用 display_name
@export var phase_2_portrait_path: String = ""  # 進入 phase 2 時換的肖像；空 = 沿用 portrait_path
@export var phase_2_background_path: String = ""  # 進入 phase 2 時換的戰鬥背景；空 = 沿用目前背景
@export var phase_2_portrait_tint: Color = Color.WHITE  # phase 2 額外色調（Color.WHITE = 不變色）
@export var portrait_tint: Color = Color.WHITE
@export var portrait_scale: float = 1.0      # 肖像相對標準框的倍率（boss / 大型妖獸 > 1，小兵可 < 1）
@export var phase_2_portrait_scale: float = 0.0  # phase 2 專用倍率；<= 0 = 沿用 portrait_scale
@export var swarm_size: int = 0              # > 1：此怪以「群」出現，遭遇時整組換成 N 隻同類（capped by MAX_ENEMIES）
@export var summon_pool: Array[String] = []  # boss 召喚物 id pool；空 = 不召喚
@export var is_summoned: bool = false        # 由 spawn_enemy() 設為 true，勝利結算時不計入掉落
@export var default_facing_left: bool = true # 圖檔已面向左 → 戰鬥中一律不翻轉（朝向畫進圖裡）
@export var split_into: String = ""          # 分裂：HP 過半時召出的敵人 id（空 = 不分裂）
@export var split_count: int = 1             # 分裂出幾隻（受 MAX_ENEMIES 上限）
@export var ultimate_action: Dictionary = {} # 大招：每 ultimate_every 回合改放此招（空 = 無）
@export var ultimate_every: int = 0          # 每 N 個自身回合放一次大招（0 = 無）
@export var floats: bool = false             # 飄浮系（鬼火/劍靈等）：允許懸浮、腳底陰影縮小淡化
# 敵方被動（機制型敵人，2026-06-11 試點）：{"kind": ..., "amount": ..., "label": 開戰告示文字}
# 目前支援 kind："strength_on_player_skill"（玩家每出一張技能牌，此敵 +amount 力量）
@export var passive: Dictionary = {}
# 接續 boss（隱龍窟雙妖正史）：此敵死亡時，滿血召出 successor 指定的敵人接續打。
# 空 = 無接續。與 phase_2（半血同隻變身）互斥——接續是「兩隻分別打」。
@export var successor: String = ""

func clone() -> EnemyData:
	var copy: EnemyData = EnemyData.new()
	copy.id = id
	copy.display_name = display_name
	copy.max_hp = max_hp
	copy.portrait_path = portrait_path
	copy.actions = actions.duplicate(true)
	copy.phase_2_actions = phase_2_actions.duplicate(true)
	copy.phase_2_display_name = phase_2_display_name
	copy.phase_2_portrait_path = phase_2_portrait_path
	copy.phase_2_background_path = phase_2_background_path
	copy.phase_2_portrait_tint = phase_2_portrait_tint
	copy.portrait_tint = portrait_tint
	copy.portrait_scale = portrait_scale
	copy.phase_2_portrait_scale = phase_2_portrait_scale
	copy.swarm_size = swarm_size
	copy.summon_pool = summon_pool.duplicate()
	copy.is_summoned = is_summoned
	copy.default_facing_left = default_facing_left
	copy.split_into = split_into
	copy.split_count = split_count
	copy.ultimate_action = ultimate_action.duplicate(true)
	copy.ultimate_every = ultimate_every
	copy.floats = floats
	copy.passive = passive.duplicate(true)
	copy.successor = successor
	return copy

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"max_hp": max_hp,
		"portrait_path": portrait_path,
		"actions": actions.duplicate(true),
		"phase_2_actions": phase_2_actions.duplicate(true),
		"phase_2_display_name": phase_2_display_name,
		"phase_2_portrait_path": phase_2_portrait_path,
		"phase_2_background_path": phase_2_background_path,
		"phase_2_portrait_tint": [phase_2_portrait_tint.r, phase_2_portrait_tint.g, phase_2_portrait_tint.b, phase_2_portrait_tint.a],
		"portrait_tint": [portrait_tint.r, portrait_tint.g, portrait_tint.b, portrait_tint.a],
		"portrait_scale": portrait_scale,
		"phase_2_portrait_scale": phase_2_portrait_scale,
		"default_facing_left": default_facing_left
	}

static func from_dict(data: Dictionary) -> EnemyData:
	var enemy: EnemyData = EnemyData.new()
	enemy.id = String(data.get("id", ""))
	enemy.display_name = String(data.get("display_name", ""))
	enemy.max_hp = int(data.get("max_hp", 60))
	enemy.portrait_path = String(data.get("portrait_path", ""))
	enemy.phase_2_display_name = String(data.get("phase_2_display_name", ""))
	enemy.phase_2_portrait_path = String(data.get("phase_2_portrait_path", ""))
	enemy.phase_2_background_path = String(data.get("phase_2_background_path", ""))
	var p2_tint_data: Array = data.get("phase_2_portrait_tint", []) as Array
	if p2_tint_data.size() >= 3:
		enemy.phase_2_portrait_tint = Color(
			float(p2_tint_data[0]),
			float(p2_tint_data[1]),
			float(p2_tint_data[2]),
			float(p2_tint_data[3]) if p2_tint_data.size() >= 4 else 1.0
		)
	var raw_actions: Array = data.get("actions", []) as Array
	var typed_actions: Array[Dictionary] = []
	for entry: Variant in raw_actions:
		if entry is Dictionary:
			typed_actions.append((entry as Dictionary).duplicate(true))
	enemy.actions = typed_actions
	var raw_phase_2: Array = data.get("phase_2_actions", []) as Array
	var typed_phase_2: Array[Dictionary] = []
	for entry: Variant in raw_phase_2:
		if entry is Dictionary:
			typed_phase_2.append((entry as Dictionary).duplicate(true))
	enemy.phase_2_actions = typed_phase_2
	var tint_data: Array = data.get("portrait_tint", []) as Array
	if tint_data.size() >= 3:
		enemy.portrait_tint = Color(
			float(tint_data[0]),
			float(tint_data[1]),
			float(tint_data[2]),
			float(tint_data[3]) if tint_data.size() >= 4 else 1.0
		)
	enemy.portrait_scale = float(data.get("portrait_scale", 1.0))
	enemy.phase_2_portrait_scale = float(data.get("phase_2_portrait_scale", 0.0))
	enemy.default_facing_left = bool(data.get("default_facing_left", true))
	return enemy
