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
	# 水墨風：較深的宣紙底、暖金邊、柔和投影 → 面板像浮在卷上的紙片
	var sb: StyleBoxFlat = style_box(Color("141b27", 0.90), Color("c8b46f", 0.42), 1, 12)
	sb.shadow_color = Color("000000", 0.40)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", sb)
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
	# 墨色描邊：標題像毛筆字、在繁雜背景上更清晰、更有書法質感
	label.add_theme_color_override("font_outline_color", Color("17110a", 0.92))
	label.add_theme_constant_override("outline_size", max(3, int(size * 0.12)))
	return label

# 水墨風分隔線：中央菱紋 ❖ 兩側金線（純 Control，無需美術）。screen 標題下方可放一條。
static func ink_divider(thickness: int = 2) -> Control:
	var brush_texture: Texture2D = load_texture("res://assets/art/ui/brush_divider.png")
	if brush_texture != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = brush_texture
		rect.custom_minimum_size = Vector2(0, max(18, thickness * 12))
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	row.add_child(_ink_rule(thickness))
	var gem: Label = card_label("❖", 14, ThemeColors.BORDER_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	gem.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(gem)
	row.add_child(_ink_rule(thickness))
	return row

static func _ink_rule(thickness: int) -> Control:
	var p: PanelContainer = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.custom_minimum_size = Vector2(0, thickness)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("c8b46f", 0.45)
	sb.set_corner_radius_all(thickness)
	p.add_theme_stylebox_override("panel", sb)
	return p

# 水墨風段落標題：標題 + 下方分隔線（VBox）。給內嵌建構的標題用（不影響 _title 的 Label 型別）。
static func section_header(text: String, size: int) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(title_label(text, size))
	box.add_child(ink_divider())
	return box

static func paragraph(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	return label

static func style_button(button: Button) -> void:
	# 水墨風：墨藍底、暖金邊，hover 提亮鍍金、pressed 沉色描金 → 取代原本偏冷的藍灰
	button.add_theme_stylebox_override("normal", style_box(Color("1d2735", 0.95), Color("b89e63", 0.62), 1, 7))
	button.add_theme_stylebox_override("hover", style_box(Color("2a3850", 0.97), ThemeColors.ACCENT_GOLD, 1, 7))
	button.add_theme_stylebox_override("pressed", style_box(Color("141d2a", 0.98), ThemeColors.BORDER_GOLD, 2, 7))
	button.add_theme_color_override("font_color", Color("ecdfc2"))
	button.add_theme_color_override("font_hover_color", Color("fff3cf"))
	button.add_theme_color_override("font_pressed_color", ThemeColors.HIGHLIGHT_GOLD)

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

# 戰鬥肖像「底部對齊地面線」：把肖像保持比例縮放後，水平置中、底部貼齊框底，
# 讓四角色與敵人站在同一條地面線（解決不同比例原圖造成的高度漂移）。
# rect 須先 set_meta("ground_box", Vector2)；換 texture（換姿勢/變身）後重呼叫即可。
static func ground_portrait(rect: TextureRect) -> void:
	if rect == null or not rect.has_meta("ground_box"):
		return
	var box: Vector2 = rect.get_meta("ground_box")
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE  # 已自算尺寸吻合比例，不會變形
	# 解除 portrait_rect 設的 custom_minimum_size 鉗制，否則「比例縮放後較短的那一邊」
	# 會被最小尺寸頂回 box，導致圖被拉伸、底部對齊也跟著失準（不同比例原圖飄移程度不同）。
	rect.custom_minimum_size = Vector2.ZERO
	var tex: Texture2D = rect.texture
	if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
		rect.position = Vector2.ZERO
		rect.size = box
		return
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	# 依「內容外框」(去除四周透明留白) 而非整張畫布來縮放，讓不同留白比例 / 正方畫布的
	# 人物都能填滿 box（解決「正方圖被寬邊鉗死、用不到框高 → 顯得特別小」的問題）。
	# get_image() 在壓縮貼圖上可能取不到 → fallback 用整張圖。
	var content_left: float = 0.0
	var content_w: float = tw
	var content_h: float = th
	var content_bottom: float = th
	var src_img: Image = tex.get_image()
	if src_img != null:
		var used: Rect2i = src_img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			content_left = float(used.position.x)
			content_w = float(used.size.x)
			content_h = float(used.size.y)
			content_bottom = float(used.position.y + used.size.y)
	var s: float = min(box.x / content_w, box.y / content_h)
	rect.size = Vector2(tw * s, th * s)  # 整張貼圖縮放後尺寸（透明邊會超出 box，無妨）
	# 內容水平置中 + 內容底部對齊地面線
	var content_center_x: float = content_left + content_w * 0.5
	rect.position = Vector2(box.x * 0.5 - content_center_x * s, box.y - content_bottom * s)

# ── 狀態 chips（BATTLE_UI_POLISH Phase B3）────────────────────────────────
# 取代直書文字狀態列：圓底色塊＋符號＋數字，橫排一眼可掃。純程式繪製、無需美術。
const STATUS_CHIP_DEFS: Dictionary = {
	"power":      {"symbol": "攻", "color": Color("c8a23c")},
	"poison":     {"symbol": "毒", "color": Color("4e7d46")},
	"weak":       {"symbol": "弱", "color": Color("4a6c9b")},
	"vulnerable": {"symbol": "破", "color": Color("b06a3a")},
	"stun":       {"symbol": "暈", "color": Color("7b5ea7")},
	"silence":    {"symbol": "禁", "color": Color("6d5a8e")},
	"berserk":    {"symbol": "狂", "color": Color("a04545")},
	"thorns":     {"symbol": "刺", "color": Color("8a7a4d")},
	"artifact":   {"symbol": "咒", "color": Color("c9a86a")},
}

static func status_chip(kind: String, value: int, chip_px: float = 24.0) -> Control:
	var define: Dictionary = STATUS_CHIP_DEFS.get(kind, {"symbol": "?", "color": Color("777777")}) as Dictionary
	var col: Color = define["color"]
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(chip_px + 10, chip_px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_circle(Vector2(chip_px * 0.5, chip_px * 0.5), chip_px * 0.5, Color(col.r, col.g, col.b, 0.92))
		c.draw_circle(Vector2(chip_px * 0.5, chip_px * 0.5), chip_px * 0.5, Color(0, 0, 0, 0.45), false, 1.5))
	var sym: Label = card_label(String(define["symbol"]), int(chip_px * 0.55), Color("fff4dc"), HORIZONTAL_ALIGNMENT_CENTER)
	sym.autowrap_mode = TextServer.AUTOWRAP_OFF  # 窄框下 card_label 預設 wrap 會逐字直書
	sym.size = Vector2(chip_px, chip_px)
	sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	sym.add_theme_constant_override("outline_size", 2)
	sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(sym)
	var num_text: String = ("%+d" % value) if kind == "power" else str(value)
	var num: Label = card_label(num_text, int(chip_px * 0.6), Color("ffe9b0"), HORIZONTAL_ALIGNMENT_LEFT)
	num.autowrap_mode = TextServer.AUTOWRAP_OFF  # 「+5」兩字元曾被 wrap 拆行
	num.position = Vector2(chip_px + 1, chip_px * 0.12)
	num.size = Vector2(chip_px, chip_px)
	num.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	num.add_theme_constant_override("outline_size", 3)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(num)
	# chip 總寬涵蓋數字（含 +N 兩三字元），避免溢出蓋到下一顆
	c.custom_minimum_size = Vector2(chip_px + 8 + num_text.length() * chip_px * 0.38, chip_px)
	return c

# 重填一整排 chips。stats = [{"kind": "poison", "value": 3}, ...]，value 0 的自動略過。
static func fill_status_chips(row: HBoxContainer, stats: Array, chip_px: float = 24.0) -> void:
	if row == null or not is_instance_valid(row):
		return
	for child: Node in row.get_children():
		child.queue_free()
	for s_v: Variant in stats:
		var s: Dictionary = s_v as Dictionary
		if int(s.get("value", 0)) == 0:
			continue
		row.add_child(status_chip(String(s.get("kind", "")), int(s["value"]), chip_px))

static func status_chip_row(chip_px: float = 24.0) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(0, chip_px)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row

# 戰鬥單位腳底橢圓陰影（BATTLE_UI_POLISH Phase A1）：純程式繪製、無需美術。
# width = 陰影寬（建議 portrait box 寬 ×0.55）。掛在 portrait 同 wrap、底部貼地面線；
# 飄浮系（floats=true）→ 陰影縮小 70%、更淡（「人浮影留地」語法）。
static func ground_shadow(width: float, floats: bool = false) -> Control:
	var w: float = width * (0.7 if floats else 1.0)
	var h: float = w * 0.22
	var alpha: float = 0.20 if floats else 0.30
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		var pts: PackedVector2Array = PackedVector2Array()
		var center: Vector2 = Vector2(w * 0.5, h * 0.5)
		for i: int in range(48):
			var a: float = TAU * float(i) / 48.0
			pts.append(center + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.5))
		c.draw_colored_polygon(pts, Color(0, 0, 0, alpha)))
	return c

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

static func hp_bar(fill_color: Color, _bg_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 1
	
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color("0d1420") # 深層沉穩暗夜藍
	bg.border_color = Color("233145", 0.8) # 藍灰精緻微光邊緣
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(999) # 現代扁平化膠囊設計
	
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	# 高光頂邊線，塑造微光立體感
	fill.border_color = Color("ffffff", 0.25)
	fill.border_width_top = 1
	fill.set_corner_radius_all(999)
	# 邊緣發光（陰影）特效，提升科幻/仙俠奇幻質感
	fill.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.32)
	fill.shadow_size = 4
	
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

# 位移類動畫（shake / dash）共用的「先 kill 舊 tween 並還原真正原點」前處理，
# 避免同節點重複觸發時把「位移中的位置」誤當成原點 → 動畫結束回不到原位。
static func _reset_pos_fx(node: Control) -> Vector2:
	# 只有在「殺掉仍在跑的 fx tween」時才用 meta 還原。fx 早已結束的話，父容器可能
	# 已經重排（意圖字增減會改 col 最小高度 → 子節點 local y 變），無條件還原過期
	# 座標會把節點釘回舊高度、直到下次重排才跳回——實機「敵人位置忽高忽低」的來源。
	if node.has_meta("_fx_pos_tween"):
		var prev: Variant = node.get_meta("_fx_pos_tween")
		if prev is Tween and (prev as Tween).is_valid():
			(prev as Tween).kill()
			if node.has_meta("_fx_pos_rest"):
				node.position = node.get_meta("_fx_pos_rest")
	var rest: Vector2 = node.position
	node.set_meta("_fx_pos_rest", rest)
	return rest

static func _end_pos_fx(node: Control) -> void:
	# fx 收尾：位置主導權交還父容器——重排一次，把節點放回容器當下認定的正確位置
	# （fx 進行中若發生過重排，tween 的還原終點是過期座標，這裡校正）。
	if node == null or not is_instance_valid(node):
		return
	var parent: Node = node.get_parent()
	if parent is Container:
		(parent as Container).queue_sort()

static func shake_node(node: Control, intensity: float = 8.0, duration: float = 0.25) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = _reset_pos_fx(node)
	var steps: int = 5
	var step_duration: float = duration / float(steps + 1)
	var tween: Tween = node.create_tween()
	for i: int in range(steps):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", orig_pos + offset, step_duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", orig_pos, step_duration)
	tween.tween_callback(_end_pos_fx.bind(node))
	node.set_meta("_fx_pos_tween", tween)

static func dash_node(node: Control, direction: Vector2, distance: float = 36.0, duration: float = 0.24) -> void:
	if node == null:
		return
	var orig_pos: Vector2 = _reset_pos_fx(node)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "position", orig_pos + direction.normalized() * distance, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", orig_pos, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_end_pos_fx.bind(node))
	node.set_meta("_fx_pos_tween", tween)

static func flash_node(node: Control, color: Color = Color(1.4, 1.4, 1.6), duration: float = 0.22) -> void:
	if node == null:
		return
	# 同節點上一個 flash 還沒結束時，先 kill 並還原 modulate 原值，避免把「閃光中
	# 的亮色」當成原值 → 節點卡在亮色回不來。
	if node.has_meta("_fx_mod_tween"):
		var prev: Variant = node.get_meta("_fx_mod_tween")
		if prev is Tween and (prev as Tween).is_valid():
			(prev as Tween).kill()
		if node.has_meta("_fx_mod_rest"):
			node.modulate = node.get_meta("_fx_mod_rest")
	var orig_mod: Color = node.modulate
	node.set_meta("_fx_mod_rest", orig_mod)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.35)
	tween.tween_property(node, "modulate", orig_mod, duration * 0.65)
	node.set_meta("_fx_mod_tween", tween)
