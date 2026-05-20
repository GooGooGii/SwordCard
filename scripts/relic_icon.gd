class_name RelicIcon
extends Control

var relic: RelicData

func _ready() -> void:
	custom_minimum_size = Vector2(28, 28)
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_relic(r: RelicData) -> void:
	relic = r
	if relic != null:
		tooltip_text = "%s\n%s" % [relic.display_name, relic.description]
	queue_redraw()

func _draw() -> void:
	if relic == null:
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
	return Color("c8b46f")
