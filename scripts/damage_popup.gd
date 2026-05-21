class_name DamagePopup
extends Label

const RISE_DISTANCE: float = 64.0
const DURATION: float = 0.65
const FONT_SIZE_DAMAGE: int = 38
const FONT_SIZE_NUMBER: int = 28

# kind: "damage" | "heal" | "block" | "poison"
static func spawn(parent: CanvasItem, world_pos: Vector2, amount: int, kind: String) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	if amount <= 0:
		return
	var popup: DamagePopup = DamagePopup.new()
	popup._configure(amount, kind)
	popup.global_position = world_pos
	popup.z_index = 500
	parent.add_child(popup)
	popup._play()

func _configure(amount: int, kind: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pivot_offset = Vector2(40, 20)
	match kind:
		"damage":
			text = "-%d" % amount
			add_theme_color_override("font_color", Color("ff5040"))
			add_theme_color_override("font_outline_color", Color("2a0606"))
			add_theme_font_size_override("font_size", FONT_SIZE_DAMAGE)
		"heal":
			text = "+%d" % amount
			add_theme_color_override("font_color", Color("6ee06a"))
			add_theme_color_override("font_outline_color", Color("0a2a0a"))
			add_theme_font_size_override("font_size", FONT_SIZE_NUMBER)
		"block":
			text = "+%d" % amount
			add_theme_color_override("font_color", Color("a8c4e8"))
			add_theme_color_override("font_outline_color", Color("0a1a30"))
			add_theme_font_size_override("font_size", FONT_SIZE_NUMBER)
		"poison":
			text = "蠱 -%d" % amount
			add_theme_color_override("font_color", Color("8fd07a"))
			add_theme_color_override("font_outline_color", Color("1a2a0a"))
			add_theme_font_size_override("font_size", FONT_SIZE_NUMBER)
		_:
			text = "%d" % amount
			add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
			add_theme_font_size_override("font_size", FONT_SIZE_NUMBER)
	add_theme_constant_override("outline_size", 6)

func _play() -> void:
	scale = Vector2(0.7, 0.7)
	modulate.a = 0.0
	var start_pos: Vector2 = position
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.10)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_delay(0.16)
	tween.tween_property(self, "position", start_pos + Vector2(0, -RISE_DISTANCE), DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION * 0.45).set_delay(DURATION * 0.55)
	tween.finished.connect(queue_free)
