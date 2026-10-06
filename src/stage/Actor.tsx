import { useAnimations, useGLTF } from "@react-three/drei";
import { useFrame } from "@react-three/fiber";
import { useEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { clone as cloneSkinned } from "three/examples/jsm/utils/SkeletonUtils.js";
import { applyToon } from "./toon";

export interface ActorProps {
  url: string;
  position: [number, number, number];
  /** 面向（度）：0＝面向鏡頭，正值往畫面右轉 */
  yaw: number;
  /** 模型身高（公尺），依包圍盒等比縮放 */
  height: number;
  /** 動作名稱（GLB 裡的 animation clip）；找不到就退回 fallbackClip */
  clip: string;
  fallbackClip?: string;
  /** 每次遞增就閃一下（受擊） */
  hitFlash?: number;
}

const FADE_SECONDS = 0.18;
const FLASH_SECONDS = 0.16;

export function Actor({ url, position, yaw, height, clip, fallbackClip = "idle", hitFlash = 0 }: ActorProps) {
  const gltf = useGLTF(url);
  const group = useRef<THREE.Group>(null);
  const { model, materials, scale } = useMemo(() => {
    const cloned = cloneSkinned(gltf.scene) as THREE.Group;
    applyToon(cloned);
    const mats: THREE.MeshToonMaterial[] = [];
    cloned.traverse((n) => {
      const mesh = n as THREE.Mesh;
      if (mesh.isMesh) mats.push(...([] as THREE.Material[]).concat(mesh.material).map((m) => m as THREE.MeshToonMaterial));
    });
    const box = new THREE.Box3().setFromObject(cloned);
    const modelHeight = Math.max(0.01, box.max.y - box.min.y);
    return { model: cloned, materials: mats, scale: height / modelHeight };
  }, [gltf.scene, height]);
  const { actions } = useAnimations(gltf.animations, group);

  useEffect(() => {
    const action = actions[clip] ?? actions[fallbackClip];
    if (!action) return;
    const loops = clip === fallbackClip || !actions[clip];
    action.setLoop(loops ? THREE.LoopRepeat : THREE.LoopOnce, loops ? Infinity : 1);
    action.clampWhenFinished = !loops;
    action.reset().fadeIn(FADE_SECONDS).play();
    return () => {
      action.fadeOut(FADE_SECONDS);
    };
  }, [actions, clip, fallbackClip]);

  const flashLeft = useRef(0);
  useEffect(() => {
    if (hitFlash > 0) flashLeft.current = FLASH_SECONDS;
  }, [hitFlash]);
  useFrame((_, delta) => {
    if (flashLeft.current <= 0) return;
    flashLeft.current = Math.max(0, flashLeft.current - delta);
    const k = flashLeft.current / FLASH_SECONDS;
    // 受擊閃光要保留輪廓：峰值只加 0.35（太亮整個人會糊成白影）
    for (const m of materials) m.emissive.setRGB(k * 0.35, k * 0.28, k * 0.22);
  });

  return (
    <group ref={group} position={position} rotation={[0, THREE.MathUtils.degToRad(yaw), 0]} scale={scale}>
      <primitive object={model} />
    </group>
  );
}
