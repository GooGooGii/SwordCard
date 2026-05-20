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
		var color: Color = Color("e4c66a", 0.86) if active else Color("6f7b8d", 0.42)
		var width: float = 4.0 if active else 2.0
		draw_line(from_point, to_point, color, width, true)
		draw_circle(to_point, 4.0 if active else 3.0, color)
