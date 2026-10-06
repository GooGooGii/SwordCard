"""Close small reconstruction tunnels in cloth/hair, without editing 2D art.

Usage (ComfyUI Python with trimesh/scipy): input.glb output.glb --steps 3
Output is a new working mesh. Character/world scale is preserved.
"""
import argparse
from pathlib import Path
import numpy as np
import trimesh
from scipy import ndimage

ap = argparse.ArgumentParser()
ap.add_argument('source', type=Path)
ap.add_argument('output', type=Path)
ap.add_argument('--steps', type=int, default=3)
args = ap.parse_args()
mesh = trimesh.load(args.source, force='mesh')
mesh.merge_vertices()
pitch = float(max(mesh.extents)) / 280
vox = mesh.voxelized(pitch)
# Pad the occupancy so closing does not erode geometry touching grid borders.
pad = args.steps + 2
volume = np.pad(vox.matrix, pad)
volume = ndimage.binary_fill_holes(volume)
volume = ndimage.binary_closing(volume, iterations=args.steps)
volume = ndimage.binary_fill_holes(volume)
healed = trimesh.voxel.ops.matrix_to_marching_cubes(volume, pitch=pitch)
healed.apply_translation(vox.translation - pad*pitch)
args.output.parent.mkdir(parents=True, exist_ok=True)
healed.export(args.output)
print('voxel_grid', volume.shape, 'pitch', pitch, 'closing_steps', args.steps,
      'faces', len(healed.faces), 'watertight', healed.is_watertight, flush=True)
