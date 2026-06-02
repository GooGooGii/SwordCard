class_name Main
extends Control

const BATTLE_END_DELAY: float = 0.8

# Phase 1 screen 系統：current_screen 持有 RefCounted screen 實例，
# 避免它在 _show() 結束後立刻被回收（其 button callback 可能還會用到它）。
var current_screen: Screen = null

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
var player_level_label: Label
var player_block_badge: BlockBadge
var player_portrait_wrap: Control
var player_portrait_image: TextureRect  # 戰鬥中切換 active 時動態換肖像
var bench_strip: Control  # 後排「站位」容器（手動定位，斜向交疊在隊長身後）
var _switch_tween: Tween = null  # 切換角色的淡出/淡入動畫，防止重疊
var enemy_hp_bar: ProgressBar
var enemy_hp_value: Label
var enemy_status_line: Label
var enemy_name_label: Label
var enemy_block_badge: BlockBadge
var enemy_portrait_wrap: Control
# Multi-Enemy 模式：每隻敵人的 widget refs，singular enemy_* 是 active 敵的 alias
# 每個 dict: {root, wrap, portrait, name_label, hp_bar, hp_value, block_badge, status_line, feedback_label, enemy_idx}
var enemy_widgets: Array[Dictionary] = []
var enemy_row_container: HBoxContainer = null  # 召喚物加入時用此 ref 重建 row
var enemy_portrait_image: TextureRect  # ref to TextureRect inside wrap, for phase 2 swap
var energy_orb: EnergyOrb
var relic_strip: HBoxContainer
var deck_overlay: Control
var deck_view_mode: String = "view"
var _deck_view_service_price: int = 0
var draw_pile_button: Button
var discard_pile_button: Button
var exhausted_pile_button: Button
var card_buttons: Array[Button] = []
var animating_cards: Array[Button] = []
var pause_menu: PauseMenu
var pause_button: Button
var debug_menu: DebugMenu
var dbg_test_mode: bool = false
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
var _potion_buttons: Array[Button] = []
var _battle_potion_strip: HBoxContainer = null
var _potion_overlay: HBoxContainer = null
var _potion_overlay_buttons: Array[Button] = []
var _selected_hand_button: Button = null
var _pending_card_confirmations: Array[Dictionary] = []

# 畫面切換淡入淡出 — _clear_root 截舊畫面當 overlay，新畫面建在下方，再淡出 overlay
var _transition_layer: CanvasLayer = null
var _transition_snapshot: TextureRect = null
var _transition_tween: Tween = null
const SCREEN_FADE_DURATION: float = 0.22

var title_bar: PanelContainer = null
var title_bar_name_label: Label = null
var title_bar_hp_bar: ProgressBar = null
var title_bar_hp_label: Label = null
var title_bar_gold_label: Label = null
var title_bar_observe_label: Label = null
var title_bar_relics_button: Button = null
var map_legend_panel: Control = null
const TITLE_BAR_HEIGHT: float = 52.0

var _temporary_player_pose: String = ""
var _pose_timer: SceneTreeTimer = null
var _pending_revive_indices: Array[int] = []
var _pending_levelups: Array[Dictionary] = []

# 卡片 drag-to-play 狀態
var _card_drag_button: Button = null
var _card_drag_card: CardData = null
var _card_drag_start_global: Vector2 = Vector2.ZERO
var _card_drag_active: bool = false
const CARD_DRAG_THRESHOLD: float = 14.0
const CARD_DRAG_TARGET_PADDING: float = 80.0  # 拖到敵人附近 N px 都算命中（桌面）
const CARD_DRAG_TARGET_PADDING_MOBILE: float = 160.0  # 手機手指較粗，放寬命中範圍

# Mobile swipe-to-play 狀態（水平滑動選卡，向上滑出手牌區出牌）
var _hand_buttons_map: Dictionary = {}  # Button → CardData，每次 _refresh_hand 重建

var selected_ascension: int = 0
var pending_seed: int = 0  # 0 = 隨機；非 0 = 下次 start_run 用此 seed 生地圖
var selected_party_ids: Array[String] = []  # character_select 多選 buffer，1–3 人
var _event_battle_on_win: Callable  # 非空時表示從事件觸發的戰鬥，勝利後執行 callback 而非正常流程
var _after_boss_relic_choice: Callable  # boss 遺物選擇後的 continuation（potion drop + 推進地圖）
var _boss_card_reward: bool = false  # 下一個 show_card_reward 是否為 boss 獎勵（三張稀有牌）
var _after_card_reward: Callable  # card reward 選/跳過後的 continuation（預設回 progress screen）
var _boon_applied: String = ""  # 本次 run 套用的加護 id（空 = 跳過）
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
	_build_potion_overlay()
	_build_title_bar()
	show_main_menu()

func _process(_delta: float) -> void:
	if pause_button == null:
		return
	var title_bar_visible: bool = title_bar != null and title_bar.visible
	var should_show: bool = run_state != null and run_state.character != null and not title_bar_visible
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
	# 點空白處取消手牌選取
	if _selected_hand_card != null:
		var is_tap_release: bool = false
		if event is InputEventScreenTouch:
			is_tap_release = not (event as InputEventScreenTouch).pressed
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			is_tap_release = not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		if is_tap_release:
			_clear_selected_hand_card()
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
	debug_menu.add_potion_requested.connect(_dbg_add_potion)
	debug_menu.jump_to_boss_requested.connect(_dbg_jump_to_boss)
	debug_menu.toggle_test_mode_requested.connect(_dbg_toggle_test_mode)
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

func _dbg_add_potion() -> void:
	if run_state == null:
		return
	if run_state.potions.size() >= RunState.MAX_POTION_SLOTS:
		print("[DEBUG] potion slots full (%d/%d)" % [run_state.potions.size(), RunState.MAX_POTION_SLOTS])
		return
	var all_potions: Array[Dictionary] = PotionCatalog.all()
	var chosen: Dictionary = all_potions[randi() % all_potions.size()]
	run_state.potions.append(chosen.duplicate())
	print("[DEBUG] added potion: %s (slots %d/%d)" % [String(chosen.get("display_name", "")), run_state.potions.size(), RunState.MAX_POTION_SLOTS])
	_refresh_potion_overlay_buttons()

func _dbg_jump_to_boss() -> void:
	if run_state == null or run_state.encounter_choices.is_empty():
		return
	# 把 encounter_index 直接推到 boss 行（地圖最後一層）
	run_state.encounter_index = run_state.encounter_choices.size() - 1
	debug_menu.visible = false
	show_progress_screen()
	print("[DEBUG] jumped to boss row (index %d)" % run_state.encounter_index)

func _dbg_toggle_test_mode() -> void:
	dbg_test_mode = not dbg_test_mode
	if debug_menu != null:
		debug_menu.set_test_mode(dbg_test_mode)
	debug_menu.visible = false
	print("[DEBUG] test mode = %s" % dbg_test_mode)
	if run_state != null and not run_state.encounter_choices.is_empty():
		show_progress_screen()

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
	_capture_transition_snapshot()
	active_map_scroll = null
	_map_drag_candidate = false
	_map_dragging = false
	for button: Button in animating_cards:
		if is_instance_valid(button):
			button.queue_free()
	animating_cards.clear()
	for child: Node in root.get_children():
		child.queue_free()
	_clear_map_legend()
	if _potion_overlay != null:
		_potion_overlay.visible = true
		_refresh_potion_overlay_buttons()
	call_deferred("_start_transition_fade_in")

func _ensure_transition_layer() -> void:
	if _transition_layer != null and is_instance_valid(_transition_layer):
		return
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100  # 蓋在所有 UI 之上
	add_child(_transition_layer)
	_transition_snapshot = TextureRect.new()
	_transition_snapshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_transition_snapshot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_transition_snapshot.modulate.a = 0.0
	_transition_layer.add_child(_transition_snapshot)

func _capture_transition_snapshot() -> void:
	_ensure_transition_layer()
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	var vp_tex: ViewportTexture = get_viewport().get_texture()
	if vp_tex == null:
		return
	var image: Image = vp_tex.get_image()
	if image == null or image.is_empty():
		# 首次啟動：尚無畫面可截 — 用純黑取代，反正是首幕沒「淡出」可言
		_transition_snapshot.texture = null
		_transition_snapshot.self_modulate = Color(0, 0, 0, 1)
		_transition_snapshot.modulate.a = 1.0
		return
	var tex: ImageTexture = ImageTexture.create_from_image(image)
	_transition_snapshot.self_modulate = Color.WHITE
	_transition_snapshot.texture = tex
	_transition_snapshot.modulate.a = 1.0

func _start_transition_fade_in() -> void:
	if _transition_snapshot == null or not is_instance_valid(_transition_snapshot):
		return
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_property(_transition_snapshot, "modulate:a", 0.0, SCREEN_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_background(path: String) -> void:
	if background_rect == null:
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		background_rect.texture = texture

func _set_event_background(event_variant: String = "") -> void:
	var variant: String = event_variant
	if variant.is_empty() and run_state != null:
		variant = String(run_state.current_event_variant)
	var specific_path: String = "res://assets/art/events/%s.png" % variant
	if not variant.is_empty() and ResourceLoader.exists(specific_path):
		_set_background(specific_path)
		return
	_set_background("res://assets/art/event_bg.png")

func _battle_background_path() -> String:
	var fallback_path: String = "res://assets/art/battle_bg.png"
	if run_state == null:
		return fallback_path
	var act_index: int = clamp(int(run_state.act), 1, 5)
	var act_path: String = "res://assets/art/battle_bg_act_%d.png" % act_index
	if ResourceLoader.exists(act_path):
		return act_path
	return fallback_path

# AudioManager 是 autoload；直接引用全域識別字 `AudioManager` 會在「以 const 路徑
# load(main.gd) 觸發的啟動期編譯」中找不到（autoload global 尚未註冊），進而毒化
# main.gd 的編譯快取（smoke test 載入 main.gd 時就會踩到）。改用節點路徑存取，
# 讓 main.gd 在任何 headless / tool 情境都能編譯；正式遊戲時節點存在、行為不變。
func _play_bgm(track: String) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am != null:
		am.play_bgm(track)

func show_main_menu() -> void:
	selected_party_ids.clear()  # 進主選單清掉 character_select 的暫存隊伍
	_hide_title_bar()
	_play_bgm("title")
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
		var continue_button: Button = UIFactory.main_menu_button("舊的回憶", true, button_height, button_font_size)
		continue_button.pressed.connect(continue_saved_run)
		action_box.add_child(continue_button)
	var start_button: Button = UIFactory.main_menu_button("新的開始", false, button_height, button_font_size)
	start_button.pressed.connect(_on_start_random_pressed)
	action_box.add_child(start_button)
	var secondary_row: HBoxContainer = HBoxContainer.new()
	secondary_row.add_theme_constant_override("separation", 8)
	var seed_button: Button = UIFactory.main_menu_button("輸入種子", false, button_height, button_font_size)
	seed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_button.pressed.connect(_show_seed_input_popup)
	secondary_row.add_child(seed_button)
	var bestiary_button: Button = UIFactory.main_menu_button("敵將圖鑑", false, button_height, button_font_size)
	bestiary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bestiary_button.pressed.connect(show_bestiary)
	secondary_row.add_child(bestiary_button)
	action_box.add_child(secondary_row)
	action_box.add_child(_build_ascension_picker(compact_layout, ultra_compact))
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
		var continue_button: Button = UIFactory.main_menu_button("舊的回憶", true, button_height, button_font_size)
		continue_button.custom_minimum_size.x = content_width
		continue_button.pressed.connect(continue_saved_run)
		action_box.add_child(continue_button)

	var start_button: Button = UIFactory.main_menu_button("新的開始", false, button_height, button_font_size)
	start_button.custom_minimum_size.x = content_width
	start_button.pressed.connect(_on_start_random_pressed)
	action_box.add_child(start_button)

	var secondary_row: HBoxContainer = HBoxContainer.new()
	secondary_row.add_theme_constant_override("separation", 8)
	secondary_row.custom_minimum_size.x = content_width
	var seed_button: Button = UIFactory.main_menu_button("輸入種子", false, button_height, button_font_size)
	seed_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_button.pressed.connect(_show_seed_input_popup)
	secondary_row.add_child(seed_button)
	var bestiary_button: Button = UIFactory.main_menu_button("敵將圖鑑", false, button_height, button_font_size)
	bestiary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bestiary_button.pressed.connect(show_bestiary)
	secondary_row.add_child(bestiary_button)
	action_box.add_child(secondary_row)

	var ascension_picker: Control = _build_ascension_picker(compact_layout, ultra_compact)
	ascension_picker.custom_minimum_size.x = content_width
	action_box.add_child(ascension_picker)

	var quit_button: Button = UIFactory.main_menu_button("離開遊戲", false, button_height, button_font_size)
	quit_button.custom_minimum_size.x = content_width
	quit_button.pressed.connect(get_tree().quit)
	action_box.add_child(quit_button)

func _on_start_random_pressed() -> void:
	pending_seed = 0
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
	panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("f6f1e6", 0.92), Color("c8b46f", 0.55), 1, 18))
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
	_hide_title_bar()
	_play_bgm("bestiary")
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	_show(BestiaryScreen.new())

func _show(next: Screen) -> void:
	current_screen = next
	next.attach(self)

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
	_hide_title_bar()
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
	_boon_applied = ""
	if dbg_test_mode:
		show_progress_screen()
	else:
		show_run_start_boons()

func _make_encounter_choices() -> Array[Array]:
	var act_enemies: Array[EnemyData] = GameData.enemies_for_act(run_state.act)
	var act_boss: Array[EnemyData] = []
	act_boss.append(GameData.boss_for_act(run_state.act))
	var char_ids: Array[String] = []
	for c: CharacterData in run_state.characters:
		char_ids.append(c.id)
	return MapGenerator.generate(act_enemies, act_boss, char_ids, run_state.act)

# ──────────────────────────────────────────────────────────────────────
# 起始加護（Run Start Boons）
# ──────────────────────────────────────────────────────────────────────

const BOON_POOL: Array[Dictionary] = [
	{"id": "extra_gold",        "name": "行囊充實",   "desc": "起始銅錢 +200。",                        "locked_by": ""},
	{"id": "extra_card",        "name": "多學一技",   "desc": "從主角技能池隨機習得 1 張招式。",         "locked_by": ""},
	{"id": "random_relic",      "name": "機緣遺物",   "desc": "獲得 1 件隨機普通遺物。",                 "locked_by": ""},
	{"id": "remove_starter",    "name": "去蕪存菁",   "desc": "從主角起始牌組移除 1 張隨機基礎牌。",     "locked_by": ""},
	{"id": "hp_up",             "name": "體魄強健",   "desc": "全隊最大 HP +12，當前 HP 同步提升。",     "locked_by": ""},
	{"id": "starting_potion",   "name": "備藥出行",   "desc": "起始攜帶 1 瓶回春丹。",                   "locked_by": ""},
	{"id": "curse_relic",       "name": "禍福相依",   "desc": "接受 1 張隨機詛咒，但獲得 1 件稀有遺物。", "locked_by": ""},
	{"id": "weapon_exchange",   "name": "奇遇法器",   "desc": "捨去主角初始武器，換取 1 件隨機稀有遺物（不可選擇）。\n【需曾擊敗 Boss】", "locked_by": "boss_cleared"},
]
const BOON_COUNT: int = 4  # 每次 run 顯示的選項數

static func _any_boss_cleared() -> bool:
	var records: Dictionary = Bestiary.load_all()
	for boss_id: String in Ascension.BOSS_IDS:
		if int(records.get(boss_id, 0)) > 0:
			return true
	return false

func _make_boon_choices() -> Array[Dictionary]:
	var boss_cleared: bool = _any_boss_cleared()
	var fixed: Array[Dictionary] = []   # 保證出現的 boon（weapon_exchange，若解鎖）
	var pool: Array[Dictionary] = []    # 可隨機抽的 boon
	for b: Dictionary in BOON_POOL:
		var lock: String = String(b.get("locked_by", ""))
		if lock == "boss_cleared":
			if boss_cleared:
				fixed.append(b)
			# 未解鎖的不放入 pool
		else:
			pool.append(b)
	pool.shuffle()
	var choices: Array[Dictionary] = []
	choices.append_array(fixed)
	var needed: int = BOON_COUNT - choices.size()
	for i: int in range(min(needed, pool.size())):
		choices.append(pool[i])
	return choices

func show_run_start_boons() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var outer: VBoxContainer = VBoxContainer.new()
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 16)
	panel.add_child(outer)
	outer.add_child(_title("起始加護", 32))
	outer.add_child(UIFactory.card_label("選擇一項，或跳過。", 13, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var choices: Array[Dictionary] = _make_boon_choices()
	# 橫排 4 格（強制橫屏、4 格並排可容納）
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	outer.add_child(row)
	for boon: Dictionary in choices:
		row.add_child(_boon_choice_panel(boon))
	var skip_btn: Button = _button("跳過（不選加護）")
	skip_btn.pressed.connect(func() -> void:
		_boon_applied = ""
		show_progress_screen()
	)
	outer.add_child(skip_btn)

func _boon_choice_panel(boon: Dictionary) -> PanelContainer:
	var boon_id: String = String(boon.get("id", ""))
	var is_special: bool = String(boon.get("locked_by", "")) == "boss_cleared"
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(185, 260)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	if is_special:
		var badge: Label = UIFactory.card_label("★ Boss 解鎖", 11, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(badge)
	var name_lbl: Label = UIFactory.card_label(String(boon.get("name", "")), 17, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_lbl)
	var desc_lbl: Label = UIFactory.card_label(String(boon.get("desc", "")), 12, Color("c8d8ec"), HORIZONTAL_ALIGNMENT_CENTER)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(165, 0)
	box.add_child(desc_lbl)
	var pick_btn: Button = _button("選取")
	pick_btn.pressed.connect(func(_bid: String = boon_id) -> void:
		_apply_boon(_bid)
	)
	box.add_child(pick_btn)
	return panel

func _apply_boon(boon_id: String) -> void:
	_boon_applied = boon_id
	var rewards: Array[Dictionary] = []
	match boon_id:
		"extra_gold":
			run_state.gold += 200
			rewards.append({
				"type": "gold",
				"display_name": "200 銅錢",
				"description": "旅費資金已加碼存入行囊。"
			})
		"extra_card":
			var pool: Array[CardData] = selected_character.reward_pool.duplicate()
			if not pool.is_empty():
				pool.shuffle()
				var card: CardData = (pool[0] as CardData).clone()
				var d: Array = run_state.character_decks[0] as Array
				d.append(card)
				rewards.append({
					"type": "card",
					"display_name": card.display_name,
					"description": card.description,
					"card": card
				})
		"random_relic":
			var relic_pool: Array[RelicData] = []
			for r: RelicData in RelicCatalog.generals():
				if r.rarity == "common" and not run_state.has_relic(r.id):
					relic_pool.append(r)
			if not relic_pool.is_empty():
				relic_pool.shuffle()
				var relic: RelicData = relic_pool[0].clone()
				run_state.add_relic(relic)
				rewards.append({
					"type": "relic",
					"display_name": relic.display_name,
					"description": relic.description,
					"relic": relic
				})
		"remove_starter":
			var d: Array = run_state.character_decks[0] as Array
			var basic_indices: Array[int] = []
			for i: int in range(d.size()):
				if (d[i] as CardData).rarity == "basic":
					basic_indices.append(i)
			if not basic_indices.is_empty():
				basic_indices.shuffle()
				var removed_card: CardData = d[basic_indices[0]]
				d.remove_at(basic_indices[0])
				rewards.append({
					"type": "remove_card",
					"display_name": removed_card.display_name,
					"description": "已從初始牌組中永久移除。"
				})
		"hp_up":
			for i: int in range(run_state.characters.size()):
				run_state.character_max_hps[i] += 12
				run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + 12)
			rewards.append({
				"type": "hp",
				"display_name": "生命上限 +12",
				"description": "全隊體魄增強，最大與當前 HP 同步提升。"
			})
		"starting_potion":
			if run_state.potions.size() < RunState.MAX_POTION_SLOTS:
				var huichun: Dictionary = PotionCatalog.by_id("huichun_dan")
				if not huichun.is_empty():
					var dup_potion: Dictionary = huichun.duplicate()
					run_state.potions.append(dup_potion)
					rewards.append({
						"type": "potion",
						"display_name": String(dup_potion.get("display_name", "回春丹")),
						"description": String(dup_potion.get("description", "")),
						"potion": dup_potion
					})
		"curse_relic":
			var all_curses: Array[String] = []
			for c: Dictionary in CurseCatalog.all():
				all_curses.append(String(c["id"]))
			if not all_curses.is_empty():
				all_curses.shuffle()
				var curse_card: CardData = CurseCatalog.make_card(all_curses[0])
				if curse_card != null:
					(run_state.character_decks[0] as Array).append(curse_card)
					rewards.append({
						"type": "curse",
						"display_name": curse_card.display_name,
						"description": "隨機詛咒加入牌組：\n%s" % curse_card.description,
						"card": curse_card
					})
			var rare_pool: Array[RelicData] = []
			for r: RelicData in RelicCatalog.generals():
				if r.rarity == "rare" and not run_state.has_relic(r.id):
					rare_pool.append(r)
			if not rare_pool.is_empty():
				rare_pool.shuffle()
				var relic: RelicData = rare_pool[0].clone()
				run_state.add_relic(relic)
				rewards.append({
					"type": "relic",
					"display_name": relic.display_name,
					"description": relic.description,
					"relic": relic
				})
		"weapon_exchange":
			var weapon_id_to_remove: String = ""
			for w: RelicData in RelicCatalog.weapons_for_character(selected_character.id):
				if run_state.has_relic(w.id):
					weapon_id_to_remove = w.id
					break
			var removed_weapon_name: String = ""
			if not weapon_id_to_remove.is_empty():
				var kept: Array[RelicData] = []
				for r_v: RelicData in run_state.relics:
					if r_v.id != weapon_id_to_remove:
						kept.append(r_v)
					else:
						removed_weapon_name = r_v.display_name
				run_state.relics = kept
				rewards.append({
					"type": "remove_weapon",
					"display_name": "捨棄武器 " + removed_weapon_name,
					"description": "失去初始法器以尋求更大機緣。"
				})
			var rare_pool2: Array[RelicData] = []
			for r2: RelicData in RelicCatalog.generals():
				if r2.rarity == "rare" and not run_state.has_relic(r2.id):
					rare_pool2.append(r2)
			if not rare_pool2.is_empty():
				rare_pool2.shuffle()
				var relic: RelicData = rare_pool2[0].clone()
				run_state.add_relic(relic)
				rewards.append({
					"type": "relic",
					"display_name": relic.display_name,
					"description": relic.description,
					"relic": relic
				})

	if not rewards.is_empty():
		_show_boon_rewards_popup(rewards, show_progress_screen)
	else:
		show_progress_screen()

func _show_boon_rewards_popup(rewards: Array[Dictionary], on_close: Callable) -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.custom_minimum_size = Vector2(420, 280)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title: Label = Label.new()
	title.text = "【加護結果】獲得加護物資"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	
	var subtitle: Label = Label.new()
	subtitle.text = "大俠踏上旅途，獲得以下物資加護："
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	box.add_child(subtitle)
	
	var content_row: HBoxContainer = HBoxContainer.new()
	content_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content_row.add_theme_constant_override("separation", 20)
	box.add_child(content_row)
	
	for item: Dictionary in rewards:
		var type: String = String(item.get("type", ""))
		var display_name: String = String(item.get("display_name", ""))
		var description: String = String(item.get("description", ""))
		
		var card_panel: PanelContainer = PanelContainer.new()
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("141c28", 0.95)
		panel_style.set_border_width_all(1)
		panel_style.border_color = Color("3a4b63")
		panel_style.set_corner_radius_all(6)
		panel_style.content_margin_left = 12
		panel_style.content_margin_right = 12
		panel_style.content_margin_top = 10
		panel_style.content_margin_bottom = 10
		card_panel.add_theme_stylebox_override("panel", panel_style)
		card_panel.custom_minimum_size = Vector2(180, 160)
		
		var item_box: VBoxContainer = VBoxContainer.new()
		item_box.alignment = BoxContainer.ALIGNMENT_CENTER
		item_box.add_theme_constant_override("separation", 6)
		card_panel.add_child(item_box)
		
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var name_color: Color = ThemeColors.TEXT_LIGHT
		
		if type == "gold":
			icon.texture = UIFactory.load_texture("res://assets/art/relics/tong_bao_qian.png")
			name_color = ThemeColors.HIGHLIGHT_GOLD
		elif type == "card" or type == "curse":
			var card_data: CardData = item.get("card") as CardData
			if card_data != null:
				icon.texture = UIFactory.load_texture(card_data.art_path)
				name_color = CardFormat.card_rarity_color(card_data)
			else:
				icon.texture = UIFactory.load_texture("res://assets/art/relics/jing_hua_fu.png")
		elif type == "relic":
			var relic_data: RelicData = item.get("relic") as RelicData
			if relic_data != null:
				icon.texture = UIFactory.load_texture("res://assets/art/relics/%s.png" % relic_data.id)
				name_color = _relic_rarity_color_for_popup(relic_data)
			else:
				icon.texture = UIFactory.load_texture("res://assets/art/relics/duo_bao_ge.png")
		elif type == "potion":
			var potion_data: Dictionary = item.get("potion", {}) as Dictionary
			if not potion_data.is_empty():
				icon.texture = UIFactory.load_texture("res://assets/art/potions/%s.png" % String(potion_data.get("id", "huichun_dan")))
				name_color = PotionCatalog.rarity_color(potion_data)
			else:
				icon.texture = UIFactory.load_texture("res://assets/art/potions/huichun_dan.png")
		elif type == "remove_card":
			icon.texture = UIFactory.load_texture("res://assets/art/relics/jing_hua_fu.png")
			name_color = Color("a5a5a5")
		elif type == "remove_weapon":
			icon.texture = UIFactory.load_texture("res://assets/art/relics/wuyue_shendao.png")
			name_color = Color("d95e5e")
		elif type == "hp":
			icon.texture = UIFactory.load_texture("res://assets/art/relics/long_xue_shi.png")
			name_color = Color("ff6c6c")
			
		item_box.add_child(icon)
		
		var name_lbl: Label = Label.new()
		name_lbl.text = display_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", name_color)
		item_box.add_child(name_lbl)
		
		var desc_lbl: Label = Label.new()
		desc_lbl.text = description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size = Vector2(160, 0)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		item_box.add_child(desc_lbl)
		
		content_row.add_child(card_panel)
		
	var btn: Button = _button("出發")
	btn.custom_minimum_size = Vector2(100, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(popup.hide)
	box.add_child(btn)
	
	popup.add_child(box)
	get_viewport().add_child(popup)
	
	popup.popup_hide.connect(func() -> void:
		popup.queue_free()
		on_close.call()
	)
	popup.popup_centered()

func show_progress_screen() -> void:
	SaveManager.save(run_state)
	_play_bgm("map_act%d" % max(1, run_state.act))
	_set_background("res://assets/art/map_bg_ink.png")
	_clear_root()
	_show_title_bar()
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
	_clear_map_legend()
	var legend_layer: CanvasLayer = CanvasLayer.new()
	legend_layer.layer = 5
	legend_layer.name = "MapLegendLayer"
	add_child(legend_layer)
	map_legend_panel = _build_map_legend(compact_map)
	legend_layer.add_child(map_legend_panel)
	var top_offset: float = TITLE_BAR_HEIGHT + (12.0 if compact_map else 20.0)
	map_legend_panel.offset_top = top_offset
	map_legend_panel.offset_bottom = top_offset + map_legend_panel.custom_minimum_size.y
	
	# 在地圖上方顯示當前幕名稱，例如「第一幕 餘杭山間」
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

func _map_view_sts(read_only: bool = false) -> Control:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact_map: bool = viewport_size.y <= 760.0
	var panel_height: float = clamp(viewport_size.y - (56.0 if compact_map else 64.0), 360.0, 760.0)
	if read_only:
		# 唯讀彈窗模式下適度壓縮高度，避免在 720p 螢幕下溢出
		panel_height = clamp(viewport_size.y - 180.0, 300.0, 500.0)
	var map_panel: PanelContainer = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(1040, panel_height)
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("081019", 0.18), Color("f4edd8", 0.10), 1, 8))
	
	if read_only:
		# 在唯讀地圖彈窗內，加入水墨地圖底紙，避免直接疊在戰鬥/奇遇背景上而雜亂
		var bg_tex: TextureRect = TextureRect.new()
		bg_tex.texture = load("res://assets/art/map_bg_ink.png") as Texture2D
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_tex.modulate = Color(0.7, 0.7, 0.7, 0.9)
		map_panel.add_child(bg_tex)

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
	# 預設 MOUSE_FILTER_STOP 會吞掉 ScrollContainer 偵測 drag 所需的觸控事件，
	# 導致 Android 上「只有右側空白能滑動、地圖內容區域滑不動」。
	# IGNORE = 讓事件直接穿過 map_area，子節點 (map_node_button) 仍能自己處理點擊。
	map_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(map_area)
	map_area.add_child(_build_map_status_banner(read_only))
	map_area.add_child(_build_map_row_markers(total_rows, content_size))
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
			var node_button: Button = _map_node_button(node_data, row_index, read_only)
			var node_index: int = int(node_data.get("index", 0))
			node_button.position = _map_node_position(row_index, node_index, row.size(), total_rows, map_area.custom_minimum_size)
			map_area.add_child(node_button)
			node_buttons.append({"button": node_button, "row": row_index, "index": node_index})
	call_deferred("_refresh_map_link_layer", line_layer, node_buttons)
	call_deferred("_focus_map_row", scroll, _map_focus_anchor(total_rows, content_size), content_size)
	return map_panel

func _clear_map_legend() -> void:
	if map_legend_panel != null and is_instance_valid(map_legend_panel):
		var legend_parent: Node = map_legend_panel.get_parent()
		if legend_parent is CanvasLayer:
			legend_parent.queue_free()
		else:
			map_legend_panel.queue_free()
	map_legend_panel = null

func _build_map_legend(compact: bool = false) -> Control:
	var entries: Array = [
		{"type": "battle",     "color": Color("e2c486"), "label": "戰鬥"},
		{"type": "boss",       "color": Color("f8d29c"), "label": "Boss"},
		{"type": "rest",       "color": Color("f4a13a"), "label": "休息"},
		{"type": "event",      "color": Color("e2cdff"), "label": "奇遇"},
		{"type": "shop",       "color": Color("e4c66a"), "label": "商店"},
		{"type": "black_shop", "color": Color("e2a86b"), "label": "黑店"},
	]
	var legend_width: float = 132.0 if compact else 164.0
	var row_h: float = 26.0 if compact else 32.0
	var legend_height: float = (22.0 if compact else 28.0) + entries.size() * row_h
	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -legend_width - 12.0
	panel.offset_top = 12.0
	panel.offset_right = -12.0
	panel.offset_bottom = 12.0 + legend_height
	panel.custom_minimum_size = Vector2(legend_width, legend_height)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 220
	panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("12202d", 0.85), Color("c8b46f", 0.6), 2, 10))
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var title: Label = Label.new()
	title.text = "圖例"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", ThemeColors.HIGHLIGHT_GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	for entry: Dictionary in entries:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon: MapNodeIcon = MapNodeIcon.new()
		icon.custom_minimum_size = Vector2(26, 26)
		icon.set_type(String(entry["type"]), entry["color"])
		icon.set_visual_state("selectable")
		row.add_child(icon)
		var label: Label = Label.new()
		label.text = String(entry["label"])
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		vbox.add_child(row)
	return panel

func _build_map_status_banner(read_only: bool = false) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	panel.offset_left = 20
	panel.offset_top = 18
	panel.offset_right = 360
	panel.offset_bottom = 82
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIFactory.style_box(Color("12202d", 0.74), Color("d0bf86", 0.32), 1, 14))
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var title: String = "第 %d / %d 層" % [run_state.encounter_index + 1, run_state.encounter_choices.size()]
	var title_label: Label = UIFactory.card_label(title, 16, ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_label)
	var hint_text: String = "請選擇發亮節點前進" if run_state.encounter_index < run_state.encounter_choices.size() else "前往下一場遭遇"
	if read_only:
		hint_text = "唯讀檢視中，點擊外部關閉"
	var hint_label: Label = UIFactory.card_label(hint_text, 12, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint_label)
	return panel

func _build_map_row_markers(total_rows: int, area_size: Vector2) -> Control:
	var layer: Control = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for row_index: int in range(total_rows):
		var row_label: Label = Label.new()
		row_label.text = "第 %d 層" % [row_index + 1]
		row_label.position = Vector2(26, _map_node_position(row_index, 0, 1, total_rows, area_size).y + 26.0)
		row_label.add_theme_font_size_override("font_size", 12)
		row_label.add_theme_color_override("font_color", Color("24303c", 0.56))
		row_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(row_label)
	return layer

func _map_content_size(total_rows: int) -> Vector2:
	return Vector2(1080, max(1160.0, 340.0 + float(total_rows) * 270.0))

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
	var top_margin: float = 108.0
	var bottom_margin: float = 130.0
	var left_margin: float = 110.0
	var right_margin: float = 90.0
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
	var row_sway: float = sin(float(row_index) * 0.82 + 0.2) * 20.0
	var node_sway: float = sin(float(row_index) * 1.18 + float(node_index) * 1.35) * 12.0
	var bend_bias: float = cos(float(row_index + node_index) * 1.05) * 10.0
	var x: float = left_margin + usable_width * normalized_x + row_sway + node_sway + bend_bias
	var y_offset: float = cos(float(row_index) * 1.08 + float(node_index) * 0.8) * 8.0
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

func _map_node_button(node_data: Dictionary, row_index: int, read_only: bool = false) -> Button:
	var node_index: int = int(node_data.get("index", 0))
	var button: Button = _route_node_button(node_data, row_index, read_only)
	var selectable: bool = _is_map_node_selectable(row_index, node_index)
	var selected: bool = row_index < run_state.chosen_map_path.size() and run_state.chosen_map_path[row_index] == node_index
	var completed: bool = row_index < run_state.encounter_index
	button.custom_minimum_size = Vector2(76, 92)
	button.text = _map_node_compact_text(node_data, row_index, selected)
	button.disabled = not selectable
	button.focus_mode = Control.FOCUS_NONE
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_map_node_button(button, node_data, selected, selectable, completed)
	# 透明 disabled stylebox — 已通過 / 未連通 都不用 border color 標示，
	# 視覺差異由 modulate（變暗）+ 之後要替換的 selected/unselected 圖檔承擔
	button.add_theme_stylebox_override("disabled", UIFactory.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 28))
	button.add_theme_color_override("font_disabled_color", Color("25313b", 0.55))
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "boss":
		button.custom_minimum_size = Vector2(92, 110)
	call_deferred("_animate_map_node", button, selected, selectable, node_type == "boss")
	return button

func _style_map_node_button(button: Button, node_data: Dictionary, selected: bool, selectable: bool, completed: bool = false) -> void:
	# 全部狀態統一透明 bg + 無 border —
	# 已通過/已選/可選的視覺差異交給 modulate（變暗）+ 之後要替換的圖檔
	button.add_theme_stylebox_override("normal", UIFactory.style_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 28))
	button.add_theme_stylebox_override("hover", UIFactory.style_box(Color("f4edd8", 0.08), Color(0, 0, 0, 0), 0, 28))
	button.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("f4edd8", 0.12), Color(0, 0, 0, 0), 0, 28))
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
		var icon_dim: float = 72.0 if node_type == "boss" else 56.0
		# 當前可前往 / 已選的節點放大一點，更醒目
		if (selectable or selected) and node_type != "boss":
			icon_dim = 68.0
		icon.custom_minimum_size = Vector2(icon_dim, icon_dim)
		icon.position.y = max(0.0, icon.position.y - 8.0)
		if icon.has_method("set_highlight"):
			icon.call("set_highlight", selectable and not selected)
		if icon.has_method("set_visual_state"):
			var visual_state: String = "locked"
			if completed:
				visual_state = "completed"
			elif selected:
				visual_state = "selected"
			elif selectable:
				visual_state = "selectable"
			icon.call("set_visual_state", visual_state)
	var label: Label = null
	if button.has_meta("route_label"):
		label = button.get_meta("route_label") as Label
	if label != null:
		label.text = ""
		label.custom_minimum_size = Vector2(0, 0)
		label.visible = false
	if completed:
		button.modulate = Color(0.92, 0.94, 0.95, 0.88)
	elif not selectable and not selected:
		# 未抵達節點：不再大幅變暗到看不清，僅略微降低存在感
		button.modulate = Color(0.84, 0.86, 0.90, 0.86)
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
	if node_type == "boss":
		var boss_enemy: EnemyData = node_data.get("enemy") as EnemyData
		if boss_enemy == null:
			return "Boss"
		return "Boss\n%s" % boss_enemy.display_name
	var enemies_arr: Array = node_data.get("enemies", []) as Array
	if enemies_arr.is_empty():
		return "戰鬥"
	var first_e: EnemyData = enemies_arr[0] as EnemyData
	if enemies_arr.size() == 1:
		return "戰鬥\n%s" % first_e.display_name
	return "戰鬥\n%s 等 %d 敵" % [first_e.display_name, enemies_arr.size()]

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
	if dbg_test_mode and row_index >= run_state.encounter_index:
		return true
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

func choose_route_node(node_data: Dictionary, target_row: int = -1) -> void:
	var node_index: int = int(node_data.get("index", 0))
	if dbg_test_mode and target_row > run_state.encounter_index:
		while run_state.chosen_map_path.size() < target_row:
			run_state.chosen_map_path.append(-1)
		run_state.encounter_index = target_row
	if run_state.chosen_map_path.size() > run_state.encounter_index:
		run_state.chosen_map_path[run_state.encounter_index] = node_index
	else:
		while run_state.chosen_map_path.size() < run_state.encounter_index:
			run_state.chosen_map_path.append(-1)
		run_state.chosen_map_path.append(node_index)
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		resolve_rest_node()
	elif node_type == "event":
		run_state.current_event_variant = String(node_data.get("event_variant", "shrine"))
		show_event_node()
	elif node_type == "shop":
		open_shop_node(bool(node_data.get("black_market", false)))
	elif node_type == "boss":
		assert(node_data.has("enemy"), "Boss 節點缺少 enemy 資料：%s" % node_data)
		start_next_battle(node_data["enemy"] as EnemyData)
	else:
		assert(node_data.has("enemies"), "戰鬥節點缺少 enemies 資料：%s" % node_data)
		start_next_battle(node_data["enemies"] as Array)

func start_next_battle(enemies: Variant) -> void:
	# enemies 可為單一 EnemyData 或 Array（地圖多敵節點）
	var is_boss: bool = false
	if enemies is EnemyData:
		is_boss = Ascension.is_boss_id((enemies as EnemyData).id)
	elif enemies is Array:
		for e: Variant in (enemies as Array):
			if e is EnemyData and Ascension.is_boss_id((e as EnemyData).id):
				is_boss = true
				break
	_play_bgm("battle_boss" if is_boss else "battle_normal")
	battle = BattleController.new()
	battle.setup(run_state, selected_character, enemies)
	# Boss phase 2 變身動畫（如拜月教主 → 水魔獸）
	battle.phase_transitioned.connect(_on_phase_transitioned)
	var mult: float = Ascension.enemy_hp_multiplier(run_state.ascension_level, is_boss)
	if mult != 1.0:
		var enemy_slots: Array = battle.state.get("enemies", []) as Array
		for slot_v: Variant in enemy_slots:
			var slot: Dictionary = slot_v as Dictionary
			var scaled_max: int = max(1, int(round(float(slot.get("max_hp", 0)) * mult)))
			slot["max_hp"] = scaled_max
			slot["hp"] = scaled_max
		battle._sync_active_enemy_to_state()
	battle_end_pending = false
	_build_battle_scene()
	_start_player_turn()

func _build_battle_scene() -> void:
	_set_background(_battle_background_path())
	_clear_root()
	_show_title_bar()
	if _potion_overlay != null:
		_potion_overlay.visible = false
	var viewport_size: Vector2 = get_viewport_rect().size
	_battle_compact = true
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 4 if _battle_compact else 6)
	root.add_child(screen)
	relic_strip = HBoxContainer.new()
	relic_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_strip.add_theme_constant_override("separation", 4)
	relic_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	screen.add_child(relic_strip)
	_refresh_relic_strip()
	_build_battle_potion_strip(screen)
	var arena: HBoxContainer = HBoxContainer.new()
	arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 24)
	screen.add_child(arena)
	# 後排 + 隊長綁成一個「隊伍站位」群組：負分隔讓隊長肖像疊在後排前面、
	# 後排從隊長身後斜向探出，形成有景深的陣形（而非並排的獨立格子）。
	var has_bench: bool = run_state != null and run_state.characters.size() > 1
	var party_group: HBoxContainer = HBoxContainer.new()
	party_group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	party_group.alignment = BoxContainer.ALIGNMENT_END
	party_group.add_theme_constant_override("separation", -42 if has_bench else 0)
	arena.add_child(party_group)
	_build_bench_widget(party_group)
	_build_player_widget(party_group)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.add_child(spacer)
	_build_enemy_row(arena)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6 if _battle_compact else 14)
	screen.add_child(bottom)
	_build_left_dock(bottom)
	hand_row = HandFan.new()
	hand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_row.custom_minimum_size = Vector2(0, 260 if _battle_compact else 320)
	hand_row.hand_base_lift = 0.0 if _battle_compact else 40.0
	bottom.add_child(hand_row)
	_build_right_dock(bottom)

func _build_bench_widget(parent: HBoxContainer) -> void:
	# 後排不再是一格格獨立的金邊盒子，而是去背肖像「斜向交疊」站在隊長身後，
	# 偏暗往後退、最近的後援疊在最上層。手動定位 → 用 Control 當容器。
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(118, 0)
	holder.size_flags_horizontal = 0
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = false  # 允許肖像略微溢出右緣、疊向隊長
	parent.add_child(holder)
	bench_strip = holder
	_refresh_bench_strip()  # 後排內容會在 _refresh_battle 持續刷新

func _refresh_bench_strip() -> void:
	if bench_strip == null or not is_instance_valid(bench_strip):
		return
	for child: Node in bench_strip.get_children():
		child.queue_free()
	if battle == null or run_state == null or run_state.characters.size() <= 1:
		bench_strip.custom_minimum_size = Vector2(0, 0)
		return  # 單人隊不顯示 bench
	var players: Array = battle.state.get("players", []) as Array
	var active: int = int(battle.state.get("active_player_index", 0))
	var bench_indices: Array[int] = []
	for i: int in range(players.size()):
		if i != active:
			bench_indices.append(i)
	if bench_indices.is_empty():
		bench_strip.custom_minimum_size = Vector2(0, 0)
		return
	bench_strip.custom_minimum_size = Vector2(118, 0)
	var n: int = bench_indices.size()
	# 由「最遠」往「最近」加 child：先加的畫在底層（被後加的蓋住）。
	# rank 0 = 最靠近隊長的第一後援（最大、最亮、最靠右下、畫最上層）。
	for draw_order: int in range(n):
		var rank: int = n - 1 - draw_order
		var bi: int = bench_indices[rank]
		var node: Control = _bench_portrait(bi, players[bi] as Dictionary, rank)
		bench_strip.add_child(node)
		if _pending_revive_indices.has(bi):
			UIFactory.flash_node(node, Color(1.6, 1.5, 0.7), 0.7)
	_pending_revive_indices.clear()

func _bench_portrait(index: int, player_data: Dictionary, rank: int) -> Control:
	# rank 0 = front-most 後援（最大最亮，貼著隊長）；rank 越大越往左後方退、越暗越小。
	var character: CharacterData = run_state.characters[index] if index < run_state.characters.size() else null
	if character == null:
		return Control.new()
	var hp: int = int(player_data.get("hp", 0))
	var max_hp_v: int = int(player_data.get("max_hp", 1))
	var alive: bool = hp > 0
	# 尺寸 / 站位：front 96、每往後一階縮 16；後排往左上錯開製造交疊景深
	var psize: float = max(64.0, 96.0 - rank * 16.0)
	var off_x: float = 22.0 - rank * 14.0   # rank0 貼齊 holder 右緣、疊向隊長；後排往左退
	var off_y: float = rank * 54.0          # 後排往上錯開，與前一個交疊約 40 px
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = Vector2(psize, psize)
	wrap.size = Vector2(psize, psize)
	wrap.pivot_offset = Vector2(psize * 0.5, psize * 0.5)
	# 錨定到 holder 底部，往上堆疊（站在同一條地平線上）
	wrap.anchor_left = 0.0
	wrap.anchor_right = 0.0
	wrap.anchor_top = 1.0
	wrap.anchor_bottom = 1.0
	wrap.offset_left = off_x
	wrap.offset_right = off_x + psize
	wrap.offset_top = -off_y - psize
	wrap.offset_bottom = -off_y
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP if alive else Control.MOUSE_FILTER_IGNORE
	# 去背肖像（無邊框盒子）。後排偏暗偏冷往後退，讓隊長在視覺上跳出來。
	var portrait: TextureRect = UIFactory.portrait_rect(character.portrait_path, Vector2(psize, psize), true)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if alive:
		var dim: float = 0.90 - rank * 0.16
		portrait.modulate = Color(dim, dim, min(1.0, dim + 0.06))
	else:
		portrait.modulate = Color(0.08, 0.09, 0.13, 0.92)  # 倒下 = 暗色剪影
	wrap.add_child(portrait)
	# 細 HP pip（取代原本的金邊盒 + 文字 HP），貼在肖像底部
	if alive:
		wrap.add_child(_bench_hp_pip(psize, float(hp) / float(max(1, max_hp_v))))
	else:
		var ko: Label = UIFactory.card_label("✕", 20, Color("c84a3a", 0.9), HORIZONTAL_ALIGNMENT_CENTER)
		ko.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		ko.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(ko)
	# 點擊切換 + hover 提亮/上浮（無 stylebox，純肖像互動）
	if alive:
		var captured: int = index
		var pnode: TextureRect = portrait
		wrap.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				var mb: InputEventMouseButton = event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_on_bench_pressed(captured))
		wrap.mouse_entered.connect(func() -> void:
			if is_instance_valid(wrap):
				wrap.scale = Vector2(1.08, 1.08)
			if is_instance_valid(pnode):
				pnode.modulate = Color(1.0, 1.0, 1.0))
		wrap.mouse_exited.connect(func() -> void:
			if is_instance_valid(wrap):
				wrap.scale = Vector2.ONE
			if is_instance_valid(pnode):
				var d: float = 0.90 - rank * 0.16
				pnode.modulate = Color(d, d, min(1.0, d + 0.06)))
		wrap.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return wrap

func _bench_hp_pip(portrait_w: float, ratio: float) -> Control:
	# 極簡 HP 條：底色 + 填色兩層 ColorRect，貼在肖像底部置中
	var pip_w: float = portrait_w * 0.66
	var pip_h: float = 5.0
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.anchor_left = 0.5
	holder.anchor_right = 0.5
	holder.anchor_top = 1.0
	holder.anchor_bottom = 1.0
	holder.offset_left = -pip_w * 0.5
	holder.offset_right = pip_w * 0.5
	holder.offset_top = -pip_h - 2.0
	holder.offset_bottom = -2.0
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("0b1018", 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	var fill: ColorRect = ColorRect.new()
	fill.color = ThemeColors.HP_FILL
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_right = clamp(ratio, 0.0, 1.0)
	fill.anchor_bottom = 1.0
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(fill)
	return holder

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

# Boss 進入 phase 2 時播放變身動畫（如拜月教主→水魔獸）。
# 由 BattleController.phase_transitioned signal 觸發。
func _on_phase_transitioned(new_name: String) -> void:
	if enemy_portrait_wrap == null or not is_instance_valid(enemy_portrait_wrap):
		return
	# 1. 大幅震動 + 藍紫色光芒閃爍（水妖意象）
	UIFactory.shake_node(enemy_portrait_wrap, 22.0, 0.55)
	UIFactory.flash_node(enemy_portrait_wrap, Color(0.7, 1.1, 2.4), 0.55)
	# 2. 肖像膨脹回縮（覺醒感）+ 中段點換 texture（若 boss 有設 phase_2_portrait_path）
	var tween: Tween = enemy_portrait_wrap.create_tween()
	tween.tween_property(enemy_portrait_wrap, "scale", Vector2(1.22, 1.22), 0.20) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_swap_to_phase_2_portrait)  # 在 scale 峰值時換圖
	tween.tween_property(enemy_portrait_wrap, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# 3. 浮動覺醒文字
	_spawn_phase_reveal_text(new_name)
	# 4. 立刻刷新 UI（label 從 state["enemy_name"] 取新名）
	_refresh_battle()

# 換到 phase 2 肖像（若 boss 有提供 phase_2_portrait_path / phase_2_portrait_tint）
# 沒設定就維持原圖、原色。安全：任何欄位缺失都 fallback 到 phase 1。
func _swap_to_phase_2_portrait() -> void:
	if enemy_portrait_image == null or not is_instance_valid(enemy_portrait_image):
		return
	if battle == null or battle.enemy == null:
		return
	var phase_2_path: String = battle.enemy.phase_2_portrait_path
	if not phase_2_path.is_empty():
		var tex: Texture2D = UIFactory.load_texture(phase_2_path)
		if tex != null:
			enemy_portrait_image.texture = tex
			UIFactory.ground_portrait(enemy_portrait_image)  # 變身後重新貼地
	var phase_2_tint: Color = battle.enemy.phase_2_portrait_tint
	if phase_2_tint != Color.WHITE:
		enemy_portrait_image.modulate = phase_2_tint

func _spawn_phase_reveal_text(name: String) -> void:
	if enemy_portrait_wrap == null or not is_instance_valid(enemy_portrait_wrap):
		return
	var label: Label = Label.new()
	label.text = "%s 覺醒！" % name
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("c0ecff"))
	label.add_theme_color_override("font_outline_color", Color("0a1838"))
	label.add_theme_constant_override("outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 600
	add_child(label)
	# 居中於肖像上方
	var start_pos: Vector2 = enemy_portrait_wrap.global_position + Vector2(enemy_portrait_wrap.size.x * 0.5 - 130, -10)
	label.global_position = start_pos
	label.scale = Vector2(0.6, 0.6)
	label.modulate.a = 0.0
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(label, "modulate:a", 1.0, 0.20)
	t.tween_property(label, "scale", Vector2(1.18, 1.18), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector2.ONE, 0.28).set_delay(0.25)
	t.tween_property(label, "global_position", start_pos + Vector2(0, -60), 1.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.85)
	t.finished.connect(label.queue_free)

func _build_player_widget(parent: HBoxContainer) -> void:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(210 if _battle_compact else 280, 0)
	col.size_flags_horizontal = 0
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 2 if _battle_compact else 4)
	parent.add_child(col)
	player_feedback_label = UIFactory.feedback_label()
	col.add_child(_wrap_feedback_label(player_feedback_label))
	var portrait_size: Vector2 = Vector2(190, 220) if _battle_compact else Vector2(260, 290)
	col.add_child(_portrait_with_block_badge(selected_character.portrait_path, portrait_size, true, true))
	player_name_label = UIFactory.card_label(selected_character.display_name, 14 if _battle_compact else 18, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(player_name_label)
	var active_lv: int = run_state.character_levels[run_state.active_character_index] if run_state.character_levels.size() > run_state.active_character_index else 1
	player_level_label = UIFactory.card_label("Lv %d" % active_lv, 12, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(player_level_label)
	player_hp_bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	player_hp_value = UIFactory.card_label("", 11 if _battle_compact else 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_hp_bar_with_overlay(player_hp_bar, player_hp_value))
	player_status_line = UIFactory.card_label("", 11 if _battle_compact else 13, Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	player_status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(player_status_line)

func _build_enemy_row(parent: HBoxContainer) -> void:
	# Multi-Enemy 模式：水平 row 排列 1–3 敵；singular alias 自動指向 active 敵
	enemy_widgets.clear()
	var enemy_count: int = 0
	if battle != null and battle.state.has("enemies"):
		enemy_count = (battle.state["enemies"] as Array).size()
	if enemy_count == 0:
		return
	# 共用標題（顯示「敵將」或敵人總數）— 多敵時放在 row 上方
	var col_wrap: VBoxContainer = VBoxContainer.new()
	col_wrap.alignment = BoxContainer.ALIGNMENT_END
	col_wrap.add_theme_constant_override("separation", 4)
	col_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(col_wrap)
	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_font_size_override("font_size", 11 if _battle_compact else 16)
	enemy_label.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	col_wrap.add_child(enemy_label)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10 if _battle_compact else 18)
	col_wrap.add_child(row)
	enemy_row_container = row
	for i: int in range(enemy_count):
		var widget: Dictionary = _build_single_enemy_widget(i, enemy_count)
		row.add_child(widget["root"])
		enemy_widgets.append(widget)
	_set_active_enemy_aliases()

# 召喚物加入後 enemies 數量變動 → 重建 row 內容（保持 row container 本體）
func _rebuild_enemy_row_in_place() -> void:
	if battle == null or enemy_row_container == null or not is_instance_valid(enemy_row_container):
		return
	for child: Node in enemy_row_container.get_children():
		child.queue_free()
	enemy_widgets.clear()
	var enemy_count: int = (battle.state["enemies"] as Array).size()
	for i: int in range(enemy_count):
		var widget: Dictionary = _build_single_enemy_widget(i, enemy_count)
		enemy_row_container.add_child(widget["root"])
		enemy_widgets.append(widget)
	_set_active_enemy_aliases()

func _enemy_portrait_size_for(total: int) -> Vector2:
	# 1 敵=full size、2 敵=78%、3 敵=62%。compact mode 整體再縮 73%
	var base_w: float = 190.0 if _battle_compact else 260.0
	var base_h: float = 220.0 if _battle_compact else 290.0
	var scale_factor: float = 1.0
	if total == 2:
		scale_factor = 0.78
	elif total >= 3:
		scale_factor = 0.62
	return Vector2(base_w * scale_factor, base_h * scale_factor)

func _build_single_enemy_widget(idx: int, total: int) -> Dictionary:
	var slot: Dictionary = battle.state["enemies"][idx] as Dictionary
	var enemy_data: EnemyData = battle.enemies[idx]
	var portrait_size: Vector2 = _enemy_portrait_size_for(total)
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 2 if _battle_compact else 4)
	# 浮動 feedback label（傷害數字、狀態提示）
	var feedback_label: Label = UIFactory.feedback_label()
	col.add_child(_wrap_feedback_label(feedback_label))
	# 意圖標籤 (顯示於頭頂上)
	var intent_label: Label = UIFactory.card_label("",
		10 if (_battle_compact or total >= 2) else 12,
		ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(intent_label)
	# portrait wrap（含 block badge）
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = portrait_size
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var portrait: TextureRect = UIFactory.portrait_rect(enemy_data.portrait_path, portrait_size, true)
	portrait.set_meta("ground_box", portrait_size)
	UIFactory.ground_portrait(portrait)  # 底部對齊地面線
	portrait.modulate = enemy_data.portrait_tint
	portrait.flip_h = not enemy_data.default_facing_left
	wrap.add_child(portrait)
	var badge: BlockBadge = BlockBadge.new()
	var badge_size: float = 40.0 if total >= 2 else 48.0
	badge.custom_minimum_size = Vector2(badge_size, badge_size + 8)
	badge.size = Vector2(badge_size, badge_size + 8)
	badge.position = Vector2(6, portrait_size.y - (badge_size + 16))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(badge)
	# Click handler — 切 active 敵
	var captured_idx: int = idx
	wrap.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_on_enemy_portrait_clicked(captured_idx))
	col.add_child(wrap)
	# Name label
	var name_label: Label = UIFactory.card_label(String(slot["name"]),
		12 if (_battle_compact or total >= 2) else 16,
		Color("ffd9a3"), HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(name_label)
	# HP bar
	var hp_bar: ProgressBar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	var hp_value: Label = UIFactory.card_label("",
		10 if (_battle_compact or total >= 2) else 12,
		ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(_hp_bar_with_overlay(hp_bar, hp_value))
	# Status line
	var status_line: Label = UIFactory.card_label("",
		10 if (_battle_compact or total >= 2) else 12,
		Color("e8c97c"), HORIZONTAL_ALIGNMENT_CENTER)
	status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(status_line)
	return {
		"root": col,
		"wrap": wrap,
		"portrait": portrait,
		"name_label": name_label,
		"hp_bar": hp_bar,
		"hp_value": hp_value,
		"block_badge": badge,
		"status_line": status_line,
		"feedback_label": feedback_label,
		"intent_label": intent_label,
		"enemy_idx": idx,
	}

func _on_enemy_portrait_clicked(idx: int) -> void:
	if battle == null:
		return
	if battle.set_active_enemy(idx):
		_set_active_enemy_aliases()
		_refresh_battle()

# 把 singular enemy_* 變數指向 active 敵的 widget refs（向後相容 animation 等程式碼）
func _set_active_enemy_aliases() -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var idx: int = battle._active_enemy_index()
	idx = clamp(idx, 0, enemy_widgets.size() - 1)
	var w: Dictionary = enemy_widgets[idx]
	enemy_portrait_wrap = w["wrap"]
	enemy_portrait_image = w["portrait"]
	enemy_name_label = w["name_label"]
	enemy_hp_bar = w["hp_bar"]
	enemy_hp_value = w["hp_value"]
	enemy_block_badge = w["block_badge"]
	enemy_status_line = w["status_line"]
	enemy_feedback_label = w["feedback_label"]

# 每次 state 變動後刷新所有敵人 widget；同時套用 active 高亮 / 死敵 dim / 消失
func _refresh_enemy_widgets() -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	# 數量變動（召喚物加入 / 戰場 reset） → 重建 row 後再 refresh
	if enemy_slots.size() != enemy_widgets.size():
		_rebuild_enemy_row_in_place()
	var active_idx: int = battle._active_enemy_index()
	for i: int in range(enemy_widgets.size()):
		if i >= enemy_slots.size():
			continue
		var slot: Dictionary = enemy_slots[i] as Dictionary
		var w: Dictionary = enemy_widgets[i]
		var name_label: Label = w["name_label"]
		var hp_bar: ProgressBar = w["hp_bar"]
		var hp_value: Label = w["hp_value"]
		var block_badge: BlockBadge = w["block_badge"]
		var status_line: Label = w["status_line"]
		var wrap: Control = w["wrap"]
		if name_label != null and is_instance_valid(name_label):
			name_label.text = String(slot["name"])
		_refresh_combatant_hp(hp_bar, hp_value, int(slot["hp"]), int(slot["max_hp"]))
		_update_poison_preview(hp_bar, int(slot["hp"]), int(slot["max_hp"]), int(slot["poison"]))
		block_badge.set_amount(int(slot["block"]))
		status_line.text = UIFactory.status_summary(int(slot["poison"]), int(slot["weak"]), int(slot["vulnerable"]))
		
		var intent_label: Label = w.get("intent_label")
		if intent_label != null and is_instance_valid(intent_label):
			var enemy_idx: int = int(w["enemy_idx"])
			var action: Dictionary = battle._action_for_enemy(enemy_idx)
			if action.is_empty() or int(slot["hp"]) <= 0:
				intent_label.text = ""
			else:
				var badge_str: String = CardFormat.intent_badge(action)
				var intent_name: String = String(action.get("intent", ""))
				var damage_text: String = ""
				if CardFormat.action_has_damage(action):
					var temp_state: Dictionary = battle.state.duplicate()
					temp_state["enemy_weak"] = int(slot.get("weak", 0))
					var pred: Dictionary = CardFormat.predict_enemy_damage(action, temp_state)
					var dealt: int = int(pred["dealt"])
					var blocked: int = int(pred["blocked"])
					if blocked > 0:
						damage_text = " 實受%d(擋%d)" % [dealt, blocked]
					elif dealt < int(pred["raw"]):
						damage_text = " 實受%d" % dealt
					else:
						damage_text = " %d點" % dealt
				intent_label.text = "%s %s%s" % [badge_str, intent_name, damage_text]
		
		# 判斷生死與消失邏輯
		var hp_now: int = int(slot["hp"])
		var last_hp: int = int(w.get("last_hp", hp_now))
		w["last_hp"] = hp_now
		
		if hp_now <= 0:
			if last_hp > 0:
				# 剛剛死亡！觸發消失動畫
				w["is_dying"] = true
				_animate_enemy_death(w)
			
			if w.get("dead_hidden", false):
				w["root"].visible = false
			elif w.get("is_dying", false):
				w["root"].visible = true
				wrap.modulate = Color(0.32, 0.32, 0.32, wrap.modulate.a)
			else:
				# 已經死亡（例如非戰鬥卡牌觸發的重設，或初次刷新）
				w["root"].visible = false
				w["dead_hidden"] = true
		else:
			w["root"].visible = true
			w["dead_hidden"] = false
			w["is_dying"] = false
			# 視覺狀態：active 全亮、其他半暗
			if i == active_idx:
				wrap.modulate = Color.WHITE
			else:
				wrap.modulate = Color(0.72, 0.72, 0.78)

func _animate_enemy_death(w: Dictionary) -> void:
	var root: Control = w["root"]
	var wrap: Control = w["wrap"]
	if root == null or not is_instance_valid(root) or wrap == null or not is_instance_valid(wrap):
		return
	var tween: Tween = create_tween()
	# 延遲 0.4 秒，讓傷害數字與震動特效先跑
	tween.tween_interval(0.4)
	# 漸隱透明度
	tween.tween_property(wrap, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		if root != null and is_instance_valid(root):
			root.visible = false
		w["dead_hidden"] = true
		w["is_dying"] = false
		if wrap != null and is_instance_valid(wrap):
			wrap.modulate.a = 1.0
	)


func _build_battle_potion_strip(parent: VBoxContainer) -> void:
	var slot_size: int = 28 if _battle_compact else 34
	var strip: HBoxContainer = HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 6)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(strip)
	_battle_potion_strip = strip
	_potion_buttons.clear()
	for i: int in range(RunState.MAX_POTION_SLOTS):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(slot_size, slot_size)
		btn.add_theme_font_size_override("font_size", 9 if _battle_compact else 10)
		var idx: int = i
		# 點藥草不再立即使用，先彈出說明 + 確認
		btn.pressed.connect(func(): _show_use_potion_confirm(idx))
		_potion_buttons.append(btn)
		strip.add_child(btn)
	_refresh_potion_buttons()

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
	var btn_h: float = 26.0 if _battle_compact else 32.0
	var btn_f: int = 11 if _battle_compact else 13
	draw_pile_button = _button("抽牌堆 (0)")
	draw_pile_button.add_theme_font_size_override("font_size", btn_f)
	draw_pile_button.custom_minimum_size = Vector2(0, btn_h)
	draw_pile_button.pressed.connect(show_draw_pile_view)
	dock.add_child(draw_pile_button)

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

func _title_bar_panel_style() -> StyleBoxFlat:
	# 不透明深色底 + 僅底邊金線，做成「獨立的一條頂列」而非浮在地圖上的半透明面板
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("12161f")
	sb.border_color = ThemeColors.BORDER_GOLD
	sb.border_width_bottom = 2
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb

func _build_title_bar() -> void:
	title_bar = PanelContainer.new()
	# 獨立的頂部資訊列：不透明、整條貼齊螢幕頂端，與地圖分開（不再半透明浮在地圖上）
	title_bar.add_theme_stylebox_override("panel", _title_bar_panel_style())
	title_bar.set_anchors_preset(Control.PRESET_TOP_WIDE, false)
	title_bar.offset_left = 0
	title_bar.offset_top = 0
	title_bar.offset_right = 0
	title_bar.offset_bottom = TITLE_BAR_HEIGHT
	title_bar.visible = false
	title_bar.z_index = 50
	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(title_bar)
	var pad: MarginContainer = MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 4)
	pad.add_theme_constant_override("margin_bottom", 4)
	title_bar.add_child(pad)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	pad.add_child(hbox)

	title_bar_name_label = UIFactory.card_label("", 16, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	title_bar_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_bar_name_label.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(title_bar_name_label)

	title_bar_hp_bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
	title_bar_hp_bar.custom_minimum_size = Vector2(150, 14)
	title_bar_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(title_bar_hp_bar)
	title_bar_hp_label = UIFactory.card_label("", 13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	title_bar_hp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(title_bar_hp_label)

	title_bar_gold_label = UIFactory.card_label("", 14, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title_bar_gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(title_bar_gold_label)

	title_bar_observe_label = UIFactory.card_label("", 14, ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	title_bar_observe_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_bar_observe_label.tooltip_text = "觀察次數：在奇遇中花 1 點揭露隱藏選項"
	hbox.add_child(title_bar_observe_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

	# 藥品條：戰鬥外顯示在 title bar 內；戰鬥場景的 _battle_potion_strip 接手時這條會被隱藏
	if _potion_overlay != null and is_instance_valid(_potion_overlay):
		var prev_parent: Node = _potion_overlay.get_parent()
		if prev_parent != null:
			prev_parent.remove_child(_potion_overlay)
		hbox.add_child(_potion_overlay)

	title_bar_relics_button = _title_bar_button("遺物 (0)", _show_battle_relics_popup)
	hbox.add_child(title_bar_relics_button)
	hbox.add_child(_title_bar_button("查看牌組", func() -> void: show_deck_view()))
	hbox.add_child(_title_bar_button("查看地圖", _show_map_overview_popup))

	var gear: Button = _title_bar_button("⚙", _toggle_pause_menu)
	gear.custom_minimum_size = Vector2(36, 30)
	gear.add_theme_font_size_override("font_size", 18)
	gear.tooltip_text = "暫停 / 設定"
	hbox.add_child(gear)

func _title_bar_button(text: String, action: Callable) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(76, 30)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(action)
	return btn

func _show_title_bar() -> void:
	if title_bar == null:
		_build_title_bar()
	title_bar.visible = true
	if root != null:
		root.add_theme_constant_override("margin_top", int(TITLE_BAR_HEIGHT) + 24)
	_refresh_title_bar()

func _hide_title_bar() -> void:
	if title_bar != null:
		title_bar.visible = false
	if root != null:
		root.add_theme_constant_override("margin_top", 20)

func _refresh_title_bar() -> void:
	if title_bar == null or not title_bar.visible or run_state == null:
		return
	var char_data: CharacterData = null
	var hp: int = 0
	var max_hp_v: int = 0
	var lv: int = 1
	if run_state.characters.size() > 0:
		var idx: int = clamp(run_state.active_character_index, 0, run_state.characters.size() - 1)
		char_data = run_state.characters[idx]
		hp = run_state.character_hps[idx] if idx < run_state.character_hps.size() else 0
		max_hp_v = run_state.character_max_hps[idx] if idx < run_state.character_max_hps.size() else 1
		lv = run_state.character_levels[idx] if idx < run_state.character_levels.size() else 1
	if char_data == null:
		char_data = selected_character
		hp = run_state.hp
		max_hp_v = run_state.max_hp
	var name_text: String = ""
	if char_data != null:
		name_text = "%s   Lv %d" % [char_data.display_name, lv]
	title_bar_name_label.text = name_text
	title_bar_hp_bar.max_value = max(1, max_hp_v)
	title_bar_hp_bar.value = hp
	title_bar_hp_label.text = "%d / %d" % [hp, max_hp_v]
	title_bar_gold_label.text = "銅錢 %d" % run_state.gold
	if title_bar_observe_label != null:
		title_bar_observe_label.text = "觀察 %d" % run_state.observe_tokens
	title_bar_relics_button.text = "遺物 (%d)" % run_state.relics.size()

func _build_potion_overlay() -> void:
	# 藥品按鈕條：由 _build_title_bar 將此 HBox 插入 title bar 內（戰鬥外顯示在頂部、不再卡在畫面左下角）。
	# 戰鬥中由 left_dock 自己的 _battle_potion_strip 接手，本 overlay 會被隱藏避免重複。
	_potion_overlay = HBoxContainer.new()
	_potion_overlay.add_theme_constant_override("separation", 4)
	_potion_overlay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_potion_overlay.visible = false
	# 不在這裡 add_child；由 title bar 決定父節點
	_potion_overlay_buttons.clear()
	for i: int in range(RunState.MAX_POTION_SLOTS):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.add_theme_font_size_override("font_size", 10)
		var idx: int = i
		btn.pressed.connect(func(): _discard_potion_prompt(idx))
		_potion_overlay_buttons.append(btn)
		_potion_overlay.add_child(btn)

func _update_potion_button(btn: Button, slot: int, in_battle: bool = true) -> void:
	if slot >= run_state.potions.size():
		# 空槽：完全隱藏，避免一排「—」的視覺雜訊
		btn.visible = false
		return
	btn.visible = true
	var potion: Dictionary = run_state.potions[slot]
	var name: String = String(potion.get("display_name", "?"))
	var tip_action: String = "（點擊查看 → 確認使用）" if in_battle else "（點擊丟棄）"
	btn.tooltip_text = "%s\n%s\n%s" % [name, String(potion.get("description", "")), tip_action]
	btn.disabled = false
	var rarity_col: Color = PotionCatalog.rarity_color(potion)
	if in_battle:
		btn.add_theme_stylebox_override("normal", UIFactory.style_box(Color("1a2230"), rarity_col, 1, 6))
		btn.add_theme_stylebox_override("hover", UIFactory.style_box(Color("2a3040"), rarity_col, 2, 6))
		btn.add_theme_stylebox_override("pressed", UIFactory.style_box(Color("0e141e"), rarity_col, 2, 6))
	else:
		# 戰鬥外（title bar）：去除彩色邊框/底色，只留藥品圖
		var flat: StyleBoxEmpty = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", flat)
		btn.add_theme_stylebox_override("hover", flat)
		btn.add_theme_stylebox_override("pressed", flat)
		btn.add_theme_stylebox_override("focus", flat)
	btn.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
	btn.remove_theme_color_override("font_disabled_color")
	
	# Load potion texture icon if available
	var art_path: String = "res://assets/art/potions/%s.png" % potion.get("id", "")
	var texture: Texture2D = UIFactory.load_texture(art_path)
	if texture != null:
		btn.text = ""
		btn.icon = texture
		btn.expand_icon = true
	else:
		btn.text = name.substr(0, 4) if name.length() > 4 else name
		btn.icon = null

func _refresh_potion_buttons() -> void:
	for i: int in range(_potion_buttons.size()):
		if is_instance_valid(_potion_buttons[i]):
			_update_potion_button(_potion_buttons[i], i, true)

func _refresh_potion_overlay_buttons() -> void:
	# 完全沒藥草時整條 strip 也隱藏；有藥草時 strip 顯示、空槽 button visible=false
	if _potion_overlay != null and is_instance_valid(_potion_overlay):
		if run_state == null or run_state.potions.is_empty():
			_potion_overlay.visible = false
			return
		# 若這個函式被呼叫，預期當前 screen 是非戰鬥（戰鬥場景另有 _potion_buttons）；
		# 注意 start_next_battle 會主動把 overlay 設為 false，所以不會在戰鬥中誤露出
	for i: int in range(_potion_overlay_buttons.size()):
		_update_potion_button(_potion_overlay_buttons[i], i, false)

func _use_potion(slot: int) -> void:
	if battle == null or slot >= run_state.potions.size():
		return
	var potion: Dictionary = run_state.potions[slot]
	var effects: Array = potion.get("effects", []) as Array
	var before_hp: int = int(battle.state["player_hp"])
	var before_block: int = int(battle.state["player_block"])
	var _dead_before_pot: Array[int] = _snapshot_dead_bench()
	var log_lines: Array[String] = battle.resolver.resolve_effects_list(effects, battle.state)
	_pending_revive_indices = _detect_revived(_dead_before_pot)
	var drew: int = int(battle.state.get("pending_draw", 0))
	if drew > 0:
		battle.state["pending_draw"] = 0
		if battle.deck != null:
			battle.deck.draw(drew)
	run_state.potions.remove_at(slot)
	battle.battle_log.append_array(log_lines)
	_refresh_battle(drew > 0)
	var hp_delta: int = int(battle.state["player_hp"]) - before_hp
	var block_delta: int = int(battle.state["player_block"]) - before_block
	if hp_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, hp_delta, "heal")
	if block_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, block_delta, "block")

# 戰鬥中點藥草：先彈出說明 + 「使用 / 取消」，避免誤觸
func _show_use_potion_confirm(slot: int) -> void:
	if battle == null or slot >= run_state.potions.size():
		return
	var potion: Dictionary = run_state.potions[slot]
	var rarity_col: Color = PotionCatalog.rarity_color(potion)
	var center_wrap: CenterContainer = CenterContainer.new()
	center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_wrap.z_index = 300
	add_child(center_wrap)
	var popup: PanelContainer = PanelContainer.new()
	popup.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0b111a", 0.96), rarity_col, 2, 10))
	center_wrap.add_child(popup)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(box)
	box.add_child(UIFactory.card_label(String(potion.get("display_name", "?")), 22, rarity_col, HORIZONTAL_ALIGNMENT_CENTER))
	# 稀有度標籤（common / uncommon / rare）
	var rarity_text: String = "%s 藥草" % String(potion.get("rarity", "common")).capitalize()
	box.add_child(UIFactory.card_label(rarity_text, 12, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	
	# Icon
	var art_path: String = "res://assets/art/potions/%s.png" % potion.get("id", "")
	var texture: Texture2D = UIFactory.load_texture(art_path)
	if texture != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(72, 72)
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(rect)
		
	# 描述
	var desc: Label = UIFactory.card_label(String(potion.get("description", "")), 14, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(360, 0)
	box.add_child(desc)
	# 按鈕列
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(btn_row)
	var captured_slot: int = slot
	var cancel_btn: Button = _button("取消")
	cancel_btn.pressed.connect(func() -> void: center_wrap.queue_free())
	btn_row.add_child(cancel_btn)
	var use_btn: Button = _button("使用")
	use_btn.pressed.connect(func() -> void:
		center_wrap.queue_free()
		_use_potion(captured_slot))
	btn_row.add_child(use_btn)

func _discard_potion_prompt(slot: int) -> void:
	if slot >= run_state.potions.size():
		return
	var potion: Dictionary = run_state.potions[slot]
	var center_wrap: CenterContainer = CenterContainer.new()
	center_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_wrap.z_index = 300
	add_child(center_wrap)
	var popup: PanelContainer = PanelContainer.new()
	popup.add_theme_stylebox_override("panel", UIFactory.style_box(Color("0b111a", 0.96), ThemeColors.BORDER_GOLD, 2, 10))
	center_wrap.add_child(popup)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	popup.add_child(box)
	box.add_child(UIFactory.card_label(String(potion.get("display_name", "?")), 20, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER))
	
	# Icon
	var art_path: String = "res://assets/art/potions/%s.png" % potion.get("id", "")
	var texture: Texture2D = UIFactory.load_texture(art_path)
	if texture != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(64, 64)
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(rect)
		
	box.add_child(UIFactory.card_label(String(potion.get("description", "")), 13, Color("d8e0ec"), HORIZONTAL_ALIGNMENT_CENTER))
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(btn_row)
	var cancel_btn: Button = _button("取消")
	cancel_btn.pressed.connect(func() -> void: center_wrap.queue_free())
	btn_row.add_child(cancel_btn)
	var discard_btn: Button = _button("丟棄")
	var captured_slot: int = slot
	discard_btn.pressed.connect(func() -> void:
		if captured_slot < run_state.potions.size():
			run_state.potions.remove_at(captured_slot)
		center_wrap.queue_free()
		_refresh_potion_overlay_buttons())
	btn_row.add_child(discard_btn)

func _hp_bar_with_overlay(bar: ProgressBar, value_label: Label) -> Control:
	var bar_height: int = 18 if _battle_compact else 22
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = Vector2(0, bar_height)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.custom_minimum_size = Vector2(0, bar_height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(bar)
	# 毒傷預覽（StS 風）：血條上疊一段半透明綠，標示這回合 tick 會被蠱毒扣掉多少。
	# 疊在血條之上、數值文字之下；預設隱藏，由 _update_poison_preview 控制。
	var poison_preview: ColorRect = ColorRect.new()
	poison_preview.color = Color("6cc24a", 0.62)
	poison_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poison_preview.anchor_top = 0.0
	poison_preview.anchor_bottom = 1.0
	poison_preview.anchor_left = 1.0
	poison_preview.anchor_right = 1.0
	poison_preview.offset_left = 0.0
	poison_preview.offset_right = 0.0
	poison_preview.offset_top = 0.0
	poison_preview.offset_bottom = 0.0
	poison_preview.visible = false
	wrap.add_child(poison_preview)
	bar.set_meta("poison_preview", poison_preview)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_label.add_theme_constant_override("shadow_outline_size", 2)
	wrap.add_child(value_label)
	return wrap

func _portrait_with_block_badge(path: String, portrait_size: Vector2, show_full: bool, is_player: bool, tint: Color = Color.WHITE) -> Control:
	var wrap: Control = Control.new()
	wrap.custom_minimum_size = portrait_size
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # 維持 box 寬，地面線置中才準
	var portrait: TextureRect = UIFactory.portrait_rect(path, portrait_size, show_full)
	portrait.set_meta("ground_box", portrait_size)
	UIFactory.ground_portrait(portrait)  # 底部對齊地面線（取代置中）
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
		enemy_portrait_image = portrait  # 保留 ref 給 phase 2 變身換圖
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

func _snapshot_dead_bench() -> Array[int]:
	if battle == null:
		return []
	var dead: Array[int] = []
	var players: Array = battle.state.get("players", []) as Array
	var active: int = int(battle.state.get("active_player_index", 0))
	for i: int in range(players.size()):
		if i != active and int((players[i] as Dictionary).get("hp", 1)) <= 0:
			dead.append(i)
	return dead

func _detect_revived(was_dead: Array[int]) -> Array[int]:
	if battle == null or was_dead.is_empty():
		return []
	var revived: Array[int] = []
	var players: Array = battle.state.get("players", []) as Array
	for i: int in was_dead:
		if i < players.size() and int((players[i] as Dictionary).get("hp", 0)) > 0:
			revived.append(i)
	return revived

func play_card(card: CardData, source_button: Button = null) -> void:
	if battle_end_pending:
		return
	_clear_selected_hand_card()
	_cancel_end_turn_warning()
	var _dead_before: Array[int] = _snapshot_dead_bench()
	var result: Dictionary = battle.play_card(card)
	_pending_revive_indices = _detect_revived(_dead_before)
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
	match card.id:
		"lxy_wanjian", "lxy_wanjianguizong":
			_animate_wan_jian_jue_effect(card)
		"lxy_yujian":
			_animate_yu_jian_effect(card)
		"lxy_tianjian":
			_animate_tian_jian_effect(card)
		"lxy_jianzhen":
			_animate_jian_zhen_effect(card)
		"lxy_jiulong":
			_animate_jiu_long_effect(card)
		"lxy_xiaoyao_shenjian":
			_animate_xiaoyao_shenjian_effect(card)
		"lyr_qiankun":
			_animate_qian_kun_effect(card)
		"lyr_qijianzhi", "lyr_qijuejianqi":
			_animate_qi_jian_zhi_effect(card)
		"lyr_bianying":
			_animate_bian_ying_effect(card)
		"lyr_lielong":
			_animate_lie_long_effect(card)
		"lyr_wanlikuang":
			_animate_wan_li_kuang_effect(card)
		"zl_leizhou", "zl_leiguang", "zl_wuleizhou", "zl_shenlei", "zl_tianlei", "zl_kuanglei", "zl_xiaoleizhou", "zl_lianzhuzhou":
			_animate_lightning_effect(card)
		"zl_xuanbing", "zl_fengxuebing", "zl_bingzhou":
			_animate_ice_effect(card)
		"zl_yanzhou", "zl_sanmeizhenhuo":
			_animate_fire_effect(card)
		"zl_diliebeng", "zl_taishan":
			_animate_earth_effect(card)
		"zl_guanyin", "zl_wuqi", "zl_ganlin", "zl_shuiling":
			_animate_heal_effect(card)
		"anu_yufeng":
			_animate_yu_feng_effect(card)
		"anu_wanyi", "anu_wanyi_ls":
			_animate_wan_yi_effect(card)
		"anu_baozhagu":
			_animate_bao_zha_gu_effect(card)
		"anu_duzhen", "anu_lianduzhen", "anu_yanshazhou":
			_animate_du_zhen_effect(card)
		"anu_wuyuezhan", "anu_xuerenwu":
			_animate_wu_yue_zhan_effect(card)
		"lxy_jiushen":
			_animate_jiu_shen_effect(card)
		"lxy_feilong":
			_animate_fei_long_effect(card, result.get("stolen_item", {}) as Dictionary)
		"lxy_zuimeng":
			_animate_zui_meng_effect(card)
		"zl_mengshe", "zl_mengshe_ls":
			_animate_meng_she_effect(card)
		"zl_huihun":
			_animate_hui_hun_effect(card)
		"zl_xuanfengzhou", "zl_fengling":
			_animate_xuan_feng_effect(card)
		"lyr_yiyang":
			_animate_yi_yang_effect(card)
		"lyr_zhanlong":
			_animate_zhan_long_effect(card)
		"lyr_fenghuan", "lyr_yuehua":
			_animate_feng_huang_effect(card)
		"anu_gushen":
			_animate_gu_shen_effect(card)
		"anu_mihun", "anu_guijiang", "anu_guwang":
			_animate_confuse_effect(card)
		"anu_guzhang", "anu_duwu", "anu_sanshigu":
			_animate_poison_fog_effect(card)
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
	# Multi-Enemy 模式：begin_enemy_phase 回傳每隻敵人的 action（陣列）
	# Phase 4 UI 才會每敵顯示獨立 intent；目前先取 active 敵 (或首個非空) 作 preview
	var actions: Array[Dictionary] = battle.begin_enemy_phase()
	var preview_action: Dictionary = {}
	var preview_idx: int = battle._active_enemy_index()
	if preview_idx >= 0 and preview_idx < actions.size():
		preview_action = actions[preview_idx]
	if preview_action.is_empty():
		for a: Dictionary in actions:
			if not a.is_empty():
				preview_action = a
				break
	if not preview_action.is_empty():
		_show_enemy_action_preview(preview_action)
	_refresh_battle()
	await get_tree().create_timer(0.8).timeout
	if not preview_action.is_empty() and CardFormat.action_has_damage(preview_action):
		UIFactory.dash_node(enemy_portrait_wrap, Vector2(-1, 0), 36.0, 0.22)
		await get_tree().create_timer(0.1).timeout
	var result: Dictionary = battle.resolve_enemy_phase(actions)
	_process_battle_curses()
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
		# Event Branching P3：tree-triggered battle 不直接 game over
		if not run_state.pending_event_return.is_empty():
			_finish_event_tree_battle(false)
			return true
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
		# Event Branching P3：tree-triggered battle 不直接 game over
		if not run_state.pending_event_return.is_empty():
			_finish_event_tree_battle(false)
			return true
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
	# Event Branching P3：tree-triggered battle → 走簡化勝利流程，跑 victory_effects 後回地圖
	if not run_state.pending_event_return.is_empty():
		_finish_event_tree_battle(true)
		return
	if _event_battle_on_win.is_valid():
		var cb: Callable = _event_battle_on_win
		_event_battle_on_win = Callable()
		battle.complete_victory()
		for defeated_e: EnemyData in battle.enemies:
			Bestiary.mark_defeated(defeated_e.id)
		var gold: int = 0
		for defeated_e: EnemyData in battle.enemies:
			if not defeated_e.is_summoned:
				gold += _battle_gold_reward(defeated_e)
		run_state.gold += gold
		battle.add_log("獲得 %d 枚銅錢。" % gold)
		cb.call()
		return
	battle.complete_victory()
	for defeated_e: EnemyData in battle.enemies:
		Bestiary.mark_defeated(defeated_e.id)
	_grant_battle_exp()
	var gold_reward: int = 0
	for defeated_e: EnemyData in battle.enemies:
		if not defeated_e.is_summoned:
			gold_reward += _battle_gold_reward(defeated_e)
	# 聚寶盆：勝利額外金錢；P4 淨化符：勝利移除 1 張隨機 curse
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "battle_victory":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				match String(e.get("kind", "")):
					"gold_bonus":
						gold_reward += int(e.get("amount", 0))
					"remove_random_curse":
						var removed: String = _try_remove_random_curse()
						if not removed.is_empty():
							battle.add_log("淨化符：除去詛咒「%s」。" % removed)
	run_state.gold = run_state.gold + gold_reward
	battle.add_log("獲得 %d 枚銅錢。" % gold_reward)
	# Boss：三選一遺物；一般戰鬥 25% 機率自動掉裝備
	var was_boss: bool = false
	var boss_id_for_drop: String = ""
	for defeated_e: EnemyData in battle.enemies:
		if Ascension.is_boss_id(defeated_e.id):
			was_boss = true
			boss_id_for_drop = defeated_e.id
			break
	if was_boss:
		# Event Branching P5：boss 勝利補 1 個 observe token
		run_state.grant_observe_tokens(RunState.OBSERVE_TOKEN_BOSS_REWARD)
		var choices: Array[RelicData] = _make_boss_relic_choices(boss_id_for_drop)
		# Boss 流程：遺物三選一 → 稀有卡三選一 → potion drop → 推進地圖
		# （boss 永遠是該幕最後節點，故 card reward 必須在 act 轉場前插入）
		_after_boss_relic_choice = func() -> void:
			if run_state.potions.size() < RunState.MAX_POTION_SLOTS:
				if randf() < 0.6:
					var all_p: Array[Dictionary] = PotionCatalog.all()
					run_state.potions.append((all_p[randi() % all_p.size()]).duplicate())
			_boss_card_reward = true
			_after_card_reward = func() -> void:
				run_state.encounter_index = run_state.encounter_index + 1
				if run_state.act < 5:
					show_act_complete()
				else:
					show_result(true)
			show_card_reward()
		show_boss_relic_choice(choices)
		return
	# 一般戰鬥：自動 25% 掉裝備
	var dropped: RelicData = _try_random_relic_drop(0.25)
	if dropped != null:
		_add_relic_with_curse_effect(dropped)
	# 藥品掉落：一般 20%
	if run_state.potions.size() < RunState.MAX_POTION_SLOTS:
		if randf() < 0.2:
			var all_potions: Array[Dictionary] = PotionCatalog.all()
			run_state.potions.append((all_potions[randi() % all_potions.size()]).duplicate())
	run_state.encounter_index = run_state.encounter_index + 1
	if run_state.encounter_index >= run_state.encounter_choices.size():
		if run_state.act < 5:
			show_act_complete()
		else:
			show_result(true)
	else:
		show_card_reward()

func _make_boss_relic_choices(boss_id: String) -> Array[RelicData]:
	var choices: Array[RelicData] = []
	# 優先把 boss 專屬神器排在第一位（若未持有）
	for a: RelicData in RelicCatalog.artifacts():
		if a.boss_id == boss_id and not run_state.has_relic(a.id):
			choices.append(a.clone())
			break
	# 用 general pool 補滿 3 個
	var general_pool: Array[RelicData] = []
	for r: RelicData in RelicCatalog.generals():
		if not run_state.has_relic(r.id):
			general_pool.append(r.clone())
	general_pool.shuffle()
	var needed: int = 3 - choices.size()
	for i: int in range(min(needed, general_pool.size())):
		choices.append(general_pool[i])
	return choices

func show_boss_relic_choice(options: Array[RelicData]) -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var outer: VBoxContainer = VBoxContainer.new()
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	outer.add_theme_constant_override("separation", 18)
	panel.add_child(outer)
	outer.add_child(_title("Boss 戰利品", 32))
	var sub: Label = UIFactory.card_label("選擇一件遺物（共三選一）", 14, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	outer.add_child(sub)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	outer.add_child(row)
	for relic: RelicData in options:
		row.add_child(_boss_relic_choice_panel(relic))
	# 允許跳過（不強制取遺物）
	var skip_btn: Button = _button("跳過（不取遺物）")
	skip_btn.pressed.connect(func() -> void:
		if _after_boss_relic_choice.is_valid():
			_after_boss_relic_choice.call()
	)
	outer.add_child(skip_btn)

func _boss_relic_choice_panel(relic: RelicData) -> PanelContainer:
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(200, 300)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var icon: RelicIcon = RelicIcon.new()
	icon.custom_minimum_size = Vector2(90, 90)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	icon.set_relic(relic)
	var name_lbl: Label = UIFactory.card_label(relic.display_name, 16, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(name_lbl)
	var rarity_color: Color = ThemeColors.TEXT_DIM
	match relic.rarity:
		"uncommon": rarity_color = ThemeColors.HIGHLIGHT_GOLD
		"rare": rarity_color = Color("c87cf0")
		"legendary": rarity_color = ThemeColors.ACCENT_GOLD
	box.add_child(UIFactory.card_label("[%s]" % relic.rarity, 11, rarity_color, HORIZONTAL_ALIGNMENT_CENTER))
	var desc_lbl: Label = UIFactory.card_label(relic.description, 12, Color("c8d8ec"), HORIZONTAL_ALIGNMENT_CENTER)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(180, 0)
	box.add_child(desc_lbl)
	# 詛咒警告
	if not relic.curse_on_acquire.is_empty():
		var curse_data: Dictionary = CurseCatalog.by_id(relic.curse_on_acquire)
		var curse_name: String = String(curse_data.get("display_name", relic.curse_on_acquire))
		var curse_warn: Label = UIFactory.card_label("⚠ 附帶詛咒：%s" % curse_name, 12, Color("ff6655"), HORIZONTAL_ALIGNMENT_CENTER)
		curse_warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		curse_warn.custom_minimum_size = Vector2(180, 0)
		box.add_child(curse_warn)
	var pick_btn: Button = _button("選取")
	pick_btn.pressed.connect(func(_r: RelicData = relic) -> void:
		_add_relic_with_curse_effect(_r)
		if _after_boss_relic_choice.is_valid():
			_after_boss_relic_choice.call()
	)
	box.add_child(pick_btn)
	return panel

func show_card_reward() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("Boss 招式精粹" if _boss_card_reward else "戰鬥勝利", 34))
	if _boss_card_reward:
		box.add_child(UIFactory.card_label("擊敗 Boss！三選一稀有招式。", 14, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	for lu: Dictionary in _pending_levelups:
		var lu_lbl: Label = UIFactory.card_label(
			"✦ %s 升至 Lv %d！" % [String(lu.get("char_name", "")), int(lu.get("new_level", 1))],
			16, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		box.add_child(lu_lbl)
		for uc_v: Variant in (lu.get("unlocked_cards", []) as Array):
			var uc: CardData = uc_v as CardData
			var uc_lbl: Label = UIFactory.card_label(
				"  解鎖招式：%s（%s）" % [uc.display_name, uc.rarity],
				13, ThemeColors.HIGHLIGHT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			box.add_child(uc_lbl)
	var rewards: Array[CardData] = _make_reward_choices()
	var reward_row: HBoxContainer = HBoxContainer.new()
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", 12)
	box.add_child(reward_row)
	# 卡片高度依視窗高度自適應、上限 349：預留標題 / 升級提示 / 兩顆按鈕 / 各層 margin 的空間，
	# 確保「跳過獎勵」「查看目前牌組」按鈕永遠落在畫面內、點得到。
	var levelup_lines: int = 0
	for lu: Dictionary in _pending_levelups:
		levelup_lines += 1 + (lu.get("unlocked_cards", []) as Array).size()
	var reserved_h: float = 300.0 + float(levelup_lines) * 26.0
	var card_h: float = clampf(get_viewport_rect().size.y - reserved_h, 180.0, 349.0)
	for reward: CardData in rewards:
		var reward_button: Button = _reward_card_button(reward, card_h)
		reward_button.pressed.connect(func(card: CardData = reward): choose_reward_card(card))
		reward_row.add_child(reward_button)
	var skip: Button = _button("跳過獎勵")
	skip.pressed.connect(_finish_card_reward)
	box.add_child(skip)
	var deck_button: Button = _button("查看目前牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

# card reward 選卡 / 跳過後的收尾：boss 流程走 _after_card_reward continuation，
# 一般戰鬥回 progress screen。每次呼叫後清掉 boss 旗標與 continuation。
func _finish_card_reward() -> void:
	_boss_card_reward = false
	if _after_card_reward.is_valid():
		var cb: Callable = _after_card_reward
		_after_card_reward = Callable()
		cb.call()
	else:
		show_progress_screen()

func _make_reward_choices() -> Array[CardData]:
	var pool: Array[CardData] = []
	var used_ids: Array[String] = []
	for card: CardData in selected_character.reward_pool:
		if not used_ids.has(card.id):
			used_ids.append(card.id)
			pool.append(card.clone())
	var active_idx: int = run_state.active_character_index
	if active_idx < run_state.character_levels.size() and active_idx < run_state.characters.size():
		var char_lv: int = run_state.character_levels[active_idx]
		for unlocked: CardData in LevelSystem.all_unlocked_cards(run_state.characters[active_idx].id, char_lv):
			if not used_ids.has(unlocked.id):
				used_ids.append(unlocked.id)
				pool.append(unlocked.clone())
	pool.shuffle()
	var count: int = 3
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "card_reward_count_bonus":
					count += int(e.get("amount", 0))
	# Boss 獎勵：優先 rare，不足再補 uncommon、最後 common（STS：boss 卡三張皆最高稀有）
	if _boss_card_reward:
		var ordered: Array[CardData] = []
		for tier: String in ["rare", "uncommon", "common", "basic"]:
			for c: CardData in pool:
				if c.rarity == tier and not ordered.has(c):
					ordered.append(c)
		pool = ordered
	var rewards: Array[CardData] = []
	for i: int in range(min(count, pool.size())):
		rewards.append(pool[i])
	# 共同牌（colorless）：非 boss 獎勵有 ~22% 機率把其中一張換成共同牌（任何角色都能拿）
	if not _boss_card_reward and not rewards.is_empty() and randf() < 0.22:
		var cl_pool: Array[CardData] = GameData.colorless_cards()
		if not cl_pool.is_empty():
			rewards[randi() % rewards.size()] = (cl_pool[randi() % cl_pool.size()] as CardData).clone()
	return rewards

func choose_reward_card(card: CardData) -> void:
	run_state.deck.append(card.clone())
	_finish_card_reward()

func _grant_battle_exp() -> void:
	_pending_levelups.clear()
	var is_boss: bool = false
	for e: EnemyData in battle.enemies:
		if Ascension.is_boss_id(e.id):
			is_boss = true
			break
	var floor_idx: int = run_state.encounter_index
	var exp_gain: int = LevelSystem.battle_exp(is_boss, floor_idx)
	for i: int in range(run_state.characters.size()):
		if run_state.character_hps[i] <= 0:
			continue
		run_state.character_exps[i] += exp_gain
		var old_lv: int = run_state.character_levels[i]
		var new_lv: int = LevelSystem.level_from_exp(run_state.character_exps[i])
		if new_lv <= old_lv:
			continue
		run_state.character_levels[i] = new_lv
		var unlocked: Array[CardData] = []
		for lv: int in range(old_lv + 1, new_lv + 1):
			unlocked.append_array(LevelSystem.unlock_cards_for(run_state.characters[i].id, lv))
		_pending_levelups.append({
			"char_name": run_state.characters[i].display_name,
			"old_level": old_lv,
			"new_level": new_lv,
			"unlocked_cards": unlocked,
		})

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


func _route_node_button(node_data: Dictionary, row_index: int = -1, read_only: bool = false) -> Button:
	var node_type: String = String(node_data.get("type", "battle"))
	var button: Button
	if node_type == "rest":
		button = _route_rest_button()
	elif node_type == "event":
		button = _route_event_button()
	elif node_type == "shop":
		button = _route_shop_button(bool(node_data.get("black_market", false)))
	elif node_type == "boss":
		assert(node_data.has("enemy"), "Boss 節點缺少 enemy 資料：%s" % node_data)
		button = _route_enemy_button(node_data["enemy"] as EnemyData, true)
	else:
		assert(node_data.has("enemies"), "戰鬥節點缺少 enemies 資料：%s" % node_data)
		var enemies_arr: Array = node_data["enemies"] as Array
		var primary: EnemyData = enemies_arr[0] as EnemyData
		button = _route_enemy_button(primary, false, enemies_arr.size())
	if not read_only:
		button.pressed.connect(func(): choose_route_node(node_data, row_index))
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
	# 「當下這一層可以選的節點」用 scale 呼吸效果指示，緩慢放大縮小。
	# 已選 / 已通過 / 未連通 都不動，差異未來由 selected/unselected 圖檔承擔。
	if button == null:
		return
	if not selectable:
		return
	var target: Control = button
	if button.has_meta("route_icon"):
		target = button.get_meta("route_icon") as Control
	if target == null:
		return
	target.pivot_offset = target.size * 0.5
	# Boss 振幅稍大一點以強化壓迫感
	var amplitude: float = 1.26 if is_boss else 1.20
	var period: float = 0.55   # 單向動畫時長，整個呼吸週期 ≈ 1.1s（比舊版快一倍）
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(target, "scale", Vector2(amplitude, amplitude), period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(target, "scale", Vector2.ONE, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _route_enemy_button(enemy: EnemyData, is_boss: bool = false, enemy_count: int = 1) -> Button:
	var label_prefix: String = "Boss" if is_boss else "戰鬥"
	var name_text: String = enemy.display_name if enemy_count <= 1 else "%s 等 %d 敵" % [enemy.display_name, enemy_count]
	var text: String = "%s\n%s  HP %d\n%s" % [label_prefix, name_text, enemy.max_hp, _enemy_route_summary(enemy)]
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
	_play_bgm("rest")
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

func show_event_node(sub_stage: String = "") -> void:
	_play_bgm("event")
	# Event Branching P2：若此 variant 有新版 tree schema，走 tree path（_show_event_tree_node）
	# 否則 fallback 舊扁平 schema（原 sub_stage 分支邏輯）
	var ed: Dictionary = EventData.for_variant(run_state.current_event_variant)
	if EventRunner.has_tree(ed):
		_show_event_tree_node(EventRunner.ROOT_ID if sub_stage.is_empty() else sub_stage)
		return
	# sub_stage 非空 = 從某個主選項進入的次階段（sub-menu）
	# 渲染 sub_flavors[sub_stage] + sub_choices[sub_stage] 而非預設 flavor / choices
	_set_event_background()
	_clear_root()
	_show_title_bar()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var event_data: Dictionary = EventData.for_variant(run_state.current_event_variant)
	box.add_child(_title(String(event_data["title"]), 32))
	# Hero banner（legacy 路徑也享受到同樣的視覺）
	var legacy_banner: Control = _make_event_illustration_banner(run_state.current_event_variant, 760, 200)
	if legacy_banner != null:
		var legacy_banner_wrap: CenterContainer = CenterContainer.new()
		legacy_banner_wrap.add_child(legacy_banner)
		box.add_child(legacy_banner_wrap)
	var _active_char_id: String = run_state.characters[run_state.active_character_index].id if run_state.characters.size() > run_state.active_character_index else ""
	var flavor_text: String
	var choices_list: Array
	if sub_stage.is_empty():
		flavor_text = EventData.flavor_for(event_data, _active_char_id)
		choices_list = event_data.get("choices", ["heal", "gain_card", "power", "upgrade", "remove", "view_deck"])
	else:
		var sub_flavors: Dictionary = event_data.get("sub_flavors", {}) as Dictionary
		flavor_text = String(sub_flavors.get(sub_stage, ""))
		var sub_choices_map: Dictionary = event_data.get("sub_choices", {}) as Dictionary
		choices_list = sub_choices_map.get(sub_stage, []) as Array
	box.add_child(UIFactory.paragraph(flavor_text))
	var heal_amount: int = int(event_data["heal"])
	var gain_cost: int = int(event_data["gain_cost"])
	var power_gain: int = int(event_data["power"])
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for choice_key: Variant in choices_list:
		var key: String = String(choice_key)
		# 角色限定 filter（choice_filters[key].if_character = [ids]）
		if not _event_choice_passes_filter(event_data, key, _active_char_id):
			continue
		# 多階段 sub_choices override — 若此 key 定義了 sub_choices，按下開 sub-menu 而非 resolve
		var sub_choices_map: Dictionary = event_data.get("sub_choices", {}) as Dictionary
		if sub_choices_map.has(key):
			var label_pair: Array = _event_branch_label(event_data, key)
			grid.add_child(_event_choice_button(String(label_pair[0]), String(label_pair[1]),
				false, func() -> void: show_event_node(key)))
			continue
		match key:
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
			"revive":
				var ra: int = int(event_data.get("revive_amount", 30))
				var has_downed: bool = false
				for h: int in run_state.character_hps:
					if h <= 0:
						has_downed = true
						break
				grid.add_child(_event_choice_button("救援", "救回 1 名倒下的同伴（%d HP）" % ra,
					not has_downed, func() -> void: resolve_event_revive(ra)))
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
			"fight":
				grid.add_child(_event_choice_button("出手", "與花妖一戰，奪取寶物",
					false, _start_event_fight))
			"observe":
				# 觀察：顯示加長 flavor，不結束事件
				grid.add_child(_event_choice_button("觀察", "細看周遭，不冒任何風險",
					false, func() -> void: _event_show_observe(event_data, sub_stage)))
			"leave":
				# 離開：不領任何獎勵或損失，直接過場
				grid.add_child(_event_choice_button("離開", "繞道離去，不參與此事",
					false, advance_non_battle_node))

# ────────────────────────────────────────────────────────────────────
# Event Branching Phase 2：tree path UI
# ────────────────────────────────────────────────────────────────────
#
# 入口由 show_event_node() 在偵測 has_tree(event) 後 dispatch 進來。
# 走 EventRunner.visible_choices 過濾顯示，葉節點 → _resolve_event_tree_outcome；
# 非葉節點 → 重新 render 該 sub-node。
#
# observe-required 選項在點擊時消費 1 token；EventRunner.eval_requires 已過濾掉
# 0 token 情形（按鈕直接不顯示）。
func _show_event_tree_node(node_id: String) -> void:
	_set_event_background()
	_clear_root()
	_show_title_bar()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var ed: Dictionary = EventData.for_variant(run_state.current_event_variant)
	box.add_child(_title(String(ed["title"]), 32))
	# Hero banner：assets/art/events/<variant>.png 直接掛在標題下，
	# 把背景的同一張圖再放大成主視覺（背景被 panel 罩著看不太清楚）
	var banner: Control = _make_event_illustration_banner(run_state.current_event_variant, 760, 200)
	if banner != null:
		var banner_wrap: CenterContainer = CenterContainer.new()
		banner_wrap.add_child(banner)
		box.add_child(banner_wrap)
	var node: Dictionary = EventRunner.get_node(ed, node_id)
	if node.is_empty():
		push_warning("event tree: missing node '%s' in variant '%s'" % [node_id, run_state.current_event_variant])
		advance_non_battle_node()
		return
	# Prompt：root 用 character_flavors fallback 到 flavor；sub-node 用該 node.prompt
	var prompt_text: String = String(node.get("prompt", ""))
	if node_id == EventRunner.ROOT_ID:
		var active_char_id: String = ""
		if run_state.characters.size() > run_state.active_character_index:
			active_char_id = run_state.characters[run_state.active_character_index].id
		var flavor_text: String = EventData.flavor_for(ed, active_char_id)
		if not flavor_text.is_empty():
			prompt_text = flavor_text if prompt_text.is_empty() else (flavor_text + "\n\n" + prompt_text)
	box.add_child(UIFactory.paragraph(prompt_text))
	var ctx: Dictionary = _build_event_context()
	var visible_choices: Array = EventRunner.visible_choices(node, ctx)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for choice_v: Variant in visible_choices:
		var choice: Dictionary = choice_v as Dictionary
		var label: String = String(choice.get("label", choice.get("id", "?")))
		var kind: String = EventRunner.leaf_kind(choice)
		var badge: Dictionary = EventRunner.badge_for_kind(kind)
		var badge_text: String = String(badge.get("text", ""))
		# 副標：徽章 + observe token 提示（若有）
		var subtitle_parts: Array[String] = []
		if not badge_text.is_empty():
			subtitle_parts.append(badge_text)
		var requires: Dictionary = choice.get("requires", {}) as Dictionary
		if bool(requires.get("observe_token", false)):
			subtitle_parts.append("（消耗 1 觀察）")
		var subtitle: String = "　".join(subtitle_parts)
		grid.add_child(_event_choice_button(label, subtitle, false,
			func() -> void: _on_event_tree_choice_selected(choice), kind))

func _build_event_context() -> Dictionary:
	# 包裝 run_state 當下狀態給 EventRunner.eval_requires 用。
	var active_char_id: String = ""
	var d_size: int = 0
	if run_state != null and run_state.characters.size() > run_state.active_character_index:
		active_char_id = run_state.characters[run_state.active_character_index].id
		d_size = (run_state.character_decks[run_state.active_character_index] as Array).size()
	var relic_ids: Array = []
	if run_state != null:
		for r: RelicData in run_state.relics:
			relic_ids.append(r.id)
	return EventRunner.build_context(
		active_char_id,
		run_state.gold if run_state != null else 0,
		run_state.power_bonus if run_state != null else 0,
		run_state.observe_tokens if run_state != null else 0,
		relic_ids,
		d_size,
	)

func _on_event_tree_choice_selected(choice: Dictionary) -> void:
	# 1. 消費 observe token（若 requires 有設）
	var requires: Dictionary = choice.get("requires", {}) as Dictionary
	if bool(requires.get("observe_token", false)):
		if not run_state.consume_observe_token():
			# UI 上選項本不該出現（eval_requires 已擋）；這裡是 safety net
			push_warning("event tree: tried to spend observe token but none left")
			return
	# 2. 若有 next → 進入子節點；否則處理 outcome（葉節點）
	if choice.has("next") and not EventRunner.is_leaf(choice):
		_show_event_tree_node(String(choice["next"]))
		return
	if not EventRunner.is_leaf(choice):
		push_warning("event tree: choice has neither next nor outcome: %s" % str(choice))
		advance_non_battle_node()
		return
	_resolve_event_tree_outcome(choice["outcome"] as Dictionary)

func _resolve_event_tree_outcome(outcome: Dictionary) -> void:
	# 葉節點結算：依 kind 分派。
	#   reward / punish / mixed / neutral: 跑 effects[] 後顯示 log + advance
	#   gamble: 擲骰決定 win/lose effects，跑完後 advance
	#   battle: 設 pending_event_return（P3 未落地前，直接跳 fight，log 警告）
	var kind: String = String(outcome.get("kind", "neutral"))
	var log_text: String = String(outcome.get("log", ""))
	match kind:
		"gamble":
			var gamble: Dictionary = outcome.get("gamble", {}) as Dictionary
			var win_chance: float = float(gamble.get("win_chance", 0.5))
			var roll: float = randf()
			var won: bool = roll < win_chance
			var effects: Array = (gamble.get("win_effects", []) if won else gamble.get("lose_effects", [])) as Array
			var summary: String = _resolve_observe_effects(effects)
			var full_text: String = "%s\n\n[ %s ] %s" % [
				log_text,
				"🎲 賭運：" + ("成功" if won else "失敗"),
				summary,
			]
			_show_event_outcome(full_text, func() -> void: _flush_pending_confirmations(advance_non_battle_node))
		"battle":
			# Phase 3：開戰、勝利跑 victory_effects、戰敗跑 defeat_effects 後回地圖
			var battle_dict: Dictionary = outcome.get("battle", {}) as Dictionary
			var enemy_id: String = String(battle_dict.get("enemy_id", ""))
			var hp_mult: float = float(battle_dict.get("enemy_hp_mult", 1.0))
			var v_effects: Array = battle_dict.get("victory_effects", []) as Array
			var d_effects: Array = battle_dict.get("defeat_effects", []) as Array
			# 先閃一張過場顯示玩家的選擇文字，再開戰
			if log_text.is_empty():
				start_event_tree_battle(enemy_id, hp_mult, v_effects, d_effects)
			else:
				_show_event_outcome(log_text, func() -> void:
					start_event_tree_battle(enemy_id, hp_mult, v_effects, d_effects))
		_:
			# reward / punish / mixed / neutral：直接跑 effects
			var effects2: Array = outcome.get("effects", []) as Array
			var summary2: String = _resolve_observe_effects(effects2)
			var badge: Dictionary = EventRunner.badge_for_kind(kind)
			var badge_text: String = String(badge.get("text", ""))
			var full_text2: String = log_text
			if not summary2.is_empty():
				if badge_text.is_empty():
					full_text2 += "\n\n[ %s ]" % summary2
				else:
					full_text2 += "\n\n[ %s ] %s" % [badge_text, summary2]
			elif not badge_text.is_empty():
				full_text2 += "\n\n[ %s ]" % badge_text
			_show_event_outcome(full_text2, func() -> void: _flush_pending_confirmations(advance_non_battle_node))

func _event_choice_passes_filter(event_data: Dictionary, choice_key: String, active_char_id: String) -> bool:
	# 角色限定：choice_filters[key].if_character = [char_ids]
	# 若 list 非空且 active char 不在其中，按鈕不顯示
	var filters: Dictionary = event_data.get("choice_filters", {}) as Dictionary
	if not filters.has(choice_key):
		return true
	var filter: Dictionary = filters[choice_key] as Dictionary
	var if_char: Array = filter.get("if_character", []) as Array
	if not if_char.is_empty() and not (active_char_id in if_char):
		return false
	return true

func _event_branch_label(event_data: Dictionary, choice_key: String) -> Array:
	# 多階段主選項的按鈕文字。EventData.branch_labels[key] = [title, desc] 可選；
	# 沒設則 fallback 用 choice key 與一段通用敘述。
	var labels: Dictionary = event_data.get("branch_labels", {}) as Dictionary
	if labels.has(choice_key):
		var entry: Array = labels[choice_key] as Array
		if entry.size() >= 2:
			return [String(entry[0]), String(entry[1])]
	return [choice_key.capitalize(), "深入此選項"]

func _event_show_observe(event_data: Dictionary, _sub_stage: String) -> void:
	# 觀察 = 顯示加長 observe_text、結算獎勵後直接結束事件
	# 若 event 有 observe_effects（陣列），結算後在 text 末附上獲得/失去摘要；
	# 若沒設，預設給輕微 +3 HP「片刻安寧」，讓觀察永遠不是純文字。
	var text: String = String(event_data.get("observe_text", "你細細地觀察了一遍，但似乎沒有新的發現。"))
	var effects: Array = event_data.get("observe_effects", []) as Array
	if effects.is_empty():
		effects = [{"kind": "heal", "amount": 3}] as Array
	var summary: String = _resolve_observe_effects(effects)
	if not summary.is_empty():
		text += "\n\n[ %s ]" % summary
	_show_event_outcome(text, func() -> void: _flush_pending_confirmations(advance_non_battle_node))

# 結算 observe_effects 並回傳摘要字串。支援的 kind：
#   heal / damage   — active 角色 HP +/-
#   gold            — ±銅錢
#   max_hp          — 永久 max_hp +/-（增加時當前 HP 同步增加；減少時 clamp）
#   power           — 永久 power_bonus +/-（影響本 run 後續所有戰鬥）
func _resolve_observe_effects(effects: Array) -> String:
	_pending_card_confirmations.clear()
	if run_state == null:
		return ""
	var parts: Array[String] = []
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var effect: Dictionary = entry as Dictionary
		var kind: String = String(effect.get("kind", ""))
		var amount: int = int(effect.get("amount", 0))
		match kind:
			"heal":
				if amount > 0:
					var actual: int = min(amount, run_state.max_hp - run_state.hp)
					run_state.hp = min(run_state.max_hp, run_state.hp + amount)
					if actual > 0:
						parts.append("回復 %d 點生命" % actual)
			"damage":
				if amount > 0:
					var dealt: int = min(amount, run_state.hp - 1)  # 保底 HP 1
					run_state.hp = max(1, run_state.hp - amount)
					if dealt > 0:
						parts.append("損失 %d 點生命" % dealt)
			"gold":
				run_state.gold = max(0, run_state.gold + amount)
				if amount > 0:
					parts.append("獲得 %d 銅錢" % amount)
				elif amount < 0:
					parts.append("失去 %d 銅錢" % -amount)
			"max_hp":
				run_state.max_hp = max(1, run_state.max_hp + amount)
				if amount > 0:
					run_state.hp = min(run_state.max_hp, run_state.hp + amount)
					parts.append("最大生命 +%d" % amount)
				elif amount < 0:
					run_state.hp = min(run_state.hp, run_state.max_hp)
					parts.append("最大生命 %d" % amount)
			"power":
				run_state.power_bonus += amount
				if amount > 0:
					parts.append("本輪攻擊 +%d" % amount)
				elif amount < 0:
					parts.append("本輪攻擊 %d" % amount)
			"heal_party":
				# 全隊活著的角色都回血（倒下的不算）
				if amount > 0:
					var healed_any: bool = false
					for i: int in range(run_state.character_hps.size()):
						if run_state.character_hps[i] > 0:
							run_state.character_hps[i] = min(run_state.character_max_hps[i], run_state.character_hps[i] + amount)
							healed_any = true
					if healed_any:
						parts.append("全隊回復 %d 點生命" % amount)
			"gain_potion":
				# 獲得一瓶藥草（背包滿則跳過）。可選 potion_id 指定特定藥；
				# 未指定或查無此 id 則退回隨機。
				if run_state.potions.size() < RunState.MAX_POTION_SLOTS:
					var chosen: Dictionary = {}
					var pid: String = String(effect.get("potion_id", ""))
					if not pid.is_empty():
						chosen = PotionCatalog.by_id(pid)
					if chosen.is_empty():
						var pool: Array[Dictionary] = PotionCatalog.all()
						if not pool.is_empty():
							chosen = pool[randi() % pool.size()] as Dictionary
					if not chosen.is_empty():
						chosen = chosen.duplicate()
						run_state.potions.append(chosen)
						parts.append("獲得藥草「%s」" % String(chosen.get("display_name", "?")))
				else:
					parts.append("藥袋已滿，無從收取")
			"upgrade_random":
				# 升級 1 張隨機未升級的卡（active 角色牌組）
				var active_idx: int = run_state.active_character_index
				if active_idx < run_state.character_decks.size():
					var d: Array = run_state.character_decks[active_idx] as Array
					var candidates: Array[int] = []
					for i: int in range(d.size()):
						var c: CardData = d[i] as CardData
						if c != null and not c.upgraded:
							candidates.append(i)
					if not candidates.is_empty():
						var pick: int = candidates[randi() % candidates.size()]
						var orig: CardData = d[pick] as CardData
						d[pick] = orig.upgraded_copy()
						parts.append("領悟「%s」更精妙的招式" % orig.display_name)
			# ── Event Branching：新 effect kinds（P6 範疇，P2 為了讓 tree 能跑先補基本實作）──
			"permanent_power":
				run_state.power_bonus += amount
				if amount > 0:
					parts.append("永久攻擊 +%d" % amount)
				elif amount < 0:
					parts.append("永久攻擊 %d" % amount)
			"next_battle_buff":
				var sub_effects: Array = effect.get("effects", []) as Array
				if not sub_effects.is_empty():
					run_state.queue_next_battle_buff(sub_effects)
					var labels: Array[String] = []
					for se_v: Variant in sub_effects:
						if not (se_v is Dictionary):
							continue
						labels.append(_describe_next_battle_buff(se_v as Dictionary))
					if not labels.is_empty():
						parts.append("下場戰鬥：" + "、".join(labels))
			"gain_relic_pool":
				var pool_key: String = String(effect.get("pool", "common"))
				var picked: RelicData = _pick_random_relic_from_pool(pool_key)
				if picked != null:
					run_state.add_relic(picked)
					parts.append("獲得「%s」" % picked.display_name)
				else:
					parts.append("（無新遺物可得）")
			"gain_card_pool":
				var pool_key2: String = String(effect.get("pool", "common"))
				var added_card: CardData = _pick_random_card_from_pool(pool_key2)
				if added_card != null:
					# 不直接加入牌組，交由 _flush_pending_confirmations 在 outcome 後讓玩家確認
					_pending_card_confirmations.append({"card": added_card, "force_accept": false})
					parts.append("習得招式「%s」" % added_card.display_name)
			"gain_curse":
				# P4：詛咒不可拒絕，仍走確認流程（讓玩家看清楚拿到什麼）
				var curse_id: String = String(effect.get("curse_id", ""))
				var curse_card: CardData = CurseCatalog.make_card(curse_id)
				if curse_card != null:
					_pending_card_confirmations.append({"card": curse_card, "force_accept": true})
					parts.append("不祥之兆纏身：「%s」" % curse_card.display_name)
				else:
					push_warning("[event tree] gain_curse with unknown id: %s" % curse_id)
			"lose_card":
				var d3: Array = run_state.character_decks[run_state.active_character_index] as Array
				if d3.size() > 5:
					var idx_to_remove: int = randi() % d3.size()
					var lost: CardData = d3[idx_to_remove] as CardData
					d3.remove_at(idx_to_remove)
					if lost != null:
						parts.append("失去「%s」" % lost.display_name)
			"act_modifier":
				push_warning("[event tree] act_modifier not implemented (P6): %s" % str(effect.get("id", "?")))
	if parts.is_empty():
		return ""
	return "、".join(parts)

func _describe_next_battle_buff(effect: Dictionary) -> String:
	var kind: String = String(effect.get("kind", ""))
	var amount: int = int(effect.get("amount", 0))
	match kind:
		"energy":
			return "靈力 +%d" % amount
		"block":
			return "護體 +%d" % amount
		"weak":
			return "虛弱 +%d" % amount
		"vulnerable":
			return "破綻 +%d" % amount
		"poison":
			return "蠱毒 +%d" % amount
		_:
			return "%s %+d" % [kind, amount]

func _pick_random_relic_from_pool(pool_key: String) -> RelicData:
	# pool_key: "common" / "uncommon" / "rare" → RelicData.rarity 字串
	var all_relics: Array[RelicData] = RelicCatalog.all()
	var candidates: Array[RelicData] = []
	for r: RelicData in all_relics:
		if run_state.has_relic(r.id):
			continue
		if r.slot != "general":
			continue
		if r.rarity == pool_key:
			candidates.append(r)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()].clone()

func _pick_random_card_from_pool(pool_key: String) -> CardData:
	# pool_key == "colorless" → 共同牌池（任何角色）；其餘事件得牌有 ~18% 改抽共同牌。
	if pool_key == "colorless" or randf() < 0.18:
		var cl_pool: Array[CardData] = GameData.colorless_cards()
		if not cl_pool.is_empty():
			return (cl_pool[randi() % cl_pool.size()] as CardData).clone()
	if run_state == null or run_state.characters.is_empty():
		return null
	var char_idx: int = run_state.active_character_index
	if char_idx >= run_state.characters.size():
		return null
	var pool: Array[CardData] = run_state.characters[char_idx].reward_pool
	if pool.is_empty():
		return null
	return (pool[randi() % pool.size()] as CardData).clone()

# ─────────────────────────────────────────────────────────────
# Event Branching Phase 3：戰鬥回流（tree 葉節點 kind="battle" 路徑）
# ─────────────────────────────────────────────────────────────
# 流程：
#   1. _resolve_event_tree_outcome 看到 outcome.kind == "battle" → 呼叫 start_event_tree_battle
#   2. start_event_tree_battle 設 run_state.pending_event_return + 開戰
#   3. 戰鬥結束（_complete_battle_victory / _check_battle_end / _finish_battle_after_delay）
#      偵測到 pending_event_return 非空 → 走 _finish_event_tree_battle 而非標準流程
#   4. _finish_event_tree_battle：勝利跑 victory_effects、戰敗 revive party + 跑 defeat_effects
#      （若 defeat_effects 跑完仍全員 0 HP → 真正 game over；否則 advance）

func start_event_tree_battle(enemy_id: String, hp_mult: float, victory_effects: Array, defeat_effects: Array) -> void:
	var template: EnemyData = GameData.enemy_by_id(enemy_id)
	if template == null:
		push_warning("event tree battle: unknown enemy id '%s' — running defeat_effects as fallback" % enemy_id)
		# 不開戰，直接跑 defeat_effects 當作 fallback
		var summary: String = _resolve_observe_effects(defeat_effects)
		var fallback_text: String = "（戰鬥未能展開，敵人 '%s' 不存在）\n\n%s" % [enemy_id, summary]
		_show_event_outcome(fallback_text, func() -> void: _flush_pending_confirmations(advance_non_battle_node))
		return
	var clone: EnemyData = template.clone()
	if hp_mult > 0.0 and not is_equal_approx(hp_mult, 1.0):
		clone.max_hp = max(1, int(round(float(clone.max_hp) * hp_mult)))
	run_state.pending_event_return = {
		"victory_effects": victory_effects.duplicate(),
		"defeat_effects": defeat_effects.duplicate(),
	}
	start_next_battle(clone)

func _finish_event_tree_battle(victory: bool) -> void:
	# 取出並清空 pending（避免之後的戰鬥結束又跑一次）
	var pending: Dictionary = run_state.pending_event_return
	run_state.pending_event_return = {}
	# 共同：把戰鬥內 HP / status 寫回 run_state（複用 complete_victory 的同步邏輯）
	if battle != null:
		# 把每個角色的 HP 從 battle.state 同步回 run_state（即使戰敗也要同步）
		var players: Array = battle.state.get("players", []) as Array
		for i: int in range(min(players.size(), run_state.character_hps.size())):
			var p: Dictionary = players[i] as Dictionary
			run_state.character_hps[i] = max(0, int(p.get("hp", 0)))
	if victory:
		for defeated_e: EnemyData in battle.enemies:
			Bestiary.mark_defeated(defeated_e.id)
		var v_effects: Array = pending.get("victory_effects", []) as Array
		var summary: String = _resolve_observe_effects(v_effects)
		var text: String = "戰勝了 %s。\n\n[ ⚔ 戰鬥勝利 ]" % battle.enemy.display_name
		if not summary.is_empty():
			text += " " + summary
		_show_event_outcome(text, func() -> void: _flush_pending_confirmations(advance_non_battle_node))
		return
	# 戰敗：先把全隊 HP 抬到 1（不直接 game over），再跑 defeat_effects
	for i: int in range(run_state.character_hps.size()):
		if run_state.character_hps[i] <= 0:
			run_state.character_hps[i] = 1
	var d_effects: Array = pending.get("defeat_effects", []) as Array
	var d_summary: String = _resolve_observe_effects(d_effects)
	# 若 defeat_effects 自身造成全滅，才是真正的 game over
	if run_state.is_all_dead():
		show_result(false)
		return
	var d_text: String = "敗給了 %s。\n\n[ ⚔ 戰鬥失敗 ]" % battle.enemy.display_name
	if not d_summary.is_empty():
		d_text += " " + d_summary
	_show_event_outcome(d_text, func() -> void: _flush_pending_confirmations(advance_non_battle_node))

func _start_event_fight() -> void:
	var outcome_text: String = _get_event_outcome(
		EventData.for_variant(run_state.current_event_variant), "fight_win")
	_event_battle_on_win = func() -> void:
		_show_event_outcome(outcome_text, advance_non_battle_node)
	start_next_battle(GameData.flower_spirit_enemy())

func _get_event_outcome(event_data: Dictionary, key: String) -> String:
	# 優先用 character_outcomes[active_char][key]（per-char 個股化結局文字），
	# 否則 fallback 到 outcomes[key]
	var active_char_id: String = ""
	if run_state != null and run_state.characters.size() > run_state.active_character_index:
		active_char_id = run_state.characters[run_state.active_character_index].id
	var char_outcomes: Dictionary = event_data.get("character_outcomes", {}) as Dictionary
	if char_outcomes.has(active_char_id):
		var per_char: Dictionary = char_outcomes[active_char_id] as Dictionary
		if per_char.has(key):
			return String(per_char[key])
	return String((event_data.get("outcomes", {}) as Dictionary).get(key, ""))

func _show_event_outcome(text: String, on_continue: Callable, variant: String = "") -> void:
	# 結算面板：寬版（720px）、上方擺事件插圖小圖（160px banner）、
	# 文字以 typewriter（~40 字/秒）緩出，繼續按鈕首次點擊跳過 typewriter、
	# 第二次才真正關閉。沒插圖的事件 fallback 為只有文字。
	var overlay: PanelContainer = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	var bg: StyleBoxFlat = UIFactory.style_box(Color(0, 0, 0, 0.72), Color(0, 0, 0, 0), 0, 0)
	overlay.add_theme_stylebox_override("panel", bg)
	root.add_child(overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 0)
	var card_style: StyleBoxFlat = UIFactory.style_box(ThemeColors.PANEL_NAVY, ThemeColors.BORDER_GOLD, 1, 8)
	card_style.content_margin_left = 28
	card_style.content_margin_right = 28
	card_style.content_margin_top = 22
	card_style.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	# 上方插圖（用呼叫方傳入的 variant，或 fallback 到當下 run_state）
	var resolved_variant: String = variant
	if resolved_variant.is_empty() and run_state != null:
		resolved_variant = String(run_state.current_event_variant)
	var ban: Control = _make_event_illustration_banner(resolved_variant, 660, 160)
	if ban != null:
		var ban_wrap: CenterContainer = CenterContainer.new()
		ban_wrap.add_child(ban)
		vbox.add_child(ban_wrap)
	var lbl: Label = UIFactory.paragraph(text)
	lbl.custom_minimum_size = Vector2(660, 0)
	vbox.add_child(lbl)
	# Typewriter
	var char_count: int = text.length()
	var tw: Tween = null
	if char_count > 0:
		lbl.visible_characters = 0
		var tw_duration: float = clamp(float(char_count) / 40.0, 0.6, 5.0)
		tw = lbl.create_tween().set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(lbl, "visible_characters", char_count, tw_duration)
	var continue_button: Button = _button("繼續")
	continue_button.pressed.connect(func() -> void:
		# 首次按下：若 typewriter 還沒跑完，跳過動畫；第二次按下才真正繼續
		if tw != null and tw.is_valid() and tw.is_running():
			tw.kill()
			lbl.visible_characters = char_count
			return
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
	# HBoxContainer 內的 Label 必須關掉 autowrap，否則每個字都換行
	var hp_lbl: Label = UIFactory.card_label(
		"HP %d / %d" % [run_state.hp, run_state.max_hp],
		13, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	hp_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(hp_lbl)
	var dot1: Label = UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	dot1.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(dot1)
	var gold_lbl: Label = UIFactory.card_label("銅錢 %d" % run_state.gold, 13, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	gold_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(gold_lbl)
	var dot2: Label = UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	dot2.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(dot2)
	var deck_lbl: Label = UIFactory.card_label("牌組 %d" % run_state.deck.size(), 13, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	deck_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hbox.add_child(deck_lbl)
	if run_state.power_bonus > 0:
		var dot3: Label = UIFactory.card_label("·", 13, ThemeColors.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		dot3.autowrap_mode = TextServer.AUTOWRAP_OFF
		hbox.add_child(dot3)
		var pow_lbl: Label = UIFactory.card_label("增傷 +%d" % run_state.power_bonus, 13, Color("88c8ff"), HORIZONTAL_ALIGNMENT_LEFT)
		pow_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		hbox.add_child(pow_lbl)
	return container

func _event_choice_button(title: String, subtitle: String, disabled: bool, on_press: Callable, kind: String = "") -> Button:
	# 文青卡片式按鈕：水墨紙底色 + 細金邊 + 標題下細分隔線 + 副標小字
	# 兩兩排列在 GridContainer 裡，hover 時邊框轉暖、bg 微亮
	# 若給 kind（reward/punish/battle/gamble/mixed/neutral），左側畫一條彩色 ribbon
	# 對應 EventRunner.leaf_kind() 的分類，玩家一眼分辨選項屬性
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
	# 左側 kind ribbon：6 px 寬、安插在 content margin（左邊 16 px）內側
	if not kind.is_empty():
		var ribbon: ColorRect = ColorRect.new()
		var rc: Color = _event_kind_color(kind)
		if disabled:
			rc.a *= 0.35
		ribbon.color = rc
		ribbon.set_anchor_and_offset(SIDE_LEFT, 0.0, 4.0)
		ribbon.set_anchor_and_offset(SIDE_RIGHT, 0.0, 10.0)
		ribbon.set_anchor_and_offset(SIDE_TOP, 0.0, 8.0)
		ribbon.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -8.0)
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ribbon)
	if not disabled:
		btn.pressed.connect(on_press)
	return btn

func _event_kind_color(kind: String) -> Color:
	# 對應 EventRunner.badge_for_kind() 的 6 種類別
	match kind:
		"reward": return Color("e4c66a")   # 金（機緣）
		"punish": return Color("c04848")   # 紅（風險）
		"battle": return Color("4a6480")   # 深藍（戰鬥）
		"gamble": return Color("d88838")   # 橘（賭運）
		"mixed":  return Color("8a8576")   # 灰（取捨）
		_:        return Color("6a6760", 0.55)  # neutral：淡灰

func _make_event_illustration_banner(variant: String, max_width: int, banner_height: int) -> Control:
	# 把 assets/art/events/<variant>.png 包裝成一條 hero banner，
	# 中央裁切、帶細金邊框、進場時淡入 + 微縮放。
	# 沒有對應圖檔就回傳 null，呼叫方應跳過插入。
	if variant.is_empty():
		return null
	var path: String = "res://assets/art/events/%s.png" % variant
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = UIFactory.load_texture(path)
	if tex == null:
		return null
	var wrap: PanelContainer = PanelContainer.new()
	wrap.clip_contents = true
	wrap.custom_minimum_size = Vector2(max_width, banner_height)
	var style: StyleBoxFlat = UIFactory.style_box(Color(0, 0, 0, 0), Color("c8b46f", 0.65), 1, 4)
	wrap.add_theme_stylebox_override("panel", style)
	var rect: TextureRect = TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(rect)
	# 進場淡入 + 1.04 → 1.0 微微內推；只跑一次（非無限呼吸，避免畫面焦點亂跑）
	rect.modulate.a = 0.0
	rect.pivot_offset = Vector2(max_width * 0.5, banner_height * 0.5)
	rect.scale = Vector2(1.04, 1.04)
	var enter: Tween = rect.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	enter.tween_property(rect, "modulate:a", 1.0, 0.45)
	enter.tween_property(rect, "scale", Vector2(1.0, 1.0), 0.55)
	return wrap

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

func resolve_event_revive(amount: int) -> void:
	for i: int in range(run_state.character_hps.size()):
		if run_state.character_hps[i] <= 0:
			run_state.character_hps[i] = min(run_state.character_max_hps[i], amount)
			break
	var ev: Dictionary = EventData.for_variant(run_state.current_event_variant)
	var outcome: String = _get_event_outcome(ev, "revive")
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
	_set_event_background()
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
	_show_event_card_confirm(
		card, false,
		func() -> void:
			run_state.deck.append(card.clone())
			advance_non_battle_node(),
		func() -> void:
			advance_non_battle_node()
	)

func _flush_pending_confirmations(on_done: Callable) -> void:
	if _pending_card_confirmations.is_empty():
		on_done.call()
		return
	var entry: Dictionary = _pending_card_confirmations.pop_front() as Dictionary
	var card: CardData = entry["card"] as CardData
	var force: bool = bool(entry.get("force_accept", false))
	_show_event_card_confirm(
		card, force,
		func() -> void:
			var d: Array = run_state.character_decks[run_state.active_character_index] as Array
			d.append(card.clone())
			_flush_pending_confirmations(on_done),
		func() -> void:
			_flush_pending_confirmations(on_done)
	)

func _show_event_card_confirm(card: CardData, force_accept: bool, on_accept: Callable, on_skip: Callable = Callable()) -> void:
	_hide_card_preview()
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1600
	add_child(overlay)
	_card_preview_overlay = overlay

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	var is_curse: bool = CurseCatalog.is_curse(card)

	# Top label
	var top_text: String = "加入牌組？"
	if is_curse or force_accept:
		top_text = "詛咒纏身，無法拒絕"
	col.add_child(_title(top_text, 26))

	# Large card display
	var card_holder: CenterContainer = CenterContainer.new()
	col.add_child(card_holder)
	var big_btn: Button = _make_card_button(card, card.cost, Vector2(193, 360), true, true)
	big_btn.disabled = true
	big_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_holder.add_child(big_btn)

	# Bottom buttons
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	col.add_child(btn_row)

	if not (is_curse or force_accept) and on_skip.is_valid():
		var skip_btn: Button = _button("不要了")
		skip_btn.pressed.connect(func() -> void:
			_hide_card_preview()
			on_skip.call())
		btn_row.add_child(skip_btn)

	var accept_text: String = "詛咒接受" if (is_curse or force_accept) else "加入牌組"
	var accept_btn: Button = _button(accept_text)
	accept_btn.pressed.connect(func() -> void:
		_hide_card_preview()
		on_accept.call())
	btn_row.add_child(accept_btn)

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
	# 只有「第一次」進這個節點的商店才重抽貨架。之後再進來（含離開程式 / 回主畫面後重載存檔）
	# 都沿用已存的貨架，避免在同一個商店反覆刷新、無限買遺物。
	if run_state.current_shop_node_index != run_state.encounter_index:
		run_state.current_shop_is_black = is_black_shop
		run_state.current_shop_inventory = _make_shop_inventory(is_black_shop)
		run_state.current_shop_potions = ShopInventory.build_potions(is_black_shop)
		run_state.current_shop_relic_id = _pick_shop_relic_id()
		run_state.shop_remove_used = false
		run_state.shop_upgrade_used = false
		run_state.current_shop_node_index = run_state.encounter_index
	show_shop_node()

func show_shop_node() -> void:
	_play_bgm("shop")
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	_show_title_bar()
	var panel: PanelContainer = UIFactory.make_panel()
	root.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)
	var box: VBoxContainer = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)
	var title_text: String = "夜路黑店" if run_state.current_shop_is_black else "山道商店"
	var flavor_text: String = "簾後藏著來路不明的珍品，價格狠，成色也狠。" if run_state.current_shop_is_black else "行商在山道旁支起小攤，貨色普通但價格公道。"
	box.add_child(_title(title_text, 34))
	box.add_child(UIFactory.paragraph(flavor_text))
	var goods_row: HBoxContainer = HBoxContainer.new()
	goods_row.add_theme_constant_override("separation", 12)
	box.add_child(goods_row)
	for item: Dictionary in run_state.current_shop_inventory:
		goods_row.add_child(_shop_item_view(item))
	# 商店多賣 1 件裝備（在 open_shop_node 開店時就決定，買掉後清空、不重抽）
	var shop_relic_id: String = run_state.current_shop_relic_id
	if not shop_relic_id.is_empty() and not run_state.has_relic(shop_relic_id):
		var relic: RelicData = RelicCatalog.by_id(shop_relic_id)
		if relic != null:
			goods_row.add_child(_shop_relic_view(relic))
	if not run_state.current_shop_potions.is_empty():
		var potion_row: HBoxContainer = HBoxContainer.new()
		potion_row.add_theme_constant_override("separation", 12)
		potion_row.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(potion_row)
		for potion_item: Dictionary in run_state.current_shop_potions:
			potion_row.add_child(_shop_potion_view(potion_item))
	var services_row: HBoxContainer = HBoxContainer.new()
	services_row.add_theme_constant_override("separation", 12)
	services_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(services_row)
	var remove_price: int = _shop_apply_discount(75)
	var upgrade_price: int = _shop_apply_discount(100)
	var remove_used: bool = run_state.shop_remove_used
	var upgrade_used: bool = run_state.shop_upgrade_used
	services_row.add_child(_shop_service_panel(
		"削牌服務", "從牌組中移除一張牌", remove_price,
		remove_used, run_state.deck.size() > 5,
		func(): _open_shop_remove_service(remove_price)))
	services_row.add_child(_shop_service_panel(
		"強化服務", "升級牌組中的一張牌", upgrade_price,
		upgrade_used, not _upgradeable_cards().is_empty(),
		func(): _open_shop_upgrade_service(upgrade_price)))
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
	panel.custom_minimum_size = Vector2(210, 305)
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
	return max(10, int(ceil(float(base) * _shop_curse_surcharge_mult())))

func _buy_shop_relic(relic: RelicData, price: int) -> void:
	if run_state.gold < price:
		return
	run_state.gold -= price
	run_state.add_relic(relic)
	run_state.current_shop_relic_id = ""  # 買掉這次的商店裝備
	show_shop_node()

func _shop_potion_view(item: Dictionary) -> Control:
	var potion: Dictionary = item["potion"] as Dictionary
	var price: int = _shop_apply_discount(int(item["price"]))
	var full: bool = run_state.potions.size() >= RunState.MAX_POTION_SLOTS
	var can_buy: bool = run_state.gold >= price and not full
	var rarity_col: Color = PotionCatalog.rarity_color(potion)
	
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(170, 250)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	
	# Potion Icon
	var icon_container: Control = Control.new()
	icon_container.custom_minimum_size = Vector2(64, 64)
	icon_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon_container)
	
	var art_path: String = "res://assets/art/potions/%s.png" % potion.get("id", "")
	var texture: Texture2D = UIFactory.load_texture(art_path)
	if texture != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(64, 64)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_container.add_child(rect)
	
	box.add_child(UIFactory.card_label(String(potion.get("display_name", "?")), 15, rarity_col, HORIZONTAL_ALIGNMENT_CENTER))
	
	var desc: Label = UIFactory.card_label(String(potion.get("description", "")), 11, Color("d8e0ec"), HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(150, 0)
	box.add_child(desc)
	
	box.add_child(UIFactory.card_label("價格：%d 銅錢" % price, 13, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	
	var buy_button: Button = _button("買下藥品")
	buy_button.disabled = not can_buy
	if full:
		buy_button.tooltip_text = "藥格已滿（%d/%d）" % [run_state.potions.size(), RunState.MAX_POTION_SLOTS]
	buy_button.pressed.connect(func(): _show_shop_potion_confirm_overlay(potion, item, price))
	box.add_child(buy_button)
	
	return panel

func _show_shop_potion_confirm_overlay(potion: Dictionary, item: Dictionary, price: int) -> void:
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
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var rarity_col: Color = PotionCatalog.rarity_color(potion)
	col.add_child(UIFactory.card_label(String(potion.get("display_name", "?")), 22, rarity_col, HORIZONTAL_ALIGNMENT_CENTER))
	col.add_child(UIFactory.paragraph(String(potion.get("description", ""))))
	col.add_child(UIFactory.card_label("價格：%d 銅錢   （持有 %d）" % [price, run_state.gold], 16, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	var full: bool = run_state.potions.size() >= RunState.MAX_POTION_SLOTS
	var cancel_btn: Button = _button("取消")
	cancel_btn.pressed.connect(_hide_card_preview)
	btn_row.add_child(cancel_btn)
	var confirm_btn: Button = _button("購買")
	confirm_btn.disabled = run_state.gold < price or full
	confirm_btn.pressed.connect(func() -> void:
		_hide_card_preview()
		_buy_shop_potion(potion, item, price))
	btn_row.add_child(confirm_btn)

func _buy_shop_potion(potion: Dictionary, item: Dictionary, price: int) -> void:
	if run_state.gold < price or run_state.potions.size() >= RunState.MAX_POTION_SLOTS:
		return
	run_state.gold -= price
	run_state.potions.append(potion.duplicate())
	run_state.current_shop_potions.erase(item)
	show_shop_node()

func _shop_curse_surcharge_mult() -> float:
	var mult: float = 1.0
	var active_idx: int = run_state.active_character_index
	if active_idx >= run_state.character_decks.size():
		return mult
	for card_v: Variant in (run_state.character_decks[active_idx] as Array):
		var card: CardData = card_v as CardData
		if card == null or not CurseCatalog.is_curse(card):
			continue
		var ret: Dictionary = CurseCatalog.retention_for(card)
		if String(ret.get("trigger", "")) != "shop":
			continue
		for eff_v: Variant in (ret.get("effects", []) as Array):
			var eff: Dictionary = eff_v as Dictionary
			if String(eff.get("kind", "")) == "shop_surcharge":
				mult += float(eff.get("amount", 0)) / 100.0
	return mult

func _shop_apply_discount(base_price: int) -> int:
	var price: int = base_price
	for r: RelicData in run_state.relics:
		for t: Dictionary in r.triggers:
			if String(t.get("trigger", "")) != "permanent":
				continue
			for e: Dictionary in (t.get("effects", []) as Array):
				if String(e.get("kind", "")) == "shop_discount":
					price -= int(e.get("amount", 0))
	return max(10, int(ceil(float(price) * _shop_curse_surcharge_mult())))

func _shop_service_panel(title: String, description: String, price: int, used: bool, available: bool, on_press: Callable) -> Control:
	var panel: PanelContainer = UIFactory.make_panel()
	panel.custom_minimum_size = Vector2(180, 130)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	box.add_child(UIFactory.card_label(title, 15, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIFactory.card_label(description, 11, Color("d8e0ec"), HORIZONTAL_ALIGNMENT_CENTER))
	if used:
		box.add_child(UIFactory.card_label("（已使用）", 12, ThemeColors.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		box.add_child(UIFactory.card_label("價格：%d 銅錢" % price, 12, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER))
		var can_use: bool = available and run_state.gold >= price
		var btn: Button = _button("使用服務")
		btn.disabled = not can_use
		if can_use:
			btn.pressed.connect(on_press)
		box.add_child(btn)
	return panel

func _open_shop_remove_service(price: int) -> void:
	_deck_view_service_price = price
	show_deck_view("shop_remove")

func _open_shop_upgrade_service(price: int) -> void:
	_deck_view_service_price = price
	show_deck_view("shop_upgrade")

func _shop_deck_remove(card: CardData) -> void:
	if run_state.gold < _deck_view_service_price or run_state.deck.size() <= 5:
		close_deck_view()
		return
	run_state.gold -= _deck_view_service_price
	run_state.shop_remove_used = true
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck.remove_at(i)
			break
	close_deck_view()
	show_shop_node()

func _shop_deck_upgrade(card: CardData) -> void:
	if run_state.gold < _deck_view_service_price or card.upgraded:
		close_deck_view()
		return
	run_state.gold -= _deck_view_service_price
	run_state.shop_upgrade_used = true
	for i: int in range(run_state.deck.size()):
		if run_state.deck[i] == card:
			run_state.deck[i] = card.upgraded_copy()
			break
	close_deck_view()
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
	panel.custom_minimum_size = Vector2(180, 400)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	if item.get("on_sale", false):
		box.add_child(UIFactory.card_label("★ 特賣！五折優惠", 12, Color("ff5555"), HORIZONTAL_ALIGNMENT_CENTER))
	var can_buy: bool = run_state.gold >= price
	var card_button: Button = _make_card_button(card, card.cost, Vector2(153, 287), can_buy, true)
	card_button.disabled = not can_buy
	card_button.pressed.connect(func(): _show_shop_buy_confirm_overlay(card, price))
	box.add_child(card_button)
	var price_label: Label = UIFactory.card_label("價格：%d 銅錢" % price, 15, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(price_label)
	return panel

func _show_shop_buy_confirm_overlay(card: CardData, price: int) -> void:
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
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	var big: Button = _make_card_button(card, card.cost, Vector2(224, 418), true, true)
	big.disabled = true
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(big)
	var price_lbl: Label = UIFactory.card_label("價格：%d 銅錢   （持有 %d）" % [price, run_state.gold], 18, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	col.add_child(price_lbl)
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	var cancel_btn: Button = _button("取消")
	cancel_btn.pressed.connect(_hide_card_preview)
	btn_row.add_child(cancel_btn)
	var confirm_btn: Button = _button("購買")
	confirm_btn.disabled = run_state.gold < price
	confirm_btn.pressed.connect(func() -> void:
		_hide_card_preview()
		buy_shop_card(card, price))
	btn_row.add_child(confirm_btn)

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
		# P4：curse 不可升級
		if CurseCatalog.is_curse(card):
			continue
		if not card.upgraded:
			cards.append(card)
	return cards

# P4：嘗試從 active 角色 deck 移除 1 張隨機 curse，回傳被移除的名稱（沒有則回空）
# 戰鬥中敵方詛咒：resolve_enemy_phase 後清 pending_player_curses，加入 active 角色 deck
func _process_battle_curses() -> void:
	if battle == null or run_state == null:
		return
	var pending: Array = battle.state.get("pending_player_curses", []) as Array
	if pending.is_empty():
		return
	battle.state["pending_player_curses"] = []
	var d_idx: int = run_state.active_character_index
	if d_idx >= run_state.character_decks.size():
		return
	var d: Array = run_state.character_decks[d_idx] as Array
	for cid_v: Variant in pending:
		var cid: String = String(cid_v)
		var curse_card: CardData = CurseCatalog.make_card(cid)
		if curse_card != null:
			d.append(curse_card)

# Boss 神器附帶詛咒：取得遺物的同時加詛咒牌到 active 角色 deck（若有 curse_on_acquire）
func _add_relic_with_curse_effect(relic: RelicData) -> void:
	run_state.add_relic(relic)
	var cid: String = relic.curse_on_acquire
	if cid.is_empty():
		return
	var curse_card: CardData = CurseCatalog.make_card(cid)
	if curse_card == null:
		return
	var d_idx: int = run_state.active_character_index
	if d_idx < run_state.character_decks.size():
		var d: Array = run_state.character_decks[d_idx] as Array
		d.append(curse_card)
	if battle != null:
		battle.add_log("神器之力反噬：「%s」詛咒加入牌組！" % curse_card.display_name)

func _try_remove_random_curse() -> String:
	if run_state == null:
		return ""
	var idx: int = run_state.active_character_index
	if idx >= run_state.character_decks.size():
		return ""
	var d: Array = run_state.character_decks[idx] as Array
	var curse_indices: Array[int] = []
	for i: int in range(d.size()):
		if CurseCatalog.is_curse(d[i] as CardData):
			curse_indices.append(i)
	if curse_indices.is_empty():
		return ""
	var pick: int = curse_indices[randi() % curse_indices.size()]
	var removed_card: CardData = d[pick] as CardData
	d.remove_at(pick)
	return removed_card.display_name

# P4：可被標準 remove 移除的卡（curse 預設不可，除非 jing_hua_fu 觸發 / 黑市驅邪）
func _removable_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card: CardData in run_state.deck:
		if CurseCatalog.is_curse(card):
			continue
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
	run_state.current_shop_node_index = -1  # encounter_index 重置，商店標記也要清，否則新幕同索引商店不重抽
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
		1: return "餘杭山間"
		2: return "蘇州地底"
		3: return "苗疆蠱土"
		4: return "鎖妖塔"
		5: return "拜月決戰"
	return ""

func _act_complete_flavor(act: int) -> String:
	match act:
		1: return "餘杭山間的惡徒已被驅散，一行人踏上了通往蘇州的路途——誰知更大的困境正在前方等待。"
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
	# 手牌 z_index 高達 1100~1200（見 hand_fan.gd / 長按預覽），不墊高的話戰鬥中檢視牌組會被手牌蓋住
	deck_overlay.z_index = 1500
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
	elif deck_view_mode == "remove" or deck_view_mode == "shop_remove":
		title_text = "選擇要移除的牌"
	elif deck_view_mode == "upgrade" or deck_view_mode == "shop_upgrade":
		title_text = "選擇要升級的牌"
	box.add_child(_title(title_text, 32))
	
	var target_cards: Array
	if custom_cards == null:
		target_cards = run_state.deck
	else:
		target_cards = custom_cards

	if deck_view_mode == "upgrade" or deck_view_mode == "shop_upgrade":
		var filtered: Array = []
		for c: CardData in target_cards:
			if not c.upgraded:
				filtered.append(c)
		target_cards = filtered

	var count_text: String = "%s  HP %d/%d  銅錢 %d" % [selected_character.display_name, run_state.hp, selected_character.max_hp, run_state.gold]
	if custom_cards == null:
		count_text += "  共 %d 張牌" % run_state.deck.size()
	else:
		count_text += "  共 %d 張牌" % target_cards.size()
	box.add_child(UIFactory.paragraph(count_text))
	
	var summary_text: String = _deck_summary_text(target_cards, custom_cards == null)
	if deck_view_mode == "upgrade" or deck_view_mode == "shop_upgrade":
		# 升級畫面隱藏「重複：...」
		var nl: int = summary_text.find("\n")
		if nl != -1:
			summary_text = summary_text.substr(0, nl)
	var summary: Label = UIFactory.paragraph(summary_text)
	box.add_child(summary)

	if deck_view_mode == "remove":
		box.add_child(UIFactory.paragraph("至少保留 5 張牌。點選一張牌後會移除並完成事件。"))
	elif deck_view_mode == "shop_remove":
		box.add_child(UIFactory.paragraph("至少保留 5 張牌。點選一張牌後花費 %d 銅錢並移除。" % _deck_view_service_price))
		
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	
	if deck_view_mode == "upgrade" or deck_view_mode == "shop_upgrade":
		# 升級畫面：每張卡單獨顯示（不分組、不顯示 xN 徽章避免擋住卡片資訊）。
		# 有 3 張就直接 show 3 張。依 (id, upgraded) 排序讓同名卡相鄰。
		# NOTE: target_cards 是未型別 Array（L4681 宣告 + filtered 也是 untyped），
		# 直接 `Array[CardData] = target_cards.duplicate()` 會丟 runtime error
		# 「Trying to assign an array of type "Array" to a variable of type "Array[CardData]"」，
		# 整個函式中斷、grid 一張卡都不會被加。改成 typed-local + append 重建。
		var sorted_cards: Array[CardData] = []
		for tc: CardData in target_cards:
			sorted_cards.append(tc)
		sorted_cards.sort_custom(func(a: CardData, b: CardData) -> bool:
			if a.id != b.id:
				return a.id < b.id
			return (not a.upgraded) and b.upgraded)
		for c: CardData in sorted_cards:
			grid.add_child(_deck_view_card(c, deck_view_mode, 1))
	else:
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
	# P4：curse 不可選（remove / upgrade 都不行）
	var is_curse: bool = CurseCatalog.is_curse(card)
	var selectable: bool = (not is_curse) and (mode == "remove" or mode == "shop_remove" or ((mode == "upgrade" or mode == "shop_upgrade") and not card.upgraded))
	var visually_enabled: bool = (mode != "upgrade" and mode != "shop_upgrade") or not card.upgraded
	var button: Button = _make_card_button(card, card.cost, Vector2(153, 287), true, visually_enabled)
	button.disabled = not selectable
	if mode == "remove":
		button.pressed.connect(func(): remove_card_from_deck(card))
	elif mode == "shop_remove":
		button.pressed.connect(func(): _shop_deck_remove(card))
	elif mode == "upgrade" and not card.upgraded:
		# 點擊 → 開啟「原 vs 升級後」對照 overlay，使用者確認後才升級
		button.pressed.connect(func(): _show_upgrade_confirm_overlay(card, func(): upgrade_card_in_deck(card)))
	elif mode == "shop_upgrade" and not card.upgraded:
		button.pressed.connect(func(): _show_upgrade_confirm_overlay(card, func(): _shop_deck_upgrade(card)))
	elif mode == "view":
		button.disabled = false
		button.pressed.connect(func(): _show_card_detail_overlay(card))
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
	return button

func _show_card_detail_overlay(card: CardData) -> void:
	_hide_card_preview()
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 1600
	add_child(overlay)
	_card_preview_overlay = overlay

	var backdrop: ColorRect = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_hide_card_preview())
	overlay.add_child(backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	# Card holder: single-child CenterContainer we replace contents in on toggle
	var card_holder: CenterContainer = CenterContainer.new()
	col.add_child(card_holder)

	var detail_state: Dictionary = {"btn": null}
	var update_display: Callable = func(show_upgraded: bool) -> void:
		var old: Button = detail_state.get("btn") as Button
		if old != null and is_instance_valid(old):
			card_holder.remove_child(old)
			old.queue_free()
		var display: CardData = card.upgraded_copy() if show_upgraded else card
		var btn: Button = _make_card_button(display, display.cost, Vector2(193, 360), true, true)
		btn.disabled = true
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_holder.add_child(btn)
		detail_state["btn"] = btn
	update_display.call(false)

	# Bottom controls row
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 28)
	col.add_child(bottom)

	var is_curse: bool = CurseCatalog.is_curse(card)
	if not card.upgraded and not is_curse:
		var upgrade_toggle: Button = _button("□ 查看升級")
		upgrade_toggle.toggle_mode = true
		upgrade_toggle.toggled.connect(func(pressed: bool) -> void:
			upgrade_toggle.text = "☑ 查看升級" if pressed else "□ 查看升級"
			update_display.call(pressed))
		bottom.add_child(upgrade_toggle)
	elif card.upgraded:
		var up_label: Label = UIFactory.card_label("★ 已升級", 16, ThemeColors.ACCENT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		bottom.add_child(up_label)

	var close_btn: Button = _button("關閉")
	close_btn.pressed.connect(_hide_card_preview)
	bottom.add_child(close_btn)

func _show_upgrade_confirm_overlay(card: CardData, on_confirm: Callable) -> void:
	# 升級畫面點卡片時彈出：左原卡 / → / 右升級後卡，下方確認/取消按鈕。
	# 仿戰鬥中長按卡片預覽（_show_card_preview）的視覺設計，但加上 confirm/cancel 行為。
	_hide_card_preview()  # 清除任何先前的 overlay（重用 _card_preview_overlay 欄位）
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	# 必須 > deck_view 的 1500（commit f5be0c5 拉高的），否則升級確認會開在牌組檢視底下、看似「當掉」
	overlay.z_index = 1600
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
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	# 卡片對照列
	var stack: HBoxContainer = HBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(stack)
	var big: Button = _make_card_button(card, card.cost, Vector2(224, 418), true, true)
	big.disabled = true
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(big)
	var arrow: Label = Label.new()
	arrow.text = "→\n升級後"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	stack.add_child(arrow)
	var upgraded: CardData = card.upgraded_copy()
	var up_btn: Button = _make_card_button(upgraded, upgraded.cost, Vector2(224, 418), true, true)
	up_btn.disabled = true
	up_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(up_btn)
	# 確認 / 取消
	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(btn_row)
	var cancel_btn: Button = _button("取消")
	cancel_btn.pressed.connect(_hide_card_preview)
	btn_row.add_child(cancel_btn)
	var confirm_btn: Button = _button("確認升級")
	confirm_btn.pressed.connect(func() -> void:
		_hide_card_preview()
		on_confirm.call())
	btn_row.add_child(confirm_btn)

func show_result(victory: bool) -> void:
	_hide_title_bar()
	_play_bgm("victory" if victory else "defeat")
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
		box.add_child(_title("勝敗乃兵家常事", 34))
		box.add_child(UIFactory.paragraph("大俠請重新來過。\n（%s 敗於 %s）" % [selected_character.display_name, battle.enemy.display_name]))
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
	var prev_scroll: ScrollContainer = active_map_scroll
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(1040, 520)
	
	var title: Label = Label.new()
	title.text = "地圖路線檢視 (點擊空白處關閉)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	
	# 加入真實的地圖視圖，以唯讀模式顯示 (不觸發前進)
	var map_panel: Control = _map_view_sts(true)
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(map_panel)
	
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(func() -> void:
		active_map_scroll = prev_scroll
		popup.queue_free()
	)
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
	if battle == null or battle.enemies.is_empty():
		return
	var enemies_to_retry: Array[EnemyData] = []
	for e: EnemyData in battle.enemies:
		if not e.is_summoned:
			enemies_to_retry.append(e.clone())
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
	start_next_battle(enemies_to_retry)

func _refresh_battle(animate_draw: bool = false) -> void:
	_refresh_title_bar()
	var top_parts: Array[String] = ["第%s幕 %d/%d 層" % [_act_numeral(run_state.act), run_state.encounter_index + 1, run_state.encounter_choices.size()]]
	top_parts.append("抽 %d / 棄 %d" % [battle.deck.draw_pile.size(), battle.deck.discard_pile.size()])
	var passive_status: String = battle.passive_status_text()
	if not passive_status.is_empty():
		top_parts.append(passive_status)
	# 隊伍 >1 人時，提示切換次數
	if run_state.characters.size() > 1:
		var switched: bool = bool(battle.state.get("switched_this_turn", false))
		top_parts.append("切換：%s" % ("已用" if switched else "本回合免費"))
	if status_label != null and is_instance_valid(status_label):
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
		if player_level_label != null and is_instance_valid(player_level_label):
			var _aidx: int = run_state.active_character_index
			player_level_label.text = "Lv %d" % (run_state.character_levels[_aidx] if _aidx < run_state.character_levels.size() else 1)
		if player_portrait_image != null and is_instance_valid(player_portrait_image):
			var pose: String = _get_active_player_pose()
			var path: String = _get_battle_portrait_path(battle.character, pose)
			var tex: Texture2D = UIFactory.load_texture(path)
			if tex != null:
				player_portrait_image.texture = tex
				UIFactory.ground_portrait(player_portrait_image)  # 換姿勢後重新貼地
	_refresh_combatant_hp(player_hp_bar, player_hp_value, int(battle.state["player_hp"]), int(battle.state["player_max_hp"]))
	_update_poison_preview(player_hp_bar, int(battle.state["player_hp"]), int(battle.state["player_max_hp"]), int(battle.state["player_poison"]))
	player_block_badge.set_amount(int(battle.state["player_block"]))
	player_status_line.text = UIFactory.status_summary(int(battle.state["player_poison"]), int(battle.state["player_weak"]), int(battle.state["player_vulnerable"]))
	_refresh_bench_strip()
	# Multi-Enemy: 迭代更新每個敵人的 widget（active 高亮、死敵 dim、HP/block/status）
	_refresh_enemy_widgets()
	if enemy_label != null and is_instance_valid(enemy_label):
		enemy_label.text = ""
	energy_orb.set_energy(int(battle.state["energy"]), int(battle.state.get("per_turn_energy", BattleController.BASE_TURN_ENERGY)))
	var buttons: Array[Button] = []
	card_buttons.clear()
	_hand_buttons_map.clear()
	_selected_hand_button = null
	for card: CardData in battle.deck.hand:
		var button: Button = _card_button(card)
		buttons.append(button)
		card_buttons.append(button)
		_hand_buttons_map[button] = card
		if card == _selected_hand_card:
			_selected_hand_button = button
	var draw_source: Vector2 = Vector2(120.0, get_viewport_rect().size.y - 70.0)
	hand_row.set_cards(buttons, animate_draw, draw_source)
	if _selected_hand_button != null:
		hand_row.set_selected_button(_selected_hand_button)
	if log_label != null and is_instance_valid(log_label):
		log_label.text = "\n".join(battle.battle_log.slice(max(0, battle.battle_log.size() - 4)))
	_refresh_potion_buttons()
	end_turn_button.disabled = false

func _refresh_combatant_hp(bar: ProgressBar, value_label: Label, hp: int, max_hp: int) -> void:
	# 平滑 tween 到目標值。重複呼叫時前一個 tween 會被 kill 以避免累積。
	# 文字 label 直接設定（不必 tween），讓玩家立刻看到數值；條色慢慢追上去更有「失血感」。
	var target: float = 0.0 if max_hp <= 0 else float(hp) / float(max_hp)
	value_label.text = "%d / %d" % [hp, max_hp]
	if bar.has_meta("hp_tween"):
		var old_tween: Variant = bar.get_meta("hp_tween")
		if old_tween is Tween and (old_tween as Tween).is_valid():
			(old_tween as Tween).kill()
	var tween: Tween = bar.create_tween()
	tween.tween_property(bar, "value", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bar.set_meta("hp_tween", tween)

func _update_poison_preview(bar: ProgressBar, hp: int, max_hp: int, poison: int) -> void:
	# 在血條右段（即將失血處）疊綠：寬度 = 這回合 tick 會扣的毒傷（封頂於當前 HP）。
	if bar == null or not is_instance_valid(bar) or not bar.has_meta("poison_preview"):
		return
	var rect: ColorRect = bar.get_meta("poison_preview") as ColorRect
	if rect == null or not is_instance_valid(rect):
		return
	if poison <= 0 or hp <= 0 or max_hp <= 0:
		rect.visible = false
		return
	var lost: int = min(poison, hp)
	rect.anchor_left = clamp(float(hp - lost) / float(max_hp), 0.0, 1.0)
	rect.anchor_right = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	rect.offset_left = 0.0
	rect.offset_right = 0.0
	rect.visible = true

func _card_button(card: CardData) -> Button:
	var affordable: bool = int(battle.state["energy"]) >= battle.effective_card_cost(card)
	var card_size: Vector2 = Vector2(120, 225) if _battle_compact else Vector2(140, 262)
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
	# 戰鬥中長按卡片預覽（升級對照）已移除——按下不再啟 0.5s timer。
	# 拖拉打牌 / 桌面點兩下出牌仍正常運作。

func _on_card_button_up(card: CardData, button: Button) -> void:
	_cancel_card_long_press()
	var was_drag_active: bool = _card_drag_button == button and _card_drag_active
	if was_drag_active:
		_evaluate_card_drop(card, button)
		_suppress_next_card_play = true
	if _card_drag_active and hand_row != null and is_instance_valid(hand_row):
		hand_row.set_drag_locked(false)
	_card_drag_button = null
	_card_drag_card = null
	_card_drag_active = false

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
			# 鎖住其他手牌的 hover，避免手指劃過鄰卡時觸發抬升抖動
			if hand_row != null and is_instance_valid(hand_row):
				hand_row.set_drag_locked(true, button)
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
	# Multi-Enemy：迴圈所有敵人的 portrait，活著的且在 hit-box 內就算命中
	return _find_enemy_under_drag(global_pos) >= 0

# 在 global_pos 下找最近的活敵（含 CARD_DRAG_TARGET_PADDING 緩衝）；無則回 -1
func _find_enemy_under_drag(global_pos: Vector2) -> int:
	if battle == null:
		return -1
	var padding: float = CARD_DRAG_TARGET_PADDING_MOBILE if OS.has_feature("mobile") else CARD_DRAG_TARGET_PADDING
	var best_idx: int = -1
	var best_dist: float = INF
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for w: Dictionary in enemy_widgets:
		var idx: int = int(w["enemy_idx"])
		if idx >= enemy_slots.size():
			continue
		var slot: Dictionary = enemy_slots[idx] as Dictionary
		if int(slot["hp"]) <= 0:
			continue  # 死敵不可作為 drop target
		var wrap: Control = w["wrap"]
		if wrap == null or not is_instance_valid(wrap):
			continue
		var rect: Rect2 = Rect2(wrap.global_position, wrap.size)
		if not rect.grow(padding).has_point(global_pos):
			continue
		var center: Vector2 = rect.position + rect.size / 2.0
		var d: float = global_pos.distance_to(center)
		if d < best_dist:
			best_dist = d
			best_idx = idx
	return best_idx

func _is_position_outside_hand(global_pos: Vector2) -> bool:
	if hand_row == null or not is_instance_valid(hand_row):
		return false
	var card_h: float = 173.0 if _battle_compact else 208.0
	var visual_card_top: float = hand_row.global_position.y + hand_row.size.y - card_h - hand_row.hand_base_lift
	return global_pos.y < visual_card_top + card_h * 0.35

func _update_drag_target_highlight(card: CardData, global_pos: Vector2) -> void:
	# Multi-Enemy：拖到敵人卡時，找最近的活敵 → 切 active + 該敵金光；其他敵 dim；無命中時 reset
	var valid: bool = _is_valid_card_drop(card, global_pos)
	if CardFormat.requires_enemy_target(card):
		var target_idx: int = _find_enemy_under_drag(global_pos)
		if target_idx >= 0 and battle != null and battle._active_enemy_index() != target_idx:
			if battle.set_active_enemy(target_idx):
				_set_active_enemy_aliases()
		# 套用 highlight：active 金光、其他 dim、死敵更暗
		_refresh_enemy_widgets()
		if valid and target_idx >= 0 and target_idx < enemy_widgets.size():
			var wrap: Control = (enemy_widgets[target_idx] as Dictionary)["wrap"] as Control
			if wrap != null:
				wrap.modulate = Color(1.30, 1.18, 1.0)
	else:
		if player_portrait_wrap != null:
			player_portrait_wrap.modulate = Color(1.0, 1.25, 1.15) if valid else Color.WHITE

func _clear_drag_target_highlight() -> void:
	# 回到正常 active 高亮（_refresh_enemy_widgets 會處理）
	_refresh_enemy_widgets()
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_portrait_wrap.modulate = Color.WHITE

func _on_card_button_pressed(card: CardData, button: Button) -> void:
	if _suppress_next_card_play:
		_suppress_next_card_play = false
		return
	if OS.has_feature("mobile"):
		return  # Mobile: play cards only by dragging out of the hand area
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
	var big: Button = _make_card_button(card, card.cost, Vector2(224, 418), true, true)
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
		var up_btn: Button = _make_card_button(upgraded, upgraded.cost, Vector2(224, 418), true, true)
		up_btn.disabled = true
		up_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(up_btn)

func _reward_card_button(card: CardData, card_height: float = 349.0) -> Button:
	var h: float = clampf(card_height, 180.0, 349.0)
	var w: float = h * (784.0 / 1466.0)
	return _make_card_button(card, card.cost, Vector2(w, h), true, true)

func _card_frame_texture_path(_card_type: String) -> String:
	# 2026-05 美術改版：三色卡套（紅/綠/紫對應 attack/skill/power）統一成中性黑白水墨 base。
	# 卡類型現在只透過描述上方的「攻擊/技能/能力」文字標示，視覺上不再用框色區分。
	return "res://assets/ui/卡套_base.png"

func _cost_gem_texture_path(_cost: int) -> String:
	# 2026-05 美術改版：靈力0~3 原圖數字不清楚，改用中性 PowerBase 底圖，數值直接由 Label 疊在上面顯示。
	return "res://assets/ui/PowerBase.png"

func _rarity_gem_texture_path(card: CardData) -> String:
	# 稀有度寶石：lv1 白(基)、lv2 青(良)、lv3 紫(稀)、lv4 金(升)
	if card.upgraded:
		return "res://assets/ui/card_lv4.png"
	match card.rarity:
		"rare":
			return "res://assets/ui/card_lv3.png"
		"uncommon":
			return "res://assets/ui/card_lv2.png"
		_:
			return "res://assets/ui/card_lv1.png"

func _make_card_button(card: CardData, cost: int, size: Vector2, affordable: bool, selectable: bool) -> Button:
	# 全部用 anchor 百分比定位，元素位置 / 字體大小皆依卡片尺寸比例縮放。
	# 卡套版面參考（2026-05 重做後再修：卡套_base 原圖 1024×1536 左右各內建 ~11.7% 透明留白，
	#   會在 STRETCH_SCALE 鋪滿 Button 時露出背景成「外圍空白」。已把貼圖裁到實際內容
	#   784×1466（比例 0.535），下方所有 anchor 百分比都是相對「裁切後的卡套」量的。
	#   卡片 Button 尺寸也統一改成 0.535 比例（見各 _make_card_button 呼叫點）以免變形。
	# 以下百分比皆相對裁切後卡套（內部竹葉/石頭裝飾仍會切進來，故元素要內縮）：
	#   art 透明圖窗：x 7%~96%, y 1%~44.5%
	#   標題名牌帶：y 45.6%~51.3%
	#   描述卷軸文字安全區：x 16%~84%, y 59%~78%
	#   左上靈力寶石 / 右上稀有度寶石。
	var title_font_size: int = int(clamp(size.y * 0.045, 10, 20))
	var type_font_size: int = int(clamp(size.y * 0.035, 9, 16))
	var desc_font_size: int = int(clamp(size.y * 0.035, 9, 15))

	var button: Button = Button.new()
	button.text = ""
	button.custom_minimum_size = size
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	_style_card_button(button, card, affordable)

	# 1) 卡圖：擴到裁切後卡套的透明圖窗（x 7%~96%, y 1%~44.5%；COVER 模式以高度 fit 為主）。
	var art: TextureRect = TextureRect.new()
	art.name = "CardArt"
	art.anchor_left = 0.069
	art.anchor_top = 0.010
	art.anchor_right = 0.957
	art.anchor_bottom = 0.445
	art.offset_left = 0
	art.offset_top = 0
	art.offset_right = 0
	art.offset_bottom = 0
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# KEEP_ASPECT_COVERED：卡圖填滿整個透明圖窗（裁多餘部份），避免 letterbox 黑邊。
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = UIFactory.load_texture(card.art_path)
	if texture != null:
		art.texture = texture
	if not affordable or not selectable:
		art.modulate = Color(0.72, 0.72, 0.72, 0.62)
	button.add_child(art)

	# 2) 卡套：蓋在卡圖上層，透明區會讓卡圖透出
	var frame: TextureRect = TextureRect.new()
	frame.name = "CardFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = UIFactory.load_texture(_card_frame_texture_path(card.card_type))
	if not affordable or not selectable:
		frame.modulate = Color(0.82, 0.82, 0.82, 0.78)
	button.add_child(frame)

	# 3) 靈力寶石（左上）
	var cost_gem: TextureRect = TextureRect.new()
	cost_gem.name = "CardCostGem"
	# 放大靈力寶石：寬 0.20→0.27、上移並加高讓數字更顯眼（左上不會撞到卡圖窗 x17%）
	cost_gem.anchor_left = 0.0
	cost_gem.anchor_top = 0.0
	cost_gem.anchor_right = 0.33
	cost_gem.anchor_bottom = 0.178
	cost_gem.offset_left = 0
	cost_gem.offset_top = 0
	cost_gem.offset_right = 0
	cost_gem.offset_bottom = 0
	cost_gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_gem.texture = UIFactory.load_texture(_cost_gem_texture_path(cost))
	button.add_child(cost_gem)

	# 3a) 靈力數值：直接疊在 PowerBase 底圖上置中顯示
	var cost_label: Label = Label.new()
	cost_label.name = "CardCostLabel"
	cost_label.text = str(cost)
	cost_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", int(clamp(size.y * 0.06, 14, 28)))
	cost_label.add_theme_color_override("font_color", ThemeColors.TEXT_LIGHT)
	cost_label.add_theme_color_override("font_outline_color", Color("1b150f", 0.9))
	cost_label.add_theme_constant_override("outline_size", 3)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_gem.add_child(cost_label)

	# 3b) 稀有度寶石（右上）：card_lv1~4 = 基/良/稀/升。比 cost gem 略小。
	var rarity_gem: TextureRect = TextureRect.new()
	rarity_gem.name = "CardRarityGem"
	# 放大稀有度寶石：寬 0.13→0.19、高 0.085→0.12（右上不超出卡圖窗 x85%）
	rarity_gem.anchor_left = 0.709
	rarity_gem.anchor_top = 0.0
	rarity_gem.anchor_right = 0.957
	rarity_gem.anchor_bottom = 0.126
	rarity_gem.offset_left = 0
	rarity_gem.offset_top = 0
	rarity_gem.offset_right = 0
	rarity_gem.offset_bottom = 0
	rarity_gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rarity_gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rarity_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_gem.texture = UIFactory.load_texture(_rarity_gem_texture_path(card))
	button.add_child(rarity_gem)

	# 4) 卡名：對齊卡套標題帶 y 47.1%~52.5% 的淺色書寫長框（再下方的 y 53~54% 是深色菱飾，
	# 然後 y 54~56% 是另一條更窄的淺帶——不是寫名字的位置）。
	var title: Label = UIFactory.card_label(card.display_title(), title_font_size, Color("2d2418"), HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "CardTitle"
	title.anchor_left = 0.108
	title.anchor_top = 0.456
	title.anchor_right = 0.892
	title.anchor_bottom = 0.513
	title.offset_left = 0
	title.offset_top = 0
	title.offset_right = 0
	title.offset_bottom = 0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 真正讓卡名隱形的元凶：card_label() 預設 AUTOWRAP_WORD_SMART，與 clip_text=true 在這個只有
	# ~33px 高的窄名牌框相撞時，整行字會被裁成完全不顯示（實測 A/B 確認）。卡名本就單行，關掉換行即可。
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.add_theme_color_override("font_outline_color", Color("1b150f", 0.8))
	title.add_theme_constant_override("outline_size", 1)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)

	# 5) 類型 + 描述：對齊卡套描述卷軸文字安全區 x 24%~76%, y 60%~78%。
	# y 78% 以下竹葉裝飾從底邊夾入快速吃掉寬度（y 90% 只剩 16% 可寫），文字會壓在裝飾上。
	var rules_container: Control = Control.new()
	rules_container.name = "CardRules"
	rules_container.anchor_left = 0.160
	rules_container.anchor_top = 0.592
	rules_container.anchor_right = 0.840
	rules_container.anchor_bottom = 0.780
	rules_container.offset_left = 0
	rules_container.offset_top = 0
	rules_container.offset_right = 0
	rules_container.offset_bottom = 0
	rules_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(rules_container)
	var rules_box: VBoxContainer = VBoxContainer.new()
	rules_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rules_box.add_theme_constant_override("separation", max(1, int(round(size.y * 0.006))))
	rules_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rules_container.add_child(rules_box)
	var type_line: Label = UIFactory.card_label(CardFormat.card_type_name(card.card_type), type_font_size, CardFormat.card_color(card.card_type, true).darkened(0.05), HORIZONTAL_ALIGNMENT_CENTER)
	type_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rules_box.add_child(type_line)
	var desc: Label = UIFactory.card_label(card.display_description(), desc_font_size, Color("2d2418"), HORIZONTAL_ALIGNMENT_LEFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	# 行距收緊（預設 Label line_spacing = 3，縮成 -1 讓多行卡片描述列排更緊湊）
	desc.add_theme_constant_override("line_spacing", -1)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	# 飛向決定：根據 effects 而非 card_type。
	# - 任何 effect 是「敵人標靶」(damage / poison / weak / vulnerable /
	#   consume_energy_damage / poison_burst) → 飛向敵人
	# - 純自身效果（block / heal / draw / energy / power / cure_*）→ 飛向自己
	# 這修正一堆 skill 卡（蠱毒、weak、飛龍探雲手）以前錯飛自己的 bug
	# CardFormat.requires_enemy_target 是 drag-to-play 命中判定也用同一規則，保持一致。
	var target_label: Label = enemy_feedback_label if CardFormat.requires_enemy_target(card) else player_feedback_label
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
	var bs: Dictionary = battle.state
	# ── 玩家（單體）──
	var player_hp_delta: int = int(bs["player_hp"]) - int(before["player_hp"])
	var player_block_delta: int = int(bs["player_block"]) - int(before["player_block"])
	var player_poison_delta: int = int(bs["player_poison"]) - int(before["player_poison"])
	var player_weak_delta: int = int(bs["player_weak"]) - int(before["player_weak"])
	var player_vulnerable_delta: int = int(bs["player_vulnerable"]) - int(before["player_vulnerable"])
	var player_lines: Array[String] = []
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
	if not player_lines.is_empty():
		_show_feedback(player_feedback_label, player_lines, Color("f4b7a8"))
	if player_hp_delta < 0:
		UIFactory.shake_node(player_portrait_wrap, 7.0, 0.28)
		_spawn_damage_popup(player_portrait_wrap, abs(player_hp_delta), "damage")
		var pmax: int = int(bs.get("player_max_hp", 1))
		if pmax > 0 and abs(player_hp_delta) >= int(pmax * 0.20):
			UIFactory.shake_node(player_portrait_wrap, 18.0, 0.45)
	elif player_hp_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, player_hp_delta, "heal")
	if player_block_delta > 0:
		UIFactory.flash_node(player_portrait_wrap, Color(1.2, 1.35, 1.55), 0.22)
		_spawn_damage_popup(player_portrait_wrap, player_block_delta, "block")
	if player_poison_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, player_poison_delta, "poison")
	if player_weak_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, player_weak_delta, "weak")
	if player_vulnerable_delta > 0:
		_spawn_damage_popup(player_portrait_wrap, player_vulnerable_delta, "vulnerable")
	# ── 敵人（逐個）：對每隻敵人各算 delta，把浮字 / 震動飄到「正確的那隻」頭上 ──
	var before_enemies: Array = before.get("enemies", []) as Array
	var cur_enemies: Array = bs.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i >= cur_enemies.size() or i >= before_enemies.size():
			continue
		_show_enemy_slot_feedback(enemy_widgets[i] as Dictionary, before_enemies[i] as Dictionary, cur_enemies[i] as Dictionary)

func _show_enemy_slot_feedback(widget: Dictionary, before_slot: Dictionary, cur_slot: Dictionary) -> void:
	var hp_delta: int = int(cur_slot.get("hp", 0)) - int(before_slot.get("hp", 0))
	var block_delta: int = int(cur_slot.get("block", 0)) - int(before_slot.get("block", 0))
	var poison_delta: int = int(cur_slot.get("poison", 0)) - int(before_slot.get("poison", 0))
	var weak_delta: int = int(cur_slot.get("weak", 0)) - int(before_slot.get("weak", 0))
	var vuln_delta: int = int(cur_slot.get("vulnerable", 0)) - int(before_slot.get("vulnerable", 0))
	var lines: Array[String] = []
	if hp_delta < 0:
		lines.append("傷害 %d" % abs(hp_delta))
	if block_delta > 0:
		lines.append("護體 +%d" % block_delta)
	if poison_delta > 0:
		lines.append("蠱毒 +%d" % poison_delta)
	if weak_delta > 0:
		lines.append("虛弱 +%d" % weak_delta)
	if vuln_delta > 0:
		lines.append("破綻 +%d" % vuln_delta)
	var fb: Variant = widget.get("feedback_label")
	if not lines.is_empty() and fb is Label:
		_show_feedback(fb as Label, lines, ThemeColors.ACCENT_GOLD)
	var wrap_v: Variant = widget.get("wrap")
	if not (wrap_v is Control) or not is_instance_valid(wrap_v as Control):
		return
	var wrap: Control = wrap_v as Control
	if hp_delta < 0:
		UIFactory.shake_node(wrap, 7.0, 0.28)
		_spawn_damage_popup(wrap, abs(hp_delta), "damage")
		var mx: int = int(cur_slot.get("max_hp", 1))
		if mx > 0 and abs(hp_delta) >= int(mx * 0.20):
			UIFactory.shake_node(wrap, 18.0, 0.45)
	if block_delta > 0:
		UIFactory.flash_node(wrap, Color(1.2, 1.35, 1.55), 0.22)
		_spawn_damage_popup(wrap, block_delta, "block")
	if poison_delta > 0:
		_spawn_damage_popup(wrap, poison_delta, "poison")
	if weak_delta > 0:
		_spawn_damage_popup(wrap, weak_delta, "weak")
	if vuln_delta > 0:
		_spawn_damage_popup(wrap, vuln_delta, "vulnerable")

func _spawn_damage_popup(target: Control, amount: int, kind: String) -> void:
	if target == null or not is_instance_valid(target):
		return
	var world_pos: Vector2 = target.global_position + Vector2(target.size.x * 0.5 - 40, target.size.y * 0.35)
	DamagePopup.spawn(self, world_pos, amount, kind)

# feedback 浮字包在 0 高度的 plain Control 裡：plain Control 不把子節點 min size 算進自己的
# min size，所以塞文字時不會撐高 arena、把手牌列擠出畫面下緣。label 錨在 slot 上緣往上延伸，
# 浮字漂在 portrait 上方而非占用欄位高度。
func _wrap_feedback_label(label: Label) -> Control:
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(0, 0)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_left = 0
	label.offset_right = 0
	label.offset_top = -58
	label.offset_bottom = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	return slot

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
	var override_path: String = "res://assets/art/battle_characters/%s_%s_v2.png" % [char_data.id, pose]
	if ResourceLoader.exists(override_path):
		return override_path
	var path: String = "res://assets/art/battle_characters/%s_%s.png" % [char_data.id, pose]
	if ResourceLoader.exists(path):
		return path
	return char_data.portrait_path

func _animate_wan_jian_jue_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	
	var texture_path: String = "res://assets/art/effects/blue_flying_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
		
	# Find alive enemies
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	# Determine target widgets based on card
	var is_all_targets: bool = (card.id == "lxy_wanjian")
	var target_widgets: Array[Dictionary] = []
	if is_all_targets:
		target_widgets = alive_targets
	else:
		var active_idx: int = battle._active_enemy_index()
		var target_widget: Dictionary = {}
		for w: Dictionary in alive_targets:
			if w["enemy_idx"] == active_idx:
				target_widget = w
				break
		if target_widget.is_empty() and not alive_targets.is_empty():
			target_widget = alive_targets[0]
		if not target_widget.is_empty():
			target_widgets.append(target_widget)
			
	if target_widgets.is_empty():
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var sword_count: int = 15
	var sword_size: Vector2 = Vector2(80, 80)
	
	for i: int in range(sword_count):
		# Select target
		var target_widget: Dictionary = target_widgets[i % target_widgets.size()]
		var wrap: Control = target_widget["wrap"] as Control
		var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
		
		# Create sword TextureRect
		var sword: TextureRect = TextureRect.new()
		sword.texture = sword_tex
		sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sword.size = sword_size
		sword.pivot_offset = sword_size / 2.0
		sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Staggered entry from top with random coordinates
		var start_pos: Vector2 = Vector2(
			randf_range(50.0, view_size.x - 50.0),
			randf_range(-180.0, -80.0)
		)
		sword.global_position = start_pos
		
		# Set angle pointing towards the target
		var to_target: Vector2 = target_center - start_pos
		var angle: float = to_target.angle()
		sword.rotation = angle
		
		# Add to tree (under self so it is on top of battle elements)
		add_child(sword)
		
		# Animate the sword flying to the target
		var duration: float = randf_range(0.35, 0.55)
		var delay: float = i * 0.04
		var tween: Tween = create_tween().set_parallel(true)
		
		# Tween position to target center (centered offset)
		var end_pos: Vector2 = target_center - sword_size / 2.0
		
		tween.tween_property(sword, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
			
		# Fade in and then fade out slightly near the end
		sword.modulate.a = 0.0
		tween.tween_property(sword, "modulate:a", 1.0, duration * 0.2)\
			.set_delay(delay)
			
		# Scale down slightly as it hits
		tween.tween_property(sword, "scale", Vector2(0.5, 0.5), duration * 0.3)\
			.set_delay(delay + duration * 0.7)
			
		# Connect completion signal to handle shake and cleanup
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(sword):
				sword.queue_free()
			# Shake the enemy portrait upon impact
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 6.0, 0.2)
		)

func _animate_yu_jian_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/blue_flying_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
	
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var start_pos: Vector2 = Vector2(100.0, get_viewport_rect().size.y * 0.7)
	
	var sword_size: Vector2 = Vector2(80, 80)
	var sword: TextureRect = TextureRect.new()
	sword.texture = sword_tex
	sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sword.size = sword_size
	sword.pivot_offset = sword_size / 2.0
	sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sword.global_position = start_pos
	
	var to_target: Vector2 = target_center - start_pos
	sword.rotation = to_target.angle()
	add_child(sword)
	
	var duration: float = 0.35
	var tween: Tween = create_tween().set_parallel(true)
	var end_pos: Vector2 = target_center - sword_size / 2.0
	tween.tween_property(sword, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	sword.modulate.a = 0.0
	tween.tween_property(sword, "modulate:a", 1.0, duration * 0.2)
	
	var captured_wrap = wrap
	tween.finished.connect(func() -> void:
		if is_instance_valid(sword):
			sword.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 6.0, 0.2)
	)

func _animate_tian_jian_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/gold_giant_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
	
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var sword_size: Vector2 = Vector2(250, 250)
	
	var sword: TextureRect = TextureRect.new()
	sword.texture = sword_tex
	sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sword.size = sword_size
	sword.pivot_offset = sword_size / 2.0
	sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var start_pos: Vector2 = Vector2(target_center.x, -300.0)
	sword.global_position = start_pos
	sword.rotation = PI / 2.0
	add_child(sword)
	
	var duration: float = 0.45
	var tween: Tween = create_tween().set_parallel(true)
	var end_pos: Vector2 = target_center - sword_size / 2.0
	
	tween.tween_property(sword, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	
	sword.scale = Vector2(1.5, 1.5)
	tween.tween_property(sword, "scale", Vector2(0.8, 0.8), duration)
	
	sword.modulate.a = 0.0
	tween.tween_property(sword, "modulate:a", 1.0, duration * 0.15)
	
	var captured_wrap = wrap
	var captured_self = self
	tween.finished.connect(func() -> void:
		if is_instance_valid(sword):
			sword.queue_free()
		
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 20.0, 0.45)
		
		for w in captured_self.enemy_widgets:
			if w != captured_wrap and is_instance_valid(w["wrap"]):
				UIFactory.shake_node(w["wrap"], 10.0, 0.3)
	)

func _animate_jian_zhen_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/blue_flying_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
	
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var radius: float = 160.0
	var sword_size: Vector2 = Vector2(70, 70)
	
	for i in range(6):
		var angle: float = i * (TAU / 6.0)
		var start_pos: Vector2 = target_center + Vector2(cos(angle), sin(angle)) * radius - sword_size / 2.0
		
		var sword: TextureRect = TextureRect.new()
		sword.texture = sword_tex
		sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sword.size = sword_size
		sword.pivot_offset = sword_size / 2.0
		sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sword.global_position = start_pos
		sword.rotation = angle + PI
		
		sword.modulate.a = 0.0
		add_child(sword)
		
		var is_first_wave: bool = (i % 2 == 0)
		var delay: float = 0.1 if is_first_wave else 0.4
		var duration: float = 0.25
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(sword, "modulate:a", 1.0, 0.1).set_delay(delay)
		
		var end_pos: Vector2 = target_center - sword_size / 2.0
		tween.tween_property(sword, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
			
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(sword):
				sword.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 5.0, 0.15)
		)

func _animate_jiu_long_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/blue_flying_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
	
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var view_size: Vector2 = get_viewport_rect().size
	var sword_size: Vector2 = Vector2(80, 80)
	
	for w_idx in range(3):
		var wave_delay: float = w_idx * 0.25
		for s_idx in range(3):
			var sword: TextureRect = TextureRect.new()
			sword.texture = sword_tex
			sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sword.size = sword_size
			sword.pivot_offset = sword_size / 2.0
			sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var start_pos: Vector2 = Vector2(
				randf_range(-150.0, -50.0),
				randf_range(100.0, view_size.y - 200.0)
			)
			sword.global_position = start_pos
			
			var to_target: Vector2 = target_center - start_pos
			sword.rotation = to_target.angle()
			sword.modulate.a = 0.0
			add_child(sword)
			
			var duration: float = randf_range(0.35, 0.45)
			var delay: float = wave_delay + s_idx * 0.04
			
			var tween: Tween = create_tween().set_parallel(true)
			var end_pos: Vector2 = target_center - sword_size / 2.0
			
			tween.tween_property(sword, "global_position", end_pos, duration)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN)
			
			tween.tween_property(sword, "modulate:a", 1.0, duration * 0.2).set_delay(delay)
			
			var captured_wrap = wrap
			tween.finished.connect(func() -> void:
				if is_instance_valid(sword):
					sword.queue_free()
				if is_instance_valid(captured_wrap):
					UIFactory.shake_node(captured_wrap, 6.0, 0.15)
			)

func _animate_xiaoyao_shenjian_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/blue_flying_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
	
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var sword_size: Vector2 = Vector2(90, 90)
	
	for slash in range(2):
		var sword: TextureRect = TextureRect.new()
		sword.texture = sword_tex
		sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sword.size = sword_size
		sword.pivot_offset = sword_size / 2.0
		sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var start_offset: Vector2
		var end_offset: Vector2
		if slash == 0:
			start_offset = Vector2(-200.0, -200.0)
			end_offset = Vector2(200.0, 200.0)
		else:
			start_offset = Vector2(200.0, -200.0)
			end_offset = Vector2(-200.0, 200.0)
			
		var start_pos: Vector2 = target_center + start_offset - sword_size / 2.0
		var end_pos: Vector2 = target_center + end_offset - sword_size / 2.0
		
		sword.global_position = start_pos
		sword.rotation = (end_pos - start_pos).angle()
		sword.modulate.a = 0.0
		add_child(sword)
		
		var delay: float = slash * 0.18
		var duration: float = 0.25
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(sword, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_LINEAR)
			
		tween.tween_property(sword, "modulate:a", 1.0, duration * 0.2).set_delay(delay)
		tween.tween_property(sword, "modulate:a", 0.0, duration * 0.3).set_delay(delay + duration * 0.7)
		
		# Connect completion signal to handle shake and cleanup
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(sword):
				sword.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 8.0, 0.2)
		)

func _animate_qian_kun_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/relics/tong_bao_qian.png"
	var coin_tex: Texture2D = UIFactory.load_texture(texture_path)
	if coin_tex == null:
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var coin_count: int = 24
	var coin_size: Vector2 = Vector2(40, 40)
	
	for i in range(coin_count):
		var target_widget: Dictionary = alive_targets[i % alive_targets.size()]
		var wrap: Control = target_widget["wrap"] as Control
		var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
		
		var coin: TextureRect = TextureRect.new()
		coin.texture = coin_tex
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.size = coin_size
		coin.pivot_offset = coin_size / 2.0
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Start from player side (left middle) with some noise
		var start_pos: Vector2 = Vector2(
			randf_range(50.0, 150.0),
			randf_range(view_size.y * 0.4, view_size.y * 0.8)
		)
		coin.global_position = start_pos
		coin.rotation = randf_range(-PI, PI)
		add_child(coin)
		
		var duration: float = randf_range(0.35, 0.5)
		var delay: float = i * 0.03
		
		var tween: Tween = create_tween().set_parallel(true)
		var end_pos: Vector2 = target_center + Vector2(randf_range(-40, 40), randf_range(-40, 40)) - coin_size / 2.0
		
		# Move and spin
		tween.tween_property(coin, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "rotation", coin.rotation + randf_range(PI, TAU * 2.0), duration)\
			.set_delay(delay)
		
		coin.modulate.a = 0.0
		tween.tween_property(coin, "modulate:a", 1.0, duration * 0.2).set_delay(delay)
		
		# Fade out near target
		tween.tween_property(coin, "modulate:a", 0.0, duration * 0.2).set_delay(delay + duration * 0.8)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(coin):
				coin.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 4.0, 0.1)
		)

func _animate_qi_jian_zhi_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/ink_slash.png"
	var slash_tex: Texture2D = UIFactory.load_texture(texture_path)
	if slash_tex == null:
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	# Create a giant slash sweeping horizontally from left to right
	var view_size: Vector2 = get_viewport_rect().size
	var slash_size: Vector2 = Vector2(300, 300)
	
	var slash: TextureRect = TextureRect.new()
	slash.texture = slash_tex
	slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slash.size = slash_size
	slash.pivot_offset = slash_size / 2.0
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Position at center y of targets
	var y_sum: float = 0.0
	for t in alive_targets:
		var wrap: Control = t["wrap"] as Control
		y_sum += wrap.global_position.y + wrap.size.y / 2.0
	var avg_y: float = y_sum / alive_targets.size()
	
	var start_pos: Vector2 = Vector2(-250.0, avg_y - slash_size.y / 2.0)
	var end_pos: Vector2 = Vector2(view_size.x + 50.0, avg_y - slash_size.y / 2.0)
	
	slash.global_position = start_pos
	# Pointing horizontally right
	slash.rotation = 0.0
	# Set clean cyan tint
	slash.modulate = Color("8edcff")
	slash.modulate.a = 0.0
	add_child(slash)
	
	var duration: float = 0.45
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(slash, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(slash, "modulate:a", 0.9, duration * 0.2)
	tween.tween_property(slash, "modulate:a", 0.0, duration * 0.3).set_delay(duration * 0.7)
	
	# Shake enemies as the slash passes through their x-coordinate
	for t in alive_targets:
		var wrap: Control = t["wrap"] as Control
		var t_x: float = wrap.global_position.x + wrap.size.x / 2.0
		var delay: float = ((t_x - start_pos.x) / (end_pos.x - start_pos.x)) * duration
		var captured_wrap = wrap
		var shake_timer: SceneTreeTimer = get_tree().create_timer(delay)
		shake_timer.timeout.connect(func() -> void:
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 10.0, 0.25)
		)
		
	tween.finished.connect(func() -> void:
		if is_instance_valid(slash):
			slash.queue_free()
	)

func _animate_bian_ying_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/ink_slash.png"
	var slash_tex: Texture2D = UIFactory.load_texture(texture_path)
	if slash_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var slash_size: Vector2 = Vector2(160, 160)
	
	# 2 quick whip slashes (X shape)
	for i in range(2):
		var slash: TextureRect = TextureRect.new()
		slash.texture = slash_tex
		slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slash.size = slash_size
		slash.pivot_offset = slash_size / 2.0
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slash.global_position = target_center - slash_size / 2.0
		
		# Rotate diagonal slashes
		slash.rotation = PI/4.0 if i == 0 else -PI/4.0
		# Dark ink style
		slash.modulate = Color(0.15, 0.15, 0.15, 0.0)
		add_child(slash)
		
		var delay: float = i * 0.12
		var duration: float = 0.2
		
		var tween: Tween = create_tween().set_parallel(true)
		# Fade in and stretch scale
		slash.scale = Vector2(0.2, 1.4)
		tween.tween_property(slash, "scale", Vector2(1.5, 0.8), duration).set_delay(delay)
		tween.tween_property(slash, "modulate:a", 0.8, duration * 0.2).set_delay(delay)
		tween.tween_property(slash, "modulate:a", 0.0, duration * 0.8).set_delay(delay + duration * 0.2)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(slash):
				slash.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 6.0, 0.15)
		)

func _animate_lie_long_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/ink_dragon.png"
	var dragon_tex: Texture2D = UIFactory.load_texture(texture_path)
	if dragon_tex == null:
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty() and not enemy_widgets.is_empty():
		target_widget = enemy_widgets[0]
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	var dragon_size: Vector2 = Vector2(180, 180)
	
	var dragon: TextureRect = TextureRect.new()
	dragon.texture = dragon_tex
	dragon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dragon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dragon.size = dragon_size
	dragon.pivot_offset = dragon_size / 2.0
	dragon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var start_pos: Vector2 = Vector2(100.0, get_viewport_rect().size.y * 0.6)
	dragon.global_position = start_pos
	
	# Point towards target
	var to_target: Vector2 = target_center - start_pos
	dragon.rotation = to_target.angle()
	# Tint crimson dragon
	dragon.modulate = Color(1.3, 0.4, 0.3)
	dragon.modulate.a = 0.0
	add_child(dragon)
	
	var duration: float = 0.45
	var tween: Tween = create_tween().set_parallel(true)
	var end_pos: Vector2 = target_center - dragon_size / 2.0
	
	# Flying in a slightly curved path
	tween.tween_property(dragon, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(dragon, "scale", Vector2(1.2, 1.2), duration * 0.5)
	tween.tween_property(dragon, "scale", Vector2(0.8, 0.8), duration * 0.5).set_delay(duration * 0.5)
	
	tween.tween_property(dragon, "modulate:a", 1.0, duration * 0.2)
	tween.tween_property(dragon, "modulate:a", 0.0, duration * 0.2).set_delay(duration * 0.8)
	
	var captured_wrap = wrap
	tween.finished.connect(func() -> void:
		if is_instance_valid(dragon):
			dragon.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 18.0, 0.4)
	)

func _animate_wan_li_kuang_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	
	# Generate 6 sandstorm clouds sweeping the screen
	var view_size: Vector2 = get_viewport_rect().size
	var particle_count: int = 8
	
	for i in range(particle_count):
		# We draw soft colored panels as sand clouds
		var cloud: ColorRect = ColorRect.new()
		# Yellow-brown sand color with low alpha
		cloud.color = Color(0.72, 0.61, 0.41, 0.0)
		var cloud_w: float = randf_range(160.0, 260.0)
		var cloud_h: float = randf_range(160.0, 260.0)
		cloud.size = Vector2(cloud_w, cloud_h)
		cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Distribute y-positions across the viewport
		var start_pos: Vector2 = Vector2(
			randf_range(-300.0, -100.0),
			randf_range(100.0, view_size.y - 300.0)
		)
		cloud.global_position = start_pos
		add_child(cloud)
		
		var delay: float = i * 0.08
		var duration: float = randf_range(0.6, 0.9)
		var end_pos: Vector2 = Vector2(view_size.x + 100.0, start_pos.y + randf_range(-50, 50))
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(cloud, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		
		# Fade in and then out
		tween.tween_property(cloud, "color:a", randf_range(0.18, 0.28), duration * 0.3).set_delay(delay)
		tween.tween_property(cloud, "color:a", 0.0, duration * 0.4).set_delay(delay + duration * 0.6)
		
	# Shake all alive enemies as the storm passes through
	for t in enemy_widgets:
		var wrap: Control = t["wrap"] as Control
		var enemy_slots: Array = battle.state.get("enemies", []) as Array
		var idx: int = t["enemy_idx"]
		if idx < enemy_slots.size() and int(enemy_slots[idx]["hp"]) > 0:
			var captured_wrap = wrap
			var shake_timer: SceneTreeTimer = get_tree().create_timer(0.3)
			shake_timer.timeout.connect(func() -> void:
				if is_instance_valid(captured_wrap):
					# Sway/shake slowly to represent storm wind
					UIFactory.shake_node(captured_wrap, 6.0, 0.4)
			)


func _animate_lightning_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/lightning_strike.png"
	var strike_tex: Texture2D = UIFactory.load_texture(texture_path)
	if strike_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var hits: int = 1
	if card.id == "zl_wuleizhou":
		hits = 5
	elif card.id in ["zl_kuanglei", "zl_leiguang", "zl_lianzhuzhou"]:
		hits = 2
		
	# Lightning flash screen tint overlay
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color("c19bff", 0.0) # Purple tint
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.22, 0.05)
	flash_tween.tween_property(overlay, "color:a", 0.0, 0.15)
	flash_tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

	for h in range(hits):
		var delay: float = h * 0.12
		var bolt: TextureRect = TextureRect.new()
		bolt.texture = strike_tex
		bolt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bolt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var bolt_size := Vector2(100.0, 480.0)
		if card.id == "zl_shenlei":
			bolt_size = Vector2(240.0, 650.0)
		elif card.id == "zl_tianlei":
			bolt_size = Vector2(160.0, 520.0)
			
		bolt.size = bolt_size
		bolt.pivot_offset = Vector2(bolt_size.x / 2.0, bolt_size.y)
		bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var x_offset: float = randf_range(-35.0, 35.0) if hits > 1 else 0.0
		var bolt_pos := Vector2(
			target_center.x + x_offset - bolt_size.x / 2.0,
			target_center.y - bolt_size.y
		)
		bolt.global_position = bolt_pos
		bolt.modulate = Color(1.2, 1.2, 1.5)
		bolt.modulate.a = 0.0
		
		add_child(bolt)
		
		var tween: Tween = create_tween().set_parallel(true)
		bolt.scale.y = 0.2
		tween.tween_property(bolt, "scale:y", 1.0, 0.08).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bolt, "modulate:a", 1.0, 0.04).set_delay(delay)
		tween.tween_property(bolt, "modulate:a", 0.0, 0.15).set_delay(delay + 0.1)
		
		var captured_wrap = wrap
		var intensity: float = 12.0 if card.id == "zl_shenlei" else (8.0 if hits == 1 else 5.0)
		tween.finished.connect(func() -> void:
			if is_instance_valid(bolt):
				bolt.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, intensity, 0.15)
		)


func _animate_ice_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/ice_spike.png"
	var ice_tex: Texture2D = UIFactory.load_texture(texture_path)
	if ice_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_rect: Rect2 = wrap.get_global_rect()
	var bottom_center := Vector2(
		target_rect.position.x + target_rect.size.x / 2.0,
		target_rect.position.y + target_rect.size.y - 10.0
	)
	
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color("a6edff", 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.18, 0.08)
	flash_tween.tween_property(overlay, "color:a", 0.0, 0.22)
	flash_tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	
	var spike_count: int = 3
	for i in range(spike_count):
		var spike: TextureRect = TextureRect.new()
		spike.texture = ice_tex
		spike.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spike.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var size := Vector2(75.0, 150.0)
		spike.size = size
		spike.pivot_offset = Vector2(size.x / 2.0, size.y)
		spike.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var offset_x: float = (i - 1) * 35.0 + randf_range(-10, 10)
		var angle: float = (i - 1) * randf_range(10.0, 20.0)
		spike.rotation = deg_to_rad(angle)
		
		spike.global_position = Vector2(
			bottom_center.x + offset_x - size.x / 2.0,
			bottom_center.y
		)
		
		spike.scale = Vector2(1.0, 0.0)
		spike.modulate = Color("e0f7ff")
		spike.modulate.a = 0.0
		add_child(spike)
		
		var delay: float = i * 0.06
		var duration: float = 0.26
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(spike, "scale", Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.2)), duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(spike, "modulate:a", 1.0, duration * 0.4).set_delay(delay)
		tween.tween_property(spike, "modulate:a", 0.0, 0.22).set_delay(delay + duration + 0.15)
		tween.tween_property(spike, "scale", Vector2(0.3, 0.3), 0.22).set_delay(delay + duration + 0.15)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(spike):
				spike.queue_free()
			if is_instance_valid(captured_wrap) and i == 1:
				UIFactory.shake_node(captured_wrap, 6.0, 0.2)
		)


func _animate_fire_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/fireball.png"
	var fire_tex: Texture2D = UIFactory.load_texture(texture_path)
	if fire_tex == null:
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	var targets_to_shoot: Array[Dictionary] = []
	if card.id == "zl_sanmeizhenhuo":
		targets_to_shoot = alive_targets
	else:
		var active_idx: int = battle._active_enemy_index()
		var target_widget: Dictionary = {}
		for w in alive_targets:
			if w["enemy_idx"] == active_idx:
				target_widget = w
				break
		if target_widget.is_empty() and not alive_targets.is_empty():
			target_widget = alive_targets[0]
		if not target_widget.is_empty():
			targets_to_shoot.append(target_widget)
			
	if targets_to_shoot.is_empty():
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var player_center: Vector2 = Vector2(120.0, view_size.y * 0.65)
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_center = player_portrait_wrap.global_position + player_portrait_wrap.size / 2.0
		
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color("ffa366", 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.15, 0.08)
	flash_tween.tween_property(overlay, "color:a", 0.0, 0.2)
	flash_tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

	for target in targets_to_shoot:
		var wrap: Control = target["wrap"] as Control
		var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
		
		var count: int = 3 if card.id == "zl_sanmeizhenhuo" else 2
		for k in range(count):
			var delay: float = k * 0.12
			
			var fireball: TextureRect = TextureRect.new()
			fireball.texture = fire_tex
			fireball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fireball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			var f_size := Vector2(65.0, 65.0)
			fireball.size = f_size
			fireball.pivot_offset = f_size / 2.0
			fireball.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fireball.global_position = player_center - f_size / 2.0
			fireball.modulate.a = 0.0
			fireball.modulate = Color(1.3, 1.0, 0.7)
			add_child(fireball)
			
			var duration: float = 0.38
			var tween: Tween = create_tween().set_parallel(true)
			var end_pos: Vector2 = target_center - f_size / 2.0
			
			tween.tween_property(fireball, "global_position", end_pos, duration)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(fireball, "rotation", fireball.rotation + randf_range(PI, TAU), duration)\
				.set_delay(delay)
			
			tween.tween_property(fireball, "modulate:a", 1.0, duration * 0.2).set_delay(delay)
			
			var captured_wrap = wrap
			var current_target_center = target_center
			tween.finished.connect(func() -> void:
				if is_instance_valid(fireball):
					fireball.queue_free()
				if is_instance_valid(captured_wrap):
					UIFactory.shake_node(captured_wrap, 6.0, 0.15)
					_spawn_fire_explosion_particles(current_target_center)
			)


func _spawn_fire_explosion_particles(pos: Vector2) -> void:
	for i in range(8):
		var particle := ColorRect.new()
		var colors = [Color("ff3b30"), Color("ff9500"), Color("ffcc00")]
		particle.color = colors[randi() % colors.size()]
		var size_val: float = randf_range(6.0, 14.0)
		particle.size = Vector2(size_val, size_val)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.global_position = pos - particle.size / 2.0
		add_child(particle)
		
		var angle: float = randf() * TAU
		var distance: float = randf_range(40.0, 90.0)
		var velocity := Vector2(cos(angle), sin(angle)) * distance
		var duration: float = randf_range(0.25, 0.45)
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", particle.global_position + velocity, duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.1, 0.1), duration)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_earth_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/mountain_stone.png"
	var stone_tex: Texture2D = UIFactory.load_texture(texture_path)
	if stone_tex == null:
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	var targets_to_hit: Array[Dictionary] = []
	if card.id == "zl_diliebeng":
		targets_to_hit = alive_targets
	else:
		var active_idx: int = battle._active_enemy_index()
		var target_widget: Dictionary = {}
		for w in alive_targets:
			if w["enemy_idx"] == active_idx:
				target_widget = w
				break
		if target_widget.is_empty() and not alive_targets.is_empty():
			target_widget = alive_targets[0]
		if not target_widget.is_empty():
			targets_to_hit.append(target_widget)
			
	if targets_to_hit.is_empty():
		return
		
	for target in targets_to_hit:
		var wrap: Control = target["wrap"] as Control
		var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
		
		var stone: TextureRect = TextureRect.new()
		stone.texture = stone_tex
		stone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var size_val: float = 160.0 if card.id == "zl_taishan" else 120.0
		var stone_size := Vector2(size_val, size_val)
		stone.size = stone_size
		stone.pivot_offset = stone_size / 2.0
		stone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var start_pos := Vector2(
			target_center.x - 180.0,
			target_center.y - 450.0
		)
		stone.global_position = start_pos
		stone.rotation = randf_range(-PI, PI)
		stone.modulate.a = 0.0
		add_child(stone)
		
		var duration: float = 0.38
		var tween: Tween = create_tween().set_parallel(true)
		var end_pos: Vector2 = target_center - stone_size / 2.0
		
		tween.tween_property(stone, "global_position", end_pos, duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		
		tween.tween_property(stone, "rotation", stone.rotation + randf_range(PI, TAU), duration)
		tween.tween_property(stone, "modulate:a", 1.0, duration * 0.25)
		
		var captured_wrap = wrap
		var intensity: float = 16.0 if card.id == "zl_taishan" else 12.0
		var current_target_center = target_center
		tween.finished.connect(func() -> void:
			if is_instance_valid(stone):
				stone.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, intensity, 0.3)
				_spawn_earth_debris_particles(current_target_center)
		)


func _spawn_earth_debris_particles(pos: Vector2) -> void:
	for i in range(8):
		var particle := ColorRect.new()
		var colors = [Color("8b7355"), Color("a0522d"), Color("5c5c5c"), Color("8e8e8e")]
		particle.color = colors[randi() % colors.size()]
		var size_val: float = randf_range(8.0, 16.0)
		particle.size = Vector2(size_val, size_val)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.global_position = pos - particle.size / 2.0
		particle.pivot_offset = particle.size / 2.0
		particle.rotation = randf() * TAU
		add_child(particle)
		
		var angle: float = randf_range(-PI * 0.9, -PI * 0.1)
		var distance: float = randf_range(50.0, 110.0)
		var velocity := Vector2(cos(angle), sin(angle)) * distance
		var duration: float = randf_range(0.3, 0.5)
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", particle.global_position + velocity, duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-PI, PI), duration)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_heal_effect(card: CardData) -> void:
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		_spawn_single_heal_vfx(player_portrait_wrap)
		
	if card.id == "zl_wuqi" and bench_strip != null and is_instance_valid(bench_strip):
		for child in bench_strip.get_children():
			if child is Control:
				_spawn_single_heal_vfx(child, true)


func _spawn_single_heal_vfx(node: Control, is_bench: bool = false) -> void:
	var node_rect = node.get_global_rect()
	var center = node_rect.position + node_rect.size / 2.0
	
	var halo: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("2be075", 0.0)
	style.border_color = Color("a6ffd2")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	
	var halo_size: float = 70.0 if is_bench else 150.0
	style.corner_radius_top_left = int(halo_size / 2)
	style.corner_radius_top_right = int(halo_size / 2)
	style.corner_radius_bottom_left = int(halo_size / 2)
	style.corner_radius_bottom_right = int(halo_size / 2)
	style.anti_aliasing = true
	
	halo.add_theme_stylebox_override("panel", style)
	halo.size = Vector2(halo_size, halo_size)
	halo.pivot_offset = Vector2(halo_size / 2.0, halo_size / 2.0)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.global_position = center - halo.size / 2.0
	add_child(halo)
	
	var duration: float = 0.6
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(halo, "scale", Vector2(1.6, 1.6), duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	style.bg_color.a = 0.15
	tween.tween_property(style, "bg_color:a", 0.0, duration * 0.8).set_delay(duration * 0.2)
	style.border_color.a = 0.8
	tween.tween_property(style, "border_color:a", 0.0, duration)
	
	tween.finished.connect(func() -> void:
		if is_instance_valid(halo):
			halo.queue_free()
	)
	
	var particle_count: int = 6 if is_bench else 12
	for i in range(particle_count):
		var particle := ColorRect.new()
		particle.color = Color("32ff82") if randf() > 0.3 else Color("ffeb3b")
		var p_size: float = randf_range(4.0, 8.0)
		particle.size = Vector2(p_size, p_size)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var spawn_pos := Vector2(
			center.x + randf_range(-node_rect.size.x * 0.4, node_rect.size.x * 0.4),
			center.y + randf_range(-node_rect.size.y * 0.3, node_rect.size.y * 0.4)
		)
		particle.global_position = spawn_pos
		add_child(particle)
		
		var rise_distance: float = randf_range(60.0, 140.0)
		var rise_duration: float = randf_range(0.5, 0.8)
		var p_tween: Tween = create_tween().set_parallel(true)
		
		p_tween.tween_property(particle, "global_position:y", spawn_pos.y - rise_distance, rise_duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "global_position:x", spawn_pos.x + randf_range(-20, 20), rise_duration)
		p_tween.tween_property(particle, "modulate:a", 0.0, rise_duration)
		
		p_tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_yu_feng_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/toxic_bee.png"
	var bee_tex: Texture2D = UIFactory.load_texture(texture_path)
	if bee_tex == null:
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var player_center: Vector2 = Vector2(120.0, view_size.y * 0.65)
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_center = player_portrait_wrap.global_position + player_portrait_wrap.size / 2.0
		
	var bee_count: int = 15
	for i in range(bee_count):
		var target: Dictionary = alive_targets[i % alive_targets.size()]
		var wrap: Control = target["wrap"] as Control
		var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
		
		var bee := TextureRect.new()
		bee.texture = bee_tex
		bee.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bee.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var bee_size := Vector2(24.0, 24.0)
		bee.size = bee_size
		bee.pivot_offset = bee_size / 2.0
		bee.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var start_pos := player_center + Vector2(randf_range(-40, 40), randf_range(-40, 40)) - bee_size / 2.0
		bee.global_position = start_pos
		bee.modulate = Color(1.1, 1.3, 0.9)
		bee.modulate.a = 0.0
		add_child(bee)
		
		var delay: float = i * 0.035
		var duration: float = randf_range(0.42, 0.62)
		var end_pos := target_center + Vector2(randf_range(-30, 30), randf_range(-30, 30)) - bee_size / 2.0
		
		var tween: Tween = create_tween().set_parallel(true)
		
		tween.tween_property(bee, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		
		var angle_to_target: float = (end_pos - start_pos).angle()
		bee.rotation = angle_to_target
		tween.tween_property(bee, "rotation", angle_to_target + randf_range(-0.3, 0.3), duration).set_delay(delay)
		
		tween.tween_property(bee, "modulate:a", 1.0, duration * 0.25).set_delay(delay)
		bee.scale = Vector2(0.5, 0.5)
		tween.tween_property(bee, "scale", Vector2(1.2, 1.2), duration * 0.4).set_delay(delay)
		
		tween.tween_property(bee, "modulate:a", 0.0, duration * 0.3).set_delay(delay + duration * 0.7)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(bee):
				bee.queue_free()
			if is_instance_valid(captured_wrap) and randf() > 0.6:
				UIFactory.shake_node(captured_wrap, 3.0, 0.1)
		)


func _animate_wan_yi_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
		
	var alive_targets: Array[Dictionary] = []
	var enemy_slots: Array = battle.state.get("enemies", []) as Array
	for i: int in range(enemy_widgets.size()):
		if i < enemy_slots.size():
			var slot: Dictionary = enemy_slots[i] as Dictionary
			if int(slot["hp"]) > 0:
				alive_targets.append(enemy_widgets[i])
				
	if alive_targets.is_empty():
		return
		
	for target in alive_targets:
		var wrap: Control = target["wrap"] as Control
		var target_rect: Rect2 = wrap.get_global_rect()
		
		var ant_count: int = 16
		for k in range(ant_count):
			var ant := ColorRect.new()
			ant.color = Color("1e0526") if randf() > 0.3 else Color("09010d")
			var ant_w: float = randf_range(3.0, 5.0)
			var ant_h: float = randf_range(4.0, 6.0)
			ant.size = Vector2(ant_w, ant_h)
			ant.pivot_offset = ant.size / 2.0
			ant.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var start_x: float = randf_range(target_rect.position.x + 10.0, target_rect.position.x + target_rect.size.x - 10.0)
			var start_y: float = target_rect.position.y + target_rect.size.y - randf_range(5.0, 25.0)
			ant.global_position = Vector2(start_x, start_y)
			ant.rotation = deg_to_rad(randf_range(-15, 15))
			ant.modulate.a = 0.0
			add_child(ant)
			
			var delay: float = randf_range(0.0, 0.4)
			var duration: float = randf_range(0.6, 1.1)
			var crawl_distance_y: float = randf_range(60.0, 160.0)
			var crawl_drift_x: float = randf_range(-25.0, 25.0)
			
			var tween: Tween = create_tween().set_parallel(true)
			tween.tween_property(ant, "global_position:y", start_y - crawl_distance_y, duration)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(ant, "global_position:x", start_x + crawl_drift_x, duration)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_SINE)
			
			tween.tween_property(ant, "modulate:a", randf_range(0.7, 1.0), duration * 0.25).set_delay(delay)
			tween.tween_property(ant, "modulate:a", 0.0, duration * 0.4).set_delay(delay + duration * 0.6)
			
			tween.finished.connect(func() -> void:
				if is_instance_valid(ant):
					ant.queue_free()
			)


func _animate_bao_zha_gu_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/poison_explosion.png"
	var blast_tex: Texture2D = UIFactory.load_texture(texture_path)
	if blast_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var blast := TextureRect.new()
	blast.texture = blast_tex
	blast.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blast.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var blast_size := Vector2(220.0, 220.0)
	blast.size = blast_size
	blast.pivot_offset = blast_size / 2.0
	blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blast.global_position = target_center - blast_size / 2.0
	blast.modulate = Color(0.5, 1.4, 0.6)
	blast.modulate.a = 0.0
	add_child(blast)
	
	var overlay := ColorRect.new()
	overlay.color = Color("4eff76", 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var flash_tween := create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.2, 0.06)
	flash_tween.tween_property(overlay, "color:a", 0.0, 0.18)
	flash_tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	
	var duration: float = 0.32
	var tween := create_tween().set_parallel(true)
	
	blast.scale = Vector2(0.2, 0.2)
	tween.tween_property(blast, "scale", Vector2(1.2, 1.2), 0.18)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(blast, "modulate:a", 1.0, 0.06)
	tween.tween_property(blast, "modulate:a", 0.0, 0.22).set_delay(0.18)
	
	var captured_wrap = wrap
	var current_target_center = target_center
	tween.finished.connect(func() -> void:
		if is_instance_valid(blast):
			blast.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 15.0, 0.35)
			_spawn_poison_explosion_particles(current_target_center)
	)


func _spawn_poison_explosion_particles(pos: Vector2) -> void:
	for i in range(10):
		var particle := ColorRect.new()
		var colors = [Color("2dfa5c"), Color("0f3b17"), Color("adff2f")]
		particle.color = colors[randi() % colors.size()]
		var size_val: float = randf_range(6.0, 14.0)
		particle.size = Vector2(size_val, size_val)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.global_position = pos - particle.size / 2.0
		add_child(particle)
		
		var angle: float = randf() * TAU
		var distance: float = randf_range(40.0, 100.0)
		var velocity := Vector2(cos(angle), sin(angle)) * distance
		var duration: float = randf_range(0.3, 0.5)
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", particle.global_position + velocity, duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "scale", Vector2(0.1, 0.1), duration)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_du_zhen_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/poison_needle.png"
	var needle_tex: Texture2D = UIFactory.load_texture(texture_path)
	if needle_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var view_size: Vector2 = get_viewport_rect().size
	var player_center: Vector2 = Vector2(120.0, view_size.y * 0.65)
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_center = player_portrait_wrap.global_position + player_portrait_wrap.size / 2.0
		
	var needles: int = 2
	if card.id == "anu_lianduzhen":
		needles = 3
		
	for k in range(needles):
		var delay: float = k * 0.1
		var needle := TextureRect.new()
		needle.texture = needle_tex
		needle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		needle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var needle_size := Vector2(50.0, 20.0)
		needle.size = needle_size
		needle.pivot_offset = needle_size / 2.0
		needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var start_pos := player_center + Vector2(0.0, (k - 1) * 15.0) - needle_size / 2.0
		needle.global_position = start_pos
		
		var to_target: Vector2 = target_center - start_pos
		needle.rotation = to_target.angle()
		needle.modulate = Color(0.8, 1.4, 0.9)
		needle.modulate.a = 0.0
		add_child(needle)
		
		var duration: float = 0.28
		var tween := create_tween().set_parallel(true)
		var end_pos := target_center - needle_size / 2.0
		
		tween.tween_property(needle, "global_position", end_pos, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		tween.tween_property(needle, "modulate:a", 1.0, duration * 0.25).set_delay(delay)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(needle):
				needle.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 4.0, 0.12)
		)


func _animate_wu_yue_zhan_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/witch_blade_slash.png"
	var slash_tex: Texture2D = UIFactory.load_texture(texture_path)
	if slash_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var slash_count: int = 2
	if card.id == "anu_xuerenwu":
		slash_count = 3
		
	for k in range(slash_count):
		var delay: float = k * 0.16
		var slash := TextureRect.new()
		slash.texture = slash_tex
		slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var size_val: float = randf_range(150.0, 180.0)
		var slash_size := Vector2(size_val, size_val)
		slash.size = slash_size
		slash.pivot_offset = slash_size / 2.0
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slash.global_position = target_center - slash_size / 2.0
		
		slash.rotation = randf_range(-PI / 3.0, PI / 3.0)
		if k % 2 == 1:
			slash.scale.x = -1.0
			
		slash.modulate = Color("e0c2ff")
		slash.modulate.a = 0.0
		add_child(slash)
		
		var duration: float = 0.22
		var tween := create_tween().set_parallel(true)
		
		tween.tween_property(slash, "scale", Vector2(1.25, 1.25) if k % 2 == 0 else Vector2(-1.25, 1.25), duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(slash, "modulate:a", 0.9, duration * 0.3).set_delay(delay)
		tween.tween_property(slash, "modulate:a", 0.0, duration * 0.5).set_delay(delay + duration * 0.5)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(slash):
				slash.queue_free()
			if is_instance_valid(captured_wrap):
				UIFactory.shake_node(captured_wrap, 6.0, 0.15)
		)


func _animate_jiu_shen_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/drunken_god.png"
	var god_tex: Texture2D = UIFactory.load_texture(texture_path)
	if god_tex == null:
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var god := TextureRect.new()
	god.texture = god_tex
	god.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	god.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var god_w: float = 460.0
	var god_h: float = 460.0
	god.size = Vector2(god_w, god_h)
	god.pivot_offset = Vector2(god_w / 2.0, god_h) # Pivot at bottom center
	god.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Place in the center/slightly left of screen
	god.global_position = Vector2((view_size.x - god_w) / 2.0 - 50.0, view_size.y - god_h - 40.0)
	god.modulate = Color("e0c2ff") # Purple-white watercolor phantom
	god.modulate.a = 0.0
	god.scale = Vector2(0.2, 0.2)
	add_child(god)
	
	# Golden flash overlay
	var overlay := ColorRect.new()
	overlay.color = Color("ffd700", 0.0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	var flash_tween := create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.24, 0.06).set_delay(0.26)
	flash_tween.tween_property(overlay, "color:a", 0.0, 0.24).set_delay(0.32)
	flash_tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)
	
	var duration: float = 0.65
	var tween := create_tween().set_parallel(true)
	
	# God phantom rises
	tween.tween_property(god, "scale", Vector2(1.0, 1.0), 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(god, "modulate:a", 0.92, 0.12)
	
	# God phantom fades away
	tween.tween_property(god, "modulate:a", 0.0, 0.25).set_delay(0.4)
	
	# Screen shake and self-damage flash on impact
	tween.finished.connect(func() -> void:
		if is_instance_valid(god):
			god.queue_free()
		# Shake all alive enemies
		for t in enemy_widgets:
			var wrap: Control = t["wrap"] as Control
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var idx: int = t["enemy_idx"]
			if idx < enemy_slots.size() and int(enemy_slots[idx]["hp"]) > 0:
				UIFactory.shake_node(wrap, 24.0, 0.6)
		# Red flash self damage feedback
		if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
			UIFactory.shake_node(player_portrait_wrap, 10.0, 0.25)
			UIFactory.flash_node(player_portrait_wrap, Color(2.0, 0.4, 0.4), 0.25)
	)


func _animate_fei_long_effect(card: CardData, stolen_item: Dictionary = {}) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/stealing_hand.png"
	var hand_tex: Texture2D = UIFactory.load_texture(texture_path)
	if hand_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var view_size: Vector2 = get_viewport_rect().size
	var player_center: Vector2 = Vector2(120.0, view_size.y * 0.65)
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_center = player_portrait_wrap.global_position + player_portrait_wrap.size / 2.0
		
	# 人物衝向目標物（有動感的近身切入，動態計算到達敵人的精確座標）
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		var orig_pos: Vector2 = player_portrait_wrap.position
		var full_vector: Vector2 = target_center - player_center
		var distance: float = full_vector.length()
		var dash_dir: Vector2 = full_vector.normalized()
		
		# 依據雙方頭像尺寸，計算剛好接觸的距離（減去雙方半寬，多推進 40 像素以增加貼身打擊感）
		var player_half_width: float = player_portrait_wrap.size.x / 2.0
		var enemy_half_width: float = wrap.size.x / 2.0
		var contact_distance: float = player_half_width + enemy_half_width - 40.0
		var dash_distance: float = max(0.0, distance - contact_distance)
		
		var dash_tween := player_portrait_wrap.create_tween()
		
		# 衝向目標
		dash_tween.tween_property(player_portrait_wrap, "position", orig_pos + dash_dir * dash_distance, 0.22)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
		# 停留
		dash_tween.tween_interval(0.15)
		
		# 收招回彈原位
		dash_tween.tween_property(player_portrait_wrap, "position", orig_pos, 0.25)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN_OUT)
		
	var hand := TextureRect.new()
	hand.texture = hand_tex
	hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var hand_size := Vector2(70.0, 70.0)
	hand.size = hand_size
	hand.pivot_offset = hand_size / 2.0
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.global_position = player_center - hand_size / 2.0
	hand.modulate = Color("85e396") # Jade green watercolor hand
	hand.modulate.a = 0.0
	add_child(hand)
	
	var duration: float = 0.28
	var tween := create_tween()
	
	# 1. Fly to target
	tween.parallel().tween_property(hand, "global_position", target_center - hand_size / 2.0, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(hand, "modulate:a", 1.0, duration * 0.3)
	
	# 2. Return to player
	var captured_wrap = wrap
	var current_player_center = player_center
	var current_target_center = target_center
	tween.tween_callback(func() -> void:
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 6.0, 0.18)
			# Spawn gold coins flying back
			_spawn_stolen_coins(current_target_center, current_player_center)
	)
	tween.tween_property(hand, "global_position", player_center - hand_size / 2.0, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(hand, "modulate:a", 0.0, duration)
	
	tween.finished.connect(func() -> void:
		if is_instance_valid(hand):
			hand.queue_free()
		if not stolen_item.is_empty():
			_show_stolen_item_popup(stolen_item)
	)


func _spawn_stolen_coins(start_pos: Vector2, end_pos: Vector2) -> void:
	var coin_path: String = "res://assets/art/relics/tong_bao_qian.png"
	var coin_tex: Texture2D = UIFactory.load_texture(coin_path)
	if coin_tex == null:
		return
		
	var coin_count: int = 5
	for i in range(coin_count):
		var coin := TextureRect.new()
		coin.texture = coin_tex
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var coin_size := Vector2(25.0, 25.0)
		coin.size = coin_size
		coin.pivot_offset = coin_size / 2.0
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.global_position = start_pos - coin_size / 2.0
		coin.modulate.a = 0.0
		add_child(coin)
		
		var delay: float = i * 0.05
		var duration: float = randf_range(0.35, 0.5)
		
		var tween := create_tween().set_parallel(true)
		
		# Curved flying path back to player
		var control_y: float = start_pos.y - randf_range(80.0, 150.0)
		var mid_pos := Vector2((start_pos.x + end_pos.x) / 2.0, control_y)
		
		tween.tween_property(coin, "global_position", end_pos - coin_size / 2.0, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(coin, "rotation", randf_range(PI, TAU * 2.0), duration).set_delay(delay)
		tween.tween_property(coin, "modulate:a", 1.0, duration * 0.3).set_delay(delay)
		tween.tween_property(coin, "modulate:a", 0.0, duration * 0.3).set_delay(delay + duration * 0.7)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(coin):
				coin.queue_free()
		)


func _show_stolen_item_popup(item: Dictionary) -> void:
	var popup: PopupPanel = _make_battle_popup()
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.custom_minimum_size = Vector2(340, 240)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title: Label = Label.new()
	title.text = "【飛龍探雲手】妙手空空"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT_GOLD)
	box.add_child(title)
	
	var content_box: HBoxContainer = HBoxContainer.new()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 16)
	box.add_child(content_box)
	
	var item_type: String = String(item.get("type", ""))
	var item_name: String = String(item.get("display_name", "寶物"))
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var desc: String = ""
	var name_color: Color = ThemeColors.TEXT_LIGHT
	
	if item_type == "gold":
		icon.texture = UIFactory.load_texture("res://assets/art/relics/tong_bao_qian.png")
		desc = "獲得 %d 銅錢，已存入背囊。" % int(item.get("amount", 0))
		name_color = ThemeColors.HIGHLIGHT_GOLD
	elif item_type == "potion":
		var potion_id: String = String(item.get("potion_id", ""))
		var potion: Dictionary = PotionCatalog.by_id(potion_id)
		if not potion.is_empty():
			desc = String(potion.get("description", ""))
			name_color = PotionCatalog.rarity_color(potion)
			icon.texture = UIFactory.load_texture("res://assets/art/potions/%s.png" % potion_id)
			if run_state.potions.size() >= RunState.MAX_POTION_SLOTS:
				desc += "\n(藥格已滿，無法攜帶！)"
				name_color = Color("a5a5a5")
		else:
			desc = "不知名的珍奇藥品。"
	
	content_box.add_child(icon)
	
	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var name_label: Label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", name_color)
	text_box.add_child(name_label)
	
	var desc_label: Label = Label.new()
	desc_label.text = desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	text_box.add_child(desc_label)
	
	content_box.add_child(text_box)
	
	var btn: Button = _button("收下")
	btn.custom_minimum_size = Vector2(80, 32)
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(popup.hide)
	box.add_child(btn)
	
	popup.add_child(box)
	get_viewport().add_child(popup)
	popup.popup_hide.connect(popup.queue_free)
	popup.popup_centered()


func _animate_zui_meng_effect(card: CardData) -> void:
	if player_portrait_wrap == null or not is_instance_valid(player_portrait_wrap):
		return
		
	var node_rect = player_portrait_wrap.get_global_rect()
	var center = node_rect.position + node_rect.size / 2.0
	
	UIFactory.shake_node(player_portrait_wrap, 4.0, 0.4)
	UIFactory.flash_node(player_portrait_wrap, Color(1.3, 1.25, 0.8), 0.35)
	
	# Spawn moon wine mist rising sparkles
	var particle_count: int = 10
	for i in range(particle_count):
		var particle := ColorRect.new()
		particle.color = Color("ffeb99") if randf() > 0.4 else Color("f8d2ff") # Yellow-gold or soft violet
		var p_size: float = randf_range(5.0, 10.0)
		particle.size = Vector2(p_size, p_size)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var spawn_pos := Vector2(
			center.x + randf_range(-node_rect.size.x * 0.4, node_rect.size.x * 0.4),
			center.y + randf_range(-node_rect.size.y * 0.3, node_rect.size.y * 0.4)
		)
		particle.global_position = spawn_pos
		add_child(particle)
		
		var rise_distance: float = randf_range(80.0, 160.0)
		var rise_duration: float = randf_range(0.6, 1.0)
		
		var tween := create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position:y", spawn_pos.y - rise_distance, rise_duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "global_position:x", spawn_pos.x + randf_range(-30, 30), rise_duration)
		tween.tween_property(particle, "modulate:a", 0.0, rise_duration)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_meng_she_effect(card: CardData) -> void:
	if player_portrait_wrap == null or not is_instance_valid(player_portrait_wrap):
		return
	var texture_path: String = "res://assets/art/effects/serpent_shadow.png"
	var snake_tex: Texture2D = UIFactory.load_texture(texture_path)
	if snake_tex == null:
		return
		
	var node_rect = player_portrait_wrap.get_global_rect()
	var center = node_rect.position + node_rect.size / 2.0
	
	var snake := TextureRect.new()
	snake.texture = snake_tex
	snake.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snake.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var snake_size := Vector2(160.0, 240.0)
	snake.size = snake_size
	snake.pivot_offset = Vector2(snake_size.x / 2.0, snake_size.y)
	snake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Center it behind Linger
	snake.global_position = Vector2(center.x - snake_size.x / 2.0, center.y - snake_size.y * 0.8)
	snake.modulate = Color("dcb0ff") # Purple-green glowing shadow
	snake.modulate.a = 0.0
	snake.scale = Vector2(0.5, 0.5)
	
	# Add snake under Linger's wrapper if possible, or just add to root
	add_child(snake)
	
	var duration: float = 0.7
	var tween := create_tween().set_parallel(true)
	
	tween.tween_property(snake, "scale", Vector2(1.1, 1.1), duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(snake, "global_position:y", snake.global_position.y - 60.0, duration)
	tween.tween_property(snake, "modulate:a", 0.8, duration * 0.3)
	tween.tween_property(snake, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	
	tween.finished.connect(func() -> void:
		if is_instance_valid(snake):
			snake.queue_free()
		# Flash portrait
		if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
			UIFactory.flash_node(player_portrait_wrap, Color(1.3, 0.8, 1.5), 0.4)
			_spawn_serpent_glow_particles(center, node_rect)
	)


func _spawn_serpent_glow_particles(center: Vector2, rect: Rect2) -> void:
	# Spawn 15 small green/purple stars floating around Linger
	for i in range(15):
		var particle := ColorRect.new()
		particle.color = Color("c18cff") if randf() > 0.5 else Color("a6ffd2")
		particle.size = Vector2(6.0, 6.0)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.global_position = center + Vector2(randf_range(-rect.size.x * 0.3, rect.size.x * 0.3), randf_range(-rect.size.y * 0.3, rect.size.y * 0.3))
		add_child(particle)
		
		var angle := randf() * TAU
		var distance := randf_range(40.0, 100.0)
		var velocity := Vector2(cos(angle), sin(angle)) * distance
		var duration := randf_range(0.6, 1.2)
		
		var tween := create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", particle.global_position + velocity, duration)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_hui_hun_effect(card: CardData) -> void:
	if player_portrait_wrap == null or not is_instance_valid(player_portrait_wrap):
		return
		
	var node_rect = player_portrait_wrap.get_global_rect()
	var center = node_rect.position + node_rect.size / 2.0
	
	# Draw golden beam descending
	var beam := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffe066", 0.28) # Semi transparent golden
	style.border_color = Color("ffffff")
	style.border_width_left = 2
	style.border_width_right = 2
	style.anti_aliasing = true
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	
	beam.add_theme_stylebox_override("panel", style)
	beam.size = Vector2(80.0, 650.0)
	beam.pivot_offset = Vector2(40.0, 0.0)
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.global_position = Vector2(center.x - 40.0, center.y - 580.0)
	beam.scale = Vector2(0.1, 1.0)
	add_child(beam)
	
	var duration: float = 0.55
	var tween := create_tween().set_parallel(true)
	
	# Beam expands horizontally and fades out
	tween.tween_property(beam, "scale", Vector2(1.2, 1.0), duration * 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(beam, "scale", Vector2(0.01, 1.0), duration * 0.4).set_delay(duration * 0.6)
	style.bg_color.a = 0.4
	tween.tween_property(style, "bg_color:a", 0.0, duration)
	style.border_color.a = 1.0
	tween.tween_property(style, "border_color:a", 0.0, duration)
	
	tween.finished.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
		# Flash portrait
		if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
			UIFactory.flash_node(player_portrait_wrap, Color(1.5, 1.4, 0.8), 0.35)
	)
	
	# Spawn rising pink/golden sparks
	var particle_count: int = 15
	for i in range(particle_count):
		var particle := ColorRect.new()
		particle.color = Color("ffe266") if randf() > 0.4 else Color("ff99bb") # Golden or soft pink
		var p_size: float = randf_range(5.0, 10.0)
		particle.size = Vector2(p_size, p_size)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var spawn_pos := Vector2(
			center.x + randf_range(-node_rect.size.x * 0.4, node_rect.size.x * 0.4),
			center.y + randf_range(-node_rect.size.y * 0.2, node_rect.size.y * 0.4)
		)
		particle.global_position = spawn_pos
		add_child(particle)
		
		var rise_distance: float = randf_range(100.0, 220.0)
		var rise_duration: float = randf_range(0.6, 1.0)
		var delay: float = randf_range(0.0, 0.15)
		
		var p_tween := create_tween().set_parallel(true)
		p_tween.tween_property(particle, "global_position:y", spawn_pos.y - rise_distance, rise_duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		p_tween.tween_property(particle, "global_position:x", spawn_pos.x + randf_range(-40, 40), rise_duration).set_delay(delay)
		p_tween.tween_property(particle, "modulate:a", 0.0, rise_duration).set_delay(delay)
		
		p_tween.finished.connect(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _animate_xuan_feng_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	# Pure code-driven whirlwind: spawn 12 green-white wind trails orbiting the target
	var particle_count: int = 12
	for i in range(particle_count):
		var wind := ColorRect.new()
		wind.color = Color("c2f0d5") if randf() > 0.5 else Color("ffffff") # Green-white wind
		var w_size := Vector2(randf_range(15.0, 35.0), randf_range(6.0, 10.0))
		wind.size = w_size
		wind.pivot_offset = w_size / 2.0
		wind.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Initial position on a circle
		var initial_angle: float = (i / float(particle_count)) * TAU
		var start_radius: float = randf_range(80.0, 140.0)
		var start_pos := target_center + Vector2(cos(initial_angle), sin(initial_angle)) * start_radius - w_size / 2.0
		wind.global_position = start_pos
		wind.rotation = initial_angle + PI/2.0
		wind.modulate.a = 0.0
		add_child(wind)
		
		var delay: float = i * 0.04
		var duration: float = randf_range(0.5, 0.75)
		
		var tween := create_tween().set_parallel(true)
		
		# Orbiting motion: tween angle and radius
		var final_angle: float = initial_angle + TAU * 1.5
		var final_radius: float = randf_range(20.0, 40.0)
		
		# We use custom lerp callbacks or simply tween position in circle
		# For simplicity, we can tween its position directly to simulate spiral spiraling in
		tween.tween_property(wind, "global_position", target_center - w_size / 2.0, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		
		tween.tween_property(wind, "rotation", final_angle + PI/2.0, duration).set_delay(delay)
		tween.tween_property(wind, "modulate:a", 0.7, duration * 0.3).set_delay(delay)
		tween.tween_property(wind, "modulate:a", 0.0, duration * 0.4).set_delay(delay + duration * 0.6)
		
		var captured_wrap = wrap
		tween.finished.connect(func() -> void:
			if is_instance_valid(wind):
				wind.queue_free()
			if is_instance_valid(captured_wrap) and i == particle_count - 1:
				UIFactory.shake_node(captured_wrap, 5.0, 0.2)
		)


func _animate_yi_yang_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var view_size: Vector2 = get_viewport_rect().size
	var player_center: Vector2 = Vector2(120.0, view_size.y * 0.65)
	if player_portrait_wrap != null and is_instance_valid(player_portrait_wrap):
		player_center = player_portrait_wrap.global_position + player_portrait_wrap.size / 2.0
		
	# Draw thin golden laser ray
	var ray := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff59d") # Golden light
	style.border_color = Color("ffffff")
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.anti_aliasing = true
	
	ray.add_theme_stylebox_override("panel", style)
	
	# Calculate distance and angle
	var diff: Vector2 = target_center - player_center
	var distance: float = diff.length()
	var angle: float = diff.angle()
	
	ray.size = Vector2(distance, 6.0)
	ray.pivot_offset = Vector2(0.0, 3.0)
	ray.global_position = player_center - Vector2(0.0, 3.0)
	ray.rotation = angle
	ray.scale = Vector2(0.01, 1.0)
	ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ray)
	
	var duration: float = 0.22
	var tween := create_tween().set_parallel(true)
	
	# Shoot laser forward
	tween.tween_property(ray, "scale:x", 1.0, duration * 0.5)\
		.set_trans(Tween.TRANS_LINEAR)
	# Fade out
	tween.tween_property(ray, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	
	var captured_wrap = wrap
	var current_target_center = target_center
	tween.finished.connect(func() -> void:
		if is_instance_valid(ray):
			ray.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 8.0, 0.15)
			# Golden flash spark explosion on impact
			_spawn_gold_cross_spark(current_target_center)
	)


func _spawn_gold_cross_spark(pos: Vector2) -> void:
	# Golden glow cross flare particle
	var p_size := Vector2(80.0, 80.0)
	
	var flare_h := ColorRect.new()
	flare_h.color = Color("ffffff")
	flare_h.size = Vector2(p_size.x, 4.0)
	flare_h.pivot_offset = Vector2(p_size.x / 2.0, 2.0)
	flare_h.global_position = pos - Vector2(p_size.x / 2.0, 2.0)
	flare_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flare_h)
	
	var flare_v := ColorRect.new()
	flare_v.color = Color("ffffff")
	flare_v.size = Vector2(4.0, p_size.y)
	flare_v.pivot_offset = Vector2(2.0, p_size.y / 2.0)
	flare_v.global_position = pos - Vector2(2.0, p_size.y / 2.0)
	flare_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flare_v)
	
	var duration: float = 0.2
	var tween := create_tween().set_parallel(true)
	
	flare_h.scale = Vector2(0.1, 1.0)
	flare_v.scale = Vector2(1.0, 0.1)
	
	tween.tween_property(flare_h, "scale:x", 1.2, duration)
	tween.tween_property(flare_v, "scale:y", 1.2, duration)
	tween.tween_property(flare_h, "modulate:a", 0.0, duration)
	tween.tween_property(flare_v, "modulate:a", 0.0, duration)
	
	tween.finished.connect(func() -> void:
		if is_instance_valid(flare_h): flare_h.queue_free()
		if is_instance_valid(flare_v): flare_v.queue_free()
	)


func _animate_zhan_long_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/gold_giant_sword.png"
	var sword_tex: Texture2D = UIFactory.load_texture(texture_path)
	if sword_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_center: Vector2 = wrap.global_position + wrap.size / 2.0
	
	var sword := TextureRect.new()
	sword.texture = sword_tex
	sword.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sword.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var sword_size := Vector2(250.0, 250.0)
	sword.size = sword_size
	sword.pivot_offset = sword_size / 2.0
	sword.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Start above and left, rotate to point diagonally down (forceful heavy hit)
	var start_pos := Vector2(target_center.x - 200.0, target_center.y - 350.0)
	sword.global_position = start_pos
	sword.rotation = deg_to_rad(-45.0)
	# Modulate dark ink grey-bronze colors
	sword.modulate = Color("1a1a1a")
	sword.modulate.a = 0.0
	add_child(sword)
	
	var duration: float = 0.38
	var tween := create_tween().set_parallel(true)
	
	var end_pos := target_center - sword_size / 2.0
	tween.tween_property(sword, "global_position", end_pos, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(sword, "rotation", deg_to_rad(30.0), duration)
	tween.tween_property(sword, "modulate:a", 0.95, duration * 0.25)
	tween.tween_property(sword, "modulate:a", 0.0, duration * 0.3).set_delay(duration * 0.7)
	
	var captured_wrap = wrap
	var current_target_center = target_center
	tween.finished.connect(func() -> void:
		if is_instance_valid(sword):
			sword.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 20.0, 0.45)
			# Black/dark grey splash particles
			_spawn_earth_debris_particles(current_target_center)
	)


func _animate_feng_huang_effect(card: CardData) -> void:
	if player_portrait_wrap == null or not is_instance_valid(player_portrait_wrap):
		return
		
	var node_rect = player_portrait_wrap.get_global_rect()
	var center = node_rect.position + node_rect.size / 2.0
	
	var texture_path: String = "res://assets/art/effects/phoenix_feather.png"
	# Since it fails to generate, we dynamically reuse a star-like structure or gold shield Panel in code
	# We will generate 3 golden panels (StyleBoxFlat round radius) representing feathers orbiting the portrait center
	var feathers: Array[Panel] = []
	var radius: float = 85.0
	
	for i in range(3):
		var feather := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ffcc00") # Golden yellow
		style.border_color = Color("ffffff")
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.anti_aliasing = true
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		
		feather.add_theme_stylebox_override("panel", style)
		feather.size = Vector2(25.0, 12.0)
		feather.pivot_offset = Vector2(12.5, 6.0)
		feather.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Initial position around center
		var angle: float = (i / 3.0) * TAU
		feather.global_position = center + Vector2(cos(angle), sin(angle)) * radius - feather.size / 2.0
		feather.rotation = angle
		feather.modulate.a = 0.0
		add_child(feather)
		feathers.append(feather)
		
		# Orbiting rotation Tween
		var duration: float = 1.6
		var tween := create_tween().set_parallel(true)
		
		tween.tween_property(feather, "modulate:a", 0.9, 0.25)
		
		# We rotate the angle over time
		var final_angle: float = angle + TAU * 1.5
		# We can calculate positions along circular orbit using tween_method or just let it rotate
		tween.tween_property(feather, "rotation", final_angle, duration)
		
		# Custom method tween to update orbit position
		var captured_feather = feather
		var captured_center = center
		var captured_angle = angle
		var captured_radius = radius
		tween.tween_method(func(progress: float) -> void:
			if is_instance_valid(captured_feather):
				var curr_angle: float = captured_angle + progress * TAU * 1.5
				captured_feather.global_position = captured_center + Vector2(cos(curr_angle), sin(curr_angle)) * captured_radius - captured_feather.size / 2.0
		, 0.0, 1.0, duration)
		
		# Fade out near end
		tween.tween_property(feather, "modulate:a", 0.0, 0.35).set_delay(duration - 0.35)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(captured_feather):
				captured_feather.queue_free()
		)


func _animate_gu_shen_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/drunken_god.png" # Reuse drunken god model
	var god_tex: Texture2D = UIFactory.load_texture(texture_path)
	if god_tex == null:
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	var god := TextureRect.new()
	god.texture = god_tex
	god.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	god.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var god_w: float = 460.0
	var god_h: float = 460.0
	god.size = Vector2(god_w, god_h)
	god.pivot_offset = Vector2(god_w / 2.0, god_h)
	god.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	god.global_position = Vector2((view_size.x - god_w) / 2.0 - 50.0, view_size.y - god_h - 40.0)
	god.modulate = Color("1e4620") # Dark green poison god phantom
	god.modulate.a = 0.0
	god.scale = Vector2(0.2, 0.2)
	add_child(god)
	
	# Poison shockwave ring
	var shockwave := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2be075", 0.0)
	style.border_color = Color("85ffb1")
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.anti_aliasing = true
	style.corner_radius_top_left = 200
	style.corner_radius_top_right = 200
	style.corner_radius_bottom_left = 200
	style.corner_radius_bottom_right = 200
	
	shockwave.add_theme_stylebox_override("panel", style)
	var ring_size := Vector2(100.0, 100.0)
	shockwave.size = ring_size
	shockwave.pivot_offset = ring_size / 2.0
	shockwave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shockwave.global_position = Vector2(view_size.x / 2.0 - 50.0, view_size.y / 2.0) - ring_size / 2.0
	shockwave.scale = Vector2(0.1, 0.1)
	
	var duration: float = 0.75
	var tween := create_tween().set_parallel(true)
	
	# God rises
	tween.tween_property(god, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(god, "modulate:a", 0.88, 0.15)
	
	# God fades
	tween.tween_property(god, "modulate:a", 0.0, 0.3).set_delay(0.45)
	
	# Shockwave triggers at peak rise
	tween.tween_callback(func() -> void:
		add_child(shockwave)
		var sw_tween := create_tween().set_parallel(true)
		sw_tween.tween_property(shockwave, "scale", Vector2(8.0, 8.0), 0.45)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		sw_tween.tween_property(style, "border_color:a", 0.0, 0.45)
		sw_tween.finished.connect(func() -> void:
			if is_instance_valid(shockwave):
				shockwave.queue_free()
		)
	).set_delay(0.3)
	
	# Impact shake on all enemies
	tween.finished.connect(func() -> void:
		if is_instance_valid(god):
			god.queue_free()
		for t in enemy_widgets:
			var wrap: Control = t["wrap"] as Control
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var idx: int = t["enemy_idx"]
			if idx < enemy_slots.size() and int(enemy_slots[idx]["hp"]) > 0:
				UIFactory.shake_node(wrap, 15.0, 0.4)
	)


func _animate_confuse_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/poison_explosion.png" # Reuse poison cloud shape
	var smoke_tex: Texture2D = UIFactory.load_texture(texture_path)
	if smoke_tex == null:
		return
		
	var active_idx: int = battle._active_enemy_index()
	var target_widget: Dictionary = {}
	for w: Dictionary in enemy_widgets:
		if w["enemy_idx"] == active_idx:
			target_widget = w
			break
	if target_widget.is_empty():
		for w: Dictionary in enemy_widgets:
			var enemy_slots: Array = battle.state.get("enemies", []) as Array
			var i: int = w["enemy_idx"]
			if i < enemy_slots.size() and int(enemy_slots[i]["hp"]) > 0:
				target_widget = w
				break
	if target_widget.is_empty():
		return
		
	var wrap: Control = target_widget["wrap"] as Control
	var target_rect = wrap.get_global_rect()
	var target_top := Vector2(target_rect.position.x + target_rect.size.x / 2.0, target_rect.position.y + 40.0)
	
	# Swirling confusing smoke over enemy head
	var smoke := TextureRect.new()
	smoke.texture = smoke_tex
	smoke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	smoke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var smoke_size := Vector2(100.0, 100.0)
	smoke.size = smoke_size
	smoke.pivot_offset = smoke_size / 2.0
	smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	smoke.global_position = target_top - smoke_size / 2.0
	smoke.modulate = Color("d46eff") # Purple pink smoke
	smoke.modulate.a = 0.0
	smoke.scale = Vector2(0.2, 0.2)
	add_child(smoke)
	
	var duration: float = 0.55
	var tween := create_tween().set_parallel(true)
	
	# Spiral spin and fade in/out
	tween.tween_property(smoke, "scale", Vector2(1.2, 1.2), duration * 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(smoke, "scale", Vector2(0.1, 0.1), duration * 0.4).set_delay(duration * 0.6)
	
	tween.tween_property(smoke, "rotation", smoke.rotation + TAU * 2.0, duration)
	tween.tween_property(smoke, "modulate:a", 0.85, duration * 0.3)
	tween.tween_property(smoke, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	
	var captured_wrap = wrap
	tween.finished.connect(func() -> void:
		if is_instance_valid(smoke):
			smoke.queue_free()
		if is_instance_valid(captured_wrap):
			UIFactory.shake_node(captured_wrap, 4.0, 0.2)
	)


func _animate_poison_fog_effect(card: CardData) -> void:
	if battle == null or enemy_widgets.is_empty():
		return
	var texture_path: String = "res://assets/art/effects/poison_explosion.png" # Reuse soft cloud texture
	var fog_tex: Texture2D = UIFactory.load_texture(texture_path)
	if fog_tex == null:
		return
		
	var view_size: Vector2 = get_viewport_rect().size
	# Target the entire bottom area of all enemies
	# Spawn 3 large drifting clouds at the bottom center of the screen (enemies side)
	var center_x: float = view_size.x * 0.72
	var bottom_y: float = view_size.y * 0.68
	
	for i in range(3):
		var fog := TextureRect.new()
		fog.texture = fog_tex
		fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var fog_size := Vector2(250.0, 250.0)
		fog.size = fog_size
		fog.pivot_offset = fog_size / 2.0
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Offset positions
		var start_pos := Vector2(
			center_x + (i - 1) * 80.0 - fog_size.x / 2.0 + randf_range(-20, 20),
			bottom_y - fog_size.y / 2.0 + randf_range(-15, 15)
		)
		fog.global_position = start_pos
		# Modulate purple/green toxic mix
		fog.modulate = Color("2e7d32") if i % 2 == 0 else Color("7b1fa2")
		fog.modulate.a = 0.0
		add_child(fog)
		
		var delay: float = i * 0.08
		var duration: float = randf_range(0.8, 1.2)
		
		var tween := create_tween().set_parallel(true)
		
		# Slowly drift left/right and float up
		var drift_x: float = randf_range(-40.0, 40.0)
		var drift_y: float = randf_range(-30.0, -10.0)
		
		tween.tween_property(fog, "global_position:x", start_pos.x + drift_x, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(fog, "global_position:y", start_pos.y + drift_y, duration)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_SINE)
		
		# Fade in and out
		tween.tween_property(fog, "modulate:a", 0.42, duration * 0.3).set_delay(delay)
		tween.tween_property(fog, "modulate:a", 0.0, duration * 0.4).set_delay(delay + duration * 0.6)
		
		tween.finished.connect(func() -> void:
			if is_instance_valid(fog):
				fog.queue_free()
		)


