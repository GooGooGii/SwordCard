extends Control

var characters: Array[CharacterData] = []
var enemies: Array[EnemyData] = []
var bosses: Array[EnemyData] = []
var selected_character: CharacterData
var run_state: RunState = RunState.new()
var battle: BattleController
var root: MarginContainer
var background_rect: TextureRect
var hand_row: HandFan
var log_label: RichTextLabel
var status_label: Label
var enemy_label: Label
var player_feedback_label: Label
var enemy_feedback_label: Label
var end_turn_button: Button
var player_hp_bar: ProgressBar
var player_hp_value: Label
var player_status_line: Label
var player_name_label: Label
var player_block_badge: BlockBadge
var player_portrait_wrap: Control
var enemy_hp_bar: ProgressBar
var enemy_hp_value: Label
var enemy_status_line: Label
var enemy_name_label: Label
var enemy_block_badge: BlockBadge
var enemy_portrait_wrap: Control
var energy_orb: EnergyOrb
var relic_strip: HBoxContainer
var deck_overlay: Control
var deck_view_mode: String = "view"
var card_buttons: Array[Button] = []
var animating_cards: Array[Button] = []
var pause_menu: PauseMenu

func _ready() -> void:
	randomize()
	SettingsManager.load_settings()
	characters = GameData.characters()
	enemies = GameData.enemies()
	bosses = GameData.bosses()
	get_tree().set_auto_accept_quit(false)
	_build_root()
	_build_pause_menu()
	show_main_menu()

func _build_pause_menu() -> void:
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.abandon_requested.connect(_on_abandon_requested)
	pause_menu.quit_requested.connect(_on_quit_requested)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()

func _toggle_pause_menu() -> void:
	if pause_menu == null:
		return
	if pause_menu.visible:
		_on_resume_requested()
		return
	# 主選單下不開暫停選單
	if run_state == null or run_state.character == null:
		return
	pause_menu.open()

func _on_resume_requested() -> void:
	pause_menu.close()

func _on_abandon_requested() -> void:
	pause_menu.close()
	SaveManager.clear()
	run_state = RunState.new()
	selected_character = null
	show_main_menu()

func _on_quit_requested() -> void:
	if run_state != null and run_state.character != null:
		SaveManager.save(run_state)
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if run_state != null and run_state.character != null:
			SaveManager.save(run_state)
		get_tree().quit()

func _build_root() -> void:
	background_rect = TextureRect.new()
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)
	root = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

func _clear_root() -> void:
	close_deck_view()
	for button: Button in animating_cards:
		if is_instance_valid(button):
			button.queue_free()
	animating_cards.clear()
	for child: Node in root.get_children():
		child.queue_free()

func _set_background(path: String) -> void:
	if background_rect == null:
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		background_rect.texture = texture

func show_main_menu() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_title("SwordCard 仙劍1 同人卡牌原型", 34))
	box.add_child(_paragraph("私人同人原型：使用原作角色名與招式名，僅供本機學習展示。"))
	if SaveManager.has_save():
		var continue_button: Button = _button("繼續冒險")
		continue_button.pressed.connect(continue_saved_run)
		box.add_child(continue_button)
	var start_button: Button = _button("開始遊戲")
	start_button.pressed.connect(show_character_select)
	box.add_child(start_button)
	var quit_button: Button = _button("離開")
	quit_button.pressed.connect(get_tree().quit)
	box.add_child(quit_button)

func continue_saved_run() -> void:
	var data: Dictionary = SaveManager.load_save()
	if data.is_empty():
		return
	var loaded_state: RunState = RunState.new()
	if not loaded_state.from_dict(data, characters):
		push_warning("存檔無法載入（角色不存在）。")
		SaveManager.clear()
		return
	run_state = loaded_state
	selected_character = run_state.character
	show_progress_screen()

func show_character_select() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)
	layout.add_child(_title("選擇角色", 30))
	layout.add_child(_paragraph("四層小型冒險：路線中會出現戰鬥、休息與事件，第四層挑戰拜月教徒。"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for character: CharacterData in characters:
		grid.add_child(_character_card(character))
	var back: Button = _button("返回主選單")
	back.pressed.connect(show_main_menu)
	layout.add_child(back)

func _character_card(character: CharacterData) -> Control:
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = Vector2(590, 255)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var portrait: TextureRect = _portrait_rect(character.portrait_path, Vector2(160, 220), true)
	if portrait.texture != null:
		row.add_child(portrait)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	row.add_child(box)
	box.add_child(_title(character.display_name, 24))
	box.add_child(_paragraph(character.battle_style))
	var card_names: Array[String] = []
	for card: CardData in character.starting_deck:
		card_names.append(card.display_title())
	var deck_text: String = "起始牌組：" + ", ".join(card_names)
	box.add_child(_paragraph(deck_text))
	var choose: Button = _button("以 %s 出戰" % character.display_name)
	choose.pressed.connect(func(): start_run(character))
	box.add_child(choose)
	return panel

func start_run(character: CharacterData) -> void:
	selected_character = character.clone()
	run_state.init_for(selected_character)
	run_state.encounter_choices = _make_encounter_choices()
	show_progress_screen()

func _make_encounter_choices() -> Array[Array]:
	return MapGenerator.generate(enemies, bosses)

func show_progress_screen() -> void:
	SaveManager.save(run_state)
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("第 %d / %d 層" % [run_state.encounter_index + 1, run_state.encounter_choices.size()], 34))
	box.add_child(_paragraph("%s  HP %d/%d  銅錢 %d  牌組 %d 張  本輪增傷 +%d" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size(), run_state.power_bonus]))
	box.add_child(_paragraph("選擇亮起的節點前進；灰色節點代表目前路線無法抵達。"))
	box.add_child(_paragraph(_passive_text()))
	if not run_state.relics.is_empty():
		var relic_names: Array[String] = []
		for r: RelicData in run_state.relics:
			relic_names.append(r.display_name)
		box.add_child(_paragraph("裝備：%s" % "、".join(relic_names)))
	box.add_child(_map_view())
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)
	var menu: Button = _button("放棄並返回主選單")
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func _map_view() -> Control:
	var map_panel: PanelContainer = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(1040, 430)
	map_panel.add_theme_stylebox_override("panel", _style_box(Color("0d1520", 0.58), Color("536277"), 1, 8))
	var map_area: Control = Control.new()
	map_area.custom_minimum_size = Vector2(1040, 420)
	map_area.clip_contents = false
	map_panel.add_child(map_area)
	var line_layer: Control = preload("res://scripts/map_link_layer.gd").new()
	line_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.add_child(line_layer)
	var map_row: HBoxContainer = HBoxContainer.new()
	map_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_row.add_theme_constant_override("separation", 12)
	map_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var node_buttons: Array[Dictionary] = []
	for row_index: int in range(run_state.encounter_choices.size()):
		var column: VBoxContainer = VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title: Label = _card_label("第 %d 層" % (row_index + 1), 15, Color("f7df9c"), HORIZONTAL_ALIGNMENT_CENTER)
		column.add_child(title)
		var row: Array = run_state.encounter_choices[row_index]
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_button: Button = _map_node_button(node_data, row_index)
			column.add_child(node_button)
			node_buttons.append({"button": node_button, "row": row_index, "index": int(node_data.get("index", 0))})
		map_row.add_child(column)
		if row_index < run_state.encounter_choices.size() - 1:
			var path_hint: Label = _card_label("", 24, Color("c8b46f"), HORIZONTAL_ALIGNMENT_CENTER)
			path_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			path_hint.custom_minimum_size = Vector2(22, 180)
			map_row.add_child(path_hint)
	map_area.add_child(map_row)
	call_deferred("_refresh_map_link_layer", line_layer, node_buttons)
	return map_panel

func _refresh_map_link_layer(line_layer: Control, node_buttons: Array[Dictionary]) -> void:
	if line_layer == null:
		return
	var centers: Dictionary = {}
	for item: Dictionary in node_buttons:
		var button: Button = item["button"] as Button
		if button == null:
			continue
		var row_index: int = int(item["row"])
		var node_index: int = int(item["index"])
		centers["%d:%d" % [row_index, node_index]] = button.global_position - line_layer.global_position + button.size * 0.5
	var segments: Array[Dictionary] = []
	for row_index: int in range(run_state.encounter_choices.size() - 1):
		var row: Array = run_state.encounter_choices[row_index]
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_index: int = int(node_data.get("index", 0))
			var from_key: String = "%d:%d" % [row_index, node_index]
			if not centers.has(from_key):
				continue
			var from_point: Vector2 = centers[from_key]
			var connects: Array = node_data.get("connects", []) as Array
			for target_variant: Variant in connects:
				var target_index: int = int(target_variant)
				var to_key: String = "%d:%d" % [row_index + 1, target_index]
				if not centers.has(to_key):
					continue
				segments.append({
					"from": from_point,
					"to": centers[to_key],
					"active": _is_map_connection_active(row_index, node_index, target_index)
				})
	line_layer.call("set_segments", segments)

func _is_map_connection_active(row_index: int, node_index: int, target_index: int) -> bool:
	if row_index >= run_state.chosen_map_path.size():
		return row_index == run_state.encounter_index and _is_map_node_selectable(row_index, node_index)
	if run_state.chosen_map_path[row_index] != node_index:
		return false
	if row_index + 1 < run_state.chosen_map_path.size():
		return run_state.chosen_map_path[row_index + 1] == target_index
	return row_index + 1 == run_state.encounter_index and _is_map_node_selectable(row_index + 1, target_index)

func _map_node_button(node_data: Dictionary, row_index: int) -> Button:
	var node_index: int = int(node_data.get("index", 0))
	var button: Button = _route_node_button(node_data)
	var selectable: bool = _is_map_node_selectable(row_index, node_index)
	var selected: bool = row_index < run_state.chosen_map_path.size() and run_state.chosen_map_path[row_index] == node_index
	button.custom_minimum_size = Vector2(180, 104)
	button.text = _map_node_text(node_data, row_index, selected)
	button.disabled = not selectable
	if selected:
		button.add_theme_stylebox_override("disabled", _style_box(Color("1f4d3b"), Color("d8f0c4"), 2, 8))
		button.add_theme_color_override("font_disabled_color", Color("f4ffe9"))
	elif row_index < run_state.encounter_index:
		button.add_theme_stylebox_override("disabled", _style_box(Color("263141"), Color("596678"), 1, 8))
		button.add_theme_color_override("font_disabled_color", Color("aeb9c8"))
	elif not selectable:
		button.add_theme_stylebox_override("disabled", _style_box(Color("262a31"), Color("59606b"), 1, 8))
		button.add_theme_color_override("font_disabled_color", Color("8f98a5"))
	return button

func _map_node_text(node_data: Dictionary, row_index: int, selected: bool) -> String:
	var title: String = _map_node_title(node_data)
	var status: String = "已選" if selected else _map_node_status(row_index, int(node_data.get("index", 0)))
	return "[%s] %s\n%s" % [_map_node_badge(node_data), title, status]

func _map_node_badge(node_data: Dictionary) -> String:
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		return "休"
	if node_type == "event":
		return "遇"
	if node_type == "shop":
		return "黑" if bool(node_data.get("black_market", false)) else "店"
	if node_type == "boss":
		return "王"
	return "戰"

func _map_node_title(node_data: Dictionary) -> String:
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		return "休息"
	if node_type == "event":
		return "奇遇"
	if node_type == "shop":
		return "黑店" if bool(node_data.get("black_market", false)) else "商店"
	var enemy: EnemyData = node_data.get("enemy") as EnemyData
	if enemy == null:
		return "戰鬥"
	if node_type == "boss":
		return "Boss\n%s" % enemy.display_name
	return "戰鬥\n%s" % enemy.display_name

func _map_node_status(row_index: int, node_index: int) -> String:
	if row_index == run_state.encounter_index and _is_map_node_selectable(row_index, node_index):
		return "可前往"
	if row_index < run_state.encounter_index:
		return "已錯過"
	if row_index == run_state.encounter_index:
		return "未連通"
	return "未知路線"

func _map_link_text(node_data: Dictionary) -> String:
	var connects: Array = node_data.get("connects", []) as Array
	if connects.is_empty():
		return "終點"
	var labels: Array[String] = []
	for target: Variant in connects:
		labels.append(str(int(target) + 1))
	return "通往 " + " / ".join(labels)

func _is_map_node_selectable(row_index: int, node_index: int) -> bool:
	if row_index != run_state.encounter_index:
		return false
	if row_index == 0:
		return true
	if run_state.chosen_map_path.size() < row_index:
		return false
	var previous_index: int = run_state.chosen_map_path[row_index - 1]
	var previous_row: Array = run_state.encounter_choices[row_index - 1]
	if previous_index < 0 or previous_index >= previous_row.size():
		return false
	var previous_node: Dictionary = previous_row[previous_index] as Dictionary
	var connects: Array = previous_node.get("connects", []) as Array
	return connects.has(node_index)

func choose_route_node(node_data: Dictionary) -> void:
	var node_index: int = int(node_data.get("index", 0))
	if run_state.chosen_map_path.size() > run_state.encounter_index:
		run_state.chosen_map_path[run_state.encounter_index] = node_index
	else:
		run_state.chosen_map_path.append(node_index)
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		resolve_rest_node()
	elif node_type == "event":
		run_state.current_event_variant = String(node_data.get("event_variant", "shrine"))
		show_event_node()
	elif node_type == "shop":
		open_shop_node(bool(node_data.get("black_market", false)))
	else:
		assert(node_data.has("enemy"), "戰鬥節點缺少 enemy 資料：%s" % node_data)
		var enemy: EnemyData = node_data["enemy"] as EnemyData
		start_next_battle(enemy)

func start_next_battle(enemy: EnemyData) -> void:
	battle = BattleController.new()
	battle.setup(run_state, selected_character, enemy)
	_build_battle_scene()
	_start_player_turn()

func _build_battle_scene() -> void:
	_set_background("res://assets/art/battle_bg.png")
	_clear_root()
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 6)
	root.add_child(screen)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("f3ead2"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen.add_child(status_label)
	relic_strip = HBoxContainer.new()
	relic_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_strip.add_theme_constant_override("separation", 4)
	relic_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	screen.add_child(relic_strip)
	_refresh_relic_strip()
	var arena: HBoxContainer = HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 24)
	screen.add_child(arena)
	_build_player_widget(arena)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(spacer)
	_build_enemy_widget(arena)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	screen.add_child(bottom)
	_build_left_dock(bottom)
	hand_row = HandFan.new()
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_row.custom_minimum_size = Vector2(0, 290)
	bottom.add_child(hand_row)
	_build_right_dock(bottom)

func _build_player_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(250, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 4)
	parent.add_child(col)
	player_feedback_label = _feedback_label()
	col.add_child(player_feedback_label)
	col.add_child(_portrait_with_block_badge(selected_character.portrait_path, Vector2(220, 230), true, true))
	player_name_label = _card_label(selected_character.display_name, 18, Color("fff8dc"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(player_name_label)
	player_hp_bar = _hp_bar(Color("c84a3a"), Color("3a1a1a"))
	col.add_child(player_hp_bar)
	player_hp_value = _card_label("", 13, Color("fff8dc"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(player_hp_value)
	player_status_line = _card_label("", 13, Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	player_status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(player_status_line)

func _build_enemy_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(260, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 4)
	parent.add_child(col)
	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 16)
	enemy_label.add_theme_color_override("font_color", Color("f7df9c"))
	col.add_child(enemy_label)
	enemy_feedback_label = _feedback_label()
	col.add_child(enemy_feedback_label)
	col.add_child(_portrait_with_block_badge(battle.enemy.portrait_path, Vector2(230, 230), true, false, battle.enemy.portrait_tint))
	enemy_name_label = _card_label(battle.enemy.display_name, 18, Color("ffd9a3"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(enemy_name_label)
	enemy_hp_bar = _hp_bar(Color("c84a3a"), Color("3a1a1a"))
	col.add_child(enemy_hp_bar)
	enemy_hp_value = _card_label("", 13, Color("fff8dc"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(enemy_hp_value)
	enemy_status_line = _card_label("", 13, Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	enemy_status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(enemy_status_line)

func _build_left_dock(parent: HBoxContainer) -> void:
	var dock: VBoxContainer = VBoxContainer.new()
	dock.custom_minimum_size = Vector2(140, 0)
	dock.size_flags_horizontal = 0
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 8)
	parent.add_child(dock)
	energy_orb = EnergyOrb.new()
	energy_orb.custom_minimum_size = Vector2(96, 96)
	energy_orb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dock.add_child(energy_orb)
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(140, 96)
	log_label.fit_content = true
	log_label.scroll_following = true
	log_label.bbcode_enabled = false
	log_label.add_theme_color_override("default_color", Color("c5cad6"))
	log_label.add_theme_font_size_override("normal_font_size", 12)
	dock.add_child(log_label)
	var deck_button: Button = _button("查看牌組")
	deck_button.add_theme_font_size_override("font_size", 13)
	deck_button.custom_minimum_size = Vector2(0, 32)
	deck_button.pressed.connect(show_deck_view)
	dock.add_child(deck_button)

func _build_right_dock(parent: HBoxContainer) -> void:
	var dock: VBoxContainer = VBoxContainer.new()
	dock.custom_minimum_size = Vector2(140, 0)
	dock.size_flags_horizontal = 0
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(dock)
	end_turn_button = Button.new()
	end_turn_button.text = "結束回合"
	end_turn_button.custom_minimum_size = Vector2(128, 76)
	end_turn_button.add_theme_font_size_override("font_size", 20)
	end_turn_button.add_theme_color_override("font_color", Color("fff5cf"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	end_turn_button.add_theme_stylebox_override("normal", _style_box(Color("8a3a2e"), Color("f4d985"), 3, 12))
	end_turn_button.add_theme_stylebox_override("hover", _style_box(Color("a44a36"), Color("ffeab0"), 4, 12))
	end_turn_button.add_theme_stylebox_override("pressed", _style_box(Color("662a22"), Color("c8b46f"), 3, 12))
	end_turn_button.add_theme_stylebox_override("disabled", _style_box(Color("4a3530"), Color("786258"), 2, 12))
	end_turn_button.pressed.connect(end_player_turn)
	dock.add_child(end_turn_button)

func _portrait_with_block_badge(path: String, portrait_size: Vector2, show_full: bool, is_player: bool, tint: Color = Color.WHITE) -> Control:
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = portrait_size
	var portrait: TextureRect = _portrait_rect(path, portrait_size, show_full)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.modulate = tint
	wrap.add_child(portrait)
	var badge: BlockBadge = BlockBadge.new()
	badge.custom_minimum_size = Vector2(48, 56)
	badge.size = Vector2(48, 56)
	badge.position = Vector2(8, portrait_size.y - 64)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(badge)
	if is_player:
		player_block_badge = badge
		player_portrait_wrap = wrap
	else:
		enemy_block_badge = badge
		enemy_portrait_wrap = wrap
	return wrap

func _refresh_relic_strip() -> void:
	if relic_strip == null:
		return
	for child: Node in relic_strip.get_children():
		child.queue_free()
	for r: RelicData in run_state.relics:
		var icon: RelicIcon = RelicIcon.new()
		icon.custom_minimum_size = Vector2(28, 28)
		relic_strip.add_child(icon)
		icon.set_relic(r)

func _grant_relic(relic: RelicData) -> bool:
	if relic == null:
		return false
	if run_state.has_relic(relic.id):
		return false
	run_state.add_relic(relic)
	return true

func _try_random_relic_drop(rarity_chance: float = 0.25) -> RelicData:
	if randf() > rarity_chance:
		return null
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()].clone()

func _hp_bar(fill_color: Color, bg_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 1
	var bg: StyleBoxFlat = _style_box(bg_color, Color("1a1a1f"), 1, 4)
	var fill: StyleBoxFlat = _style_box(fill_color, fill_color.lightened(0.25), 0, 4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _start_player_turn() -> void:
	var result: Dictionary = battle.start_turn()
	_show_state_feedback(result["before_tick"])
	if _check_battle_end():
		return
	_refresh_battle(true)

func play_card(card: CardData, source_button: Button = null) -> void:
	var result: Dictionary = battle.play_card(card)
	if not bool(result["affordable"]):
		_refresh_battle()
		return
	if source_button != null and is_instance_valid(source_button):
		_detach_card_button(source_button)
		_refresh_battle()
		_animate_played_card(source_button, card)
	else:
		_refresh_battle()
	_show_state_feedback(result["before_card"])
	if bool(result["ended"]) and _check_battle_end():
		return

func end_player_turn() -> void:
	end_turn_button.disabled = true
	_animate_hand_discard()
	var action: Dictionary = battle.begin_enemy_phase()
	_show_enemy_action_preview(action)
	_refresh_battle()
	await get_tree().create_timer(0.8).timeout
	if _action_has_damage(action):
		_dash_node(enemy_portrait_wrap, Vector2(-1, 0), 36.0, 0.22)
		await get_tree().create_timer(0.1).timeout
	var result: Dictionary = battle.resolve_enemy_phase(action)
	_show_state_feedback(result["before_enemy"])
	_refresh_battle()
	if bool(result["ended"]) and _check_battle_end():
		return
	await get_tree().create_timer(0.6).timeout
	_start_player_turn()

func _action_has_damage(action: Dictionary) -> bool:
	for effect: Dictionary in (action.get("effects", []) as Array):
		if String(effect.get("kind", "")) == "damage":
			return true
	return false

func _show_enemy_action_preview(action: Dictionary) -> void:
	var preview_lines: Array[String] = []
	preview_lines.append(String(action["intent"]))
	var effect_text: String = _enemy_action_effect_summary(action)
	if not effect_text.is_empty():
		preview_lines.append(effect_text)
	_show_feedback(enemy_feedback_label, preview_lines, Color("f7df9c"))

func _enemy_action_effect_summary(action: Dictionary) -> String:
	var effects: Array = action.get("effects", []) as Array
	var parts: Array[String] = []
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"damage":
				parts.append("傷害 %d" % amount)
			"block":
				parts.append("護體 +%d" % amount)
			"poison":
				parts.append("蠱毒 +%d" % amount)
			"weak":
				parts.append("虛弱 +%d" % amount)
			"vulnerable":
				parts.append("破綻 +%d" % amount)
			"heal":
				parts.append("治療 +%d" % amount)
			_:
				if amount > 0:
					parts.append("%s %d" % [kind, amount])
	if parts.is_empty():
		return ""
	return " / ".join(parts)

func _check_battle_end() -> bool:
	if battle.is_victory():
		_complete_battle_victory()
		return true
	if battle.is_defeat():
		show_result(false)
		return true
	return false

func _complete_battle_victory() -> void:
	battle.complete_victory()
	var gold_reward: int = _battle_gold_reward(battle.enemy)
	# 聚寶盆：勝利額外金錢
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "battle_victory":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "gold_bonus":
					gold_reward += int(e.get("amount", 0))
	run_state.gold = run_state.gold + gold_reward
	battle.add_log("獲得 %d 枚銅錢。" % gold_reward)
	# Boss 必掉神器；一般戰鬥 25% 機率掉裝備
	var dropped: RelicData = null
	var was_boss: bool = battle.enemy.id == "moon_worshipper" or battle.enemy.id == "centipede_lord" or battle.enemy.id == "witch_queen"
	if was_boss:
		for a: RelicData in RelicCatalog.artifacts():
			if a.boss_id == battle.enemy.id and not run_state.has_relic(a.id):
				dropped = a.clone()
				break
	else:
		dropped = _try_random_relic_drop(0.25)
	if dropped != null:
		run_state.add_relic(dropped)
		battle.add_log("獲得裝備：%s" % dropped.display_name)
	run_state.encounter_index = run_state.encounter_index + 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		show_result(true)
	else:
		show_card_reward()

func show_card_reward() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("戰鬥勝利", 34))
	box.add_child(_paragraph("%s 擊敗了 %s。選擇 1 張卡加入牌組。" % [selected_character.display_name, battle.enemy.display_name]))
	box.add_child(_paragraph("目前 HP %d/%d，銅錢 %d，牌組 %d 張。" % [run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size()]))
	var rewards: Array[CardData] = _make_reward_choices()
	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 12)
	box.add_child(reward_row)
	for reward: CardData in rewards:
		var reward_button: Button = _reward_card_button(reward)
		reward_button.pressed.connect(func(card: CardData = reward): choose_reward_card(card))
		reward_row.add_child(reward_button)
	var skip: Button = _button("跳過獎勵")
	skip.pressed.connect(show_progress_screen)
	box.add_child(skip)
	var deck_button: Button = _button("查看目前牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func _make_reward_choices() -> Array[CardData]:
	var pool: Array[CardData] = []
	var used_ids: Array[String] = []
	for card: CardData in selected_character.reward_pool:
		if not used_ids.has(card.id):
			used_ids.append(card.id)
			pool.append(card.clone())
	pool.shuffle()
	var count: int = 3
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "card_reward_count_bonus":
					count += int(e.get("amount", 0))
	var rewards: Array[CardData] = []
	for i: int in range(min(count, pool.size())):
		rewards.append(pool[i])
	return rewards

func choose_reward_card(card: CardData) -> void:
	run_state.deck.append(card.clone())
	show_progress_screen()

func _battle_gold_reward(enemy: EnemyData) -> int:
	if enemy.id == "moon_worshipper":
		return 65
	return 28 + run_state.encounter_index * 8

func _route_node_button(node_data: Dictionary) -> Button:
	var node_type: String = String(node_data.get("type", "battle"))
	var button: Button
	if node_type == "rest":
		button = _route_rest_button()
	elif node_type == "event":
		button = _route_event_button()
	elif node_type == "shop":
		button = _route_shop_button(bool(node_data.get("black_market", false)))
	else:
		assert(node_data.has("enemy"), "戰鬥節點缺少 enemy 資料：%s" % node_data)
		var enemy: EnemyData = node_data["enemy"] as EnemyData
		button = _route_enemy_button(enemy, node_type == "boss")
	button.pressed.connect(func(): choose_route_node(node_data))
	return button

func _build_route_button(text: String, icon_type: String, icon_color: Color, font_color: Color = Color("fff8dc")) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon: MapNodeIcon = MapNodeIcon.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.set_type(icon_type, icon_color)
	box.add_child(icon)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return button

func _route_enemy_button(enemy: EnemyData, is_boss: bool = false) -> Button:
	var label_prefix: String = "Boss" if is_boss else "戰鬥"
	var text: String = "%s\n%s  HP %d\n%s" % [label_prefix, enemy.display_name, enemy.max_hp, _enemy_route_summary(enemy)]
	var icon_type: String = "boss" if is_boss else "battle"
	var icon_color: Color = Color("f8d29c") if is_boss else Color("e2c486")
	var button: Button = _build_route_button(text, icon_type, icon_color)
	var bg_color: Color = Color("452a35") if is_boss else Color("273449")
	button.add_theme_stylebox_override("normal", _style_box(bg_color, Color("c8b46f"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(bg_color.lightened(0.14), Color("f7df9c"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("1d2838"), Color("e4c66a"), 2, 8))
	return button

func _route_rest_button() -> Button:
	var heal_amount: int = EventData.rest_heal_for(selected_character.max_hp)
	var text: String = "休息\n回復 %d HP\n或升級 1 張牌" % heal_amount
	var button: Button = _build_route_button(text, "rest", Color("f4a13a"), Color("f4ffe9"))
	button.add_theme_stylebox_override("normal", _style_box(Color("2f5f4a"), Color("c8e6c9"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("3d755d"), Color("eef9df"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("244736"), Color("d8f0c4"), 2, 8))
	return button

func _route_event_button() -> Button:
	var button: Button = _build_route_button("奇遇\n山路異光\n選擇一項機緣", "event", Color("e2cdff"))
	button.add_theme_stylebox_override("normal", _style_box(Color("4f3f73"), Color("d9c2ff"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("66508f"), Color("efe2ff"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("382d55"), Color("d9c2ff"), 2, 8))
	return button

func _route_shop_button(is_black_shop: bool) -> Button:
	var title: String = "黑店" if is_black_shop else "商店"
	var hint: String = "高價珍品\n升級卡機率高" if is_black_shop else "購買卡牌\n補強牌組"
	var text: String = "%s\n%s\n銅錢 %d" % [title, hint, run_state.gold]
	var icon_type: String = "black_shop" if is_black_shop else "shop"
	var icon_color: Color = Color("e2a86b") if is_black_shop else Color("e4c66a")
	var button: Button = _build_route_button(text, icon_type, icon_color)
	var bg_color: Color = Color("2d2036") if is_black_shop else Color("5b4a2f")
	var border_color: Color = Color("e2a86b") if is_black_shop else Color("e4c66a")
	button.add_theme_stylebox_override("normal", _style_box(bg_color, border_color, 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(bg_color.lightened(0.14), Color("f7df9c"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(bg_color.darkened(0.12), Color("d2b96b"), 2, 8))
	return button

func _enemy_route_summary(enemy: EnemyData) -> String:
	var badges: Array[String] = []
	for action: Dictionary in enemy.actions:
		var badge: String = _intent_badge(action)
		for part: String in badge.split(" "):
			if not badges.has(part):
				badges.append(part)
	return " ".join(badges)

func resolve_rest_node() -> void:
	run_state.pending_rest_heal = EventData.rest_heal_for(selected_character.max_hp)
	show_rest_node()

func show_rest_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("清修片刻", 34))
	box.add_child(_paragraph("溪聲入耳，山風洗塵。你可以調息療傷，也可以靜心打磨一式招法。"))
	box.add_child(_paragraph("%s  HP %d/%d  銅錢 %d  可升級 %d 張牌" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, _upgradeable_cards().size()]))
	var heal_button: Button = _button("調息：回復 %d HP" % run_state.pending_rest_heal)
	heal_button.pressed.connect(resolve_rest_heal)
	box.add_child(heal_button)
	var upgrade_button: Button = _button("打磨招式：升級 1 張牌")
	upgrade_button.disabled = _upgradeable_cards().is_empty()
	upgrade_button.pressed.connect(show_upgrade_card_view)
	box.add_child(upgrade_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func resolve_rest_heal() -> void:
	var bonus: int = 0
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "rest_heal_bonus":
					bonus += int(e.get("amount", 0))
	run_state.heal(run_state.pending_rest_heal + bonus)
	run_state.pending_rest_heal = 0
	advance_non_battle_node()

func show_event_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	box.add_child(_title(String(event_data["title"]), 34))
	box.add_child(_paragraph(String(event_data["flavor"])))
	box.add_child(_paragraph("%s  HP %d/%d  銅錢 %d  本輪增傷 +%d" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.power_bonus]))
	var heal_amount: int = int(event_data["heal"])
	var gain_cost: int = int(event_data["gain_cost"])
	var power_gain: int = int(event_data["power"])
	var heal_button: Button = _button("調息：回復 %d HP" % heal_amount)
	heal_button.pressed.connect(func(): resolve_event_heal(heal_amount))
	box.add_child(heal_button)
	var card_button: Button = _button("探取：失去 %d HP，獲得 1 張卡" % gain_cost)
	card_button.pressed.connect(func(): resolve_event_gain_card(gain_cost))
	box.add_child(card_button)
	var power_button: Button = _button("%s：本輪增傷 +%d" % [String(event_data["power_label"]), power_gain])
	power_button.pressed.connect(func(): resolve_event_power(power_gain))
	box.add_child(power_button)
	var upgrade_button: Button = _button("悟法：升級 1 張牌")
	upgrade_button.disabled = _upgradeable_cards().is_empty()
	upgrade_button.pressed.connect(show_upgrade_card_view)
	box.add_child(upgrade_button)
	var remove_button: Button = _button("洗髓：移除 1 張牌")
	remove_button.disabled = run_state.deck.size() <= 5
	remove_button.pressed.connect(show_remove_card_view)
	box.add_child(remove_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func resolve_event_heal(amount: int) -> void:
	run_state.heal(amount)
	advance_non_battle_node()

func resolve_event_gain_card(hp_cost: int = 6) -> void:
	run_state.take_damage(hp_cost)
	var rewards: Array[CardData] = _make_reward_choices()
	if not rewards.is_empty():
		run_state.deck.append(rewards[0].clone())
	advance_non_battle_node()

func resolve_event_power(amount: int = 1) -> void:
	var bonus: int = 0
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "event_power_bonus":
					bonus += int(e.get("amount", 0))
	run_state.power_bonus = run_state.power_bonus + amount + bonus
	advance_non_battle_node()

func open_shop_node(is_black_shop: bool) -> void:
	run_state.current_shop_is_black = is_black_shop
	run_state.current_shop_inventory = _make_shop_inventory(is_black_shop)
	show_shop_node()

func show_shop_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title_text: String = "夜路黑店" if run_state.current_shop_is_black else "山道商店"
	var flavor_text: String = "簾後藏著來路不明的珍品，價格狠，成色也狠。" if run_state.current_shop_is_black else "行商在山道旁支起小攤，貨色普通但價格公道。"
	box.add_child(_title(title_text, 34))
	box.add_child(_paragraph(flavor_text))
	box.add_child(_paragraph("%s  HP %d/%d  銅錢 %d  牌組 %d 張" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size()]))
	var goods_row: HBoxContainer = HBoxContainer.new()
	goods_row.add_theme_constant_override("separation", 12)
	box.add_child(goods_row)
	for item: Dictionary in run_state.current_shop_inventory:
		goods_row.add_child(_shop_item_view(item))
	# 商店多賣 1 件裝備（每次進商店重抽）
	if not run_state.has_meta("shop_relic_offered_at_index") or int(run_state.get_meta("shop_relic_offered_at_index", -1)) != run_state.encounter_index:
		run_state.set_meta("shop_relic_offered_at_index", run_state.encounter_index)
		run_state.set_meta("shop_relic_id", _pick_shop_relic_id())
	var shop_relic_id: String = String(run_state.get_meta("shop_relic_id", ""))
	if not shop_relic_id.is_empty() and not run_state.has_relic(shop_relic_id):
		var relic: RelicData = RelicCatalog.by_id(shop_relic_id)
		if relic != null:
			goods_row.add_child(_shop_relic_view(relic))
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)
	var leave: Button = _button("離開商店")
	leave.pressed.connect(advance_non_battle_node)
	box.add_child(leave)

func _pick_shop_relic_id() -> String:
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	if run_state.current_shop_is_black:
		# 黑店 30% 機率出角色專武
		var weapon_pool: Array[RelicData] = RelicCatalog.weapons_for_character(selected_character.id)
		var avail_weapons: Array[RelicData] = []
		for w: RelicData in weapon_pool:
			if not run_state.has_relic(w.id):
				avail_weapons.append(w)
		if not avail_weapons.is_empty() and randf() < 0.3:
			return avail_weapons[randi() % avail_weapons.size()].id
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()].id

func _shop_relic_view(relic: RelicData) -> Control:
	var price: int = _shop_relic_price(relic)
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = Vector2(230, 338)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var icon: RelicIcon = RelicIcon.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	icon.set_relic(relic)
	box.add_child(_card_label(relic.display_name, 17, Color("fff8dc"), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_card_label(relic.description, 12, Color("d8e0ec"), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_card_label("價格：%d 銅錢" % price, 14, Color("f7df9c"), HORIZONTAL_ALIGNMENT_CENTER))
	var can_buy: bool = run_state.gold >= price
	var buy_button: Button = _button("買下裝備")
	buy_button.disabled = not can_buy
	buy_button.pressed.connect(func(): _buy_shop_relic(relic, price))
	box.add_child(buy_button)
	return panel

func _shop_relic_price(relic: RelicData) -> int:
	var base: int = 70
	match relic.rarity:
		"uncommon":
			base = 95
		"rare":
			base = 130
		"legendary":
			base = 180
	if run_state.current_shop_is_black:
		base = int(base * 1.2)
	# 通寶錢折扣
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "shop_discount":
					base -= int(e.get("amount", 0))
	return max(10, base)

func _buy_shop_relic(relic: RelicData, price: int) -> void:
	if run_state.gold < price:
		return
	run_state.gold -= price
	run_state.add_relic(relic)
	run_state.set_meta("shop_relic_id", "")  # 清掉這次的商店裝備
	show_shop_node()

func _shop_item_view(item: Dictionary) -> Control:
	var card: CardData = item["card"] as CardData
	var price: int = int(item["price"])
	# 通寶錢折扣
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "shop_discount":
					price = max(5, price - int(e.get("amount", 0)))
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = Vector2(230, 338)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var can_buy: bool = run_state.gold >= price
	var card_button: Button = _make_card_button(card, card.cost, Vector2(210, 270), can_buy, true)
	card_button.disabled = not can_buy
	card_button.pressed.connect(func(): buy_shop_card(card, price))
	box.add_child(card_button)
	var price_label: Label = _card_label("價格：%d 銅錢" % price, 15, Color("f7df9c"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(price_label)
	var buy_button: Button = _button("買下")
	buy_button.disabled = not can_buy
	buy_button.pressed.connect(func(): buy_shop_card(card, price))
	box.add_child(buy_button)
	return panel

func buy_shop_card(card: CardData, price: int) -> void:
	if run_state.gold < price:
		return
	run_state.gold = run_state.gold - price
	run_state.deck.append(card.clone())
	for i: int in range(run_state.current_shop_inventory.size()):
		var item_card: CardData = run_state.current_shop_inventory[i]["card"] as CardData
		if item_card == card:
			run_state.current_shop_inventory.remove_at(i)
			break
	show_shop_node()

func _make_shop_inventory(is_black_shop: bool) -> Array[Dictionary]:
	return ShopInventory.build(selected_character, is_black_shop)

func show_remove_card_view() -> void:
	if run_state.deck.size() <= 5:
		return
	show_deck_view("remove")

func show_upgrade_card_view() -> void:
	if _upgradeable_cards().is_empty():
		return
	show_deck_view("upgrade")

func remove_card_from_deck(card: CardData) -> void:
	if run_state.deck.size() <= 5:
		close_deck_view()
		return
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck.remove_at(i)
			break
	close_deck_view()
	advance_non_battle_node()

func upgrade_card_in_deck(card: CardData) -> void:
	if card.upgraded:
		return
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck[i] = card.upgraded_copy()
			break
	close_deck_view()
	advance_non_battle_node()

func _upgradeable_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card: CardData in run_state.deck:
		if not card.upgraded:
			cards.append(card)
	return cards

func advance_non_battle_node() -> void:
	run_state.encounter_index = run_state.encounter_index + 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		show_result(true)
	else:
		show_progress_screen()

func show_deck_view(mode: String = "view") -> void:
	close_deck_view()
	deck_view_mode = mode
	deck_overlay = PanelContainer.new()
	deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_overlay.add_theme_stylebox_override("panel", _style_box(Color("0b111a", 0.94), Color("c8b46f"), 2, 8))
	add_child(deck_overlay)
	var outer: MarginContainer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_bottom", 28)
	deck_overlay.add_child(outer)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	outer.add_child(box)
	var title_text: String = "目前牌組"
	if deck_view_mode == "remove":
		title_text = "選擇要移除的牌"
	elif deck_view_mode == "upgrade":
		title_text = "選擇要升級的牌"
	box.add_child(_title(title_text, 32))
	box.add_child(_paragraph("%s  HP %d/%d  銅錢 %d  共 %d 張牌" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size()]))
	var summary: Label = _paragraph(_deck_summary_text())
	box.add_child(summary)
	if deck_view_mode == "remove":
		box.add_child(_paragraph("至少保留 5 張牌。點選一張牌後會移除並完成事件。"))
	elif deck_view_mode == "upgrade":
		box.add_child(_paragraph("點選一張未升級的牌，升級後會完成此節點。"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for card: CardData in run_state.deck:
		grid.add_child(_deck_view_card(card, deck_view_mode))
	var close_button: Button = _button("關閉")
	close_button.pressed.connect(close_deck_view)
	box.add_child(close_button)

func close_deck_view() -> void:
	if deck_overlay != null:
		deck_overlay.queue_free()
		deck_overlay = null
	deck_view_mode = "view"

func _deck_summary_text() -> String:
	var attack_count: int = 0
	var skill_count: int = 0
	var power_count: int = 0
	for card: CardData in run_state.deck:
		match card.card_type:
			"attack":
				attack_count = attack_count + 1
			"skill":
				skill_count = skill_count + 1
			"power":
				power_count = power_count + 1
	return "攻擊 %d    技能 %d    能力 %d    可升級 %d\n%s" % [attack_count, skill_count, power_count, _upgradeable_cards().size(), _duplicate_summary_text()]

func _duplicate_summary_text() -> String:
	var counts: Dictionary = {}
	var names: Dictionary = {}
	for card: CardData in run_state.deck:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
		names[card.id] = card.display_title()
	var parts: Array[String] = []
	for id_variant: Variant in counts.keys():
		var id: String = String(id_variant)
		var count: int = int(counts[id])
		if count > 1:
			parts.append("%s x%d" % [String(names[id]), count])
	if parts.is_empty():
		return "重複：無"
	return "重複：" + "，".join(parts)

func _deck_view_card(card: CardData, mode: String = "view") -> Button:
	var selectable: bool = mode == "remove" or (mode == "upgrade" and not card.upgraded)
	var visually_enabled: bool = mode != "upgrade" or not card.upgraded
	var button: Button = _make_card_button(card, card.cost, Vector2(190, 260), true, visually_enabled)
	button.disabled = not selectable
	if mode == "remove":
		button.pressed.connect(func(): remove_card_from_deck(card))
	elif mode == "upgrade" and not card.upgraded:
		button.pressed.connect(func(): upgrade_card_in_deck(card))
	else:
		button.add_theme_stylebox_override("disabled", _style_box(_card_color(card.card_type, true), Color("e7d38a"), 2, 8))
		button.add_theme_color_override("font_disabled_color", Color("fff8dc"))
	return button

func show_result(victory: bool) -> void:
	SaveManager.clear()
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	if victory:
		box.add_child(_title("小型冒險完成", 34))
		box.add_child(_paragraph("%s 完成了 %d 層路線，最終 HP %d/%d，剩餘銅錢 %d。" % [selected_character.display_name, run_state.encounter_choices.size(), run_state.hp, selected_character.max_hp, run_state.gold]))
	else:
		box.add_child(_title("戰鬥失敗", 34))
		box.add_child(_paragraph("%s 敗於 %s。調整出牌節奏再試一次。" % [selected_character.display_name, battle.enemy.display_name]))
	var retry: Button = _button("重新開始此角色")
	retry.pressed.connect(func(): start_run(selected_character))
	box.add_child(retry)
	var select: Button = _button("重新選擇角色")
	select.pressed.connect(show_character_select)
	box.add_child(select)
	var menu: Button = _button("返回主選單")
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func _refresh_battle(animate_draw: bool = false) -> void:
	var top_parts: Array[String] = ["第 %d/%d 層" % [run_state.encounter_index + 1, run_state.encounter_choices.size()]]
	top_parts.append("抽 %d / 棄 %d" % [battle.deck.draw_pile.size(), battle.deck.discard_pile.size()])
	var passive_status: String = battle.passive_status_text()
	if not passive_status.is_empty():
		top_parts.append(passive_status)
	status_label.text = "    ".join(top_parts)
	_refresh_combatant_hp(player_hp_bar, player_hp_value, int(battle.state["player_hp"]), int(battle.state["player_max_hp"]))
	player_block_badge.set_amount(int(battle.state["player_block"]))
	player_status_line.text = _status_summary(int(battle.state["player_poison"]), int(battle.state["player_weak"]), int(battle.state["player_vulnerable"]))
	_refresh_combatant_hp(enemy_hp_bar, enemy_hp_value, int(battle.state["enemy_hp"]), int(battle.state["enemy_max_hp"]))
	enemy_block_badge.set_amount(int(battle.state["enemy_block"]))
	enemy_status_line.text = _status_summary(int(battle.state["enemy_poison"]), int(battle.state["enemy_weak"]), int(battle.state["enemy_vulnerable"]))
	var next_action: Dictionary = battle.next_enemy_action()
	enemy_label.text = "%s  下一步\n%s" % [_intent_badge(next_action), String(next_action["intent"])]
	energy_orb.set_energy(int(battle.state["energy"]), BattleController.TURN_ENERGY)
	var buttons: Array[Button] = []
	card_buttons.clear()
	for card: CardData in battle.deck.hand:
		var button: Button = _card_button(card)
		buttons.append(button)
		card_buttons.append(button)
	var draw_source: Vector2 = Vector2(120.0, get_viewport_rect().size.y - 70.0)
	hand_row.set_cards(buttons, animate_draw, draw_source)
	log_label.text = "\n".join(battle.battle_log.slice(max(0, battle.battle_log.size() - 4)))
	end_turn_button.disabled = false

func _refresh_combatant_hp(bar: ProgressBar, value_label: Label, hp: int, max_hp: int) -> void:
	bar.value = 0.0 if max_hp <= 0 else float(hp) / float(max_hp)
	value_label.text = "%d / %d" % [hp, max_hp]

func _status_summary(poison: int, weak: int, vulnerable: int) -> String:
	var parts: Array[String] = []
	if poison > 0:
		parts.append("蠱毒 %d" % poison)
	if weak > 0:
		parts.append("虛弱 %d" % weak)
	if vulnerable > 0:
		parts.append("破綻 %d" % vulnerable)
	if parts.is_empty():
		return ""
	return "   ".join(parts)

func _card_button(card: CardData) -> Button:
	var affordable: bool = int(battle.state["energy"]) >= battle.effective_card_cost(card)
	var button: Button = _make_card_button(card, card.cost, Vector2(172, 238), affordable, true)
	button.disabled = not affordable
	button.pressed.connect(func(): play_card(card, button))
	return button

func _reward_card_button(card: CardData) -> Button:
	return _make_card_button(card, card.cost, Vector2(230, 300), true, true)

func _make_card_button(card: CardData, cost: int, size: Vector2, affordable: bool, selectable: bool) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	_style_card_button(button, card, affordable)
	var outer: MarginContainer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 8)
	outer.add_theme_constant_override("margin_top", 8)
	outer.add_theme_constant_override("margin_right", 8)
	outer.add_theme_constant_override("margin_bottom", 8)
	button.add_child(outer)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	outer.add_child(box)
	var type_bar: PanelContainer = PanelContainer.new()
	type_bar.custom_minimum_size = Vector2(0, 5)
	type_bar.add_theme_stylebox_override("panel", _strip_box(_card_color(card.card_type, true).lightened(0.16), 3))
	box.add_child(type_bar)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	box.add_child(header)
	var title: Label = _card_label(card.display_title(), 14, Color("fff8dc"), HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var rarity_badge: Label = _card_label(_card_rarity_name(card), 11, _card_rarity_color(card), HORIZONTAL_ALIGNMENT_RIGHT)
	header.add_child(rarity_badge)
	var cost_badge: PanelContainer = PanelContainer.new()
	cost_badge.custom_minimum_size = Vector2(30, 26)
	cost_badge.add_theme_stylebox_override("panel", _style_box(Color("161d2a", 0.92), Color("f4d985"), 1, 6))
	header.add_child(cost_badge)
	var cost_label: Label = _card_label(str(cost), 15, Color("f7df9c"), HORIZONTAL_ALIGNMENT_CENTER)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_badge.add_child(cost_label)
	var art_frame: PanelContainer = PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(size.x - 22, max(86.0, size.y * 0.42))
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.add_theme_stylebox_override("panel", _style_box(Color("0b111a", 0.42), _card_rarity_color(card), 1, 6))
	box.add_child(art_frame)
	var art: TextureRect = TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = _load_texture(card.art_path)
	if texture != null:
		art.texture = texture
	if not affordable or not selectable:
		art.modulate = Color(0.72, 0.72, 0.72, 0.62)
	art_frame.add_child(art)
	var type_line: Label = _card_label(_card_type_name(card.card_type), 12, Color("f7df9c"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(type_line)
	var desc: Label = _card_label(card.display_description(), 12, Color("e8edf3"), HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	_ignore_child_mouse(button)
	return button

func _card_label(text: String, size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _ignore_child_mouse(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_child_mouse(child)

func _detach_card_button(button: Button) -> void:
	var global_pos: Vector2 = button.global_position
	var preserved_scale: Vector2 = button.scale
	var parent: Node = button.get_parent()
	if parent != null:
		parent.remove_child(button)
	add_child(button)
	button.pivot_offset = button.size / 2.0
	button.rotation = 0.0
	button.global_position = global_pos
	button.scale = preserved_scale
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_child_mouse(button)
	animating_cards.append(button)

func _animate_played_card(button: Button, card: CardData) -> void:
	var target_label: Label = enemy_feedback_label if card.card_type == "attack" else player_feedback_label
	if target_label == null:
		button.queue_free()
		return
	var target_center: Vector2 = target_label.global_position + target_label.size / 2.0
	var target_pos: Vector2 = target_center - button.size / 2.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(button, "global_position", target_pos, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.65, 0.65), 0.42)
	tween.tween_property(button, "modulate:a", 0.0, 0.42).set_delay(0.06)
	tween.finished.connect(func() -> void:
		animating_cards.erase(button)
		if is_instance_valid(button):
			button.queue_free())

func _shake_node(node: Control, intensity: float = 8.0, duration: float = 0.25) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = node.position
	var steps: int = 5
	var step_duration: float = duration / float(steps + 1)
	var tween: Tween = create_tween()
	for i: int in range(steps):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", orig_pos + offset, step_duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", orig_pos, step_duration)

func _dash_node(node: Control, direction: Vector2, distance: float = 36.0, duration: float = 0.24) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = node.position
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", orig_pos + direction.normalized() * distance, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", orig_pos, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _flash_node(node: Control, color: Color = Color(1.4, 1.4, 1.6), duration: float = 0.22) -> void:
	if node == null:
		return
	var orig_mod: Color = node.modulate
	var tween: Tween = create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.35)
	tween.tween_property(node, "modulate", orig_mod, duration * 0.65)

func _animate_hand_discard() -> void:
	var snapshot: Array[Button] = []
	for b: Button in card_buttons:
		if is_instance_valid(b):
			snapshot.append(b)
	if snapshot.is_empty():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var discard_target: Vector2 = Vector2(viewport_size.x - 120.0, viewport_size.y - 70.0)
	for i: int in range(snapshot.size()):
		var button: Button = snapshot[i]
		_detach_card_button(button)
		var delay: float = i * 0.04
		var target_pos: Vector2 = discard_target - button.size / 2.0
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(button, "global_position", target_pos, 0.32).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(button, "scale", Vector2(0.42, 0.42), 0.32).set_delay(delay)
		tween.tween_property(button, "modulate:a", 0.0, 0.32).set_delay(delay + 0.08)
		tween.finished.connect(func() -> void:
			if is_instance_valid(button):
				button.queue_free())
	card_buttons.clear()

func _show_state_feedback(before: Dictionary) -> void:
	var player_lines: Array[String] = []
	var enemy_lines: Array[String] = []
	var bs: Dictionary = battle.state
	var player_hp_delta: int = int(bs["player_hp"]) - int(before["player_hp"])
	var enemy_hp_delta: int = int(bs["enemy_hp"]) - int(before["enemy_hp"])
	var player_block_delta: int = int(bs["player_block"]) - int(before["player_block"])
	var enemy_block_delta: int = int(bs["enemy_block"]) - int(before["enemy_block"])
	var player_poison_delta: int = int(bs["player_poison"]) - int(before["player_poison"])
	var player_weak_delta: int = int(bs["player_weak"]) - int(before["player_weak"])
	var player_vulnerable_delta: int = int(bs["player_vulnerable"]) - int(before["player_vulnerable"])
	var enemy_poison_delta: int = int(bs["enemy_poison"]) - int(before["enemy_poison"])
	var enemy_weak_delta: int = int(bs["enemy_weak"]) - int(before["enemy_weak"])
	var enemy_vulnerable_delta: int = int(bs["enemy_vulnerable"]) - int(before["enemy_vulnerable"])
	if player_hp_delta < 0:
		player_lines.append("受傷 %d" % abs(player_hp_delta))
	elif player_hp_delta > 0:
		player_lines.append("治療 +%d" % player_hp_delta)
	if player_block_delta > 0:
		player_lines.append("護體 +%d" % player_block_delta)
	if player_poison_delta > 0:
		player_lines.append("蠱毒 +%d" % player_poison_delta)
	if player_weak_delta > 0:
		player_lines.append("虛弱 +%d" % player_weak_delta)
	if player_vulnerable_delta > 0:
		player_lines.append("破綻 +%d" % player_vulnerable_delta)
	if enemy_hp_delta < 0:
		enemy_lines.append("傷害 %d" % abs(enemy_hp_delta))
	if enemy_block_delta > 0:
		enemy_lines.append("護體 +%d" % enemy_block_delta)
	if enemy_poison_delta > 0:
		enemy_lines.append("蠱毒 +%d" % enemy_poison_delta)
	if enemy_weak_delta > 0:
		enemy_lines.append("虛弱 +%d" % enemy_weak_delta)
	if enemy_vulnerable_delta > 0:
		enemy_lines.append("破綻 +%d" % enemy_vulnerable_delta)
	if not player_lines.is_empty():
		_show_feedback(player_feedback_label, player_lines, Color("f4b7a8"))
	if not enemy_lines.is_empty():
		_show_feedback(enemy_feedback_label, enemy_lines, Color("f7df9c"))
	if player_hp_delta < 0:
		_shake_node(player_portrait_wrap, 7.0, 0.28)
	if enemy_hp_delta < 0:
		_shake_node(enemy_portrait_wrap, 7.0, 0.28)
	if player_block_delta > 0:
		_flash_node(player_portrait_wrap, Color(1.2, 1.35, 1.55), 0.22)
	if enemy_block_delta > 0:
		_flash_node(enemy_portrait_wrap, Color(1.2, 1.35, 1.55), 0.22)

func _show_feedback(label: Label, lines: Array[String], color: Color) -> void:
	if label == null:
		return
	label.text = "\n".join(lines)
	label.modulate = Color(color.r, color.g, color.b, 1.0)
	label.scale = Vector2(1.08, 1.08)
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)

func _intent_badge(action: Dictionary) -> String:
	var effects: Array = action.get("effects", []) as Array
	var has_damage: bool = false
	var has_block: bool = false
	var has_status: bool = false
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		if kind == "damage":
			has_damage = true
		elif kind == "block":
			has_block = true
		elif kind == "poison" or kind == "weak" or kind == "vulnerable":
			has_status = true
	var badges: Array[String] = []
	if has_damage:
		badges.append("[攻擊]")
	if has_block:
		badges.append("[防守]")
	if has_status:
		badges.append("[異常]")
	if badges.is_empty():
		badges.append("[行動]")
	return " ".join(badges)

func _passive_text() -> String:
	var labels: Array[String] = []
	for passive: Dictionary in selected_character.passives:
		var label: String = String(passive.get("label", ""))
		if not label.is_empty():
			labels.append("被動：%s。" % label)
	return "\n".join(labels)

func _card_type_name(card_type: String) -> String:
	match card_type:
		"attack":
			return "攻擊"
		"skill":
			return "技能"
		"power":
			return "能力"
	return card_type

func _card_color(card_type: String, affordable: bool) -> Color:
	if not affordable:
		return Color("5f6673")
	match card_type:
		"attack":
			return Color("8f3f35")
		"skill":
			return Color("2f6f61")
		"power":
			return Color("7756a8")
	return Color("4f5f73")

func _card_rarity_name(card: CardData) -> String:
	if card.upgraded:
		return "升"
	match card.rarity:
		"rare":
			return "稀"
		"uncommon":
			return "良"
	return "基"

func _card_rarity_color(card: CardData) -> Color:
	if card.upgraded:
		return Color("f7df9c")
	match card.rarity:
		"rare":
			return Color("d9c2ff")
		"uncommon":
			return Color("b9ead6")
	return Color("c7d2e3")

func _style_card_button(button: Button, card: CardData, affordable: bool) -> void:
	var base_color: Color = _card_color(card.card_type, affordable)
	var border_color: Color = _card_rarity_color(card)
	var normal: StyleBoxFlat = _style_box(base_color, border_color, 2, 8)
	var hover: StyleBoxFlat = _style_box(base_color.lightened(0.12), border_color.lightened(0.18), 3, 8)
	var pressed: StyleBoxFlat = _style_box(base_color.darkened(0.12), border_color, 2, 8)
	var disabled: StyleBoxFlat = _style_box(Color("404753"), Color("7a8190"), 1, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	button.add_theme_color_override("font_disabled_color", Color("b8bec8"))
	button.add_theme_font_size_override("font_size", 15)

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _style_box(Color("273449"), Color("8ea3c4"), 1, 6))
	button.add_theme_stylebox_override("hover", _style_box(Color("33435c"), Color("c3d3ee"), 2, 6))
	button.add_theme_stylebox_override("pressed", _style_box(Color("1f2a3c"), Color("e4c66a"), 2, 6))
	button.add_theme_color_override("font_color", Color("edf2f7"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("f7e7a2"))

func _style_box(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func _strip_box(bg_color: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.set_corner_radius_all(radius)
	return box

func _make_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style_box(Color("18212f", 0.86), Color("536277"), 1, 8))
	panel.add_theme_constant_override("margin_left", 18)
	panel.add_theme_constant_override("margin_top", 18)
	panel.add_theme_constant_override("margin_right", 18)
	panel.add_theme_constant_override("margin_bottom", 18)
	return panel

func _title(text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f7df9c"))
	return label

func _paragraph(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("dbe4ef"))
	return label

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.add_theme_font_size_override("font_size", 18)
	_style_button(button)
	return button

func _portrait_rect(path: String, size: Vector2, show_full_image: bool = false) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if show_full_image else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = _load_texture(path)
	if texture != null:
		rect.texture = texture
	return rect

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _feedback_label() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(260, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("f7df9c"))
	label.modulate.a = 0.0
	return label
