extends SceneTree

const OUTPUT_DIR := "res://tmp/battle_bg_review"
const REVIEW_ACTS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]


func _initialize() -> void:
	var abs_dir: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	await process_frame
	for act: int in REVIEW_ACTS:
		await _capture_act_battle(act, abs_dir)
	print("Battle background review renders saved to %s" % abs_dir)
	quit()


func _capture_act_battle(act: int, abs_dir: String) -> void:
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

	main.run_state.act = act
	var boss: EnemyData = GameData.boss_for_act(act).clone()
	main.start_next_battle(boss)
	await process_frame
	await process_frame
	await create_timer(0.15).timeout

	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed for act %d" % act)
	var out_path: String = "%s/act_%d_battle.png" % [abs_dir, act]
	var err: Error = image.save_png(out_path)
	assert(err == OK, "Failed to save render for act %d: %s" % [act, error_string(err)])

	main.queue_free()
	await process_frame
