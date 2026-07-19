extends SceneTree

const OUTPUT_DIR := "res://tmp/battle_bg_review"


func _initialize() -> void:
	var abs_dir: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	await process_frame
	var packed: PackedScene = load("res://scenes/main.tscn")
	var main: Main = packed.instantiate() as Main
	root.add_child(main)
	await process_frame
	await process_frame

	main.dbg_test_mode = true
	main.start_run([(main.characters[0] as CharacterData).clone()])
	await process_frame
	await process_frame
	_clear_story_layers(main)
	_populate_review_inventory(main.run_state)
	main.run_state.act = 4
	main.run_state.act_intro_seen = 4

	var boss: EnemyData = GameData.boss_for_act(4).clone()
	main._start_boss_with_intro(boss)
	await process_frame
	await process_frame
	assert(main.battle.enemy.id == "ghost_general", "Act 4 boss node must start with the Ghost General")
	await create_timer(1.5).timeout
	_save_viewport(main, "%s/tomb_general_stage_1_ghost_general.png" % abs_dir)
	_save_viewport(main, "%s/ghost_general_candidate_facing_left.png" % abs_dir)
	var ghost_portrait: TextureRect = (main.enemy_widgets[0] as Dictionary)["portrait"] as TextureRect
	ghost_portrait.scale.x = -1.0
	ghost_portrait.position.x += ghost_portrait.size.x
	await process_frame
	_save_viewport(main, "%s/ghost_general_candidate_facing_right.png" % abs_dir)

	main.battle.state["enemy_hp"] = 0
	(main.battle.state["enemies"] as Array)[0]["hp"] = 0
	main._complete_battle_victory()
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	_save_viewport(main, "%s/tomb_general_intro.png" % abs_dir)

	var story_root: Control = _story_root(main)
	assert(story_root != null, "Ghost General victory must show the collapse story card")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	story_root.gui_input.emit(click)
	await create_timer(0.4).timeout
	assert(main.battle.enemy.id == "tomb_general", "Collapse story must continue into the Red Ghost King battle")
	assert(main.run_state.encounter_index == 0, "Intermediate Ghost General victory must not advance the map")
	# 第二層 Boss 必須由正式 enemy-id 路由自動選到血池背景。
	await process_frame
	await process_frame
	await create_timer(1.5).timeout
	_save_viewport(main, "%s/tomb_general_candidate_facing_left_v2.png" % abs_dir)
	var red_ghost_portrait: TextureRect = (main.enemy_widgets[0] as Dictionary)["portrait"] as TextureRect
	red_ghost_portrait.scale.x = -1.0
	red_ghost_portrait.position.x += red_ghost_portrait.size.x
	await process_frame
	_save_viewport(main, "%s/tomb_general_candidate_facing_right_v2.png" % abs_dir)

	main.queue_free()
	await process_frame
	quit()


func _clear_story_layers(main: Main) -> void:
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120:
			child.queue_free()
	await process_frame


func _story_root(main: Main) -> Control:
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120 and child.get_child_count() > 0:
			return child.get_child(0) as Control
	return null


func _save_viewport(main: Main, path: String) -> void:
	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed")
	var err: Error = image.save_png(path)
	assert(err == OK, "Failed to save %s" % path)


func _populate_review_inventory(state: RunState) -> void:
	for relic: RelicData in RelicCatalog.all():
		if state.relics.size() >= 6:
			break
		if not state.has_relic(relic.id):
			state.add_relic(relic.clone())
	state.potions.clear()
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	for i: int in range(min(state.effective_potion_slots(), all_potions.size())):
		state.potions.append(all_potions[i].duplicate(true))
