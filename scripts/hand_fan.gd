class_name HandFan
extends Control

const ARC_RADIUS: float = 1600.0
const MAX_TOTAL_ANGLE_DEG: float = 28.0
const ANGLE_PER_CARD_DEG: float = 5.5
const HOVER_LIFT: float = 56.0
var hand_base_lift: float = 72.0
const HOVER_SCALE: float = 1.06
const ANIM_DURATION: float = 0.12
const DRAW_ANIM_DURATION: float = 0.18
const DRAW_ANIM_STAGGER: float = 0.015

var _card_buttons: Array[Button] = []
var _base_positions: Array[Vector2] = []
var _base_rotations: Array[float] = []
var _hovered_index: int = -1
var _draw_animation_id: int = 0
var _hover_tweens: Dictionary = {}
var _selected_index: int = -1

func _ready() -> void:
	clip_contents = false
	resized.connect(_layout)

func set_cards(buttons: Array[Button], animate: bool = false, animate_from: Vector2 = Vector2.ZERO) -> void:
	_draw_animation_id += 1
	for child: Node in get_children():
		child.queue_free()
	_card_buttons.clear()
	_base_positions.clear()
	_base_rotations.clear()
	_hovered_index = -1
	_selected_index = -1
	for tween: Tween in _hover_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_hover_tweens.clear()
	for i: int in range(buttons.size()):
		var button: Button = buttons[i]
		add_child(button)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx: int = i
		button.mouse_entered.connect(func() -> void: _on_hover(idx))
		button.mouse_exited.connect(func() -> void: _on_unhover(idx))
		button.button_down.connect(func() -> void: _on_hover(idx))
		button.button_up.connect(func() -> void: _on_unhover(idx))
		_card_buttons.append(button)
	if animate:
		for button: Button in _card_buttons:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.position = animate_from - global_position
			button.rotation = 0.0
			button.scale = Vector2(0.55, 0.55)
			button.modulate.a = 0.0
		call_deferred("_start_draw_animation", animate_from, _draw_animation_id)
		return
	_compute_base_layout()
	_apply_layout(false, Vector2.ZERO)

func set_selected_button(button: Button) -> void:
	_selected_index = -1
	if button != null:
		_selected_index = _card_buttons.find(button)
	_apply_layout(false, Vector2.ZERO)

func clear_selected_button() -> void:
	_selected_index = -1
	_apply_layout(false, Vector2.ZERO)

# 強制重新套用 layout（drag-to-play 沒打成功時用來 snap back）
func relayout() -> void:
	_apply_layout(false, Vector2.ZERO)

func _start_draw_animation(animate_from: Vector2, animation_id: int) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if animation_id != _draw_animation_id:
		return
	_compute_base_layout()
	_apply_layout(true, animate_from)

func _layout() -> void:
	_compute_base_layout()
	_apply_layout(false, Vector2.ZERO)

func _compute_base_layout() -> void:
	var n: int = _card_buttons.size()
	_base_positions.clear()
	_base_rotations.clear()
	if n == 0:
		return
	var total_angle_deg: float = min(MAX_TOTAL_ANGLE_DEG, ANGLE_PER_CARD_DEG * max(1, n - 1))
	var w: float = size.x
	var h: float = size.y
	for i: int in range(n):
		var button: Button = _card_buttons[i]
		var card_size: Vector2 = button.custom_minimum_size
		var t: float = 0.5 if n == 1 else float(i) / float(n - 1)
		var angle_deg: float = -total_angle_deg / 2.0 + total_angle_deg * t
		var angle_rad: float = deg_to_rad(angle_deg)
		var base_pos: Vector2 = Vector2(w / 2.0 - card_size.x / 2.0, h - card_size.y - hand_base_lift)
		_base_positions.append(base_pos)
		_base_rotations.append(angle_rad)

func _apply_layout(animate: bool, animate_from: Vector2) -> void:
	var n: int = _card_buttons.size()
	if n == 0:
		return
	var local_from: Vector2 = animate_from - global_position
	for i: int in range(n):
		var button: Button = _card_buttons[i]
		var card_size: Vector2 = button.custom_minimum_size
		button.size = card_size
		button.pivot_offset = Vector2(card_size.x / 2.0, card_size.y + ARC_RADIUS)
		button.z_index = 1100 if i == _selected_index else i
		if animate:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.position = local_from
			button.rotation = 0.0
			button.scale = Vector2(0.55, 0.55)
			button.modulate.a = 0.0
			var delay: float = i * DRAW_ANIM_STAGGER
			var target_button: Button = button
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(button, "position", _base_positions[i], DRAW_ANIM_DURATION).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(button, "rotation", _base_rotations[i], DRAW_ANIM_DURATION).set_delay(delay)
			tween.tween_property(button, "scale", Vector2.ONE, DRAW_ANIM_DURATION).set_delay(delay)
			tween.tween_property(button, "modulate:a", 1.0, DRAW_ANIM_DURATION * 0.85).set_delay(delay)
			tween.finished.connect(func() -> void:
				if is_instance_valid(target_button):
					target_button.mouse_filter = Control.MOUSE_FILTER_STOP)
		else:
			_apply_button_rest_state(button, i)

func _kill_hover_tween(index: int) -> void:
	if _hover_tweens.has(index):
		var existing: Tween = _hover_tweens[index]
		if existing != null and existing.is_valid():
			existing.kill()
		_hover_tweens.erase(index)

func _on_hover(index: int) -> void:
	if index < 0 or index >= _card_buttons.size():
		return
	if index == _selected_index:
		return
	_hovered_index = index
	var button: Button = _card_buttons[index]
	button.z_index = 1000
	_kill_hover_tween(index)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "rotation", _base_rotations[index], ANIM_DURATION)
	tween.tween_property(button, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), ANIM_DURATION)
	tween.tween_property(button, "position", _base_positions[index] + Vector2(0, -HOVER_LIFT), ANIM_DURATION)
	_hover_tweens[index] = tween

func _on_unhover(index: int) -> void:
	if index < 0 or index >= _card_buttons.size():
		return
	if index == _selected_index:
		return
	if _hovered_index == index:
		_hovered_index = -1
	var button: Button = _card_buttons[index]
	button.z_index = index
	_kill_hover_tween(index)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "rotation", _base_rotations[index], ANIM_DURATION)
	tween.tween_property(button, "scale", Vector2.ONE, ANIM_DURATION)
	tween.tween_property(button, "position", _base_positions[index], ANIM_DURATION)
	_hover_tweens[index] = tween

func _apply_button_rest_state(button: Button, index: int) -> void:
	if index == _selected_index:
		button.position = _base_positions[index] + Vector2(0, -HOVER_LIFT)
		button.rotation = _base_rotations[index]
		button.scale = Vector2(HOVER_SCALE, HOVER_SCALE)
		button.modulate.a = 1.0
		return
	button.position = _base_positions[index]
	button.rotation = _base_rotations[index]
	button.scale = Vector2.ONE
	button.modulate.a = 1.0
