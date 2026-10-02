extends Node3D

## Isolated art QA scene; it never replaces the battle model or touches saves.
const MODEL_PATH: String = "res://assets/models/candidates/li_xiaoyao_crossover_composite_with_sword_v2.glb"
const HEAD_MODEL_PATH: String = "res://assets/models/candidates/li_xiaoyao_crossover_head_triposr_v1.glb"
const MENU_SCENE: String = "res://scenes/main.tscn"

var _model: Node3D
var _camera: Camera3D
var _yaw: float = 0.0
var _dragging: bool = false


func _ready() -> void:
	_build_stage()
	_build_model()
	_build_overlay()
	_update_camera()


func _build_stage() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("343a42")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d4dce7")
	environment.ambient_light_energy = 0.6
	world.environment = environment
	add_child(world)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key.light_energy = 1.4
	key.shadow_enabled = true
	add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-28.0, 145.0, 0.0)
	fill.light_energy = 0.5
	add_child(fill)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("55535a")
	floor_material.roughness = 0.92
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.current = true
	add_child(_camera)


func _build_model() -> void:
	var inspect_head: bool = OS.get_environment("SWORDCARD_3D_REVIEW_HEAD") == "1"
	var model_path: String = HEAD_MODEL_PATH if inspect_head else MODEL_PATH
	# candidates/ 有 .gdignore（不匯入、不進 APK）→ 開發時直接從 GLB 原檔讀
	_model = _load_gltf_runtime(model_path)
	if _model == null:
		push_warning("Cannot load 3D candidate: " + model_path)
		return
	_model.name = "LiXiaoyaoCrossoverCandidate"
	# TripoSR exports Z-up geometry; Godot's 3D world is Y-up.
	_model.rotation_degrees = Vector3(-90.0, 90.0, 0.0)
	_model.scale = Vector3(0.85, -0.85, 0.85) if inspect_head else Vector3(2.2, -2.2, 2.2)
	_model.position.y = 1.35 if inspect_head else 1.1
	add_child(_model)


func _load_gltf_runtime(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		return null
	var document: GLTFDocument = GLTFDocument.new()
	var state: GLTFState = GLTFState.new()
	if document.append_from_file(path, state) != OK:
		return null
	return document.generate_scene(state) as Node3D


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(column)

	var title := Label.new()
	title.text = "李逍遙聯動造型 · 3D 候選（靜態，未綁骨架）"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)
	for item in [["正面", 0.0], ["左側", 90.0], ["背面", 180.0], ["右側", 270.0]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size = Vector2(80.0, 42.0)
		button.pressed.connect(_set_view.bind(float(item[1])))
		buttons.add_child(button)

	var hint := Label.new()
	hint.text = "拖曳旋轉視角 · Esc 返回主選單"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("e5e5e5"))
	column.add_child(hint)


func _set_view(degrees: float) -> void:
	_yaw = deg_to_rad(degrees)
	_update_camera()


func _update_camera() -> void:
	var inspect_head: bool = OS.get_environment("SWORDCARD_3D_REVIEW_HEAD") == "1"
	var distance: float = 1.8 if inspect_head else 4.7
	var target_height: float = 1.35 if inspect_head else 1.1
	_camera.position = Vector3(sin(_yaw) * distance, target_height + 0.12, cos(_yaw) * distance)
	_camera.look_at(Vector3(0.0, target_height, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(MENU_SCENE)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	if event is InputEventMouseMotion and _dragging:
		_yaw += event.relative.x * 0.008
		_update_camera()
	if event is InputEventScreenDrag:
		_yaw += event.relative.x * 0.008
		_update_camera()
