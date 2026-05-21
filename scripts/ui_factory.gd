class_name UIFactory
extends RefCounted

static func style_box(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
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

static func strip_box(bg_color: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.set_corner_radius_all(radius)
	return box

static func make_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style_box(Color("18212f", 0.86), Color("536277"), 1, 8))
	panel.add_theme_constant_override("margin_left", 18)
	panel.add_theme_constant_override("margin_top", 18)
	panel.add_theme_constant_override("margin_right", 18)
	panel.add_theme_constant_override("margin_bottom", 18)
	return panel

static func title_label(text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	return label

static func paragraph(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	return label

static func style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", style_box(ThemeColors.PANEL_NAVY, Color("8ea3c4"), 1, 6))
	button.add_theme_stylebox_override("hover", style_box(Color("33435c"), Color("c3d3ee"), 2, 6))
	button.add_theme_stylebox_override("pressed", style_box(Color("1f2a3c"), Color("e4c66a"), 2, 6))
	button.add_theme_color_override("font_color", Color("edf2f7"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("f7e7a2"))

static func main_menu_button(text: String, emphasized: bool = false, min_height: float = 58.0, font_size: int = 20) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, min_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", font_size)
	var base: Color = Color("ede0b9", 0.92) if emphasized else Color("f3ede2", 0.9)
	var hover: Color = Color("f4e6bf", 0.98) if emphasized else Color("faf5ec", 0.96)
	var pressed: Color = Color("dbc58f", 0.98) if emphasized else Color("e7dece", 0.95)
	var border: Color = Color("d5bf8b", 0.75) if emphasized else Color("ddd1bf", 0.72)
	var font_color: Color = Color("2d2418") if emphasized else Color("253540")
	button.add_theme_stylebox_override("normal", style_box(base, border, 1, 999))
	button.add_theme_stylebox_override("hover", style_box(hover, border.lightened(0.06), 1, 999))
	button.add_theme_stylebox_override("pressed", style_box(pressed, border, 1, 999))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	return button

static func card_label(text: String, size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

static func feedback_label() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(260, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	label.modulate.a = 0.0
	return label

static func menu_chip(text: String) -> Control:
	var chip: PanelContainer = PanelContainer.new()
	chip.add_theme_stylebox_override("panel", style_box(Color("f4d985", 0.10), Color("f4d985", 0.34), 1, 999))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var label: Label = card_label(text, 13, Color("f7e7a2"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.add_child(label)
	return chip

static func menu_info_row(label_text: String, value_text: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style_box(Color("111926", 0.70), Color("61748f", 0.32), 1, 10))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(card_label(label_text, 13, Color("9fb0c8"), HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(card_label(value_text, 16, Color("edf2f7"), HORIZONTAL_ALIGNMENT_LEFT))
	return panel

static func portrait_rect(path: String, size: Vector2, show_full_image: bool = false) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if show_full_image else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = load_texture(path)
	if texture != null:
		rect.texture = texture
	return rect

static var _texture_cache: Dictionary = {}

static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path) as Texture2D
	_texture_cache[path] = tex
	return tex

static func hp_bar(fill_color: Color, bg_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 1
	var bg: StyleBoxFlat = style_box(bg_color, Color("1a1a1f"), 1, 4)
	var fill: StyleBoxFlat = style_box(fill_color, fill_color.lightened(0.25), 0, 4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

static func status_summary(poison: int, weak: int, vulnerable: int) -> String:
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

static func ignore_child_mouse(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		ignore_child_mouse(child)

static func shake_node(node: Control, intensity: float = 8.0, duration: float = 0.25) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = node.position
	var steps: int = 5
	var step_duration: float = duration / float(steps + 1)
	var tween: Tween = node.create_tween()
	for i: int in range(steps):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", orig_pos + offset, step_duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", orig_pos, step_duration)

static func dash_node(node: Control, direction: Vector2, distance: float = 36.0, duration: float = 0.24) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = node.position
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "position", orig_pos + direction.normalized() * distance, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", orig_pos, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

static func flash_node(node: Control, color: Color = Color(1.4, 1.4, 1.6), duration: float = 0.22) -> void:
	if node == null:
		return
	var orig_mod: Color = node.modulate
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.35)
	tween.tween_property(node, "modulate", orig_mod, duration * 0.65)
