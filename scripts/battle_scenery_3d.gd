class_name BattleScenery3D
extends Node3D

## 3D 戰鬥場景：把 PAL1 手繪背景從「靜止鏡頭」投影到簡單的 3D 代理幾何上
## （地面、遠景牆、建物／石階／前景卡片）——電影 matte painting 的做法。
## 鏡頭在靜止位置時畫面與原圖完全相同；鏡頭環繞時各面依真實深度產生視差，
## 角色陰影也會落在對的平面上（next_pass 收影）。
## 幾何以「原圖 uv」描述，執行時依畫面比例（同 background_rect 的 KEEP_ASPECT_COVERED 裁切）
## 換算成世界座標，所以任何螢幕比例都對得上手繪內容。

## 每張背景的代理幾何（uv 以原圖為 0..1）；沒登記的背景用 DEFAULT_LAYOUT（地面＋遠景牆）。
## - wall_v：地面與遠景牆的交界，取場地最遠的那條邊；必須 ≤ 所有卡片的 v_bottom
##   （比牆還遠的卡片會被牆擋住；build() 會把它拉到牆前，但視差就和牆一樣了）
## - cards：[u0, v_top, u1, v_bottom] 以底邊貼地的直立面。底邊 v 決定深度：
##   底邊越低（越靠畫面下方）越近。前景卡片不可蓋到角色站位（真實深度會擋住腳），
##   角色腳底約在畫面 v≈0.65，前景卡片的 v_top 請放在 0.7 以下。
const DEFAULT_LAYOUT: Dictionary = {"wall_v": 0.52, "cards": []}
const LAYOUTS: Dictionary = {
	# 第 1 幕・餘杭竹林：左涼亭（台基 v≈0.50）、右石階（階底 v≈0.53）、左右下角前景草叢。
	# wall_v 取 0.49（比涼亭台基更遠），否則涼亭卡片會落在遠景牆後面被擋住。
	"res://assets/art/battle_bg_act_1.png": {
		"wall_v": 0.49,
		"cards": [
			[0.0, 0.0, 0.29, 0.50],
			[0.69, 0.0, 1.0, 0.53],
			[0.0, 0.76, 0.15, 1.0],
			[0.85, 0.72, 1.0, 1.0],
		],
	},
}
const EDGE_MARGIN: float = 0.35  # 貼畫面邊的面往外延伸（畫面寬高比例），鏡頭環繞時不露邊

const PROJECTION_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform sampler2D painting : source_color, filter_linear, repeat_disable;
uniform vec3 projector_origin;
uniform mat3 projector_world_to_view;
uniform float tan_half_fov;
uniform float canvas_aspect;
uniform vec4 cover_uv;  // canvas 0..1 → 原圖 uv：uv = cover_uv.xy + canvas01 * cover_uv.zw

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 view = projector_world_to_view * (world_position - projector_origin);
	float depth = max(-view.z, 0.001);
	vec2 ndc = vec2(view.x / depth / (tan_half_fov * canvas_aspect), view.y / depth / tan_half_fov);
	vec2 canvas01 = vec2((ndc.x + 1.0) * 0.5, (1.0 - ndc.y) * 0.5);
	ALBEDO = texture(painting, cover_uv.xy + canvas01 * cover_uv.zw).rgb;
}
"""

static var _projection_shader: Shader

var _material: ShaderMaterial
var _built_key: String = ""
var _proxy_count: int = 0
var _wall_z: float = 0.0


## 重建代理幾何；同一張圖＋同一畫面尺寸重複呼叫不做事（每幀呼叫也安全）。
## rest 是投影用的「靜止鏡頭」，與 BattleStage3D 角色站位用的靜止鏡頭相同。
func build(painting: Texture2D, canvas_size: Vector2, rest: Transform3D, fov: float, layer: int, shadow_pass: Material) -> void:
	var path: String = painting.resource_path if painting != null else ""
	var key: String = "%s|%d|%d" % [path, int(canvas_size.x), int(canvas_size.y)]
	if key == _built_key:
		return
	_built_key = key
	for child: Node in get_children():
		remove_child(child)  # 立刻離開場景，換背景那一幀才不會新舊幾何重疊
		child.queue_free()
	_proxy_count = 0
	if painting == null or canvas_size.x < 1.0 or canvas_size.y < 1.0:
		return
	if _projection_shader == null:
		_projection_shader = Shader.new()
		_projection_shader.code = PROJECTION_SHADER
	_material = ShaderMaterial.new()
	_material.shader = _projection_shader
	_material.set_shader_parameter("painting", painting)
	_material.set_shader_parameter("projector_origin", rest.origin)
	_material.set_shader_parameter("projector_world_to_view", rest.basis.inverse())
	_material.set_shader_parameter("tan_half_fov", tan(deg_to_rad(fov * 0.5)))
	_material.set_shader_parameter("canvas_aspect", canvas_size.x / canvas_size.y)
	var cover: Rect2 = cover_rect(Vector2(painting.get_width(), painting.get_height()), canvas_size)
	_material.set_shader_parameter("cover_uv", Vector4(
		-cover.position.x / cover.size.x, -cover.position.y / cover.size.y,
		canvas_size.x / cover.size.x, canvas_size.y / cover.size.y))
	var card_material: ShaderMaterial = _material.duplicate() as ShaderMaterial
	card_material.next_pass = shadow_pass  # 直立面也收角色陰影；地面由 BattleStage3D 的收影面負責

	var layout: Dictionary = LAYOUTS.get(path, DEFAULT_LAYOUT) as Dictionary
	var margin: Vector2 = canvas_size * EDGE_MARGIN
	var wall_y: float = cover.position.y + float(layout.get("wall_v", 0.52)) * cover.size.y
	var near_y: float = canvas_size.y + margin.y
	var left_x: float = -margin.x
	var right_x: float = canvas_size.x + margin.x
	var top_y: float = -margin.y
	# 地面：畫面下緣外 → 遠景牆交界
	var ground_corners: Array[Vector3] = []
	for point: Vector2 in [Vector2(left_x, wall_y), Vector2(right_x, wall_y), Vector2(right_x, near_y), Vector2(left_x, near_y)]:
		ground_corners.append(_ground_hit(point, canvas_size, rest, fov))
	_add_quad("Ground", ground_corners, _material, layer)
	# 遠景牆：立在地面最遠邊，往上蓋過天空
	_wall_z = _ground_hit(Vector2(canvas_size.x * 0.5, wall_y), canvas_size, rest, fov).z
	_add_vertical("BackdropWall", Rect2(left_x, top_y, right_x - left_x, wall_y - top_y), _wall_z, canvas_size, rest, fov, card_material, layer)
	# 直立卡片：底邊貼地，深度由底邊決定；貼畫面邊的方向往外延伸
	var index: int = 0
	for spec_value: Variant in layout.get("cards", []) as Array:
		var spec: Array = spec_value as Array
		var u0: float = float(spec[0])
		var v_top: float = float(spec[1])
		var u1: float = float(spec[2])
		var v_bottom: float = float(spec[3])
		var depth_y: float = min(cover.position.y + v_bottom * cover.size.y, canvas_size.y)
		var x0: float = left_x if u0 <= 0.0 else cover.position.x + u0 * cover.size.x
		var x1: float = right_x if u1 >= 1.0 else cover.position.x + u1 * cover.size.x
		var y0: float = top_y if v_top <= 0.0 else cover.position.y + v_top * cover.size.y
		var y1: float = near_y if v_bottom >= 1.0 else depth_y
		var card_z: float = max(_ground_hit(Vector2((x0 + x1) * 0.5, depth_y), canvas_size, rest, fov).z, _wall_z + 0.05)
		_add_vertical("Card%d" % index, Rect2(x0, y0, x1 - x0, y1 - y0), card_z, canvas_size, rest, fov, card_material, layer)
		index += 1


func proxy_count() -> int:
	return _proxy_count


func wall_z() -> float:
	return _wall_z


## background_rect 的 KEEP_ASPECT_COVERED：原圖等比放大到蓋滿畫面、置中裁切。回傳原圖在 canvas 上的範圍。
static func cover_rect(image_size: Vector2, canvas_size: Vector2) -> Rect2:
	var scale_factor: float = max(canvas_size.x / max(1.0, image_size.x), canvas_size.y / max(1.0, image_size.y))
	var drawn: Vector2 = image_size * scale_factor
	return Rect2((canvas_size - drawn) * 0.5, drawn)


## canvas（以畫面左上為原點）上一點 → 鏡頭空間射線（未正規化，z = -1）。
## 與 Camera3D 的 KEEP_HEIGHT／垂直 fov 針孔模型一致。
static func camera_space_ray(canvas_point: Vector2, canvas_size: Vector2, fov: float) -> Vector3:
	var extent: Vector2 = canvas_size.max(Vector2.ONE)
	var tan_half: float = tan(deg_to_rad(fov * 0.5))
	var ndc: Vector2 = Vector2(canvas_point.x / extent.x * 2.0 - 1.0, 1.0 - canvas_point.y / extent.y * 2.0)
	return Vector3(ndc.x * tan_half * extent.x / extent.y, ndc.y * tan_half, -1.0)


static func _ground_hit(canvas_point: Vector2, canvas_size: Vector2, rest: Transform3D, fov: float) -> Vector3:
	var direction: Vector3 = rest.basis * camera_space_ray(canvas_point, canvas_size, fov)
	if direction.y > -0.0001:
		direction.y = -0.0001  # 高於地平線：推到極遠處（呼叫端只傳地平線以下的點）
	return rest.origin + direction * (-rest.origin.y / direction.y)


static func _plane_z_hit(canvas_point: Vector2, z: float, canvas_size: Vector2, rest: Transform3D, fov: float) -> Vector3:
	var direction: Vector3 = rest.basis * camera_space_ray(canvas_point, canvas_size, fov)
	return rest.origin + direction * ((z - rest.origin.z) / min(direction.z, -0.0001))


func _add_vertical(node_name: String, canvas_rect: Rect2, z: float, canvas_size: Vector2, rest: Transform3D, fov: float, material: Material, layer: int) -> void:
	var corners: Array[Vector3] = []
	for point: Vector2 in [canvas_rect.position, canvas_rect.position + Vector2(canvas_rect.size.x, 0.0),
			canvas_rect.end, canvas_rect.position + Vector2(0.0, canvas_rect.size.y)]:
		corners.append(_plane_z_hit(point, z, canvas_size, rest, fov))
	_add_quad(node_name, corners, material, layer)


## corners 依畫面上「左上→右上→右下→左下」排列＝從鏡頭看順時針，即 Godot 的正面。
func _add_quad(node_name: String, corners: Array[Vector3], material: Material, layer: int) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(corners)
	var normal: Vector3 = (corners[3] - corners[0]).cross(corners[1] - corners[0]).normalized()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([normal, normal, normal, normal])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.layers = layer
	add_child(instance)
	_proxy_count += 1
