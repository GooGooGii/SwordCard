"""Remove the blurry generated head while keeping the textured body mesh.

Run with a Python environment containing trimesh. The separate detailed-head
candidate stays editable; this deliberately does not weld or rig the meshes.
"""

from pathlib import Path

import numpy as np
import trimesh


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/models/candidates/li_xiaoyao_crossover_triposr_v2.glb"
OUTPUT = ROOT / "assets/models/candidates/li_xiaoyao_crossover_body_trimmed_v4.glb"
HEAD_CUT_Z = 0.35

mesh = trimesh.load(SOURCE, force="mesh")
keep = np.all(mesh.vertices[mesh.faces, 2] <= HEAD_CUT_Z, axis=1)
mesh.update_faces(keep)
mesh.remove_unreferenced_vertices()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
mesh.export(OUTPUT)
print(f"Trimmed body: {len(mesh.vertices)} vertices, {len(mesh.faces)} faces -> {OUTPUT}")
