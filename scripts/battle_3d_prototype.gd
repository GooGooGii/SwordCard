extends Node3D

## 3D battle presentation study. The live card battle remains in main.gd.
const HERO_MODEL: String = "res://assets/models/li_xiaoyao_blockout.glb"
const MENU_SCENE: String = "res://scenes/main.tscn"

var _camera: Camera3D
var _hero: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _spell: MeshInstance3D
var _pose_label: Label
var _pose_tween: Tween
var _orbit_yaw: float = 0.25
var _dragging: bool = false


func _ready() -> void:
	_build_arena()
	_build_hero()
	_build_interface()
	_set_pose("idle")


func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = 0.86
	return result


func _box(parent: Node3D, name: String, dimensions: Vector3, position_3d: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.material_override = _material(color)
	mesh.position = position_3d
	parent.add_child(mesh)
	return mesh


func _build_arena() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("b7c9bd")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("fff0d4")
	settings.ambient_light_energy = 0.32
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)

	_box(self, "GrassyGround", Vector3(100.0, 0.25, 100.0), Vector3(0.0, -0.16, 0.0), Color("58744b"))
	var dirt := MeshInstance3D.new()
	dirt.name = "DirtPath"
	var dirt_shape := SphereMesh.new()
	dirt_shape.radius = 1.0
	dirt_shape.height = 2.0
	dirt.mesh = dirt_shape
	dirt.material_override = _material(Color("92735a"))
	dirt.scale = Vector3(4.9, 0.02, 1.45)
	dirt.position = Vector3(0.0, -0.025, 0.15)
	add_child(dirt)
	for i in range(24):
		var x: float = -5.8 + float((i * 37) % 112) * 0.1
		var z: float = -3.3 if i % 2 == 0 else 2.9
		var tuft := _box(self, "GrassTuft", Vector3(0.08, 0.16, 0.08), Vector3(x, 0.05, z), Color("73915a"))
		tuft.rotation_degrees.z = 18.0 if i % 3 == 0 else -13.0

	# A training target lets us inspect combat scale without inventing a PAL1 enemy design.
	var target := Node3D.new()
	target.name = "TrainingTarget"
	target.position = Vector3(2.25, 0.0, 0.0)
	add_child(target)
	_box(target, "Post", Vector3(0.28, 1.55, 0.28), Vector3(0.0, 0.78, 0.0), Color("54402d"))
	_box(target, "StrawBody", Vector3(0.80, 0.82, 0.42), Vector3(0.0, 1.30, 0.0), Color("b69a5d"))
	_box(target, "StrawHead", Vector3(0.40, 0.38, 0.40), Vector3(0.0, 1.90, 0.0), Color("c0a46b"))
	_box(target, "TargetBand", Vector3(0.85, 0.09, 0.47), Vector3(0.0, 1.30, 0.0), Color("593a30"))

	_camera = Camera3D.new()
	_camera.fov = 48.0
	_camera.current = true
	add_child(_camera)
	_update_camera()


func _build_hero() -> void:
	if not ResourceLoader.exists(HERO_MODEL):
		push_warning("3D model not imported yet: " + HERO_MODEL)
		return
	var model_scene: PackedScene = load(HERO_MODEL) as PackedScene
	if model_scene == null:
		push_warning("Unable to load 3D model: " + HERO_MODEL)
		return
	_hero = model_scene.instantiate() as Node3D
	_hero.name = "LiXiaoyaoBlockout"
	_hero.position = Vector3(-2.15, 0.0, 0.0)
	_hero.rotation_degrees.y = 60.0
	add_child(_hero)
	_left_arm = _hero.find_child("LeftArmPivot", true, false) as Node3D
	_right_arm = _hero.find_child("RightArmPivot", true, false) as Node3D

	_spell = MeshInstance3D.new()
	var spell_mesh := SphereMesh.new()
	spell_mesh.radius = 0.24
	spell_mesh.height = 0.48
	_spell.mesh = spell_mesh
	var spell_material := _material(Color("80ddf5"))
	spell_material.emission_enabled = true
	spell_material.emission = Color("5dcdea")
	spell_material.emission_energy_multiplier = 1.6
	_spell.material_override = spell_material
	_spell.position = Vector3(-1.2, 1.4, -0.2)
	_spell.visible = false
	add_child(_spell)


func _build_interface() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	overlay.add_child(column)

	var title := Label.new()
	title.text = "SwordCard · 3D 戰場原型"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("fff0d2"))
	title.add_theme_color_override("font_shadow_color", Color("17201a"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_pose_label = Label.new()
	_pose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pose_label.add_theme_font_size_override("font_size", 18)
	_pose_label.add_theme_color_override("font_color", Color("fff0d2"))
	column.add_child(_pose_label)

	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(space)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)
	for spec in [
		["待命", "idle"], ["攻擊", "attack"], ["擋格", "block"],
		["施法", "cast"], ["命危", "low_hp"], ["倒地", "downed"]
	]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(84.0, 46.0)
		button.pressed.connect(_set_pose.bind(spec[1]))
		actions.add_child(button)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 18)
	column.add_child(footer)
	var hint := Label.new()
	hint.text = "拖曳背景旋轉鏡頭 · 手機可滑動"
	hint.add_theme_color_override("font_color", Color("fff0d2"))
	footer.add_child(hint)
	var back := Button.new()
	back.text = "返回主選單"
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	footer.add_child(back)
	var gap := Control.new()
	gap.custom_minimum_size.y = 16.0
	column.add_child(gap)


func _set_pose(pose: String) -> void:
	if _pose_tween != null and _pose_tween.is_running():
		_pose_tween.kill()
	var names: Dictionary = {"idle": "待命", "attack": "攻擊", "block": "擋格", "cast": "施法", "low_hp": "命危", "downed": "倒地"}
	_pose_label.text = "李逍遙 · %s　（建模與戰場尺度驗證）" % names.get(pose, pose)
	if _hero == null:
		return
	# 與正式戰鬥共用同一份姿勢表（BattleStage3D.pose_targets）
	var targets: Dictionary = BattleStage3D.pose_targets(pose, 60.0)
	var hero_rotation: Vector3 = targets["body_rotation"]
	var hero_position: Vector3 = Vector3(-2.15, 0.0, 0.0) + (targets["body_offset"] as Vector3)
	var left_rotation: Vector3 = targets["left_arm"]
	var right_rotation: Vector3 = targets["right_arm"]
	_spell.visible = pose == "cast"
	_pose_tween = create_tween().set_parallel(true)
	_pose_tween.tween_property(_hero, "rotation_degrees", hero_rotation, 0.28)
	_pose_tween.tween_property(_hero, "position", hero_position, 0.28)
	if _left_arm != null:
		_pose_tween.tween_property(_left_arm, "rotation_degrees", left_rotation, 0.28)
	if _right_arm != null:
		_pose_tween.tween_property(_right_arm, "rotation_degrees", right_rotation, 0.28)


func _update_camera() -> void:
	_camera.position = Vector3(sin(_orbit_yaw) * 7.2, 4.0, cos(_orbit_yaw) * 7.2)
	_camera.look_at(Vector3(0.0, 0.72, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(MENU_SCENE)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	if event is InputEventMouseMotion and _dragging:
		_orbit_yaw += event.relative.x * 0.007
		_update_camera()
	if event is InputEventScreenDrag:
		_orbit_yaw += event.relative.x * 0.007
		_update_camera()
