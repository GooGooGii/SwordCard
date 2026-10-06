// Standalone development QA; excluded from the production game entry.
import { Suspense, useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Canvas } from '@react-three/fiber';
import { useGLTF } from '@react-three/drei';
import * as THREE from 'three';
import { clone } from 'three/examples/jsm/utils/SkeletonUtils.js';
import { applyToon } from '../../src/stage/toon';

const params = new URLSearchParams(location.search);
const variant = params.get('variant') ?? 'pal1_v1';
if (!/^[a-z0-9_]+$/.test(variant)) throw new Error('Invalid candidate variant');
const ids = ['li_xiaoyao','zhao_linger','lin_yueru','anu','wuhou'];

function Model({ id, clip, time }: { id: string; clip: string; time: number }) {
  const gltf = useGLTF(`/source_art/characters/${id}/raw_candidate_${variant}.glb`);
  const model = useMemo(() => {
    const root = clone(gltf.scene);
    applyToon(root);
    if (params.get('clay') === '1') root.traverse(object => {
      const mesh = object as THREE.Mesh;
      if (mesh.isMesh) mesh.material = new THREE.MeshStandardMaterial({ color: '#a6afb9', roughness: 1 });
    });
    return root;
  }, [gltf.scene]);
  const mixer = useMemo(() => new THREE.AnimationMixer(model), [model]);
  useEffect(() => {
    mixer.stopAllAction();
    const animation = gltf.animations.find(a => a.name === clip)!;
    mixer.clipAction(animation).play();
    mixer.setTime(Math.min(time, animation.duration - .001));
    model.updateMatrixWorld(true);
    let triangles = 0, bones = 0;
    const joints: Record<string, number[]> = {};
    const textures = new Set<THREE.Texture>();
    model.traverse(object => {
      if ((object as THREE.Bone).isBone) {
        bones++;
        joints[object.name] = object.getWorldPosition(new THREE.Vector3()).toArray();
      }
      const mesh = object as THREE.Mesh;
      if (!mesh.isMesh) return;
      triangles += (mesh.geometry.index?.count ?? mesh.geometry.attributes.position.count) / 3;
      for (const mat of [mesh.material].flat() as THREE.MeshToonMaterial[]) if (mat.map) textures.add(mat.map);
    });
    const box = new THREE.Box3().setFromObject(model, true);
    (window as any).__character = { id, clip, time, triangles, bones, joints,
      clips: gltf.animations.map(a => ({ name: a.name, duration: a.duration })),
      textures: [...textures].map(t => ({ width: t.image.width, height: t.image.height })),
      bounds: { min: box.min.toArray(), max: box.max.toArray() } };
    return () => { mixer.stopAllAction(); mixer.uncacheRoot(model); };
  }, [model, gltf.animations, mixer, id, clip, time]);
  return <primitive object={model} />;
}

function Harness() {
  const [id, setId] = useState(ids.includes(params.get('id') ?? '') ? params.get('id')! : 'lin_yueru');
  const [clip, setClip] = useState('idle');
  const [time, setTime] = useState(0);
  const [angle, setAngle] = useState('front');
  const cameras: Record<string, [number, number, number]> = {
    front: [0, .9, 3.8], back: [0, .9, -3.8], left: [-3.8, .9, 0], right: [3.8, .9, 0],
    front45: [2.7, 1.5, 2.7], back45: [-2.7, 1.5, -2.7],
  };
  return <>
    <div style={{ height: 36 }}>
      <select aria-label="character" value={id} onChange={e => setId(e.target.value)}>{ids.map(v => <option key={v}>{v}</option>)}</select>
      <select aria-label="clip" value={clip} onChange={e => setClip(e.target.value)}>{['idle','attack','hit'].map(v => <option key={v}>{v}</option>)}</select>
      <select aria-label="angle" value={angle} onChange={e => setAngle(e.target.value)}>{Object.keys(cameras).map(v => <option key={v}>{v}</option>)}</select>
      <input aria-label="time" type="number" step=".05" value={time} onChange={e => setTime(Number(e.target.value))} />
    </div>
    <Canvas key={angle} orthographic camera={{ position: cameras[angle], zoom: 270, near: .01, far: 100 }}
      onCreated={({ camera }) => { camera.lookAt(0, .82, 0); camera.updateProjectionMatrix(); }}
      style={{ width: '100vw', height: 'calc(100vh - 36px)' }}>
      <ambientLight intensity={1.7} /><directionalLight position={[-3,5,4]} intensity={2} />
      <Suspense fallback={null}><Model id={id} clip={clip} time={time} /></Suspense>
    </Canvas>
  </>;
}
createRoot(document.getElementById('root')!).render(<Harness />);
