extends SceneTree
#
# 奇遇事件「實機渲染截圖」工具（Event Redesign 驗證用）
# ---------------------------------------------------------------------------
# 開一場真 run、把 current_event_variant 設成指定事件、呼叫 show_event_node()，
# 截圖存 PNG，肉眼確認分支樹選項 / 徽章 / hide_badge「❔ 未知」是否如預期渲染。
#
# 跑法（務必 windowed，不要 --headless）：
#   godot --path . -s render_event.gd
# 看 res://_event_<variant>.png；看完自行刪除暫存 PNG。
# ---------------------------------------------------------------------------

const WINDOW := Vector2i(1280, 720)
# 要截圖的事件 variant（root 節點畫面）
const VARIANTS := ["ancient_battlefield", "ghost_forest"]
# 驗證條件分支：低血（觸發 hp_below）＋ 設旗標（觸發 event_flag 回訪選項）
const LOW_HP := true
const SET_FLAGS := ["fox_spared", "marked_by_bandits"]

var main: Node

func _initialize() -> void:
	var root := get_root()
	root.size = WINDOW
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	_run()

func _run() -> void:
	await process_frame
	await process_frame
	main.start_run(GameData.characters()[0])
	await process_frame
	if LOW_HP:
		main.run_state.character_hps[0] = max(1, int(main.run_state.character_max_hps[0] * 0.3))
	for f in SET_FLAGS:
		main.run_state.set_event_flag(f)
	for v in VARIANTS:
		main.run_state.current_event_variant = v
		main.show_event_node()
		for i in range(8): await process_frame
		get_root().get_texture().get_image().save_png("res://_event_%s.png" % v)
		print("[event] saved _event_%s.png" % v)
		for i in range(3): await process_frame
	print("[event] done; %d shot(s)" % VARIANTS.size())
	quit(0)
