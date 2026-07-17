extends SceneTree

const OUTPUT_PATH := "res://tmp/battle_bg_review/miao_chieftain_pal1_v2_boss.png"
const CANDIDATE_PATH := "res://assets/art/enemies/miao_chieftain_pal1_v2.png"


func _initialize() -> void:
	var abs_output: String = ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(abs_output.get_base_dir())
	await process_frame

	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed != null, "Failed to load main scene")
	var main: Main = packed.instantiate() as Main
	assert(main != null, "Failed to instantiate main scene")
	root.add_child(main)
	await process_frame
	await process_frame

	main.dbg_test_mode = true
	var party: Array[CharacterData] = []
	party.append((main.characters[0] as CharacterData).clone())
	main.start_run(party)
	await process_frame
	await process_frame

	main.run_state.act = 2
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120:
			child.queue_free()
	await process_frame
	main.run_state.act_intro_seen = 2

	var boss: EnemyData = GameData.boss_for_act(2).clone()
	boss.portrait_path = CANDIDATE_PATH
	# 候選原圖面向右；正式敵人站位要朝左面向玩家。
	boss.default_facing_left = false
	main.start_next_battle(boss)
	await process_frame
	await process_frame
	await create_timer(0.2).timeout

	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed")
	var err: Error = image.save_png(abs_output)
	assert(err == OK, "Failed to save render: %s" % error_string(err))
	print("Miao chieftain candidate render saved to %s" % abs_output)
	main.queue_free()
	await process_frame
	quit()
