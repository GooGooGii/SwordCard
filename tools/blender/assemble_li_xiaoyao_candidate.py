"""Assemble the separately reconstructed head and body into one review GLB.

This is a static two-mesh candidate, not a welded or rigged game character.
Run with a Python environment containing trimesh.
"""

from pathlib import Path

import numpy as np
import trimesh


ROOT = Path(__file__).resolve().parents[2]
MODEL_DIR = ROOT / "assets/models/candidates"
BODY = MODEL_DIR / "li_xiaoyao_crossover_body_trimmed_v4.glb"
HEAD = MODEL_DIR / "li_xiaoyao_crossover_head_triposr_v1.glb"
OUTPUT = MODEL_DIR / "li_xiaoyao_crossover_composite_with_sword_v2.glb"

# Matches the relative transforms validated in character_3d_candidate.gd.
HEAD_SCALE = 0.54 / 2.2
HEAD_OFFSET = (-0.02 / 2.2, 0.0, (1.91 - 1.1) / 2.2)

body = trimesh.load(BODY, force="mesh")
head = trimesh.load(HEAD, force="mesh")
head.apply_scale(HEAD_SCALE)
head.apply_translation(HEAD_OFFSET)

scene = trimesh.Scene()
scene.add_geometry(body, node_name="Body", geom_name="Body")
scene.add_geometry(head, node_name="DetailedHead", geom_name="DetailedHead")


def finish(mesh: trimesh.Trimesh, name: str, color: tuple[int, int, int], metallic: float) -> None:
    material = trimesh.visual.material.PBRMaterial(
        name=name,
        baseColorFactor=[*color, 255],
        metallicFactor=metallic,
        roughnessFactor=0.32 if metallic else 0.7,
    )
    mesh.visual = trimesh.visual.TextureVisuals(material=material)
    scene.add_geometry(mesh, node_name=name, geom_name=name)


def sword_transform(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    # Downward, slightly to the player's right, as in the selected artwork.
    transform = trimesh.transformations.translation_matrix([-0.035, -0.225, 0.055])
    transform @= trimesh.transformations.rotation_matrix(np.radians(-23.0), [1, 0, 0])
    mesh.apply_transform(transform)
    return mesh


# A separate prop is preferable to fusing a blade into the character body.
# Dimensions are in TripoSR's normalized model space (the Godot review scales 2.2x).
sections = [(0.0, 0.017), (-0.32, 0.014), (-0.46, 0.0)]
blade_vertices = []
for z, width in sections:
    blade_vertices.extend(
        [[-0.006, 0.0, z], [0.0, width, z], [0.006, 0.0, z], [0.0, -width, z]]
    )
blade_faces = []
for ring in range(len(sections) - 1):
    for edge in range(4):
        a = ring * 4 + edge
        b = ring * 4 + (edge + 1) % 4
        c = (ring + 1) * 4 + edge
        d = (ring + 1) * 4 + (edge + 1) % 4
        blade_faces.extend([[a, b, d], [a, d, c]])
blade_faces.extend([[0, 3, 2], [0, 2, 1]])
blade = trimesh.Trimesh(vertices=blade_vertices, faces=blade_faces, process=False)
finish(sword_transform(blade), "SilverJianBlade", (190, 204, 208), 0.8)

guard = trimesh.creation.box(extents=[0.018, 0.12, 0.017])
guard.apply_translation([0, 0, 0.014])
finish(sword_transform(guard), "OrnateGoldGuard", (156, 116, 49), 0.75)

grip = trimesh.creation.cylinder(radius=0.009, height=0.105, sections=16)
grip.apply_translation([0, 0, 0.075])
finish(sword_transform(grip), "DarkSwordGrip", (43, 28, 26), 0.15)

for index, z in enumerate((0.037, 0.065, 0.093, 0.118)):
    ring = trimesh.creation.cylinder(radius=0.011, height=0.004, sections=16)
    ring.apply_translation([0, 0, z])
    finish(sword_transform(ring), f"GoldGripRing{index}", (174, 138, 70), 0.75)

pommel = trimesh.creation.icosphere(subdivisions=2, radius=0.018)
pommel.apply_scale([0.8, 0.8, 1.2])
pommel.apply_translation([0, 0, 0.137])
finish(sword_transform(pommel), "GoldPommel", (174, 132, 58), 0.75)

for side, y in (("Left", -0.061), ("Right", 0.061)):
    curl = trimesh.creation.icosphere(subdivisions=2, radius=0.013)
    curl.apply_translation([0, y, 0.028])
    finish(sword_transform(curl), f"GoldGuardCurl{side}", (176, 129, 55), 0.75)

gem = trimesh.creation.icosphere(subdivisions=2, radius=0.014)
gem.apply_scale([0.45, 1.0, 1.25])
gem.apply_translation([-0.014, 0, 0.014])
finish(sword_transform(gem), "BlueGuardGem", (42, 109, 144), 0.25)

scene.export(OUTPUT)
print(f"Composite candidate GLB: {OUTPUT}")
