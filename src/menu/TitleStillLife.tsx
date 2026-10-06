import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { RoundedBox } from "@react-three/drei";
import { useEffect, useMemo, useRef } from "react";
import * as THREE from "three";
import { titleFraming } from "./titleFraming";

// 參考：PAL1 DOS 起始選單（竹簡、帶鞘長劍、酒葫蘆）。全部是可受光的立體幾何。
// https://taipeigoodgood.pixnet.net/blog/posts/11380278150
const VERSES = ["趙客縵胡纓", "吳鉤霜雪明", "銀鞍照白馬", "颯沓如流星", "十步殺一人", "千里不留行", "事了拂衣去", "深藏身與名", "閒過信陵飲", "脫劍膝前橫", "將炙啖朱亥", "持觴勸侯嬴", "三杯吐然諾", "五嶽倒為輕", "眼花耳熱後", "意氣素霓生", "救趙揮金槌"];

function woodTexture(index: number): THREE.CanvasTexture {
  const canvas = document.createElement("canvas");
  canvas.width = 128;
  canvas.height = 1024;
  const ctx = canvas.getContext("2d")!;
  const shading = ctx.createLinearGradient(0, 0, 128, 0);
  shading.addColorStop(0, "#665237");
  shading.addColorStop(0.18, "#baa077");
  shading.addColorStop(0.55, "#c6ae86");
  shading.addColorStop(1, "#8b704c");
  ctx.fillStyle = shading;
  ctx.fillRect(0, 0, 128, 1024);
  // 固定種子的纖維紋，不在每次 render 產生不同素材。
  let seed = index * 1297 + 43;
  const noise = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
  for (let i = 0; i < 130; i++) {
    const x = noise() * 128;
    ctx.strokeStyle = `rgba(61, 39, 21, ${0.03 + noise() * 0.12})`;
    ctx.lineWidth = 0.3 + noise();
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.bezierCurveTo(x + noise() * 6, 320, x - noise() * 6, 680, x + noise() * 3, 1024);
    ctx.stroke();
  }
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.font = '50px "KaiTi", "DFKai-SB", "BiauKai", serif';
  const text = VERSES[index % VERSES.length]!;
  [...text].forEach((char, i) => {
    ctx.save();
    ctx.translate(62 + noise() * 4, 190 + i * 120);
    ctx.rotate((noise() - 0.5) * 0.08);
    ctx.fillStyle = "#3d3022";
    ctx.fillText(char, 0, 0);
    ctx.restore();
  });
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
}

function BambooManuscript() {
  const textures = useMemo(() => VERSES.map((_, i) => woodTexture(i)), []);
  useEffect(() => () => textures.forEach((t) => t.dispose()), [textures]);
  return (
    <group position={[0.25, 0.07, 0.85]} rotation={[0, -0.08, 0]}>
      {textures.map((texture, i) => {
        const rolled = i < 3;
        const elevation = rolled ? [0.57, 0.23, 0.08][i]! : 0;
        return (
          <group key={i} position={[(i - 8) * 0.30, elevation, 0]} rotation={[0, 0, rolled ? [1.04, 0.6, 0.22][i]! : 0]}>
            <RoundedBox args={[0.285, 0.10, 3.65]} radius={0.03} smoothness={2} castShadow receiveShadow>
              <meshStandardMaterial color="#a18760" roughness={0.86} />
            </RoundedBox>
            <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.052, 0]} receiveShadow>
              <planeGeometry args={[0.27, 3.61]} />
              <meshStandardMaterial map={texture} roughness={0.92} />
            </mesh>
            {[-1.53, 1.53].map((z) => (
              <mesh key={z} position={[0, 0.075, z]} rotation={[0, 0, Math.PI / 2]} castShadow>
                <cylinderGeometry args={[0.017, 0.017, 0.303, 6]} />
                <meshStandardMaterial color="#722d24" roughness={1} />
              </mesh>
            ))}
          </group>
        );
      })}
    </group>
  );
}

function gourdTexture(): THREE.CanvasTexture {
  const canvas = document.createElement("canvas");
  canvas.width = canvas.height = 256;
  const ctx = canvas.getContext("2d")!;
  ctx.fillStyle = "#9d542b";
  ctx.fillRect(0, 0, 256, 256);
  for (let i = 0; i < 2200; i++) {
    const x = (i * 79.73) % 256;
    const y = (i * 41.37) % 256;
    ctx.fillStyle = i % 3 ? "#713b2322" : "#d7995938";
    ctx.fillRect(x, y, 1 + i % 3, 1 + i % 2);
  }
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

function WineGourd() {
  const geometry = useMemo(() => new THREE.LatheGeometry([
    [0.05, 0], [0.24, 0.03], [0.43, 0.14], [0.55, 0.36], [0.56, 0.55],
    [0.49, 0.75], [0.32, 0.91], [0.19, 1.02], [0.23, 1.12], [0.35, 1.25],
    [0.39, 1.43], [0.33, 1.60], [0.16, 1.72], [0.085, 1.78], [0.08, 1.86],
  ].map(([x, y]) => new THREE.Vector2(x!, y!)), 40), []);
  const texture = useMemo(gourdTexture, []);
  const rope = useMemo(() => new THREE.CatmullRomCurve3([
    new THREE.Vector3(0.07, 1.85, 0), new THREE.Vector3(0.24, 1.97, 0.02),
    new THREE.Vector3(0.39, 1.88, 0.06), new THREE.Vector3(0.28, 1.76, 0.05),
    new THREE.Vector3(0.10, 1.84, 0),
  ]), []);
  useEffect(() => () => { texture.dispose(); geometry.dispose(); }, [texture, geometry]);
  return (
    <group position={[-1.85, 0.59, -0.8]} rotation={[0.72, 0, 0.45]}>
      <mesh geometry={geometry} castShadow receiveShadow>
        <meshStandardMaterial map={texture} roughness={0.75} />
      </mesh>
      <mesh position={[0, 1.87, 0]} castShadow>
        <cylinderGeometry args={[0.065, 0.073, 0.13, 12]} />
        <meshStandardMaterial color="#58351f" roughness={1} />
      </mesh>
      {[1.79, 1.82, 1.85].map((y) => (
        <mesh key={y} position={[0, y, 0]} rotation={[Math.PI / 2, 0, 0]} castShadow>
          <torusGeometry args={[0.083, 0.012, 5, 20]} />
          <meshStandardMaterial color="#5b3924" roughness={1} />
        </mesh>
      ))}
      <mesh castShadow>
        <tubeGeometry args={[rope, 20, 0.015, 5, false]} />
        <meshStandardMaterial color="#65442b" roughness={1} />
      </mesh>
    </group>
  );
}

function SheathedSword() {
  const sheath = useMemo(() => {
    const shape = new THREE.Shape();
    shape.moveTo(-2.4, 0);
    shape.lineTo(-2.12, -0.16);
    shape.lineTo(0.98, -0.19);
    shape.lineTo(1.12, -0.13);
    shape.lineTo(1.12, 0.13);
    shape.lineTo(0.98, 0.19);
    shape.lineTo(-2.12, 0.16);
    shape.closePath();
    return new THREE.ExtrudeGeometry(shape, { depth: 0.10, bevelEnabled: true, bevelSegments: 2, steps: 1, bevelSize: 0.028, bevelThickness: 0.025 });
  }, []);
  useEffect(() => () => sheath.dispose(), [sheath]);
  return (
    <group position={[0.08, 0.21, 1.75]} rotation={[0, 0.32, 0]}>
      <mesh geometry={sheath} rotation={[-Math.PI / 2, 0, 0]} castShadow receiveShadow>
        <meshStandardMaterial color="#503523" roughness={0.6} />
      </mesh>
      <RoundedBox args={[3.12, 0.012, 0.23]} position={[-0.62, 0.138, 0]} radius={0.005} smoothness={1} receiveShadow>
        <meshStandardMaterial color="#242b29" roughness={0.79} />
      </RoundedBox>
      {[-0.152, 0.152].map((z) => (
        <mesh key={z} position={[-0.63, 0.13, z]} castShadow>
          <boxGeometry args={[3.08, 0.016, 0.019]} />
          <meshStandardMaterial color="#a27c40" metalness={0.5} roughness={0.6} />
        </mesh>
      ))}
      {Array.from({ length: 21 }, (_, i) => (
        <mesh key={i} position={[-2.06 + i * 0.145, 0.15, 0]} rotation={[-Math.PI / 2, 0, Math.PI / 4]}>
          <torusGeometry args={[0.048, 0.007, 4, 4]} />
          <meshStandardMaterial color="#b19c71" metalness={0.25} roughness={0.65} />
        </mesh>
      ))}
      <RoundedBox args={[0.16, 0.17, 0.65]} position={[1.12, 0.13, 0]} radius={0.04} smoothness={3} castShadow>
        <meshStandardMaterial color="#b18549" metalness={0.65} roughness={0.4} />
      </RoundedBox>
      <mesh position={[1.56, 0.13, 0]} rotation={[0, 0, Math.PI / 2]} castShadow>
        <cylinderGeometry args={[0.078, 0.09, 0.74, 12]} />
        <meshStandardMaterial color="#492b20" roughness={0.88} />
      </mesh>
      {Array.from({ length: 12 }, (_, i) => (
        <mesh key={i} position={[1.22 + i * 0.06, 0.13, 0]} rotation={[0, Math.PI / 2, 0]} castShadow>
          <torusGeometry args={[0.081, 0.009, 5, 12]} />
          <meshStandardMaterial color="#916d43" roughness={0.95} />
        </mesh>
      ))}
      <mesh position={[1.98, 0.13, 0]} rotation={[0, 0, Math.PI / 2]} castShadow>
        <cylinderGeometry args={[0.11, 0.10, 0.14, 12]} />
        <meshStandardMaterial color="#af854a" metalness={0.6} roughness={0.45} />
      </mesh>
    </group>
  );
}

function StillLifeCamera() {
  const { camera, size } = useThree();
  const framing = titleFraming(size.width, size.height);
  useEffect(() => {
    camera.far = framing.cameraFar;
    camera.updateProjectionMatrix();
  }, [camera, framing.cameraFar]);
  const elapsed = useRef(0);
  const reducedMotion = useMemo(() => window.matchMedia("(prefers-reduced-motion: reduce)").matches, []);
  useFrame((_, delta) => {
    elapsed.current += delta;
    const t = reducedMotion ? 0 : elapsed.current;
    const { fit } = framing;
    camera.position.set(Math.sin(t * 0.12) * 0.08, 6.3 * fit, 7.3 * fit);
    camera.lookAt(0, 0.2, -0.10);
  });
  return <fog attach="fog" args={["#030302", framing.fogNear, framing.fogFar]} />;
}

export default function TitleStillLife({ active }: { active: boolean }) {
  return (
    <Canvas frameloop={active ? "always" : "never"} shadows dpr={[1, 1.5]} camera={{ position: [0, 6.3, 7.3], fov: 39, near: 0.1, far: 50 }} gl={{ antialias: true, powerPreference: "low-power" }}>
      <color attach="background" args={["#030302"]} />
      <StillLifeCamera />
      <ambientLight intensity={0.22} color="#d2b28d" />
      <spotLight position={[-3, 6.8, 3]} angle={0.65} penumbra={0.65} intensity={95} color="#ffe0ae" decay={2} castShadow shadow-mapSize={[1024, 1024]} shadow-bias={-0.0002} />
      <directionalLight position={[3, 3, -1]} intensity={0.40} color="#b6c2c7" />
      <group position={[0, 0, 0.45]}>
        <BambooManuscript />
        <WineGourd />
        <SheathedSword />
      </group>
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.02, 0]} receiveShadow>
        <planeGeometry args={[200, 200]} />
        <meshStandardMaterial color="#030302" roughness={1} />
      </mesh>
    </Canvas>
  );
}
