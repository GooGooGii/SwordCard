extends Control

var characters: Array[CharacterData] = []
var enemies: Array[EnemyData] = []
var selected_character: CharacterData
var selected_enemy: EnemyData
var run_deck: Array[CardData] = []
var run_hp: int = 0
var run_power_bonus: int = 0
var encounter_index: int = 0
var encounter_choices: Array[Array] = []
var deck: DeckManager
var resolver: EffectResolver
var state: Dictionary = {}
var action_index: int = 0
var root: MarginContainer
var background_rect: TextureRect
var hand_row: HBoxContainer
var log_label: RichTextLabel
var status_label: Label
var enemy_label: Label
var player_feedback_label: Label
var enemy_feedback_label: Label
var end_turn_button: Button
var deck_overlay: Control
var deck_view_mode: String = "view"
var pending_rest_heal: int = 0
var card_buttons: Array[Button] = []
var battle_log: Array[String] = []

func _ready() -> void:
	randomize()
	characters = GameData.characters()
	enemies = GameData.enemies()
	_build_root()
	show_main_menu()

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
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

func _clear_root() -> void:
	close_deck_view()
	for child: Node in root.get_children():
		child.queue_free()

func _set_background(path: String) -> void:
	if background_rect == null:
		return
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		background_rect.texture = texture

func show_main_menu() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_title("SwordCard 仙劍1 同人卡牌原型", 34))
	box.add_child(_paragraph("私人同人原型：使用原作角色名與招式名，僅供本機學習展示。"))
	var start_button: Button = _button("開始遊戲")
	start_button.pressed.connect(show_character_select)
	box.add_child(start_button)
	var quit_button: Button = _button("離開")
	quit_button.pressed.connect(get_tree().quit)
	box.add_child(quit_button)

func show_character_select() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)
	layout.add_child(_title("選擇角色", 30))
	layout.add_child(_paragraph("四層小型冒險：路線中會出現戰鬥、休息與事件，第四層挑戰拜月教徒。"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	layout.add_child(grid)
	for character: CharacterData in characters:
		grid.add_child(_character_card(character))
	var back: Button = _button("返回主選單")
	back.pressed.connect(show_main_menu)
	layout.add_child(back)

func _character_card(character: CharacterData) -> Control:
	var panel: PanelContainer = _make_panel()
	panel.custom_minimum_size = Vector2(560, 190)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var portrait: TextureRect = _portrait_rect(character.portrait_path, Vector2(150, 150))
	if portrait.texture != null:
		box.add_child(portrait)
	box.add_child(_title(character.display_name, 24))
	box.add_child(_paragraph(character.battle_style))
	var card_names: Array[String] = []
	for card: CardData in character.starting_deck:
		card_names.append(card.display_title())
	var deck_text: String = "起始牌組：" + ", ".join(card_names)
	box.add_child(_paragraph(deck_text))
	var choose: Button = _button("以 %s 出戰" % character.display_name)
	choose.pressed.connect(func(): start_run(character))
	box.add_child(choose)
	return panel

func start_run(character: CharacterData) -> void:
	selected_character = character.clone()
	run_deck.clear()
	for card: CardData in selected_character.starting_deck:
		run_deck.append(card.clone())
	run_hp = selected_character.max_hp
	run_power_bonus = 0
	encounter_index = 0
	encounter_choices = _make_encounter_choices()
	show_progress_screen()

func _make_encounter_choices() -> Array[Array]:
	var choices: Array[Array] = []
	var normal_enemies: Array[EnemyData] = []
	for enemy: EnemyData in enemies:
		if enemy.id != "moon_worshipper":
			normal_enemies.append(enemy)
	for i: int in range(3):
		normal_enemies.shuffle()
		var row: Array[Dictionary] = []
		row.append({"type": "battle", "enemy": normal_enemies[0].clone()})
		if i == 1:
			row.append({"type": "rest"})
		elif i == 2:
			row.append({"type": "event"})
		else:
			row.append({"type": "battle", "enemy": normal_enemies[1 % normal_enemies.size()].clone()})
		choices.append(row)
	for enemy: EnemyData in enemies:
		if enemy.id == "moon_worshipper":
			var boss_row: Array[Dictionary] = []
			boss_row.append({"type": "boss", "enemy": enemy.clone()})
			choices.append(boss_row)
			break
	return choices

func show_progress_screen() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var choices: Array = encounter_choices[encounter_index]
	box.add_child(_title("第 %d / %d 層" % [encounter_index + 1, encounter_choices.size()], 34))
	box.add_child(_paragraph("%s  HP %d/%d  牌組 %d 張  本輪增傷 +%d" % [selected_character.display_name, run_hp, selected_character.max_hp, run_deck.size(), run_power_bonus]))
	if choices.size() > 1:
		box.add_child(_paragraph("選擇下一條路線"))
	else:
		box.add_child(_paragraph("終點 Boss"))
	box.add_child(_paragraph(_passive_text()))
	var route_row: HBoxContainer = HBoxContainer.new()
	route_row.add_theme_constant_override("separation", 14)
	box.add_child(route_row)
	for node_variant: Variant in choices:
		var node_data: Dictionary = node_variant as Dictionary
		route_row.add_child(_route_node_button(node_data))
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)
	var menu: Button = _button("放棄並返回主選單")
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func start_next_battle(enemy: EnemyData) -> void:
	selected_enemy = enemy.clone()
	deck = DeckManager.new()
	resolver = EffectResolver.new()
	deck.setup(run_deck)
	action_index = 0
	battle_log.clear()
	state = {
		"player_name": selected_character.display_name,
		"player_max_hp": selected_character.max_hp,
		"player_hp": run_hp,
		"player_block": 0,
		"player_poison": 0,
		"player_weak": 0,
		"player_power": run_power_bonus,
		"enemy_name": selected_enemy.display_name,
		"enemy_max_hp": selected_enemy.max_hp,
		"enemy_hp": selected_enemy.max_hp,
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"energy": 3,
		"pending_draw": 0,
		"turn": 0,
		"li_discount_used": false,
		"lin_block_used": false
	}
	_apply_battle_start_passive()
	_build_battle_scene()
	_start_player_turn()

func _build_battle_scene() -> void:
	_set_background("res://assets/art/battle_bg.png")
	_clear_root()
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 12)
	root.add_child(screen)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color("f3ead2"))
	screen.add_child(status_label)
	var middle: HBoxContainer = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	screen.add_child(middle)
	var player_panel: PanelContainer = _make_panel()
	player_panel.custom_minimum_size = Vector2(380, 220)
	var player_box: VBoxContainer = VBoxContainer.new()
	player_panel.add_child(player_box)
	var player_portrait: TextureRect = _portrait_rect(selected_character.portrait_path, Vector2(210, 180))
	if player_portrait.texture != null:
		player_box.add_child(player_portrait)
	player_box.add_child(_title(selected_character.display_name, 28))
	player_box.add_child(_paragraph(selected_character.battle_style))
	player_box.add_child(_paragraph("卡牌以點擊施放。靈力不足時不可出牌。"))
	player_box.add_child(_paragraph(_passive_text()))
	player_feedback_label = _feedback_label()
	player_box.add_child(player_feedback_label)
	middle.add_child(player_panel)
	var enemy_panel: PanelContainer = _make_panel()
	enemy_panel.custom_minimum_size = Vector2(380, 220)
	var enemy_box: VBoxContainer = VBoxContainer.new()
	enemy_panel.add_child(enemy_box)
	var enemy_portrait: TextureRect = _portrait_rect(selected_enemy.portrait_path, Vector2(230, 190))
	if enemy_portrait.texture != null:
		enemy_box.add_child(enemy_portrait)
	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.add_theme_font_size_override("font_size", 22)
	enemy_label.add_theme_color_override("font_color", Color("f8e6c8"))
	enemy_box.add_child(enemy_label)
	enemy_feedback_label = _feedback_label()
	enemy_box.add_child(enemy_feedback_label)
	middle.add_child(enemy_panel)
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(360, 220)
	log_label.fit_content = true
	log_label.add_theme_color_override("default_color", Color("d8e0ec"))
	log_label.add_theme_font_size_override("normal_font_size", 16)
	middle.add_child(log_label)
	hand_row = HBoxContainer.new()
	hand_row.add_theme_constant_override("separation", 10)
	screen.add_child(hand_row)
	end_turn_button = _button("結束回合")
	end_turn_button.pressed.connect(end_player_turn)
	screen.add_child(end_turn_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	screen.add_child(deck_button)

func _start_player_turn() -> void:
	state["turn"] = int(state["turn"]) + 1
	state["energy"] = 3
	state["player_block"] = 0
	state["enemy_block"] = 0
	state["pending_draw"] = 0
	state["lin_block_used"] = false
	if int(state["enemy_vulnerable"]) > 0:
		state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	if int(state["enemy_weak"]) > 0:
		state["enemy_weak"] = int(state["enemy_weak"]) - 1
	var before_tick: Dictionary = _snapshot_state()
	_add_logs(resolver.tick_statuses(state))
	_show_state_feedback(before_tick)
	if _check_battle_end():
		return
	deck.draw(5)
	_add_log("第 %d 回合開始，抽 5 張牌。" % state["turn"])
	_refresh_battle()

func play_card(card: CardData) -> void:
	var cost: int = _effective_card_cost(card)
	if int(state["energy"]) < cost:
		_add_log("靈力不足，無法施放 %s。" % card.display_title())
		_refresh_battle()
		return
	state["energy"] = int(state["energy"]) - cost
	if selected_character.id == "li_xiaoyao" and card.card_type == "attack" and not bool(state["li_discount_used"]):
		state["li_discount_used"] = true
	_add_log("施放 %s。" % card.display_title())
	var before_card: Dictionary = _snapshot_state()
	_add_logs(resolver.resolve_card(card, state))
	_apply_card_play_passive(card)
	_show_state_feedback(before_card)
	deck.discard_card(card)
	if int(state["pending_draw"]) > 0:
		deck.draw(int(state["pending_draw"]))
		state["pending_draw"] = 0
	if _check_battle_end():
		return
	_refresh_battle()

func end_player_turn() -> void:
	end_turn_button.disabled = true
	deck.discard_hand()
	var action: Dictionary = selected_enemy.actions[action_index % selected_enemy.actions.size()]
	action_index = action_index + 1
	_add_log("%s：%s。" % [selected_enemy.display_name, action["intent"]])
	var before_enemy: Dictionary = _snapshot_state()
	_add_logs(resolver.resolve_enemy_action(action, state))
	_show_state_feedback(before_enemy)
	if _check_battle_end():
		return
	_start_player_turn()

func _check_battle_end() -> bool:
	if int(state["enemy_hp"]) <= 0:
		_complete_battle_victory()
		return true
	if int(state["player_hp"]) <= 0:
		show_result(false)
		return true
	return false

func _complete_battle_victory() -> void:
	run_hp = int(state["player_hp"])
	encounter_index = encounter_index + 1
	if encounter_index >= encounter_choices.size():
		show_result(true)
	else:
		show_card_reward()

func show_card_reward() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("戰鬥勝利", 34))
	box.add_child(_paragraph("%s 擊敗了 %s。選擇 1 張卡加入牌組。" % [selected_character.display_name, selected_enemy.display_name]))
	box.add_child(_paragraph("目前 HP %d/%d，牌組 %d 張。" % [run_hp, selected_character.max_hp, run_deck.size()]))
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
	var rewards: Array[CardData] = []
	for i: int in range(min(3, pool.size())):
		rewards.append(pool[i])
	return rewards

func choose_reward_card(card: CardData) -> void:
	run_deck.append(card.clone())
	show_progress_screen()

func _route_node_button(node_data: Dictionary) -> Button:
	var node_type: String = String(node_data.get("type", "battle"))
	if node_type == "rest":
		return _route_rest_button()
	if node_type == "event":
		return _route_event_button()
	var enemy: EnemyData = node_data["enemy"] as EnemyData
	return _route_enemy_button(enemy, node_type == "boss")

func _route_enemy_button(enemy: EnemyData, is_boss: bool = false) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	var label: String = "Boss" if is_boss else "戰鬥"
	button.text = "%s\n%s  HP %d\n%s" % [label, enemy.display_name, enemy.max_hp, _enemy_route_summary(enemy)]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	var bg_color: Color = Color("452a35") if is_boss else Color("273449")
	button.add_theme_stylebox_override("normal", _style_box(bg_color, Color("c8b46f"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(bg_color.lightened(0.14), Color("f7df9c"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("1d2838"), Color("e4c66a"), 2, 8))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.pressed.connect(func(): start_next_battle(enemy))
	return button

func _route_rest_button() -> Button:
	var heal_amount: int = max(1, int(ceil(selected_character.max_hp * 0.25)))
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	button.text = "休息\n回復 %d HP\n或升級 1 張牌" % heal_amount
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _style_box(Color("2f5f4a"), Color("c8e6c9"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("3d755d"), Color("eef9df"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("244736"), Color("d8f0c4"), 2, 8))
	button.add_theme_color_override("font_color", Color("f4ffe9"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.pressed.connect(resolve_rest_node)
	return button

func _route_event_button() -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	button.text = "奇遇\n山路異光\n選擇一項機緣"
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _style_box(Color("4f3f73"), Color("d9c2ff"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("66508f"), Color("efe2ff"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("382d55"), Color("d9c2ff"), 2, 8))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.pressed.connect(show_event_node)
	return button

func _enemy_route_summary(enemy: EnemyData) -> String:
	var badges: Array[String] = []
	for action: Dictionary in enemy.actions:
		var badge: String = _intent_badge(action)
		for part: String in badge.split(" "):
			if not badges.has(part):
				badges.append(part)
	return " ".join(badges)

func resolve_rest_node() -> void:
	pending_rest_heal = max(1, int(ceil(selected_character.max_hp * 0.25)))
	show_rest_node()

func show_rest_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("清修片刻", 34))
	box.add_child(_paragraph("溪聲入耳，山風洗塵。你可以調息療傷，也可以靜心打磨一式招法。"))
	box.add_child(_paragraph("%s  HP %d/%d  可升級 %d 張牌" % [selected_character.display_name, run_hp, selected_character.max_hp, _upgradeable_cards().size()]))
	var heal_button: Button = _button("調息：回復 %d HP" % pending_rest_heal)
	heal_button.pressed.connect(resolve_rest_heal)
	box.add_child(heal_button)
	var upgrade_button: Button = _button("打磨招式：升級 1 張牌")
	upgrade_button.disabled = _upgradeable_cards().is_empty()
	upgrade_button.pressed.connect(show_upgrade_card_view)
	box.add_child(upgrade_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func resolve_rest_heal() -> void:
	run_hp = min(selected_character.max_hp, run_hp + pending_rest_heal)
	pending_rest_heal = 0
	advance_non_battle_node()

func show_event_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("山路異光", 34))
	box.add_child(_paragraph("石壁間浮現微光，像是前人留下的靈痕。你可以停步調息，也可以冒險汲取其中力量。"))
	box.add_child(_paragraph("%s  HP %d/%d  本輪增傷 +%d" % [selected_character.display_name, run_hp, selected_character.max_hp, run_power_bonus]))
	var heal_button: Button = _button("調息：回復 8 HP")
	heal_button.pressed.connect(func(): resolve_event_heal(8))
	box.add_child(heal_button)
	var card_button: Button = _button("探取：失去 6 HP，獲得 1 張卡")
	card_button.pressed.connect(resolve_event_gain_card)
	box.add_child(card_button)
	var power_button: Button = _button("凝神：本輪增傷 +1")
	power_button.pressed.connect(resolve_event_power)
	box.add_child(power_button)
	var upgrade_button: Button = _button("悟法：升級 1 張牌")
	upgrade_button.disabled = _upgradeable_cards().is_empty()
	upgrade_button.pressed.connect(show_upgrade_card_view)
	box.add_child(upgrade_button)
	var remove_button: Button = _button("洗髓：移除 1 張牌")
	remove_button.disabled = run_deck.size() <= 5
	remove_button.pressed.connect(show_remove_card_view)
	box.add_child(remove_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func resolve_event_heal(amount: int) -> void:
	run_hp = min(selected_character.max_hp, run_hp + amount)
	advance_non_battle_node()

func resolve_event_gain_card() -> void:
	run_hp = max(1, run_hp - 6)
	var rewards: Array[CardData] = _make_reward_choices()
	if not rewards.is_empty():
		run_deck.append(rewards[0].clone())
	advance_non_battle_node()

func resolve_event_power() -> void:
	run_power_bonus = run_power_bonus + 1
	advance_non_battle_node()

func show_remove_card_view() -> void:
	if run_deck.size() <= 5:
		return
	show_deck_view("remove")

func show_upgrade_card_view() -> void:
	if _upgradeable_cards().is_empty():
		return
	show_deck_view("upgrade")

func remove_card_from_run_deck(card: CardData) -> void:
	if run_deck.size() <= 5:
		close_deck_view()
		return
	for i: int in range(run_deck.size()):
		if run_deck[i] == card:
			run_deck.remove_at(i)
			break
	close_deck_view()
	advance_non_battle_node()

func upgrade_card_in_run_deck(card: CardData) -> void:
	if card.upgraded:
		return
	for i: int in range(run_deck.size()):
		if run_deck[i] == card:
			run_deck[i] = card.upgraded_copy()
			break
	close_deck_view()
	advance_non_battle_node()

func _upgradeable_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card: CardData in run_deck:
		if not card.upgraded:
			cards.append(card)
	return cards

func advance_non_battle_node() -> void:
	encounter_index = encounter_index + 1
	if encounter_index >= encounter_choices.size():
		show_result(true)
	else:
		show_progress_screen()

func show_deck_view(mode: String = "view") -> void:
	close_deck_view()
	deck_view_mode = mode
	deck_overlay = PanelContainer.new()
	deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_overlay.add_theme_stylebox_override("panel", _style_box(Color("0b111a", 0.94), Color("c8b46f"), 2, 8))
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
	if deck_view_mode == "remove":
		title_text = "選擇要移除的牌"
	elif deck_view_mode == "upgrade":
		title_text = "選擇要升級的牌"
	box.add_child(_title(title_text, 32))
	box.add_child(_paragraph("%s  HP %d/%d  共 %d 張牌" % [selected_character.display_name, run_hp, selected_character.max_hp, run_deck.size()]))
	var summary: Label = _paragraph(_deck_summary_text())
	box.add_child(summary)
	if deck_view_mode == "remove":
		box.add_child(_paragraph("至少保留 5 張牌。點選一張牌後會移除並完成事件。"))
	elif deck_view_mode == "upgrade":
		box.add_child(_paragraph("點選一張未升級的牌，升級後會完成此節點。"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for card: CardData in run_deck:
		grid.add_child(_deck_view_card(card, deck_view_mode))
	var close_button: Button = _button("關閉")
	close_button.pressed.connect(close_deck_view)
	box.add_child(close_button)

func close_deck_view() -> void:
	if deck_overlay != null:
		deck_overlay.queue_free()
		deck_overlay = null
	deck_view_mode = "view"

func _deck_summary_text() -> String:
	var attack_count: int = 0
	var skill_count: int = 0
	var power_count: int = 0
	for card: CardData in run_deck:
		match card.card_type:
			"attack":
				attack_count = attack_count + 1
			"skill":
				skill_count = skill_count + 1
			"power":
				power_count = power_count + 1
	return "攻擊 %d    技能 %d    能力 %d    可升級 %d\n%s" % [attack_count, skill_count, power_count, _upgradeable_cards().size(), _duplicate_summary_text()]

func _duplicate_summary_text() -> String:
	var counts: Dictionary = {}
	var names: Dictionary = {}
	for card: CardData in run_deck:
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

func _deck_view_card(card: CardData, mode: String = "view") -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(170, 170)
	button.text = "%s\n%s    費用 %d\n\n%s" % [card.display_title(), _card_type_name(card.card_type), card.cost, card.display_description()]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var selectable: bool = mode == "remove" or (mode == "upgrade" and not card.upgraded)
	button.disabled = not selectable
	_style_card_button(button, card, true)
	if mode == "remove":
		button.pressed.connect(func(): remove_card_from_run_deck(card))
	elif mode == "upgrade" and not card.upgraded:
		button.pressed.connect(func(): upgrade_card_in_run_deck(card))
	else:
		button.add_theme_stylebox_override("disabled", _style_box(_card_color(card.card_type, true), Color("e7d38a"), 2, 8))
		button.add_theme_color_override("font_disabled_color", Color("fff8dc"))
	return button

func show_result(victory: bool) -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	if victory:
		box.add_child(_title("小型冒險完成", 34))
		box.add_child(_paragraph("%s 完成了 %d 層路線，最終 HP %d/%d。" % [selected_character.display_name, encounter_choices.size(), run_hp, selected_character.max_hp]))
	else:
		box.add_child(_title("戰鬥失敗", 34))
		box.add_child(_paragraph("%s 敗於 %s。調整出牌節奏再試一次。" % [selected_character.display_name, selected_enemy.display_name]))
	var retry: Button = _button("重新開始此角色")
	retry.pressed.connect(func(): start_run(selected_character))
	box.add_child(retry)
	var select: Button = _button("重新選擇角色")
	select.pressed.connect(show_character_select)
	box.add_child(select)
	var menu: Button = _button("返回主選單")
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func _refresh_battle() -> void:
	status_label.text = "第 %d/%d 層    %s\nHP %d/%d    護體 %d    靈力 %d/3    抽牌 %d    棄牌 %d    蠱毒 %d" % [
		encounter_index + 1,
		encounter_choices.size(),
		state["player_name"],
		state["player_hp"],
		state["player_max_hp"],
		state["player_block"],
		state["energy"],
		deck.draw_pile.size(),
		deck.discard_pile.size(),
		state["player_poison"]
	]
	var next_action: Dictionary = selected_enemy.actions[action_index % selected_enemy.actions.size()]
	enemy_label.text = "%s\n\nHP %d/%d    護體 %d\n蠱毒 %d    虛弱 %d    破綻 %d\n\n%s  下一步：%s" % [
		state["enemy_name"],
		state["enemy_hp"],
		state["enemy_max_hp"],
		state["enemy_block"],
		state["enemy_poison"],
		state["enemy_weak"],
		state["enemy_vulnerable"],
		_intent_badge(next_action),
		next_action["intent"]
	]
	for child: Node in hand_row.get_children():
		child.queue_free()
	card_buttons.clear()
	for card: CardData in deck.hand:
		var button: Button = _card_button(card)
		hand_row.add_child(button)
		card_buttons.append(button)
	log_label.text = "\n".join(battle_log.slice(max(0, battle_log.size() - 9)))
	end_turn_button.disabled = false

func _card_button(card: CardData) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(158, 184)
	var cost: int = _effective_card_cost(card)
	var type_name: String = _card_type_name(card.card_type)
	button.text = "%s\n%s    費用 %d\n\n%s" % [card.display_title(), type_name, cost, card.display_description()]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var affordable: bool = int(state["energy"]) >= cost
	button.disabled = not affordable
	_style_card_button(button, card, affordable)
	button.pressed.connect(func(): play_card(card))
	return button

func _reward_card_button(card: CardData) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 210)
	button.text = "%s\n%s    費用 %d\n\n%s" % [card.display_title(), _card_type_name(card.card_type), card.cost, card.display_description()]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_card_button(button, card, true)
	return button

func _snapshot_state() -> Dictionary:
	return {
		"player_hp": int(state["player_hp"]),
		"player_block": int(state["player_block"]),
		"player_poison": int(state["player_poison"]),
		"player_weak": int(state["player_weak"]),
		"enemy_hp": int(state["enemy_hp"]),
		"enemy_block": int(state["enemy_block"]),
		"enemy_poison": int(state["enemy_poison"]),
		"enemy_weak": int(state["enemy_weak"]),
		"enemy_vulnerable": int(state["enemy_vulnerable"])
	}

func _show_state_feedback(before: Dictionary) -> void:
	var player_lines: Array[String] = []
	var enemy_lines: Array[String] = []
	var player_hp_delta: int = int(state["player_hp"]) - int(before["player_hp"])
	var enemy_hp_delta: int = int(state["enemy_hp"]) - int(before["enemy_hp"])
	var player_block_delta: int = int(state["player_block"]) - int(before["player_block"])
	var enemy_block_delta: int = int(state["enemy_block"]) - int(before["enemy_block"])
	var player_poison_delta: int = int(state["player_poison"]) - int(before["player_poison"])
	var enemy_poison_delta: int = int(state["enemy_poison"]) - int(before["enemy_poison"])
	var enemy_weak_delta: int = int(state["enemy_weak"]) - int(before["enemy_weak"])
	var enemy_vulnerable_delta: int = int(state["enemy_vulnerable"]) - int(before["enemy_vulnerable"])
	if player_hp_delta < 0:
		player_lines.append("受傷 %d" % abs(player_hp_delta))
	elif player_hp_delta > 0:
		player_lines.append("治療 +%d" % player_hp_delta)
	if player_block_delta > 0:
		player_lines.append("護體 +%d" % player_block_delta)
	if player_poison_delta > 0:
		player_lines.append("蠱毒 +%d" % player_poison_delta)
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
		_show_feedback(enemy_feedback_label, enemy_lines, Color("f7df9c"))

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

func _intent_badge(action: Dictionary) -> String:
	var effects: Array = action.get("effects", []) as Array
	var has_damage: bool = false
	var has_block: bool = false
	var has_status: bool = false
	for effect: Dictionary in effects:
		var kind: String = String(effect.get("kind", ""))
		if kind == "damage":
			has_damage = true
		elif kind == "block":
			has_block = true
		elif kind == "poison" or kind == "weak" or kind == "vulnerable":
			has_status = true
	var badges: Array[String] = []
	if has_damage:
		badges.append("[攻擊]")
	if has_block:
		badges.append("[防守]")
	if has_status:
		badges.append("[異常]")
	if badges.is_empty():
		badges.append("[行動]")
	return " ".join(badges)

func _effective_card_cost(card: CardData) -> int:
	if selected_character.id == "li_xiaoyao" and card.card_type == "attack" and not bool(state.get("li_discount_used", false)):
		return max(0, card.cost - 1)
	return card.cost

func _apply_battle_start_passive() -> void:
	match selected_character.id:
		"zhao_linger":
			state["player_hp"] = min(selected_character.max_hp, int(state["player_hp"]) + 3)
			run_hp = int(state["player_hp"])
			_add_log("趙靈兒被動：戰鬥開始回復 3 點生命。")
		"anu":
			state["enemy_poison"] = int(state["enemy_poison"]) + 3
			_add_log("阿奴被動：敵人開場受到 3 層蠱毒。")

func _apply_card_play_passive(card: CardData) -> void:
	if selected_character.id != "lin_yueru":
		return
	if bool(state["lin_block_used"]):
		return
	for effect: Dictionary in card.effects:
		if String(effect.get("kind", "")) == "block":
			state["lin_block_used"] = true
			state["enemy_hp"] = max(0, int(state["enemy_hp"]) - 3)
			_add_log("林月如被動：回身反擊造成 3 點傷害。")
			return

func _passive_text() -> String:
	match selected_character.id:
		"li_xiaoyao":
			return "被動：每場戰鬥第一張攻擊牌費用 -1。"
		"zhao_linger":
			return "被動：每場戰鬥開始回復 3 點生命。"
		"lin_yueru":
			return "被動：每回合第一次獲得護體時，造成 3 點反擊傷害。"
		"anu":
			return "被動：敵人每場戰鬥開場受到 3 層蠱毒。"
	return ""

func _card_type_name(card_type: String) -> String:
	match card_type:
		"attack":
			return "攻擊"
		"skill":
			return "技能"
		"power":
			return "能力"
	return card_type

func _card_color(card_type: String, affordable: bool) -> Color:
	if not affordable:
		return Color("5f6673")
	match card_type:
		"attack":
			return Color("8f3f35")
		"skill":
			return Color("2f6f61")
		"power":
			return Color("7756a8")
	return Color("4f5f73")

func _style_card_button(button: Button, card: CardData, affordable: bool) -> void:
	var base_color: Color = _card_color(card.card_type, affordable)
	var normal: StyleBoxFlat = _style_box(base_color, Color("e7d38a"), 2, 8)
	var hover: StyleBoxFlat = _style_box(base_color.lightened(0.12), Color("f4e2a5"), 3, 8)
	var pressed: StyleBoxFlat = _style_box(base_color.darkened(0.12), Color("d2b96b"), 2, 8)
	var disabled: StyleBoxFlat = _style_box(Color("404753"), Color("7a8190"), 1, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	button.add_theme_color_override("font_disabled_color", Color("b8bec8"))
	button.add_theme_font_size_override("font_size", 15)

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _style_box(Color("273449"), Color("8ea3c4"), 1, 6))
	button.add_theme_stylebox_override("hover", _style_box(Color("33435c"), Color("c3d3ee"), 2, 6))
	button.add_theme_stylebox_override("pressed", _style_box(Color("1f2a3c"), Color("e4c66a"), 2, 6))
	button.add_theme_color_override("font_color", Color("edf2f7"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("f7e7a2"))

func _style_box(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = bg_color
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func _add_log(line: String) -> void:
	battle_log.append(line)
	if battle_log.size() > 40:
		battle_log.pop_front()

func _add_logs(lines: Array[String]) -> void:
	for line: String in lines:
		_add_log(line)

func _make_panel() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style_box(Color("18212f", 0.86), Color("536277"), 1, 8))
	panel.add_theme_constant_override("margin_left", 18)
	panel.add_theme_constant_override("margin_top", 18)
	panel.add_theme_constant_override("margin_right", 18)
	panel.add_theme_constant_override("margin_bottom", 18)
	return panel

func _title(text: String, size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f7df9c"))
	return label

func _paragraph(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("dbe4ef"))
	return label

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.add_theme_font_size_override("font_size", 18)
	_style_button(button)
	return button

func _portrait_rect(path: String, size: Vector2) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture: Texture2D = _load_texture(path)
	if texture != null:
		rect.texture = texture
	return rect

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _feedback_label() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(260, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("f7df9c"))
	label.modulate.a = 0.0
	return label
