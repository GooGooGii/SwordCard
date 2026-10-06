"""Versioned STYLE D configs, based on each approved 2D silhouette.

Keeps historical rigs untouched. Run with the project Python before Blender.
Joint coordinates are fractions of each character's full model height, and
were checked against the new sheets rather than copied from Li Xiaoyao.
"""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPECS = {
    'zhao_linger': {'height': 1.58, 'neck': .79, 'head': .85,
        'shoulder': [.10, .745], 'elbow': [.18, .635],
        'wrist': [.235, .515], 'hand_tip': [.245, .455],
        'hip': [.045, .49], 'knee': [.055, .26], 'ankle': [.055, .055],
        'waist': .49, 'weapon': {'kind': 'jian', 'length': .32, 'style': 'pal1'}},
    'lin_yueru': {'height': 1.66, 'neck': .79, 'head': .85,
        'shoulder': [.105, .745], 'elbow': [.18, .635],
        'wrist': [.245, .515], 'hand_tip': [.255, .455],
        'hip': [.06, .49], 'knee': [.09, .265], 'ankle': [.09, .055],
        'waist': .49, 'weapon': {'kind': 'jian', 'length': .43, 'style': 'pal1'}},
    'anu': {'height': 1.55, 'neck': .78, 'head': .84,
        'shoulder': [.10, .73], 'elbow': [.18, .615],
        'wrist': [.235, .49], 'hand_tip': [.25, .43],
        'hip': [.055, .49], 'knee': [.08, .255], 'ankle': [.09, .035],
        'waist': .49, 'weapon': {'kind': 'dao', 'length': .30, 'style': 'pal1'}},
    'wuhou': {'height': 1.68, 'neck': .79, 'head': .85,
        'shoulder': [.10, .74], 'elbow': [.18, .62],
        'wrist': [.24, .48], 'hand_tip': [.25, .42],
        'hip': [.05, .49], 'knee': [.055, .26], 'ankle': [.06, .05],
        'waist': .49, 'weapon': {'kind': 'staff', 'length': .72, 'style': 'pal1'}},
}

for cid, spec in SPECS.items():
    folder = ROOT / 'source_art' / 'characters' / cid
    cfg = json.loads((folder / 'rig.json').read_text(encoding='utf-8'))
    cfg.update(raw='raw_style_d_v1.glb', views='views_style_d_v1',
        out='raw_candidate_style_d_v1.glb', height=spec['height'],
        faces=14000, remesh=.003, texture_size=2048,
        projection_visibility_floor=0, garment_waist=spec['waist'])
    # Long hair is excluded from source stature estimates: joints follow the
    # actual face/shoulders/hips in each sheet. Unseen back structure is inferred.
    cfg['joints'] = {'pelvis': [0, .49], 'spine': [0, .58],
        'chest': [0, .70], 'neck': [0, spec['neck']],
        'head': [0, spec['head']], 'head_top': [0, .99]}
    for name in ('shoulder', 'elbow', 'wrist', 'hand_tip', 'hip', 'knee', 'ankle'):
        cfg['joints'][name] = spec[name]
    cfg['weapon'] = spec['weapon']
    cfg.pop('projection_cloth_band', None)
    # Preserve distinct sword/knife/casting gestures and bound them to this
    # character's rig. Slightly raised idle hands avoid clipping robe hems.
    for name in ('relax', 'breath'):
        pose = cfg['poses'][name]
        pose['upper_arm.L'] = [.40, -.05, -.915]
        pose['upper_arm.R'] = [-.40, -.05, -.915]
        pose['forearm.L'] = [.22, -.23, -.948]
        pose['forearm.R'] = [-.22, -.23, -.948]
        pose['hand.L'] = [.15, -.18, -.972]
        pose['hand.R'] = [-.15, -.18, -.972]
    if cid == 'wuhou':
        # A staff stays near vertical: a sword-style downwards tip would place
        # the green staff head in the floor. Grip remains at right hand.
        for pose in cfg['poses'].values():
            pose['_weapon'] = 'hand'
        cfg['poses']['relax']['forearm.R'] = [-.18, -.78, -.60]
        cfg['poses']['breath']['forearm.R'] = [-.18, -.80, -.57]
    (folder / 'rig_style_d_v1.json').write_text(
        json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(cid, 'rig_style_d_v1.json')
