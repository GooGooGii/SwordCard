extends Control

const BATTLE_END_DELAY: float = 0.8

var characters: Array[CharacterData] = []
var enemies: Array[EnemyData] = []
var bosses: Array[EnemyData] = []
var selected_character: CharacterData
var run_state: RunState = RunState.new()
var battle: BattleController
var root: MarginContainer
var background_rect: TextureRect
var hand_row: HandFan
var _battle_compact: bool = false
var log_label: RichTextLabel
var status_label: Label
var enemy_label: Label
var player_feedback_label: Label
var enemy_feedback_label: Label
var end_turn_button: Button
var player_hp_bar: ProgressBar
var player_hp_value: Label
var player_status_line: Label
var player_name_label: Label
var player_block_badge: BlockBadge
var player_portrait_wrap: Control
var player_portrait_image: TextureRect  # 戰鬥中切換 active 時動態換肖像
var bench_strip: VBoxContainer  # 後排頭像容器（戰鬥中可點切換上場）
var _switch_tween: Tween = null  # 切換角色的淡出/淡入動畫，防止重疊
var enemy_hp_bar: ProgressBar
var enemy_hp_value: Label
var enemy_status_line: Label
var enemy_name_label: Label
var enemy_block_badge: BlockBadge
var enemy_portrait_wrap: Control
var energy_orb: EnergyOrb
var relic_strip: HBoxContainer
var deck_overlay: Control
var deck_view_mode: String = "view"
var draw_pile_button: Button
var discard_pile_button: Button
var exhausted_pile_button: Button
var card_buttons: Array[Button] = []
var animating_cards: Array[Button] = []
var pause_menu: PauseMenu
var pause_button: Button
var debug_menu: DebugMenu
var battle_end_pending: bool = false
var active_map_scroll: ScrollContainer = null
var _map_drag_candidate: bool = false
var _map_dragging: bool = false
var _map_drag_start_pointer: Vector2 = Vector2.ZERO
var _map_drag_start_scroll: Vector2 = Vector2.ZERO

var _end_turn_warning_id: int = 0
var _card_preview_id: int = 0
var _card_preview_overlay: Control = null
var _suppress_next_card_play: bool = false
var _selected_hand_card: CardData = null
var _selected_hand_button: Button = null

var _temporary_player_pose: String = ""
var _pose_timer: SceneTreeTimer = null

# 卡片 drag-to-play 狀態
var _card_drag_button: Button = null
var _card_drag_card: CardData = null
var _card_drag_start_global: Vector2 = Vector2.ZERO
var _card_drag_active: bool = false
const CARD_DRAG_THRESHOLD: float = 14.0
const CARD_DRAG_TARGET_PADDING: float = 80.0  # 拖到敵人附近 N px 都算命中

var selected_ascension: int = 0
var pending_seed: int = 0  # 0 = 隨機；非 0 = 下次 start_run 用此 seed 生地圖
var selected_party_ids: Array[String] = []  # character_select 多選 buffer，1–3 人
const PARTY_MAX_SIZE: int = 3

const BASE_MARGIN_H: int = 28
const BASE_MARGIN_V: int = 20
const PAUSE_BUTTON_SIZE: Vector2 = Vector2(40, 40)
const MAP_DRAG_THRESHOLD: float = 12.0
const ACT_HEAL_AMOUNT: int = 20

func _ready() -> void:
	randomize()
	SettingsManager.load_settings()
	characters = GameData.characters()
	enemies = GameData.enemies()
	bosses = GameData.bosses()
	get_tree().set_auto_accept_quit(false)
	_build_root()
	_build_pause_menu()
	_build_pause_button()
	if not OS.has_feature("mobile"):
		_build_debug_menu()
	_apply_safe_area_margins()
	get_viewport().size_changed.connect(_apply_safe_area_margins)
	show_main_menu()

func _process(_delta: float) -> void:
	if pause_button == null:
		return
	var should_show: bool = run_state != null and run_state.character != null
	if pause_button.visible != should_show:
		pause_button.visible = should_show

func _build_pause_menu() -> void:
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.abandon_requested.connect(_on_abandon_requested)
	pause_menu.quit_requested.connect(_on_quit_requested)

func _build_pause_button() -> void:
	pause_button = Button.new()
	pause_button.text = "暫停"
	pause_button.custom_minimum_size = PAUSE_BUTTON_SIZE
	pause_button.size = PAUSE_BUTTON_SIZE
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT, false)
	pause_button.add_theme_font_size_override("font_size", 18)
	pause_button.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
	pause_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	pause_button.add_theme_stylebox_override("normal", _pause_button_style(ThemeColors.PANEL_NAVY, ThemeColors.BORDER_GOLD, 2))
	pause_button.add_theme_stylebox_override("hover", _pause_button_style(ThemeColors.PANEL_NAVY_HOV, ThemeColors.ACCENT_GOLD, 3))
	pause_button.add_theme_stylebox_override("pressed", _pause_button_style(ThemeColors.PANEL_NAVY_PRS, ThemeColors.BORDER_GOLD, 2))
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_button.visible = false
	pause_button.text = "⚙"
	pause_button.custom_minimum_size = Vector2(40, 40)
	pause_button.size = pause_button.custom_minimum_size
	pause_button.add_theme_font_size_override("font_size", 28)
	pause_button.add_theme_color_override("font_color", Color("fff6e4", 0.92))
	pause_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	pause_button.add_theme_color_override("font_pressed_color", Color("f0dcc1"))
	pause_button.add_theme_stylebox_override("normal", _pause_button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	pause_button.add_theme_stylebox_override("hover", _pause_button_style(Color(0, 0, 0, 0.10), Color(0, 0, 0, 0), 0))
	pause_button.add_theme_stylebox_override("pressed", _pause_button_style(Color(0, 0, 0, 0.16), Color(0, 0, 0, 0), 0))
	pause_button.pressed.connect(_toggle_pause_menu)
	add_child(pause_button)

func _pause_button_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	return s

func _apply_safe_area_margins() -> void:
	var left: int = BASE_MARGIN_H
	var right: int = BASE_MARGIN_H
	var top: int = BASE_MARGIN_V
	var bottom: int = BASE_MARGIN_V
	if OS.has_feature("mobile"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var window_size: Vector2i = DisplayServer.window_get_size()
		var visible: Vector2 = get_viewport().get_visible_rect().size
		if window_size.x > 0 and window_size.y > 0 and safe.size.x > 0 and safe.size.y > 0:
			var sx: float = visible.x / float(window_size.x)
			var sy: float = visible.y / float(window_size.y)
			var inset_l: int = int(round(safe.position.x * sx))
			var inset_t: int = int(round(safe.position.y * sy))
			var inset_r: int = int(round((window_size.x - safe.position.x - safe.size.x) * sx))
			var inset_b: int = int(round((window_size.y - safe.position.y - safe.size.y) * sy))
			left = max(BASE_MARGIN_H, inset_l)
			top = max(BASE_MARGIN_V, inset_t)
			right = max(BASE_MARGIN_H, inset_r)
			bottom = max(BASE_MARGIN_V, inset_b)
	if root != null:
		root.add_theme_constant_override("margin_left", left)
		root.add_theme_constant_override("margin_right", right)
		root.add_theme_constant_override("margin_top", top)
		root.add_theme_constant_override("margin_bottom", bottom)
	if pause_button != null:
		pause_button.offset_top = top
		pause_button.offset_bottom = top + PAUSE_BUTTON_SIZE.y
		pause_button.offset_left = -PAUSE_BUTTON_SIZE.x - right
		pause_button.offset_right = -right

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var keycode: int = (event as InputEventKey).keycode
		if keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()
		elif keycode == KEY_F1:
			_toggle_debug_menu()
			get_viewport().set_input_as_handled()
	if _handle_map_pointer_input(event):
		get_viewport().set_input_as_handled()

func _handle_map_pointer_input(event: InputEvent) -> bool:
	if active_map_scroll == null or not is_instance_valid(active_map_scroll) or not active_map_scroll.visible:
		_map_drag_candidate = false
		_map_dragging = false
		return false
	var scroll_rect: Rect2 = active_map_scroll.get_global_rect()
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mouse_button.pressed:
			if not scroll_rect.has_point(mouse_button.position):
				return false
			_map_drag_candidate = true
			_map_dragging = false
			_map_drag_start_pointer = mouse_button.position
			_map_drag_start_scroll = Vector2(active_map_scroll.scroll_horizontal, active_map_scroll.scroll_vertical)
			return false
		var was_dragging: bool = _map_dragging
		_map_drag_candidate = false
		_map_dragging = false
		return was_dragging
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if not _map_drag_candidate:
			return false
		var delta_from_start: Vector2 = motion.position - _map_drag_start_pointer
		if not _map_dragging and delta_from_start.length() < MAP_DRAG_THRESHOLD:
			return false
		_map_dragging = true
		_apply_map_scroll_from_drag(delta_from_start)
		return true
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if not scroll_rect.has_point(touch.position):
				return false
			_map_drag_candidate = true
			_map_dragging = false
			_map_drag_start_pointer = touch.position
			_map_drag_start_scroll = Vector2(active_map_scroll.scroll_horizontal, active_map_scroll.scroll_vertical)
			return false
		var was_touch_dragging: bool = _map_dragging
		_map_drag_candidate = false
		_map_dragging = false
		return was_touch_dragging
	if event is InputEventScreenDrag:
		var screen_drag: InputEventScreenDrag = event as InputEventScreenDrag
		if not _map_drag_candidate:
			return false
		var touch_delta_from_start: Vector2 = screen_drag.position - _map_drag_start_pointer
		if not _map_dragging and touch_delta_from_start.length() < MAP_DRAG_THRESHOLD:
			return false
		_map_dragging = true
		_apply_map_scroll_from_drag(touch_delta_from_start)
		return true
	return false

func _apply_map_scroll_from_drag(pointer_delta: Vector2) -> void:
	if active_map_scroll == null or not is_instance_valid(active_map_scroll):
		return
	var hbar: HScrollBar = active_map_scroll.get_h_scroll_bar()
	var vbar: VScrollBar = active_map_scroll.get_v_scroll_bar()
	var max_h: float = hbar.max_value - hbar.page if hbar != null else 0.0
	var max_v: float = vbar.max_value - vbar.page if vbar != null else 0.0
	active_map_scroll.scroll_horizontal = int(clamp(_map_drag_start_scroll.x - pointer_delta.x, 0.0, max(0.0, max_h)))
	active_map_scroll.scroll_vertical = int(clamp(_map_drag_start_scroll.y - pointer_delta.y, 0.0, max(0.0, max_v)))

func _toggle_pause_menu() -> void:
	if pause_menu == null:
		return
	if pause_menu.visible:
		_on_resume_requested()
		return
	# 主選單下不開暫停選單
	if run_state == null or run_state.character == null:
		return
	pause_menu.open()

func _build_debug_menu() -> void:
	debug_menu = DebugMenu.new()
	add_child(debug_menu)
	debug_menu.gold_bonus_requested.connect(_dbg_gold_bonus)
	debug_menu.full_heal_requested.connect(_dbg_full_heal)
	debug_menu.add_card_requested.connect(_dbg_add_card)
	debug_menu.add_relic_requested.connect(_dbg_add_relic)
	debug_menu.jump_to_boss_requested.connect(_dbg_jump_to_boss)
	debug_menu.close_requested.connect(func() -> void: debug_menu.visible = false)

func _toggle_debug_menu() -> void:
	if debug_menu == null:
		return
	if run_state == null or run_state.character == null:
		debug_menu.visible = false
		return
	debug_menu.toggle()

func _dbg_gold_bonus() -> void:
	if run_state == null:
		return
	run_state.gold += 100
	print("[DEBUG] +100 gold (total %d)" % run_state.gold)

func _dbg_full_heal() -> void:
	if run_state == null:
		return
	# 全隊回滿 HP
	for i: int in range(run_state.character_hps.size()):
		run_state.character_hps[i] = run_state.character_max_hps[i]
	if battle != null and not battle_end_pending:
		var players: Array = battle.state.get("players", []) as Array
		for i: int in range(players.size()):
			var p: Dictionary = players[i] as Dictionary
			p["hp"] = int(p["max_hp"])
		battle._sync_active_to_state()
		_refresh_battle()
	print("[DEBUG] full heal applied to all %d character(s)" % run_state.characters.size())

func _dbg_add_card() -> void:
	if run_state == null or selected_character == null:
		return
	if selected_character.reward_pool.is_empty():
		print("[DEBUG] reward_pool empty, nothing to add")
		return
	var card: CardData = selected_character.reward_pool[randi() % selected_character.reward_pool.size()]
	run_state.deck.append(card.clone())
	print("[DEBUG] added card: %s (deck size %d)" % [card.display_title(), run_state.deck.size()])

func _dbg_add_relic() -> void:
	if run_state == null:
		return
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.all():
		if r.slot != "general":
			continue
		if run_state.has_relic(r.id):
			continue
		pool.append(r)
	if pool.is_empty():
		print("[DEBUG] no eligible relics left")
		return
	var chosen: RelicData = pool[randi() % pool.size()]
	run_state.add_relic(chosen)
	print("[DEBUG] added relic: %s" % chosen.display_name)

func _dbg_jump_to_boss() -> void:
	if run_state == null or run_state.encounter_choices.is_empty():
		return
	# 把 encounter_index 直接推到 boss 行（地圖最後一層）
	run_state.encounter_index = run_state.encounter_choices.size() - 1
	debug_menu.visible = false
	show_progress_screen()
	print("[DEBUG] jumped to boss row (index %d)" % run_state.encounter_index)

func _on_resume_requested() -> void:
	pause_menu.close()

func _on_abandon_requested() -> void:
	pause_menu.close()
	SaveManager.clear()
	run_state = RunState.new()
	selected_character = null
	show_main_menu()

func _on_quit_requested() -> void:
	if run_state != null and run_state.character != null:
		SaveManager.save(run_state)
	get_tree().quit()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if run_state != null and run_state.character != null:
				SaveManager.save(run_state)
			get_tree().quit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if pause_menu != null and pause_menu.handle_back():
				return
			if run_state != null and run_state.character != null:
				_toggle_pause_menu()
				return
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if run_state != null and run_state.character != null:
				SaveManager.save(run_state)

func _build_root() -> void:
	background_rect = TextureRect.new()
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_rect)
	root = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

func _clear_root() -> void:
	close_deck_view()
	_hide_card_preview()
	_cancel_end_turn_warning()
	active_map_scroll = null
	_map_drag_candidate = false
	_map_dragging = false
	for button: Button in animating_cards:
		if is_instance_valid(button):
			button.queue_free()
	animating_cards.clear()
	for child: Node in root.get_children():
		child.queue_free()

func _set_background(path: String) -> void:
	if background_rect == null:
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		background_rect.texture = texture

func show_main_menu() -> void:
	selected_party_ids.clear()  # 進主選單清掉 character_select 的暫存隊伍
	_set_background("res://assets/art/login_background.jpg")
	_clear_root()
	var viewport_size: Vector2 = get_viewport_rect().size
	var ultra_compact: bool = viewport_size.y <= 760.0
	var compact_layout: bool = viewport_size.y <= 900.0
	_build_minimal_main_menu(ultra_compact, compact_layout, viewport_size)
	return
	root.add_theme_constant_override("margin_left", 20 if ultra_compact else 28)
	root.add_theme_constant_override("margin_top", 16 if ultra_compact else 20)
	root.add_theme_constant_override("margin_right", 20 if ultra_compact else 28)
	root.add_theme_constant_override("margin_bottom", 18 if ultra_compact else 32)
	var shell_gap: int = 14 if ultra_compact else (18 if compact_layout else 28)
	var panel_margin: int = 18 if ultra_compact else (24 if compact_layout else 34)
	var section_gap: int = 10 if ultra_compact else (14 if compact_layout else 18)
	var button_height: float = 40.0 if ultra_compact else (48.0 if compact_layout else 58.0)
	var button_font_size: int = 18 if ultra_compact else 20
	var title_size: int = 36 if ultra_compact else (44 if compact_layout else 54)
	var subtitle_size: int = 16 if ultra_compact else (18 if compact_layout else 20)
	var preview_gap: int = 8 if ultra_compact else (10 if compact_layout else 14)
	var preview_size: Vector2 = Vector2(190, 220) if ultra_compact else (Vector2(260, 300) if compact_layout else Vector2(340, 420))

	var shell: HBoxContainer = HBoxContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.alignment = BoxContainer.ALIGNMENT_CENTER
	shell.add_theme_constant_override("separation", shell_gap)
	root.add_child(shell)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.custom_minimum_size = Vector2(500 if ultra_compact else (520 if compact_layout else 560), 0)
	left_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("101722", 0.80), Color("d7c89a", 0.38), 1, 16))
	shell.add_child(left_panel)

	var left_margin: MarginContainer = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", panel_margin)
	left_margin.add_theme_constant_override("margin_top", panel_margin)
	left_margin.add_theme_constant_override("margin_right", panel_margin)
	left_margin.add_theme_constant_override("margin_bottom", panel_margin)
	left_panel.add_child(left_margin)

	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", section_gap)
	left_margin.add_child(left_box)

	left_box.add_child(UIFactory.card_label("仙劍奇俠傳・卡牌冒險原型", 14, ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	var title: Label = Label.new()
	title.text = "SwordCard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", title_size)
	title.add_theme_color_override("font_color", Color("fff6d6"))
	left_box.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "踏入山路、抽牌應敵、在每次分歧中決定這趟旅程要長成什麼樣子。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", subtitle_size)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	left_box.add_child(subtitle)

	var feature_row: HBoxContainer = HBoxContainer.new()
	feature_row.add_theme_constant_override("separation", 8 if ultra_compact else 10)
	left_box.add_child(feature_row)
	feature_row.add_child(UIFactory.menu_chip("牌組構築"))
	feature_row.add_child(UIFactory.menu_chip("路線選擇"))
	feature_row.add_child(UIFactory.menu_chip("角色流派"))

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(spacer)

	var action_box: VBoxContainer = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 10 if compact_layout else 12)
	left_box.add_child(action_box)
	if SaveManager.has_save():
		var continue_button: Button = UIFactory.main_menu_button("繼續冒險", true, button_height, button_font_size)
		continue_button.pressed.connect(continue_saved_run)
		action_box.add_child(continue_button)
		var summary: String = _saved_run_summary()
		if not summary.is_empty() and not ultra_compact:
			var summary_label: Label = Label.new()
			summary_label.text = summary
			summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary_label.add_theme_font_size_override("font_size", 12 if compact_layout else 13)
			summary_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
			action_box.add_child(summary_label)
	var start_button: Button = UIFactory.main_menu_button("開始遊戲", false, button_height, button_font_size)
	start_button.pressed.connect(_on_start_random_pressed)
	action_box.add_child(start_button)
	var daily_button: Button = UIFactory.main_menu_button("每日挑戰", false, button_height, button_font_size)
	daily_button.pressed.connect(_on_daily_challenge_pressed)
	action_box.add_child(daily_button)
	var seed_button: Button = UIFactory.main_menu_button("輸入種子", false, button_height, button_font_size)
	seed_button.pressed.connect(_show_seed_input_popup)
	action_box.add_child(seed_button)
	action_box.add_child(_build_ascension_picker(compact_layout, ultra_compact))
	var bestiary_button: Button = UIFactory.main_menu_button("敵將圖鑑", false, button_height, button_font_size)
	bestiary_button.pressed.connect(show_bestiary)
	action_box.add_child(bestiary_button)
	var quit_button: Button = UIFactory.main_menu_button("離開遊戲", false, button_height, button_font_size)
	quit_button.pressed.connect(get_tree().quit)
	action_box.add_child(quit_button)

	if not compact_layout:
		var footer: VBoxContainer = VBoxContainer.new()
		footer.add_theme_constant_override("separation", 8)
		left_box.add_child(footer)
		footer.add_child(UIFactory.paragraph("從四位角色中挑選起手流派，穿越地圖事件、商店與戰鬥節點，完成一輪小型冒險。"))
		footer.add_child(UIFactory.card_label("角色 %d 位  ・  一般敵人 %d 種" % [characters.size(), enemies.size()], 14, Color("9fb0c8"), HORIZONTAL_ALIGNMENT_LEFT))

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(320 if ultra_compact else (360 if compact_layout else 420), 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0d121b", 0.72), Color("8ea3c4", 0.28), 1, 16))
	shell.add_child(right_panel)

	var right_margin: MarginContainer = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 18 if compact_layout else 24)
	right_margin.add_theme_constant_override("margin_top", 18 if compact_layout else 24)
	right_margin.add_theme_constant_override("margin_right", 18 if compact_layout else 24)
	right_margin.add_theme_constant_override("margin_bottom", 18 if compact_layout else 24)
	right_panel.add_child(right_margin)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.add_theme_constant_override("separation", section_gap)
	right_margin.add_child(right_box)

	var preview_character: CharacterData = characters[0] if not characters.is_empty() else null
	if selected_character != null:
		preview_character = selected_character

	var preview_frame: PanelContainer = PanelContainer.new()
	preview_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_frame.add_theme_stylebox_override("panel", UIFactory.style_box(Color("e8dcc0", 0.10), Color("f4d985", 0.44), 2, 18))
	right_box.add_child(preview_frame)

	var preview_wrap: MarginContainer = MarginContainer.new()
	preview_wrap.add_theme_constant_override("margin_left", 12 if ultra_compact else 18)
	preview_wrap.add_theme_constant_override("margin_top", 12 if ultra_compact else 18)
	preview_wrap.add_theme_constant_override("margin_right", 12 if ultra_compact else 18)
	preview_wrap.add_theme_constant_override("margin_bottom", 12 if ultra_compact else 18)
	preview_frame.add_child(preview_wrap)

	var preview_box: VBoxContainer = VBoxContainer.new()
	preview_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_theme_constant_override("separation", preview_gap)
	preview_wrap.add_child(preview_box)

	preview_box.add_child(UIFactory.card_label("本次旅程推薦", 14, ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	if preview_character != null:
		var portrait: TextureRect = UIFactory.portrait_rect(preview_character.portrait_path, preview_size, true)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		preview_box.add_child(portrait)
		var name_label: Label = Label.new()
		name_label.text = preview_character.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.add_theme_font_size_override("font_size", 20 if ultra_compact else (24 if compact_layout else 28))
		name_label.add_theme_color_override("font_color", Color("fff6d6"))
		preview_box.add_child(name_label)
		preview_box.add_child(UIFactory.paragraph(preview_character.battle_style))

	if not compact_layout:
		var quick_info: VBoxContainer = VBoxContainer.new()
		quick_info.add_theme_constant_override("separation", 10)
		right_box.add_child(quick_info)
		quick_info.add_child(UIFactory.menu_info_row("遊玩節奏", "地圖探索 + 戰鬥回合制"))
		quick_info.add_child(UIFactory.menu_info_row("目前內容", "角色選擇、事件、商店、戰鬥與遺物"))
		quick_info.add_child(UIFactory.menu_info_row("操作入口", "可從主選單直接開始或接續存檔"))

func _build_minimal_main_menu(ultra_compact: bool, compact_layout: bool, viewport_size: Vector2) -> void:
	root.add_theme_constant_override("margin_left", 16 if ultra_compact else 24)
	root.add_theme_constant_override("margin_top", 16 if ultra_compact else 24)
	root.add_theme_constant_override("margin_right", 16 if ultra_compact else 24)
	root.add_theme_constant_override("margin_bottom", 16 if ultra_compact else 24)
	var panel_margin: int = 12 if ultra_compact else (16 if compact_layout else 18)
	var section_gap: int = 8 if ultra_compact else 10
	var button_height: float = 30.0 if ultra_compact else (32.0 if compact_layout else 36.0)
	var button_font_size: int = 13 if ultra_compact else 14
	var shell_width: float = min(viewport_size.x - (32 if ultra_compact else 48), 360.0 if compact_layout else 410.0)
	var content_width: float = shell_width - float(panel_margin * 2)

	var stage: VBoxContainer = VBoxContainer.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(stage)

	var top_spacer: Control = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(top_spacer)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(shell_width, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", UIFactory.style_box(Color("14202a", 0.26), Color("f0e6d6", 0.12), 1, 20))
	stage.add_child(card)

	var bottom_gap: Control = Control.new()
	bottom_gap.custom_minimum_size = Vector2(0, 20 if ultra_compact else 28)
	stage.add_child(bottom_gap)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", panel_margin)
	margin.add_theme_constant_override("margin_top", panel_margin)
	margin.add_theme_constant_override("margin_right", panel_margin)
	margin.add_theme_constant_override("margin_bottom", panel_margin)
	card.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", section_gap)
	margin.add_child(content)

	var action_box: VBoxContainer = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 8 if compact_layout else 10)
	content.add_child(action_box)
	if SaveManager.has_save():
		var continue_button: Button = UIFactory.main_menu_button("繼續冒險", true, button_height, button_font_size)
		continue_button.custom_minimum_size.x = content_width
		continue_button.pressed.connect(continue_saved_run)
		action_box.add_child(continue_button)
		var summary: String = _saved_run_summary()
		if not summary.is_empty():
			var summary_label: Label = Label.new()
			summary_label.text = summary
			summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary_label.add_theme_font_size_override("font_size", 11 if compact_layout else 12)
			summary_label.add_theme_color_override("font_color", Color("21303a", 0.92))
			action_box.add_child(summary_label)

	var start_button: Button = UIFactory.main_menu_button("開始遊戲", false, button_height, button_font_size)
	start_button.custom_minimum_size.x = content_width
	start_button.pressed.connect(_on_start_random_pressed)
	action_box.add_child(start_button)

	var daily_button: Button = UIFactory.main_menu_button("每日挑戰", false, button_height, button_font_size)
	daily_button.custom_minimum_size.x = content_width
	daily_button.pressed.connect(_on_daily_challenge_pressed)
	action_box.add_child(daily_button)

	var seed_button: Button = UIFactory.main_menu_button("輸入種子", false, button_height, button_font_size)
	seed_button.custom_minimum_size.x = content_width
	seed_button.pressed.connect(_show_seed_input_popup)
	action_box.add_child(seed_button)

	var ascension_picker: Control = _build_ascension_picker(compact_layout, ultra_compact)
	ascension_picker.custom_minimum_size.x = content_width
	action_box.add_child(ascension_picker)

	var bestiary_button: Button = UIFactory.main_menu_button("敵將圖鑑", false, button_height, button_font_size)
	bestiary_button.custom_minimum_size.x = content_width
	bestiary_button.pressed.connect(show_bestiary)
	action_box.add_child(bestiary_button)

	var quit_button: Button = UIFactory.main_menu_button("離開遊戲", false, button_height, button_font_size)
	quit_button.custom_minimum_size.x = content_width
	quit_button.pressed.connect(get_tree().quit)
	action_box.add_child(quit_button)

func _saved_run_summary() -> String:
	if not SaveManager.has_save():
		return ""
	var data: Dictionary = SaveManager.load_save()
	if data.is_empty():
		return ""
	# load_save 已經 migrate 到當前版本（v2），所以可以直接讀新欄位
	var char_ids: Array = data.get("character_ids", []) as Array
	if char_ids.is_empty():
		return ""
	var char_names: Array[String] = []
	for id_v: Variant in char_ids:
		var nm: String = String(id_v)
		for c: CharacterData in characters:
			if c.id == nm:
				nm = c.display_name
				break
		char_names.append(nm)
	var hps: Array = data.get("character_hps", []) as Array
	var max_hps: Array = data.get("character_max_hps", []) as Array
	var gold: int = int(data.get("gold", 0))
	var encounter_index: int = int(data.get("encounter_index", 0))
	var total_rows: int = (data.get("encounter_choices", []) as Array).size()
	var total_deck: int = 0
	for cdeck_v: Variant in (data.get("character_decks", []) as Array):
		total_deck += (cdeck_v as Array).size()
	var relic_count: int = (data.get("relics", []) as Array).size()
	# HP 行：每個角色一段「李 30/40」
	var hp_parts: Array[String] = []
	for i: int in range(char_names.size()):
		var hp_i: int = int(hps[i]) if i < hps.size() else 0
		var max_i: int = int(max_hps[i]) if i < max_hps.size() else 0
		var status: String = "倒下" if hp_i <= 0 else "%d/%d" % [hp_i, max_i]
		hp_parts.append("%s %s" % [char_names[i], status])
	var party_str: String = "  /  ".join(char_names) if char_names.size() > 1 else char_names[0]
	return "%s  ·  第 %d/%d 層\n%s\n銅錢 %d  ·  牌組共 %d 張  ·  遺物 %d 件" % [
		party_str, encounter_index + 1, total_rows,
		"  ·  ".join(hp_parts),
		gold, total_deck, relic_count
	]

func _on_start_random_pressed() -> void:
	pending_seed = 0
	show_character_select()

func _on_daily_challenge_pressed() -> void:
	pending_seed = Time.get_date_string_from_system().hash()
	show_character_select()

func _show_seed_input_popup() -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(360, 0)
	var title: Label = Label.new()
	title.text = "輸入種子字串"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	var hint: Label = Label.new()
	hint.text = "任意字串會被 hash 成 seed；相同字串總是產生同一張地圖。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	box.add_child(hint)
	var input: LineEdit = LineEdit.new()
	input.placeholder_text = "例：spring-2026"
	input.add_theme_font_size_override("font_size", 16)
	box.add_child(input)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var cancel: Button = _button("取消")
	cancel.pressed.connect(popup.hide)
	row.add_child(cancel)
	var confirm: Button = _button("挑戰此種子")
	var on_confirm: Callable = func() -> void:
		var text: String = input.text.strip_edges()
		if text.is_empty():
			popup.hide()
			return
		pending_seed = text.hash() if text.hash() != 0 else 1
		popup.hide()
		show_character_select()
	confirm.pressed.connect(on_confirm)
	input.text_submitted.connect(func(_t: String) -> void: on_confirm.call())
	row.add_child(confirm)
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()
	input.grab_focus()

func _build_ascension_picker(compact_layout: bool = false, ultra_compact: bool = false) -> Control:
	var unlocked_max: int = Ascension.get_unlocked_max()
	selected_ascension = clamp(selected_ascension, 0, unlocked_max)
	var row_height: float = 30.0 if ultra_compact else (34.0 if compact_layout else 36.0)
	var font_size: int = 15 if ultra_compact else (16 if compact_layout else 18)
	var note_font_size: int = 10 if ultra_compact else 11
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("f6f1e6", 0.16), Color("f4efe6", 0.0), 0, 18))
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4 if ultra_compact else 6)
	panel.add_child(box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6 if ultra_compact else 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var prev_btn: Button = Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(36 if ultra_compact else 40, row_height)
	prev_btn.add_theme_font_size_override("font_size", font_size)
	prev_btn.add_theme_stylebox_override("normal", UIFactory.style_box(Color("f8f3ea", 0.68), Color("f0e7d8", 0.0), 0, 999))
	prev_btn.add_theme_stylebox_override("hover", UIFactory.style_box(Color("fff9f0", 0.88), Color("f0e7d8", 0.0), 0, 999))
	prev_btn.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("eadfcf", 0.92), Color("f0e7d8", 0.0), 0, 999))
	prev_btn.add_theme_color_override("font_color", Color("5a4a33"))
	prev_btn.disabled = selected_ascension <= 0
	prev_btn.pressed.connect(func() -> void:
		selected_ascension = max(0, selected_ascension - 1)
		show_main_menu())
	row.add_child(prev_btn)
	var label: Label = Label.new()
	label.text = "難度 A%d" % selected_ascension
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("21303a", 0.96))
	label.custom_minimum_size = Vector2(104 if ultra_compact else 120, row_height)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var next_btn: Button = Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(36 if ultra_compact else 40, row_height)
	next_btn.add_theme_font_size_override("font_size", font_size)
	next_btn.add_theme_stylebox_override("normal", UIFactory.style_box(Color("f8f3ea", 0.68), Color("f0e7d8", 0.0), 0, 999))
	next_btn.add_theme_stylebox_override("hover", UIFactory.style_box(Color("fff9f0", 0.88), Color("f0e7d8", 0.0), 0, 999))
	next_btn.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("eadfcf", 0.92), Color("f0e7d8", 0.0), 0, 999))
	next_btn.add_theme_color_override("font_color", Color("5a4a33"))
	next_btn.disabled = selected_ascension >= unlocked_max
	next_btn.pressed.connect(func() -> void:
		selected_ascension = min(unlocked_max, selected_ascension + 1)
		show_main_menu())
	row.add_child(next_btn)
	var desc: Label = Label.new()
	desc.text = Ascension.describe(selected_ascension)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 11 if compact_layout else 12)
	desc.add_theme_color_override("font_color", Color("22333d", 0.92))
	desc.custom_minimum_size = Vector2(0, 0)
	box.add_child(desc)
	var unlock_note: Label = Label.new()
	if selected_ascension < Ascension.MAX_LEVEL:
		unlock_note.text = "解鎖至 A%d / A%d 上限" % [unlocked_max, Ascension.MAX_LEVEL]
	else:
		unlock_note.text = "已達 A%d 上限" % Ascension.MAX_LEVEL
	unlock_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_note.add_theme_font_size_override("font_size", note_font_size)
	unlock_note.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
	unlock_note.visible = not ultra_compact
	box.add_child(unlock_note)
	return panel

func show_bestiary() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("敵將圖鑑", 32))
	var data: Dictionary = Bestiary.load_all()
	var defeated_count: int = 0
	var total_count: int = enemies.size() + bosses.size()
	for k: Variant in data.keys():
		if int(data[k]) > 0:
			defeated_count += 1
	box.add_child(UIFactory.paragraph("已記錄 %d / %d 種敵將" % [defeated_count, total_count]))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(960, 480)
	box.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for enemy: EnemyData in enemies:
		grid.add_child(_bestiary_tile(enemy, false, int(data.get(enemy.id, 0))))
	for boss: EnemyData in bosses:
		grid.add_child(_bestiary_tile(boss, true, int(data.get(boss.id, 0))))
	var back: Button = _button("返回主選單")
	back.pressed.connect(show_main_menu)
	box.add_child(back)

func _bestiary_tile(enemy: EnemyData, is_boss: bool, kill_count: int) -> Control:
	var defeated: bool = kill_count > 0
	var border: Color = ThemeColors.HIGHLIGHT_GOLD if is_boss else (ThemeColors.BORDER_GOLD if defeated else Color("5f6570", 0.5))
	var bg: Color = Color("18212f", 0.85) if defeated else Color("0d121b", 0.85)
	var tile: PanelContainer = PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UIFactory.style_box(bg, border, 2 if is_boss else 1, 8))
	tile.custom_minimum_size = Vector2(290, 220)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	tile.add_child(inner)
	var portrait: TextureRect = UIFactory.portrait_rect(enemy.portrait_path, Vector2(120, 96), true)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not defeated:
		portrait.modulate = Color(0.0, 0.0, 0.0, 0.85)
	inner.add_child(portrait)
	var name_label: Label = Label.new()
	name_label.text = enemy.display_name if defeated else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD if defeated else ThemeColors.TEXT_DIM)
	inner.add_child(name_label)
	if defeated:
		var stats: Label = Label.new()
		stats.text = "HP %d  ·  擊敗 %d 次%s" % [enemy.max_hp, kill_count, "  ·  Boss" if is_boss else ""]
		stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_theme_font_size_override("font_size", 12)
		stats.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		inner.add_child(stats)
		var intents: Array[String] = []
		for action: Dictionary in enemy.actions:
			intents.append(String(action.get("intent", "")))
		var intent_label: Label = Label.new()
		intent_label.text = "招式：%s" % "、".join(intents)
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		intent_label.add_theme_font_size_override("font_size", 11)
		intent_label.add_theme_color_override("font_color", ThemeColors.TEXT_MUTED)
		intent_label.custom_minimum_size = Vector2(260, 0)
		inner.add_child(intent_label)
	else:
		var locked: Label = Label.new()
		locked.text = "尚未交手"
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.add_theme_font_size_override("font_size", 12)
		locked.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		inner.add_child(locked)
	return tile

func continue_saved_run() -> void:
	var data: Dictionary = SaveManager.load_save()
	if data.is_empty():
		return
	var loaded_state: RunState = RunState.new()
	if not loaded_state.from_dict(data, characters):
		push_warning("存檔無法載入（角色不存在）。")
		SaveManager.clear()
		return
	run_state = loaded_state
	selected_character = run_state.character
	show_progress_screen()

func show_character_select(preview_id: String = "") -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	# preview 預設順序：明確 preview_id > 目前隊伍隊長 > characters[0]
	var preview_character: CharacterData = null
	if not preview_id.is_empty():
		preview_character = _character_by_id(preview_id)
	if preview_character == null and not selected_party_ids.is_empty():
		preview_character = _character_by_id(selected_party_ids[0])
	if preview_character == null and not characters.is_empty():
		preview_character = characters[0]
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 10)
	screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(screen)
	screen.add_child(_title("選擇隊伍（%d / %d）" % [selected_party_ids.size(), PARTY_MAX_SIZE], 30))
	var stage: Control = _character_select_stage(preview_character)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(stage)
	var thumb_row: HBoxContainer = HBoxContainer.new()
	thumb_row.alignment = BoxContainer.ALIGNMENT_CENTER
	thumb_row.add_theme_constant_override("separation", 12)
	screen.add_child(thumb_row)
	for character: CharacterData in characters:
		thumb_row.add_child(_character_thumb(character, character.id == preview_character.id))
	# 隊伍順序提示
	var party_summary: Label = Label.new()
	party_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	party_summary.add_theme_font_size_override("font_size", 14)
	if selected_party_ids.is_empty():
		party_summary.text = "點下方頭像加入隊伍；先選的人是隊長"
		party_summary.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	else:
		var names: Array[String] = []
		for i: int in range(selected_party_ids.size()):
			var c: CharacterData = _character_by_id(selected_party_ids[i])
			if c != null:
				var prefix: String = "★ " if i == 0 else ""
				names.append(prefix + c.display_name)
		party_summary.text = "出戰順序：" + "  →  ".join(names)
		party_summary.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	screen.add_child(party_summary)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	action_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	screen.add_child(action_row)
	action_row.add_child(_event_choice_button(
		"出戰",
		"率隊踏上山路（%d 人）" % selected_party_ids.size() if not selected_party_ids.is_empty() else "至少選 1 人",
		selected_party_ids.is_empty(),
		_on_party_depart_pressed))
	action_row.add_child(_event_choice_button("返回", "回主選單", false, show_main_menu))

func _on_party_thumb_pressed(character: CharacterData) -> void:
	# 切換選取狀態（先預覽，再加入或移出）
	var pos: int = selected_party_ids.find(character.id)
	if pos >= 0:
		selected_party_ids.remove_at(pos)
	elif selected_party_ids.size() < PARTY_MAX_SIZE:
		selected_party_ids.append(character.id)
	# 滿員時點未選的人 = 只切換預覽、不加入
	show_character_select(character.id)

func _on_party_depart_pressed() -> void:
	if selected_party_ids.is_empty():
		return
	var party: Array[CharacterData] = []
	for id: String in selected_party_ids:
		var c: CharacterData = _character_by_id(id)
		if c != null:
			party.append(c)
	if party.is_empty():
		return
	start_run(party)

func _character_by_id(id: String) -> CharacterData:
	for c: CharacterData in characters:
		if c.id == id:
			return c
	return null

func _character_select_stage(character: CharacterData) -> Control:
	var stage: Control = Control.new()
	stage.custom_minimum_size = Vector2(1120, 520)
	var halo: PanelContainer = PanelContainer.new()
	halo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	halo.custom_minimum_size = Vector2(470, 470)
	halo.size = Vector2(470, 470)
	halo.position = Vector2(-235, -228)
	halo.add_theme_stylebox_override("panel", UIFactory.style_box(Color("d8dec6", 0.18), Color("d7c06d", 0.72), 2, 235))
	stage.add_child(halo)
	var portrait: TextureRect = UIFactory.portrait_rect(character.portrait_path, Vector2(430, 455), true)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	portrait.size = Vector2(430, 455)
	portrait.position = Vector2(-215, -232)
	stage.add_child(portrait)
	var name_label: Label = _title(character.display_name, 28)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	name_label.position = Vector2(-180, -74)
	name_label.custom_minimum_size = Vector2(360, 42)
	name_label.size = Vector2(360, 42)
	stage.add_child(name_label)
	var poem_path: String = _character_poem_image_path(character.id)
	var poem_texture: Texture2D = UIFactory.load_texture(poem_path)
	if poem_texture != null:
		var poem_image: TextureRect = TextureRect.new()
		poem_image.custom_minimum_size = Vector2(180, 420)
		poem_image.size = Vector2(180, 420)
		poem_image.position = Vector2(12, 34)
		poem_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		poem_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		poem_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		poem_image.texture = poem_texture
		stage.add_child(poem_image)
	else:
		var poem_box: HBoxContainer = HBoxContainer.new()
		poem_box.custom_minimum_size = Vector2(180, 420)
		poem_box.position = Vector2(12, 34)
		poem_box.add_theme_constant_override("separation", 18)
		stage.add_child(poem_box)
		var poem_lines: Array[String] = _character_poem(character.id)
		for index: int in range(0, poem_lines.size(), 2):
			var merged_line: String = poem_lines[index]
			if index + 1 < poem_lines.size():
				merged_line += "，" + poem_lines[index + 1]
			poem_box.add_child(_vertical_poem_line(merged_line))
	var info_panel: PanelContainer = PanelContainer.new()
	info_panel.custom_minimum_size = Vector2(320, 300)
	info_panel.size = Vector2(320, 300)
	info_panel.anchor_left = 1.0
	info_panel.anchor_right = 1.0
	info_panel.offset_left = -352
	info_panel.offset_right = -24
	info_panel.offset_top = 84
	info_panel.offset_bottom = 384
	info_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0d151f", 0.58), Color("8ea3c4", 0.48), 1, 8))
	stage.add_child(info_panel)
	var info_box: VBoxContainer = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info_panel.add_child(info_box)
	info_box.add_child(_title("角色說明", 22))
	info_box.add_child(UIFactory.paragraph(character.battle_style))
	info_box.add_child(UIFactory.paragraph("生命值：%d" % character.max_hp))
	var card_names: Array[String] = []
	for card: CardData in character.starting_deck:
		card_names.append(card.display_title())
	var deck_text: String = "起始牌組：" + ", ".join(card_names)
	info_box.add_child(UIFactory.paragraph(deck_text))
	var in_party: bool = selected_party_ids.has(character.id)
	var party_full: bool = selected_party_ids.size() >= PARTY_MAX_SIZE
	var choose_title: String
	var choose_subtitle: String
	var choose_disabled: bool = false
	if in_party:
		var pos: int = selected_party_ids.find(character.id) + 1
		choose_title = "移出隊伍"
		choose_subtitle = "目前隊伍第 %d 位" % pos
	elif party_full:
		choose_title = "隊伍已滿"
		choose_subtitle = "先移出一人才能加入"
		choose_disabled = true
	else:
		var next_pos: int = selected_party_ids.size() + 1
		choose_title = "加入隊伍"
		choose_subtitle = "排第 %d 位%s" % [next_pos, "（隊長）" if next_pos == 1 else ""]
	info_box.add_child(_event_choice_button(choose_title, choose_subtitle, choose_disabled, func() -> void: _on_party_thumb_pressed(character)))
	var confirm_depart_button: Button = _button("確認出戰")
	confirm_depart_button.disabled = selected_party_ids.is_empty()
	confirm_depart_button.pressed.connect(_on_party_depart_pressed)
	info_box.add_child(confirm_depart_button)
	return stage

func _character_thumb(character: CharacterData, selected: bool) -> Control:
	var party_pos: int = selected_party_ids.find(character.id) + 1  # 0 = 未選；1+ = 隊伍中順序
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(112, 92)
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	# 視覺：被選入隊伍的人最亮、目前 preview 的人金邊、其餘維持暗色
	var in_party: bool = party_pos > 0
	var base: Color
	var border: Color
	var border_width: int = 1
	if in_party:
		base = Color("33435c", 0.95)
		border = ThemeColors.HIGHLIGHT_GOLD
		border_width = 2
	elif selected:
		base = Color("18212f", 0.86)
		border = ThemeColors.HIGHLIGHT_GOLD
		border_width = 2
	else:
		base = Color("18212f", 0.86)
		border = Color("536277", 0.75)
	button.add_theme_stylebox_override("normal", UIFactory.style_box(base, border, border_width, 8))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(base.lightened(0.12), ThemeColors.ACCENT_GOLD, 2, 8))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(base.darkened(0.1), ThemeColors.HIGHLIGHT_GOLD, 2, 8))
	button.pressed.connect(func() -> void: _on_party_thumb_pressed(character))
	var image: TextureRect = UIFactory.portrait_rect(character.portrait_path, Vector2(96, 72), true)
	image.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	image.size = Vector2(96, 72)
	image.position = Vector2(-48, 6)
	button.add_child(image)
	var label: Label = UIFactory.card_label(character.display_name, 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	label.position = Vector2(-50, -22)
	label.custom_minimum_size = Vector2(100, 20)
	label.size = Vector2(100, 20)
	button.add_child(label)
	# 隊伍順序 badge：左上角圓圈裡的數字
	if in_party:
		var badge: PanelContainer = PanelContainer.new()
		badge.custom_minimum_size = Vector2(22, 22)
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
		badge.offset_left = 4
		badge.offset_top = 4
		badge.offset_right = 26
		badge.offset_bottom = 26
		var badge_style: StyleBoxFlat = StyleBoxFlat.new()
		badge_style.bg_color = ThemeColors.HIGHLIGHT_GOLD
		badge_style.set_corner_radius_all(11)
		badge_style.content_margin_left = 2
		badge_style.content_margin_right = 2
		badge_style.content_margin_top = 1
		badge_style.content_margin_bottom = 1
		badge.add_theme_stylebox_override("panel", badge_style)
		var badge_label: Label = Label.new()
		badge_label.text = str(party_pos)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 14)
		badge_label.add_theme_color_override("font_color", Color("1b160d"))
		badge.add_child(badge_label)
		button.add_child(badge)
	UIFactory.ignore_child_mouse(button)
	return button

func _character_poem(character_id: String) -> Array[String]:
	match character_id:
		"li_xiaoyao":
			return ["少年御劍出雲關", "一壺清夢照塵寰", "萬里仙途憑笑闖", "逍遙風起斬妖還"]
		"zhao_linger":
			return ["靈澤如煙護月華", "五行清露洗塵沙", "夢蛇一現山河靜", "慈念長明照萬家"]
		"lin_yueru":
			return ["月映長鞭破夜寒", "英姿一劍動雲端", "回身敢向強敵笑", "赤膽芳心照玉欄"]
		"anu":
			return ["苗疆鈴響引春風", "蠱影花香入霧中", "笑語偏藏奇術妙", "忘憂一曲月朦朧"]
	return ["劍影初分照遠山", "清風入袖試新關", "此身既赴仙途路", "一念凌雲破夜寒"]

func _character_poem_image_path(character_id: String) -> String:
	match character_id:
		"li_xiaoyao":
			return "res://assets/ui/poems/li_xiaoyao_poem.png"
		"zhao_linger":
			return "res://assets/ui/poems/zhao_linger_poem.png"
		"lin_yueru":
			return "res://assets/ui/poems/lin_yueru_poem.png"
		"anu":
			return "res://assets/ui/poems/anu_poem.png"
	return ""

func _vertical_poem_line(text: String) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	for character: String in text:
		var glyph: Label = UIFactory.card_label(character, 24, Color("c98b42"), HORIZONTAL_ALIGNMENT_CENTER)
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.custom_minimum_size = Vector2(28, 34)
		glyph.add_theme_color_override("font_outline_color", Color("f5dfb0", 0.32))
		glyph.add_theme_constant_override("outline_size", 1)
		column.add_child(glyph)
	return column

func start_run(party_or_char: Variant) -> void:
	# 接受單一 CharacterData（單人 run）或 Array[CharacterData]（組隊）
	var party: Array[CharacterData] = []
	if party_or_char is CharacterData:
		party.append((party_or_char as CharacterData).clone())
	elif party_or_char is Array:
		for c_v: Variant in (party_or_char as Array):
			if c_v is CharacterData:
				party.append((c_v as CharacterData).clone())
	if party.is_empty():
		push_warning("start_run called with empty party")
		return
	selected_character = party[0]  # 隊長作為「主角」沿用既有 main.gd 路徑
	run_state.ascension_level = selected_ascension
	var seed_for_run: int = pending_seed if pending_seed != 0 else randi()
	seed(seed_for_run)
	run_state.map_seed = seed_for_run
	run_state.init_for(party)
	# 套 ascension starting_hp 倍率到每個角色
	var hp_mult: float = Ascension.starting_hp_multiplier(run_state.ascension_level)
	if hp_mult != 1.0:
		for i: int in range(run_state.character_max_hps.size()):
			var new_max: int = max(1, int(round(float(run_state.character_max_hps[i]) * hp_mult)))
			run_state.character_max_hps[i] = new_max
			run_state.character_hps[i] = new_max
	run_state.encounter_choices = _make_encounter_choices()
	randomize()  # 地圖生成完，戰鬥/獎勵恢復隨機 RNG
	pending_seed = 0  # 消費掉
	selected_party_ids.clear()  # 隊伍鎖死、清掉 select buffer
	show_progress_screen()

func _make_encounter_choices() -> Array[Array]:
	var act_enemies: Array[EnemyData] = GameData.enemies_for_act(run_state.act)
	var act_boss: Array[EnemyData] = []
	act_boss.append(GameData.boss_for_act(run_state.act))
	return MapGenerator.generate(act_enemies, act_boss)

func show_progress_screen() -> void:
	SaveManager.save(run_state)
	_set_background("res://assets/art/map_bg_ink.png")
	_clear_root()
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact_map: bool = viewport_size.y <= 760.0
	_build_streamlined_progress_screen(compact_map)
	return
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8 if compact_map else 14)
	panel.add_child(box)
	box.add_child(_title("第%s幕・%d/%d 層" % [_act_numeral(run_state.act), run_state.encounter_index + 1, run_state.encounter_choices.size()], 28 if compact_map else 34))
	var act_location: Label = UIFactory.card_label(_act_title(run_state.act), 16 if compact_map else 20, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(act_location)
	var map_summary: Label = UIFactory.paragraph("%s  HP %d/%d  銅錢 %d  牌組 %d 張  本輪增傷 +%d" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size(), run_state.power_bonus])
	map_summary.add_theme_font_size_override("font_size", 14 if compact_map else 17)
	box.add_child(map_summary)
	if run_state.map_seed != 0:
		var seed_label: Label = UIFactory.card_label("種子 %d  ·  難度 A%d" % [run_state.map_seed, run_state.ascension_level], 12, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(seed_label)
	if not compact_map:
		box.add_child(UIFactory.paragraph("選擇亮起的節點前進；灰色節點代表目前路線無法抵達。"))
	var passive_label: Label = UIFactory.paragraph(_passive_text())
	passive_label.add_theme_font_size_override("font_size", 14 if compact_map else 17)
	box.add_child(passive_label)
	if not run_state.relics.is_empty():
		var relic_names: Array[String] = []
		for r: RelicData in run_state.relics:
			relic_names.append(r.display_name)
		var relic_label: Label = UIFactory.paragraph("裝備：%s" % "、".join(relic_names))
		relic_label.add_theme_font_size_override("font_size", 14 if compact_map else 17)
		box.add_child(relic_label)
	box.add_child(_map_view())
	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(button_row)
	button_row.add_child(_event_choice_button("路線", "總覽全部層數", false, _show_map_overview_popup))
	button_row.add_child(_event_choice_button("翻閱", "查看當前手札", false, show_deck_view))
	button_row.add_child(_event_choice_button("放棄", "返回主選單", false, show_main_menu))

func _map_view() -> Control:
	return _map_view_sts()

func _build_streamlined_progress_screen(compact_map: bool) -> void:
	root.add_theme_constant_override("margin_left", 14 if compact_map else 18)
	root.add_theme_constant_override("margin_top", 14 if compact_map else 18)
	root.add_theme_constant_override("margin_right", 14 if compact_map else 18)
	root.add_theme_constant_override("margin_bottom", 14 if compact_map else 18)
	var layer: Control = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(layer)
	var map_panel: Control = _map_view_sts()
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(map_panel)
	
	# 在地圖上方顯示當前幕名稱，例如「第一幕 余杭山間」
	var act_label: Label = Label.new()
	act_label.text = "第%s幕 %s" % [_act_numeral(run_state.act), _act_title(run_state.act)]
	act_label.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	act_label.offset_left = 12
	act_label.offset_top = 8
	act_label.offset_right = 500
	act_label.offset_bottom = 48
	act_label.add_theme_font_size_override("font_size", 20 if compact_map else 24)
	act_label.add_theme_color_override("font_color", ThemeColors.HIGHLIGHT_GOLD)
	act_label.add_theme_color_override("font_outline_color", Color("000000", 0.72))
	act_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(act_label)
	
	layer.add_child(_build_map_toolbar())


func _build_map_toolbar() -> Control:
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.set_anchors_preset(Control.PRESET_TOP_RIGHT, false)
	toolbar.offset_left = -140
	toolbar.offset_top = 4
	toolbar.offset_right = -PAUSE_BUTTON_SIZE.x - 10
	toolbar.offset_bottom = 44
	toolbar.alignment = BoxContainer.ALIGNMENT_END
	toolbar.add_theme_constant_override("separation", 8)
	toolbar.add_child(_map_icon_button("人", "角色狀態", _show_map_status_popup))
	toolbar.add_child(_map_icon_button("牌", "查看牌組", func() -> void: show_deck_view()))
	return toolbar

func _map_icon_button(symbol: String, tooltip: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = symbol
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("fff6e4", 0.94))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("f0dcc1"))
	button.add_theme_stylebox_override("normal", _pause_button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	button.add_theme_stylebox_override("hover", _pause_button_style(Color(0, 0, 0, 0.10), Color(0, 0, 0, 0), 0))
	button.add_theme_stylebox_override("pressed", _pause_button_style(Color(0, 0, 0, 0.16), Color(0, 0, 0, 0), 0))
	button.pressed.connect(action)
	return button

func _map_view_sts() -> Control:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact_map: bool = viewport_size.y <= 760.0
	var panel_height: float = clamp(viewport_size.y - (56.0 if compact_map else 64.0), 360.0, 760.0)
	var map_panel: PanelContainer = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(1040, panel_height)
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("f4edd8", 0.02), Color("f4edd8", 0.08), 1, 8))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1040, panel_height)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	map_panel.add_child(scroll)
	active_map_scroll = scroll
	var map_area: Control = Control.new()
	var total_rows: int = run_state.encounter_choices.size()
	var content_size: Vector2 = _map_content_size(total_rows)
	map_area.custom_minimum_size = content_size
	map_area.size = content_size
	map_area.clip_contents = false
	scroll.add_child(map_area)
	# 地圖底紙由 show_progress_screen() 的全域 background_rect 提供
	# （透過半透明的 panel 透出來），不在這裡再疊一張同樣的圖，避免捲動時前後兩張錯位
	var line_layer: Control = preload("res://scripts/map_link_layer.gd").new()
	line_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_area.add_child(line_layer)
	var node_buttons: Array[Dictionary] = []
	for row_index: int in range(total_rows):
		var row: Array = run_state.encounter_choices[row_index]
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_button: Button = _map_node_button(node_data, row_index)
			var node_index: int = int(node_data.get("index", 0))
			node_button.position = _map_node_position(row_index, node_index, row.size(), total_rows, map_area.custom_minimum_size)
			map_area.add_child(node_button)
			node_buttons.append({"button": node_button, "row": row_index, "index": node_index})
	call_deferred("_refresh_map_link_layer", line_layer, node_buttons)
	call_deferred("_focus_map_row", scroll, _map_focus_anchor(total_rows, content_size), content_size)
	return map_panel

func _map_content_size(total_rows: int) -> Vector2:
	return Vector2(1040, max(1180.0, 360.0 + float(total_rows) * 320.0))

func _map_focus_anchor(total_rows: int, content_size: Vector2) -> Vector2:
	var target_row: int = clamp(run_state.encounter_index, 0, max(0, total_rows - 1))
	var row: Array = run_state.encounter_choices[target_row] if target_row < run_state.encounter_choices.size() else []
	var target_index: int = 0
	if target_row < run_state.chosen_map_path.size():
		target_index = clamp(int(run_state.chosen_map_path[target_row]), 0, max(0, row.size() - 1))
	else:
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_index: int = int(node_data.get("index", 0))
			if _is_map_node_selectable(target_row, node_index):
				target_index = node_index
				break
	var anchor: Vector2 = _map_node_position(target_row, target_index, max(1, row.size()), total_rows, content_size)
	return anchor + Vector2(38.0, 46.0)

func _focus_map_row(scroll: ScrollContainer, anchor: Vector2, content_size: Vector2) -> void:
	if scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if scroll == null or not is_instance_valid(scroll):
		return
	var viewport_height: float = scroll.size.y
	if viewport_height <= 0.0:
		viewport_height = scroll.custom_minimum_size.y
	var target_scroll: float = anchor.y - viewport_height * 0.48
	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	var max_scroll: float = max(0.0, content_size.y - viewport_height)
	if vbar != null:
		max_scroll = max(0.0, vbar.max_value - vbar.page)
	scroll.scroll_vertical = int(clamp(target_scroll, 0.0, max_scroll))

func _map_node_position(row_index: int, node_index: int, row_size: int, total_rows: int, area_size: Vector2) -> Vector2:
	var top_margin: float = 72.0
	var bottom_margin: float = 150.0
	var left_margin: float = 80.0
	var right_margin: float = 80.0
	var usable_height: float = max(1.0, area_size.y - top_margin - bottom_margin)
	var usable_width: float = max(1.0, area_size.x - left_margin - right_margin)
	var y_ratio: float = 0.0 if total_rows <= 1 else float(row_index) / float(total_rows - 1)
	var y: float = area_size.y - bottom_margin - usable_height * y_ratio
	var lane_patterns: Dictionary = {
		1: [0.5],
		2: [0.34, 0.66],
		3: [0.22, 0.5, 0.78],
		4: [0.14, 0.38, 0.62, 0.86],
		5: [0.1, 0.3, 0.5, 0.7, 0.9],
		6: [0.08, 0.24, 0.4, 0.6, 0.76, 0.92]
	}
	var pattern: Array = lane_patterns.get(row_size, []) as Array
	if pattern.is_empty():
		for lane_index: int in range(row_size):
			pattern.append(float(lane_index + 1) / float(row_size + 1))
	var normalized_x: float = float(pattern[min(node_index, pattern.size() - 1)])
	var row_sway: float = sin(float(row_index) * 0.95 + 0.3) * 48.0
	var node_sway: float = sin(float(row_index) * 1.25 + float(node_index) * 1.55) * 34.0
	var bend_bias: float = cos(float(row_index + node_index) * 1.1) * 18.0
	var x: float = left_margin + usable_width * normalized_x + row_sway + node_sway + bend_bias
	var y_offset: float = cos(float(row_index) * 1.2 + float(node_index) * 0.85) * 14.0
	return Vector2(x - 38.0, y - 46.0 + y_offset)

func _refresh_map_link_layer(line_layer: Control, node_buttons: Array[Dictionary]) -> void:
	if line_layer == null:
		return
	var centers: Dictionary = {}
	for item: Dictionary in node_buttons:
		var button: Button = item["button"] as Button
		if button == null:
			continue
		var row_index: int = int(item["row"])
		var node_index: int = int(item["index"])
		centers["%d:%d" % [row_index, node_index]] = button.global_position - line_layer.global_position + button.size * 0.5
	var segments: Array[Dictionary] = []
	for row_index: int in range(run_state.encounter_choices.size() - 1):
		var row: Array = run_state.encounter_choices[row_index]
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var node_index: int = int(node_data.get("index", 0))
			var from_key: String = "%d:%d" % [row_index, node_index]
			if not centers.has(from_key):
				continue
			var from_point: Vector2 = centers[from_key]
			var connects: Array = node_data.get("connects", []) as Array
			for target_variant: Variant in connects:
				var target_index: int = int(target_variant)
				var to_key: String = "%d:%d" % [row_index + 1, target_index]
				if not centers.has(to_key):
					continue
				segments.append({
					"from": from_point,
					"to": centers[to_key],
					"active": _is_map_connection_active(row_index, node_index, target_index)
				})
	line_layer.call("set_segments", segments)

func _is_map_connection_active(row_index: int, node_index: int, target_index: int) -> bool:
	if row_index >= run_state.chosen_map_path.size():
		return row_index == run_state.encounter_index and _is_map_node_selectable(row_index, node_index)
	if run_state.chosen_map_path[row_index] != node_index:
		return false
	if row_index + 1 < run_state.chosen_map_path.size():
		return run_state.chosen_map_path[row_index + 1] == target_index
	return row_index + 1 == run_state.encounter_index and _is_map_node_selectable(row_index + 1, target_index)

func _map_node_button(node_data: Dictionary, row_index: int) -> Button:
	var node_index: int = int(node_data.get("index", 0))
	var button: Button = _route_node_button(node_data)
	var selectable: bool = _is_map_node_selectable(row_index, node_index)
	var selected: bool = row_index < run_state.chosen_map_path.size() and run_state.chosen_map_path[row_index] == node_index
	var completed: bool = row_index < run_state.encounter_index
	button.custom_minimum_size = Vector2(76, 92)
	button.text = _map_node_compact_text(node_data, row_index, selected)
	button.disabled = not selectable
	button.focus_mode = Control.FOCUS_NONE
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_map_node_button(button, node_data, selected, selectable, completed)
	if selected:
		button.add_theme_stylebox_override("disabled", UIFactory.style_box(Color("214130", 0.34), Color("f5f1d6"), 2, 28))
		button.add_theme_color_override("font_disabled_color", Color("25313b"))
	elif completed:
		button.add_theme_stylebox_override("disabled", UIFactory.style_box(Color("345b45", 0.28), Color("8fd2a2", 0.78), 2, 28))
		button.add_theme_color_override("font_disabled_color", Color("dff3e3"))
	elif not selectable:
		button.add_theme_stylebox_override("disabled", UIFactory.style_box(Color("5f6570", 0.08), Color("778899", 0.24), 1, 28))
		button.add_theme_color_override("font_disabled_color", Color("8c99a6"))
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "boss":
		button.custom_minimum_size = Vector2(92, 110)
	call_deferred("_animate_map_node", button, selected, selectable, node_type == "boss")
	return button

func _style_map_node_button(button: Button, node_data: Dictionary, selected: bool, selectable: bool, completed: bool = false) -> void:
	var normal_bg: Color = Color(0, 0, 0, 0)
	var hover_bg: Color = Color("f4edd8", 0.08)
	var pressed_bg: Color = Color("f4edd8", 0.12)
	var hover_border: Color = Color("25313b", 0.24)
	var pressed_border: Color = Color("f5f1d6")
	if completed:
		hover_bg = Color("7db58b", 0.18)
		pressed_bg = Color("5f9d73", 0.22)
		hover_border = Color("8fd2a2", 0.6)
		pressed_border = Color("dff3e3", 0.9)
	elif selectable or selected:
		hover_bg = Color("f0d79a", 0.18)
		pressed_bg = Color("e4c67a", 0.24)
		hover_border = Color("ecd89a", 0.72)
		pressed_border = Color("fff4d2", 0.94)
	button.add_theme_stylebox_override("normal", UIFactory.style_box(normal_bg, Color(0, 0, 0, 0), 0, 28))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(hover_bg, hover_border, 1, 28))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(pressed_bg, pressed_border, 1, 28))
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_constant_override("v_separation", 0)
	button.add_theme_color_override("font_color", Color("25313b", 0.55))
	button.add_theme_color_override("font_hover_color", Color("1d2838", 0.75))
	button.add_theme_color_override("font_pressed_color", Color("1d2838", 0.75))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var icon: Control = null
	if button.has_meta("route_icon"):
		icon = button.get_meta("route_icon") as Control
	if icon != null:
		var node_type: String = String(node_data.get("type", "battle"))
		icon.custom_minimum_size = Vector2(72, 72) if node_type == "boss" else Vector2(56, 56)
		icon.position.y = max(0.0, icon.position.y - 8.0)
	var label: Label = null
	if button.has_meta("route_label"):
		label = button.get_meta("route_label") as Label
	if label != null:
		label.text = ""
		label.custom_minimum_size = Vector2(0, 0)
		label.visible = false
	if completed:
		button.modulate = Color(0.82, 1.0, 0.86, 0.98)
	elif not selectable and not selected:
		button.modulate = Color(0.64, 0.64, 0.64, 0.72)
	else:
		button.modulate = Color.WHITE

func _map_node_compact_text(node_data: Dictionary, row_index: int, selected: bool) -> String:
	return ""

func _map_node_text(node_data: Dictionary, row_index: int, selected: bool) -> String:
	var title: String = _map_node_title(node_data)
	var status: String = "已選" if selected else _map_node_status(row_index, int(node_data.get("index", 0)))
	return "[%s] %s\n%s" % [_map_node_badge(node_data), title, status]

func _map_node_badge(node_data: Dictionary) -> String:
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		return "休"
	if node_type == "event":
		return "遇"
	if node_type == "shop":
		return "黑" if bool(node_data.get("black_market", false)) else "店"
	if node_type == "boss":
		return "王"
	return "戰"

func _map_node_title(node_data: Dictionary) -> String:
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		return "休息"
	if node_type == "event":
		return "奇遇"
	if node_type == "shop":
		return "黑店" if bool(node_data.get("black_market", false)) else "商店"
	var enemy: EnemyData = node_data.get("enemy") as EnemyData
	if enemy == null:
		return "戰鬥"
	if node_type == "boss":
		return "Boss\n%s" % enemy.display_name
	return "戰鬥\n%s" % enemy.display_name

func _map_node_status(row_index: int, node_index: int) -> String:
	if row_index == run_state.encounter_index and _is_map_node_selectable(row_index, node_index):
		return "可前往"
	if row_index < run_state.encounter_index:
		return "已錯過"
	if row_index == run_state.encounter_index:
		return "未連通"
	return "未知路線"

func _map_link_text(node_data: Dictionary) -> String:
	var connects: Array = node_data.get("connects", []) as Array
	if connects.is_empty():
		return "終點"
	var labels: Array[String] = []
	for target: Variant in connects:
		labels.append(str(int(target) + 1))
	return "通往 " + " / ".join(labels)

func _is_map_node_selectable(row_index: int, node_index: int) -> bool:
	if row_index != run_state.encounter_index:
		return false
	if row_index == 0:
		return true
	if run_state.chosen_map_path.size() < row_index:
		return false
	var previous_index: int = run_state.chosen_map_path[row_index - 1]
	var previous_row: Array = run_state.encounter_choices[row_index - 1]
	if previous_index < 0 or previous_index >= previous_row.size():
		return false
	var previous_node: Dictionary = previous_row[previous_index] as Dictionary
	var connects: Array = previous_node.get("connects", []) as Array
	return connects.has(node_index)

func choose_route_node(node_data: Dictionary) -> void:
	var node_index: int = int(node_data.get("index", 0))
	if run_state.chosen_map_path.size() > run_state.encounter_index:
		run_state.chosen_map_path[run_state.encounter_index] = node_index
	else:
		run_state.chosen_map_path.append(node_index)
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		resolve_rest_node()
	elif node_type == "event":
		run_state.current_event_variant = String(node_data.get("event_variant", "shrine"))
		show_event_node()
	elif node_type == "shop":
		open_shop_node(bool(node_data.get("black_market", false)))
	else:
		assert(node_data.has("enemy"), "戰鬥節點缺少 enemy 資料：%s" % node_data)
		var enemy: EnemyData = node_data["enemy"] as EnemyData
		start_next_battle(enemy)

func start_next_battle(enemy: EnemyData) -> void:
	battle = BattleController.new()
	battle.setup(run_state, selected_character, enemy)
	var mult: float = Ascension.enemy_hp_multiplier(run_state.ascension_level, Ascension.is_boss_id(enemy.id))
	if mult != 1.0:
		var scaled_max: int = max(1, int(round(float(battle.state["enemy_max_hp"]) * mult)))
		battle.state["enemy_max_hp"] = scaled_max
		battle.state["enemy_hp"] = scaled_max
		battle.enemy.max_hp = scaled_max
	battle_end_pending = false
	_build_battle_scene()
	_start_player_turn()

func _build_battle_scene() -> void:
	_set_background("res://assets/art/battle_bg.png")
	_clear_root()
	var viewport_size: Vector2 = get_viewport_rect().size
	_battle_compact = OS.has_feature("mobile") or viewport_size.y <= 500.0
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 4 if _battle_compact else 6)
	root.add_child(screen)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("f3ead2"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen.add_child(status_label)
	relic_strip = HBoxContainer.new()
	relic_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_strip.add_theme_constant_override("separation", 4)
	relic_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	screen.add_child(relic_strip)
	_refresh_relic_strip()
	var arena: HBoxContainer = HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 24)
	screen.add_child(arena)
	_build_bench_widget(arena)
	_build_player_widget(arena)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena.add_child(spacer)
	_build_enemy_widget(arena)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6 if _battle_compact else 14)
	screen.add_child(bottom)
	_build_left_dock(bottom)
	hand_row = HandFan.new()
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_row.custom_minimum_size = Vector2(0, 180 if _battle_compact else 290)
	hand_row.hand_base_lift = 80.0 if _battle_compact else 72.0
	bottom.add_child(hand_row)
	_build_right_dock(bottom)

func _build_bench_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(110, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	parent.add_child(col)
	bench_strip = col
	_refresh_bench_strip()  # 後排內容會在 _refresh_battle 持續刷新

func _refresh_bench_strip() -> void:
	if bench_strip == null or not is_instance_valid(bench_strip):
		return
	for child: Node in bench_strip.get_children():
		child.queue_free()
	if battle == null or run_state == null or run_state.characters.size() <= 1:
		return  # 單人隊不顯示 bench
	var players: Array = battle.state.get("players", []) as Array
	var active: int = int(battle.state.get("active_player_index", 0))
	for i: int in range(players.size()):
		if i == active:
			continue
		bench_strip.add_child(_bench_portrait(i, players[i] as Dictionary))

func _bench_portrait(index: int, player_data: Dictionary) -> Control:
	var character: CharacterData = run_state.characters[index] if index < run_state.characters.size() else null
	if character == null:
		return Control.new()
	var hp: int = int(player_data.get("hp", 0))
	var max_hp_v: int = int(player_data.get("max_hp", 1))
	var alive: bool = hp > 0
	var wrap: VBoxContainer = VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(96, 96)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	btn.disabled = not alive
	var border: Color = ThemeColors.BORDER_GOLD if alive else Color("5f6570", 0.5)
	var bg: Color = Color("18212f", 0.85) if alive else Color("0d121b", 0.85)
	btn.add_theme_stylebox_override("normal", UIFactory.style_box(bg, border, 1, 8))
	btn.add_theme_stylebox_override("hover", UIFactory.style_box(bg.lightened(0.1), ThemeColors.ACCENT_GOLD, 2, 8))
	btn.add_theme_stylebox_override("pressed", UIFactory.style_box(bg.darkened(0.1), ThemeColors.HIGHLIGHT_GOLD, 2, 8))
	btn.add_theme_stylebox_override("disabled", UIFactory.style_box(Color("0d121b", 0.6), Color("5f6570", 0.4), 1, 8))
	if alive:
		btn.pressed.connect(func() -> void: _on_bench_pressed(index))
	var portrait: TextureRect = UIFactory.portrait_rect(character.portrait_path, Vector2(84, 84), true)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	portrait.size = Vector2(84, 84)
	portrait.position = Vector2(-42, -42)
	if not alive:
		portrait.modulate = Color(0.0, 0.0, 0.0, 0.7)
	btn.add_child(portrait)
	UIFactory.ignore_child_mouse(btn)
	wrap.add_child(btn)
	var name_label: Label = UIFactory.card_label(character.display_name, 12, ThemeColors.TEXT_LIGHT if alive else ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	wrap.add_child(name_label)
	if alive:
		var hp_label: Label = UIFactory.card_label("HP %d/%d" % [hp, max_hp_v], 11, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
		wrap.add_child(hp_label)
	else:
		var ko_label: Label = UIFactory.card_label("倒下", 11, Color("c84a3a"), HORIZONTAL_ALIGNMENT_CENTER)
		wrap.add_child(ko_label)
	return wrap

func _on_bench_pressed(index: int) -> void:
	if battle == null:
		return
	var result: Dictionary = battle.switch_active(index)
	if not bool(result.get("changed", false)):
		var reason: String = String(result.get("reason", ""))
		if reason == "no_energy":
			battle.add_log("靈力不足，無法再換人。")
		elif reason == "dead":
			battle.add_log("該角色已倒下。")
		_refresh_battle()
		return
	# 切換成功 → 淡出舊肖像、換圖、淡入新肖像
	_animate_portrait_switch()

func _animate_portrait_switch() -> void:
	# 若前一個切換動畫還沒跑完，先中止並重設 alpha
	if _switch_tween != null and _switch_tween.is_valid():
		_switch_tween.kill()
		if player_portrait_image != null and is_instance_valid(player_portrait_image):
			player_portrait_image.modulate.a = 1.0
		if player_name_label != null and is_instance_valid(player_name_label):
			player_name_label.modulate.a = 1.0
	if player_portrait_image == null or not is_instance_valid(player_portrait_image):
		_refresh_battle()
		return
	_switch_tween = create_tween()
	_switch_tween.set_parallel(false)
	# Phase 1：淡出舊角色（0.13 s）
	_switch_tween.tween_property(player_portrait_image, "modulate:a", 0.0, 0.13) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if player_name_label != null and is_instance_valid(player_name_label):
		_switch_tween.parallel().tween_property(player_name_label, "modulate:a", 0.0, 0.10)
	# 中點：更新所有戰鬥數值（texture、HP、手牌等）；此時 alpha = 0 看不到 pop
	_switch_tween.tween_callback(_refresh_battle)
	# Phase 2：淡入新角色（0.18 s）
	_switch_tween.tween_property(player_portrait_image, "modulate:a", 1.0, 0.18) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	if player_name_label != null and is_instance_valid(player_name_label):
		_switch_tween.parallel().tween_property(player_name_label, "modulate:a", 1.0, 0.15)
	# 動畫結束：金色 flash 提示「新角色上場」
	_switch_tween.tween_callback(func() -> void:
		if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
			UIFactory.flash_node(player_portrait_wrap, Color(1.3, 1.2, 0.85), 0.35)
	)

func _build_player_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(160 if _battle_compact else 250, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 2 if _battle_compact else 4)
	parent.add_child(col)
	player_feedback_label = UIFactory.feedback_label()
	if _battle_compact:
		player_feedback_label.custom_minimum_size = Vector2(0, 0)
	col.add_child(player_feedback_label)
	var portrait_size: Vector2 = Vector2(120, 130) if _battle_compact else Vector2(220, 230)
	col.add_child(_portrait_with_block_badge(selected_character.portrait_path, portrait_size, true, true))
	player_name_label = UIFactory.card_label(selected_character.display_name, 18, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	if not _battle_compact:
		col.add_child(player_name_label)
	player_hp_bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	player_hp_bar.custom_minimum_size = Vector2(0, 12 if _battle_compact else 18)
	col.add_child(player_hp_bar)
	player_hp_value = UIFactory.card_label("", 11 if _battle_compact else 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(player_hp_value)
	player_status_line = UIFactory.card_label("", 11 if _battle_compact else 13, Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	player_status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(player_status_line)

func _build_enemy_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(170 if _battle_compact else 260, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 2 if _battle_compact else 4)
	parent.add_child(col)
	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 11 if _battle_compact else 16)
	enemy_label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	col.add_child(enemy_label)
	enemy_feedback_label = UIFactory.feedback_label()
	if _battle_compact:
		enemy_feedback_label.custom_minimum_size = Vector2(0, 0)
	col.add_child(enemy_feedback_label)
	var portrait_size: Vector2 = Vector2(120, 130) if _battle_compact else Vector2(230, 230)
	col.add_child(_portrait_with_block_badge(battle.enemy.portrait_path, portrait_size, true, false, battle.enemy.portrait_tint))
	enemy_name_label = UIFactory.card_label(battle.enemy.display_name, 18, Color("ffd9a3"), HORIZONTAL_ALIGNMENT_CENTER)
	if not _battle_compact:
		col.add_child(enemy_name_label)
	enemy_hp_bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	enemy_hp_bar.custom_minimum_size = Vector2(0, 12 if _battle_compact else 18)
	col.add_child(enemy_hp_bar)
	enemy_hp_value = UIFactory.card_label("", 11 if _battle_compact else 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(enemy_hp_value)
	enemy_status_line = UIFactory.card_label("", 11 if _battle_compact else 13, Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	enemy_status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(enemy_status_line)

func _build_left_dock(parent: HBoxContainer) -> void:
	var dock: VBoxContainer = VBoxContainer.new()
	dock.custom_minimum_size = Vector2(110 if _battle_compact else 140, 0)
	dock.size_flags_horizontal = 0
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 4 if _battle_compact else 8)
	parent.add_child(dock)
	energy_orb = EnergyOrb.new()
	var orb_sz: float = 68.0 if _battle_compact else 96.0
	energy_orb.custom_minimum_size = Vector2(orb_sz, orb_sz)
	energy_orb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dock.add_child(energy_orb)
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(110 if _battle_compact else 140, 36 if _battle_compact else 96)
	log_label.fit_content = not _battle_compact
	log_label.scroll_following = true
	log_label.bbcode_enabled = false
	log_label.add_theme_color_override("default_color", ThemeColors.TEXT_MUTED)
	log_label.add_theme_font_size_override("normal_font_size", 10 if _battle_compact else 12)
	dock.add_child(log_label)
	var btn_h: float = 26.0 if _battle_compact else 32.0
	var btn_f: int = 11 if _battle_compact else 13
	var deck_button: Button = _button("查看牌組")
	deck_button.add_theme_font_size_override("font_size", btn_f)
	deck_button.custom_minimum_size = Vector2(0, btn_h)
	deck_button.pressed.connect(show_deck_view)
	dock.add_child(deck_button)
	draw_pile_button = _button("抽牌堆 (0)")
	draw_pile_button.add_theme_font_size_override("font_size", btn_f)
	draw_pile_button.custom_minimum_size = Vector2(0, btn_h)
	draw_pile_button.pressed.connect(show_draw_pile_view)
	dock.add_child(draw_pile_button)
	var relics_button: Button = _button("遺物 (%d)" % run_state.relics.size())
	relics_button.add_theme_font_size_override("font_size", btn_f)
	relics_button.custom_minimum_size = Vector2(0, btn_h)
	relics_button.pressed.connect(_show_battle_relics_popup)
	dock.add_child(relics_button)

func _build_right_dock(parent: HBoxContainer) -> void:
	var dock: VBoxContainer = VBoxContainer.new()
	dock.custom_minimum_size = Vector2(110 if _battle_compact else 140, 0)
	dock.size_flags_horizontal = 0
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_theme_constant_override("separation", 4 if _battle_compact else 8)
	parent.add_child(dock)
	end_turn_button = Button.new()
	end_turn_button.text = "結束回合"
	var et_w: float = 108.0 if _battle_compact else 128.0
	var et_h: float = 52.0 if _battle_compact else 76.0
	var et_f: int = 15 if _battle_compact else 20
	end_turn_button.custom_minimum_size = Vector2(et_w, et_h)
	end_turn_button.add_theme_font_size_override("font_size", et_f)
	end_turn_button.add_theme_color_override("font_color", Color("fff5cf"))
	end_turn_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	end_turn_button.add_theme_stylebox_override("normal", UIFactory.style_box(Color("8a3a2e"), ThemeColors.HIGHLIGHT_GOLD, 3, 12))
	end_turn_button.add_theme_stylebox_override("hover", UIFactory.style_box(Color("a44a36"), Color("ffeab0"), 4, 12))
	end_turn_button.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("662a22"), ThemeColors.BORDER_GOLD, 3, 12))
	end_turn_button.add_theme_stylebox_override("disabled", UIFactory.style_box(Color("4a3530"), Color("786258"), 2, 12))
	end_turn_button.pressed.connect(end_player_turn)
	dock.add_child(end_turn_button)
	var btn_h: float = 26.0 if _battle_compact else 32.0
	var btn_f: int = 11 if _battle_compact else 13
	discard_pile_button = _button("棄牌堆 (0)")
	discard_pile_button.add_theme_font_size_override("font_size", btn_f)
	discard_pile_button.custom_minimum_size = Vector2(0, btn_h)
	discard_pile_button.pressed.connect(show_discard_pile_view)
	dock.add_child(discard_pile_button)
	exhausted_pile_button = _button("消耗堆 (0)")
	exhausted_pile_button.add_theme_font_size_override("font_size", btn_f)
	exhausted_pile_button.custom_minimum_size = Vector2(0, btn_h)
	exhausted_pile_button.pressed.connect(show_exhaust_pile_view)
	dock.add_child(exhausted_pile_button)

func _portrait_with_block_badge(path: String, portrait_size: Vector2, show_full: bool, is_player: bool, tint: Color = Color.WHITE) -> Control:
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = portrait_size
	var portrait: TextureRect = UIFactory.portrait_rect(path, portrait_size, show_full)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.modulate = tint
	wrap.add_child(portrait)
	var badge: BlockBadge = BlockBadge.new()
	badge.custom_minimum_size = Vector2(48, 56)
	badge.size = Vector2(48, 56)
	badge.position = Vector2(8, portrait_size.y - 64)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(badge)
	if is_player:
		player_block_badge = badge
		player_portrait_wrap = wrap
		player_portrait_image = portrait  # 保留 ref 給切換時動態換圖
	else:
		enemy_block_badge = badge
		enemy_portrait_wrap = wrap
	return wrap

func _refresh_relic_strip() -> void:
	if relic_strip == null:
		return
	for child: Node in relic_strip.get_children():
		child.queue_free()
	for r: RelicData in run_state.relics:
		var icon: RelicIcon = RelicIcon.new()
		icon.custom_minimum_size = Vector2(28, 28)
		relic_strip.add_child(icon)
		icon.set_relic(r)

func _grant_relic(relic: RelicData) -> bool:
	if relic == null:
		return false
	if run_state.has_relic(relic.id):
		return false
	run_state.add_relic(relic)
	return true

func _try_random_relic_drop(rarity_chance: float = 0.25) -> RelicData:
	if randf() > rarity_chance:
		return null
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()].clone()

func _start_player_turn() -> void:
	_clear_selected_hand_card()
	var result: Dictionary = battle.start_turn()
	_show_state_feedback(result["before_tick"])
	if _check_battle_end():
		return
	_refresh_battle(true)

func play_card(card: CardData, source_button: Button = null) -> void:
	if battle_end_pending:
		return
	_clear_selected_hand_card()
	_cancel_end_turn_warning()
	var result: Dictionary = battle.play_card(card)
	if not bool(result["affordable"]):
		_refresh_battle()
		return
	
	# Set temporary pose for action feedback
	if card.card_type == "attack":
		_temporary_player_pose = "attack"
	else:
		_temporary_player_pose = "cast"
	
	_pose_timer = get_tree().create_timer(0.4)
	var current_timer := _pose_timer
	current_timer.timeout.connect(func() -> void:
		if _pose_timer == current_timer:
			_temporary_player_pose = ""
			_refresh_battle()
	)
	if source_button != null and is_instance_valid(source_button):
		_detach_card_button(source_button)
		_refresh_battle()
		_animate_played_card(source_button, card)
	else:
		_refresh_battle()
	_show_state_feedback(result["before_card"])
	if bool(result["ended"]) and await _finish_battle_after_delay():
		return

func end_player_turn() -> void:
	if battle_end_pending:
		return
	_clear_selected_hand_card()
	if _end_turn_warning_id == 0 and int(battle.state["energy"]) > 0 and _has_affordable_card_in_hand():
		_show_end_turn_warning()
		return
	_end_turn_warning_id = 0
	end_turn_button.text = "結束回合"
	end_turn_button.disabled = true
	_animate_hand_discard()
	var action: Dictionary = battle.begin_enemy_phase()
	_show_enemy_action_preview(action)
	_refresh_battle()
	await get_tree().create_timer(0.8).timeout
	if CardFormat.action_has_damage(action):
		UIFactory.dash_node(enemy_portrait_wrap, Vector2(-1, 0), 36.0, 0.22)
		await get_tree().create_timer(0.1).timeout
	var result: Dictionary = battle.resolve_enemy_phase(action)
	_show_state_feedback(result["before_enemy"])
	_refresh_battle()
	if bool(result["ended"]) and await _finish_battle_after_delay():
		return
	await get_tree().create_timer(0.6).timeout
	_start_player_turn()

func _has_affordable_card_in_hand() -> bool:
	for card: CardData in battle.deck.hand:
		if battle.effective_card_cost(card) <= int(battle.state["energy"]):
			return true
	return false

func _show_end_turn_warning() -> void:
	_end_turn_warning_id += 1
	var my_id: int = _end_turn_warning_id
	end_turn_button.text = "再按確認\n剩 %d 點靈力" % int(battle.state["energy"])
	UIFactory.flash_node(end_turn_button, Color(1.4, 1.3, 1.0), 0.3)
	await get_tree().create_timer(1.0).timeout
	if _end_turn_warning_id != my_id:
		return
	end_player_turn()  # auto-confirm

func _cancel_end_turn_warning() -> void:
	if _end_turn_warning_id == 0:
		return
	_end_turn_warning_id = 0
	if is_instance_valid(end_turn_button):
		end_turn_button.text = "結束回合"

func _show_enemy_action_preview(action: Dictionary) -> void:
	var preview_lines: Array[String] = []
	preview_lines.append(String(action["intent"]))
	var effect_text: String = CardFormat.enemy_action_effect_summary(action)
	if not effect_text.is_empty():
		preview_lines.append(effect_text)
	_show_feedback(enemy_feedback_label, preview_lines, ThemeColors.ACCENT_GOLD)

func _check_battle_end() -> bool:
	if battle.is_victory():
		_complete_battle_victory()
		return true
	if battle.is_defeat():
		show_result(false)
		return true
	return false

func _finish_battle_after_delay() -> bool:
	if battle_end_pending:
		return true
	if not battle.is_battle_over():
		return false
	battle_end_pending = true
	_set_battle_input_enabled(false)
	await get_tree().create_timer(BATTLE_END_DELAY).timeout
	if battle.is_victory():
		_complete_battle_victory()
		return true
	if battle.is_defeat():
		show_result(false)
		return true
	return false

func _set_battle_input_enabled(enabled: bool) -> void:
	if end_turn_button != null:
		end_turn_button.disabled = not enabled
	for button: Button in card_buttons:
		if is_instance_valid(button):
			button.disabled = not enabled

func _complete_battle_victory() -> void:
	battle.complete_victory()
	Bestiary.mark_defeated(battle.enemy.id)
	var gold_reward: int = _battle_gold_reward(battle.enemy)
	# 聚寶盆：勝利額外金錢
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "battle_victory":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "gold_bonus":
					gold_reward += int(e.get("amount", 0))
	run_state.gold = run_state.gold + gold_reward
	battle.add_log("獲得 %d 枚銅錢。" % gold_reward)
	# Boss 必掉神器；一般戰鬥 25% 機率掉裝備
	var dropped: RelicData = null
	var was_boss: bool = Ascension.is_boss_id(battle.enemy.id)
	if was_boss:
		for a: RelicData in RelicCatalog.artifacts():
			if a.boss_id == battle.enemy.id and not run_state.has_relic(a.id):
				dropped = a.clone()
				break
		if dropped == null:
			dropped = _try_random_relic_drop(1.0)
	else:
		dropped = _try_random_relic_drop(0.25)
	if dropped != null:
		run_state.add_relic(dropped)
		battle.add_log("獲得裝備：%s" % dropped.display_name)
	run_state.encounter_index = run_state.encounter_index + 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		if run_state.act < 5:
			show_act_complete()
		else:
			show_result(true)
	else:
		show_card_reward()

func show_card_reward() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("戰鬥勝利", 34))
	box.add_child(UIFactory.paragraph("%s 擊敗了 %s。選擇 1 張卡加入牌組。" % [selected_character.display_name, battle.enemy.display_name]))
	box.add_child(UIFactory.paragraph("目前 HP %d/%d，銅錢 %d，牌組 %d 張。" % [run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size()]))
	var rewards: Array[CardData] = _make_reward_choices()
	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 12)
	box.add_child(reward_row)
	for reward: CardData in rewards:
		var reward_button: Button = _reward_card_button(reward)
		reward_button.pressed.connect(func(card: CardData = reward): choose_reward_card(card))
		reward_row.add_child(reward_button)
	var skip: Button = _button("跳過獎勵")
	skip.pressed.connect(show_progress_screen)
	box.add_child(skip)
	var deck_button: Button = _button("查看目前牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func _make_reward_choices() -> Array[CardData]:
	var pool: Array[CardData] = []
	var used_ids: Array[String] = []
	for card: CardData in selected_character.reward_pool:
		if not used_ids.has(card.id):
			used_ids.append(card.id)
			pool.append(card.clone())
	pool.shuffle()
	var count: int = 3
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "card_reward_count_bonus":
					count += int(e.get("amount", 0))
	var rewards: Array[CardData] = []
	for i: int in range(min(count, pool.size())):
		rewards.append(pool[i])
	return rewards

func choose_reward_card(card: CardData) -> void:
	run_state.deck.append(card.clone())
	show_progress_screen()

func _battle_gold_reward(enemy: EnemyData) -> int:
	var is_boss: bool = Ascension.is_boss_id(enemy.id)
	var base: int = 0
	if is_boss:
		match run_state.act:
			1: base = 80
			2: base = 120
			3: base = 160
			4: base = 200
			5: base = 250
			_: base = 80 + run_state.act * 40
	else:
		base = 18 + run_state.act * 8 + run_state.encounter_index * 3
	return max(0, int(round(float(base) * Ascension.gold_multiplier(run_state.ascension_level))))


func _route_node_button(node_data: Dictionary) -> Button:
	var node_type: String = String(node_data.get("type", "battle"))
	var button: Button
	if node_type == "rest":
		button = _route_rest_button()
	elif node_type == "event":
		button = _route_event_button()
	elif node_type == "shop":
		button = _route_shop_button(bool(node_data.get("black_market", false)))
	else:
		assert(node_data.has("enemy"), "戰鬥節點缺少 enemy 資料：%s" % node_data)
		var enemy: EnemyData = node_data["enemy"] as EnemyData
		button = _route_enemy_button(enemy, node_type == "boss")
	button.pressed.connect(func(): choose_route_node(node_data))
	return button

func _build_route_button(text: String, icon_type: String, icon_color: Color, font_color: Color = ThemeColors.TEXT_LIGHT) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon: MapNodeIcon = MapNodeIcon.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.set_type(icon_type, icon_color)
	box.add_child(icon)
	button.set_meta("route_icon", icon)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	button.set_meta("route_label", label)
	return button

func _animate_map_node(button: Button, selected: bool, selectable: bool, is_boss: bool) -> void:
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var target: Control = button
	if button.has_meta("route_icon"):
		target = button.get_meta("route_icon") as Control
	if target != null:
		target.pivot_offset = target.size * 0.5
	if selected:
		button.self_modulate = Color(1.12, 1.2, 1.05, 1.0)
	elif selectable:
		var glow: Tween = create_tween().set_loops()
		glow.tween_property(button, "self_modulate", Color(1.22, 1.18, 0.9, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glow.tween_property(button, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_boss and target != null:
		var pulse: Tween = create_tween().set_loops()
		pulse.tween_property(target, "scale", Vector2(1.12, 1.12), 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(target, "scale", Vector2.ONE, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _route_enemy_button(enemy: EnemyData, is_boss: bool = false) -> Button:
	var label_prefix: String = "Boss" if is_boss else "戰鬥"
	var text: String = "%s\n%s  HP %d\n%s" % [label_prefix, enemy.display_name, enemy.max_hp, _enemy_route_summary(enemy)]
	var icon_type: String = "boss" if is_boss else "battle"
	var icon_color: Color = Color("f8d29c") if is_boss else Color("e2c486")
	var button: Button = _build_route_button(text, icon_type, icon_color)
	var bg_color: Color = Color("452a35") if is_boss else ThemeColors.PANEL_NAVY
	button.add_theme_stylebox_override("normal", UIFactory.style_box(bg_color, ThemeColors.BORDER_GOLD, 2, 8))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(bg_color.lightened(0.14), ThemeColors.ACCENT_GOLD, 3, 8))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("1d2838"), Color("e4c66a"), 2, 8))
	return button

func _route_rest_button() -> Button:
	var heal_amount: int = EventData.rest_heal_for(selected_character.max_hp)
	var text: String = "休息\n回復 %d HP\n或升級 1 張牌" % heal_amount
	var button: Button = _build_route_button(text, "rest", Color("f4a13a"), Color("f4ffe9"))
	button.add_theme_stylebox_override("normal", UIFactory.style_box(Color("2f5f4a"), Color("c8e6c9"), 2, 8))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(Color("3d755d"), Color("eef9df"), 3, 8))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("244736"), Color("d8f0c4"), 2, 8))
	return button

func _route_event_button() -> Button:
	var button: Button = _build_route_button("奇遇\n山路異光\n選擇一項機緣", "event", Color("e2cdff"))
	button.add_theme_stylebox_override("normal", UIFactory.style_box(Color("4f3f73"), Color("d9c2ff"), 2, 8))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(Color("66508f"), Color("efe2ff"), 3, 8))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("382d55"), Color("d9c2ff"), 2, 8))
	return button

func _route_shop_button(is_black_shop: bool) -> Button:
	var title: String = "黑店" if is_black_shop else "商店"
	var hint: String = "高價珍品\n升級卡機率高" if is_black_shop else "購買卡牌\n補強牌組"
	var text: String = "%s\n%s\n銅錢 %d" % [title, hint, run_state.gold]
	var icon_type: String = "black_shop" if is_black_shop else "shop"
	var icon_color: Color = Color("e2a86b") if is_black_shop else Color("e4c66a")
	var button: Button = _build_route_button(text, icon_type, icon_color)
	var bg_color: Color = Color("2d2036") if is_black_shop else Color("5b4a2f")
	var border_color: Color = Color("e2a86b") if is_black_shop else Color("e4c66a")
	button.add_theme_stylebox_override("normal", UIFactory.style_box(bg_color, border_color, 2, 8))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(bg_color.lightened(0.14), ThemeColors.ACCENT_GOLD, 3, 8))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(bg_color.darkened(0.12), Color("d2b96b"), 2, 8))
	return button

func _enemy_route_summary(enemy: EnemyData) -> String:
	var badges: Array[String] = []
	for action: Dictionary in enemy.actions:
		var badge: String = CardFormat.intent_badge(action)
		for part: String in badge.split(" "):
			if not badges.has(part):
				badges.append(part)
	return " ".join(badges)

func resolve_rest_node() -> void:
	run_state.pending_rest_heal = EventData.rest_heal_for(selected_character.max_hp)
	show_rest_node()

func show_rest_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(_title("清修片刻", 32))
	box.add_child(UIFactory.paragraph("溪聲入耳，山風洗塵。你可以調息療傷，也可以靜心打磨一式招法。"))
	box.add_child(UIFactory.paragraph("%s  HP %d/%d  銅錢 %d  可升級 %d 張牌" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, _upgradeable_cards().size()]))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(row)
	row.add_child(_event_choice_button("調息", "回復 %d 點生命" % run_state.pending_rest_heal, false, resolve_rest_heal))
	row.add_child(_event_choice_button("打磨", "升級 1 張招式", _upgradeable_cards().is_empty(), show_upgrade_card_view))
	row.add_child(_event_choice_button("翻閱", "查看當前手札", false, show_deck_view))

func resolve_rest_heal() -> void:
	var bonus: int = 0
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "rest_heal_bonus":
					bonus += int(e.get("amount", 0))
	run_state.heal(run_state.pending_rest_heal + bonus)
	run_state.pending_rest_heal = 0
	advance_non_battle_node()

func show_event_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	box.add_child(_title(String(event_data["title"]), 32))
	box.add_child(UIFactory.paragraph(String(event_data["flavor"])))
	box.add_child(_event_status_strip())
	var heal_amount: int = int(event_data["heal"])
	var gain_cost: int = int(event_data["gain_cost"])
	var power_gain: int = int(event_data["power"])
	var choices_list: Array = event_data.get("choices", ["heal", "gain_card", "power", "upgrade", "remove", "view_deck"])
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for choice_key: Variant in choices_list:
		match String(choice_key):
			"heal":
				grid.add_child(_event_choice_button("調息", "回復 %d 點生命" % heal_amount,
					heal_amount <= 0, func() -> void: resolve_event_heal(heal_amount)))
			"gain_card":
				grid.add_child(_event_choice_button("探取", "失去 %d HP，得 1 張招式" % gain_cost,
					false, func() -> void: resolve_event_gain_card(gain_cost)))
			"power":
				grid.add_child(_event_choice_button(String(event_data["power_label"]),
					"本輪增傷 +%d" % power_gain,
					false, func() -> void: resolve_event_power(power_gain)))
			"upgrade":
				grid.add_child(_event_choice_button("悟法", "升級 1 張招式",
					_upgradeable_cards().is_empty(), show_upgrade_card_view))
			"remove":
				grid.add_child(_event_choice_button("洗髓", "移除 1 張招式",
					run_state.deck.size() <= 5, show_remove_card_view))
			"view_deck":
				grid.add_child(_event_choice_button("翻閱", "查看當前手札", false, show_deck_view))
			"pact":
				var pc: int = int(event_data.get("pact_max_hp_cost", 8))
				var pp: int = int(event_data.get("pact_power", 4))
				grid.add_child(_event_choice_button(String(event_data["power_label"]),
					"最大 HP -%d，永久增傷 +%d" % [pc, pp], false, _resolve_yokai_pact))
			"gamble":
				var ww: int = int(event_data.get("gamble_win_power", 5))
				var ld: int = int(event_data.get("gamble_lose_damage", 10))
				grid.add_child(_event_choice_button(String(event_data["power_label"]),
					"五成增傷 +%d，五成損血 %d" % [ww, ld], false, _resolve_ghost_gamble))
			"tainted_power":
				var td: int = int(event_data.get("taint_damage", 6))
				grid.add_child(_event_choice_button(String(event_data["power_label"]),
					"增傷 +%d，但損血 %d" % [power_gain, td], false, _resolve_tainted_power))

func _get_event_outcome(event_data: Dictionary, key: String) -> String:
	return String((event_data.get("outcomes", {}) as Dictionary).get(key, ""))

func _show_event_outcome(text: String, on_continue: Callable) -> void:
	var overlay: PanelContainer = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	var bg: StyleBoxFlat = UIFactory.style_box(Color(0, 0, 0, 0.68), Color(0, 0, 0, 0), 0, 0)
	overlay.add_theme_stylebox_override("panel", bg)
	root.add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 0)
	var card_style: StyleBoxFlat = UIFactory.style_box(ThemeColors.PANEL_NAVY, ThemeColors.BORDER_GOLD, 1, 8)
	card_style.content_margin_left = 28
	card_style.content_margin_right = 28
	card_style.content_margin_top = 24
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	var lbl: Label = UIFactory.paragraph(text)
	lbl.custom_minimum_size = Vector2(384, 0)
	vbox.add_child(lbl)
	var continue_button: Button = _button("繼續")
	continue_button.pressed.connect(func() -> void:
		overlay.queue_free()
		on_continue.call())
	vbox.add_child(continue_button)

func _resolve_yokai_pact() -> void:
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var cost: int = int(event_data.get("pact_max_hp_cost", 8))
	var power: int = int(event_data.get("pact_power", 4))
	run_state.max_hp = max(1, run_state.max_hp - cost)
	if run_state.hp > run_state.max_hp:
		run_state.hp = run_state.max_hp
	run_state.power_bonus += power
	var outcome: String = _get_event_outcome(event_data, "pact")
	if not outcome.is_empty():
		_show_event_outcome(outcome, advance_non_battle_node)
	else:
		advance_non_battle_node()

func _resolve_tainted_power() -> void:
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	run_state.power_bonus += int(event_data["power"])
	run_state.take_damage(int(event_data.get("taint_damage", 6)))
	var outcome: String = _get_event_outcome(event_data, "tainted_power")
	if not outcome.is_empty():
		_show_event_outcome(outcome, advance_non_battle_node)
	else:
		advance_non_battle_node()

func _resolve_ghost_gamble() -> void:
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var win_power: int = int(event_data.get("gamble_win_power", 5))
	var lose_damage: int = int(event_data.get("gamble_lose_damage", 10))
	var won: bool = randf() < 0.5
	var outcome_key: String = "gamble_win" if won else "gamble_lose"
	if won:
		run_state.power_bonus += win_power
	else:
		run_state.take_damage(lose_damage)
	var outcome: String = _get_event_outcome(event_data, outcome_key)
	if not outcome.is_empty():
		_show_event_outcome(outcome, advance_non_battle_node)
	else:
		advance_non_battle_node()

func _event_status_strip() -> PanelContainer:
	# 奇遇頁狀態列：深色底板 + HP 條 + 金幣 + 牌組數 + 增傷（獨立於敘事文字）
	var container: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = UIFactory.style_box(ThemeColors.PANEL_NAVY, Color("1a1a1f"), 1, 6)
	container.add_theme_stylebox_override("panel", style)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.custom_minimum_size = Vector2(0, 36)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	container.add_child(hbox)
	# HP bar + text
	var bar: ProgressBar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	bar.custom_minimum_size = Vector2(72, 12)
	bar.max_value = run_state.max_hp
	bar.value = run_state.hp
	hbox.add_child(bar)
	var hp_lbl: Label = UIFactory.card_label(
		"HP %d / %d" % [run_state.hp, run_state.max_hp],
		13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	hbox.add_child(hp_lbl)
	# dot separator
	hbox.add_child(UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# gold
	hbox.add_child(UIFactory.card_label("銅錢 %d" % run_state.gold, 13, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	# dot separator
	hbox.add_child(UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	# deck count
	hbox.add_child(UIFactory.card_label("牌組 %d" % run_state.deck.size(), 13, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	# power bonus – only show when non-zero
	if run_state.power_bonus > 0:
		hbox.add_child(UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		hbox.add_child(UIFactory.card_label("增傷 +%d" % run_state.power_bonus, 13, Color("88c8ff"), HORIZONTAL_ALIGNMENT_LEFT))
	return container

func _event_choice_button(title: String, subtitle: String, disabled: bool, on_press: Callable) -> Button:
	# 文青卡片式按鈕：水墨紙底色 + 細金邊 + 標題下細分隔線 + 副標小字
	# 兩兩排列在 GridContainer 裡，hover 時邊框轉暖、bg 微亮
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(260, 84)
	btn.disabled = disabled
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	var bg_normal: Color = Color("f3ede2", 0.88)
	var bg_hover: Color = Color("faf5ec", 0.96)
	var bg_pressed: Color = Color("e7dece", 0.95)
	var bg_disabled: Color = Color("a89e88", 0.30)
	var border_normal: Color = Color("c8b46f", 0.65)
	var border_hover: Color = Color("e4c66a", 0.95)
	var border_pressed: Color = Color("c8b46f", 0.95)
	var border_disabled: Color = Color("8a8576", 0.35)
	btn.add_theme_stylebox_override("normal", _event_card_style(bg_normal, border_normal, 1))
	btn.add_theme_stylebox_override("hover", _event_card_style(bg_hover, border_hover, 2))
	btn.add_theme_stylebox_override("pressed", _event_card_style(bg_pressed, border_pressed, 2))
	btn.add_theme_stylebox_override("disabled", _event_card_style(bg_disabled, border_disabled, 1))
	var stack: VBoxContainer = VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation", 4)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(stack)
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("3a2f1c") if not disabled else Color("6f6a5d"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title_label)
	var divider: PanelContainer = PanelContainer.new()
	divider.custom_minimum_size = Vector2(48, 1)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var divider_style: StyleBoxFlat = StyleBoxFlat.new()
	divider_style.bg_color = Color("c8b46f", 0.55) if not disabled else Color("8a8576", 0.3)
	divider.add_theme_stylebox_override("panel", divider_style)
	stack.add_child(divider)
	var subtitle_label: Label = Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color("574b34") if not disabled else Color("7c7768"))
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(subtitle_label)
	if not disabled:
		btn.pressed.connect(on_press)
	return btn

func _event_card_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(2)  # 接近直角的薄圓角，文青風
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func resolve_event_heal(amount: int) -> void:
	run_state.heal(amount)
	var ev: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var outcome: String = _get_event_outcome(ev, "heal")
	if not outcome.is_empty():
		_show_event_outcome(outcome, advance_non_battle_node)
	else:
		advance_non_battle_node()

func resolve_event_gain_card(hp_cost: int = 6) -> void:
	run_state.take_damage(hp_cost)
	var ev: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var outcome: String = _get_event_outcome(ev, "gain_card")
	if not outcome.is_empty():
		_show_event_outcome(outcome, func() -> void: show_event_card_reward(hp_cost))
	else:
		show_event_card_reward(hp_cost)

func show_event_card_reward(hp_cost_paid: int) -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("探取", 34))
	box.add_child(UIFactory.paragraph("已失去 %d 點生命。選擇 1 張招式加入牌組。" % hp_cost_paid))
	box.add_child(UIFactory.paragraph("目前 HP %d/%d，牌組 %d 張。" % [run_state.hp, selected_character.max_hp, run_state.deck.size()]))
	var rewards: Array[CardData] = _make_reward_choices()
	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 12)
	box.add_child(reward_row)
	for reward: CardData in rewards:
		var reward_button: Button = _reward_card_button(reward)
		reward_button.pressed.connect(func(card: CardData = reward): _choose_event_card(card))
		reward_row.add_child(reward_button)
	var deck_button: Button = _button("查看目前牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func _choose_event_card(card: CardData) -> void:
	run_state.deck.append(card.clone())
	advance_non_battle_node()

func resolve_event_power(amount: int = 1) -> void:
	var bonus: int = 0
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "event_power_bonus":
					bonus += int(e.get("amount", 0))
	run_state.power_bonus = run_state.power_bonus + amount + bonus
	var ev_p: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var outcome_p: String = _get_event_outcome(ev_p, "power")
	if not outcome_p.is_empty():
		_show_event_outcome(outcome_p, advance_non_battle_node)
	else:
		advance_non_battle_node()

func open_shop_node(is_black_shop: bool) -> void:
	run_state.current_shop_is_black = is_black_shop
	run_state.current_shop_inventory = _make_shop_inventory(is_black_shop)
	show_shop_node()

func show_shop_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title_text: String = "夜路黑店" if run_state.current_shop_is_black else "山道商店"
	var flavor_text: String = "簾後藏著來路不明的珍品，價格狠，成色也狠。" if run_state.current_shop_is_black else "行商在山道旁支起小攤，貨色普通但價格公道。"
	box.add_child(_title(title_text, 34))
	box.add_child(UIFactory.paragraph(flavor_text))
	box.add_child(UIFactory.paragraph("%s  HP %d/%d  銅錢 %d  牌組 %d 張" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold, run_state.deck.size()]))
	var goods_row: HBoxContainer = HBoxContainer.new()
	goods_row.add_theme_constant_override("separation", 12)
	box.add_child(goods_row)
	for item: Dictionary in run_state.current_shop_inventory:
		goods_row.add_child(_shop_item_view(item))
	# 商店多賣 1 件裝備（每次進商店重抽）
	if not run_state.has_meta("shop_relic_offered_at_index") or int(run_state.get_meta("shop_relic_offered_at_index", -1)) != run_state.encounter_index:
		run_state.set_meta("shop_relic_offered_at_index", run_state.encounter_index)
		run_state.set_meta("shop_relic_id", _pick_shop_relic_id())
	var shop_relic_id: String = String(run_state.get_meta("shop_relic_id", ""))
	if not shop_relic_id.is_empty() and not run_state.has_relic(shop_relic_id):
		var relic: RelicData = RelicCatalog.by_id(shop_relic_id)
		if relic != null:
			goods_row.add_child(_shop_relic_view(relic))
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(bottom_row)
	bottom_row.add_child(_event_choice_button("翻閱", "查看當前手札", false, show_deck_view))
	bottom_row.add_child(_event_choice_button("離店", "收手回程", false, advance_non_battle_node))

func _pick_shop_relic_id() -> String:
	var pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			pool.append(r)
	if run_state.current_shop_is_black:
		# 黑店 30% 機率出角色專武
		var weapon_pool: Array[RelicData] = RelicCatalog.weapons_for_character(selected_character.id)
		var avail_weapons: Array[RelicData] = []
		for w: RelicData in weapon_pool:
			if not run_state.has_relic(w.id):
				avail_weapons.append(w)
		if not avail_weapons.is_empty() and randf() < 0.3:
			return avail_weapons[randi() % avail_weapons.size()].id
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()].id

func _shop_relic_view(relic: RelicData) -> Control:
	var price: int = _shop_relic_price(relic)
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(230, 338)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var icon: RelicIcon = RelicIcon.new()
	icon.custom_minimum_size = Vector2(80, 80)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	icon.set_relic(relic)
	box.add_child(UIFactory.card_label(relic.display_name, 17, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIFactory.card_label(relic.description, 12, Color("d8e0ec"), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIFactory.card_label("價格：%d 銅錢" % price, 14, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var can_buy: bool = run_state.gold >= price
	var buy_button: Button = _button("買下裝備")
	buy_button.disabled = not can_buy
	buy_button.pressed.connect(func(): _buy_shop_relic(relic, price))
	box.add_child(buy_button)
	return panel

func _shop_relic_price(relic: RelicData) -> int:
	var base: int = 70
	match relic.rarity:
		"uncommon":
			base = 95
		"rare":
			base = 130
		"legendary":
			base = 180
	if run_state.current_shop_is_black:
		base = int(base * 1.2)
	# 通寶錢折扣
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "shop_discount":
					base -= int(e.get("amount", 0))
	return max(10, base)

func _buy_shop_relic(relic: RelicData, price: int) -> void:
	if run_state.gold < price:
		return
	run_state.gold -= price
	run_state.add_relic(relic)
	run_state.set_meta("shop_relic_id", "")  # 清掉這次的商店裝備
	show_shop_node()

func _shop_item_view(item: Dictionary) -> Control:
	var card: CardData = item["card"] as CardData
	var price: int = int(item["price"])
	# 通寶錢折扣
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "shop_discount":
					price = max(5, price - int(e.get("amount", 0)))
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(230, 338)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var can_buy: bool = run_state.gold >= price
	var card_button: Button = _make_card_button(card, card.cost, Vector2(210, 270), can_buy, true)
	card_button.disabled = not can_buy
	card_button.pressed.connect(func(): buy_shop_card(card, price))
	box.add_child(card_button)
	var price_label: Label = UIFactory.card_label("價格：%d 銅錢" % price, 15, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(price_label)
	var buy_button: Button = _button("買下")
	buy_button.disabled = not can_buy
	buy_button.pressed.connect(func(): buy_shop_card(card, price))
	box.add_child(buy_button)
	return panel

func buy_shop_card(card: CardData, price: int) -> void:
	if run_state.gold < price:
		return
	run_state.gold = run_state.gold - price
	run_state.deck.append(card.clone())
	for i: int in range(run_state.current_shop_inventory.size()):
		var item_card: CardData = run_state.current_shop_inventory[i]["card"] as CardData
		if item_card == card:
			run_state.current_shop_inventory.remove_at(i)
			break
	show_shop_node()

func _make_shop_inventory(is_black_shop: bool) -> Array[Dictionary]:
	return ShopInventory.build(selected_character, is_black_shop)

func show_remove_card_view() -> void:
	if run_state.deck.size() <= 5:
		return
	show_deck_view("remove")

func show_upgrade_card_view() -> void:
	if _upgradeable_cards().is_empty():
		return
	show_deck_view("upgrade")

func remove_card_from_deck(card: CardData) -> void:
	if run_state.deck.size() <= 5:
		close_deck_view()
		return
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck.remove_at(i)
			break
	close_deck_view()
	advance_non_battle_node()

func upgrade_card_in_deck(card: CardData) -> void:
	if card.upgraded:
		return
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck[i] = card.upgraded_copy()
			break
	close_deck_view()
	advance_non_battle_node()

func _upgradeable_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card: CardData in run_state.deck:
		if not card.upgraded:
			cards.append(card)
	return cards

func advance_non_battle_node() -> void:
	run_state.encounter_index = run_state.encounter_index + 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		if run_state.act < 5:
			show_act_complete()
		else:
			show_result(true)
	else:
		show_progress_screen()

func show_act_complete() -> void:
	var completed_act: int = run_state.act
	for i: int in range(run_state.characters.size()):
		run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + ACT_HEAL_AMOUNT)
	run_state.act = completed_act + 1
	run_state.encounter_index = 0
	run_state.chosen_map_path.clear()
	run_state.encounter_choices = _make_encounter_choices()
	SaveManager.save(run_state)
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(_title("第%s幕完成" % _act_numeral(completed_act), 38))
	var sub: Label = _title(_act_title(completed_act), 22)
	sub.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(sub)
	box.add_child(UIFactory.paragraph(_act_complete_flavor(completed_act)))
	box.add_child(UIFactory.paragraph("所有角色恢復 %d 點生命。" % ACT_HEAL_AMOUNT))
	var hp_parts: Array[String] = []
	for i: int in range(run_state.characters.size()):
		var c: CharacterData = run_state.characters[i]
		hp_parts.append("%s HP %d/%d" % [c.display_name, run_state.character_hps[i], run_state.character_max_hps[i]])
	box.add_child(UIFactory.paragraph("  ".join(hp_parts)))
	var next_name: String = _act_next_name(completed_act)
	var continue_btn: Button = _button("前往%s →" % next_name)
	continue_btn.pressed.connect(func() -> void: show_progress_screen())
	box.add_child(continue_btn)
	var menu_btn: Button = _button("返回主選單")
	menu_btn.pressed.connect(func() -> void:
		SaveManager.clear()
		show_main_menu())
	box.add_child(menu_btn)

func _act_numeral(act: int) -> String:
	match act:
		1: return "一"
		2: return "二"
		3: return "三"
		4: return "四"
		5: return "五"
	return str(act)

func _act_title(act: int) -> String:
	match act:
		1: return "余杭山間"
		2: return "蘇州地底"
		3: return "苗疆蠱土"
		4: return "鎖妖塔"
		5: return "拜月決戰"
	return ""

func _act_complete_flavor(act: int) -> String:
	match act:
		1: return "余杭山間的惡徒已被驅散，一行人踏上了通往蘇州的路途——誰知更大的困境正在前方等待。"
		2: return "離開蘇州地底的殭屍之地，穿越險峻山路，苗疆蠱土的神秘與危險已在眼前。"
		3: return "苗疆的蠱毒危機雖已解除，但真正的威脅遠不止如此，眾人向鎖妖塔進發，決意斬草除根。"
		4: return "鎖妖塔的封印被破，邪神即將甦醒！為阻止拜月教主完成邪法，必須立刻趕赴教壇，決一死戰。"
	return ""

func _act_next_name(act: int) -> String:
	match act:
		1: return "蘇州地底"
		2: return "苗疆蠱土"
		3: return "鎖妖塔"
		4: return "拜月決戰"
	return "下一幕"

func show_deck_view(mode: String = "view", custom_cards = null, custom_title: String = "") -> void:
	close_deck_view()
	deck_view_mode = mode
	deck_overlay = PanelContainer.new()
	deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_overlay.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0b111a", 0.94), ThemeColors.BORDER_GOLD, 2, 8))
	add_child(deck_overlay)
	var outer: MarginContainer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 34)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_right", 34)
	outer.add_theme_constant_override("margin_bottom", 28)
	deck_overlay.add_child(outer)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	outer.add_child(box)
	
	var title_text: String = "目前牌組"
	if not custom_title.is_empty():
		title_text = custom_title
	elif deck_view_mode == "remove":
		title_text = "選擇要移除的牌"
	elif deck_view_mode == "upgrade":
		title_text = "選擇要升級的牌"
	box.add_child(_title(title_text, 32))
	
	var target_cards: Array
	if custom_cards == null:
		target_cards = run_state.deck
	else:
		target_cards = custom_cards
		
	var count_text: String = "%s  HP %d/%d  銅錢 %d" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold]
	if custom_cards == null:
		count_text += "  共 %d 張牌" % run_state.deck.size()
	else:
		count_text += "  共 %d 張牌" % target_cards.size()
	box.add_child(UIFactory.paragraph(count_text))
	
	var summary: Label = UIFactory.paragraph(_deck_summary_text(target_cards, custom_cards == null))
	box.add_child(summary)
	
	if deck_view_mode == "remove":
		box.add_child(UIFactory.paragraph("至少保留 5 張牌。點選一張牌後會移除並完成事件。"))
	elif deck_view_mode == "upgrade":
		box.add_child(UIFactory.paragraph("點選一張未升級的牌，升級後會完成此節點。每張卡下方標註升級後的數值。"))
		
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	
	var grouped: Array[Dictionary] = _group_and_sort_cards(target_cards)
	for item in grouped:
		var card: CardData = item["card"] as CardData
		var count: int = item["count"]
		grid.add_child(_deck_view_card(card, deck_view_mode, count))
		
	var close_button: Button = _button("關閉")
	close_button.pressed.connect(close_deck_view)
	box.add_child(close_button)

func close_deck_view() -> void:
	if deck_overlay != null:
		deck_overlay.queue_free()
		deck_overlay = null
	deck_view_mode = "view"

func show_draw_pile_view() -> void:
	if battle == null or battle.deck == null:
		return
	show_deck_view("view", battle.deck.draw_pile, "抽牌堆")

func show_discard_pile_view() -> void:
	if battle == null or battle.deck == null:
		return
	show_deck_view("view", battle.deck.discard_pile, "棄牌堆")

func show_exhaust_pile_view() -> void:
	if battle == null or battle.deck == null:
		return
	show_deck_view("view", battle.deck.exhausted_pile, "消耗堆")

func _group_and_sort_cards(cards: Array) -> Array[Dictionary]:
	var groups: Dictionary = {}
	var order: Array[String] = []
	for card: CardData in cards:
		var key: String = card.id + "_upgraded_" + str(card.upgraded)
		if not groups.has(key):
			groups[key] = {
				"card": card,
				"count": 0
			}
			order.append(key)
		groups[key]["count"] += 1
	
	var sorted_groups: Array[Dictionary] = []
	for key in order:
		sorted_groups.append(groups[key])
	
	sorted_groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca: CardData = a["card"] as CardData
		var cb: CardData = b["card"] as CardData
		
		var type_score = func(t: String) -> int:
			match t:
				"power": return 1
				"skill": return 2
				"attack": return 3
			return 4
		
		var score_a: int = type_score.call(ca.card_type)
		var score_b: int = type_score.call(cb.card_type)
		if score_a != score_b:
			return score_a < score_b
			
		var title_a: String = ca.display_title()
		var title_b: String = cb.display_title()
		if title_a != title_b:
			return title_a < title_b
			
		if ca.upgraded != cb.upgraded:
			return not ca.upgraded
			
		return false
	)
	
	return sorted_groups

func _deck_summary_text(target_cards: Array, is_main_deck: bool) -> String:
	var attack_count: int = 0
	var skill_count: int = 0
	var power_count: int = 0
	for card: CardData in target_cards:
		match card.card_type:
			"attack":
				attack_count = attack_count + 1
			"skill":
				skill_count = skill_count + 1
			"power":
				power_count = power_count + 1
	var dup_summary: String = _duplicate_summary_text(target_cards)
	if is_main_deck:
		return "攻擊 %d    技能 %d    能力 %d    可升級 %d\n%s" % [attack_count, skill_count, power_count, _upgradeable_cards().size(), dup_summary]
	else:
		return "攻擊 %d    技能 %d    能力 %d\n%s" % [attack_count, skill_count, power_count, dup_summary]

func _duplicate_summary_text(target_cards: Array) -> String:
	var counts: Dictionary = {}
	var names: Dictionary = {}
	for card: CardData in target_cards:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
		names[card.id] = card.display_title()
	var parts: Array[String] = []
	for id_variant: Variant in counts.keys():
		var id: String = String(id_variant)
		var count: int = int(counts[id])
		if count > 1:
			parts.append("%s x%d" % [String(names[id]), count])
	if parts.is_empty():
		return "重複：無"
	return "重複：" + "，".join(parts)

func _deck_view_card(card: CardData, mode: String = "view", count: int = 1) -> Control:
	var selectable: bool = mode == "remove" or (mode == "upgrade" and not card.upgraded)
	var visually_enabled: bool = mode != "upgrade" or not card.upgraded
	var button: Button = _make_card_button(card, card.cost, Vector2(190, 260), true, visually_enabled)
	button.disabled = not selectable
	if mode == "remove":
		button.pressed.connect(func(): remove_card_from_deck(card))
	elif mode == "upgrade" and not card.upgraded:
		button.pressed.connect(func(): upgrade_card_in_deck(card))
	else:
		button.add_theme_stylebox_override("disabled", UIFactory.style_box(CardFormat.card_color(card.card_type, true), Color("e7d38a"), 2, 8))
		button.add_theme_color_override("font_disabled_color", ThemeColors.TEXT_LIGHT)
	
	if count > 1:
		var badge: PanelContainer = PanelContainer.new()
		badge.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0b111a"), ThemeColors.BORDER_GOLD, 2, 6))
		badge.custom_minimum_size = Vector2(32, 32)
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -28
		badge.offset_top = -6
		badge.offset_right = 4
		badge.offset_bottom = 26
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var badge_label: Label = UIFactory.card_label("x%d" % count, 12, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(badge_label)
		button.add_child(badge)
		
	if mode == "upgrade" and not card.upgraded:
		var wrap: VBoxContainer = VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 4)
		wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		wrap.add_child(button)
		wrap.add_child(_upgrade_preview_panel(card))
		return wrap
	return button

func _upgrade_preview_panel(card: CardData) -> Control:
	var upgraded: CardData = card.upgraded_copy()
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("f3ede2", 0.16)
	style.border_color = Color("c8b46f", 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var title: Label = Label.new()
	title.text = "升級後 → %s" % upgraded.display_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	var desc: Label = Label.new()
	desc.text = upgraded.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(174, 0)
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	box.add_child(desc)
	return panel

func show_result(victory: bool) -> void:
	if victory:
		Ascension.mark_cleared(run_state.ascension_level)
		SaveManager.clear()
	# 失敗時暫時保留存檔，retry 用得到；其他按鈕的 callback 會自己 clear
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	if victory:
		box.add_child(_title("通關！仙劍成道", 34))
		box.add_child(UIFactory.paragraph("%s 歷經五幕征途，終於擊敗了拜月教主，守護了天下蒼生。\n最終 HP %d/%d，剩餘銅錢 %d。" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold]))
	else:
		box.add_child(_title("戰鬥失敗", 34))
		box.add_child(UIFactory.paragraph("%s 敗於 %s。調整出牌節奏再試一次。" % [selected_character.display_name, battle.enemy.display_name]))
		var general_count: int = 0
		for r: RelicData in run_state.relics:
			if r.slot == "general":
				general_count += 1
		var retry_text: String = "重打這一場 (滿血，扣 1 件遺物)" if general_count > 0 else "重打這一場 (滿血)"
		var retry_battle: Button = _button(retry_text)
		retry_battle.pressed.connect(_retry_current_battle)
		box.add_child(retry_battle)
	var retry_run: Button = _button("重新開始此角色")
	retry_run.pressed.connect(func() -> void:
		SaveManager.clear()
		start_run(selected_character))
	box.add_child(retry_run)
	var select: Button = _button("重新選擇角色")
	select.pressed.connect(func() -> void:
		SaveManager.clear()
		show_character_select())
	box.add_child(select)
	var menu: Button = _button("返回主選單")
	menu.pressed.connect(func() -> void:
		SaveManager.clear()
		show_main_menu())
	box.add_child(menu)

func _make_battle_popup() -> PopupPanel:
	var popup: PopupPanel = PopupPanel.new()
	popup.exclusive = false
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(ThemeColors.OVERLAY_BG.r, ThemeColors.OVERLAY_BG.g, ThemeColors.OVERLAY_BG.b, 0.97)
	panel_style.border_color = ThemeColors.BORDER_GOLD
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	popup.add_theme_stylebox_override("panel", panel_style)
	return popup

func _show_battle_relics_popup() -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(460, 0)
	var title: Label = Label.new()
	title.text = "遺物清單 (%d)" % run_state.relics.size()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	if run_state.relics.is_empty():
		var empty: Label = Label.new()
		empty.text = "尚未持有任何遺物"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		box.add_child(empty)
	else:
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(440, 420)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		var list: VBoxContainer = VBoxContainer.new()
		list.add_theme_constant_override("separation", 8)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for r: RelicData in run_state.relics:
			list.add_child(_relic_popup_entry(r))
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()

func _show_map_status_popup() -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(460, 0)
	var title: Label = Label.new()
	title.text = "角色狀態"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	# 多角色隊伍：每人各一行 HP；單人沿用舊格式
	if run_state.characters.size() > 1:
		var total_deck: int = 0
		for cdeck_v: Variant in run_state.character_decks:
			total_deck += (cdeck_v as Array).size()
		box.add_child(UIFactory.paragraph("銅錢 %d  ·  牌組共 %d 張" % [run_state.gold, total_deck]))
		for i: int in range(run_state.characters.size()):
			var c: CharacterData = run_state.characters[i]
			var hp_i: int = run_state.character_hps[i]
			var max_hp_i: int = run_state.character_max_hps[i]
			var deck_i: int = (run_state.character_decks[i] as Array).size()
			var pb_i: int = run_state.character_power_bonus[i]
			var prefix: String = "★ " if i == 0 else "   "
			var status: String = "倒下" if hp_i <= 0 else "HP %d/%d" % [hp_i, max_hp_i]
			box.add_child(UIFactory.paragraph("%s%s  %s  牌組 %d  增傷 +%d" % [prefix, c.display_name, status, deck_i, pb_i]))
	else:
		box.add_child(UIFactory.paragraph("%s  HP %d/%d  銅錢 %d  牌組 %d 張  本輪增傷 +%d" % [
			selected_character.display_name,
			run_state.hp,
			selected_character.max_hp,
			run_state.gold,
			run_state.deck.size(),
			run_state.power_bonus
		]))
	if run_state.map_seed != 0:
		box.add_child(UIFactory.paragraph("種子 %d  ·  難度 A%d" % [run_state.map_seed, run_state.ascension_level]))
	var passive_text: String = _passive_text()
	if not passive_text.is_empty():
		box.add_child(UIFactory.paragraph(passive_text))
	if run_state.relics.is_empty():
		box.add_child(UIFactory.paragraph("目前沒有遺物。"))
	else:
		var relic_title: Label = Label.new()
		relic_title.text = "遺物"
		relic_title.add_theme_font_size_override("font_size", 16)
		relic_title.add_theme_color_override("font_color", ThemeColors.HIGHLIGHT_GOLD)
		box.add_child(relic_title)
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(440, 320)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		var list: VBoxContainer = VBoxContainer.new()
		list.add_theme_constant_override("separation", 8)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for relic: RelicData in run_state.relics:
			list.add_child(_relic_popup_entry(relic))
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()

func _relic_popup_entry(relic: RelicData) -> Control:
	var entry: PanelContainer = PanelContainer.new()
	var border: Color = _relic_rarity_color_for_popup(relic)
	entry.add_theme_stylebox_override("panel", UIFactory.style_box(Color("111926", 0.65), border, 1, 8))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	entry.add_child(row)
	var icon: RelicIcon = RelicIcon.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.set_relic(relic)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # popup 已顯示說明，不需要再開一層
	row.add_child(icon)
	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	var name_label: Label = Label.new()
	name_label.text = relic.display_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", border)
	text_box.add_child(name_label)
	var desc: Label = Label.new()
	desc.text = relic.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc.custom_minimum_size = Vector2(360, 0)
	text_box.add_child(desc)
	return entry

func _relic_rarity_color_for_popup(relic: RelicData) -> Color:
	match relic.rarity:
		"uncommon":
			return Color("76c4d8")
		"rare":
			return Color("d9c2ff")
		"legendary":
			return Color("ffb84a")
	return ThemeColors.BORDER_GOLD

func _show_map_overview_popup() -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(520, 0)
	var title: Label = Label.new()
	title.text = "路線總覽"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	var hint: Label = Label.new()
	hint.text = "★ 當前位置  ✓ 已走過  · 待選"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	box.add_child(hint)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for row_index: int in range(run_state.encounter_choices.size()):
		list.add_child(_map_overview_row(row_index))
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()

func _map_overview_row(row_index: int) -> Control:
	var is_current: bool = row_index == run_state.encounter_index
	var is_past: bool = row_index < run_state.encounter_index
	var bg: Color = Color("f4d985", 0.18) if is_current else (Color("273449", 0.4) if is_past else Color("273449", 0.7))
	var border: Color = ThemeColors.ACCENT_GOLD if is_current else (Color("5f6570", 0.5) if is_past else Color("8ea3c4", 0.5))
	var entry: PanelContainer = PanelContainer.new()
	entry.add_theme_stylebox_override("panel", UIFactory.style_box(bg, border, 2 if is_current else 1, 6))
	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	entry.add_child(hb)
	var prefix: String = "★" if is_current else ("✓" if is_past else "·")
	var prefix_label: Label = Label.new()
	prefix_label.text = prefix
	prefix_label.add_theme_font_size_override("font_size", 18)
	prefix_label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD if is_current else ThemeColors.TEXT_MUTED)
	prefix_label.custom_minimum_size = Vector2(22, 0)
	hb.add_child(prefix_label)
	var row_data: Array = run_state.encounter_choices[row_index]
	var chosen_idx: int = -1
	if row_index < run_state.chosen_map_path.size():
		chosen_idx = int(run_state.chosen_map_path[row_index])
	var node_descriptions: Array[String] = []
	for node_v: Variant in row_data:
		var node_data: Dictionary = node_v as Dictionary
		var node_index: int = int(node_data.get("index", 0))
		var badge: String = _map_node_badge(node_data)
		if node_index == chosen_idx:
			badge = "[%s ★]" % badge
		else:
			badge = "[%s]" % badge
		node_descriptions.append(badge)
	var row_label: Label = Label.new()
	row_label.text = "第 %d 層  %s" % [row_index + 1, "  ".join(node_descriptions)]
	row_label.add_theme_font_size_override("font_size", 15)
	row_label.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT if is_current else (ThemeColors.TEXT_MUTED if is_past else ThemeColors.TEXT_DIM))
	row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(row_label)
	return entry

func _retry_current_battle() -> void:
	if battle == null or battle.enemy == null:
		return
	var enemy_to_retry: EnemyData = battle.enemy.clone()
	# 扣 1 件 general 遺物（不扣專武 / 神器）
	var general_indices: Array[int] = []
	for i: int in range(run_state.relics.size()):
		if run_state.relics[i].slot == "general":
			general_indices.append(i)
	if not general_indices.is_empty():
		var idx: int = general_indices[randi() % general_indices.size()]
		run_state.relics.remove_at(idx)
	# 全隊回滿（包含被擊倒的後排）— 重打一場 = 從健康狀態出發
	for i: int in range(run_state.character_hps.size()):
		run_state.character_hps[i] = run_state.character_max_hps[i]
	run_state.active_character_index = 0  # 重打 = 隊長重上場
	SaveManager.save(run_state)
	start_next_battle(enemy_to_retry)

func _refresh_battle(animate_draw: bool = false) -> void:
	var top_parts: Array[String] = ["第%s幕 %d/%d 層" % [_act_numeral(run_state.act), run_state.encounter_index + 1, run_state.encounter_choices.size()]]
	top_parts.append("抽 %d / 棄 %d" % [battle.deck.draw_pile.size(), battle.deck.discard_pile.size()])
	var passive_status: String = battle.passive_status_text()
	if not passive_status.is_empty():
		top_parts.append(passive_status)
	# 隊伍 >1 人時，提示切換次數
	if run_state.characters.size() > 1:
		var switched: bool = bool(battle.state.get("switched_this_turn", false))
		top_parts.append("切換：%s" % ("已用" if switched else "本回合免費"))
	status_label.text = "    ".join(top_parts)
	if draw_pile_button != null and is_instance_valid(draw_pile_button):
		draw_pile_button.text = "抽牌堆 (%d)" % battle.deck.draw_pile.size()
	if discard_pile_button != null and is_instance_valid(discard_pile_button):
		discard_pile_button.text = "棄牌堆 (%d)" % battle.deck.discard_pile.size()
	if exhausted_pile_button != null and is_instance_valid(exhausted_pile_button):
		exhausted_pile_button.text = "消耗堆 (%d)" % battle.deck.exhausted_pile.size()
	# 玩家欄位反映 ACTIVE 角色（battle.character 為 active 的 alias）
	if battle.character != null:
		if player_name_label != null:
			player_name_label.text = battle.character.display_name
		if player_portrait_image != null and is_instance_valid(player_portrait_image):
			var pose: String = _get_active_player_pose()
			var path: String = _get_battle_portrait_path(battle.character, pose)
			var tex: Texture2D = UIFactory.load_texture(path)
			if tex != null:
				player_portrait_image.texture = tex
	_refresh_combatant_hp(player_hp_bar, player_hp_value, int(battle.state["player_hp"]), int(battle.state["player_max_hp"]))
	player_block_badge.set_amount(int(battle.state["player_block"]))
	player_status_line.text = UIFactory.status_summary(int(battle.state["player_poison"]), int(battle.state["player_weak"]), int(battle.state["player_vulnerable"]))
	_refresh_bench_strip()
	_refresh_combatant_hp(enemy_hp_bar, enemy_hp_value, int(battle.state["enemy_hp"]), int(battle.state["enemy_max_hp"]))
	enemy_block_badge.set_amount(int(battle.state["enemy_block"]))
	enemy_status_line.text = UIFactory.status_summary(int(battle.state["enemy_poison"]), int(battle.state["enemy_weak"]), int(battle.state["enemy_vulnerable"]))
	var next_action: Dictionary = battle.next_enemy_action()
	var intent_lines: Array[String] = ["%s  下一步" % CardFormat.intent_badge(next_action), String(next_action["intent"])]
	if CardFormat.action_has_damage(next_action):
		var pred: Dictionary = CardFormat.predict_enemy_damage(next_action, battle.state)
		var dealt: int = int(pred["dealt"])
		var blocked: int = int(pred["blocked"])
		if blocked > 0:
			intent_lines.append("實受 %d (擋 %d)" % [dealt, blocked])
		elif dealt < int(pred["raw"]):
			intent_lines.append("實受 %d" % dealt)
	enemy_label.text = "\n".join(intent_lines)
	energy_orb.set_energy(int(battle.state["energy"]), int(battle.state.get("per_turn_energy", BattleController.BASE_TURN_ENERGY)))
	var buttons: Array[Button] = []
	card_buttons.clear()
	_selected_hand_button = null
	for card: CardData in battle.deck.hand:
		var button: Button = _card_button(card)
		buttons.append(button)
		card_buttons.append(button)
		if card == _selected_hand_card:
			_selected_hand_button = button
	var draw_source: Vector2 = Vector2(120.0, get_viewport_rect().size.y - 70.0)
	hand_row.set_cards(buttons, animate_draw, draw_source)
	if _selected_hand_button != null:
		hand_row.set_selected_button(_selected_hand_button)
	log_label.text = "\n".join(battle.battle_log.slice(max(0, battle.battle_log.size() - 4)))
	end_turn_button.disabled = false

func _refresh_combatant_hp(bar: ProgressBar, value_label: Label, hp: int, max_hp: int) -> void:
	bar.value = 0.0 if max_hp <= 0 else float(hp) / float(max_hp)
	value_label.text = "%d / %d" % [hp, max_hp]

func _card_button(card: CardData) -> Button:
	var affordable: bool = int(battle.state["energy"]) >= battle.effective_card_cost(card)
	var card_size: Vector2 = Vector2(148, 200) if _battle_compact else Vector2(172, 238)
	var button: Button = _make_card_button(card, card.cost, card_size, affordable, true)
	button.disabled = not affordable
	button.pressed.connect(func() -> void: _on_card_button_pressed(card, button))
	button.button_down.connect(func() -> void: _on_card_button_down(card, button))
	button.button_up.connect(func() -> void: _on_card_button_up(card, button))
	button.gui_input.connect(func(event: InputEvent) -> void: _on_card_button_gui_input(card, button, event))
	return button

func _on_card_button_down(card: CardData, button: Button) -> void:
	if button.disabled:
		return
	_card_drag_button = button
	_card_drag_card = card
	_card_drag_start_global = button.get_global_mouse_position()
	_card_drag_active = false
	_start_card_long_press(card, button)

func _on_card_button_up(card: CardData, button: Button) -> void:
	if _card_drag_button == button and _card_drag_active:
		_evaluate_card_drop(card, button)
		_suppress_next_card_play = true
	_card_drag_button = null
	_card_drag_card = null
	_card_drag_active = false
	_cancel_card_long_press()

func _on_card_button_gui_input(card: CardData, button: Button, event: InputEvent) -> void:
	if _card_drag_button != button:
		return
	if _card_preview_overlay != null:
		return  # 長按預覽優先；不啟動拖拉
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag):
		return
	var current_global: Vector2 = button.get_global_mouse_position()
	if not _card_drag_active:
		if current_global.distance_to(_card_drag_start_global) >= CARD_DRAG_THRESHOLD:
			_card_drag_active = true
			_cancel_card_long_press()  # 拖拉開始就取消長按預覽 timer
	if _card_drag_active:
		var parent: Node = button.get_parent()
		if parent is Control:
			var local_mouse: Vector2 = (parent as Control).get_local_mouse_position()
			button.position = local_mouse - button.size * 0.5
			button.rotation = 0.0
			button.scale = Vector2(1.05, 1.05)
			button.z_index = 1200  # 高於 set_selected_button 的 1100
			_update_drag_target_highlight(card, current_global)

func _evaluate_card_drop(card: CardData, button: Button) -> void:
	var drop_global: Vector2 = button.get_global_mouse_position()
	_clear_drag_target_highlight()
	if _is_valid_card_drop(card, drop_global):
		play_card(card, button)
	else:
		if hand_row != null and is_instance_valid(hand_row):
			hand_row.relayout()

func _is_valid_card_drop(card: CardData, global_pos: Vector2) -> bool:
	if CardFormat.requires_enemy_target(card):
		return _is_position_near_enemy(global_pos)
	return _is_position_outside_hand(global_pos)

func _is_position_near_enemy(global_pos: Vector2) -> bool:
	if enemy_portrait_wrap == null or not is_instance_valid(enemy_portrait_wrap):
		return false
	var rect: Rect2 = Rect2(enemy_portrait_wrap.global_position, enemy_portrait_wrap.size)
	return rect.grow(CARD_DRAG_TARGET_PADDING).has_point(global_pos)

func _is_position_outside_hand(global_pos: Vector2) -> bool:
	if hand_row == null or not is_instance_valid(hand_row):
		return false
	return global_pos.y < hand_row.global_position.y

func _update_drag_target_highlight(card: CardData, global_pos: Vector2) -> void:
	# 簡單回饋：拖到有效位置時 enemy_portrait_wrap 微亮 / 拖到手牌外（self 卡）時 player 微亮
	var valid: bool = _is_valid_card_drop(card, global_pos)
	if CardFormat.requires_enemy_target(card):
		if enemy_portrait_wrap != null:
			enemy_portrait_wrap.modulate = Color(1.25, 1.15, 1.0) if valid else Color.WHITE
	else:
		if player_portrait_wrap != null:
			player_portrait_wrap.modulate = Color(1.0, 1.25, 1.15) if valid else Color.WHITE

func _clear_drag_target_highlight() -> void:
	if enemy_portrait_wrap != null and is_instance_valid(enemy_portrait_wrap):
		enemy_portrait_wrap.modulate = Color.WHITE
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_portrait_wrap.modulate = Color.WHITE

func _on_card_button_pressed(card: CardData, button: Button) -> void:
	if _suppress_next_card_play:
		_suppress_next_card_play = false
		return
	if _selected_hand_card == card and _selected_hand_button == button:
		play_card(card, button)
		return
	_selected_hand_card = card
	_selected_hand_button = button
	if hand_row != null:
		hand_row.set_selected_button(button)

func _start_card_long_press(card: CardData, button: Button) -> void:
	_card_preview_id += 1
	var my_id: int = _card_preview_id
	await get_tree().create_timer(0.5).timeout
	if my_id != _card_preview_id:
		return
	if not is_instance_valid(button) or not button.button_pressed:
		return
	_show_card_preview(card)
	_suppress_next_card_play = true

func _cancel_card_long_press() -> void:
	_card_preview_id += 1  # invalidate any pending timer
	_hide_card_preview()

func _clear_selected_hand_card() -> void:
	_selected_hand_card = null
	_selected_hand_button = null
	if hand_row != null:
		hand_row.clear_selected_button()

func _hide_card_preview() -> void:
	if _card_preview_overlay != null and is_instance_valid(_card_preview_overlay):
		_card_preview_overlay.queue_free()
	_card_preview_overlay = null

func _show_card_preview(card: CardData) -> void:
	_hide_card_preview()
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 300
	add_child(overlay)
	_card_preview_overlay = overlay
	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.55)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var stack: HBoxContainer = HBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(stack)
	var big: Button = _make_card_button(card, card.cost, Vector2(260, 360), true, true)
	big.disabled = true
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(big)
	if not card.upgraded:
		var arrow: Label = Label.new()
		arrow.text = "→\n升級後"
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.add_theme_font_size_override("font_size", 20)
		arrow.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
		stack.add_child(arrow)
		var upgraded: CardData = card.upgraded_copy()
		var up_btn: Button = _make_card_button(upgraded, upgraded.cost, Vector2(260, 360), true, true)
		up_btn.disabled = true
		up_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(up_btn)

func _reward_card_button(card: CardData) -> Button:
	return _make_card_button(card, card.cost, Vector2(230, 300), true, true)

func _card_frame_texture_path(card_type: String) -> String:
	match card_type:
		"skill":
			return "res://assets/ui/card_frame_skill.png"
		"power":
			return "res://assets/ui/card_frame_power.png"
		_:
			return "res://assets/ui/card_frame_attack.png"

func _make_card_button(card: CardData, cost: int, size: Vector2, affordable: bool, selectable: bool) -> Button:
	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	_style_card_button(button, card, affordable)
	var frame: TextureRect = TextureRect.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = UIFactory.load_texture(_card_frame_texture_path(card.card_type))
	if not affordable or not selectable:
		frame.modulate = Color(0.82, 0.82, 0.82, 0.78)
	button.add_child(frame)
	var outer: MarginContainer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", int(round(size.x * 0.11)))
	outer.add_theme_constant_override("margin_top", int(round(size.y * 0.065)))
	outer.add_theme_constant_override("margin_right", int(round(size.x * 0.11)))
	outer.add_theme_constant_override("margin_bottom", int(round(size.y * 0.08)))
	button.add_child(outer)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	outer.add_child(box)
	var type_bar: PanelContainer = PanelContainer.new()
	type_bar.custom_minimum_size = Vector2(0, max(4.0, size.y * 0.015))
	type_bar.add_theme_stylebox_override("panel", UIFactory.strip_box(CardFormat.card_color(card.card_type, true).lightened(0.16), 999))
	box.add_child(type_bar)
	var art_frame: PanelContainer = PanelContainer.new()
	# 只指定最小高度；寬度跟著 outer margin 計算過的 box 內寬走，避免硬寫 (size.x - 22)
	# 超過 outer margin 真正留下的空間（2 * 11% = 22% > 22 像素）導致 art_frame 溢出右側
	art_frame.custom_minimum_size = Vector2(0, max(92.0, size.y * 0.41))
	art_frame.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0b111a", 0.14), Color(1, 1, 1, 0), 0, 6))
	box.add_child(art_frame)
	var art_layer: Control = Control.new()
	art_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(art_layer)
	var art: TextureRect = TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = UIFactory.load_texture(card.art_path)
	if texture != null:
		art.texture = texture
	if not affordable or not selectable:
		art.modulate = Color(0.72, 0.72, 0.72, 0.62)
	art_layer.add_child(art)
	var title_back: PanelContainer = PanelContainer.new()
	title_back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	title_back.offset_left = 0
	title_back.offset_top = -28
	title_back.offset_right = 0
	title_back.offset_bottom = 0
	title_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_back.add_theme_stylebox_override("panel", UIFactory.style_box(Color(0.06, 0.05, 0.04, 0.32), Color(0, 0, 0, 0), 0, 6))
	art_layer.add_child(title_back)
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_row.add_theme_constant_override("separation", 4)
	title_back.add_child(title_row)
	var title: Label = UIFactory.card_label(card.display_title(), 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)
	var rarity_badge: Label = UIFactory.card_label(CardFormat.card_rarity_name(card), 10, CardFormat.card_rarity_color(card), HORIZONTAL_ALIGNMENT_RIGHT)
	rarity_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(rarity_badge)
	var cost_badge: PanelContainer = PanelContainer.new()
	cost_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	cost_badge.offset_left = -34
	cost_badge.offset_top = 6
	cost_badge.offset_right = -6
	cost_badge.offset_bottom = 34
	cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cost_style: StyleBoxFlat = StyleBoxFlat.new()
	cost_style.bg_color = Color(0.10, 0.08, 0.05, 0.42)
	cost_style.border_color = Color("f2d48a", 0.45)
	cost_style.set_border_width_all(1)
	cost_style.set_corner_radius_all(6)
	cost_style.content_margin_left = 2
	cost_style.content_margin_right = 2
	cost_style.content_margin_top = 2
	cost_style.content_margin_bottom = 2
	cost_badge.add_theme_stylebox_override("panel", cost_style)
	art_layer.add_child(cost_badge)
	var cost_label: Label = UIFactory.card_label(str(cost), 14, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	cost_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_badge.add_child(cost_label)
	var rules_panel: PanelContainer = PanelContainer.new()
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color(0.90, 0.87, 0.76, 0.78), Color(0, 0, 0, 0), 0, 10))
	box.add_child(rules_panel)
	var rules_margin: MarginContainer = MarginContainer.new()
	rules_margin.add_theme_constant_override("margin_left", 10)
	rules_margin.add_theme_constant_override("margin_top", 8)
	rules_margin.add_theme_constant_override("margin_right", 10)
	rules_margin.add_theme_constant_override("margin_bottom", 12)
	rules_panel.add_child(rules_margin)
	var rules_box: VBoxContainer = VBoxContainer.new()
	rules_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_box.add_theme_constant_override("separation", 4)
	rules_margin.add_child(rules_box)
	var type_line: Label = UIFactory.card_label(CardFormat.card_type_name(card.card_type), 11, CardFormat.card_color(card.card_type, true).darkened(0.05), HORIZONTAL_ALIGNMENT_CENTER)
	rules_box.add_child(type_line)
	var desc: Label = UIFactory.card_label(card.display_description(), 12, Color("2d2418"), HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_box.add_child(desc)
	UIFactory.ignore_child_mouse(button)
	return button

func _detach_card_button(button: Button) -> void:
	var global_pos: Vector2 = button.global_position
	var preserved_scale: Vector2 = button.scale
	var parent: Node = button.get_parent()
	if parent != null:
		parent.remove_child(button)
	add_child(button)
	button.pivot_offset = button.size / 2.0
	button.rotation = 0.0
	button.global_position = global_pos
	button.scale = preserved_scale
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIFactory.ignore_child_mouse(button)
	animating_cards.append(button)

func _animate_played_card(button: Button, card: CardData) -> void:
	var target_label: Label = enemy_feedback_label if card.card_type == "attack" else player_feedback_label
	if target_label == null:
		button.queue_free()
		return
	var target_center: Vector2 = target_label.global_position + target_label.size / 2.0
	var target_pos: Vector2 = target_center - button.size / 2.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(button, "global_position", target_pos, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.65, 0.65), 0.42)
	tween.tween_property(button, "modulate:a", 0.0, 0.42).set_delay(0.06)
	tween.finished.connect(func() -> void:
		animating_cards.erase(button)
		if is_instance_valid(button):
			button.queue_free())

func _animate_hand_discard() -> void:
	var snapshot: Array[Button] = []
	for b: Button in card_buttons:
		if is_instance_valid(b):
			snapshot.append(b)
	if snapshot.is_empty():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var discard_target: Vector2 = Vector2(viewport_size.x - 120.0, viewport_size.y - 70.0)
	for i: int in range(snapshot.size()):
		var button: Button = snapshot[i]
		_detach_card_button(button)
		var delay: float = i * 0.04
		var target_pos: Vector2 = discard_target - button.size / 2.0
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(button, "global_position", target_pos, 0.32).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(button, "scale", Vector2(0.42, 0.42), 0.32).set_delay(delay)
		tween.tween_property(button, "modulate:a", 0.0, 0.32).set_delay(delay + 0.08)
		tween.finished.connect(func() -> void:
			if is_instance_valid(button):
				button.queue_free())
	card_buttons.clear()

func _show_state_feedback(before: Dictionary) -> void:
	var player_lines: Array[String] = []
	var enemy_lines: Array[String] = []
	var bs: Dictionary = battle.state
	var player_hp_delta: int = int(bs["player_hp"]) - int(before["player_hp"])
	var enemy_hp_delta: int = int(bs["enemy_hp"]) - int(before["enemy_hp"])
	var player_block_delta: int = int(bs["player_block"]) - int(before["player_block"])
	var enemy_block_delta: int = int(bs["enemy_block"]) - int(before["enemy_block"])
	var player_poison_delta: int = int(bs["player_poison"]) - int(before["player_poison"])
	var player_weak_delta: int = int(bs["player_weak"]) - int(before["player_weak"])
	var player_vulnerable_delta: int = int(bs["player_vulnerable"]) - int(before["player_vulnerable"])
	var enemy_poison_delta: int = int(bs["enemy_poison"]) - int(before["enemy_poison"])
	var enemy_weak_delta: int = int(bs["enemy_weak"]) - int(before["enemy_weak"])
	var enemy_vulnerable_delta: int = int(bs["enemy_vulnerable"]) - int(before["enemy_vulnerable"])
	if player_hp_delta < 0:
		player_lines.append("受傷 %d" % abs(player_hp_delta))
	elif player_hp_delta > 0:
		player_lines.append("治療 +%d" % player_hp_delta)
	if player_block_delta > 0:
		player_lines.append("護體 +%d" % player_block_delta)
	if player_poison_delta > 0:
		player_lines.append("蠱毒 +%d" % player_poison_delta)
	if player_weak_delta > 0:
		player_lines.append("虛弱 +%d" % player_weak_delta)
	if player_vulnerable_delta > 0:
		player_lines.append("破綻 +%d" % player_vulnerable_delta)
	if enemy_hp_delta < 0:
		enemy_lines.append("傷害 %d" % abs(enemy_hp_delta))
	if enemy_block_delta > 0:
		enemy_lines.append("護體 +%d" % enemy_block_delta)
	if enemy_poison_delta > 0:
		enemy_lines.append("蠱毒 +%d" % enemy_poison_delta)
	if enemy_weak_delta > 0:
		enemy_lines.append("虛弱 +%d" % enemy_weak_delta)
	if enemy_vulnerable_delta > 0:
		enemy_lines.append("破綻 +%d" % enemy_vulnerable_delta)
	if not player_lines.is_empty():
		_show_feedback(player_feedback_label, player_lines, Color("f4b7a8"))
	if not enemy_lines.is_empty():
		_show_feedback(enemy_feedback_label, enemy_lines, ThemeColors.ACCENT_GOLD)
	if player_hp_delta < 0:
		UIFactory.shake_node(player_portrait_wrap, 7.0, 0.28)
		_spawn_damage_popup(player_portrait_wrap, abs(player_hp_delta), "damage")
	elif player_hp_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, player_hp_delta, "heal")
	if enemy_hp_delta < 0:
		UIFactory.shake_node(enemy_portrait_wrap, 7.0, 0.28)
		_spawn_damage_popup(enemy_portrait_wrap, abs(enemy_hp_delta), "damage")
	if player_block_delta > 0:
		UIFactory.flash_node(player_portrait_wrap, Color(1.2, 1.35, 1.55), 0.22)
		_spawn_damage_popup(player_portrait_wrap, player_block_delta, "block")
	if enemy_block_delta > 0:
		UIFactory.flash_node(enemy_portrait_wrap, Color(1.2, 1.35, 1.55), 0.22)
		_spawn_damage_popup(enemy_portrait_wrap, enemy_block_delta, "block")

func _spawn_damage_popup(target: Control, amount: int, kind: String) -> void:
	if target == null or not is_instance_valid(target):
		return
	var world_pos: Vector2 = target.global_position + Vector2(target.size.x * 0.5 - 40, target.size.y * 0.35)
	DamagePopup.spawn(self, world_pos, amount, kind)

func _show_feedback(label: Label, lines: Array[String], color: Color) -> void:
	if label == null:
		return
	label.text = "\n".join(lines)
	label.modulate = Color(color.r, color.g, color.b, 1.0)
	label.scale = Vector2(1.08, 1.08)
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)

func _passive_text() -> String:
	var labels: Array[String] = []
	for passive: Dictionary in selected_character.passives:
		var label: String = String(passive.get("label", ""))
		if not label.is_empty():
			labels.append("被動：%s。" % label)
	return "\n".join(labels)

func _style_card_button(button: Button, card: CardData, affordable: bool) -> void:
	var hover_tint: Color = CardFormat.card_color(card.card_type, true).lightened(0.18)
	var press_tint: Color = CardFormat.card_color(card.card_type, true).darkened(0.2)
	var normal: StyleBoxFlat = UIFactory.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 18)
	var hover: StyleBoxFlat = UIFactory.style_box(Color(hover_tint.r, hover_tint.g, hover_tint.b, 0.12), Color(1, 0.98, 0.88, 0.38), 1, 18)
	var pressed: StyleBoxFlat = UIFactory.style_box(Color(press_tint.r, press_tint.g, press_tint.b, 0.18), Color(1, 0.9, 0.62, 0.45), 1, 18)
	var disabled: StyleBoxFlat = UIFactory.style_box(Color(0, 0, 0, 0.08), Color(0, 0, 0, 0), 0, 18)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	button.add_theme_color_override("font_disabled_color", Color("b8bec8"))
	button.add_theme_font_size_override("font_size", 15)

func _title(text: String, size: int) -> Label:
	return UIFactory.title_label(text, size)

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.add_theme_font_size_override("font_size", 18)
	UIFactory.style_button(button)
	return button

func _get_active_player_pose() -> String:
	if _temporary_player_pose != "":
		return _temporary_player_pose
	if battle == null or battle.state == null:
		return "idle"
	var hp: int = int(battle.state.get("player_hp", 10))
	var max_hp: int = int(battle.state.get("player_max_hp", 10))
	var block: int = int(battle.state.get("player_block", 0))
	if hp <= 0:
		return "downed"
	if hp <= max_hp * 0.25:
		return "low_hp"
	if block > 0:
		return "block"
	return "idle"

func _get_battle_portrait_path(char_data: CharacterData, pose: String) -> String:
	if char_data == null:
		return ""
	var path: String = "res://assets/art/battle_characters/%s_%s.png" % [char_data.id, pose]
	if FileAccess.file_exists(path):
		return path
	return char_data.portrait_path
