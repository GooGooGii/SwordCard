extends SceneTree

const OUTPUT_DIR := "res://tmp/battle_bg_review"
const REVIEW_ACTS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]


func _initialize() -> void:
	var abs_dir: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	await process_frame
	for act: int in REVIEW_ACTS:
		await _capture_act_battle(act, GameData.enemies_for_act(act)[0] as EnemyData, "normal", abs_dir)
		await _capture_act_battle(act, GameData.boss_for_act(act), "boss", abs_dir)
	print("Battle background review renders saved to %s" % abs_dir)
	quit()


func _capture_act_battle(act: int, enemy_source: EnemyData, label: String, abs_dir: String) -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed != null, "Failed to load main scene")
	var main: Main = packed.instantiate() as Main
	assert(main != null, "Failed to instantiate main scene")
	root.add_child(main)
	await process_frame
	await process_frame

	main.dbg_test_mode = true
	var party: Array[CharacterData] = []
	if not main.characters.is_empty():
		party.append((main.characters[0] as CharacterData).clone())
	assert(not party.is_empty(), "No characters available for render harness")
	main.start_run(party)
	await process_frame
	await process_frame
	_populate_review_inventory(main.run_state)

	main.run_state.act = act
	# start_run() has already created the first act's click-to-dismiss story overlay.
	# The harness has no pointer input, so discard only that test-time overlay before battle.
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120:
			child.queue_free()
	await process_frame
	# Mark this act seen so start_next_battle() does not create another overlay.
	main.run_state.act_intro_seen = act
	main.start_next_battle(enemy_source.clone())
	await process_frame
	await process_frame
	# 等開戰遺物觸發文字／浮動數字結束，再截取穩定戰鬥 UI。
	await create_timer(1.5).timeout

	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed for act %d" % act)
	var out_path: String = "%s/act_%d_%s.png" % [abs_dir, act, label]
	var err: Error = image.save_png(out_path)
	assert(err == OK, "Failed to save %s render for act %d: %s" % [label, act, error_string(err)])

	main.queue_free()
	await process_frame


func _populate_review_inventory(state: RunState) -> void:
	# 美術驗收使用接近中後期 run 的資訊密度：6 件遺物＋滿藥格，避免空白 UI 誤判空間。
	for relic: RelicData in RelicCatalog.all():
		if state.relics.size() >= 6:
			break
		if not state.has_relic(relic.id):
			state.add_relic(relic.clone())
	state.potions.clear()
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	for i: int in range(min(state.effective_potion_slots(), all_potions.size())):
		state.potions.append(all_potions[i].duplicate(true))
