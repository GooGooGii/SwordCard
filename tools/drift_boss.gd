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
	for r in range(8):
		var slot: Dictionary = main.battle.state["enemies"][0]
		slot["hp"] = 40  # 95 max，<50% 觸發 phase2
		main.battle.state["enemy_hp"] = 40
		# 出一張卡推進結算 + phase 檢查
		var played := false
		for card in main.battle.deck.hand:
			if main.battle.effective_card_cost(card) <= int(main.battle.state["energy"]):
				main.play_card(card, null)
				played = true
				break
		await _wait(30)
		_dump("r%d_after_play" % r)
		if main.battle.enemy_phased[0]:
			await _wait(20)
			_dump("phase2_settled")
			break
		main.end_player_turn()
		await _wait(60)
	print("[boss] done")
	quit(0)
