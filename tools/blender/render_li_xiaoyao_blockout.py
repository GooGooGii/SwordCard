"""Render the editable Blender blockout for visual review."""

from pathlib import Path

import bpy
from mathutils import Vector


PROJECT = Path(__file__).resolve().parents[2]
SOURCE = PROJECT / "source_art" / "3d" / "li_xiaoyao_blockout.blend"
PREVIEW = PROJECT / "tmp" / "li_xiaoyao_3d_preview.png"

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene

bpy.ops.object.camera_add(location=(3.4, -5.5, 2.7))
camera = bpy.context.object
camera.rotation_euler = (Vector((0.0, 0.0, 1.10)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 3.15
scene.camera = camera

scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.color_type = "MATERIAL"
scene.display.shading.light = "STUDIO"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(PREVIEW)
PREVIEW.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.render.render(write_still=True)
print(f"Rendered {PREVIEW}")
