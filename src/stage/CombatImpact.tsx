import { useFrame } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";

export interface CombatImpactEvent {
  key: number;
  position: [number, number, number];
  kind: "slash" | "block" | "heal";
  speed: number;
}

/** 小面積的接觸劍光／護體／回血；不用全螢幕閃光，也不依賴 bloom。 */
export function CombatImpact({ event }: { event: CombatImpactEvent }) {
  const ref = useRef<THREE.Group>(null);
  const age = useRef(0);
  const color = event.kind === "block" ? "#9acfff" : event.kind === "heal" ? "#a5edac" : "#ffe5aa";
  useFrame(({ camera }, delta) => {
    const g = ref.current;
    if (!g) return;
    age.current += delta * event.speed;
    const t = Math.min(1, age.current / 0.3);
    g.quaternion.copy(camera.quaternion);
    g.scale.setScalar(0.55 + t * 0.7);
    g.visible = t < 1;
    g.traverse((o) => {
      if (o instanceof THREE.Mesh) (o.material as THREE.MeshBasicMaterial).opacity = (1 - t) ** 2;
    });
  });
  return (
    <group ref={ref} position={event.position}>
      <mesh rotation={[0, 0, -0.65]}>
        <torusGeometry args={[0.48, event.kind === "slash" ? 0.018 : 0.012, 3, 24, event.kind === "slash" ? Math.PI * 1.2 : Math.PI * 2]} />
        <meshBasicMaterial color={color} transparent depthWrite={false} toneMapped={false} />
      </mesh>
      {event.kind === "slash" ? Array.from({ length: 7 }, (_, i) => {
        const a = i * Math.PI * 2 / 7;
        return <mesh key={i} position={[Math.cos(a) * 0.24, Math.sin(a) * 0.24, 0]} rotation={[0, 0, a]}>
          <planeGeometry args={[0.18, 0.014]} />
          <meshBasicMaterial color={color} transparent depthWrite={false} toneMapped={false} side={THREE.DoubleSide} />
        </mesh>;
      }) : null}
    </group>
  );
}
