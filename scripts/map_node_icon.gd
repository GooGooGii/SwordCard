class_name MapNodeIcon
extends Control

var node_type: String = "battle"
var icon_color: Color = Color("f7df9c")

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_type(type: String, color: Color = Color("f7df9c")) -> void:
	node_type = type
	icon_color = color
	queue_redraw()

func _draw() -> void:
	var s: float = min(size.x, size.y)
	var c: Vector2 = size / 2.0
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
