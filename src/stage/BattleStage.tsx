import { Html, useTexture } from "@react-three/drei";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { Bloom, EffectComposer, Vignette } from "@react-three/postprocessing";
import { lazy, Suspense, useEffect, useMemo, useRef, type ReactNode } from "react";
import * as THREE from "three";
import { Actor } from "./Actor";
import { CombatImpact, type CombatImpactEvent } from "./CombatImpact";
import { Billboard } from "./Billboard";
import { FpsMeter } from "./FpsMeter";
import { buildBackdrop, type BackdropLayout } from "./backdrop";
import { resolveBattleScene } from "./scenes/catalog";
import { resolveSceneEnvironment } from "./scenes/presentation";
import { presentBossArt } from "./artCandidates";

const BloodPoolScene = lazy(() => import("./scenes/BloodPoolScene"));
const PalScene = lazy(() => import("./scenes/PalScene"));

export interface StageActor {
  id: string;
  /** 3D 模型（.glb）或 2D 立繪（.png，立在 3D 舞台上）；依副檔名判斷 */
  url: string;
  /** 2D 立繪專用：原圖是否朝左、要在畫面上面向哪邊、是否浮空 */
  imageFacesLeft?: boolean;
  facing?: 1 | -1;
  floats?: boolean;
  position: [number, number, number];
  /** 衝刺目標（世界座標）；null＝站回原位。位移由舞台平滑插值 */
  lunge?: [number, number, number] | null;
  yaw: number;
  height: number;
  clip: string;
  hitFlash: number;
  hp: number;
  maxHp: number;
  name: string;
  /** 頭上的 HTML（敵人意圖等）；正式戰鬥畫面用 */
  overhead?: ReactNode;
  /** 意圖錨點相對頭頂的世界座標偏移，避免遮住高帽／臉部。 */
  headOffset?: [number, number, number];
  /** 血條下方的 HTML（護體、狀態） */
  badge?: ReactNode;
  /** 拖曳出牌的落點：畫面上蓋一塊 data-target 的區域（例如 "enemy:0"） */
  dropTarget?: string;
  /** 落點高亮（拖曳中可選的目標） */
  dropActive?: boolean;
}

export interface StageProps {
  impacts?: CombatImpactEvent[];
  active?: boolean;
  /** 章節資料的場景 ID；素材未交付時安全回退十里坡。 */
  sceneId?: string;
  /** 既有明確背景參數優先於 sceneId，保留原型與自訂背景的接法。 */
  backdropUrl?: string;
  backdropLayout?: BackdropLayout;
  /** 場景的附加 R3F 道具；不含鏡頭、角色與原有燈光。 */
  scenery?: ReactNode;
  actors: StageActor[];
  /** 鏡頭推近的焦點（世界座標）；null＝回到靜止位置 */
  focus: [number, number, number] | null;
  /** 浮動數字：每筆一次性顯示；kind 決定配色（damage、strong、heal、block…） */
  popups: { key: number; position: [number, number, number]; text: string; kind?: string }[];
  /** 效能量測輸出的 DOM（null＝不量測） */
  perfTarget?: HTMLElement | null;
  /** 畫質：low＝關閉後製、解析度上限 1（REDESIGN §9.1 省電） */
  quality?: "high" | "low";
  /**
   * false＝不在 Canvas 裡用 drei Html 畫血條、意圖、浮動數字，改由外部 DOM 疊層畫
   * （drei Html 各自持有 React root，戰鬥結束或敵人倒下時同步卸載會出錯，正式戰鬥畫面用 false）。
   */
  htmlOverlays?: boolean;
  /** 每一幀把每個角色的頭頂、腳下、身體中央、浮動數字位置投影成畫面座標（CSS px）寫進來 */
  anchorsRef?: { current: Map<string, StageAnchor> };
}

export interface StageAnchor {
  head: [number, number];
  foot: [number, number];
  mid: [number, number];
  pop: [number, number];
}

/** 每幀投影角色的錨點到畫面座標（給 Canvas 外的 DOM 疊層用） */
function Projector({ actors, anchorsRef }: { actors: StageActor[]; anchorsRef: { current: Map<string, StageAnchor> } }) {
  const { camera, size } = useThree();
  const v = useMemo(() => new THREE.Vector3(), []);
  useFrame(() => {
    // 不刪掉已經離場的角色：倒下那一刻的浮動數字還要留在原地播完
    const map = anchorsRef.current;
    const project = (x: number, y: number, z: number): [number, number] => {
      v.set(x, y, z).project(camera);
      return [(v.x * 0.5 + 0.5) * size.width, (-v.y * 0.5 + 0.5) * size.height];
    };
    for (const a of actors) {
      const [x, , z] = a.position;
      const lift = a.floats ? 0.55 : 0.25;
      const [dx, dy, dz] = a.headOffset ?? [0, 0, 0];
      map.set(a.id, {
        head: project(x + dx, a.height + lift + dy, z + dz),
        foot: project(x, -0.02, z),
        mid: project(x, a.height * 0.5 + (a.floats ? 0.3 : 0), z),
        pop: project(x, 1.9, z),
      });
    }
  });
  return null;
}

/** 裝置像素比上限（REDESIGN §6.4）：手機 DPR 3 是最大的效能殺手 */
const MAX_DPR = 1.5;

// 靜止鏡頭（仙劍一式斜向俯視，約 45°）：手繪地面的投影源，也是環繞與推鏡的基準。
// 看向點往鏡頭方向偏（z>0），讓整個戰場往畫面上方移，下方留給手牌。
const REST_TARGET = new THREE.Vector3(0.1, 0, 1.12);
const REST_OFFSET = new THREE.Vector3(0, 5.3, 5.6); // 相對看向點：上方＋後方 → 約 43° 俯角
const REST_POSITION = REST_TARGET.clone().add(REST_OFFSET);
const FOV = 40;
const SWAY = { x: 0.16, z: 0.1, periodX: 11, periodZ: 7.3 };
const FOCUS_PUSH = 0.08; // 短推鏡仍保留大 Boss 頭部與隊友 HUD 的空間

function CameraRig({ focus }: { focus: StageProps["focus"] }) {
  const { camera } = useThree();
  const weight = useRef(0);
  const time = useRef(0);
  const focusPoint = useRef(new THREE.Vector3());
  useFrame((_, delta) => {
    time.current += delta;
    const t = time.current;
    const targetWeight = focus ? 1 : 0;
    weight.current += (targetWeight - weight.current) * Math.min(1, delta * (focus ? 7 : 3.5));
    if (focus) focusPoint.current.set(...focus);
    const target = REST_TARGET.clone();
    if (weight.current > 0.001) target.lerp(focusPoint.current, weight.current * 0.18);
    // 推鏡＝沿著同一個俯角往看向點拉近，不會掉到平視
    const offset = REST_OFFSET.clone().multiplyScalar(1 - weight.current * FOCUS_PUSH);
    const sway = new THREE.Vector3(
      Math.sin((t / SWAY.periodX) * Math.PI * 2) * SWAY.x,
      0,
      Math.sin((t / SWAY.periodZ) * Math.PI * 2) * SWAY.z,
    );
    camera.position.copy(target).add(offset).add(sway);
    camera.lookAt(target);
  });
  return null;
}

function Backdrop({ url, layout }: { url: string; layout: BackdropLayout }) {
  const texture = useTexture(url);
  texture.colorSpace = THREE.SRGBColorSpace;
  const { size } = useThree();
  const group = useMemo(() => {
    const projector = new THREE.PerspectiveCamera(FOV, size.width / size.height, 0.1, 200);
    projector.position.copy(REST_POSITION);
    projector.lookAt(REST_TARGET);
    projector.updateMatrixWorld();
    projector.updateProjectionMatrix();
    return buildBackdrop(texture, projector, layout);
  }, [texture, size.width, size.height, layout]);
  useEffect(() => () => group.traverse((n) => (n as THREE.Mesh).geometry?.dispose()), [group]);
  return <primitive object={group} />;
}

/** 衝刺：往 target 快速滑過去（ease-out），target 清除後較慢地退回 home。 */
function LungeGroup({ home, target, children }: { home: [number, number, number]; target: [number, number, number] | null; children: ReactNode }) {
  const ref = useRef<THREE.Group>(null);
  const homeVec = useMemo(() => new THREE.Vector3(...home), [home[0], home[1], home[2]]);
  useEffect(() => {
    ref.current?.position.copy(homeVec);
  }, [homeVec]);
  useFrame((_, delta) => {
    const g = ref.current;
    if (!g) return;
    const goal = target ? new THREE.Vector3(...target) : homeVec;
    g.position.lerp(goal, Math.min(1, delta * (target ? 14 : 6)));
  });
  return <group ref={ref}>{children}</group>;
}

function HpBar({ actor }: { actor: StageActor }) {
  const ratio = Math.max(0, actor.hp / actor.maxHp);
  return (
    <Html position={[actor.position[0], -0.02, actor.position[2]]} center zIndexRange={[10, 0]} style={{ pointerEvents: "none" }}>
      <div className="hp">
        <div className="hp-fill" style={{ width: `${ratio * 100}%` }} />
        <span className="hp-text">
          {actor.hp} / {actor.maxHp}
        </span>
      </div>
      <div className="actor-name">{actor.name}</div>
      {actor.badge}
    </Html>
  );
}

/** 頭上的意圖與拖曳落點（不跟著衝刺移動，和血條一樣固定在站位上） */
function ActorOverlay({ actor }: { actor: StageActor }) {
  const [x, , z] = actor.position;
  const [dx, dy, dz] = actor.headOffset ?? [0, 0, 0];
  return (
    <>
      {actor.overhead ? (
        <Html position={[x + dx, actor.height + (actor.floats ? 0.55 : 0.25) + dy, z + dz]} center zIndexRange={[12, 0]} style={{ pointerEvents: "none" }}>
          {actor.overhead}
        </Html>
      ) : null}
      {actor.dropTarget ? (
        <Html position={[x, actor.height * 0.5 + (actor.floats ? 0.3 : 0), z]} center zIndexRange={[8, 0]}>
          <div className={`drop-zone ${actor.dropActive ? "active" : ""}`} data-target={actor.dropTarget} />
        </Html>
      ) : null}
    </>
  );
}

export function BattleStage({ active = true, sceneId, backdropUrl, backdropLayout, scenery, actors, focus, popups, impacts = [], perfTarget = null, quality = "high", htmlOverlays = true, anchorsRef }: StageProps) {
  const scene = resolveBattleScene(sceneId);
  const environment = resolveSceneEnvironment(scene, {
    explicitBackdrop: backdropUrl !== undefined || backdropLayout !== undefined,
    explicitScenery: scenery !== undefined,
  });
  const environmentPerf = import.meta.env.DEV && environment && new URLSearchParams(window.location.search).has("scenePerf");
  const displayActors = actors.map((a) => presentBossArt(a, {
    development: import.meta.env.DEV, search: window.location.search, sceneId: scene.renderedId,
  }));
  const bossArtCandidate = import.meta.env.DEV && displayActors.some((a, i) => a.url !== actors[i]?.url);
  return (
    <Canvas
      data-scene-environment={environment ?? undefined}
      data-boss-art-candidate={bossArtCandidate ? "red_ghost_king_dos" : undefined}
      frameloop={active ? "always" : "never"}
      shadows
      flat
      dpr={[1, quality === "low" ? 1 : MAX_DPR]}
      camera={{ position: REST_POSITION.toArray(), fov: FOV, near: 0.1, far: 200 }}
      gl={{ antialias: true, powerPreference: "high-performance" }}
    >
      <Suspense fallback={null}>
        {perfTarget || environmentPerf ? <FpsMeter target={perfTarget} /> : null}
        <CameraRig focus={focus} />
        {environment === "blood_pool" ? <BloodPoolScene quality={quality} /> : environment ? <PalScene id={environment} quality={quality} /> : <Backdrop url={backdropUrl ?? scene.backdropUrl} layout={backdropLayout ?? scene.backdropLayout} />}
        {scenery}
        <hemisphereLight args={["#e6ecff", "#b48a5c", 0.75]} />
        {/* 主光從左上後方來（和敵方同側），影子往右下落，俯視時看得到人物腳下的影子 */}
        <directionalLight
          position={[-5, 9, -2]}
          intensity={1.8}
          color="#ffe9cc"
          castShadow
          shadow-mapSize={[1024, 1024]}
          shadow-camera-left={-7}
          shadow-camera-right={7}
          shadow-camera-top={7}
          shadow-camera-bottom={-7}
          shadow-bias={-0.0005}
        />
        {/* 補光：從鏡頭方向照亮人物正面（俯視時看到的主要是頭肩與正面） */}
        <directionalLight position={[2, 6, 8]} intensity={0.55} color="#dfe8ff" />
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0.002, 0]} receiveShadow>
          <planeGeometry args={[30, 30]} />
          <shadowMaterial opacity={0.32} />
        </mesh>
        {displayActors.map((a) => (
          <group key={a.id}>
            {a.dropActive ? <mesh position={[a.position[0], 0.035, a.position[2]]} rotation={[-Math.PI / 2, 0, 0]}>
              <ringGeometry args={[0.48, 0.51, 40]} />
              <meshBasicMaterial color="#fff0bd" transparent opacity={0.85} depthWrite={false} side={THREE.DoubleSide} toneMapped={false} />
            </mesh> : null}
            <LungeGroup home={a.position} target={a.lunge ?? null}>
              {a.url.endsWith(".glb") ? (
                <Actor url={a.url} position={[0, 0, 0]} yaw={a.yaw} height={a.height} clip={a.clip} hitFlash={a.hitFlash} />
              ) : (
                <Billboard
                  url={a.url}
                  position={[0, 0, 0]}
                  height={a.height}
                  imageFacesLeft={a.imageFacesLeft ?? true}
                  facing={a.facing ?? -1}
                  floats={a.floats ?? false}
                  clip={a.clip}
                  hitFlash={a.hitFlash}
                />
              )}
            </LungeGroup>
            {/* 血條固定在站位上，不跟著衝刺移動（衝刺很短，跟著跑反而晃眼） */}
            {htmlOverlays ? <HpBar actor={a} /> : null}
            {htmlOverlays ? <ActorOverlay actor={a} /> : null}
          </group>
        ))}
        {anchorsRef ? <Projector actors={displayActors} anchorsRef={anchorsRef} /> : null}
        {impacts.map((event) => <CombatImpact key={event.key} event={event} />)}
        {(htmlOverlays ? popups : []).map((p) => (
          <Html key={p.key} position={p.position} center style={{ pointerEvents: "none" }}>
            <div className={p.kind ? `popup popup-${p.kind}` : "popup"}>{p.text}</div>
          </Html>
        ))}
        {quality === "high" ? (
          <EffectComposer multisampling={0}>
            <Bloom mipmapBlur intensity={0.35} luminanceThreshold={0.82} />
            <Vignette offset={0.32} darkness={0.55} />
          </EffectComposer>
        ) : null}
      </Suspense>
    </Canvas>
  );
}
