extends SceneTree
# 敵人位置漂移探針：重現使用者場景（黑苗頭領+雙士兵），跨「出牌→敵回合→新回合」
# 多輪記錄每敵 wrap 的 global_position.y 與 portrait 的 position.y / texture，抓上下浮動來源。
# 跑法：godot --path . -s tools/drift_probe.gd（要 windowed，動畫/tween 需要真 frame）

var main: Node

func _initialize() -> void:
	get_root().size = Vector2i(1280, 720)
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(main)
	_run()

func _dump(tag: String) -> void:
	for i in range(main.enemy_widgets.size()):
		var w: Dictionary = main.enemy_widgets[i]
		var wrap: Control = w["wrap"]
		var portrait: TextureRect = w["portrait"]
		if wrap == null or not is_instance_valid(wrap):
			continue
		var tex_name: String = portrait.texture.resource_path.get_file() if portrait.texture != null else "null"
		print("[drift] %s e%d wrap_y=%.1f wrap_gy=%.1f por_y=%.1f por_h=%.1f tex=%s" % [
			tag, i, wrap.position.y, wrap.global_position.y, portrait.position.y, portrait.size.y, tex_name])

func _wait(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _run() -> void:
	await _wait(2)
	main.start_run(GameData.characters()[2])  # 林月如（同使用者場景）
	await _wait(1)
	var trio: Array[EnemyData] = []
	for id in ["miao_soldier", "miao_chieftain", "miao_soldier"]:
		var e: EnemyData = GameData.enemy_by_id(id)
		if e != null:
			trio.append(e)
	if trio.size() < 3:
		# fallback：任 3 敵
		trio.clear()
		for id2 in ["bandit", "miao_chieftain", "bandit"]:
			var e2: EnemyData = GameData.enemy_by_id(id2)
			if e2 != null:
				trio.append(e2)
	main.start_next_battle(trio)
	await _wait(20)
	_dump("turn1_start")
	# 連打 3 輪：出第一張可打的卡 → 結束回合 → 敵人行動 → 新回合
	for round_i in range(3):
		# 出一張卡（用 play_card 直接路徑）
		var played: bool = false
		for card in main.battle.deck.hand:
			if main.battle.effective_card_cost(card) <= int(main.battle.state["energy"]):
				main.play_card(card, null)
				played = true
				break
		await _wait(50)  # 等出牌動畫+shake 完
		_dump("r%d_after_play" % round_i)
		main.end_player_turn()
		await _wait(90)  # 等敵人行動動畫完
		_dump("r%d_after_enemy" % round_i)
		if main.battle == null or main.battle.is_battle_over():
			print("[drift] battle over early")
			break
	print("[drift] done")
	quit(0)
