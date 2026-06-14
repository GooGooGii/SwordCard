extends SceneTree
# BATTLE_UI_POLISH 驗證：1敵 / 3敵 / 含飄浮系 三張戰鬥截圖
var main: Node

func _initialize() -> void:
	get_root().size = Vector2i(1280, 720)
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(main)
	_run()

func _shot(label: String) -> void:
	for i in range(14):
		await process_frame
	get_root().get_texture().get_image().save_png("res://_bui_%s.png" % label)
	print("[bui] saved _bui_%s.png" % label)

func _run() -> void:
	await process_frame
	await process_frame
	# 三人隊 + 3 敵（使用者回報：組隊比例怪）
	var chars: Array = GameData.characters()
	main.start_run([chars[0], chars[1], chars[3]])
	await process_frame
	var party_trio: Array[EnemyData] = []
	for id in ["skeleton_soldier", "grave_fire", "earth_imp"]:
		var e0: EnemyData = GameData.enemy_by_id(id)
		if e0 != null:
			party_trio.append(e0)
	main.start_next_battle(party_trio)
	await _shot("party_trio")
	main.show_main_menu()
	await process_frame
	main.start_run(GameData.characters()[0])
	await process_frame
	# 灌 16 件遺物驗證 +N 摺疊（Phase C2）
	for r in RelicCatalog.all():
		if main.run_state.relics.size() >= 16:
			break
		if not main.run_state.has_relic(r.id):
			main.run_state.add_relic(r)
	# 1 敵
	main.start_next_battle(GameData.enemy_by_id("bandit"))
	await _shot("single")
	# 3 敵（含飄浮系 grave_fire 驗證陰影縮小）＋灌滿狀態驗證 chips
	var trio: Array[EnemyData] = []
	for id in ["skeleton_soldier", "grave_fire", "earth_imp"]:
		var e: EnemyData = GameData.enemy_by_id(id)
		if e != null:
			trio.append(e)
	main.start_next_battle(trio)
	await process_frame
	# 敵人狀態：毒/弱/破/暈 各給不同敵，玩家：power/毒/弱
	var slots: Array = main.battle.state["enemies"]
	slots[0]["poison"] = 4; slots[0]["weak"] = 2
	slots[1]["vulnerable"] = 3; slots[1]["stunned"] = 1
	slots[2]["poison"] = 7; slots[2]["block"] = 6
	main.battle.state["player_power"] = 5
	main.battle.state["player_poison"] = 2
	main.battle.state["player_weak"] = 1
	main.battle.state["player_block"] = 8
	main.battle._sync_state_to_active()
	main._refresh_battle()
	await _shot("trio_status")
	print("[bui] done")
	quit(0)
