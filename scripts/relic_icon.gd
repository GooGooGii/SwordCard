class_name RelicIcon
extends Control

var relic: RelicData

func _ready() -> void:
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func set_relic(r: RelicData) -> void:
	relic = r
	if relic != null:
		tooltip_text = "%s\n%s" % [relic.display_name, relic.description]
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if relic == null:
		return
	var tapped: bool = false
	if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		tapped = true
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			tapped = true
	if tapped:
		_show_info_popup()
		accept_event()

func _show_info_popup() -> void:
	var popup: PopupPanel = PopupPanel.new()
	popup.exclusive = false
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color("13202c", 0.96)
	panel_style.border_color = _rarity_border()
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	popup.add_theme_stylebox_override("panel", panel_style)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(300, 0)
	var title_label: Label = Label.new()
	title_label.text = relic.display_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", _rarity_border())
	box.add_child(title_label)
	var desc_label: Label = Label.new()
	desc_label.text = relic.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(280, 0)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color("e8e2c8"))
	box.add_child(desc_label)
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()

func _draw() -> void:
	if relic == null:
		return
	
	var art_path: String = "res://assets/art/relics/%s.png" % relic.id
	var texture: Texture2D = UIFactory.load_texture(art_path)
	if texture != null:
		# 直接畫遺物美術。稀有度顏色已由 panel_style border / title_label 表達，
		# 圖上不再疊圓圈（之前的 draw_arc 會擋住美術細節）。
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return

	var s: float = min(size.x, size.y)
	var c: Vector2 = size / 2.0
	var r: float = s * 0.42
	var border: Color = _rarity_border()
	match relic.icon_shape:
		"star":
			_draw_star(c, r, relic.icon_color, border)
		"hex":
			_draw_hex(c, r, relic.icon_color, border)
		"circle":
			draw_circle(c, r, relic.icon_color)
			draw_arc(c, r, 0, TAU, 32, border, 2.0, true)
		_:
			_draw_diamond(c, r, relic.icon_color, border)

func _draw_diamond(c: Vector2, r: float, fill: Color, border: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(0, -r),
		c + Vector2(r, 0),
		c + Vector2(0, r),
		c + Vector2(-r, 0)
	])
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, border, 2.0, true)

func _draw_hex(c: Vector2, r: float, fill: Color, border: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var a: float = i * TAU / 6.0 - PI / 6.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, fill)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, border, 2.0, true)

func _draw_star(c: Vector2, r: float, fill: Color, border: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var radius: float = r if i % 2 == 0 else r * 0.45
		var a: float = i * TAU / 10.0 - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(pts, fill)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, border, 1.6, true)

func _rarity_border() -> Color:
	match relic.rarity:
		"uncommon":
			return Color("76c4d8")
		"rare":
			return Color("d9c2ff")
		"legendary":
			return Color("ffb84a")
	return ThemeColors.BORDER_GOLD
