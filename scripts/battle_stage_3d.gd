class_name BattleStage3D
extends TextureRect

## 正式戰鬥的 3D 戰場層：畫在 PAL1 手繪背景之上、戰鬥 UI（血條／意圖／手牌）之下。
##
## 站位與動畫仍由 2D 版面決定：HBox 排版、shake / dash / flash tween 照舊作用在肖像 wrap 上。
## 這裡每幀把被追蹤的肖像框投影到 3D 地面，改由 3D 角色呈現：
## - CHARACTER_MODELS 有登記的角色 → 3D 模型＋六姿勢（idle/attack/block/cast/low_hp/downed）
## - 其他角色與敵人 → 原立繪 Sprite3D 立在地面上，投影後與 2D 框完全重合
## 地面是只收陰影的透明面，所以背景仍是原本的手繪場景；2D 橢圓腳影改由真實陰影取代。
## 用 SubViewport＋TextureRect（而非 SubViewportContainer）是為了以實體解析度渲染，
## 在 canvas_items 放大的視窗／手機上不會比 2D 立繪糊。

const CHARACTER_MODELS: Dictionary = {
	"li_xiaoyao": {"path": "res://assets/models/li_xiaoyao_blockout.glb", "yaw": 60.0},
}
const CAMERA_FOV: float = 40.0
const CAMERA_HEIGHT: float = 2.6
const CAMERA_PITCH: float = -10.0  # 地平線約落在畫面 26% 高，對齊手繪背景的遠山
const NO_GROUND_DEPTH: float = 14.0  # 腳底高於地平線（理論上不會）時的退路深度
const POSE_TIME: float = 0.18
const BLOB_WIDTH_RATIO: float = 0.55  # 與 UIFactory.ground_shadow 的 0.55 一致
const GROUND_LAYER: int = 1 << 1  # 收影地面獨立一層，補光用 cull mask 避開
const SUN_DIRECTION: Vector3 = Vector3(0.55, -0.65, -0.5)  # 光行進方向：往右、往下、往畫面深處
const SHADOW_CATCHER_SHADER: String = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, specular_disabled, ambient_light_disabled;

uniform vec3 shadow_tint : source_color = vec3(0.03, 0.025, 0.05);
uniform float strength = 0.5;

void fragment() {
	ALBEDO = vec3(0.0);
	EMISSION = shadow_tint;
	ALPHA = 0.0;
}

void light() {
	// ATTENUATION 含陰影：受光 1、全影 0 → 影越深越不透明
	ALPHA = max(ALPHA, (1.0 - ATTENUATION) * strength);
}
"""

static var _model_cache: Dictionary = {}
static var _blob_texture: GradientTexture2D

var _viewport: SubViewport
var _camera: Camera3D
var _camera_origin: Vector3 = Vector3(0.0, CAMERA_HEIGHT, 0.0)
var _camera_basis: Basis = Basis.from_euler(Vector3(deg_to_rad(CAMERA_PITCH), 0.0, 0.0))
var _world: Node3D  # 位於原點、無旋轉縮放 → 子節點的 local transform 就是世界座標
var _actors: Dictionary = {}  # key -> actor Dictionary（見 _create_actor）


func _init() -> void:
	name = "BattleStage3D"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_priority = 100  # 在 tween / 版面更新之後才讀肖像位置
	# 透明 viewport 輸出是 premultiplied alpha；不改 blend mode 立繪髮絲邊緣會發黑
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	material = blend
	_build_world()


func _ready() -> void:
	texture = _viewport.get_texture()
	_update_viewport_size()


func _process(_delta: float) -> void:
	sync_now()


# ── 對外 API ───────────────────────────────────────────────────────────────

## 把一個 2D 肖像交給 3D 戰場呈現；同一 key 重複呼叫只會重新綁定（後排／敵列重建時用）。
## character_id 有登記模型就用 3D 模型，否則用該肖像目前的 texture 當立繪。
func track(key: String, portrait: TextureRect, character_id: String = "", pose: String = "idle", floats: bool = false) -> void:
	if portrait == null:
		return
	var actor: Dictionary = _actors.get(key, {}) as Dictionary
	if actor.is_empty():
		actor = _create_actor()
		_actors[key] = actor
	actor["portrait"] = portrait
	actor["floats"] = floats
	portrait.self_modulate.a = 0.0  # 只藏繪製；版面、點擊、modulate 動畫照常
	_hide_2d_shadows(portrait)
	_set_actor_model(actor, character_id)
	_set_actor_pose(actor, pose)


func sync_now() -> void:
	_update_viewport_size()
	var stale: Array[String] = []
	for key: String in _actors:
		var actor: Dictionary = _actors[key]
		var portrait: Variant = actor.get("portrait")
		if not is_instance_valid(portrait) or (portrait as Node).is_queued_for_deletion():
			stale.append(key)
			continue
		_sync_actor(actor)
	for key: String in stale:
		_remove_actor(key)
	_sort_sprites_by_2d_order()


func actor_count() -> int:
	return _actors.size()


func uses_model(key: String) -> bool:
	var actor: Dictionary = _actors.get(key, {}) as Dictionary
	return actor.get("model") != null


func actor_pose(key: String) -> String:
	var actor: Dictionary = _actors.get(key, {}) as Dictionary
	return String(actor.get("pose", ""))


func actor_root_position(key: String) -> Vector3:
	var actor: Dictionary = _actors.get(key, {}) as Dictionary
	var node: Node3D = actor.get("model") as Node3D
	if node == null:
		node = actor.get("sprite") as Node3D
	return node.position if node != null else Vector3.ZERO


## 畫面（canvas 座標）上的一點 → 對應的 3D 地面點。
func screen_to_ground(canvas_point: Vector2) -> Vector3:
	_update_viewport_size()
	return _point_at_depth(canvas_point, _ground_depth(canvas_point))


func ground_to_screen(world_point: Vector3) -> Vector2:
	var extent: Vector2 = size.max(Vector2.ONE)
	var view: Vector3 = _camera_basis.inverse() * (world_point - _camera_origin)
	var depth: float = max(0.001, -view.z)
	var tan_half: float = tan(deg_to_rad(CAMERA_FOV * 0.5))
	var ndc: Vector2 = Vector2(view.x / depth / (tan_half * extent.x / extent.y), view.y / depth / tan_half)
	var local: Vector2 = Vector2((ndc.x + 1.0) * 0.5 * extent.x, (1.0 - ndc.y) * 0.5 * extent.y)
	return local + _canvas_xform(self).origin


## 3D 角色姿勢表：base_yaw 為角色面向，其餘是相對於站位的位移與傾角。
## 也供 battle_3d_prototype.gd 的姿勢檢視使用，兩邊共用同一份數值。
static func pose_targets(pose: String, base_yaw: float) -> Dictionary:
	var body_rotation: Vector3 = Vector3(0.0, base_yaw, 0.0)
	var body_offset: Vector3 = Vector3.ZERO
	var left_arm: Vector3 = Vector3.ZERO
	var right_arm: Vector3 = Vector3.ZERO
	match pose:
		"attack":
			body_rotation.z = -10.0
			body_offset.x = 0.25
			right_arm = Vector3(-115.0, 0.0, 22.0)
			left_arm = Vector3(-28.0, 0.0, -18.0)
		"block":
			body_rotation.z = -4.0
			right_arm = Vector3(-155.0, 0.0, 28.0)
			left_arm = Vector3(-72.0, 0.0, -22.0)
		"cast":
			left_arm = Vector3(-105.0, 0.0, -17.0)
			right_arm = Vector3(-25.0, 0.0, 10.0)
		"low_hp":
			body_rotation.z = -19.0
			body_offset.y = -0.29
			left_arm = Vector3(-65.0, 0.0, -30.0)
		"downed":
			body_rotation.z = 82.0
			body_offset = Vector3(0.30, 0.12, 0.0)
			right_arm = Vector3(-15.0, 0.0, 0.0)
	return {"body_rotation": body_rotation, "body_offset": body_offset, "left_arm": left_arm, "right_arm": right_arm}


# ── 場景建構 ───────────────────────────────────────────────────────────────

func _build_world() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "StageViewport"
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.gui_disable_input = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_world = Node3D.new()
	_world.name = "StageWorld"
	_viewport.add_child(_world)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR  # 透明，露出手繪背景
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("fff0d4")
	environment.ambient_light_energy = 0.55
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	_world.add_child(world_environment)

	# 主光：鏡頭左前上方，影子往右後方斜落在角色右側的空地上。
	# 不能往鏡頭方向落（會整片藏在腳下的血條後面），也不能純側光
	# （立繪是面向鏡頭的薄板，側光擦過板面時影子會縮成一條線）。
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.basis = Basis.looking_at(SUN_DIRECTION)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	_world.add_child(sun)
	# 補光：從鏡頭方向照亮模型正面（主光是逆光），不投影。
	# 不可照到收影地面：shadow_to_opacity 對每盞燈取 min(1 - 受光)，無影補光會把整片陰影歸零。
	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-18.0, 8.0, 0.0)
	fill.light_energy = 0.42
	fill.light_cull_mask = 0xFFFFF & ~GROUND_LAYER  # 20 個 render layer 中去掉地面層
	_world.add_child(fill)

	# 只顯示陰影的地面：受光處全透明，陰影處變暗。不用 StandardMaterial3D.shadow_to_opacity——
	# 它的 alpha 會被「環境光×albedo」封頂，深色地面整片透明（實測 alpha 全 0）。
	var ground: MeshInstance3D = MeshInstance3D.new()
	ground.name = "ShadowCatcher"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	ground.mesh = plane
	ground.position = Vector3(0.0, 0.0, -20.0)
	ground.layers = GROUND_LAYER
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var catcher_shader: Shader = Shader.new()
	catcher_shader.code = SHADOW_CATCHER_SHADER
	var catcher: ShaderMaterial = ShaderMaterial.new()
	catcher.shader = catcher_shader
	catcher.render_priority = -20
	ground.material_override = catcher
	_world.add_child(ground)

	_camera = Camera3D.new()
	_camera.name = "StageCamera"
	_camera.fov = CAMERA_FOV
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT  # 與 _camera_space_ray 的投影模型一致
	_camera.transform = Transform3D(_camera_basis, _camera_origin)
	_camera.current = true
	_world.add_child(_camera)


func _create_actor() -> Dictionary:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.centered = true
	sprite.shaded = false  # 立繪本身已畫好光影，保持與 2D 一致的色彩
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_world.add_child(sprite)
	# 半透明立繪不投影，另用 alpha-cut 的同一張圖只負責投影（剪影準確、邊緣不影響畫面）
	var caster: Sprite3D = Sprite3D.new()
	caster.centered = true
	caster.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_world.add_child(caster)
	# 腳底接觸陰影（主光的影子落在右後方，腳下仍需要一圈貼地暗影）
	var blob: MeshInstance3D = MeshInstance3D.new()
	var blob_mesh: PlaneMesh = PlaneMesh.new()
	blob_mesh.size = Vector2(1.0, 1.0)
	blob.mesh = blob_mesh
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var blob_material: StandardMaterial3D = StandardMaterial3D.new()
	blob_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blob_material.albedo_texture = _contact_shadow_texture()
	blob_material.render_priority = -10
	blob.material_override = blob_material
	_world.add_child(blob)
	return {
		"portrait": null, "floats": false, "sprite": sprite, "caster": caster, "blob": blob,
		"model": null, "model_id": "", "model_height": 2.0, "yaw": 0.0,
		"left_arm": null, "right_arm": null, "meshes": [], "pose": "", "pose_tween": null,
		"overlay_add": null, "overlay_mul": null,
	}


func _remove_actor(key: String) -> void:
	var actor: Dictionary = _actors[key]
	var tween: Variant = actor.get("pose_tween")
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()
	for node_key: String in ["sprite", "caster", "blob", "model"]:
		var node: Variant = actor.get(node_key)
		if node != null and is_instance_valid(node):
			(node as Node).queue_free()
	_actors.erase(key)


func _set_actor_model(actor: Dictionary, character_id: String) -> void:
	var wanted: String = character_id if CHARACTER_MODELS.has(character_id) else ""
	if String(actor["model_id"]) == wanted:
		return
	var old_model: Variant = actor.get("model")
	if old_model != null and is_instance_valid(old_model):
		(old_model as Node).queue_free()
	actor["model"] = null
	actor["body"] = null
	actor["model_id"] = wanted
	actor["meshes"] = []
	actor["pose"] = ""  # 換模型後姿勢要立即重套
	if wanted.is_empty():
		return
	var spec: Dictionary = CHARACTER_MODELS[wanted]
	var packed: PackedScene = _load_model(String(spec["path"]))
	if packed == null:
		actor["model_id"] = ""
		return
	var anchor: Node3D = Node3D.new()  # 站位與尺度；姿勢 tween 作用在子節點 body 上
	anchor.name = "ModelAnchor"
	var body: Node3D = packed.instantiate() as Node3D
	if body == null:
		anchor.free()
		actor["model_id"] = ""
		return
	anchor.add_child(body)
	_world.add_child(anchor)
	var meshes: Array = []
	for node: Node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		meshes.append(mesh_instance)
	actor["model"] = anchor
	actor["body"] = body
	actor["meshes"] = meshes
	actor["yaw"] = float(spec.get("yaw", 0.0))
	actor["model_height"] = _model_height(body, meshes)
	actor["left_arm"] = body.find_child("LeftArmPivot", true, false) as Node3D
	actor["right_arm"] = body.find_child("RightArmPivot", true, false) as Node3D


func _set_actor_pose(actor: Dictionary, pose: String) -> void:
	if String(actor["pose"]) == pose:
		return
	var instant: bool = String(actor["pose"]).is_empty()
	actor["pose"] = pose
	var body: Node3D = actor.get("body") as Node3D
	if actor.get("model") == null or body == null:
		return
	var previous: Variant = actor.get("pose_tween")
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	var targets: Dictionary = pose_targets(pose, float(actor["yaw"]))
	var left_arm: Node3D = actor.get("left_arm") as Node3D
	var right_arm: Node3D = actor.get("right_arm") as Node3D
	if instant or not is_inside_tree():
		body.rotation_degrees = targets["body_rotation"]
		body.position = targets["body_offset"]
		if left_arm != null:
			left_arm.rotation_degrees = targets["left_arm"]
		if right_arm != null:
			right_arm.rotation_degrees = targets["right_arm"]
		return
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "rotation_degrees", targets["body_rotation"], POSE_TIME)
	tween.tween_property(body, "position", targets["body_offset"], POSE_TIME)
	if left_arm != null:
		tween.tween_property(left_arm, "rotation_degrees", targets["left_arm"], POSE_TIME)
	if right_arm != null:
		tween.tween_property(right_arm, "rotation_degrees", targets["right_arm"], POSE_TIME)
	actor["pose_tween"] = tween


# ── 每幀同步 ───────────────────────────────────────────────────────────────

func _sync_actor(actor: Dictionary) -> void:
	var portrait: TextureRect = actor["portrait"] as TextureRect
	var sprite: Sprite3D = actor["sprite"] as Sprite3D
	var caster: Sprite3D = actor["caster"] as Sprite3D
	var blob: MeshInstance3D = actor["blob"] as MeshInstance3D
	var model: Node3D = actor.get("model") as Node3D
	var tint: Color = _effective_modulate(portrait)
	var shown: bool = portrait.is_visible_in_tree() and tint.a > 0.01
	var wrap: Control = portrait.get_parent() as Control
	var wrap_xform: Transform2D = _canvas_xform(wrap) if wrap != null else _canvas_xform(portrait)
	var wrap_size: Vector2 = wrap.size if wrap != null else portrait.size
	# 2D 版面約定：肖像內容底部貼齊 wrap 底邊中央（UIFactory.ground_portrait）
	var feet: Vector2 = wrap_xform * Vector2(wrap_size.x * 0.5, wrap_size.y)
	var depth: float = _ground_depth(feet)
	var per_pixel: float = _world_per_canvas_pixel(depth)
	var ground_point: Vector3 = _point_at_depth(feet, depth)

	var floats: bool = bool(actor["floats"])
	var blob_width: float = wrap_size.x * wrap_xform.get_scale().x * per_pixel * BLOB_WIDTH_RATIO * (0.7 if floats else 1.0)
	blob.visible = shown
	blob.position = ground_point + Vector3(0.0, 0.004, 0.0)
	blob.scale = Vector3(blob_width, 1.0, blob_width * 0.5)
	(blob.material_override as StandardMaterial3D).albedo_color = Color(1.0, 1.0, 1.0, tint.a * (0.45 if floats else 0.75))

	if model != null:
		sprite.visible = false
		caster.visible = false
		model.visible = shown
		var box: Vector2 = portrait.get_meta("ground_box", wrap_size) as Vector2
		var target_height: float = box.y * abs(wrap_xform.get_scale().y) * per_pixel
		model.position = ground_point
		model.scale = Vector3.ONE * (target_height / max(0.01, float(actor["model_height"])))
		_apply_model_tint(actor, tint)
		return

	var tex: Texture2D = portrait.texture
	if tex == null or tex.get_height() <= 0:
		sprite.visible = false
		caster.visible = false
		return
	var rect: Rect2 = _drawn_rect(portrait)
	var center: Vector3 = _point_at_depth(rect.get_center(), depth)
	var flipped: bool = _canvas_xform(portrait).x.x < 0.0
	for quad: Sprite3D in [sprite, caster]:
		quad.texture = tex
		quad.pixel_size = per_pixel * rect.size.y / float(tex.get_height())
		quad.flip_h = flipped
		quad.transform = Transform3D(_camera_basis, center)  # 與鏡頭平行 → 投影後與 2D 框完全重合
	sprite.visible = shown
	sprite.modulate = tint
	caster.visible = shown and tint.a >= 0.5


## 2D 的疊放順序就是樹狀順序（後排先畫、HBox 後面的敵人蓋在前面）；
## 3D 半透明物件改用 render_priority 照同樣順序排，避免同深度的三敵交疊時閃爍。
func _sort_sprites_by_2d_order() -> void:
	var ordered: Array[Dictionary] = []
	for key: String in _actors:
		var actor: Dictionary = _actors[key]
		if is_instance_valid(actor.get("portrait")):
			ordered.append(actor)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _tree_order_less(_tree_order_key(a["portrait"] as Node), _tree_order_key(b["portrait"] as Node)))
	for i: int in range(ordered.size()):
		(ordered[i]["sprite"] as Sprite3D).render_priority = min(i, 100)


static func _tree_order_key(node: Node) -> Array[int]:
	var key: Array[int] = []
	while node != null and node.get_parent() != null:
		key.push_front(node.get_index())
		node = node.get_parent()
	return key


static func _tree_order_less(a: Array[int], b: Array[int]) -> bool:
	for i: int in range(min(a.size(), b.size())):
		if a[i] != b[i]:
			return a[i] < b[i]
	return a.size() < b.size()  # 祖先先畫、子孫後畫


func _apply_model_tint(actor: Dictionary, tint: Color) -> void:
	# 2D 的 flash（>1 提亮）、陣亡/後排變暗（<1）、換人淡出（alpha）全部鏡像到模型上
	var transparency: float = clamp(1.0 - tint.a, 0.0, 1.0)
	var overlay: Material = null
	var brighten: float = max(tint.r, max(tint.g, tint.b)) - 1.0
	if brighten > 0.02:
		var add_material: StandardMaterial3D = actor.get("overlay_add") as StandardMaterial3D
		if add_material == null:
			add_material = StandardMaterial3D.new()
			add_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			add_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			actor["overlay_add"] = add_material
		add_material.albedo_color = Color(max(tint.r - 1.0, 0.0), max(tint.g - 1.0, 0.0), max(tint.b - 1.0, 0.0)) * 0.6
		overlay = add_material
	elif min(tint.r, min(tint.g, tint.b)) < 0.98:
		var mul_material: StandardMaterial3D = actor.get("overlay_mul") as StandardMaterial3D
		if mul_material == null:
			mul_material = StandardMaterial3D.new()
			mul_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mul_material.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			actor["overlay_mul"] = mul_material
		mul_material.albedo_color = Color(tint.r, tint.g, tint.b)
		overlay = mul_material
	for mesh_instance: Variant in actor["meshes"]:
		if not is_instance_valid(mesh_instance):
			continue
		var mi: MeshInstance3D = mesh_instance as MeshInstance3D
		mi.transparency = transparency
		mi.material_overlay = overlay


# ── 投影數學（canvas 座標 ↔ 3D）─────────────────────────────────────────────

func _update_viewport_size() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var wanted: Vector2i = Vector2i((size * _canvas_pixel_scale()).round())
	wanted = wanted.max(Vector2i.ONE)
	if _viewport.size != wanted:
		_viewport.size = wanted


func _canvas_pixel_scale() -> Vector2:
	if not is_inside_tree():
		return Vector2.ONE
	var final_scale: Vector2 = get_viewport().get_final_transform().get_scale().abs()
	return final_scale.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))


## 鏡頭空間射線（未正規化，z = -1 → 乘上深度 d 就是沿鏡頭前方 d 的點）。
## 與 _camera 的設定（KEEP_HEIGHT、垂直 fov）是同一個針孔模型；自己算而不呼叫
## Camera3D.project_ray_*，才能在節點進樹前（smoke test 的同步 _initialize）使用。
func _camera_space_ray(canvas_point: Vector2) -> Vector3:
	var extent: Vector2 = size.max(Vector2.ONE)
	var local: Vector2 = canvas_point - _canvas_xform(self).origin
	var tan_half: float = tan(deg_to_rad(CAMERA_FOV * 0.5))
	var ndc: Vector2 = Vector2(local.x / extent.x * 2.0 - 1.0, 1.0 - local.y / extent.y * 2.0)
	return Vector3(ndc.x * tan_half * extent.x / extent.y, ndc.y * tan_half, -1.0)


## 腳底那條畫面水平線打到地面的深度；無 roll 的鏡頭下同一列深度相同。
func _ground_depth(canvas_point: Vector2) -> float:
	var direction: Vector3 = _camera_basis * _camera_space_ray(canvas_point)
	if direction.y > -0.0001:
		return NO_GROUND_DEPTH
	return -_camera_origin.y / direction.y


func _point_at_depth(canvas_point: Vector2, depth: float) -> Vector3:
	return _camera_origin + _camera_basis * (_camera_space_ray(canvas_point) * depth)


func _world_per_canvas_pixel(depth: float) -> float:
	return 2.0 * depth * tan(deg_to_rad(CAMERA_FOV * 0.5)) / max(1.0, size.y)


## 進樹時就是 get_global_transform；進樹前（測試）沿父鏈累乘 local transform。
static func _canvas_xform(item: CanvasItem) -> Transform2D:
	if item.is_inside_tree():
		return item.get_global_transform()
	var xform: Transform2D = item.get_transform()
	var node: Node = item.get_parent()
	while node is CanvasItem:
		xform = (node as CanvasItem).get_transform() * xform
		node = node.get_parent()
	return xform


## 肖像實際畫出貼圖的範圍（canvas 座標）。ground_portrait 用 STRETCH_SCALE（整框）；
## 後排肖像是 KEEP_ASPECT_CENTERED（框內置中等比）。
static func _drawn_rect(portrait: TextureRect) -> Rect2:
	var local: Rect2 = Rect2(Vector2.ZERO, portrait.size)
	var tex: Texture2D = portrait.texture
	var keep_aspect: bool = portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED or portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT
	if keep_aspect and tex != null and tex.get_width() > 0 and tex.get_height() > 0:
		var tex_size: Vector2 = Vector2(tex.get_width(), tex.get_height())
		var fit: float = min(portrait.size.x / tex_size.x, portrait.size.y / tex_size.y)
		var drawn: Vector2 = tex_size * fit
		var offset: Vector2 = (portrait.size - drawn) * 0.5 if portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED else Vector2.ZERO
		local = Rect2(offset, drawn)
	var xform: Transform2D = _canvas_xform(portrait)
	var a: Vector2 = xform * local.position
	var b: Vector2 = xform * local.end
	return Rect2(Vector2(min(a.x, b.x), min(a.y, b.y)), (b - a).abs())


func _effective_modulate(item: CanvasItem) -> Color:
	var color: Color = Color.WHITE
	var node: Node = item
	var stop: Node = get_parent()
	while node != null and node != stop:
		if node is CanvasItem:
			color *= (node as CanvasItem).modulate
		node = node.get_parent()
	return color


static func _hide_2d_shadows(portrait: TextureRect) -> void:
	var parent: Node = portrait.get_parent()
	if parent == null:
		return
	for child: Node in parent.get_children():
		if child is CanvasItem and child.has_meta("ground_shadow"):
			(child as CanvasItem).visible = false


static func _load_model(path: String) -> PackedScene:
	if _model_cache.has(path):
		return _model_cache[path] as PackedScene
	var packed: PackedScene = null
	if ResourceLoader.exists(path):
		packed = load(path) as PackedScene
	if packed == null:
		push_warning("3D model unavailable, falling back to portrait: " + path)
	_model_cache[path] = packed
	return packed


## 模型站在原點，取所有 mesh AABB 的最高點當身高（模型尚未進樹，自己累乘 local transform）。
static func _model_height(body: Node3D, meshes: Array) -> float:
	var top: float = 0.0
	for mesh_instance: Variant in meshes:
		var mi: MeshInstance3D = mesh_instance as MeshInstance3D
		var relative: Transform3D = Transform3D.IDENTITY
		var node: Node = mi
		while node != null and node != body:
			if node is Node3D:
				relative = (node as Node3D).transform * relative
			node = node.get_parent()
		top = max(top, (relative * mi.get_aabb()).end.y)
	return top if top > 0.1 else 2.0


static func _contact_shadow_texture() -> GradientTexture2D:
	if _blob_texture != null:
		return _blob_texture
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.42))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	gradient.add_point(0.55, Color(0.0, 0.0, 0.0, 0.22))
	_blob_texture = GradientTexture2D.new()
	_blob_texture.gradient = gradient
	_blob_texture.fill = GradientTexture2D.FILL_RADIAL
	_blob_texture.fill_from = Vector2(0.5, 0.5)
	_blob_texture.fill_to = Vector2(1.0, 0.5)
	_blob_texture.width = 64
	_blob_texture.height = 64
	return _blob_texture
