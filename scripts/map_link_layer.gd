class_name MapLinkLayer
extends Control

var segments: Array[Dictionary] = []

func set_segments(next_segments: Array[Dictionary]) -> void:
	segments = next_segments
	queue_redraw()

func _draw() -> void:
	for segment: Dictionary in segments:
		var from_point: Vector2 = segment["from"]
		var to_point: Vector2 = segment["to"]
		var active: bool = bool(segment.get("active", false))
		var color: Color = Color("ecd48a", 0.9) if active else Color("46525d", 0.26)
		var width: float = 3.0 if active else 1.6
		if active:
			_draw_curved_segment(from_point, to_point, Color("fff4c7", 0.14), 8.0)
			_draw_curved_segment(from_point, to_point, Color("f6df9a", 0.26), 5.0)
		_draw_curved_segment(from_point, to_point, color, width)
		draw_circle(to_point, 3.2 if active else 1.8, color)

func _draw_curved_segment(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	var points: PackedVector2Array = _curve_points(from_point, to_point)
	if points.size() < 2:
		return
	draw_polyline(points, color, width, true)

func _curve_points(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var delta: Vector2 = to_point - from_point
	if delta.length() <= 0.0:
		points.append(from_point)
		points.append(to_point)
		return points
	var curve_strength: float = clamp(abs(delta.x) * 0.16, 18.0, 56.0)
	var control_a: Vector2 = from_point + Vector2(delta.x * 0.18, -curve_strength)
	var control_b: Vector2 = to_point - Vector2(delta.x * 0.18, -curve_strength)
	var steps: int = 20
	for step: int in range(steps + 1):
		var t: float = step / float(steps)
		points.append(_cubic_bezier(from_point, control_a, control_b, to_point, t))
	return points

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var omt: float = 1.0 - t
	return (
		p0 * omt * omt * omt
		+ p1 * 3.0 * omt * omt * t
		+ p2 * 3.0 * omt * t * t
		+ p3 * t * t * t
	)
