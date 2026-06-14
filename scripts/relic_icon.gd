class_name RelicIcon
extends Control

var relic: RelicData
# 切換用：戰鬥遺物帶建構時可注入「全部遺物清單 + 本顆索引」，
# 說明 popup 便能用左右白色三角鈕切換上一個 / 下一個遺物檢視（>1 件才顯示箭頭）。
var siblings: Array = []      # Array[RelicData]
var sibling_index: int = 0

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
	# 切換清單：有注入 siblings（戰鬥遺物帶）就能在全部遺物間切換，否則只有自己這顆。
	var list: Array = siblings if siblings.size() > 1 else [relic]
	var start_idx: int = clampi(sibling_index, 0, list.size() - 1) if siblings.size() > 1 else 0
	var popup: PopupPanel = PopupPanel.new()
	popup.exclusive = false
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color("13202c", 0.96)
	panel_style.border_color = _border_for(list[start_idx] as RelicData)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	popup.add_theme_stylebox_override("panel", panel_style)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	popup.add_child(content)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	_fill_info_popup(popup, content, list, start_idx)

# 就地重填 popup 內容；多件時左右各放一個「去背白色三角」切換鈕（畫面上只見白三角）。
func _fill_info_popup(popup: PopupPanel, content: VBoxContainer, list: Array, idx: int) -> void:
	for child: Node in content.get_children():
		child.queue_free()
	var cur: RelicData = list[idx] as RelicData
	var border: Color = _border_for(cur)
	(popup.get_theme_stylebox("panel") as StyleBoxFlat).border_color = border
	var multi: bool = list.size() > 1
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 12)
	title_row.custom_minimum_size = Vector2(300, 0)
	content.add_child(title_row)
	if multi:
		var prev_i: int = (idx - 1 + list.size()) % list.size()
		title_row.add_child(_nav_triangle("◀", func() -> void: _fill_info_popup(popup, content, list, prev_i)))
	var title_label: Label = Label.new()
	title_label.text = cur.display_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", border)
	title_row.add_child(title_label)
	if multi:
		var next_i: int = (idx + 1) % list.size()
		title_row.add_child(_nav_triangle("▶", func() -> void: _fill_info_popup(popup, content, list, next_i)))
	if multi:
		var counter: Label = Label.new()
		counter.text = "%d / %d" % [idx + 1, list.size()]
		counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counter.add_theme_font_size_override("font_size", 12)
		counter.add_theme_color_override("font_color", Color("9aa3b2"))
		content.add_child(counter)
	var desc_label: Label = Label.new()
	desc_label.text = cur.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color("e8e2c8"))
	content.add_child(desc_label)
	popup.reset_size()
	popup.popup_centered()

# 去背白色三角切換鈕：StyleBoxEmpty 三態 → 無方框、無底色，畫面上只見一個白色三角。
func _nav_triangle(glyph: String, on_press: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = glyph
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(34, 34)
	btn.add_theme_font_size_override("font_size", 22)
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_color_override("font_color", Color("ffffff"))
	btn.add_theme_color_override("font_hover_color", Color("ffe9b8"))
	btn.add_theme_color_override("font_pressed_color", Color("cfd6e2"))
	btn.pressed.connect(on_press)
	return btn

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
	return _border_for(relic)

func _border_for(r: RelicData) -> Color:
	if r == null:
		return ThemeColors.BORDER_GOLD
	match r.rarity:
		"uncommon":
			return Color("76c4d8")
		"rare":
			return Color("d9c2ff")
		"legendary":
			return Color("ffb84a")
	return ThemeColors.BORDER_GOLD
