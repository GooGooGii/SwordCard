import { useTexture } from "@react-three/drei";
import { useFrame, useThree } from "@react-three/fiber";
import { useEffect, useMemo, useRef } from "react";
import * as THREE from "three";

/**
 * 2D 立繪立在 3D 舞台上（非人形、長袍等 3D 綁骨做不好的角色用，REDESIGN §6.1）。
 * - 板子永遠面向鏡頭（只繞 Y 軸轉，保持直立），用 alpha-test 投出真實陰影
 * - 動作用程式做：待命呼吸（縮放）／浮游（上下）、出招（往前撲）、受擊（後仰＋閃光）
 */
export interface BillboardProps {
  url: string;
  position: [number, number, number];
  height: number;
  /** 原圖裡角色朝左還是朝右 */
  imageFacesLeft: boolean;
  /** 要在畫面上面向哪邊：1＝右、-1＝左（斜向站位時敵方面向右下的我方） */
  facing: 1 | -1;
  floats?: boolean;
  clip: string;
  hitFlash: number;
}

const FLASH_SECONDS = 0.16;

export function Billboard({ url, position, height, imageFacesLeft, facing, floats = false, clip, hitFlash }: BillboardProps) {
  // 原圖朝向和要面向的方向不同時，水平翻轉
  const mirror = imageFacesLeft === (facing === 1);
  const texture = useTexture(url);
  texture.colorSpace = THREE.SRGBColorSpace;
  const { camera } = useThree();
  const pivot = useRef<THREE.Group>(null);
  const body = useRef<THREE.Mesh>(null);
  const image = texture.image as { width: number; height: number };
  const width = height * (image.width / image.height);

  const material = useMemo(
    () =>
      new THREE.MeshBasicMaterial({
        map: texture,
        transparent: true,
        alphaTest: 0.35,
        side: THREE.DoubleSide,
        toneMapped: false,
      }),
    [texture],
  );
  // 只寫深度的投影材質：讓陰影形狀跟著立繪輪廓
  const shadowMaterial = useMemo(
    () => new THREE.MeshDepthMaterial({ map: texture, alphaTest: 0.35, depthPacking: THREE.RGBADepthPacking }),
    [texture],
  );
  useEffect(() => () => material.dispose(), [material]);

  const flashLeft = useRef(0);
  const clipTime = useRef(0);
  const lastClip = useRef(clip);
  useEffect(() => {
    if (hitFlash > 0) flashLeft.current = FLASH_SECONDS;
  }, [hitFlash]);

  useFrame((state, delta) => {
    const p = pivot.current;
    const b = body.current;
    if (!p || !b) return;
    // 面向鏡頭，只繞 Y 軸
    const toCamera = new THREE.Vector3().subVectors(camera.position, p.getWorldPosition(new THREE.Vector3()));
    p.rotation.y = Math.atan2(toCamera.x, toCamera.z);

    if (lastClip.current !== clip) {
      lastClip.current = clip;
      clipTime.current = 0;
    }
    clipTime.current += delta;
    const t = state.clock.elapsedTime;
    let offsetX = 0;
    let offsetY = floats ? 0.25 + Math.sin(t * 2.2) * 0.08 : 0;
    let tilt = 0;
    let squash = 1 + Math.sin(t * 2.0) * 0.012;
    const k = clipTime.current;
    if (clip === "attack") {
      const lunge = Math.sin(Math.min(1, k / 0.5) * Math.PI); // 撲出去再回來
      offsetX = lunge * 0.9 * facing;
      tilt = -lunge * 0.18 * facing;
    } else if (clip === "hit") {
      const recoil = Math.max(0, 1 - k / 0.35);
      offsetX = -recoil * 0.18 * facing;
      tilt = recoil * 0.12 * facing;
      squash *= 1 - recoil * 0.05;
    }
    b.position.set(offsetX, height / 2 + offsetY, 0);
    b.rotation.z = tilt;
    b.scale.set(mirror ? -1 : 1, squash, 1);

    if (flashLeft.current > 0) {
      flashLeft.current = Math.max(0, flashLeft.current - delta);
      const f = flashLeft.current / FLASH_SECONDS;
      material.color.setRGB(1 + f * 0.6, 1 + f * 0.5, 1 + f * 0.4);
    } else {
      material.color.setRGB(1, 1, 1);
    }
  });

  return (
    <group ref={pivot} position={position}>
      <mesh ref={body} material={material} customDepthMaterial={shadowMaterial} castShadow>
        <planeGeometry args={[width, height]} />
      </mesh>
    </group>
  );
}
