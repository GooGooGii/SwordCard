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
		var color: Color = Color("25313b", 0.88) if active else Color("46525d", 0.32)
		var width: float = 3.0 if active else 1.6
		var curve_points: PackedVector2Array = _curve_points(from_point, to_point)
		if active:
			_draw_dashed_curve(curve_points, Color("f5f1d6", 0.28), 6.0, 10.0, 7.0)
		_draw_dashed_curve(curve_points, color, width, 8.0 if active else 6.0, 8.0 if active else 7.0)
		draw_circle(to_point, 3.5 if active else 2.0, color)

func _curve_points(from_point: Vector2, to_point: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var delta: Vector2 = to_point - from_point
	var horizontal: float = delta.x
	var vertical: float = delta.y
	var curve_strength: float = clamp(abs(horizontal) * 0.28 + abs(vertical) * 0.08 + 34.0, 34.0, 110.0)
	var bend_dir: float = -1.0 if horizontal >= 0.0 else 1.0
	var switchback_dir: float = -bend_dir if abs(horizontal) > 24.0 else bend_dir
	var control_1: Vector2 = from_point + Vector2(horizontal * 0.08 + curve_strength * bend_dir, vertical * 0.24)
	var control_2: Vector2 = from_point + Vector2(horizontal * 0.92 + curve_strength * switchback_dir, vertical * 0.76)
	var steps: int = 28
	for i: int in range(steps + 1):
		var t: float = i / float(steps)
		points.append(_cubic_bezier(from_point, control_1, control_2, to_point, t))
	return points

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var omt: float = 1.0 - t
	return omt * omt * omt * p0 + 3.0 * omt * omt * t * p1 + 3.0 * omt * t * t * p2 + t * t * t * p3

func _draw_dashed_curve(points: PackedVector2Array, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	if points.size() < 2:
		return
	var drawing_dash: bool = true
	var remaining: float = dash_length
	for i: int in range(points.size() - 1):
		var segment_start: Vector2 = points[i]
		var segment_end: Vector2 = points[i + 1]
		var delta: Vector2 = segment_end - segment_start
		var length: float = delta.length()
		if length <= 0.0:
			continue
		var direction: Vector2 = delta / length
		var cursor: float = 0.0
		while cursor < length:
			var step: float = min(remaining, length - cursor)
			if drawing_dash:
				draw_line(segment_start + direction * cursor, segment_start + direction * (cursor + step), color, width, true)
			cursor += step
			remaining -= step
			if remaining <= 0.0:
				drawing_dash = not drawing_dash
				remaining = dash_length if drawing_dash else gap_length
