import { useCallback, useEffect, useRef, useState } from "react";
import { BattleStage, type StageActor } from "./stage/BattleStage";
import { lungePoint, slotPosition, yawToward, type Vec3 } from "./stage/formation";
import { CardHand, type CardView } from "./ui/CardHand";
import { writeMemory, type PrototypeMemory } from "./menu/prototypeMemory";

/**
 * 階段 0′ 原型：只驗證「3D 畫風＋仙劍一式斜向站位＋出牌演出＋手機效能」，不含正式遊戲邏輯。
 */
const ASSETS = {
  ground: "/assets/backgrounds/shilipo_ground.jpg",
  hero: "/assets/characters/li_xiaoyao.glb",
  linger: "/assets/characters/zhao_linger_style_d_v3.glb",
  bandit: "/assets/characters/bandit_chief.glb",
  wasp: "/assets/enemies/demon_wasp.png",
};

// 網址參數：?stress＝3 對 3 的效能壓力測試；?perf＝顯示幀率（stress 自動開）
const PARAMS = new URLSearchParams(window.location.search);
const STRESS = PARAMS.has("stress");
const PERF = STRESS || PARAMS.has("perf");

interface Combatant {
  id: string;
  url: string;
  height: number;
  name: string;
  maxHp: number;
  floats?: boolean;
}

const PARTY: Combatant[] = STRESS
  ? [
      { id: "hero", url: ASSETS.hero, height: 1.75, name: "李逍遙", maxHp: 74 },
      { id: "linger", url: ASSETS.linger, height: 1.58, name: "趙靈兒", maxHp: 58 },
      { id: "p3", url: ASSETS.hero, height: 1.75, name: "隊友三", maxHp: 70 },
    ]
  : [
      { id: "hero", url: ASSETS.hero, height: 1.75, name: "李逍遙", maxHp: 74 },
      { id: "linger", url: ASSETS.linger, height: 1.58, name: "趙靈兒", maxHp: 58 },
    ];

const ENEMIES: Combatant[] = STRESS
  ? [
      { id: "bandit", url: ASSETS.bandit, height: 1.9, name: "山賊頭目", maxHp: 42 },
      { id: "wasp", url: ASSETS.wasp, height: 1.3, name: "蜂妖", maxHp: 18, floats: true },
      { id: "e3", url: ASSETS.bandit, height: 1.9, name: "山賊", maxHp: 30 },
    ]
  : [
      { id: "bandit", url: ASSETS.bandit, height: 1.9, name: "山賊頭目", maxHp: 42 },
      { id: "wasp", url: ASSETS.wasp, height: 1.3, name: "蜂妖", maxHp: 18, floats: true },
    ];

const HAND: CardView[] = [
  { id: "c1", name: "御劍術", cost: 1, type: "招式", text: "造成 7 點傷害。" },
  { id: "c2", name: "萬劍訣", cost: 2, type: "招式", element: "風", text: "對全體造成 5 點傷害 2 次。" },
  { id: "c3", name: "飛龍探雲手", cost: 1, type: "身法", text: "偷取敵人 1 件道具。" },
  { id: "c4", name: "護體", cost: 1, type: "身法", text: "獲得 6 點護體。" },
  { id: "c5", name: "天罡劍氣", cost: 2, type: "仙術", element: "雷", text: "造成 12 點傷害；剋風。" },
];

const IMPACT_MS = 430; // 出招動作的刺擊影格＋衝刺時間
const RETURN_MS = 1000;
const LUNGE_GAP = 1.0; // 衝刺停在目標前方的距離（公尺）

const partyPos = (i: number): Vec3 => slotPosition("party", i, PARTY.length);
const enemyPos = (i: number): Vec3 => slotPosition("enemy", i, ENEMIES.length);
const ENEMY_CENTER = slotPosition("enemy", 0, 1);
const PARTY_CENTER = slotPosition("party", 0, 1);

export default function BattlePrototype({ memory, entryId, active, onExit }: { memory: PrototypeMemory | null; entryId: number; active: boolean; onExit: () => void }) {
  const restored = memory?.mode === (STRESS ? "stress" : "standard") ? memory : null;
  const [qi, setQi] = useState(restored?.qi ?? 3);
  const [hand, setHand] = useState(() => restored ? restored.handIds.map((id) => HAND.find((card) => card.id === id)!) : HAND);
  const [clips, setClips] = useState<Record<string, string>>({});
  const [flashes, setFlashes] = useState<Record<string, number>>({});
  const [hps, setHps] = useState<Record<string, number>>(() => restored?.hps ?? Object.fromEntries([...PARTY, ...ENEMIES].map((c) => [c.id, c.maxHp])));
  const [lunge, setLunge] = useState<{ id: string; to: Vec3 } | null>(null);
  const [focus, setFocus] = useState<Vec3 | null>(null);
  const [popups, setPopups] = useState<{ key: number; position: Vec3; text: string }[]>([]);
  const popupKey = useRef(0);
  const busy = useRef(false);
  const [playing, setPlaying] = useState(false);
  const timers = useRef<ReturnType<typeof window.setTimeout>[]>([]);
  const later = (callback: () => void, delay: number) => {
    timers.current.push(window.setTimeout(callback, delay));
  };
  useEffect(() => () => timers.current.forEach(window.clearTimeout), []);
  useEffect(() => {
    timers.current.forEach(window.clearTimeout);
    timers.current = [];
    setQi(restored?.qi ?? 3);
    setHand(restored ? restored.handIds.map((id) => HAND.find((card) => card.id === id)!) : HAND);
    setHps(restored?.hps ?? Object.fromEntries([...PARTY, ...ENEMIES].map((c) => [c.id, c.maxHp])));
    setClips({});
    setFlashes({});
    setLunge(null);
    setFocus(null);
    setPopups([]);
    busy.current = false;
    setPlaying(false);
  }, [entryId, memory]);
  useEffect(() => {
    // 演出完成才保存，避免保存「已扣真氣但傷害尚未結算」的中間狀態。
    if (active && !playing) writeMemory({ version: 1, mode: STRESS ? "stress" : "standard", qi, handIds: hand.map((c) => c.id), hps });
  }, [qi, hand, hps, playing, active]);

  const setClip = (id: string, clip: string) => setClips((c) => ({ ...c, [id]: clip }));

  const onPlay = useCallback((card: CardView) => {
    if (busy.current) return;
    busy.current = true;
    setPlaying(true);
    // 原型：仙術由靈兒施放、其他由逍遙出手；目標是第一個還活著的敵人
    const attackerIndex = card.type === "仙術" ? 1 : 0;
    const attacker = PARTY[attackerIndex]!;
    const targetIndex = 0;
    const target = ENEMIES[targetIndex]!;
    const from = partyPos(attackerIndex);
    const to = enemyPos(targetIndex);
    setQi((q) => q - card.cost);
    setHand((h) => h.filter((c) => c.id !== card.id));
    setClip(attacker.id, "attack");
    if (card.type !== "仙術") setLunge({ id: attacker.id, to: lungePoint(from, to, LUNGE_GAP) });
    setFocus([(from[0] + to[0]) / 2, 0, (from[2] + to[2]) / 2]);
    later(() => {
      const damage = 7 + card.cost * 3;
      setHps((h) => ({ ...h, [target.id]: Math.max(0, (h[target.id] ?? 0) - damage) }));
      setFlashes((f) => ({ ...f, [target.id]: (f[target.id] ?? 0) + 1 }));
      setClip(target.id, "hit");
      later(() => setClip(target.id, "idle"), 550);
      const key = ++popupKey.current;
      setPopups((p) => [...p, { key, position: [to[0], target.height + 0.4, to[2]], text: `-${damage}` }]);
      later(() => setPopups((p) => p.filter((x) => x.key !== key)), 900);
    }, IMPACT_MS);
    later(() => {
      setClip(attacker.id, "idle");
      setLunge(null);
      setFocus(null);
      busy.current = false;
      setPlaying(false);
    }, RETURN_MS);
  }, []);

  const toActor = (c: Combatant, pos: Vec3, facing: Vec3): StageActor => ({
    id: c.id,
    url: c.url,
    position: pos,
    lunge: lunge?.id === c.id ? lunge.to : null,
    yaw: yawToward(pos, facing),
    height: c.height,
    floats: c.floats ?? false,
    imageFacesLeft: true,
    facing: facing[0] > pos[0] ? 1 : -1,
    clip: clips[c.id] ?? (STRESS && c.id === "e3" ? "attack" : "idle"),
    hitFlash: flashes[c.id] ?? 0,
    hp: hps[c.id] ?? c.maxHp,
    maxHp: c.maxHp,
    name: c.name,
  });
  const actors: StageActor[] = [
    ...PARTY.map((c, i) => toActor(c, partyPos(i), ENEMY_CENTER)),
    ...ENEMIES.map((c, i) => toActor(c, enemyPos(i), PARTY_CENTER)),
  ];
  const [perfEl, setPerfEl] = useState<HTMLDivElement | null>(null);

  return (
    <div className="app">
      <BattleStage
        active={active}
        backdropUrl={ASSETS.ground}
        backdropLayout={{ wallV: 0.0 }}
        actors={actors}
        focus={focus}
        popups={popups}
        perfTarget={PERF ? perfEl : null}
      />
      {PERF ? <div className="perf" ref={setPerfEl} /> : null}
      <button className="back-to-title" disabled={playing} onClick={onExit}>返回選單</button>
      <div className="qi-seal" title="真氣">
        {qi}
      </div>
      <button
        className="reset"
        disabled={playing}
        onClick={() => {
          setQi(3);
          setHand(HAND);
          setHps(Object.fromEntries([...PARTY, ...ENEMIES].map((c) => [c.id, c.maxHp])));
        }}
      >
        重來
      </button>
      <CardHand cards={hand} qi={qi} onPlay={onPlay} />
      <div className="hud">逍遙・3D 畫風原型（階段 0′）</div>
    </div>
  );
}
