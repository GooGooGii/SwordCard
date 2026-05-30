class_name DebugMenu
extends CanvasLayer

signal gold_bonus_requested
signal full_heal_requested
signal add_card_requested
signal add_relic_requested
signal add_potion_requested
signal jump_to_boss_requested
signal toggle_test_mode_requested
signal close_requested

var test_mode_enabled: bool = false
var _test_mode_button: Button = null

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func toggle() -> void:
	visible = not visible

func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(ThemeColors.OVERLAY_BG.r, ThemeColors.OVERLAY_BG.g, ThemeColors.OVERLAY_BG.b, 0.96)
	bg.border_color = ThemeColors.BORDER_GOLD
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(10)
	bg.content_margin_left = 20
	bg.content_margin_right = 20
	bg.content_margin_top = 16
	bg.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", bg)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UIFactory.title_label("Debug Menu", 22))
	_add_action(box, "+100 Gold", func() -> void: gold_bonus_requested.emit())
	_add_action(box, "Full Heal", func() -> void: full_heal_requested.emit())
	_add_action(box, "Add Random Card", func() -> void: add_card_requested.emit())
	_add_action(box, "Add Random Relic", func() -> void: add_relic_requested.emit())
	_add_action(box, "Add Random Potion", func() -> void: add_potion_requested.emit())
	_add_action(box, "Jump to Boss", func() -> void: jump_to_boss_requested.emit())
	_test_mode_button = _add_action(box, _test_mode_label(), func() -> void: toggle_test_mode_requested.emit())
	_add_action(box, "Close (F1)", func() -> void: close_requested.emit())

func set_test_mode(enabled: bool) -> void:
	test_mode_enabled = enabled
	if _test_mode_button != null:
		_test_mode_button.text = _test_mode_label()

func _test_mode_label() -> String:
	return "Test Mode: ON (任意點地圖)" if test_mode_enabled else "Test Mode: OFF"

func _add_action(parent: VBoxContainer, text: String, on_press: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
	btn.add_theme_stylebox_override("normal", UIFactory.style_box(ThemeColors.PANEL_NAVY, ThemeColors.BORDER_GOLD, 1, 6))
	btn.add_theme_stylebox_override("hover", UIFactory.style_box(ThemeColors.PANEL_NAVY_HOV, ThemeColors.ACCENT_GOLD, 2, 6))
	btn.add_theme_stylebox_override("pressed", UIFactory.style_box(ThemeColors.PANEL_NAVY_PRS, ThemeColors.BORDER_GOLD, 1, 6))
	btn.pressed.connect(on_press)
	parent.add_child(btn)
	return btn
