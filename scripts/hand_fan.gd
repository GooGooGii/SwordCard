class_name HandFan
extends Control

const ARC_RADIUS: float = 600.0
const MAX_TOTAL_ANGLE_DEG: float = 36.0
const ANGLE_PER_CARD_DEG: float = 7.0
const HOVER_LIFT: float = 28.0
const HOVER_SCALE: float = 1.12
const ANIM_DURATION: float = 0.12

var _card_buttons: Array[Button] = []
var _base_positions: Array[Vector2] = []
var _base_rotations: Array[float] = []
var _hovered_index: int = -1

func _ready() -> void:
	clip_contents = false
	resized.connect(_layout)

func set_cards(buttons: Array[Button]) -> void:
	for child: Node in get_children():
		child.queue_free()
	_card_buttons.clear()
	_base_positions.clear()
	_base_rotations.clear()
	_hovered_index = -1
	for i: int in range(buttons.size()):
		var button: Button = buttons[i]
		add_child(button)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx: int = i
		button.mouse_entered.connect(func() -> void: _on_hover(idx))
		button.mouse_exited.connect(func() -> void: _on_unhover(idx))
		_card_buttons.append(button)
	_layout()

func _layout() -> void:
	var n: int = _card_buttons.size()
	if n == 0:
		return
	var total_angle_deg: float = min(MAX_TOTAL_ANGLE_DEG, ANGLE_PER_CARD_DEG * max(1, n - 1))
	var w: float = size.x
	var h: float = size.y
	_base_positions.clear()
	_base_rotations.clear()
	for i: int in range(n):
		var button: Button = _card_buttons[i]
		var card_size: Vector2 = button.custom_minimum_size
		var t: float = 0.5 if n == 1 else float(i) / float(n - 1)
		var angle_deg: float = -total_angle_deg / 2.0 + total_angle_deg * t
		var angle_rad: float = deg_to_rad(angle_deg)
		button.size = card_size
		button.pivot_offset = Vector2(card_size.x / 2.0, card_size.y + ARC_RADIUS)
		var base_pos: Vector2 = Vector2(w / 2.0 - card_size.x / 2.0, h - card_size.y)
		button.position = base_pos
		button.rotation = angle_rad
		button.scale = Vector2.ONE
		button.z_index = i
		_base_positions.append(base_pos)
		_base_rotations.append(angle_rad)

func _on_hover(index: int) -> void:
	if index < 0 or index >= _card_buttons.size():
		return
	_hovered_index = index
	var button: Button = _card_buttons[index]
	button.z_index = 1000
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "rotation", 0.0, ANIM_DURATION)
	tween.tween_property(button, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), ANIM_DURATION)
	tween.tween_property(button, "position", _base_positions[index] + Vector2(0, -HOVER_LIFT), ANIM_DURATION)

func _on_unhover(index: int) -> void:
	if index < 0 or index >= _card_buttons.size():
		return
	if _hovered_index == index:
		_hovered_index = -1
	var button: Button = _card_buttons[index]
	button.z_index = index
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "rotation", _base_rotations[index], ANIM_DURATION)
	tween.tween_property(button, "scale", Vector2.ONE, ANIM_DURATION)
	tween.tween_property(button, "position", _base_positions[index], ANIM_DURATION)
