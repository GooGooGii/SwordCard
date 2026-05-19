extends Control

var characters: Array[CharacterData] = []
var enemies: Array[EnemyData] = []
var selected_character: CharacterData
var selected_enemy: EnemyData
var deck: DeckManager
var resolver: EffectResolver
var state: Dictionary = {}
var action_index: int = 0
var root: MarginContainer
var hand_row: HBoxContainer
var log_label: RichTextLabel
var status_label: Label
var enemy_label: Label
var end_turn_button: Button
var card_buttons: Array[Button] = []
var battle_log: Array[String] = []

func _ready() -> void:
	randomize()
	characters = GameData.characters()
	enemies = GameData.enemies()
	_build_root()
	show_main_menu()

func _build_root() -> void:
	root = MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_top", 20)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

func _clear_root() -> void:
	for child: Node in root.get_children():
		child.queue_free()

func show_main_menu() -> void:
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
	_clear_root()
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	root.add_child(layout)
	layout.add_child(_title("選擇角色", 30))
	layout.add_child(_paragraph("第一版先做單場戰鬥。四名角色都有不同起始牌組與戰鬥節奏。"))
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
	box.add_child(_title(character.display_name, 24))
	box.add_child(_paragraph(character.battle_style))
	var card_names: Array[String] = []
	for card: CardData in character.starting_deck:
		card_names.append(card.display_name)
	var deck_text: String = "起始牌組：" + ", ".join(card_names)
	box.add_child(_paragraph(deck_text))
	var choose: Button = _button("以 %s 出戰" % character.display_name)
	choose.pressed.connect(func(): start_battle(character))
	box.add_child(choose)
	return panel

func start_battle(character: CharacterData) -> void:
	selected_character = character.clone()
	var picked_enemy: EnemyData = enemies.pick_random() as EnemyData
	selected_enemy = picked_enemy.clone()
	deck = DeckManager.new()
	resolver = EffectResolver.new()
	deck.setup(selected_character.starting_deck)
	action_index = 0
	battle_log.clear()
	state = {
		"player_name": selected_character.display_name,
		"player_max_hp": selected_character.max_hp,
		"player_hp": selected_character.max_hp,
		"player_block": 0,
		"player_poison": 0,
		"player_weak": 0,
		"player_power": 0,
		"enemy_name": selected_enemy.display_name,
		"enemy_max_hp": selected_enemy.max_hp,
		"enemy_hp": selected_enemy.max_hp,
		"enemy_block": 0,
		"enemy_poison": 0,
		"enemy_weak": 0,
		"enemy_vulnerable": 0,
		"energy": 3,
		"pending_draw": 0,
		"turn": 0
	}
	_build_battle_scene()
	_start_player_turn()

func _build_battle_scene() -> void:
	_clear_root()
	var screen: VBoxContainer = VBoxContainer.new()
	screen.add_theme_constant_override("separation", 12)
	root.add_child(screen)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 20)
	screen.add_child(status_label)
	var middle: HBoxContainer = HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	screen.add_child(middle)
	var player_panel: PanelContainer = _make_panel()
	player_panel.custom_minimum_size = Vector2(380, 220)
	var player_box: VBoxContainer = VBoxContainer.new()
	player_panel.add_child(player_box)
	player_box.add_child(_title(selected_character.display_name, 28))
	player_box.add_child(_paragraph(selected_character.battle_style))
	player_box.add_child(_paragraph("卡牌以點擊施放。靈力不足時不可出牌。"))
	middle.add_child(player_panel)
	var enemy_panel: PanelContainer = _make_panel()
	enemy_panel.custom_minimum_size = Vector2(380, 220)
	var enemy_box: VBoxContainer = VBoxContainer.new()
	enemy_panel.add_child(enemy_box)
	enemy_label = Label.new()
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_label.add_theme_font_size_override("font_size", 22)
	enemy_box.add_child(enemy_label)
	middle.add_child(enemy_panel)
	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(360, 220)
	log_label.fit_content = true
	middle.add_child(log_label)
	hand_row = HBoxContainer.new()
	hand_row.add_theme_constant_override("separation", 10)
	screen.add_child(hand_row)
	end_turn_button = _button("結束回合")
	end_turn_button.pressed.connect(end_player_turn)
	screen.add_child(end_turn_button)

func _start_player_turn() -> void:
	state["turn"] = int(state["turn"]) + 1
	state["energy"] = 3
	state["player_block"] = 0
	state["enemy_block"] = 0
	state["pending_draw"] = 0
	if int(state["enemy_vulnerable"]) > 0:
		state["enemy_vulnerable"] = int(state["enemy_vulnerable"]) - 1
	if int(state["enemy_weak"]) > 0:
		state["enemy_weak"] = int(state["enemy_weak"]) - 1
	_add_logs(resolver.tick_statuses(state))
	if _check_battle_end():
		return
	deck.draw(5)
	_add_log("第 %d 回合開始，抽 5 張牌。" % state["turn"])
	_refresh_battle()

func play_card(card: CardData) -> void:
	if int(state["energy"]) < card.cost:
		_add_log("靈力不足，無法施放 %s。" % card.display_name)
		_refresh_battle()
		return
	state["energy"] = int(state["energy"]) - card.cost
	_add_log("施放 %s。" % card.display_name)
	_add_logs(resolver.resolve_card(card, state))
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
	_add_logs(resolver.resolve_enemy_action(action, state))
	if _check_battle_end():
		return
	_start_player_turn()

func _check_battle_end() -> bool:
	if int(state["enemy_hp"]) <= 0:
		show_result(true)
		return true
	if int(state["player_hp"]) <= 0:
		show_result(false)
		return true
	return false

func show_result(victory: bool) -> void:
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	if victory:
		box.add_child(_title("戰鬥勝利", 34))
		box.add_child(_paragraph("%s 擊敗了 %s。" % [selected_character.display_name, selected_enemy.display_name]))
	else:
		box.add_child(_title("戰鬥失敗", 34))
		box.add_child(_paragraph("%s 敗於 %s。調整出牌節奏再試一次。" % [selected_character.display_name, selected_enemy.display_name]))
	var retry: Button = _button("再戰一次")
	retry.pressed.connect(func(): start_battle(selected_character))
	box.add_child(retry)
	var select: Button = _button("重新選擇角色")
	select.pressed.connect(show_character_select)
	box.add_child(select)
	var menu: Button = _button("返回主選單")
	menu.pressed.connect(show_main_menu)
	box.add_child(menu)

func _refresh_battle() -> void:
	status_label.text = "%s  HP %d/%d  護體 %d  靈力 %d/3  抽牌 %d  棄牌 %d  蠱毒 %d" % [
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
	enemy_label.text = "%s\nHP %d/%d  護體 %d\n蠱毒 %d  虛弱 %d  破綻 %d\n意圖：%s" % [
		state["enemy_name"],
		state["enemy_hp"],
		state["enemy_max_hp"],
		state["enemy_block"],
		state["enemy_poison"],
		state["enemy_weak"],
		state["enemy_vulnerable"],
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
	button.custom_minimum_size = Vector2(148, 170)
	button.text = "%s\n費用 %d\n%s" % [card.display_name, card.cost, card.description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = int(state["energy"]) < card.cost
	button.pressed.connect(func(): play_card(card))
	return button

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
	return label

func _paragraph(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	return label

func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 46)
	button.add_theme_font_size_override("font_size", 18)
	return button
