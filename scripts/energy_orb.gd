class_name EnergyOrb
extends Control

const CENTER_COLOR: Color = Color("9bd8ff")
const MID_COLOR: Color = Color("2f7fb8")
const EDGE_COLOR: Color = Color("17345a")
const BORDER_COLOR: Color = Color("8edcff")
const HIGHLIGHT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.42)
const BORDER_WIDTH: float = 3.0
const SEGMENTS: int = 64

var energy: int = 0
var max_energy: int = 3
var _label: Label
var _last_set_energy: int = -1  # 偵測 set_energy 增減以觸發 pulse；-1 = 首次
var _pulse_tween: Tween = null

func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color("f3faff"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh_label()

func set_energy(current: int, total: int) -> void:
	var prior: int = _last_set_energy
	_last_set_energy = current
	energy = current
	max_energy = total
	_refresh_label()
	# 第一次設定不觸發動畫（戰鬥開始 fade in 自己會做）
	if prior == -1 or prior == current:
		return
	_pulse(current > prior)

func _pulse(increased: bool) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	pivot_offset = size / 2.0
	var peak_scale: Vector2 = Vector2.ONE * (1.18 if increased else 1.10)
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(self, "scale", peak_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_delay(0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if increased:
		# 能量回滿 / 增加：cyan flash 強調獎勵
		modulate = Color(1.4, 1.4, 1.6)
		_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.30)

func _refresh_label() -> void:
	if _label != null:
		_label.text = "%d/%d" % [energy, max_energy]

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0 - BORDER_WIDTH / 2.0
	_draw_radial_fan(center, radius, CENTER_COLOR, EDGE_COLOR)
	var mid_radius: float = radius * 0.7
	_draw_radial_fan(center, mid_radius, CENTER_COLOR.lerp(MID_COLOR, 0.5), MID_COLOR)
	var highlight_center: Vector2 = center + Vector2(-radius * 0.32, -radius * 0.34)
	var highlight_radius: float = radius * 0.35
	_draw_radial_fan(highlight_center, highlight_radius, HIGHLIGHT_COLOR, Color(HIGHLIGHT_COLOR.r, HIGHLIGHT_COLOR.g, HIGHLIGHT_COLOR.b, 0.0))
	draw_arc(center, radius, 0.0, TAU, SEGMENTS, BORDER_COLOR, BORDER_WIDTH, true)

func _draw_radial_fan(center: Vector2, radius: float, inner: Color, outer: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	points.append(center)
	colors.append(inner)
	for i: int in range(SEGMENTS + 1):
		var a: float = i * TAU / SEGMENTS
		points.append(center + Vector2(cos(a), sin(a)) * radius)
		colors.append(outer)
	draw_polygon(points, colors)
