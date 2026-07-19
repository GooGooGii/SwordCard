extends SceneTree

const OUTPUT_DIR := "res://tmp/battle_bg_review"
const CANDIDATE_BG := "res://assets/art/battle_bg_boss_stone_elder_v1.png"
const CANDIDATE_PORTRAIT := "res://assets/art/enemies/stone_elder_pal1_v1.png"


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
	main.run_state.act = 7
	main.run_state.act_intro_seen = 7

	var boss: EnemyData = GameData.boss_for_act(7).clone()
	boss.portrait_path = CANDIDATE_PORTRAIT
	boss.portrait_scale = 1.85
	boss.default_facing_left = false
	var rear_guard: EnemyData = GameData.enemy_by_id("miao_soldier")
	var front_guard: EnemyData = GameData.enemy_by_id("miao_soldier")
	for guard: EnemyData in [rear_guard, front_guard]:
		guard.portrait_path = "res://assets/art/enemies/miao_spear_guard_pal1_v2.png"
		guard.portrait_scale = 1.35
		guard.default_facing_left = true
	main.start_next_battle([rear_guard, boss, front_guard])
	await process_frame
	await process_frame
	main._set_background(CANDIDATE_BG)
	await create_timer(1.5).timeout

	# Variant A: compress the enemy formation and let the silhouettes overlap.
	main.enemy_row_container.add_theme_constant_override("separation", -72)
	await process_frame
	_save_viewport(main, "%s/stone_elder_formation_overlap.png" % abs_dir)

	# Variant B: a shallow diagonal formation.  Keep the information bars level;
	# only the grounded figures move in depth so combat data remains easy to scan.
	main.enemy_row_container.add_theme_constant_override("separation", -72)
	var draw_orders: Array[int] = [0, 1, 2]
	await process_frame
	# The Guiyin Altar's long brick seams descend toward screen-right.  Derive
	# every foot offset from the same slope so the three grounding points are
	# truly collinear instead of using three hand-tuned heights.  Anchor the
	# rightmost enemy to the original ground line, keeping all figures above HP.
	const BRICK_GROUND_SLOPE := 0.24
	const FORMATION_GROUND_DROP := 10.0
	var right_ground_x: float = -INF
	for widget: Dictionary in main.enemy_widgets:
		var wrap: Control = widget["wrap"] as Control
		right_ground_x = max(right_ground_x, wrap.global_position.x + wrap.size.x * 0.5)
	for i: int in range(main.enemy_widgets.size()):
		var widget: Dictionary = main.enemy_widgets[i]
		var wrap: Control = widget["wrap"] as Control
		var portrait: TextureRect = widget["portrait"] as TextureRect
		var ground_x: float = wrap.global_position.x + wrap.size.x * 0.5
		var depth_offset: float = (ground_x - right_ground_x) * BRICK_GROUND_SLOPE + FORMATION_GROUND_DROP
		portrait.position.y += depth_offset
		# Shadow is the first child added to the portrait wrap.
		var shadow: Control = wrap.get_child(0) as Control
		shadow.position.y += depth_offset
		wrap.z_index = draw_orders[i]
		_layout_enemy_hud_at_figure(widget, wrap, portrait)
	await process_frame
	_save_viewport(main, "%s/stone_elder_formation_diagonal.png" % abs_dir)

	main.queue_free()
	await process_frame
	quit()


func _save_viewport(main: Main, path: String) -> void:
	var image: Image = main.get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty(), "Viewport capture failed")
	var err: Error = image.save_png(path)
	assert(err == OK, "Failed to save %s" % path)


func _layout_enemy_hud_at_figure(widget: Dictionary, wrap: Control, portrait: TextureRect) -> void:
	var content_rect: Rect2 = _opaque_content_rect(portrait)
	var intent_label: Label = widget["intent_label"] as Label
	var intent_icon_row: HBoxContainer = widget["intent_icon_row"] as HBoxContainer
	intent_icon_row.reparent(wrap)
	intent_label.reparent(wrap)
	intent_icon_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intent_icon_row.size = Vector2(96, 28)
	intent_icon_row.position = Vector2(content_rect.get_center().x - 48.0, content_rect.position.y - 54.0)
	intent_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	intent_label.size = Vector2(96, 28)
	intent_label.position = Vector2(content_rect.get_center().x - 48.0, content_rect.position.y - 29.0)

	var hp_wrap: Control = widget["hp_wrap"] as Control
	var status_line: HBoxContainer = widget["status_line"] as HBoxContainer
	var name_label: Label = widget["name_label"] as Label
	hp_wrap.reparent(wrap)
	status_line.reparent(wrap)
	name_label.reparent(wrap)
	var hp_width: float = hp_wrap.custom_minimum_size.x
	hp_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hp_wrap.size = Vector2(hp_width, hp_wrap.custom_minimum_size.y)
	hp_wrap.position = Vector2(content_rect.get_center().x - hp_width * 0.5, content_rect.end.y + 5.0)
	status_line.size = Vector2(hp_width, 22)
	status_line.position = Vector2(content_rect.get_center().x - hp_width * 0.5, content_rect.end.y + 27.0)
	name_label.size = Vector2(hp_width, 20)
	name_label.position = Vector2(content_rect.get_center().x - hp_width * 0.5, content_rect.end.y + 47.0)


func _opaque_content_rect(portrait: TextureRect) -> Rect2:
	var texture: Texture2D = portrait.texture
	if texture == null:
		return Rect2(portrait.position, portrait.size)
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return Rect2(portrait.position, portrait.size)
	var used: Rect2i = image.get_used_rect()
	var source_size := Vector2(image.get_width(), image.get_height())
	var fit_scale: float = min(portrait.size.x / source_size.x, portrait.size.y / source_size.y)
	var fitted_size: Vector2 = source_size * fit_scale
	var fitted_offset: Vector2 = (portrait.size - fitted_size) * 0.5
	var visual_origin: Vector2 = portrait.position
	var used_position := Vector2(used.position)
	if portrait.scale.x < 0.0:
		# Flipped TextureRects are translated right by their full width; convert
		# back to the wrap's unmirrored local coordinates before anchoring HUD.
		visual_origin.x -= portrait.size.x
		used_position.x = source_size.x - float(used.end.x)
	return Rect2(
		visual_origin + fitted_offset + used_position * fit_scale,
		Vector2(used.size) * fit_scale)


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
