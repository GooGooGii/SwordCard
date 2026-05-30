class_name BestiaryScreen
extends Screen

func _build() -> Control:
	var panel: PanelContainer = UIFactory.make_panel()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(UIFactory.title_label("敵將圖鑑", 32))

	var data: Dictionary = Bestiary.load_all()
	var defeated_count: int = 0
	var total_count: int = main.enemies.size() + main.bosses.size()
	for k: Variant in data.keys():
		if int(data[k]) > 0:
			defeated_count += 1
	box.add_child(UIFactory.paragraph("已記錄 %d / %d 種敵將" % [defeated_count, total_count]))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(960, 480)
	box.add_child(scroll)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for enemy: EnemyData in main.enemies:
		grid.add_child(_tile(enemy, false, int(data.get(enemy.id, 0))))
	for boss: EnemyData in main.bosses:
		grid.add_child(_tile(boss, true, int(data.get(boss.id, 0))))

	var back: Button = main._button("返回主選單")
	back.pressed.connect(main.show_main_menu)
	box.add_child(back)
	return panel

func _tile(enemy: EnemyData, is_boss: bool, kill_count: int) -> Control:
	var defeated: bool = kill_count > 0
	var border: Color = ThemeColors.HIGHLIGHT_GOLD if is_boss else (ThemeColors.BORDER_GOLD if defeated else Color("5f6570", 0.5))
	var bg: Color = Color("18212f", 0.85) if defeated else Color("0d121b", 0.85)
	var tile: PanelContainer = PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UIFactory.style_box(bg, border, 2 if is_boss else 1, 8))
	tile.custom_minimum_size = Vector2(290, 220)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	tile.add_child(inner)
	var portrait: TextureRect = UIFactory.portrait_rect(enemy.portrait_path, Vector2(120, 96), true)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not defeated:
		portrait.modulate = Color(0.0, 0.0, 0.0, 0.85)
	inner.add_child(portrait)
	var name_label: Label = Label.new()
	name_label.text = enemy.display_name if defeated else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD if defeated else ThemeColors.TEXT_DIM)
	inner.add_child(name_label)
	if defeated:
		var stats: Label = Label.new()
		stats.text = "HP %d  ·  擊敗 %d 次%s" % [enemy.max_hp, kill_count, "  ·  Boss" if is_boss else ""]
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_theme_font_size_override("font_size", 12)
		stats.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		inner.add_child(stats)
		var intents: Array[String] = []
		for action: Dictionary in enemy.actions:
			intents.append(String(action.get("intent", "")))
		var intent_label: Label = Label.new()
		intent_label.text = "招式：%s" % "、".join(intents)
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intent_label.add_theme_font_size_override("font_size", 11)
		intent_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		intent_label.custom_minimum_size = Vector2(260, 0)
		inner.add_child(intent_label)
	else:
		var locked: Label = Label.new()
		locked.text = "尚未交手"
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.add_theme_font_size_override("font_size", 12)
		locked.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		inner.add_child(locked)
	return tile
