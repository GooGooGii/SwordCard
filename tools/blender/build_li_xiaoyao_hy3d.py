"""Hunyuan3D-2mv 形體 → 遊戲用李逍遙模型：清碎塊、減面、四視角投影貼圖、骨架、佩劍、六姿勢。

blender --background --python tools/blender/build_li_xiaoyao_hy3d.py -- <raw.glb> <views_dir> <out.glb>
        [--faces 30000] [--tex 2048] [--front -Y] [--preview <png 資料夾>]

- raw.glb：tools/comfyui/hunyuan3d_mv.py 的輸出（只有形體）
- views_dir：front/left/back/right.png（白底）與 *_rgba.png（去背，用來量人物外框）
- --front：原始網格「臉朝向」的軸（匯入 Blender 後的座標），轉成 Blender 慣例 -Y（glTF/Godot 的 +Z）
- 角色座標：腳底 z=0、身高 HEIGHT、臉朝 -Y、+X＝角色自己的左邊
- 動作（action）名稱＝BattleStage3D 的姿勢名：idle / attack / block / cast / low_hp / downed
"""
import argparse
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HEIGHT = 1.8
VIEWS = ("front", "left", "back", "right")
FEET_BAND = 0.04  # 腳＝最底下 4% 身高

# 關節：（x, z）以身高為單位，x 相對兩腳中點，+x＝角色左側。量自 front 參考圖（A-pose）。
JOINTS = {
    "pelvis": (0.0, 0.50), "spine": (0.0, 0.60), "chest": (0.0, 0.70), "neck": (0.0, 0.80),
    "head": (0.0, 0.845), "head_top": (0.0, 0.95),
    "shoulder": (0.115, 0.755), "elbow": (0.18, 0.63), "wrist": (0.215, 0.53), "hand_tip": (0.225, 0.465),
    "hip": (0.06, 0.50), "knee": (0.098, 0.27), "ankle": (0.14, 0.065),
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("raw")
    ap.add_argument("views")
    ap.add_argument("out")
    ap.add_argument("--faces", type=int, default=30000)
    ap.add_argument("--tex", type=int, default=2048)
    ap.add_argument("--front", default="-Y", choices=["-Y", "+Y", "-X", "+X"])
    ap.add_argument("--preview", default="")
    ap.add_argument("--remesh", type=float, default=0.003, help="體素大小（×身高），0＝不重建")
    return ap.parse_args(argv)


def select_only(objects, active):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = active


def import_body(path: str) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
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
    body.name = "LiXiaoyao"
    body.data.materials.clear()
    return body


def keep_main_parts(body, min_fraction=0.02):
    """marching cubes 常留下漂浮碎塊：只留頂點數 ≥ 總數 2% 的連通塊。"""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    # glTF 匯入可能每個三角形各自一份頂點：先焊接，否則整個模型都會被當成碎塊
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)  # 法線一律朝外（可見度光線從表面外側出發）
    bm.verts.ensure_lookup_table()
    bm.verts.index_update()
    seen = set()
    islands = []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack = [v]
        island = []
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


def orient_and_normalize(body, front_axis: str):
    # 人物最長的軸是身高：若不是 Z（例如 TripoSR 輸出），先轉成 Z 朝上
    co = np.array([v.co[:] for v in body.data.vertices])
    tallest = int(np.argmax(co.max(axis=0) - co.min(axis=0)))
    if tallest == 0:
        body.data.transform(Matrix.Rotation(math.pi / 2, 4, "Y"))
    elif tallest == 1:
        body.data.transform(Matrix.Rotation(-math.pi / 2, 4, "X"))
    turn = {"-Y": 0.0, "+Y": math.pi, "-X": -math.pi / 2, "+X": math.pi / 2}[front_axis]
    body.data.transform(Matrix.Rotation(turn, 4, "Z"))
    co = np.array([v.co[:] for v in body.data.vertices])
    print(f"tallest axis={'XYZ'[tallest]}")
    zmin, zmax = co[:, 2].min(), co[:, 2].max()
    scale = HEIGHT / (zmax - zmin)
    co = (co - [0.0, 0.0, zmin]) * scale
    # 身體中心：x 用腳（z<5%）的平均，避開單側長披巾；y 用骨盆高度切片的平均
    feet = co[co[:, 2] < HEIGHT * 0.05]
    pelvis = co[np.abs(co[:, 2] - HEIGHT * 0.5) < HEIGHT * 0.03]
    co -= [feet[:, 0].mean(), pelvis[:, 1].mean(), 0.0]
    for vertex, new in zip(body.data.vertices, co):
        vertex.co = new
    body.data.update()


def remesh(body, voxel: float):
    """Hunyuan 的 surface-net 網格有大量非流形邊（實測 14 萬條），減面會卡在一半：
    先體素重建成乾淨的流形網格。voxel 以身高為單位。"""
    if voxel <= 0.0:
        return
    mod = body.modifiers.new("Remesh", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = voxel * HEIGHT
    mod.adaptivity = 0.0
    select_only([body], body)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    print(f"remesh voxel={voxel * HEIGHT:.4f} -> faces {len(body.data.polygons)}")


def decimate(body, faces: int):
    current = len(body.data.polygons)
    if current > faces:
        mod = body.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = faces / current
        select_only([body], body)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    body.data.validate(verbose=False)  # 清掉減面後的退化面（否則 glTF 匯出警告 not valid）
    select_only([body], body)
    bpy.ops.object.shade_smooth()
    print(f"faces {current} -> {len(body.data.polygons)}")


def unwrap(body):
    select_only([body], body)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")


def figure_box(path: Path):
    """去背圖的人物上下緣與兩腳中點（0..1，影像座標 y 向下）。
    水平對位用腳而非外框：外框含單側長披巾，生成的披巾形狀和參考圖不會完全一樣。"""
    image = bpy.data.images.load(str(path))
    w, h = image.size
    alpha = np.array(image.pixels[:]).reshape(h, w, 4)[::-1, :, 3]  # Blender 像素由下往上
    ys, xs = np.nonzero(alpha > 0.06)
    bpy.data.images.remove(image)
    top, bottom = ys.min() / h, (ys.max() + 1) / h
    feet = xs[ys > ys.max() - (ys.max() - ys.min()) * FEET_BAND]
    return top, bottom, (feet.mean() + 0.5) / w


def math_node(nodes, op, a=None, b=None, links=None, value_b=None):
    node = nodes.new("ShaderNodeMath")
    node.operation = op
    if a is not None:
        links.new(a, node.inputs[0])
    if b is not None:
        links.new(b, node.inputs[1])
    if value_b is not None:
        node.inputs[1].default_value = value_b
    return node.outputs[0]


VIEW_DIRECTIONS = {  # 從模型指向各視角鏡頭的方向
    "front": Vector((0.0, -1.0, 0.0)), "left": Vector((1.0, 0.0, 0.0)),
    "back": Vector((0.0, 1.0, 0.0)), "right": Vector((-1.0, 0.0, 0.0)),
}
VIS_CHANNEL = {"front": "R", "left": "G", "back": "B", "right": "A"}


def bake_visibility(body):
    """每個頂點對四個正交視角的可見度（被自己身體擋住＝0）存成 RGBA 顏色屬性 vis。"""
    from mathutils.bvhtree import BVHTree
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bvh = BVHTree.FromObject(body, depsgraph)
    attr = body.data.color_attributes.new("vis", "FLOAT_COLOR", "POINT")
    hidden = 0
    for vertex in body.data.vertices:
        channels = []
        for view in VIEWS:
            direction = VIEW_DIRECTIONS[view]
            origin = vertex.co + vertex.normal * 0.004
            occluded = False
            for _attempt in range(4):  # 極近距離打到的是頂點自己的鄰面：略過後繼續往前找
                hit, _normal, _index, distance = bvh.ray_cast(origin, direction)
                if hit is None:
                    break
                if distance > 0.01:
                    occluded = True
                    break
                origin = hit + direction * 0.002
            channels.append(0.0 if occluded else 1.0)
        hidden += channels.count(0.0)
        attr.data[vertex.index].color = channels
    print(f"visibility: {hidden} occluded vertex-views / {len(body.data.vertices) * 4}")


def bake_projection(body, views_dir: Path, size: int) -> bpy.types.Image:
    """四張參考圖依朝向投影（法線加權 × 可見度），烘焙成 UV 貼圖。"""
    bake_visibility(body)
    co = np.array([v.co[:] for v in body.data.vertices])
    zmin, zmax = co[:, 2].min(), co[:, 2].max()
    feet = co[co[:, 2] < zmin + (zmax - zmin) * FEET_BAND]
    feet_center = (feet[:, 0].mean(), feet[:, 1].mean())
    # 每個視角：水平軸（世界座標分量、正向是否等於畫面右方）、法線權重軸
    specs = {
        "front": (0, +1, (1, -1)),   # 鏡頭在 -Y：畫面右＝+X；法線 -Y 面
        "back": (0, -1, (1, +1)),    # 鏡頭在 +Y：畫面右＝-X
        "left": (1, +1, (0, +1)),    # 鏡頭在 +X（角色左側）：畫面右＝+Y
        "right": (1, -1, (0, -1)),   # 鏡頭在 -X：畫面右＝-Y
    }
    mat = bpy.data.materials.new("ProjectionBake")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    coord = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coord.outputs["Object"], sep.inputs[0])
    geo = nodes.new("ShaderNodeNewGeometry")
    nsep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geo.outputs["Normal"], nsep.inputs[0])
    vis = nodes.new("ShaderNodeVertexColor")
    vis.layer_name = "vis"
    vis_rgb = nodes.new("ShaderNodeSeparateColor")
    links.new(vis.outputs["Color"], vis_rgb.inputs[0])
    vis_socket = {"R": vis_rgb.outputs[0], "G": vis_rgb.outputs[1], "B": vis_rgb.outputs[2], "A": vis.outputs["Alpha"]}
    color_sum = None
    weight_sum = None
    for view, (axis, sign, (n_axis, n_sign)) in specs.items():
        top, bottom, feet_u = figure_box(views_dir / f"{view}_rgba.png")
        # 影像是正方形：水平與垂直同一比例（由身高決定）
        scale_v = (bottom - top) / (zmax - zmin)
        offset_v = (1.0 - bottom) - zmin * scale_v
        # 水平：兩腳中點對齊（sign<0 時左右相反）
        scale_u = scale_v * sign
        offset_u = feet_u - feet_center[axis] * scale_u
        u = math_node(nodes, "MULTIPLY_ADD", sep.outputs[axis], None, links)
        u.node.inputs[1].default_value = scale_u
        u.node.inputs[2].default_value = offset_u
        v = math_node(nodes, "MULTIPLY_ADD", sep.outputs[2], None, links)
        v.node.inputs[1].default_value = scale_v
        v.node.inputs[2].default_value = offset_v
        uv = nodes.new("ShaderNodeCombineXYZ")
        links.new(u, uv.inputs[0])
        links.new(v, uv.inputs[1])
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(views_dir / f"{view}.png"))
        tex.extension = "EXTEND"
        links.new(uv.outputs[0], tex.inputs[0])
        facing = math_node(nodes, "MULTIPLY", nsep.outputs[n_axis], None, links, value_b=float(n_sign))
        facing = math_node(nodes, "MAXIMUM", facing, None, links, value_b=0.0)
        weight = math_node(nodes, "POWER", facing, None, links, value_b=6.0)
        # 被擋住的視角只留 3% 權重：四面都擋住的凹處（腋下）仍有顏色可混，不會烘成黑色
        visible = math_node(nodes, "ADD", vis_socket[VIS_CHANNEL[view]], None, links, value_b=0.03)
        weight = math_node(nodes, "MULTIPLY", weight, visible, links)
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
            weight_sum = math_node(nodes, "ADD", weight_sum, weight, links)
    weight_sum = math_node(nodes, "MAXIMUM", weight_sum, None, links, value_b=1e-4)
    weight_vec = nodes.new("ShaderNodeCombineXYZ")
    for i in range(3):
        links.new(weight_sum, weight_vec.inputs[i])
    divide = nodes.new("ShaderNodeVectorMath")
    divide.operation = "DIVIDE"
    links.new(color_sum, divide.inputs[0])
    links.new(weight_vec.outputs[0], divide.inputs[1])
    emission = nodes.new("ShaderNodeEmission")
    links.new(divide.outputs[0], emission.inputs["Color"])
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(emission.outputs[0], out.inputs["Surface"])
    baked = bpy.data.images.new("LiXiaoyaoAlbedo", size, size, alpha=False)
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
    body.data.color_attributes.remove(body.data.color_attributes["vis"])  # 只供烘焙，不匯出
    return baked


def finish_material(body, baked: bpy.types.Image):
    mat = bpy.data.materials.new("LiXiaoyaoSkin")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.85
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = baked
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    body.data.materials.clear()
    body.data.materials.append(mat)


def build_armature(body) -> bpy.types.Object:
    arm_data = bpy.data.armatures.new("LiXiaoyaoRig")
    rig = bpy.data.objects.new("LiXiaoyaoRig", arm_data)
    bpy.context.scene.collection.objects.link(rig)
    select_only([rig], rig)
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones

    def p(name, side=1.0, y=0.0):
        x, z = JOINTS[name]
        return Vector((x * side * HEIGHT, y, z * HEIGHT))

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
        bone(f"clavicle.{suffix}", p("neck") + Vector((0.02 * side * HEIGHT, 0, -0.05 * HEIGHT)), p("shoulder", side), "chest")
        bone(f"upper_arm.{suffix}", p("shoulder", side), p("elbow", side), f"clavicle.{suffix}")
        bone(f"forearm.{suffix}", p("elbow", side), p("wrist", side), f"upper_arm.{suffix}")
        bone(f"hand.{suffix}", p("wrist", side), p("hand_tip", side), f"forearm.{suffix}")
        bone(f"thigh.{suffix}", p("hip", side), p("knee", side), "pelvis")
        bone(f"shin.{suffix}", p("knee", side), p("ankle", side), f"thigh.{suffix}")
        bone(f"foot.{suffix}", p("ankle", side), p("ankle", side) + Vector((0, -0.08 * HEIGHT, -0.05 * HEIGHT)), f"shin.{suffix}")
    # 御劍：劍是獨立骨頭（無父骨、不參與蒙皮），每個姿勢各自擺放；靜止時握在右手、劍尖朝下
    sword = bone("sword", p("hand_tip", -1.0), p("hand_tip", -1.0) + Vector((0.0, 0.0, -SWORD_LENGTH * HEIGHT)))
    sword.use_deform = False
    bpy.ops.object.mode_set(mode="OBJECT")
    # 自動權重（bone heat）；失敗的頂點改綁最近的骨頭
    select_only([body, rig], rig)
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    unweighted = sum(1 for v in body.data.vertices if not any(g.weight > 1e-3 for g in v.groups))
    if unweighted > len(body.data.vertices) * 0.2:
        # bone heat 對重建後的網格常「找不到解」（全部頂點沒權重）：改用距離加權
        print(f"bone heat failed for {unweighted} vertices; using distance weights")
        distance_weights(body, rig)
    else:
        fix_unweighted(body, rig)
    rebind_cloth(body, rig)
    return rig


def distance_weights(body, rig, power: float = 4.0):
    """距離加權，但每個頂點只在「最近骨頭＋其父骨＋其子骨」之間分配：
    袖子（最近是 upper_arm）不會分到 chest，腋下（最近是 chest）不會分到 upper_arm，
    舉手時袖子才不會被扯成一片片的板子。"""
    co = np.array([v.co[:] for v in body.data.vertices])
    bones = [b for b in rig.data.bones if b.use_deform]
    index = {b.name: j for j, b in enumerate(bones)}
    distances = np.empty((len(co), len(bones)))
    for j, bone in enumerate(bones):
        a = np.array(bone.head_local[:])
        ab = np.array(bone.tail_local[:]) - a
        t = np.clip(((co - a) @ ab) / max(float(ab @ ab), 1e-9), 0.0, 1.0)
        distances[:, j] = np.linalg.norm(co - (a + np.outer(t, ab)), axis=1)
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
        w = 1.0 / np.power(distances[i, allowed] + 0.01 * HEIGHT, power)
        w /= w.sum()
        for j, weight in zip(allowed, w):
            if weight > 0.01:
                groups[j].add([i], float(weight), "REPLACE")


ARM_BONES = ("upper_arm", "forearm", "hand")
# ×身高：離該段手臂骨頭超過此距離就當披巾。上臂是燈籠袖（太小會把袖子切下來）；
# 前臂與手是窄袖口＋護腕，收緊才能把垂在手邊的披巾分出來（否則手一動披巾被扯成板片）
CLOTH_ARM_DISTANCE = {"upper_arm": 0.075, "forearm": 0.05, "hand": 0.045}


def _segment_distance(point, bone) -> float:
    a, b = bone.head_local, bone.tail_local
    ab = b - a
    t = max(0.0, min(1.0, (point - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (point - (a + ab * t)).length


def rebind_cloth(body, rig):
    """bone heat 會把垂在手邊的長披巾綁到手臂，一舉手整片披巾甩出去：
    離該側手臂骨頭超過 CLOTH_ARM_DISTANCE 的頂點，手臂權重改給軀幹（高處 chest、低處 spine）。"""
    names = {g.index: g.name for g in body.vertex_groups}
    groups = {g.name: g for g in body.vertex_groups}
    moved = 0
    for vertex in body.data.vertices:
        for side in ("L", "R"):
            arm_names = [f"{n}.{side}" for n in ARM_BONES]
            arm_weight = sum(g.weight for g in vertex.groups if names[g.group] in arm_names)
            if arm_weight <= 1e-4:
                continue
            if any(_segment_distance(vertex.co, rig.data.bones[f"{n}.{side}"]) <= CLOTH_ARM_DISTANCE[n] * HEIGHT
                   for n in ARM_BONES):
                continue
            for name in arm_names:
                groups[name].remove([vertex.index])
            # 一律給 chest（手臂鏈的上層）：給 spine 的話彎腰時披巾下半和黏在手邊的部分會被扯開
            groups["chest"].add([vertex.index], arm_weight, "ADD")
            moved += 1
    print(f"cloth vertices rebound to torso: {moved}")


def fix_unweighted(body, rig):
    segments = {b.name: (b.head_local.copy(), b.tail_local.copy()) for b in rig.data.bones if b.use_deform}
    groups = {g.name: g for g in body.vertex_groups}
    for name in segments:
        if name not in groups:
            groups[name] = body.vertex_groups.new(name=name)
    fixed = 0
    for vertex in body.data.vertices:
        if any(g.weight > 1e-3 for g in vertex.groups):
            continue
        best, best_d = None, 1e9
        for name, (a, b) in segments.items():
            ab = b - a
            t = max(0.0, min(1.0, (vertex.co - a).dot(ab) / max(ab.length_squared, 1e-9)))
            d = (vertex.co - (a + ab * t)).length
            if d < best_d:
                best, best_d = name, d
        groups[best].add([vertex.index], 1.0, "REPLACE")
        fixed += 1
    print(f"unweighted vertices fixed: {fixed} / {len(body.data.vertices)}")


def build_sword(rig) -> bpy.types.Object:
    """樸素長劍（分件方塊），綁在獨立的 sword 骨頭上（御劍：可離手飛出）。"""
    def part(name, size, location, color):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
        obj = bpy.context.active_object
        obj.name = name
        obj.scale = size
        mat = bpy.data.materials.new(name + "Mat")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.8 if name != "SwordGrip" else 0.0
        bsdf.inputs["Roughness"].default_value = 0.35
        obj.data.materials.append(mat)
        return obj

    hand = rig.data.bones["sword"]
    grip_center = hand.head_local
    down = Vector((0.0, 0.0, -1.0))
    h = HEIGHT
    pieces = [
        part("SwordGrip", (0.022 * h, 0.022 * h, 0.075 * h), grip_center, (0.18, 0.11, 0.06)),
        part("SwordGuard", (0.09 * h, 0.03 * h, 0.018 * h), grip_center + down * 0.045 * h, (0.75, 0.58, 0.22)),
        part("SwordBlade", (0.026 * h, 0.008 * h, (SWORD_LENGTH - 0.05) * h), grip_center + down * (0.05 + (SWORD_LENGTH - 0.05) * 0.5) * h, (0.78, 0.82, 0.86)),
    ]
    select_only(pieces, pieces[0])
    bpy.ops.object.join()
    sword = bpy.context.active_object
    sword.name = "Sword"
    select_only([sword], sword)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    sword.parent = rig
    sword.parent_type = "BONE"
    sword.parent_bone = "sword"
    # 綁骨的子物件以「骨頭尾端＋骨頭方向」為原點：反矩陣要含骨頭旋轉，不然劍會被轉歪
    bone_tail = rig.matrix_world @ hand.matrix_local @ Matrix.Translation((0.0, hand.length, 0.0))
    sword.matrix_parent_inverse = bone_tail.inverted()
    return sword


# 姿勢：骨頭 → 世界方向（角色臉朝 -Y、+X＝角色左）。依骨架階層順序套用。
# 御劍流：AI 生成網格的手和衣擺黏在一起，手臂大幅度動作會把表面扯成板片，
# 所以手臂只做待命那種小幅度變化，姿勢靠身體前傾／下蹲／抬頭＋劍的位置表現。
_IDLE_ARMS = {
    "upper_arm.L": (0.35, 0.0, -0.94), "forearm.L": (0.25, -0.15, -0.96),
    "upper_arm.R": (-0.35, 0.0, -0.94), "forearm.R": (-0.2, -0.2, -0.96), "hand.R": (-0.05, -0.15, -0.99),
}
POSES = {
    "idle": dict(_IDLE_ARMS),
    "attack": {**_IDLE_ARMS,
        "spine": (0.0, -0.15, 0.99), "chest": (0.05, -0.2, 0.98), "head": (0.0, -0.1, 0.99),
        "forearm.L": (0.2, -0.45, -0.87),  # 左手劍指；右手（披巾那側）維持待命，避免拉扯
        "thigh.R": (-0.1, -0.3, -0.95), "thigh.L": (0.12, 0.25, -0.96),
    },
    "block": {**_IDLE_ARMS,
        "chest": (0.0, 0.08, 1.0),
        "forearm.L": (0.2, -0.45, -0.87),
        "thigh.L": (0.18, 0.1, -0.98), "thigh.R": (-0.18, -0.1, -0.98),
    },
    "cast": {**_IDLE_ARMS,
        "head": (0.0, 0.15, 0.99),  # 抬頭看頭頂的劍
        "forearm.L": (0.15, -0.5, -0.85), "hand.L": (0.1, -0.7, -0.7),
    },
    "low_hp": {**_IDLE_ARMS,
        # 上身只微彎（彎太多披巾會被胸口帶著甩出去），命危感靠低頭＋屈膝
        "spine": (0.0, -0.15, 0.99), "chest": (0.03, -0.25, 0.97), "neck": (0.0, -0.6, 0.8), "head": (0.0, -0.8, 0.6),
        "thigh.L": (0.1, -0.5, -0.86), "shin.L": (0.05, 0.45, -0.89),
        "thigh.R": (-0.1, -0.4, -0.92), "shin.R": (-0.05, 0.4, -0.92),
    },
    "downed": {  # 手臂維持靜止姿勢跟著身體躺下（另外擺手臂會把右手邊的披巾扯開）
        "head": (0.0, 0.25, 0.97),
    },
}
SWORD_LENGTH = 0.45  # ×身高（握柄到劍尖）
# 劍：「hand」＝握在右手；否則（握柄位置 ×身高, 劍尖方向）
SWORD_POSES = {
    "idle": "hand",
    "attack": ((-0.05, -0.75, 0.66), (0.0, -1.0, 0.02)),   # 飛向前方敵人
    "block": ((0.22, -0.28, 0.72), (-1.0, 0.0, 0.05)),     # 橫在胸前
    "cast": ((0.0, -0.05, 1.12), (0.0, 0.0, 1.0)),         # 懸在頭頂、劍尖朝天
    "low_hp": ((-0.2, -0.12, 0.42), (0.05, 0.0, -1.0)),    # 插地撐住
    "downed": ((-0.35, 0.1, 0.02), (0.0, 1.0, 0.0)),       # 落在身旁
}
DOWNED_ROOT_ROTATION = (-80.0, 0.0, 15.0)  # 骨盆繞世界 X 往後倒（臉朝上），稍偏一側
DOWNED_ROOT_DROP = 0.40  # 骨盆下降（×身高），讓身體貼地


def place_sword(rig, spec):
    pb = rig.pose.bones["sword"]
    if spec == "hand":
        hand = rig.pose.bones["hand.R"]
        head, direction = hand.tail.copy(), (hand.tail - hand.head).normalized()
    else:
        head, direction = Vector(spec[0]) * HEIGHT, Vector(spec[1]).normalized()
    rest = rig.data.bones["sword"].matrix_local.to_3x3()
    rot = (rest @ Vector((0.0, 1.0, 0.0))).rotation_difference(direction).to_matrix()
    pb.matrix = Matrix.Translation(head) @ (rot @ rest).to_4x4()
    bpy.context.view_layer.update()


def aim(rig, bone_name: str, direction):
    pb = rig.pose.bones[bone_name]
    bpy.context.view_layer.update()
    m = pb.matrix.copy()
    current = (m.to_3x3() @ Vector((0.0, 1.0, 0.0))).normalized()
    rot = current.rotation_difference(Vector(direction).normalized()).to_matrix().to_4x4()
    head = m.translation.copy()
    pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ m
    bpy.context.view_layer.update()


def build_actions(rig):
    select_only([rig], rig)
    bpy.ops.object.mode_set(mode="POSE")
    order = [b.name for b in rig.data.bones]  # 建立順序即父先子後
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    rig.animation_data_create()
    for pose_name, aims in POSES.items():
        for pb in rig.pose.bones:
            pb.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        if pose_name == "downed":
            pelvis = rig.pose.bones["pelvis"]
            rx, ry, rz = (math.radians(a) for a in DOWNED_ROOT_ROTATION)
            head = pelvis.matrix.translation.copy()
            rot = (Matrix.Rotation(rz, 4, "Z") @ Matrix.Rotation(rx, 4, "X") @ Matrix.Rotation(ry, 4, "Y"))
            drop = Matrix.Translation((0.0, 0.0, -DOWNED_ROOT_DROP * HEIGHT))
            pelvis.matrix = drop @ Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pelvis.matrix
            bpy.context.view_layer.update()
        for bone_name in order:
            if bone_name in aims:
                aim(rig, bone_name, aims[bone_name])
        place_sword(rig, SWORD_POSES[pose_name])
        action = bpy.data.actions.new(pose_name)
        action.use_fake_user = True
        rig.animation_data.action = action
        for pb in rig.pose.bones:  # 兩個相同關鍵影格：避免 Godot 收到長度 0 的動畫
            for frame in (1, 10):
                pb.keyframe_insert("rotation_quaternion", frame=frame)
                pb.keyframe_insert("location", frame=frame)
        track = rig.animation_data.nla_tracks.new()
        track.name = pose_name
        track.strips.new(pose_name, 1, action)
        rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.ops.object.mode_set(mode="OBJECT")


def render_previews(folder: str, objects):
    """各姿勢正面＋側面的快速預覽（Workbench），檢查骨架與貼圖。"""
    out = Path(folder)
    out.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x, scene.render.resolution_y = 512, 640
    cam_data = bpy.data.cameras.new("PreviewCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = HEIGHT * 1.35
    cam = bpy.data.objects.new("PreviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    rig = next(o for o in objects if o.type == "ARMATURE")
    for pose_name in ["rest"] + list(POSES.keys()):
        rig.animation_data.action = bpy.data.actions.get(pose_name) if pose_name != "rest" else None
        for track in rig.animation_data.nla_tracks:
            track.mute = True
        if pose_name == "rest":
            for pb in rig.pose.bones:
                pb.matrix_basis = Matrix.Identity(4)
        scene.frame_set(1)
        for label, loc, rot in (("front", (0, -6, HEIGHT * 0.5), (math.radians(90), 0, 0)),
                                ("side", (6, 0, HEIGHT * 0.5), (math.radians(90), 0, math.radians(90)))):
            cam.location, cam.rotation_euler = loc, rot
            scene.render.filepath = str(out / f"{pose_name}_{label}.png")
            bpy.ops.render.render(write_still=True)
    rig.animation_data.action = None
    for track in rig.animation_data.nla_tracks:
        track.mute = False


def main():
    args = parse_args()
    views = Path(args.views).resolve()  # Blender 的相對路徑以 .blend 為基準，一律轉絕對
    args.out = str(Path(args.out).resolve())
    body = import_body(str(Path(args.raw).resolve()))
    keep_main_parts(body)
    orient_and_normalize(body, args.front)
    remesh(body, args.remesh)
    decimate(body, args.faces)
    keep_main_parts(body, min_fraction=0.002)  # 重建後多孔的披巾末端會留下零碎小島，bone heat 遇到就整個失敗
    unwrap(body)
    baked = bake_projection(body, views, args.tex)
    baked.filepath_raw = str(Path(args.out).with_suffix(".albedo.png"))
    baked.file_format = "PNG"
    baked.save()
    finish_material(body, baked)
    rig = build_armature(body)
    sword = build_sword(rig)
    build_actions(rig)
    if args.preview:
        render_previews(args.preview, [body, rig, sword])
    select_only([body, rig, sword], rig)
    bpy.ops.export_scene.gltf(
        filepath=args.out, export_format="GLB", use_selection=True,
        export_animations=True, export_animation_mode="ACTIONS",
        export_image_format="JPEG", export_jpeg_quality=90, export_yup=True,
    )
    print(f"exported {args.out}")


main()
