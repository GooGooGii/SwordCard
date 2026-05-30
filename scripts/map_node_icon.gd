class_name MapNodeIcon
extends Control

const COMPLETED_BRUSH_RING_TEXTURE: Texture2D = preload("res://assets/ui/map_node_completed_brush_ring.svg")
const COMPLETED_BRUSH_RING_TINT: Color = Color("1b2731", 0.94)

var node_type: String = "battle"
var icon_color: Color = ThemeColors.ACCENT_GOLD
var icon_texture: Texture2D
var highlighted: bool = false
var state_mode: String = "locked"

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_type(type: String, color: Color = ThemeColors.ACCENT_GOLD) -> void:
	node_type = type
	icon_color = color
	icon_texture = _load_node_texture(type)
	queue_redraw()

func set_highlight(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()

func set_visual_state(value: String) -> void:
	if state_mode == value:
		return
	state_mode = value
	queue_redraw()

func _draw() -> void:
	var s: float = min(size.x, size.y)
	var c: Vector2 = size / 2.0
	var core_radius: float = s * 0.34
	var ring_radius: float = s * 0.43
	# 2026-05 改版：未抵達(locked) 不再用暗灰圓盤蓋住 icon；可前往(selectable)/已選(selected)
	# 只用金光環提示，不蓋實心圓盤，讓原本的節點 icon 直接露出來。
	match state_mode:
		"completed":
			_draw_completed_brush_ring(c, s)
			draw_circle(c, core_radius + 4.0, Color("14202b", 0.10))
		"selected":
			draw_circle(c, ring_radius + 9.0, Color("f5d27a", 0.20))
			draw_circle(c, ring_radius + 3.0, Color("f7df9c", 0.26))
			draw_arc(c, ring_radius + 3.0, 0.0, TAU, 64, Color("ffe6a0", 0.96), 3.4, true)
		"selectable":
			draw_circle(c, ring_radius + 7.0, Color("f5d27a", 0.16))
			draw_circle(c, ring_radius + 2.0, Color("f7df9c", 0.20))
			draw_arc(c, ring_radius + 1.0, 0.0, TAU, 48, Color("f8d878", 0.78), 2.2, true)
		_:
			# locked / 其他：完全不畫底盤，只露出原本的 icon
			if highlighted:
				draw_arc(c, ring_radius + 0.5, 0.0, TAU, 48, Color("f8d878", 0.7), 1.8, true)
	if icon_texture != null:
		var draw_size: Vector2 = Vector2.ONE * (s * (0.64 if state_mode == "completed" else 0.82))
		var draw_pos: Vector2 = (size - draw_size) * 0.5
		draw_texture_rect(icon_texture, Rect2(draw_pos, draw_size), false)
		return
	match node_type:
		"battle":
			_draw_swords(c, s)
		"rest":
			_draw_campfire(c, s)
		"event":
			_draw_question(c, s)
		"shop":
			_draw_coin(c, s, Color("e4c66a"))
		"black_shop":
			_draw_coin(c, s, Color("c19a55"))
		"boss":
			_draw_skull(c, s)

func _load_node_texture(type: String) -> Texture2D:
	var texture_path: String = "res://assets/ui/node_%s.png" % type
	if ResourceLoader.exists(texture_path):
		return load(texture_path) as Texture2D
	return null

func _base_fill_color() -> Color:
	match state_mode:
		"selected":
			return Color("f0dfb2")
		"selectable":
			return Color("e4d3a4")
		"completed":
			return Color("96b79f")
		"locked":
			return Color("48525d")
		_:
			return Color("cfbe90")

func _base_ring_color() -> Color:
	match state_mode:
		"selected":
			return Color("f7df9c")
		"selectable":
			return Color("efe2b7")
		"completed":
			return Color("bfe5c4")
		"locked":
			return Color("6d7882", 0.7)
		_:
			return Color("c8b46f")

func _draw_completed_brush_ring(c: Vector2, s: float) -> void:
	if COMPLETED_BRUSH_RING_TEXTURE == null:
		return
	var ring_size: float = s * 1.42
	var ring_rect: Rect2 = Rect2(
		c - Vector2(ring_size * 0.5, ring_size * 0.5) + Vector2(-1.5, 2.0),
		Vector2.ONE * ring_size
	)
	var texture_size: Vector2 = COMPLETED_BRUSH_RING_TEXTURE.get_size()
	draw_texture_rect_region(
		COMPLETED_BRUSH_RING_TEXTURE,
		ring_rect,
		Rect2(Vector2.ZERO, texture_size),
		COMPLETED_BRUSH_RING_TINT
	)

func _draw_swords(c: Vector2, s: float) -> void:
	var r: float = s * 0.36
	var w: float = 3.0
	draw_line(c + Vector2(-r, -r), c + Vector2(r, r), icon_color, w, true)
	draw_line(c + Vector2(r, -r), c + Vector2(-r, r), icon_color, w, true)
	draw_circle(c + Vector2(-r, r), 4.0, icon_color)
	draw_circle(c + Vector2(r, r), 4.0, icon_color)

func _draw_campfire(c: Vector2, s: float) -> void:
	var r: float = s * 0.36
	var log_y: float = r * 0.7
	draw_line(c + Vector2(-r * 0.8, log_y), c + Vector2(r * 0.8, log_y + 4), Color("a06a3a"), 4.0, true)
	draw_line(c + Vector2(-r * 0.8, log_y + 4), c + Vector2(r * 0.8, log_y), Color("a06a3a"), 4.0, true)
	var flame_outer: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.55, log_y),
		c + Vector2(-r * 0.25, -r * 0.2),
		c + Vector2(0, -r * 0.9),
		c + Vector2(r * 0.25, -r * 0.2),
		c + Vector2(r * 0.55, log_y)
	])
	draw_colored_polygon(flame_outer, Color("f4a13a"))
	var flame_inner: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.25, log_y - 4),
		c + Vector2(0, -r * 0.5),
		c + Vector2(r * 0.25, log_y - 4)
	])
	draw_colored_polygon(flame_inner, Color("fce85f"))

func _draw_question(c: Vector2, s: float) -> void:
	var r: float = s * 0.32
	var arc_pts: PackedVector2Array = PackedVector2Array()
	var segments: int = 24
	for i: int in range(segments + 1):
		var a: float = -PI + (i / float(segments)) * PI
		arc_pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.7 - r * 0.25))
	draw_polyline(arc_pts, icon_color, 3.5, true)
	draw_line(c + Vector2(r, -r * 0.25), c + Vector2(0, r * 0.35), icon_color, 3.5, true)
	draw_circle(c + Vector2(0, r * 0.78), 4.0, icon_color)

func _draw_coin(c: Vector2, s: float, fill: Color) -> void:
	var r: float = s * 0.4
	draw_circle(c, r, fill)
	draw_arc(c, r, 0, TAU, 48, fill.darkened(0.45), 2.0, true)
	draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.55), fill.darkened(0.5), 2.0, true)
	draw_line(c + Vector2(-r * 0.55, 0), c + Vector2(r * 0.55, 0), fill.darkened(0.5), 2.0, true)
	draw_arc(c, r * 0.42, 0, TAU, 24, fill.darkened(0.5), 1.6, true)

func _draw_skull(c: Vector2, s: float) -> void:
	var r: float = s * 0.36
	draw_circle(c + Vector2(0, -r * 0.1), r, icon_color)
	var jaw_pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(-r * 0.55, r * 0.2),
		c + Vector2(-r * 0.4, r * 0.7),
		c + Vector2(r * 0.4, r * 0.7),
		c + Vector2(r * 0.55, r * 0.2)
	])
	draw_colored_polygon(jaw_pts, icon_color)
	draw_circle(c + Vector2(-r * 0.32, -r * 0.15), r * 0.2, Color("1a0e0e"))
	draw_circle(c + Vector2(r * 0.32, -r * 0.15), r * 0.2, Color("1a0e0e"))
	var nose: PackedVector2Array = PackedVector2Array([
		c + Vector2(0, r * 0.1),
		c + Vector2(-r * 0.1, r * 0.32),
		c + Vector2(r * 0.1, r * 0.32)
	])
	draw_colored_polygon(nose, Color("1a0e0e"))
	for i: int in range(4):
		var x: float = -r * 0.3 + i * (r * 0.2)
		draw_line(c + Vector2(x, r * 0.5), c + Vector2(x, r * 0.7), Color("1a0e0e"), 1.6, true)
