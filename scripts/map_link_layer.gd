class_name MapLinkLayer
extends Control

var segments: Array[Dictionary] = []

func set_segments(next_segments: Array[Dictionary]) -> void:
	segments = next_segments
	queue_redraw()

func _draw() -> void:
	# 路徑三態：已走過＝深墨實線（旅程的足跡）；可前往＝金色光徑；未來＝淡虛線。
	for segment: Dictionary in segments:
		var from_point: Vector2 = segment["from"]
		var to_point: Vector2 = segment["to"]
		var active: bool = bool(segment.get("active", false))
		var walked: bool = bool(segment.get("walked", false))
		if walked:
			var ink: Color = Color("2e3c49", 0.92)
			_draw_curved_segment(from_point, to_point, Color("2e3c49", 0.22), 6.0)
			_draw_curved_segment(from_point, to_point, ink, 3.6)
			draw_circle(to_point, 3.4, ink)
		elif active:
			var gold: Color = Color("ecd48a", 0.95)
			_draw_curved_segment(from_point, to_point, Color("fff4c7", 0.16), 9.0)
			_draw_curved_segment(from_point, to_point, Color("f6df9a", 0.30), 5.5)
			_draw_curved_segment(from_point, to_point, gold, 3.2)
			draw_circle(to_point, 3.2, gold)
		else:
			var faint: Color = Color("3c4a56", 0.42)
			_draw_dashed_curve(from_point, to_point, faint, 1.8)
			draw_circle(to_point, 1.8, faint)

func _draw_curved_segment(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	var points: PackedVector2Array = _curve_points(from_point, to_point)
	if points.size() < 2:
		return
	draw_polyline(points, color, width, true)

func _draw_dashed_curve(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	# 沿貝茲取樣點隔段畫線 → 自然的水墨點虛線
	var points: PackedVector2Array = _curve_points(from_point, to_point)
	for i: int in range(0, points.size() - 1, 2):
		draw_line(points[i], points[i + 1], color, width, true)

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
