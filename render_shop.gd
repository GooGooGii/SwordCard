extends SceneTree
#
# 商店畫面「實機渲染截圖」工具（美術審查用，暫時檔）
# 跑法（務必 windowed，不要 --headless）：
#   godot --path . -s render_shop.gd
# 輸出 res://_shop_normal.png / res://_shop_black.png；看完刪除。
#

const WINDOW := Vector2i(1280, 720)
const SHOTS := [
	{"black": false, "label": "normal"},
	{"black": true, "label": "black"},
]

var main: Node

func _initialize() -> void:
	get_root().size = WINDOW
	_run()

func _fresh_main() -> void:
	if main != null:
		main.queue_free()
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(main)

func _run() -> void:
	await process_frame
	await process_frame
	for shot in SHOTS:
		_fresh_main()
		await process_frame
		await process_frame
		main.start_run(GameData.characters()[0])
		await process_frame
		main.run_state.gold = 250
		main.open_shop_node(bool(shot["black"]))
		# 固定讓第一張卡特賣，穩定驗證「五折特賣」印章渲染
		if not main.run_state.current_shop_inventory.is_empty():
			main.run_state.current_shop_inventory[0]["on_sale"] = true
			main.show_shop_node()
		for i in range(8): await process_frame
		var fname := "res://_shop_%s.png" % shot["label"]
		get_root().get_texture().get_image().save_png(fname)
		print("[shop] saved %s" % fname)
		# 捲到底再拍一張（遺物/藥品/服務列）
		var scrolls := main.find_children("*", "ScrollContainer", true, false)
		if not scrolls.is_empty():
			var sc: ScrollContainer = scrolls[0]
			sc.scroll_vertical = 620
			for i in range(4): await process_frame
			var fname_mid := "res://_shop_%s_mid.png" % shot["label"]
			get_root().get_texture().get_image().save_png(fname_mid)
			print("[shop] saved %s" % fname_mid)
			sc.scroll_vertical = 100000
			for i in range(4): await process_frame
			var fname2 := "res://_shop_%s_bottom.png" % shot["label"]
			get_root().get_texture().get_image().save_png(fname2)
			print("[shop] saved %s" % fname2)
		for i in range(3): await process_frame
	print("[shop] done")
	quit(0)
