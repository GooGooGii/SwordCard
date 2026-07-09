class_name RelicIcon
extends Control

var relic: RelicData
# 切換用：戰鬥遺物帶建構時可注入「全部遺物清單 + 本顆索引」，
# 說明 popup 便能用左右白色三角鈕切換上一個 / 下一個遺物檢視（>1 件才顯示箭頭）。
var siblings: Array = []      # Array[RelicData]
var sibling_index: int = 0

func _ready() -> void:
	# 預設 28×28（戰鬥遺物帶），但呼叫端建構時若已明確給更大尺寸（商店 80、彈窗 120）不要覆寫——
	# _ready 在整棵樹進場景時才觸發，會晚於建構期的賦值
	if custom_minimum_size == Vector2.ZERO:
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
	# 用 overlay + CenterContainer + PanelContainer（與藥品彈窗同結構）：面板緊貼內容、
	# 不會像 PopupPanel 被撐成正方形而下半留白。點背景關閉。
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 300
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.07, 0.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed) \
				or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			overlay.queue_free())
	overlay.add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	var panel_sb: StyleBoxFlat = StyleBoxFlat.new()
	panel_sb.bg_color = Color("13202c", 0.97)
	panel_sb.border_color = _border_for(list[start_idx] as RelicData)
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(12)
	panel_sb.content_margin_left = 24
	panel_sb.content_margin_right = 24
	panel_sb.content_margin_top = 18
	panel_sb.content_margin_bottom = 18
	panel_sb.shadow_color = Color("000000", 0.5)
	panel_sb.shadow_size = 10
	panel_sb.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", panel_sb)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(content)
	get_viewport().add_child(overlay)
	_fill_info_popup(panel, content, list, start_idx)

# 就地重填面板內容；多件時左右各放一個「去背白色三角」切換鈕（畫面上只見白三角）。
func _fill_info_popup(panel: PanelContainer, content: VBoxContainer, list: Array, idx: int) -> void:
	for child: Node in content.get_children():
		child.queue_free()
	var cur: RelicData = list[idx] as RelicData
	var border: Color = _border_for(cur)
	(panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color = border
	var multi: bool = list.size() > 1
	# ── 標題：名稱置中（切換三角移到下方遺物圖左右；與藥品彈窗一致）──
	var title_label: Label = UIFactory.title_label(cur.display_name, 26)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", border)
	content.add_child(title_label)
	# ── 稀有度膠囊 +（多件）計數 ──
	var meta_row: HBoxContainer = HBoxContainer.new()
	meta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_row.add_theme_constant_override("separation", 10)
	content.add_child(meta_row)
	var rar: String = cur.rarity if not cur.rarity.is_empty() else "common"
	var pill: PanelContainer = PanelContainer.new()
	var pill_sb: StyleBoxFlat = UIFactory.style_box(Color(border.r, border.g, border.b, 0.18), Color(border.r, border.g, border.b, 0.5), 1, 999)
	pill_sb.content_margin_left = 12
	pill_sb.content_margin_right = 12
	pill_sb.content_margin_top = 2
	pill_sb.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", pill_sb)
	var pill_lbl: Label = Label.new()
	pill_lbl.text = "%s 遺物" % rar.capitalize()
	pill_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill_lbl.add_theme_font_size_override("font_size", 12)
	pill_lbl.add_theme_color_override("font_color", border)
	pill.add_child(pill_lbl)
	meta_row.add_child(pill)
	if multi:
		var counter: Label = Label.new()
		counter.text = "%d / %d" % [idx + 1, list.size()]
		counter.autowrap_mode = TextServer.AUTOWRAP_OFF
		counter.add_theme_font_size_override("font_size", 12)
		counter.add_theme_color_override("font_color", Color("9aa3b2"))
		meta_row.add_child(counter)
	# ── 主視覺：◀ 遺物圖 ▶ — 切換三角放在圖的左右兩側 ──
	var hero_row: HBoxContainer = HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 18)
	content.add_child(hero_row)
	if multi:
		var prev_i: int = (idx - 1 + list.size()) % list.size()
		hero_row.add_child(_nav_triangle("◀", func() -> void: _fill_info_popup(panel, content, list, prev_i)))
	var hero_icon: RelicIcon = RelicIcon.new()
	hero_row.add_child(hero_icon)
	hero_icon.custom_minimum_size = Vector2(120, 120)
	hero_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_icon.set_relic(cur)
	if multi:
		var next_i: int = (idx + 1) % list.size()
		hero_row.add_child(_nav_triangle("▶", func() -> void: _fill_info_popup(panel, content, list, next_i)))
	# ── 描述：嵌入暗底卷軸框 ──
	var desc_panel: PanelContainer = PanelContainer.new()
	var desc_sb: StyleBoxFlat = UIFactory.style_box(Color("0d141d", 0.66), Color(border.r, border.g, border.b, 0.28), 1, 10)
	desc_sb.content_margin_left = 16
	desc_sb.content_margin_right = 16
	desc_sb.content_margin_top = 10
	desc_sb.content_margin_bottom = 10
	desc_panel.add_theme_stylebox_override("panel", desc_sb)
	content.add_child(desc_panel)
	var desc_label: Label = Label.new()
	desc_label.text = cur.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(320, 0)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color("e8e2c8"))
	desc_panel.add_child(desc_label)

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
