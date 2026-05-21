class_name PauseMenu
extends CanvasLayer

signal resume_requested
signal abandon_requested
signal quit_requested

var _root_panel: PanelContainer
var _main_box: VBoxContainer
var _settings_box: VBoxContainer
var _is_settings_visible: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func open() -> void:
	visible = true
	_show_main()
	get_tree().paused = true

func close() -> void:
	visible = false
	_is_settings_visible = false
	get_tree().paused = false

func handle_back() -> bool:
	if not visible:
		return false
	if _is_settings_visible:
		_show_main()
		return true
	resume_requested.emit()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			if _is_settings_visible:
				_show_main()
			else:
				resume_requested.emit()
			get_viewport().set_input_as_handled()

func _build() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.62)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_root_panel = PanelContainer.new()
	_root_panel.custom_minimum_size = Vector2(420, 380)
	var box_style: StyleBoxFlat = StyleBoxFlat.new()
	box_style.bg_color = Color("13202c", 0.96)
	box_style.border_color = Color("c8b46f")
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(10)
	box_style.content_margin_left = 24
	box_style.content_margin_right = 24
	box_style.content_margin_top = 20
	box_style.content_margin_bottom = 20
	_root_panel.add_theme_stylebox_override("panel", box_style)
	center.add_child(_root_panel)
	_main_box = _build_main_panel()
	_settings_box = _build_settings_panel()
	_root_panel.add_child(_main_box)
	_root_panel.add_child(_settings_box)
	_settings_box.visible = false

func _show_main() -> void:
	_main_box.visible = true
	_settings_box.visible = false
	_is_settings_visible = false

func _show_settings() -> void:
	_main_box.visible = false
	_settings_box.visible = true
	_is_settings_visible = true

func _build_main_panel() -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_title_label("暫停"))
	var resume: Button = _menu_button("繼續")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	box.add_child(resume)
	var settings: Button = _menu_button("設定")
	settings.pressed.connect(_show_settings)
	box.add_child(settings)
	var abandon: Button = _menu_button("放棄冒險")
	abandon.pressed.connect(func() -> void: abandon_requested.emit())
	box.add_child(abandon)
	var quit_button: Button = _menu_button("退出遊戲")
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	box.add_child(quit_button)
	return box

func _build_settings_panel() -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_title_label("設定"))
	box.add_child(_volume_row("主音量", SettingsManager.master_volume, func(v: float) -> void:
		SettingsManager.master_volume = v
		SettingsManager.apply_runtime()
		SettingsManager.save_settings()))
	box.add_child(_volume_row("音樂", SettingsManager.music_volume, func(v: float) -> void:
		SettingsManager.music_volume = v
		SettingsManager.apply_runtime()
		SettingsManager.save_settings()))
	box.add_child(_volume_row("音效", SettingsManager.sfx_volume, func(v: float) -> void:
		SettingsManager.sfx_volume = v
		SettingsManager.apply_runtime()
		SettingsManager.save_settings()))
	if not OS.has_feature("mobile"):
		var fs_check: CheckButton = CheckButton.new()
		fs_check.text = "全螢幕"
		fs_check.button_pressed = SettingsManager.fullscreen
		fs_check.add_theme_font_size_override("font_size", 16)
		fs_check.add_theme_color_override("font_color", Color("e8e2c8"))
		fs_check.toggled.connect(func(toggled: bool) -> void:
			SettingsManager.fullscreen = toggled
			SettingsManager.apply_runtime()
			SettingsManager.save_settings())
		box.add_child(fs_check)
	var back: Button = _menu_button("返回")
	back.pressed.connect(_show_main)
	box.add_child(back)
	return box

func _volume_row(label_text: String, value: float, on_change: Callable) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(72, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("e8e2c8"))
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value
	slider.custom_minimum_size = Vector2(180, 24)
	row.add_child(slider)
	var value_label: Label = Label.new()
	value_label.text = "%d" % int(value)
	value_label.custom_minimum_size = Vector2(36, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", Color("c8b46f"))
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = "%d" % int(v)
		on_change.call(v))
	return row

func _menu_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 44)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color("fff8dc"))
	btn.add_theme_color_override("font_hover_color", Color("ffffff"))
	var normal: StyleBoxFlat = _stylebox(Color("273449"), Color("c8b46f"), 2)
	var hover: StyleBoxFlat = _stylebox(Color("324663"), Color("f7df9c"), 3)
	var pressed: StyleBoxFlat = _stylebox(Color("1c2737"), Color("c8b46f"), 2)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn

func _stylebox(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	return s

func _title_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("f7df9c"))
	return label
