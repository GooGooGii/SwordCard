extends SceneTree
# 蛇妖 boss phase 轉換漂移探針：單挑蛇妖，打到 HP<50% 觸發 phase2 換圖，
# 記錄換圖前後 portrait 的視覺底邊（position.y + size.y）是否一致（貼地是否跳動）。
var main: Node

func _initialize() -> void:
	get_root().size = Vector2i(1280, 720)
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(main)
	_run()

func _dump(tag: String) -> void:
	var w: Dictionary = main.enemy_widgets[0]
	var wrap: Control = w["wrap"]
	var p: TextureRect = w["portrait"]
	var tex: String = p.texture.resource_path.get_file() if p.texture != null else "null"
	print("[boss] %s wrap_gy=%.1f por_y=%.1f por_h=%.1f bottom=%.1f tex=%s phased=%s" % [
		tag, wrap.global_position.y, p.position.y, p.size.y, p.position.y + p.size.y, tex,
		str(main.battle.enemy_phased[0])])

func _wait(f: int) -> void:
	for i in range(f): await process_frame

func _run() -> void:
	await _wait(2)
	main.start_run(GameData.characters()[2])
	await _wait(1)
	main.start_next_battle(GameData.enemy_by_id("red_eye_demon"))
	await _wait(20)
	_dump("phase1")
	# 直接把 boss 打到剛好過半門檻下，end_turn 觸發 phase 檢查
	# 一刀斬殺蛇妖 → 狐妖女接續登場
	var slot: Dictionary = main.battle.state["enemies"][0]
	slot["hp"] = 5
	main.battle.state["enemy_hp"] = 5
	main.battle.state["energy"] = 99
	for card in main.battle.deck.hand:
		if CardFormat.action_has_damage({"effects": card.effects}):
			main.play_card(card, null)
			break
	await _wait(40)
	print("[boss] enemies now = %d" % (main.battle.state["enemies"] as Array).size())
	get_root().get_texture().get_image().save_png("res://_boss_succession.png")
	print("[boss] saved _boss_succession.png")
	print("[boss] done")
	quit(0)
