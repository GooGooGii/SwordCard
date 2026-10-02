extends SceneTree

## Capture four actual Godot renderer views for art review.
const SCENE_PATH := "res://scenes/character_3d_candidate.tscn"
const OUTPUT_DIR := "res://docs/3d_previews/candidate_li_xiaoyao_crossover_v7_sword"


func _initialize() -> void:
	await process_frame
	var packed: PackedScene = load(SCENE_PATH)
	if packed == null:
		push_error("Cannot load candidate preview scene")
		quit(1)
		return
	var preview: Node3D = packed.instantiate() as Node3D
	root.add_child(preview)
	await process_frame
	await process_frame

	var output_path: String = "res://docs/3d_previews/candidate_li_xiaoyao_head_v1" if OS.get_environment("SWORDCARD_3D_REVIEW_HEAD") == "1" else OUTPUT_DIR
	var output_dir: String = ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(output_dir)
	for spec in [["front", 0.0], ["left", 90.0], ["back", 180.0], ["right", 270.0]]:
		preview.call("_set_view", float(spec[1]))
		await process_frame
		await process_frame
		var image: Image = preview.get_viewport().get_texture().get_image()
		if image == null or image.is_empty():
			push_error("Viewport capture failed for " + spec[0])
			quit(1)
			return
		var path: String = output_dir.path_join(spec[0] + ".png")
		var error: Error = image.save_png(path)
		if error != OK:
			push_error("Cannot save " + path + ": " + error_string(error))
			quit(1)
			return
		print("Candidate review render: " + path)
	preview.queue_free()
	await process_frame
	quit(0)
