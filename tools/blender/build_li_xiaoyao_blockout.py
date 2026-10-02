"""Build an editable 3D battle blockout and export it for Godot.

Run with Blender: blender --background --python tools/blender/build_li_xiaoyao_blockout.py
The shapes are intentionally simple. This is a camera/scale/pose test, not final art.
"""

from pathlib import Path

import bpy


PROJECT = Path(__file__).resolve().parents[2]
SOURCE = PROJECT / "source_art" / "3d" / "li_xiaoyao_blockout.blend"
EXPORT = PROJECT / "assets" / "models" / "li_xiaoyao_blockout.glb"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, rgb, metallic=0.0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*rgb, 1.0)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*rgb, 1.0)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = 0.82
    return result


skin = material("warm_skin", (0.73, 0.47, 0.33))
hair = material("black_hair", (0.055, 0.048, 0.045))
shirt = material("cream_tunic", (0.67, 0.62, 0.49))
inner = material("pale_sleeves", (0.81, 0.77, 0.66))
pants = material("dark_trousers", (0.13, 0.13, 0.12))
wrap = material("dark_wraps", (0.20, 0.21, 0.19))
sash = material("muted_blue_sash", (0.24, 0.34, 0.36))
wood = material("sword_grip", (0.30, 0.18, 0.10))
steel = material("sword_steel", (0.63, 0.69, 0.67), 0.55)


def ellipsoid(name, location, scale, mat, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
        obj.location = location
    return obj


def block(name, location, scale, mat, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
        obj.location = location
    return obj


def pivot(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_size = 0.13
    obj.empty_display_type = "PLAIN_AXES"
    obj.parent = parent
    obj.location = location
    return obj


root = pivot("LiXiaoyao")

# PAL1 DOS battle silhouette: long black tied hair, light short top, dark legs.
ellipsoid("torso_inner", (0, 0, 1.26), (0.30, 0.20, 0.40), inner, root)
ellipsoid("short_tunic", (0, 0.01, 1.26), (0.33, 0.23, 0.34), shirt, root)
block("waist_sash", (0, -0.005, 1.02), (0.64, 0.33, 0.10), sash, root)
block("sash_tail", (-0.17, 0.13, 0.77), (0.11, 0.05, 0.44), sash, root)

for side, x in (("Left", -0.18), ("Right", 0.18)):
    leg = pivot(f"{side}LegPivot", (x, 0, 0.88), root)
    ellipsoid(f"{side}Thigh", (0, 0, -0.22), (0.135, 0.14, 0.31), pants, leg)
    ellipsoid(f"{side}Shin", (0, 0, -0.55), (0.105, 0.11, 0.29), pants, leg)
    block(f"{side}ShinWrap", (0, -0.015, -0.60), (0.21, 0.22, 0.10), wrap, leg)
    ellipsoid(f"{side}Shoe", (0, -0.095, -0.80), (0.15, 0.24, 0.08), wrap, leg)

left_arm = pivot("LeftArmPivot", (-0.33, 0, 1.49), root)
right_arm = pivot("RightArmPivot", (0.33, 0, 1.49), root)
for side, arm in (("Left", left_arm), ("Right", right_arm)):
    ellipsoid(f"{side}Sleeve", (0, 0, -0.15), (0.14, 0.15, 0.22), inner, arm)
    ellipsoid(f"{side}Forearm", (0, -0.045, -0.40), (0.115, 0.12, 0.20), skin, arm)
    block(f"{side}WristWrap", (0, -0.055, -0.48), (0.25, 0.25, 0.09), wrap, arm)
    ellipsoid(f"{side}Hand", (0, -0.07, -0.59), (0.105, 0.10, 0.12), skin, arm)

ellipsoid("neck", (0, -0.015, 1.66), (0.11, 0.11, 0.15), skin, root)
ellipsoid("young_adult_face", (0, -0.045, 1.84), (0.195, 0.175, 0.225), skin, root)
ellipsoid("hair_cap", (0, 0.01, 1.995), (0.21, 0.19, 0.14), hair, root)
ellipsoid("topknot", (0, 0.12, 2.115), (0.095, 0.095, 0.10), hair, root)
ellipsoid("long_tied_hair", (0, 0.20, 1.62), (0.085, 0.085, 0.45), hair, root)
block("hair_tie", (0, 0.21, 2.045), (0.15, 0.12, 0.06), sash, root)
for x in (-0.09, 0.09):
    ellipsoid("eye", (x * 0.75, -0.207, 1.865), (0.020, 0.012, 0.023), hair, root)
ellipsoid("nose", (0, -0.222, 1.80), (0.021, 0.025, 0.038), skin, root)

# Sword hangs ready in the right hand; a plain jian rather than a fantasy blade.
block("SwordGrip", (0.10, -0.075, -0.68), (0.07, 0.07, 0.24), wood, right_arm)
block("SwordGuard", (0.16, -0.075, -0.80), (0.27, 0.08, 0.055), steel, right_arm)
blade = block("SwordBlade", (0.31, -0.075, -1.11), (0.065, 0.025, 0.66), steel, right_arm)
blade.rotation_euler[1] = -0.42

# A little asymmetry makes the idle silhouette readable from the battle camera.
left_arm.rotation_euler[1] = -0.15
right_arm.rotation_euler[1] = -0.16

SOURCE.parent.mkdir(parents=True, exist_ok=True)
EXPORT.parent.mkdir(parents=True, exist_ok=True)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
bpy.ops.export_scene.gltf(filepath=str(EXPORT), export_format="GLB", export_animations=False)
print(f"Saved {SOURCE}")
print(f"Exported {EXPORT}")
