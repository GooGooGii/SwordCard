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
	# 3 敵（含飄浮系 grave_fire 驗證陰影縮小）
	var trio: Array[EnemyData] = []
	for id in ["skeleton_soldier", "grave_fire", "earth_imp"]:
		var e: EnemyData = GameData.enemy_by_id(id)
		if e != null:
			trio.append(e)
	main.start_next_battle(trio)
	await _shot("trio_float")
	print("[bui] done")
	quit(0)
