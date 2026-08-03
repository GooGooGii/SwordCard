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
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120:
			child.queue_free()
	await process_frame
	_populate_review_inventory(main.run_state)
	main.run_state.act = 8
	main.run_state.act_intro_seen = 8

	var boss: EnemyData = GameData.boss_for_act(8).clone()
	main.start_next_battle([boss])
	await process_frame
	await process_frame
	_save_viewport(main, "%s/baiyue_formal_phase1.png" % abs_dir)

	main.battle.enemy_phased[0] = true
	var slot: Dictionary = (main.battle.state["enemies"] as Array)[0] as Dictionary
	slot["name"] = boss.phase_2_display_name
	main._rebuild_enemy_row_in_place()
	main._refresh_battle()
	await process_frame
	await process_frame
	main._swap_to_phase_2_portrait()
	await process_frame
	_save_viewport(main, "%s/baiyue_formal_phase2.png" % abs_dir)

	main.queue_free()
	await process_frame
	quit()


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
