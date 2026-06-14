extends SceneTree
# 永久攻擊力（power_bonus）上限探針。
# 1) 每個事件 variant：單一 root→leaf 路徑上能拿到的 permanent_power 上限（含 legacy power 欄位）。
# 2) 一輪 8 幕：每幕地圖在 connects 約束下，DP 找「累積事件 power 最大」的路徑；加總全 run。
#    事件節點 12% 是行腳商人、22% 是埋伏（皆 0 power），只有 ~66% 真事件計入。本探針分兩種統計：
#    - realistic：尊重 merchant/ambush（那些節點 power=0）
#    - ceiling：忽略暗路，假設每個事件節點都是真事件、且該 variant 走最高 power 分支
#   godot --headless --path . -s tools/power_probe.gd
const SEEDS := 300

func _initialize() -> void:
	var variant_max := {}
	for v in MapGenerator.EVENT_VARIANTS:
		variant_max[v] = _variant_max_power(v)
	# 印每個 variant 的單路徑 power 上限（排序）
	var pairs := []
	for v in variant_max: pairs.append([v, variant_max[v]])
	pairs.sort_custom(func(a, b): return a[1] > b[1])
	print("=== 各事件 variant 單一路徑 permanent_power 上限 ===")
	for p in pairs:
		print("  %-22s +%d" % [p[0], p[1]])
	var global_max_variant: int = int(pairs[0][1])

	# 全 run DP
	var enemies := GameData.enemies()
	var realistic := []
	var ceiling := []
	var ev_nodes := []
	# 逐幕累積 raw power（acts 1..N 的最佳路徑加總），用來配對「打該幕 boss 時手上的最大 power」
	var cum_raw_by_act := [0, 0, 0, 0, 0, 0, 0, 0]  # max over seeds of cumulative raw after act i
	for s in range(SEEDS):
		seed(s * 2654435761)
		var total_real := 0
		var total_ceil := 0
		var total_ev := 0
		var running := 0
		for act in range(1, 9):
			var act_enemies: Array[EnemyData] = GameData.enemies_for_act(act)
			var boss: Array[EnemyData] = [GameData.boss_for_act(act)]
			var elites: Array[EnemyData] = GameData.elites_for_act(act)
			var map: Array = MapGenerator.generate(act_enemies, boss, ["li_xiaoyao"], act, elites, 0)
			var r := _best_path_power(map, variant_max, global_max_variant)
			total_real += r[0]
			total_ceil += r[1]
			total_ev += r[2]
			running += r[0]
			if running > int(cum_raw_by_act[act - 1]): cum_raw_by_act[act - 1] = running
		realistic.append(total_real)
		ceiling.append(total_ceil)
		ev_nodes.append(total_ev)
	randomize()
	var real_max: int = _max(realistic)
	var ceil_max: int = _max(ceiling)
	print("\n=== 一輪 8 幕（%d seeds，李逍遙單人；DP 取最佳路徑）===" % SEEDS)
	print("  最佳路徑可踩到的事件節點數：  avg %.1f  max %d" % [_avg(ev_nodes), _max(ev_nodes)])
	print("  realistic RAW power（未套上限）：avg %.1f  max %d" % [_avg(realistic), real_max])
	print("  ceiling   RAW power（未套上限）：avg %.1f  max %d" % [_avg(ceiling), ceil_max])
	# 套 RunState.add_power_bonus 的軟上限+遞減曲線 → 有效 power
	print("\n=== 套 cap 曲線（SOFT %d / HARD %d）後的有效 power ===" % [RunState.POWER_SOFT_CAP, RunState.POWER_HARD_CAP])
	print("  realistic 有效 power：avg %d  max %d" % [_eff(int(_avg(realistic))), _eff(real_max)])
	print("  ceiling   有效 power：max %d" % _eff(ceil_max))
	# 爆發檢查：把「打該幕 boss 時的最大有效 power」配對該幕 boss HP，看 2×九龍訣(12×3) 是否 < HP。
	# power 是整輪累積——打 act1 boss 時手上 power 遠低於終局值，故須逐幕配對而非一律用終局 12。
	var boss_names := ["蛇妖男", "黑苗頭領", "殭屍王", "赤鬼王", "火麒麟", "鎮獄明王", "石長老", "拜月教主"]
	var boss_hp := [95, 96, 106, 110, 92, 145, 126, 155]
	print("\n=== 爆發檢查：逐幕（該幕最大有效 power 配該幕 boss）｜九龍訣 12×3 ===")
	var all_safe := true
	for i in range(8):
		var eff_here: int = _eff(int(cum_raw_by_act[i]))
		var one: int = (12 + eff_here) * 3
		var two: int = one * 2
		var safe: bool = two < int(boss_hp[i])
		if not safe: all_safe = false
		print("  幕%d %-8s HP %3d | 最大有效power %2d | 一發 %3d 兩發 %3d  %s" % [
			i + 1, boss_names[i], boss_hp[i], eff_here, one, two, ("✓" if safe else "✗ 兩發可秒")])
	print("\n  => %s" % ("全 boss 守住「不能兩發秒」 ✓" if all_safe else "仍有 boss 可被兩發秒 ✗ —— 需拉該幕 HP"))
	quit(0)

# 鏡像 RunState.add_power_bonus 的曲線：把 raw 全額累積後算有效值
func _eff(raw: int) -> int:
	if raw <= RunState.POWER_SOFT_CAP:
		return min(RunState.POWER_HARD_CAP, raw)
	var rest: int = raw - RunState.POWER_SOFT_CAP
	return min(RunState.POWER_HARD_CAP, RunState.POWER_SOFT_CAP + int(ceil(rest * 0.5)))

# 一幕地圖：DP 找最佳路徑的事件 power 累積（含尊重暗路的 realistic 與忽略暗路的 ceiling）
func _best_path_power(map: Array, variant_max: Dictionary, global_max: int) -> Array:
	var rows := map.size()
	# best_real[node_index] / best_ceil / best_ev（到該節點為止的最佳累積）
	var prev_real := {}
	var prev_ceil := {}
	var prev_ev := {}
	for r in range(rows):
		var row: Array = map[r]
		var cur_real := {}
		var cur_ceil := {}
		var cur_ev := {}
		for ni in range(row.size()):
			var node: Dictionary = row[ni]
			var is_event: bool = String(node.get("type", "")) == "event"
			var real_gain := 0
			var ceil_gain := 0
			var ev_gain := 0
			if is_event:
				ev_gain = 1
				var variant := String(node.get("event_variant", ""))
				var is_secret: bool = node.get("merchant_event", false) or node.get("ambush_event", false)
				real_gain = (0 if is_secret else int(variant_max.get(variant, 0)))
				ceil_gain = global_max
			# 取所有「能連到本節點」的前列最佳值
			var base_real := 0
			var base_ceil := 0
			var base_ev := 0
			if r == 0:
				base_real = 0; base_ceil = 0; base_ev = 0
			else:
				base_real = -1; base_ceil = -1; base_ev = -1
				var prev_row: Array = map[r - 1]
				for pi in range(prev_row.size()):
					var pconnects: Array = (prev_row[pi] as Dictionary).get("connects", []) as Array
					if pconnects.has(ni):
						if int(prev_real.get(pi, -1)) > base_real: base_real = int(prev_real.get(pi, -1))
						if int(prev_ceil.get(pi, -1)) > base_ceil: base_ceil = int(prev_ceil.get(pi, -1))
						if int(prev_ev.get(pi, -1)) > base_ev: base_ev = int(prev_ev.get(pi, -1))
				if base_real < 0: continue  # 不可達
			cur_real[ni] = base_real + real_gain
			cur_ceil[ni] = base_ceil + ceil_gain
			cur_ev[ni] = base_ev + ev_gain
		prev_real = cur_real; prev_ceil = cur_ceil; prev_ev = cur_ev
	return [_dict_max(prev_real), _dict_max(prev_ceil), _dict_max(prev_ev)]

# 單一事件 variant：root→leaf 任一路徑上的 permanent_power 上限
func _variant_max_power(variant: String) -> int:
	var ed: Dictionary = EventData.for_variant(variant)
	if EventRunner.has_tree(ed):
		var memo := {}      # node_id → max power（避免重複/環造成指數爆炸）
		return _node_max_power(ed, EventRunner.ROOT_ID, memo, {})
	# legacy 扁平：選 power 選項即得 ed["power"]
	return max(0, int(ed.get("power", 0)))

func _node_max_power(ed: Dictionary, node_id: String, memo: Dictionary, visiting: Dictionary) -> int:
	if memo.has(node_id): return int(memo[node_id])
	if visiting.has(node_id): return 0   # 環：切斷
	visiting[node_id] = true
	var node: Dictionary = EventRunner.get_node(ed, node_id)
	var choices: Array = node.get("choices", []) as Array
	var best := 0
	for cv in choices:
		var choice: Dictionary = cv as Dictionary
		var val := 0
		if choice.has("outcome"):
			val = _outcome_power(choice["outcome"] as Dictionary)
		elif choice.has("next"):
			val = _node_max_power(ed, String(choice["next"]), memo, visiting)
		if val > best: best = val
	visiting.erase(node_id)
	memo[node_id] = best
	return best

func _outcome_power(outcome: Dictionary) -> int:
	var total := _effects_power(outcome.get("effects", []) as Array)
	if outcome.has("gamble"):
		var g: Dictionary = outcome["gamble"] as Dictionary
		# best case = 賭贏
		total += _effects_power(g.get("win_effects", []) as Array)
	return total

func _effects_power(effects: Array) -> int:
	var sum := 0
	for ev in effects:
		var e: Dictionary = ev as Dictionary
		var k := String(e.get("kind", ""))
		if k == "permanent_power" or k == "power":
			sum += int(e.get("amount", 0))
	return sum

func _dict_max(d: Dictionary) -> int:
	var m := 0
	for k in d:
		if int(d[k]) > m: m = int(d[k])
	return m
func _avg(a: Array) -> float:
	if a.is_empty(): return 0.0
	var s := 0
	for x in a: s += int(x)
	return float(s) / float(a.size())
func _max(a: Array) -> int:
	var m := 0
	for x in a:
		if int(x) > m: m = int(x)
	return m
