extends SceneTree

const OUTPUT_PATH := "res://tmp/battle_bg_review/miao_chieftain_pal1_v2_boss.png"


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
	_populate_review_inventory(main.run_state)

	main.run_state.act = 2
	for child: Node in main.get_children():
		if child is CanvasLayer and (child as CanvasLayer).layer == 120:
			child.queue_free()
	await process_frame
	main.run_state.act_intro_seen = 2

	var boss: EnemyData = GameData.boss_for_act(2).clone()
	assert(not boss.default_facing_left, "Miao review expects the source portrait to require horizontal flipping")
	main.start_next_battle(boss)
	await process_frame
	await process_frame
	var boss_portrait: TextureRect = (main.enemy_widgets[1] as Dictionary)["portrait"] as TextureRect
	assert(boss_portrait.scale.x < 0.0, "Miao boss TextureRect must be horizontally flipped in the battle UI")
	# 等開戰遺物觸發文字／浮動數字結束，再截取穩定戰鬥 UI。
	await create_timer(1.5).timeout

	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed")
	var err: Error = image.save_png(abs_output)
	assert(err == OK, "Failed to save render: %s" % error_string(err))
	print("Miao chieftain production render saved to %s" % abs_output)
	main.queue_free()
	await process_frame
	quit()


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
