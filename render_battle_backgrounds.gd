extends SceneTree

const WINDOW := Vector2i(1280, 720)
const HERO_ID := "li_xiaoyao"
const OUTPUT_PREFIX := "battle_bg_preview_act_"

var main: Main

func _initialize() -> void:
	var root: Window = get_root()
	root.size = WINDOW
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	_run()

func _run() -> void:
	await process_frame
	await process_frame

	var hero: CharacterData = _character_by_id(HERO_ID)
	if hero == null:
		push_error("render_battle_backgrounds: missing hero '%s'" % HERO_ID)
		quit(1)
		return

	main.start_run(hero)
	await process_frame
	await process_frame

	for act: int in range(1, 9):
		_prepare_run_for_act(act)
		var enemy: EnemyData = GameData.boss_for_act(act)
		main.start_next_battle(enemy)
		for i: int in range(8):
			await process_frame
		var path: String = "res://_%s%d.png" % [OUTPUT_PREFIX, act]
		get_root().get_texture().get_image().save_png(path)
		print("[battle-bg] saved %s" % path)
		await process_frame

	print("[battle-bg] done")
	quit(0)

func _prepare_run_for_act(act: int) -> void:
	main.run_state.act = act
	main.run_state.encounter_index = max(0, act - 1)
	main.run_state.encounter_choices = [[{"type": "battle"}]]
	main.run_state.active_character_index = 0
	main.selected_character = main.run_state.character
	main.battle = null

func _character_by_id(id: String) -> CharacterData:
	for character: CharacterData in GameData.characters():
		if character.id == id:
			return character
	return null
