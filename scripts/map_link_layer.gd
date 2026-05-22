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
		if active:
			_draw_dashed_segment(from_point, to_point, Color("f5f1d6", 0.28), 6.0, 10.0, 7.0)
		_draw_dashed_segment(from_point, to_point, color, width, 8.0 if active else 6.0, 8.0 if active else 7.0)
		draw_circle(to_point, 3.5 if active else 2.0, color)

# 直線虛線：從 from_point 直接到 to_point，不繞 Bezier
func _draw_dashed_segment(from_point: Vector2, to_point: Vector2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	var delta: Vector2 = to_point - from_point
	var length: float = delta.length()
	if length <= 0.0:
		return
	var direction: Vector2 = delta / length
	var cursor: float = 0.0
	while cursor < length:
		var dash_end: float = min(cursor + dash_length, length)
		draw_line(from_point + direction * cursor, from_point + direction * dash_end, color, width, true)
		cursor = dash_end + gap_length
