extends Control

var characters: Array[CharacterData] = []
var enemies: Array[EnemyData] = []
var selected_character: CharacterData
var selected_enemy: EnemyData
var run_deck: Array[CardData] = []
var run_hp: int = 0
var run_gold: int = 0
var run_power_bonus: int = 0
var current_shop_cards: Array[CardData] = []
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

# ── Equipment state ──────────────────────────
var all_equipment: Array[EquipmentData] = []
var all_char_weapons: Array[EquipmentData] = []
var all_artifacts: Array[EquipmentData] = []
# 4 slots: weapon / armor / accessory_1 / accessory_2
var run_equipped: Dictionary = {"weapon": null, "armor": null, "accessory_1": null, "accessory_2": null}
var run_bag: Array[EquipmentData] = []
var unlocked_artifact_ids: Array[String] = []
var current_shop_equipment: Array[EquipmentData] = []
var fighting_artifact_boss: bool = false

func _ready() -> void:
	randomize()
	characters = GameData.characters()
	all_equipment = GameData.all_equipment()
	all_char_weapons = GameData.character_weapons()
	all_artifacts = GameData.artifacts()
	_load_unlocks()
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
	if _has_save():
		var continue_button: Button = _button("繼續遊戲")
		continue_button.pressed.connect(_continue_run)
		box.add_child(continue_button)
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
	run_gold = 0
	run_power_bonus = 0
	current_shop_cards.clear()
	current_shop_equipment.clear()
	run_bag.clear()
	fighting_artifact_boss = false
	# Reset slots — keep weapon only if player pre-selected an artifact before starting
	run_equipped = {"weapon": run_equipped.get("weapon"), "armor": null, "accessory_1": null, "accessory_2": null}
	# Apply passive max_hp from pre-equipped artifact (if any)
	_apply_passive_max_hp()
	run_hp = selected_character.max_hp
	encounter_index = 0
	encounter_choices = _make_encounter_choices()
	if unlocked_artifact_ids.is_empty():
		show_progress_screen()
	else:
		show_artifact_selection_screen()

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
			row.append({"type": "shop"})
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
	_save_run()
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
	box.add_child(_paragraph("%s  HP %d/%d  金幣 %d  牌組 %d 張  增傷 +%d" % [selected_character.display_name, run_hp, selected_character.max_hp, run_gold, run_deck.size(), run_power_bonus]))
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
	var equip_button: Button = _button("裝備管理（%s）" % _equipped_summary())
	equip_button.pressed.connect(show_equipment_overlay)
	box.add_child(equip_button)
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
		"player_block_bonus": 0,
		"global_cost_reduction": 0,
		"skill_cost_reduction": 0,
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
	_apply_equipment_battle_start()
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
	_apply_equipment_turn_start()
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
	run_gold += 20 + randi() % 11
	_apply_equipment_victory()
	if fighting_artifact_boss:
		fighting_artifact_boss = false
		show_artifact_unlock_screen()
		return
	encounter_index = encounter_index + 1
	if selected_enemy.id == "moon_worshipper":
		show_artifact_boss_prompt()
		return
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
	box.add_child(_paragraph("目前 HP %d/%d，金幣 %d，牌組 %d 張。" % [run_hp, selected_character.max_hp, run_gold, run_deck.size()]))
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
	# Equipment alternative reward (33% chance, skip if no pool available)
	var equip_pool: Array[EquipmentData] = _random_equipment_pool(1)
	if not equip_pool.is_empty():
		var equip_alt_button: Button = _button("改為獲得裝備：%s（%s）" % [equip_pool[0].display_name, equip_pool[0].rarity_display()])
		equip_alt_button.pressed.connect(func(): _gain_equipment_and_advance(equip_pool[0]))
		box.add_child(equip_alt_button)
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
	if node_type == "shop":
		return _route_shop_button()
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

func _route_shop_button() -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(260, 160)
	button.text = "商店\n江湖商人\n購買卡牌與道具"
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _style_box(Color("5c4a20"), Color("d4a844"), 2, 8))
	button.add_theme_stylebox_override("hover", _style_box(Color("7a6228"), Color("f5c84a"), 3, 8))
	button.add_theme_stylebox_override("pressed", _style_box(Color("3f3318"), Color("c49830"), 2, 8))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.pressed.connect(func():
		current_shop_cards = _generate_shop_cards()
		current_shop_equipment = _generate_shop_equipment()
		show_shop_node()
	)
	return button

func _generate_shop_cards() -> Array[CardData]:
	var pool: Array[CardData] = []
	for card: CardData in selected_character.reward_pool:
		pool.append(card.clone())
	pool.shuffle()
	var result: Array[CardData] = []
	for i: int in range(min(3, pool.size())):
		result.append(pool[i])
	return result

func _generate_shop_equipment() -> Array[EquipmentData]:
	var pool: Array[EquipmentData] = []
	for equip: EquipmentData in all_equipment:
		if not _is_equipment_owned(equip.id):
			pool.append(equip.clone())
	for equip: EquipmentData in all_char_weapons:
		if equip.owner == selected_character.id and not _is_equipment_owned(equip.id):
			pool.append(equip.clone())
	pool.shuffle()
	var result: Array[EquipmentData] = []
	for i: int in range(min(3, pool.size())):
		result.append(pool[i])
	return result

func _is_equipment_owned(id: String) -> bool:
	for slot: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
		var e: EquipmentData = run_equipped[slot] as EquipmentData
		if e != null and e.id == id:
			return true
	for e: EquipmentData in run_bag:
		if e.id == id:
			return true
	return false

func _card_shop_price(card: CardData) -> int:
	match card.rarity:
		"uncommon": return 75
		"rare": return 100
	return 50

func show_shop_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("江湖商人", 34))
	box.add_child(_paragraph("一位行商在路邊擺開攤子，兜售各式奇術秘法。"))
	box.add_child(_paragraph("%s  HP %d/%d  金幣 %d  牌組 %d 張" % [selected_character.display_name, run_hp, selected_character.max_hp, run_gold, run_deck.size()]))
	box.add_child(_title("卡牌", 22))
	var card_row: HBoxContainer = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 12)
	box.add_child(card_row)
	if current_shop_cards.is_empty():
		card_row.add_child(_paragraph("（已售罄）"))
	else:
		for card: CardData in current_shop_cards:
			var price: int = _card_shop_price(card)
			card_row.add_child(_shop_card_button(card, price))
	box.add_child(_title("裝備", 22))
	var equip_row: HBoxContainer = HBoxContainer.new()
	equip_row.add_theme_constant_override("separation", 12)
	box.add_child(equip_row)
	if current_shop_equipment.is_empty():
		equip_row.add_child(_paragraph("（已售罄）"))
	else:
		for equip: EquipmentData in current_shop_equipment:
			equip_row.add_child(_shop_equip_button(equip))
	box.add_child(_title("道具", 22))
	var heal_price: int = 40
	var heal_button: Button = _button("調息：回復 20 HP（%d 金）" % heal_price)
	heal_button.disabled = run_gold < heal_price or run_hp >= selected_character.max_hp
	heal_button.pressed.connect(func(): buy_heal_from_shop(20, heal_price))
	box.add_child(heal_button)
	var remove_price: int = 90
	var remove_button: Button = _button("洗髓：移除 1 張牌（%d 金）" % remove_price)
	remove_button.disabled = run_gold < remove_price or run_deck.size() <= 5
	remove_button.pressed.connect(_open_shop_remove_view)
	box.add_child(remove_button)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)
	var equip_manage_button: Button = _button("裝備管理（%s）" % _equipped_summary())
	equip_manage_button.pressed.connect(show_equipment_overlay)
	box.add_child(equip_manage_button)
	var leave_button: Button = _button("離開商店")
	leave_button.pressed.connect(advance_non_battle_node)
	box.add_child(leave_button)

func _shop_card_button(card: CardData, price: int) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 210)
	var affordable: bool = run_gold >= price
	button.text = "%s\n%s  費用 %d\n售價 %d 金\n\n%s" % [card.display_title(), _card_type_name(card.card_type), card.cost, price, card.display_description()]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not affordable
	_style_card_button(button, card, affordable)
	if affordable:
		button.pressed.connect(func(): buy_card_from_shop(card, price))
	return button

func buy_card_from_shop(card: CardData, price: int) -> void:
	if run_gold < price:
		return
	run_gold -= price
	run_deck.append(card.clone())
	for i: int in range(current_shop_cards.size()):
		if current_shop_cards[i] == card:
			current_shop_cards.remove_at(i)
			break
	show_shop_node()

func buy_heal_from_shop(amount: int, price: int) -> void:
	if run_gold < price:
		return
	run_gold -= price
	run_hp = min(selected_character.max_hp, run_hp + amount)
	show_shop_node()

func _open_shop_remove_view() -> void:
	if run_deck.size() <= 5:
		return
	show_deck_view("shop_remove")

func remove_card_from_shop_deck(card: CardData) -> void:
	var price: int = 90
	if run_gold < price or run_deck.size() <= 5:
		close_deck_view()
		return
	run_gold -= price
	for i: int in range(run_deck.size()):
		if run_deck[i] == card:
			run_deck.remove_at(i)
			break
	close_deck_view()
	show_shop_node()

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
	var bonus: int = _equipment_rest_heal_bonus()
	run_hp = min(selected_character.max_hp, run_hp + pending_rest_heal + bonus)
	pending_rest_heal = 0
	advance_non_battle_node()

func show_event_node() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var events: Array = _get_event_definitions()
	var event: Dictionary = events[randi() % events.size()]
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title(String(event["title"]), 34))
	box.add_child(_paragraph(String(event["description"])))
	box.add_child(_paragraph("%s  HP %d/%d  金幣 %d  增傷 +%d" % [selected_character.display_name, run_hp, selected_character.max_hp, run_gold, run_power_bonus]))
	for choice_v: Variant in event["choices"]:
		var choice: Dictionary = choice_v as Dictionary
		var condition: String = String(choice.get("condition", ""))
		var available: bool = _check_event_condition(condition)
		var btn: Button = _button(String(choice["label"]))
		btn.disabled = not available
		if not available and condition != "":
			btn.text = "%s（%s）" % [String(choice["label"]), _event_condition_hint(condition)]
		btn.pressed.connect(func(): _resolve_event_choice(choice["effects"] as Array))
		box.add_child(btn)
	var deck_button: Button = _button("查看牌組")
	deck_button.pressed.connect(show_deck_view)
	box.add_child(deck_button)

func _check_event_condition(condition: String) -> bool:
	if condition == "":
		return true
	if condition == "upgradeable":
		return not _upgradeable_cards().is_empty()
	if condition.begins_with("deck_min:"):
		return run_deck.size() >= int(condition.split(":")[1])
	if condition.begins_with("gold_min:"):
		return run_gold >= int(condition.split(":")[1])
	return true

func _event_condition_hint(condition: String) -> String:
	if condition == "upgradeable":
		return "牌組內無可升級的牌"
	if condition.begins_with("deck_min:"):
		return "牌組張數不足"
	if condition.begins_with("gold_min:"):
		return "需要 %d 金幣" % int(condition.split(":")[1])
	return ""

func _resolve_event_choice(effects: Array) -> void:
	var interactive: String = ""
	for eff_v: Variant in effects:
		var eff: Dictionary = eff_v as Dictionary
		var kind: String  = String(eff.get("kind", ""))
		var amount: int   = int(eff.get("amount", 0))
		match kind:
			"heal":      run_hp = min(selected_character.max_hp, run_hp + amount)
			"damage":    run_hp = max(1, run_hp - amount)
			"gold":      run_gold += amount
			"power":     run_power_bonus += amount
			"full_heal": run_hp = selected_character.max_hp
			"gain_card":
				var pool: Array[CardData] = _make_reward_choices()
				if not pool.is_empty():
					run_deck.append(pool[0].clone())
			"gain_equipment":
				var eq_pool: Array[EquipmentData] = _random_equipment_pool(1)
				if not eq_pool.is_empty():
					_gain_equipment(eq_pool[0])
			"upgrade_card", "remove_card":
				interactive = kind
	if interactive == "upgrade_card":
		show_upgrade_card_view()
	elif interactive == "remove_card":
		show_remove_card_view()
	else:
		advance_non_battle_node()

func _get_event_definitions() -> Array:
	return [
		{
			"title": "山路異光",
			"description": "石壁間浮現微光，像是前人留下的靈痕。山風輕拂，隱隱有古老靈韻流動，令人心生嚮往。",
			"choices": [
				{"label": "調息：回復 8 HP",                             "condition": "",            "effects": [{"kind":"heal","amount":8}]},
				{"label": "探取靈痕：失去 6 HP，獲得 1 張招式",           "condition": "",            "effects": [{"kind":"damage","amount":6},{"kind":"gain_card"}]},
				{"label": "凝神：本輪增傷 +1",                           "condition": "",            "effects": [{"kind":"power","amount":1}]},
				{"label": "悟法：升級 1 張牌",                           "condition": "upgradeable", "effects": [{"kind":"upgrade_card"}]},
				{"label": "洗髓：移除 1 張牌",                           "condition": "deck_min:6",  "effects": [{"kind":"remove_card"}]},
				{"label": "探索洞窟：獲得 1 件裝備",                      "condition": "",            "effects": [{"kind":"gain_equipment"}]},
			]
		},
		{
			"title": "古井靈泉",
			"description": "荒廢的村落邊，一口古井散發淡淡靈氣。水面倒映星光，清澈見底，卻令人難以揣測深處藏著什麼。",
			"choices": [
				{"label": "謹慎飲用：回復 15 HP",                        "condition": "",            "effects": [{"kind":"heal","amount":15}]},
				{"label": "縱情暢飲：失去 8 HP，回復 28 HP",              "condition": "",            "effects": [{"kind":"damage","amount":8},{"kind":"heal","amount":28}]},
				{"label": "取水售出：獲得 25 金幣",                       "condition": "",            "effects": [{"kind":"gold","amount":25}]},
				{"label": "離去",                                         "condition": "",            "effects": [{"kind":"nothing"}]},
			]
		},
		{
			"title": "落魄劍客",
			"description": "山道旁倒著一名渾身是傷的劍客，氣息奄奄。他掙扎著說：「此地不可久留⋯⋯山賊就在後頭⋯⋯」",
			"choices": [
				{"label": "出手相救：失去 12 HP，獲得 1 件裝備",          "condition": "",            "effects": [{"kind":"damage","amount":12},{"kind":"gain_equipment"}]},
				{"label": "傳授武學：升級 1 張牌",                        "condition": "upgradeable", "effects": [{"kind":"upgrade_card"}]},
				{"label": "搜其行囊：獲得 35 金幣，失去 8 HP",            "condition": "",            "effects": [{"kind":"gold","amount":35},{"kind":"damage","amount":8}]},
				{"label": "繼續趕路",                                     "condition": "",            "effects": [{"kind":"nothing"}]},
			]
		},
		{
			"title": "荒廟神像",
			"description": "深山廢廟，一尊面目模糊的神像端坐蓮台。香案積滿灰塵，神像底座有一道細縫，隱隱透出微光。",
			"choices": [
				{"label": "虔誠祭拜：回復 20 HP",                        "condition": "",            "effects": [{"kind":"heal","amount":20}]},
				{"label": "探入裂縫：獲得 1 件裝備",                      "condition": "",            "effects": [{"kind":"gain_equipment"}]},
				{"label": "奉上香火（30 金）：本輪增傷 +2",               "condition": "gold_min:30", "effects": [{"kind":"gold","amount":-30},{"kind":"power","amount":2}]},
				{"label": "推開神像：移除 1 張牌",                        "condition": "deck_min:6",  "effects": [{"kind":"remove_card"}]},
			]
		},
		{
			"title": "蠱師遺跡",
			"description": "被廢棄的山洞，四壁刻滿奇異蠱紋，地上散落著殘破蠱器與枯骨。空氣中瀰漫著古舊的腐朽氣息。",
			"choices": [
				{"label": "研習蠱紋：升級 1 張牌",                        "condition": "upgradeable", "effects": [{"kind":"upgrade_card"}]},
				{"label": "收集殘器：獲得 1 件裝備",                      "condition": "",            "effects": [{"kind":"gain_equipment"}]},
				{"label": "祭煉蠱術：失去 10 HP，獲得 1 張招式",          "condition": "",            "effects": [{"kind":"damage","amount":10},{"kind":"gain_card"}]},
				{"label": "立刻撤離",                                     "condition": "",            "effects": [{"kind":"nothing"}]},
			]
		},
		{
			"title": "靈氣秘地",
			"description": "深山中一塊天然靈氣匯聚之地，五行元素渾然天成，草木蔥鬱，靈石遍地，令人心曠神怡。",
			"choices": [
				{"label": "靜心調息：回復 20 HP，本輪增傷 +1",            "condition": "",            "effects": [{"kind":"heal","amount":20},{"kind":"power","amount":1}]},
				{"label": "突破修為：失去 15 HP，升級 1 張牌",            "condition": "upgradeable", "effects": [{"kind":"damage","amount":15},{"kind":"upgrade_card"}]},
				{"label": "廣納靈氣：回復至滿血",                         "condition": "",            "effects": [{"kind":"full_heal"}]},
				{"label": "感悟劍道：獲得 1 張招式",                      "condition": "",            "effects": [{"kind":"gain_card"}]},
			]
		},
		{
			"title": "神秘商隊",
			"description": "山路上遇到一支打扮奇異的小商隊，為首的白髮老者笑容深邃，兜售著來歷不明的奇物。",
			"choices": [
				{"label": "以血換法器：失去 18 HP，獲得 1 件裝備",        "condition": "",            "effects": [{"kind":"damage","amount":18},{"kind":"gain_equipment"}]},
				{"label": "以金易寶（60 金）：獲得 1 件裝備",             "condition": "gold_min:60", "effects": [{"kind":"gold","amount":-60},{"kind":"gain_equipment"}]},
				{"label": "以技換知：升級 1 張牌",                        "condition": "upgradeable", "effects": [{"kind":"upgrade_card"}]},
				{"label": "告辭離去",                                     "condition": "",            "effects": [{"kind":"nothing"}]},
			]
		},
	]

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
	elif deck_view_mode == "shop_remove":
		title_text = "洗髓：選擇要移除的牌（90 金）"
	box.add_child(_title(title_text, 32))
	box.add_child(_paragraph("%s  HP %d/%d  共 %d 張牌" % [selected_character.display_name, run_hp, selected_character.max_hp, run_deck.size()]))
	var summary: Label = _paragraph(_deck_summary_text())
	box.add_child(summary)
	if deck_view_mode == "remove":
		box.add_child(_paragraph("至少保留 5 張牌。點選一張牌後會移除並完成事件。"))
	elif deck_view_mode == "upgrade":
		box.add_child(_paragraph("點選一張未升級的牌，升級後會完成此節點。"))
	elif deck_view_mode == "shop_remove":
		box.add_child(_paragraph("花費 90 金移除 1 張牌。至少保留 5 張。移除後返回商店。"))
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
	var selectable: bool = mode == "remove" or (mode == "upgrade" and not card.upgraded) or mode == "shop_remove"
	button.disabled = not selectable
	_style_card_button(button, card, true)
	if mode == "remove":
		button.pressed.connect(func(): remove_card_from_run_deck(card))
	elif mode == "upgrade" and not card.upgraded:
		button.pressed.connect(func(): upgrade_card_in_run_deck(card))
	elif mode == "shop_remove":
		button.pressed.connect(func(): remove_card_from_shop_deck(card))
	else:
		button.add_theme_stylebox_override("disabled", _style_box(_card_color(card.card_type, true), Color("e7d38a"), 2, 8))
		button.add_theme_color_override("font_disabled_color", Color("fff8dc"))
	return button

func show_result(victory: bool) -> void:
	_clear_save()
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
		box.add_child(_paragraph("%s 完成了 %d 層路線，最終 HP %d/%d，剩餘金幣 %d。" % [selected_character.display_name, encounter_choices.size(), run_hp, selected_character.max_hp, run_gold]))
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
	var cost: int = card.cost
	if selected_character.id == "li_xiaoyao" and card.card_type == "attack" and not bool(state.get("li_discount_used", false)):
		cost = max(0, cost - 1)
	cost = max(0, cost - int(state.get("global_cost_reduction", 0)))
	if card.card_type == "skill":
		cost = max(0, cost - int(state.get("skill_cost_reduction", 0)))
	return cost

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

# ══════════════════════════════════════════════════
#  EQUIPMENT SYSTEM
# ══════════════════════════════════════════════════

func _get_all_equipped() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	for slot: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
		var e: Variant = run_equipped.get(slot)
		if e != null:
			result.append(e as EquipmentData)
	return result

func _apply_passive_max_hp() -> void:
	for equip: EquipmentData in _get_all_equipped():
		for eff: Dictionary in equip.effects:
			if String(eff.get("trigger","")) == "passive" and String(eff.get("kind","")) == "max_hp":
				selected_character.max_hp += int(eff["amount"])

func _apply_equipment_battle_start() -> void:
	for equip: EquipmentData in _get_all_equipped():
		for eff: Dictionary in equip.effects:
			var trigger: String = String(eff.get("trigger",""))
			var kind: String   = String(eff.get("kind",""))
			var amount: int    = int(eff.get("amount", 0))
			if trigger == "passive":
				match kind:
					"attack":       state["player_power"]        = int(state["player_power"]) + amount
					"block_bonus":  state["player_block_bonus"]  = int(state.get("player_block_bonus",0)) + amount
					"cost_all":     state["global_cost_reduction"]= int(state.get("global_cost_reduction",0)) + amount
					"skill_cost":   state["skill_cost_reduction"] = int(state.get("skill_cost_reduction",0)) + amount
			elif trigger == "battle_start":
				match kind:
					"block":        state["player_block"] = int(state["player_block"]) + amount
					"heal":         state["player_hp"]    = min(int(state["player_max_hp"]), int(state["player_hp"]) + amount)
					"energy":       state["energy"]       = int(state["energy"]) + amount
					"draw":         state["pending_draw"] = int(state.get("pending_draw",0)) + amount
					"poison_enemy": state["enemy_poison"] = int(state["enemy_poison"]) + amount

func _apply_equipment_turn_start() -> void:
	for equip: EquipmentData in _get_all_equipped():
		for eff: Dictionary in equip.effects:
			if String(eff.get("trigger","")) != "turn_start":
				continue
			var kind: String  = String(eff.get("kind",""))
			var amount: int   = int(eff.get("amount", 0))
			match kind:
				"block":   state["player_block"] = int(state["player_block"]) + amount
				"heal":    state["player_hp"]    = min(int(state["player_max_hp"]), int(state["player_hp"]) + amount)
				"energy":  state["energy"]       = int(state["energy"]) + amount
				"draw":    state["pending_draw"] = int(state.get("pending_draw",0)) + amount

func _apply_equipment_victory() -> void:
	for equip: EquipmentData in _get_all_equipped():
		for eff: Dictionary in equip.effects:
			if String(eff.get("trigger","")) != "on_victory":
				continue
			var kind: String  = String(eff.get("kind",""))
			var amount: int   = int(eff.get("amount", 0))
			match kind:
				"heal": run_hp = min(selected_character.max_hp, run_hp + amount)
				"gold": run_gold += amount

func _equipment_rest_heal_bonus() -> int:
	var bonus: int = 0
	for equip: EquipmentData in _get_all_equipped():
		for eff: Dictionary in equip.effects:
			if String(eff.get("trigger","")) == "rest" and String(eff.get("kind","")) == "heal_bonus":
				bonus += int(eff.get("amount", 0))
	return bonus

func _equipped_summary() -> String:
	var parts: Array[String] = []
	for slot: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
		var e: Variant = run_equipped.get(slot)
		if e != null:
			parts.append((e as EquipmentData).display_name)
	if parts.is_empty():
		return "無"
	return ", ".join(parts)

func _equip_item(equip: EquipmentData) -> void:
	var slot: String = equip.slot
	if slot == "accessory":
		if run_equipped["accessory_1"] == null:
			slot = "accessory_1"
		elif run_equipped["accessory_2"] == null:
			slot = "accessory_2"
		else:
			slot = "accessory_1"
	var current: Variant = run_equipped.get(slot)
	if current != null:
		run_bag.append(current as EquipmentData)
	run_equipped[slot] = equip
	if equip.slot == "accessory" and slot == "accessory_1":
		pass  # already set above

func _gain_equipment(equip: EquipmentData) -> void:
	# Auto-equip if slot is empty, else bag it
	var slot: String = equip.slot
	var target_slot: String = slot
	if slot == "accessory":
		if run_equipped["accessory_1"] == null:
			target_slot = "accessory_1"
		elif run_equipped["accessory_2"] == null:
			target_slot = "accessory_2"
		else:
			target_slot = ""  # both full → bag
	if target_slot != "" and run_equipped.get(target_slot) == null:
		run_equipped[target_slot] = equip.clone()
	else:
		run_bag.append(equip.clone())

func _random_equipment_pool(count: int) -> Array[EquipmentData]:
	var pool: Array[EquipmentData] = []
	for equip: EquipmentData in all_equipment:
		if not _is_equipment_owned(equip.id):
			pool.append(equip.clone())
	for equip: EquipmentData in all_char_weapons:
		if equip.owner == selected_character.id and not _is_equipment_owned(equip.id):
			pool.append(equip.clone())
	pool.shuffle()
	var result: Array[EquipmentData] = []
	for i: int in range(min(count, pool.size())):
		result.append(pool[i])
	return result

func _gain_equipment_and_advance(equip: EquipmentData) -> void:
	_gain_equipment(equip)
	show_progress_screen()

func buy_equipment_from_shop(equip: EquipmentData) -> void:
	if run_gold < equip.price:
		return
	run_gold -= equip.price
	_gain_equipment(equip)
	for i: int in range(current_shop_equipment.size()):
		if current_shop_equipment[i] == equip:
			current_shop_equipment.remove_at(i)
			break
	show_shop_node()

func _shop_equip_button(equip: EquipmentData) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 210)
	var affordable: bool = run_gold >= equip.price
	button.text = "%s\n%s %s\n售價 %d 金\n\n%s" % [equip.display_name, equip.slot_display(), equip.rarity_display(), equip.price, equip.description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not affordable
	var base_color: Color = Color("5c4a20") if affordable else Color("404753")
	var normal: StyleBoxFlat = _style_box(base_color, Color("d4a844"), 2, 8)
	var hover: StyleBoxFlat  = _style_box(base_color.lightened(0.12), Color("f5c84a"), 3, 8)
	var dis: StyleBoxFlat    = _style_box(Color("404753"), Color("7a8190"), 1, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("disabled", dis)
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("b8bec8"))
	button.add_theme_font_size_override("font_size", 14)
	if affordable:
		button.pressed.connect(func(): buy_equipment_from_shop(equip))
	return button

# ── Equipment Overlay ──────────────────────

func show_equipment_overlay() -> void:
	close_deck_view()
	deck_overlay = PanelContainer.new()
	deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_overlay.add_theme_stylebox_override("panel", _style_box(Color("0b111a", 0.94), Color("d4a844"), 2, 8))
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
	box.add_child(_title("裝備管理", 32))
	box.add_child(_paragraph("點選倉庫裝備可替換對應槽位。武器槽：專武/神器；防具槽：防具；飾品槽：飾品（共兩格）。"))
	# Slot display
	var slots_row: HBoxContainer = HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 10)
	box.add_child(slots_row)
	for slot_label: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
		slots_row.add_child(_equip_slot_widget(slot_label))
	# Bag
	if not run_bag.is_empty():
		box.add_child(_title("倉庫", 22))
		var bag_row: HBoxContainer = HBoxContainer.new()
		bag_row.add_theme_constant_override("separation", 10)
		box.add_child(bag_row)
		for equip: EquipmentData in run_bag:
			bag_row.add_child(_bag_equip_button(equip))
	var close_button: Button = _button("關閉")
	close_button.pressed.connect(close_deck_view)
	box.add_child(close_button)

func _slot_display_name(slot: String) -> String:
	match slot:
		"weapon": return "武器"
		"armor":  return "防具"
		"accessory_1": return "飾品①"
		"accessory_2": return "飾品②"
	return slot

func _equip_slot_widget(slot: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 160)
	panel.add_theme_stylebox_override("panel", _style_box(Color("1e2d1e"), Color("8ea88e"), 1, 6))
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.add_child(_paragraph(_slot_display_name(slot)))
	var equip: Variant = run_equipped.get(slot)
	if equip != null:
		var e: EquipmentData = equip as EquipmentData
		var lbl: Label = _paragraph("%s\n%s\n%s" % [e.display_name, e.rarity_display(), e.description])
		lbl.add_theme_font_size_override("font_size", 13)
		vbox.add_child(lbl)
		var unequip_btn: Button = _button("卸下")
		unequip_btn.custom_minimum_size = Vector2(80, 32)
		unequip_btn.add_theme_font_size_override("font_size", 14)
		unequip_btn.pressed.connect(func(): _unequip_slot(slot))
		vbox.add_child(unequip_btn)
	else:
		vbox.add_child(_paragraph("（空）"))
	return panel

func _bag_equip_button(equip: EquipmentData) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(200, 160)
	button.text = "%s\n%s %s\n\n%s" % [equip.display_name, equip.slot_display(), equip.rarity_display(), equip.description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_stylebox_override("normal", _style_box(Color("2a2a1a"), Color("d4a844"), 2, 6))
	button.add_theme_stylebox_override("hover",  _style_box(Color("3d3b20"), Color("f5c84a"), 3, 6))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(func(): _equip_from_bag(equip))
	return button

func _unequip_slot(slot: String) -> void:
	var e: Variant = run_equipped.get(slot)
	if e != null:
		run_bag.append(e as EquipmentData)
		run_equipped[slot] = null
	show_equipment_overlay()

func _equip_from_bag(equip: EquipmentData) -> void:
	for i: int in range(run_bag.size()):
		if run_bag[i] == equip:
			run_bag.remove_at(i)
			break
	_equip_item(equip)
	show_equipment_overlay()

# ── Artifact Boss & Unlock ──────────────────

func show_artifact_boss_prompt() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("神器傳說", 34))
	box.add_child(_paragraph("擊退拜月教徒之際，洞壁金光乍現，隱約有一道古老威壓滲出。\n傳說天地初開時，神器守護靈就深眠於此。"))
	box.add_child(_paragraph("HP %d/%d  金幣 %d" % [run_hp, selected_character.max_hp, run_gold]))
	var challenge_button: Button = _button("挑戰上古守護靈")
	challenge_button.add_theme_stylebox_override("normal", _style_box(Color("452a10"), Color("f0c060"), 2, 8))
	challenge_button.add_theme_color_override("font_color", Color("fff8dc"))
	challenge_button.pressed.connect(_start_artifact_boss_fight)
	box.add_child(challenge_button)
	var skip_button: Button = _button("離開，完成冒險")
	skip_button.pressed.connect(func(): show_result(true))
	box.add_child(skip_button)

func _start_artifact_boss_fight() -> void:
	fighting_artifact_boss = true
	var boss: EnemyData = GameData._artifact_boss()
	start_next_battle(boss)

func show_artifact_unlock_screen() -> void:
	_set_background("res://assets/art/event_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("神器現世", 34))
	box.add_child(_paragraph("守護靈消散，留下五件神器的餘韻。選擇一件永久解鎖，此後每次冒險開局皆可攜帶。"))
	var artifact_row: HBoxContainer = HBoxContainer.new()
	artifact_row.add_theme_constant_override("separation", 12)
	box.add_child(artifact_row)
	for artifact: EquipmentData in all_artifacts:
		artifact_row.add_child(_artifact_unlock_button(artifact))
	var skip_button: Button = _button("放棄，不解鎖神器")
	skip_button.pressed.connect(func(): show_result(true))
	box.add_child(skip_button)

func _artifact_unlock_button(artifact: EquipmentData) -> Button:
	var already: bool = unlocked_artifact_ids.has(artifact.id)
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 230)
	button.text = "%s\n%s\n%s\n\n%s" % [artifact.display_name, artifact.rarity_display(), "（已解鎖）" if already else "（未解鎖）", artifact.description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_stylebox_override("normal", _style_box(Color("3a2a60"), Color("d0a0ff"), 2, 8))
	button.add_theme_stylebox_override("hover",  _style_box(Color("5040a0"), Color("e8c8ff"), 3, 8))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(func(): _unlock_artifact(artifact))
	return button

func _unlock_artifact(artifact: EquipmentData) -> void:
	if not unlocked_artifact_ids.has(artifact.id):
		unlocked_artifact_ids.append(artifact.id)
		_save_unlocks()
	run_equipped["weapon"] = artifact.clone()
	show_result(true)

# ── Pre-run artifact selection ──────────────

func show_artifact_selection_screen() -> void:
	_set_background("res://assets/art/main_menu_bg.png")
	_clear_root()
	var panel: PanelContainer = _make_panel()
	root.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_title("選擇神器（可選）", 32))
	box.add_child(_paragraph("你已解鎖以下神器，可在武器槽裝備一件帶入本次冒險。"))
	var artifact_row: HBoxContainer = HBoxContainer.new()
	artifact_row.add_theme_constant_override("separation", 12)
	box.add_child(artifact_row)
	for artifact_id: String in unlocked_artifact_ids:
		var artifact: EquipmentData = _find_equipment_by_id(artifact_id, all_artifacts)
		if artifact != null:
			artifact_row.add_child(_pre_run_artifact_button(artifact))
	var none_button: Button = _button("不帶神器，直接出發")
	none_button.pressed.connect(func():
		run_equipped["weapon"] = null
		show_progress_screen()
	)
	box.add_child(none_button)

func _pre_run_artifact_button(artifact: EquipmentData) -> Button:
	var equipped: bool = (run_equipped.get("weapon") as EquipmentData) != null and (run_equipped.get("weapon") as EquipmentData).id == artifact.id
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(210, 230)
	button.text = "%s\n%s\n%s\n\n%s" % [artifact.display_name, artifact.rarity_display(), "【已選】" if equipped else "", artifact.description]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_stylebox_override("normal", _style_box(Color("3a2a60"), Color("d0a0ff"), 2, 8))
	button.add_theme_stylebox_override("hover",  _style_box(Color("5040a0"), Color("e8c8ff"), 3, 8))
	button.add_theme_color_override("font_color", Color("fff8dc"))
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(func():
		_apply_passive_max_hp()  # reset before re-applying
		run_equipped["weapon"] = artifact.clone()
		selected_character.max_hp += _sum_passive_max_hp(artifact)
		run_hp = selected_character.max_hp
		show_progress_screen()
	)
	return button

func _sum_passive_max_hp(equip: EquipmentData) -> int:
	var sum: int = 0
	for eff: Dictionary in equip.effects:
		if String(eff.get("trigger","")) == "passive" and String(eff.get("kind","")) == "max_hp":
			sum += int(eff.get("amount", 0))
	return sum

func _find_equipment_by_id(id: String, pool: Array[EquipmentData]) -> EquipmentData:
	for equip: EquipmentData in pool:
		if equip.id == id:
			return equip
	return null

# ── Meta-progression saves ──────────────────

func _save_unlocks() -> void:
	var file: FileAccess = FileAccess.open("user://unlocks.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"unlocked_artifact_ids": unlocked_artifact_ids}, "\t"))
	file.close()

func _load_unlocks() -> void:
	if not FileAccess.file_exists("user://unlocks.json"):
		return
	var file: FileAccess = FileAccess.open("user://unlocks.json", FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.get_data() as Dictionary
	if data.has("unlocked_artifact_ids"):
		unlocked_artifact_ids.clear()
		for id_v: Variant in data["unlocked_artifact_ids"]:
			unlocked_artifact_ids.append(String(id_v))

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

func _has_save() -> bool:
	return FileAccess.file_exists("user://savegame.json")

func _clear_save() -> void:
	if _has_save():
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("savegame.json")

func _save_run() -> void:
	if selected_character == null:
		return
	var data: Dictionary = {
		"version": 2,
		"character_id": selected_character.id,
		"run_hp": run_hp,
		"run_gold": run_gold,
		"run_power_bonus": run_power_bonus,
		"encounter_index": encounter_index,
		"run_deck": _serialize_deck(),
		"encounter_choices": _serialize_encounter_choices(),
		"run_equipped": _serialize_equipped(),
		"run_bag": _serialize_bag()
	}
	var file: FileAccess = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _serialize_deck() -> Array:
	var result: Array = []
	for card: CardData in run_deck:
		result.append({"id": card.id, "upgraded": card.upgraded})
	return result

func _serialize_encounter_choices() -> Array:
	var result: Array = []
	for row: Array in encounter_choices:
		var serialized_row: Array = []
		for node_variant: Variant in row:
			var node_data: Dictionary = node_variant as Dictionary
			var entry: Dictionary = {"type": String(node_data.get("type", "battle"))}
			if node_data.has("enemy"):
				var enemy: EnemyData = node_data["enemy"] as EnemyData
				entry["enemy_id"] = enemy.id
			serialized_row.append(entry)
		result.append(serialized_row)
	return result

func _serialize_equipped() -> Dictionary:
	var result: Dictionary = {}
	for slot: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
		var e: Variant = run_equipped.get(slot)
		result[slot] = (e as EquipmentData).id if e != null else ""
	return result

func _serialize_bag() -> Array:
	var result: Array = []
	for e: EquipmentData in run_bag:
		result.append(e.id)
	return result

func _find_any_equipment_by_id(id: String) -> EquipmentData:
	for e: EquipmentData in all_equipment:
		if e.id == id: return e
	for e: EquipmentData in all_char_weapons:
		if e.id == id: return e
	for e: EquipmentData in all_artifacts:
		if e.id == id: return e
	return null

func _load_run() -> bool:
	if not _has_save():
		return false
	var file: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return false
	var data: Dictionary = json.get_data() as Dictionary
	if not data.has("version") or not data.has("character_id"):
		return false
	var char_id: String = String(data["character_id"])
	selected_character = null
	for character: CharacterData in characters:
		if character.id == char_id:
			selected_character = character.clone()
			break
	if selected_character == null:
		return false
	run_hp = int(data["run_hp"])
	run_gold = int(data.get("run_gold", 0))
	run_power_bonus = int(data.get("run_power_bonus", 0))
	encounter_index = int(data["encounter_index"])
	run_deck.clear()
	for card_entry: Variant in data["run_deck"]:
		var card_dict: Dictionary = card_entry as Dictionary
		var found: CardData = _find_card_by_id(String(card_dict["id"]))
		if found == null:
			continue
		if bool(card_dict["upgraded"]):
			run_deck.append(found.upgraded_copy())
		else:
			run_deck.append(found.clone())
	encounter_choices.clear()
	for row_data: Variant in data["encounter_choices"]:
		var row: Array = []
		for node_entry: Variant in row_data:
			var node_dict: Dictionary = node_entry as Dictionary
			var entry: Dictionary = {"type": String(node_dict.get("type", "battle"))}
			if node_dict.has("enemy_id"):
				var found_enemy: EnemyData = _find_enemy_by_id(String(node_dict["enemy_id"]))
				if found_enemy != null:
					entry["enemy"] = found_enemy.clone()
			row.append(entry)
		encounter_choices.append(row)
	current_shop_cards.clear()
	current_shop_equipment.clear()
	run_equipped = {"weapon": null, "armor": null, "accessory_1": null, "accessory_2": null}
	run_bag.clear()
	if data.has("run_equipped"):
		var eq_data: Dictionary = data["run_equipped"] as Dictionary
		for slot: String in ["weapon", "armor", "accessory_1", "accessory_2"]:
			var eid: String = String(eq_data.get(slot, ""))
			if eid != "":
				var found_e: EquipmentData = _find_any_equipment_by_id(eid)
				if found_e != null:
					run_equipped[slot] = found_e.clone()
	if data.has("run_bag"):
		for bid_v: Variant in data["run_bag"]:
			var bid: String = String(bid_v)
			var found_e: EquipmentData = _find_any_equipment_by_id(bid)
			if found_e != null:
				run_bag.append(found_e.clone())
	return true

func _find_card_by_id(id: String) -> CardData:
	for card: CardData in selected_character.starting_deck:
		if card.id == id:
			return card
	for card: CardData in selected_character.reward_pool:
		if card.id == id:
			return card
	return null

func _find_enemy_by_id(id: String) -> EnemyData:
	for enemy: EnemyData in enemies:
		if enemy.id == id:
			return enemy
	return null

func _continue_run() -> void:
	if _load_run():
		show_progress_screen()
	else:
		_clear_save()
		show_main_menu()

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
