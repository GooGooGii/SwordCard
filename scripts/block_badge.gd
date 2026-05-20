class_name BlockBadge
extends Control

const FILL_COLOR: Color = Color("2a4567", 0.94)
const BORDER_COLOR: Color = Color("a8c4e8")
const TEXT_COLOR: Color = Color("e8f4ff")
const BORDER_WIDTH: float = 2.0

var amount: int = 0
var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.offset_top = 2
	_label.offset_bottom = -8
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_apply_amount()

func set_amount(value: int) -> void:
	amount = value
	_apply_amount()

func _apply_amount() -> void:
	visible = amount > 0
	if _label != null:
		_label.text = str(amount)
	queue_redraw()

func _draw() -> void:
	if amount <= 0:
		return
	var w: float = size.x
	var h: float = size.y
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(w * 0.12, h * 0.04),
		Vector2(w * 0.88, h * 0.04),
		Vector2(w * 0.88, h * 0.62),
		Vector2(w * 0.5, h * 0.96),
		Vector2(w * 0.12, h * 0.62)
	])
	draw_colored_polygon(pts, FILL_COLOR)
	var border: PackedVector2Array = pts.duplicate()
	border.append(pts[0])
	draw_polyline(border, BORDER_COLOR, BORDER_WIDTH, true)
