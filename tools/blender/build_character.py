"""AI 生成形體 → 遊戲用角色 GLB：清理、體素重建、減面、四視角投影貼圖、骨架、兵器、多鍵動作。

blender --background --python tools/blender/build_character.py -- <rig.json> [--preview <png 資料夾>]

rig.json（路徑相對於 rig.json 所在資料夾）：
  raw: 原始形體 GLB（tools/comfyui/hunyuan3d_mv.py 的輸出）
  views: 四視角資料夾（front/left/back/right.png 白底＋*_rgba.png 去背；缺左側可用右側鏡像）
  out: 輸出 GLB
  height, front_axis("-Y"/"+Y"/"-X"/"+X"), faces（三角面目標）, remesh, texture_size
  joints: {名稱: [x, z]}，以身高為單位；x 相對兩腳中點、+x＝角色自己的左側
  weapon: {kind: "jian"|"dao", length}（握在右手；為獨立骨頭 weapon，不參與蒙皮）
  poses: {姿勢名: {骨頭: [世界方向 x,y,z], "_pelvis": [位移 ×身高], "_weapon": "hand"|[[握柄位置],[劍尖方向]]}}
  actions: {動作名: {loop: bool, keys: [[影格, 姿勢名], ...]}}（30 fps）

角色座標：腳底 z=0、臉朝 -Y（glTF/Three.js 的 +Z）、+X＝角色自己的左邊。
移植自舊專案 SwordCard 的 tools/blender/build_li_xiaoyao_hy3d.py（踩坑紀錄見該 repo 的 docs/THREE_D_PROTOTYPE.md）。
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

VIEWS = ("front", "left", "back", "right")
VIEW_DIRECTIONS = {
    "front": Vector((0.0, -1.0, 0.0)), "left": Vector((1.0, 0.0, 0.0)),
    "back": Vector((0.0, 1.0, 0.0)), "right": Vector((-1.0, 0.0, 0.0)),
}
VIS_CHANNEL = {"front": "R", "left": "G", "back": "B", "right": "A"}
FEET_BAND = 0.04
FPS = 30


def select_only(objects, active):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = active


# ── 形體 ────────────────────────────────────────────────────────────────────

def import_body(path: Path, name: str):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    select_only(meshes, meshes[0])
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for obj in list(bpy.context.scene.objects):
        if obj != body:
            bpy.data.objects.remove(obj, do_unlink=True)
    select_only([body], body)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    body.name = name
    body.data.materials.clear()
    return body


def keep_main_parts(body, min_fraction):
    """焊接重疊頂點、法線朝外，並刪掉零碎小島（bone heat 遇到小島會整個失敗）。"""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.verts.ensure_lookup_table()
    bm.verts.index_update()
    seen, islands = set(), []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, island = [v], []
        seen.add(v.index)
        while stack:
            cur = stack.pop()
            island.append(cur)
            for edge in cur.link_edges:
                other = edge.other_vert(cur)
                if other.index not in seen:
                    seen.add(other.index)
                    stack.append(other)
        islands.append(island)
    total = len(bm.verts)
    doomed = [v for island in islands if len(island) < total * min_fraction for v in island]
    bmesh.ops.delete(bm, geom=doomed, context="VERTS")
    bm.to_mesh(body.data)
    bm.free()
    print(f"islands={len(islands)} removed_verts={len(doomed)}")


def orient_and_normalize(body, front_axis: str, height: float):
    co = np.array([v.co[:] for v in body.data.vertices])
    tallest = int(np.argmax(co.max(axis=0) - co.min(axis=0)))
    if tallest == 0:
        body.data.transform(Matrix.Rotation(math.pi / 2, 4, "Y"))
    elif tallest == 1:
        body.data.transform(Matrix.Rotation(-math.pi / 2, 4, "X"))
    turn = {"-Y": 0.0, "+Y": math.pi, "-X": -math.pi / 2, "+X": math.pi / 2}[front_axis]
    body.data.transform(Matrix.Rotation(turn, 4, "Z"))
    co = np.array([v.co[:] for v in body.data.vertices])
    zmin, zmax = co[:, 2].min(), co[:, 2].max()
    co = (co - [0.0, 0.0, zmin]) * (height / (zmax - zmin))
    feet = co[co[:, 2] < height * FEET_BAND]
    pelvis = co[np.abs(co[:, 2] - height * 0.5) < height * 0.03]
    co -= [feet[:, 0].mean(), pelvis[:, 1].mean(), 0.0]
    for vertex, new in zip(body.data.vertices, co):
        vertex.co = new
    body.data.update()


def remesh(body, voxel_fraction: float, height: float):
    """surface-net 網格有大量非流形邊，減面會卡住：先體素重建成乾淨的流形網格。"""
    if voxel_fraction <= 0:
        return
    mod = body.modifiers.new("Remesh", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = voxel_fraction * height
    select_only([body], body)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print(f"remesh -> faces {len(body.data.polygons)}")


def _triangle_count(mesh) -> int:
    return sum(len(p.vertices) - 2 for p in mesh.polygons)


def decimate(body, triangles: int):
    """目標以三角面計（體素重建輸出四邊面，直接用面數算比例會多出一倍）。"""
    current = _triangle_count(body.data)
    if current > triangles:
        mod = body.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = triangles / current
        select_only([body], body)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    body.data.validate(verbose=False)
    select_only([body], body)
    bpy.ops.object.shade_smooth()
    print(f"triangles {current} -> {_triangle_count(body.data)}")


def unwrap(body):
    select_only([body], body)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")


# ── 貼圖：四視角投影（法線權重 × 可見度）→ 烘焙 ─────────────────────────────

def figure_box(path: Path):
    image = bpy.data.images.load(str(path))
    w, h = image.size
    alpha = np.array(image.pixels[:]).reshape(h, w, 4)[::-1, :, 3]
    ys, xs = np.nonzero(alpha > 0.06)
    bpy.data.images.remove(image)
    feet = xs[ys > ys.max() - (ys.max() - ys.min()) * FEET_BAND]
    return ys.min() / h, (ys.max() + 1) / h, (feet.mean() + 0.5) / w


def bake_visibility(body):
    from mathutils.bvhtree import BVHTree
    bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    attr = body.data.color_attributes.new("vis", "FLOAT_COLOR", "POINT")
    for vertex in body.data.vertices:
        channels = []
        for view in VIEWS:
            direction = VIEW_DIRECTIONS[view]
            origin = vertex.co + vertex.normal * 0.004
            occluded = False
            for _ in range(4):
                hit, _n, _i, distance = bvh.ray_cast(origin, direction)
                if hit is None:
                    break
                if distance > 0.01:
                    occluded = True
                    break
                origin = hit + direction * 0.002
            channels.append(0.0 if occluded else 1.0)
        attr.data[vertex.index].color = channels


def math_node(nodes, links, op, a=None, b=None, value_b=None):
    node = nodes.new("ShaderNodeMath")
    node.operation = op
    if a is not None:
        links.new(a, node.inputs[0])
    if b is not None:
        links.new(b, node.inputs[1])
    if value_b is not None:
        node.inputs[1].default_value = value_b
    return node.outputs[0]


def projection_fallback(body, views_dir, specs, zmin, zmax, feet_center, cloth_band=None):
    """Fill occluded UV samples from nearby confidently painted mesh vertices.

    A soft visibility floor paints a second face on a rear ponytail. A hard
    mask alone leaves black holes. The fallback follows 3D surface proximity,
    preserving the strict mask without reintroducing occluded view colors.
    """
    from mathutils.kdtree import KDTree
    co = np.array([v.co[:] for v in body.data.vertices])
    normals = np.array([v.normal[:] for v in body.data.vertices])
    vis = np.array([v.color[:] for v in body.data.color_attributes['vis'].data])
    colors = np.zeros((len(co), 3))
    total = np.zeros(len(co))
    for view, (axis, sign, (n_axis, n_sign)) in specs.items():
        top,bottom,feet_u = figure_box(views_dir / f'{view}_rgba.png')
        scale = (bottom-top)/(zmax-zmin)
        uv_u = feet_u + (co[:,axis]-feet_center[axis])*scale*sign
        uv_v = (1-bottom)+(co[:,2]-zmin)*scale
        path = views_dir / f'{view}_pad.png'
        image = bpy.data.images.load(str(path if path.exists() else views_dir / f'{view}.png'))
        w,h = image.size
        pixels = np.array(image.pixels[:]).reshape(h,w,4)
        x = np.clip(np.rint(uv_u*w).astype(int),0,w-1)
        y = np.clip(np.rint(uv_v*h).astype(int),0,h-1)
        rgb = pixels[y,x,:3]
        # Image pixels are encoded sRGB; a vertex color shader expects linear.
        rgb = np.where(rgb <= .04045, rgb/12.92, ((rgb+.055)/1.055)**2.4)
        weight = np.maximum(normals[:,n_axis]*n_sign,0)**6 * vis[:,VIEWS.index(view)]
        if cloth_band and view in ("left", "right"):
            width, bottom, top = cloth_band
            in_cloth = (np.abs(co[:,0]) < width*zmax) & (co[:,2] > bottom*zmax) & (co[:,2] < top*zmax)
            weight[in_cloth] = 0
        colors += rgb*weight[:,None]
        total += weight
        bpy.data.images.remove(image)
    good = total > .001
    if not good.any():
        raise ValueError('No visible projection samples; check source views and mesh orientation')
    colors[good] /= total[good,None]
    tree = KDTree(int(good.sum()))
    for i in np.flatnonzero(good):
        tree.insert(Vector(co[i]),int(i))
    tree.balance()
    for i in np.flatnonzero(~good):
        _,nearest,_ = tree.find(Vector(co[i]))
        colors[i] = colors[nearest]
    attr = body.data.color_attributes.new('projection_fallback','FLOAT_COLOR','POINT')
    rgba = np.column_stack([colors,np.ones(len(colors))]).astype(np.float32)
    attr.data.foreach_set('color',rgba.ravel())
    print(f'projection fallback vertices: {(~good).sum()} / {len(co)}')


def bake_projection(body, views_dir: Path, size: int, visibility_floor: float = .03, cloth_band=None):
    bake_visibility(body)
    co = np.array([v.co[:] for v in body.data.vertices])
    zmin, zmax = co[:, 2].min(), co[:, 2].max()
    feet = co[co[:, 2] < zmin + (zmax - zmin) * FEET_BAND]
    feet_center = (feet[:, 0].mean(), feet[:, 1].mean())
    specs = {"front": (0, +1, (1, -1)), "back": (0, -1, (1, +1)), "left": (1, +1, (0, +1)), "right": (1, -1, (0, -1))}
    if visibility_floor <= 0:
        projection_fallback(body, views_dir, specs, zmin, zmax, feet_center, cloth_band)
    mat = bpy.data.materials.new("ProjectionBake")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nodes.new("ShaderNodeTexCoord").outputs["Object"], sep.inputs[0])
    nsep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nodes.new("ShaderNodeNewGeometry").outputs["Normal"], nsep.inputs[0])
    vis = nodes.new("ShaderNodeVertexColor")
    vis.layer_name = "vis"
    vis_rgb = nodes.new("ShaderNodeSeparateColor")
    links.new(vis.outputs["Color"], vis_rgb.inputs[0])
    vis_socket = {"R": vis_rgb.outputs[0], "G": vis_rgb.outputs[1], "B": vis_rgb.outputs[2], "A": vis.outputs["Alpha"]}
    color_sum = weight_sum = None
    for view, (axis, sign, (n_axis, n_sign)) in specs.items():
        if not (views_dir / f"{view}.png").exists():
            continue
        top, bottom, feet_u = figure_box(views_dir / f"{view}_rgba.png")
        scale_v = (bottom - top) / (zmax - zmin)
        offset_v = (1.0 - bottom) - zmin * scale_v
        scale_u = scale_v * sign
        offset_u = feet_u - feet_center[axis] * scale_u
        u = math_node(nodes, links, "MULTIPLY_ADD", sep.outputs[axis])
        u.node.inputs[1].default_value, u.node.inputs[2].default_value = scale_u, offset_u
        v = math_node(nodes, links, "MULTIPLY_ADD", sep.outputs[2])
        v.node.inputs[1].default_value, v.node.inputs[2].default_value = scale_v, offset_v
        uv = nodes.new("ShaderNodeCombineXYZ")
        links.new(u, uv.inputs[0])
        links.new(v, uv.inputs[1])
        tex = nodes.new("ShaderNodeTexImage")
        padded = views_dir / f"{view}_pad.png"  # tools/art/pad_views.py：邊緣外擴，對不準時不會沾到白底
        tex.image = bpy.data.images.load(str(padded if padded.exists() else views_dir / f"{view}.png"))
        tex.extension = "EXTEND"
        links.new(uv.outputs[0], tex.inputs[0])
        facing = math_node(nodes, links, "MULTIPLY", nsep.outputs[n_axis], value_b=float(n_sign))
        facing = math_node(nodes, links, "MAXIMUM", facing, value_b=0.0)
        weight = math_node(nodes, links, "POWER", facing, value_b=6.0)
        visible = math_node(nodes, links, "ADD", vis_socket[VIS_CHANNEL[view]], value_b=visibility_floor)
        weight = math_node(nodes, links, "MULTIPLY", weight, visible)
        if cloth_band and view in ("left", "right"):
            width, bottom, top = cloth_band
            central = math_node(nodes, links, "LESS_THAN", math_node(nodes, links, "ABSOLUTE", sep.outputs[0]), value_b=width*zmax)
            above = math_node(nodes, links, "GREATER_THAN", sep.outputs[2], value_b=bottom*zmax)
            below = math_node(nodes, links, "LESS_THAN", sep.outputs[2], value_b=top*zmax)
            mask = math_node(nodes, links, "MULTIPLY", central, above)
            mask = math_node(nodes, links, "MULTIPLY", mask, below)
            outside = math_node(nodes, links, "SUBTRACT", b=mask)
            outside.node.inputs[0].default_value = 1
            weight = math_node(nodes, links, "MULTIPLY", weight, outside)
        scaled = nodes.new("ShaderNodeVectorMath")
        scaled.operation = "SCALE"
        links.new(tex.outputs["Color"], scaled.inputs[0])
        links.new(weight, scaled.inputs["Scale"])
        if color_sum is None:
            color_sum, weight_sum = scaled.outputs[0], weight
        else:
            add = nodes.new("ShaderNodeVectorMath")
            add.operation = "ADD"
            links.new(color_sum, add.inputs[0])
            links.new(scaled.outputs[0], add.inputs[1])
            color_sum = add.outputs[0]
            weight_sum = math_node(nodes, links, "ADD", weight_sum, weight)
    raw_weight = weight_sum
    weight_sum = math_node(nodes, links, "MAXIMUM", weight_sum, value_b=1e-4)
    weight_vec = nodes.new("ShaderNodeCombineXYZ")
    for i in range(3):
        links.new(weight_sum, weight_vec.inputs[i])
    divide = nodes.new("ShaderNodeVectorMath")
    divide.operation = "DIVIDE"
    links.new(color_sum, divide.inputs[0])
    links.new(weight_vec.outputs[0], divide.inputs[1])
    output_color = divide.outputs[0]
    if visibility_floor <= 0:
        fallback = nodes.new('ShaderNodeVertexColor')
        fallback.layer_name = 'projection_fallback'
        mix = nodes.new('ShaderNodeMixRGB')
        links.new(math_node(nodes, links, 'GREATER_THAN', raw_weight, value_b=.001), mix.inputs[0])
        links.new(fallback.outputs['Color'],mix.inputs[1])
        links.new(output_color,mix.inputs[2])
        output_color = mix.outputs[0]
    emission = nodes.new("ShaderNodeEmission")
    links.new(output_color, emission.inputs["Color"])
    links.new(emission.outputs[0], nodes.new("ShaderNodeOutputMaterial").inputs["Surface"])
    baked = bpy.data.images.new(f"{body.name}Albedo", size, size, alpha=False)
    target = nodes.new("ShaderNodeTexImage")
    target.image = baked
    nodes.active = target
    body.data.materials.clear()
    body.data.materials.append(mat)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    scene.cycles.device = "CPU"
    select_only([body], body)
    bpy.ops.object.bake(type="EMIT", margin=8)
    body.data.color_attributes.remove(body.data.color_attributes["vis"])
    if "projection_fallback" in body.data.color_attributes:
        body.data.color_attributes.remove(body.data.color_attributes["projection_fallback"])
    out = bpy.data.materials.new(f"{body.name}Skin")
    out.use_nodes = True
    bsdf = out.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = out.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = baked
    out.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    body.data.materials.clear()
    body.data.materials.append(out)


# ── 骨架與權重 ───────────────────────────────────────────────────────────────

def build_armature(body, joints: dict, height: float, weapon_length: float):
    arm_data = bpy.data.armatures.new(f"{body.name}Rig")
    rig = bpy.data.objects.new(f"{body.name}Rig", arm_data)
    bpy.context.scene.collection.objects.link(rig)
    select_only([rig], rig)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones

    def p(name, side=1.0):
        x, z = joints[name]
        return Vector((x * side * height, 0.0, z * height))

    def bone(name, head, tail, parent=None):
        b = eb.new(name)
        b.head, b.tail = head, tail
        if parent is not None:
            b.parent = eb[parent]
            b.use_connect = (b.head - eb[parent].tail).length < 1e-4
        return b

    bone("pelvis", p("pelvis"), p("spine"))
    bone("spine", p("spine"), p("chest"), "pelvis")
    bone("chest", p("chest"), p("neck"), "spine")
    bone("neck", p("neck"), p("head"), "chest")
    bone("head", p("head"), p("head_top"), "neck")
    for suffix, side in (("L", 1.0), ("R", -1.0)):
        bone(f"clavicle.{suffix}", p("neck") + Vector((0.02 * side * height, 0, -0.05 * height)), p("shoulder", side), "chest")
        bone(f"upper_arm.{suffix}", p("shoulder", side), p("elbow", side), f"clavicle.{suffix}")
        bone(f"forearm.{suffix}", p("elbow", side), p("wrist", side), f"upper_arm.{suffix}")
        bone(f"hand.{suffix}", p("wrist", side), p("hand_tip", side), f"forearm.{suffix}")
        bone(f"thigh.{suffix}", p("hip", side), p("knee", side), "pelvis")
        bone(f"shin.{suffix}", p("knee", side), p("ankle", side), f"thigh.{suffix}")
        bone(f"foot.{suffix}", p("ankle", side), p("ankle", side) + Vector((0, -0.08 * height, -0.05 * height)), f"shin.{suffix}")
    weapon = bone("weapon", p("hand_tip", -1.0), p("hand_tip", -1.0) + Vector((0.0, 0.0, -weapon_length * height)))
    weapon.use_deform = False  # 兵器是獨立骨頭（可離手飛出），不參與蒙皮
    bpy.ops.object.mode_set(mode="OBJECT")
    select_only([body, rig], rig)
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    unweighted = sum(1 for v in body.data.vertices if not any(g.weight > 1e-3 for g in v.groups))
    print(f"bone heat unweighted: {unweighted} / {len(body.data.vertices)}")
    if unweighted > len(body.data.vertices) * 0.2:
        distance_weights(body, rig)
    else:
        fix_unweighted(body, rig)
    return rig


def _segment_distances(co, bones):
    out = np.empty((len(co), len(bones)))
    for j, bone in enumerate(bones):
        a = np.array(bone.head_local[:])
        ab = np.array(bone.tail_local[:]) - a
        t = np.clip(((co - a) @ ab) / max(float(ab @ ab), 1e-9), 0.0, 1.0)
        out[:, j] = np.linalg.norm(co - (a + np.outer(t, ab)), axis=1)
    return out


def distance_weights(body, rig, power: float = 4.0):
    """bone heat 失敗時的退路：只在「最近骨頭＋父骨＋子骨」之間做反距離加權。"""
    co = np.array([v.co[:] for v in body.data.vertices])
    bones = [b for b in rig.data.bones if b.use_deform]
    index = {b.name: j for j, b in enumerate(bones)}
    distances = _segment_distances(co, bones)
    neighbours = []
    for bone in bones:
        allowed = {index[bone.name]}
        if bone.parent is not None and bone.parent.name in index:
            allowed.add(index[bone.parent.name])
        allowed.update(index[c.name] for c in bone.children if c.name in index)
        neighbours.append(sorted(allowed))
    for group in list(body.vertex_groups):
        body.vertex_groups.remove(group)
    groups = [body.vertex_groups.new(name=b.name) for b in bones]
    nearest = np.argmin(distances, axis=1)
    for i in range(len(co)):
        allowed = neighbours[nearest[i]]
        w = 1.0 / np.power(distances[i, allowed] + 0.018, power)
        w /= w.sum()
        for j, weight in zip(allowed, w):
            if weight > 0.01:
                groups[j].add([i], float(weight), "REPLACE")


def fix_unweighted(body, rig):
    bones = [b for b in rig.data.bones if b.use_deform]
    groups = {g.name: g for g in body.vertex_groups}
    for b in bones:
        if b.name not in groups:
            groups[b.name] = body.vertex_groups.new(name=b.name)
    targets = [v for v in body.data.vertices if not any(g.weight > 1e-3 for g in v.groups)]
    if not targets:
        return
    distances = _segment_distances(np.array([v.co[:] for v in targets]), bones)
    for v, row in zip(targets, distances):
        groups[bones[int(np.argmin(row))].name].add([v.index], 1.0, "REPLACE")


# ── 兵器 ─────────────────────────────────────────────────────────────────────

def build_weapon(rig, kind: str, length: float, height: float):
    """分件方塊組成的兵器，綁在 weapon 骨頭上。jian＝細直劍；dao＝寬刃刀。"""
    def part(name, size, location, color, metallic):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = size
        mat = bpy.data.materials.new(name + "Mat")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Metallic"].default_value = metallic
        bsdf.inputs["Roughness"].default_value = 0.35
        obj.data.materials.append(mat)
        return obj

    bone = rig.data.bones["weapon"]
    grip = bone.head_local
    down = Vector((0.0, 0.0, -1.0))
    h = height
    blade_w = 0.026 if kind == "jian" else 0.05
    pieces = [
        part("Grip", (0.022 * h, 0.022 * h, 0.075 * h), grip, (0.18, 0.11, 0.06), 0.0),
        part("Guard", (0.09 * h, 0.03 * h, 0.018 * h), grip + down * 0.045 * h, (0.62, 0.5, 0.25), 0.8),
        part("Blade", (blade_w * h, 0.008 * h, (length - 0.05) * h), grip + down * (0.05 + (length - 0.05) * 0.5) * h, (0.78, 0.82, 0.86), 0.85),
    ]
    select_only(pieces, pieces[0])
    bpy.ops.object.join()
    weapon = bpy.context.active_object
    weapon.name = "Weapon"
    select_only([weapon], weapon)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    weapon.parent = rig
    weapon.parent_type = "BONE"
    weapon.parent_bone = "weapon"
    # 綁骨子物件以「骨頭尾端＋骨頭方向」為原點：反矩陣要含骨頭旋轉
    weapon.matrix_parent_inverse = (rig.matrix_world @ bone.matrix_local @ Matrix.Translation((0.0, bone.length, 0.0))).inverted()
    return weapon


# ── 姿勢與動作 ───────────────────────────────────────────────────────────────

def aim(rig, bone_name: str, direction):
    pb = rig.pose.bones[bone_name]
    bpy.context.view_layer.update()
    m = pb.matrix.copy()
    current = (m.to_3x3() @ Vector((0.0, 1.0, 0.0))).normalized()
    rot = current.rotation_difference(Vector(direction).normalized()).to_matrix().to_4x4()
    head = m.translation.copy()
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def place_weapon(rig, spec, height: float):
    pb = rig.pose.bones["weapon"]
    if spec == "hand":
        hand = rig.pose.bones["hand.R"]
        head, direction = hand.tail.copy(), (hand.tail - hand.head).normalized()
    else:
        head, direction = Vector(spec[0]) * height, Vector(spec[1]).normalized()
    rest = rig.data.bones["weapon"].matrix_local.to_3x3()
    rot = (rest @ Vector((0.0, 1.0, 0.0))).rotation_difference(direction).to_matrix()
    pb.matrix = Matrix.Translation(head) @ (rot @ rest).to_4x4()
    bpy.context.view_layer.update()


def apply_pose(rig, pose: dict, height: float):
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    offset = pose.get("_pelvis")
    if offset:
        pelvis = rig.pose.bones["pelvis"]
        pelvis.matrix = Matrix.Translation(Vector(offset) * height) @ pelvis.matrix
        bpy.context.view_layer.update()
    for bone in rig.data.bones:  # 建立順序即父先子後
        if bone.name in pose:
            aim(rig, bone.name, pose[bone.name])
    place_weapon(rig, pose.get("_weapon", "hand"), height)


def build_actions(rig, poses: dict, actions: dict, height: float):
    select_only([rig], rig)
    bpy.ops.object.mode_set(mode="POSE")
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    rig.animation_data_create()
    # Existing strips must not overwrite/reset the pose while the next clip is
    # being authored. Otherwise root offsets accumulate once per earlier clip.
    rig.animation_data.use_nla = False
    bpy.context.scene.render.fps = FPS
    for action_name, spec in actions.items():
        action = bpy.data.actions.new(action_name)
        action.use_fake_user = True
        rig.animation_data.action = action
        for frame, pose_name in spec["keys"]:
            rig.animation_data.action = None
            apply_pose(rig, poses[pose_name], height)
            rig.animation_data.action = action
            for pb in rig.pose.bones:
                pb.keyframe_insert("rotation_quaternion", frame=frame)
                pb.keyframe_insert("location", frame=frame)
        track = rig.animation_data.nla_tracks.new()
        track.name = action_name
        track.strips.new(action_name, 1, action)
        rig.animation_data.action = None
    rig.animation_data.use_nla = True
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.ops.object.mode_set(mode="OBJECT")


def render_previews(folder: Path, rig, poses: dict, height: float):
    folder.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x, scene.render.resolution_y = 512, 640
    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = height * 1.35
    scene.collection.objects.link(cam)
    scene.camera = cam
    for track in rig.animation_data.nla_tracks:
        track.mute = True
    for pose_name, pose in poses.items():
        select_only([rig], rig)
        bpy.ops.object.mode_set(mode="POSE")
        apply_pose(rig, pose, height)
        bpy.ops.object.mode_set(mode="OBJECT")
        for label, loc, rot in (("front", (0, -6, height * 0.5), (math.radians(90), 0, 0)),
                                ("side", (6, 0, height * 0.5), (math.radians(90), 0, math.radians(90)))):
            cam.location, cam.rotation_euler = loc, rot
            scene.render.filepath = str(folder / f"{pose_name}_{label}.png")
            bpy.ops.render.render(write_still=True)
    for track in rig.animation_data.nla_tracks:
        track.mute = False
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("config", type=Path)
    ap.add_argument("--preview", type=Path)
    args = ap.parse_args(argv)
    config_path = args.config.resolve()
    base = config_path.parent
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    height = float(cfg.get("height", 1.8))
    body = import_body(base / cfg["raw"], cfg["id"])
    keep_main_parts(body, 0.02)
    orient_and_normalize(body, cfg.get("front_axis", "-Y"), height)
    remesh(body, float(cfg.get("remesh", 0.003)), height)
    # Optional candidate cleanup for thin AI cloth/hair edges; historical rigs
    # retain their exact default behavior. Run before UV and skinning.
    if int(cfg.get("surface_smooth_iterations", 0)) > 0:
        cleanup = body.modifiers.new("CandidateSurfaceSmooth", "SMOOTH")
        cleanup.factor = float(cfg.get("surface_smooth_factor", .55))
        cleanup.iterations = int(cfg["surface_smooth_iterations"])
        select_only([body], body)
        bpy.ops.object.modifier_apply(modifier=cleanup.name)
    decimate(body, int(cfg.get("faces", 15000)))
    keep_main_parts(body, 0.002)
    body.data.validate(verbose=False)
    body.data.update()
    unwrap(body)
    bake_projection(body, base / cfg["views"], int(cfg.get("texture_size", 2048)), float(cfg.get("projection_visibility_floor", .03)), cfg.get("projection_cloth_band"))
    weapon_cfg = cfg.get("weapon", {"kind": "jian", "length": 0.45})
    rig = build_armature(body, cfg["joints"], height, float(weapon_cfg["length"]))
    if "garment_waist" in cfg:
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from pal_weights import constrain_lower_garment
        constrain_lower_garment(body, height, float(cfg["garment_waist"]))
    if weapon_cfg.get("style") == "pal1":
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from pal_weapons import build_pal_weapon
        weapon = build_pal_weapon(rig, weapon_cfg["kind"], float(weapon_cfg["length"]), height)
    else:
        weapon = build_weapon(rig, weapon_cfg["kind"], float(weapon_cfg["length"]), height)
    build_actions(rig, cfg["poses"], cfg["actions"], height)
    # Auto weights can leave empty deform entries; validate before preview/export.
    body.data.validate(verbose=False)
    if args.preview:
        render_previews(args.preview.resolve(), rig, cfg["poses"], height)
    out = (base / cfg["out"]).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    select_only([body, rig, weapon], rig)
    bpy.ops.export_scene.gltf(
        filepath=str(out), export_format="GLB", use_selection=True,
        export_animations=True, export_animation_mode="ACTIONS",
        export_image_format="JPEG", export_jpeg_quality=88, export_yup=True,
    )
    print(f"exported {out}")


main()
