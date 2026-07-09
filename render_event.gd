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
# 每張截圖：事件 variant ＋ 操作角色 ＋ 事前旗標（觸發 event_flag 回訪選項）
const SHOTS := [
	{"variant": "tangyu_sparring", "character": "anu", "flags": []},
	{"variant": "spring", "character": "zhao_linger", "flags": []},
	{"variant": "tavern_acquaintance", "character": "anu", "flags": ["yamen_grudge", "thief_backer_grudge"]},
	{"variant": "baiyue_altar", "character": "li_xiaoyao", "flags": ["waner_clue", "yao_freed"]},
]
# 低血（觸發 hp_below 條件選項）
const LOW_HP := false

var main: Node

func _initialize() -> void:
	get_root().size = WINDOW
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(main)
	_run()

func _character_by_id(id: String) -> CharacterData:
	for c in GameData.characters():
		if c.id == id:
			return c
	return GameData.characters()[0]

func _run() -> void:
	# 同一行程重複 start_run/重建 main 會殘影疊圖——一個行程只截一張，
	# 用環境變數 EVENT_SHOT=<index> 選 SHOTS 的哪一筆（shell 迴圈跑多張）。
	await process_frame
	await process_frame
	var idx := int(OS.get_environment("EVENT_SHOT")) if OS.get_environment("EVENT_SHOT") != "" else 0
	var shot: Dictionary = SHOTS[clampi(idx, 0, SHOTS.size() - 1)]
	main.start_run(_character_by_id(shot["character"]))
	await process_frame
	if LOW_HP:
		main.run_state.character_hps[0] = max(1, int(main.run_state.character_max_hps[0] * 0.3))
	for f in shot["flags"]:
		main.run_state.set_event_flag(f)
	main.run_state.current_event_variant = shot["variant"]
	main.show_event_node()
	for i in range(8): await process_frame
	var fname := "res://_event_%s_%s.png" % [shot["variant"], shot["character"]]
	get_root().get_texture().get_image().save_png(fname)
	print("[event] saved %s" % fname)
	quit(0)
