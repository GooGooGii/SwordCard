extends SceneTree
# AI 平衡批次跑分器：單一 godot 程序內用 auto policy 跑「角色 × seed」矩陣，印出勝率彙整。
# 用於快速迭代 policy / 平衡數值（一次 boot 跑完所有組合，遠快於反覆開關程序）。
#
# 跑法：
#   godot --headless --path . -s tools/ai_batch.gd
#   AIBATCH_SEEDS=12 AIBATCH_CHARS=li_xiaoyao,anu godot --headless --path . -s tools/ai_batch.gd

func _initialize() -> void:
	var n_seeds: int = 8
	if OS.get_environment("AIBATCH_SEEDS").is_valid_int():
		n_seeds = int(OS.get_environment("AIBATCH_SEEDS"))
	var chars: Array = ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"]
	var ce: String = OS.get_environment("AIBATCH_CHARS")
	if not ce.is_empty():
		chars = []
		for c: String in ce.split(",", false):
			chars.append(c.strip_edges())
	var asc: int = int(OS.get_environment("AIBATCH_ASC")) if OS.get_environment("AIBATCH_ASC").is_valid_int() else 0
	# 固定 seed 集（1001..），可重現
	var seeds: Array = []
	for i: int in range(n_seeds):
		seeds.append(1001 + i * 7)

	print("=== AI batch: %d chars x %d seeds (asc %d) ===" % [chars.size(), n_seeds, asc])
	var grand_total: int = 0
	var grand_win: int = 0
	for ch: String in chars:
		var wins: int = 0
		var act_sum: int = 0
		var acts: Array = []
		for sd: int in seeds:
			var r: Dictionary = _run_one(ch, asc, sd)
			if bool(r.get("victory", false)):
				wins += 1
			var fa: int = int(r.get("final_act", 0))
			act_sum += fa
			acts.append(fa)
		var rate: float = 100.0 * wins / float(seeds.size())
		var avg_act: float = float(act_sum) / float(seeds.size())
		print("%-12s win %2d/%d (%5.1f%%)  avg_act %.2f  acts=%s" % [ch, wins, seeds.size(), rate, avg_act, str(acts)])
		grand_total += seeds.size()
		grand_win += wins
	print("--- overall win %d/%d (%.1f%%) ---" % [grand_win, grand_total, 100.0 * grand_win / float(grand_total)])
	quit(0)

func _run_one(char_id: String, asc: int, run_seed: int) -> Dictionary:
	var engine: AiRunEngine = AiRunEngine.new()
	engine.setup([char_id], asc, run_seed)
	var guard: int = 0
	while guard < 200000:
		guard += 1
		var view: Dictionary = engine.next_view()
		if String(view.get("kind", "")) == "done":
			break
		engine.apply(AiRunEngine.auto_choice(view))
	return engine.result
