import { useCallback, useEffect, useMemo, useRef, useState, type MouseEvent } from "react";
import { canPlay, effectiveCard, computeDamage, endTurn, playCard, type BattleStep, usePotion, canUsePotion } from "../../core/battle";
import { cardDef } from "../../core/cards";
import { describeIntent, STATUS_NAME } from "../../core/describe";
import { concludeBattle, nodeOf, updateBattle, type RunState } from "../../core/run";
import type { BattleState, EnemyState, PartyMemberState, Ref, StatusBag } from "../../core/types";
import { CHARACTERS } from "../../content/characters";
import { useSettings } from "../../game/settings";
import { game } from "../../game/store";
import { playMusic, playSfx } from "../../platform/audio";
import { BattleStage, type StageActor, type StageAnchor } from "../../stage/BattleStage";
import { HERO_POSES } from "../../content/heroArt";
import type { CombatImpactEvent } from "../../stage/CombatImpact";
import { lungePoint, slotPosition, sideCenter, yawToward, type Vec3 } from "../../stage/formation";
import { GameMenu } from "../common/GameMenu";
import { useMenuRequest } from "../common/useEscape";
import { useAssets } from "../common/useAsset";
import { BattleHud } from "./BattleHud";
import { PotionBar, PowerList, potionTargetKind } from "./PotionBar";
import { Hand, needsTarget, type TargetRef } from "./Hand";
import { snapshot, toBeats, type Beat, type FxKind, type Shown } from "./playback";
import { StageOverlay, type OverlayLayer } from "./StageOverlay";

/**
 * 正式戰鬥畫面：3D 舞台（仙劍一式斜向）＋ HUD。
 * 狀態只透過 core 的 playCard／endTurn 改，每一步寫回行程（自動存檔）；畫面依事件播放演出。
 */
const ENEMY_FALLBACK = "/assets/enemies/demon_wasp.png";
const PARTY_FALLBACK = "/assets/characters/li_xiaoyao_style_d_ready_v2.glb";
// 固定 PAL 俯視鏡頭下 2.6 會裁掉敵人頭部；意圖／血條和實際模型共用此高度。
const MAX_ENEMY_HEIGHT = 1.95;

type Pending = Extract<RunState["pending"], { kind: "battle" }>;

function statusChips(status: StatusBag, extra: { block: number; counter?: number; breakStacks?: number; breakThreshold?: number }) {
  const chips: { key: string; text: string; cls: string }[] = [];
  if (extra.block > 0) chips.push({ key: "block", text: `護 ${extra.block}`, cls: "block" });
  if (status.strength) chips.push({ key: "str", text: `${STATUS_NAME.strength} ${status.strength}`, cls: "buff" });
  if (status.weak) chips.push({ key: "weak", text: `${STATUS_NAME.weak} ${status.weak}`, cls: "debuff" });
  if (status.vulnerable) chips.push({ key: "vul", text: `${STATUS_NAME.vulnerable} ${status.vulnerable}`, cls: "debuff" });
  if (status.poison) chips.push({ key: "poison", text: `${STATUS_NAME.poison} ${status.poison}`, cls: "poison" });
  for (const c of ["stun", "seal", "sleep", "confuse"] as const) {
    if (status[c]) chips.push({ key: c, text: `${STATUS_NAME[c]} ${status[c]}`, cls: "control" });
  }
  if (extra.counter) chips.push({ key: "counter", text: `反擊 ${extra.counter}`, cls: "buff" });
  if (extra.breakStacks) chips.push({ key: "break", text: `破勢 ${extra.breakStacks}/${extra.breakThreshold}`, cls: "break" });
  return (
    <div className="bt-chips">
      {chips.map((c) => (
        <span key={c.key} className={`bt-chip-s ${c.cls}`}>
          {c.text}
        </span>
      ))}
    </div>
  );
}

function intentView(battle: BattleState, enemy: EnemyState) {
  if (!enemy.intent || enemy.dead) return null;
  const def = game.db.enemies[enemy.defId]!;
  const move = def.moves.find((m) => m.id === enemy.intent!.moveId);
  if (!move) return null;
  const target = enemy.intent.target !== null ? battle.party[enemy.intent.target] : undefined;
  let predicted: number | undefined;
  if (move.damage !== undefined && (move.intent === "attack" || move.intent === "attack_all" || move.intent === "debuff")) {
    predicted = computeDamage({ base: move.damage, attacker: enemy.status, defender: target?.status ?? null, halved: enemy.intent.halved }).amount;
  }
  const kind = move.intent === "attack" || move.intent === "attack_all" ? "attack" : move.intent === "block" || move.intent === "buff" || move.intent === "heal" ? "self" : "other";
  return (
    <div className={`bt-intent ${kind} ${enemy.intent.cancelled ? "cancelled" : ""} ${enemy.intent.halved ? "halved" : ""}`}>
      <b>{move.name}</b>
      <span>{describeIntent(move, predicted)}</span>
      {target ? <em>→ {CHARACTERS[target.charId].name}</em> : null}
      {enemy.intent.cancelled ? <small>破勢・取消</small> : enemy.intent.halved ? <small>破勢・減半</small> : null}
    </div>
  );
}

export function BattleScreen({ run }: { run: RunState }) {
  const pending = run.pending as Pending;
  const battle = pending.battle;
  const node = nodeOf(game.db, run, pending.nodeId);
  const spec = node.battle!;
  const settings = useSettings();
  const [shown, setShown] = useState<Shown | null>(null);
  const [busy, setBusy] = useState(false);
  const [selected, setSelected] = useState<number | null>(null);
  const [hover, setHover] = useState<TargetRef | null>(null);
  const [dragKind, setDragKind] = useState<"enemy" | "party" | null>(null);
  const [banner, setBanner] = useState<{ text: string; kind: string; key: number } | null>({ text: node.label, kind: "turn", key: 0 });
  const [popups, setPopups] = useState<{ key: number; actorId: string; text: string; kind: FxKind }[]>([]);
  const anchors = useRef(new Map<string, StageAnchor>());
  const [flashes, setFlashes] = useState<Record<string, number>>({});
  const [impacts, setImpacts] = useState<CombatImpactEvent[]>([]);
  const [clips, setClips] = useState<Record<string, string>>({});
  const [lunges, setLunges] = useState<Record<string, Vec3 | null>>({});
  const [focus, setFocus] = useState<Vec3 | null>(null);
  const [menu, setMenu] = useState(false);
  // 教學提示：第一次打這場、第一回合才顯示
  const [tips, setTips] = useState(() => (spec.tips && pending.attempt === 0 && battle.turn === 1 ? spec.tips : null));
  const timers = useRef<number[]>([]);
  const seq = useRef(1);

  useEffect(() => {
    playMusic(spec.music ?? (spec.boss ? "boss" : "battle"));
    const id = window.setTimeout(() => setBanner(null), 1400);
    return () => {
      window.clearTimeout(id);
      timers.current.forEach(window.clearTimeout);
    };
  }, [spec.music, spec.boss]);

  const view = shown ?? snapshot(battle);
  const partyN = battle.party.length;
  // 場地（血池、水域）不站在舞台上，顯示成 HUD 上的一塊
  const bodyIndices = battle.enemies.map((_, i) => i).filter((i) => !game.db.enemies[view.enemies[i]?.defId ?? battle.enemies[i]!.defId]?.isField);
  const fieldIndices = battle.enemies.map((_, i) => i).filter((i) => !bodyIndices.includes(i));
  const partyPos = (i: number): Vec3 => slotPosition("party", i, partyN);
  const enemyPos = (i: number): Vec3 => slotPosition("enemy", Math.max(0, bodyIndices.indexOf(i)), Math.max(1, bodyIndices.length));
  const refPos = (ref: Ref): Vec3 => (ref.side === "party" ? partyPos(ref.index) : enemyPos(ref.index));
  const refKey = (ref: Ref) => `${ref.side === "party" ? "p" : "e"}${ref.index}`;

  // 設定可選 3D 模型或 2D 立繪；選的那種沒有就退回另一種
  const partyUrls = useAssets(
    battle.party.map((m) => {
      const ch = CHARACTERS[m.charId];
      return settings.partyStyle === "2d" ? [ch.standee, ch.model, PARTY_FALLBACK] : [ch.model, ch.standee, PARTY_FALLBACK];
    }),
  );
  const enemyUrls = useAssets(view.enemies.map((e) => [game.db.enemies[e.defId]?.model, ENEMY_FALLBACK]));

  const later = (ms: number, fn: () => void) => {
    timers.current.push(window.setTimeout(fn, ms));
  };

  /** 播放一步的演出；播完對齊 core 的最終狀態 */
  const playback = (prev: BattleState, step: BattleStep) => {
    const beats = toBeats(
      step.events,
      (defId) => {
        const def = cardDef(game.db, defId);
        return { name: def.name, motion: def.motion };
      },
      (actor, moveId) => {
        const e = step.state.enemies[actor.index] ?? prev.enemies[actor.index];
        return game.db.enemies[e!.defId]?.moves.find((m) => m.id === moveId)?.name ?? "";
      },
    );
    const speed = settings.animSpeed;
    if (speed === 0 || beats.length === 0) {
      setShown(null);
      if (beats.length) playSfx(step.events.some((e) => e.type === "damage") ? "hit" : "card");
      return;
    }
    const snap = snapshot(prev);
    setShown(structuredClone(snap));
    setBusy(true);
    let t = 0;
    for (const beat of beats) {
      later(t, () => applyBeat(beat, snap, step.state, speed));
      t += beat.wait / speed;
    }
    later(t + 200, () => {
      setShown(null);
      setBusy(false);
      setLunges({});
      setClips({});
      setFocus(null);
    });
  };

  const applyBeat = (beat: Beat, snap: Shown, final: BattleState, speed: number) => {
    if (beat.impact) {
      const at = refPos(beat.impact.at);
      const key = seq.current++;
      setImpacts((events) => [...events, { key, position: [at[0], 0.9, at[2]], kind: beat.impact!.kind, speed }]);
      later(340 / speed, () => setImpacts((events) => events.filter((event) => event.key !== key)));
    }
    if (beat.shown) {
      beat.shown(snap, final);
      setShown(structuredClone(snap));
    }
    if (beat.banner) {
      setBanner({ ...beat.banner, key: seq.current++ });
      if (beat.banner.text === "合擊氣滿！") playSfx("combo");
    }
    if (beat.clip?.clip === "downed") playSfx("downed");
    if (beat.popup) {
      const at = beat.popup.at;
      const actorId = at.side === "party" ? `p-${battle.party[at.index]?.charId}` : `e-${snap.enemies[at.index]?.uid}`;
      const key = seq.current++;
      setPopups((p) => [...p.slice(-12), { key, actorId, text: beat.popup!.text, kind: beat.popup!.kind }]);
      later(1100 / speed, () => setPopups((p) => p.filter((x) => x.key !== key)));
      if (beat.popup.kind === "strong") playSfx("strong");
      else if (beat.popup.kind === "break") playSfx("break");
      else if (beat.popup.kind === "block") playSfx("block");
      else if (beat.popup.kind === "heal") playSfx("heal");
    }
    if (beat.flash) {
      const k = refKey(beat.flash);
      setFlashes((f) => ({ ...f, [k]: (f[k] ?? 0) + 1 }));
      playSfx("hit");
    }
    if (beat.clip) {
      const k = refKey(beat.clip.actor);
      const clip = beat.clip.clip;
      setClips((c) => ({ ...c, [k]: clip }));
      if (clip === "hit") later(420 / speed, () => setClips((c) => (c[k] === "hit" ? { ...c, [k]: "idle" } : c)));
    }
    if (beat.lunge) {
      const k = refKey(beat.lunge.actor);
      const from = refPos(beat.lunge.actor);
      if (beat.lunge.target) {
        const to = refPos(beat.lunge.target);
        setLunges((l) => ({ ...l, [k]: lungePoint(from, to, 1.0) }));
        setFocus(to);
        later(410 / speed, () => setLunges((l) => ({ ...l, [k]: null })));
      }
      setClips((c) => ({ ...c, [k]: beat.lunge!.motion === "strike" ? "attack" : beat.lunge!.motion === "guard" ? "guard" : "cast" }));
      later(520 / speed, () => setClips((c) => ({ ...c, [k]: "idle" })));
      playSfx("card");
    }
  };

  const commit = (step: BattleStep, played: number) => {
    const prev = battle;
    game.update((_, r) => updateBattle(r, step.state, played));
    playback(prev, step);
  };

  const onPlay = (uid: number, target: number | null) => {
    if (busy || battle.outcome !== "ongoing" || canPlay(game.db, battle, uid, target)) return;
    setSelected(null);
    setHover(null);
    commit(playCard(game.db, battle, uid, target), 1);
  };

  const [selectedPotion, setSelectedPotion] = useState<number | null>(null);
  const onUsePotion = (slot: number, target: number | null) => {
    if (busy || battle.outcome !== "ongoing" || canUsePotion(game.db, battle, slot, target)) return;
    setSelectedPotion(null);
    commit(usePotion(game.db, battle, slot, target), 0);
  };
  const selectCard = (uid: number | null) => {
    setSelected(uid);
    if (uid !== null) setSelectedPotion(null);
  };
  const selectPotion = (slot: number | null) => {
    setSelectedPotion(slot);
    if (slot !== null) setSelected(null);
  };

  const onEndTurn = () => {
    if (busy || battle.outcome !== "ongoing") return;
    setSelected(null);
    setSelectedPotion(null);
    commit(endTurn(game.db, battle), 0);
  };

  // 鍵盤：E 結束回合、Esc 取消選牌／關提示；Android 返回鍵打開選單
  useMenuRequest(useCallback(() => setMenu(true), []));
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "e" || e.key === "E") onEndTurn();
      if (e.key === "Escape") {
        setSelected(null);
        setSelectedPotion(null);
        setTips(null);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  // 點選出牌：選了一張要選目標的牌，點目標區塊就打出
  const selectedCard = selected !== null ? battle.hand.find((c) => c.uid === selected) : undefined;
  const potionKind = selectedPotion !== null ? potionTargetKind(game.db.potions?.[battle.potions?.[selectedPotion] ?? ""]) : null;
  const selectedKind = selectedCard ? needsTarget(effectiveCard(game.db, battle, selectedCard)) : potionKind;
  const targetingKind = dragKind ?? selectedKind;
  const onTargetClick = (e: MouseEvent<HTMLDivElement>) => {
    const el = (e.target as HTMLElement).closest("[data-target]") as HTMLElement | null;
    if (!el || !selectedKind) return;
    const [side, index] = el.dataset.target!.split(":");
    if (side !== (selectedKind === "enemy" ? "enemy" : "party")) return;
    if (selectedPotion !== null) onUsePotion(selectedPotion, Number(index));
    else if (selected !== null) onPlay(selected, Number(index));
  };

  const actors: StageActor[] = useMemo(() => {
    const list: StageActor[] = [];
    const enemyCenter = sideCenter("enemy");
    const partyCenter = sideCenter("party");
    battle.party.forEach((m: PartyMemberState, i) => {
      const shownUnit = view.party[i]!;
      const ch = CHARACTERS[m.charId];
      const pos = partyPos(i);
      const k = `p${i}`;
      list.push({
        id: `p-${m.charId}`,
        url: partyUrls[i] ?? PARTY_FALLBACK,
        // 2D 立繪才有姿勢圖（3D 模型用自己的動畫）
        poses: partyUrls[i] === ch.standee ? HERO_POSES[m.charId] : undefined,
        imageFacesLeft: true,
        facing: -1,
        position: pos,
        lunge: lunges[k] ?? null,
        yaw: yawToward(pos, enemyCenter),
        height: ch.height,
        clip: clips[k] ?? (shownUnit.gone ? "downed" : "idle"),
        hitFlash: flashes[k] ?? 0,
        hp: shownUnit.hp,
        maxHp: m.maxHp,
        name: shownUnit.gone ? `${ch.name}（昏迷）` : ch.name,
        badge: statusChips(m.status, { block: shownUnit.block, counter: m.counter }),
        dropTarget: `party:${i}`,
        dropActive: targetingKind === "party" && !busy,
      });
    });
    for (const i of bodyIndices) {
      const shownUnit = view.enemies[i];
      const e = battle.enemies[i];
      if (!shownUnit || shownUnit.gone || !e) continue;
      const def = game.db.enemies[shownUnit.defId]!;
      const pos = enemyPos(i);
      const k = `e${i}`;
      list.push({
        id: `e-${shownUnit.uid}`,
        url: enemyUrls[i] ?? ENEMY_FALLBACK,
        imageFacesLeft: def.imageFacesLeft ?? false,
        facing: 1,
        floats: def.floats ?? false,
        position: pos,
        lunge: lunges[k] ?? null,
        yaw: yawToward(pos, partyCenter),
        // 舞台在敵方深度大約只拍得到 3 公尺高：太高的 Boss 縮到 2.6，頭才不會出畫面
        height: Math.min(def.height, MAX_ENEMY_HEIGHT),
        clip: clips[k] ?? "idle",
        hitFlash: flashes[k] ?? 0,
        hp: shownUnit.hp,
        maxHp: e.uid === shownUnit.uid ? e.maxHp : def.maxHp,
        name: def.name,
        overhead: e.uid === shownUnit.uid ? intentView(battle, e) : null,
        badge: statusChips(e.status, { block: shownUnit.block, breakStacks: e.breakStacks, breakThreshold: e.breakThreshold }),
        dropTarget: `enemy:${i}`,
        dropActive: targetingKind === "enemy" && !busy,
      });
    }
    return list;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [battle, view, partyUrls, enemyUrls, lunges, clips, flashes, targetingKind, busy]);

  // 舞台上方的 DOM 疊層：血條、名字、狀態、意圖、拖曳落點；浮動數字另外依角色分組（角色倒下後數字仍留在原地）
  const layers: OverlayLayer[] = [
    ...actors.map((a) => ({
      id: a.id,
      head: a.overhead ?? undefined,
      foot: (
        <>
          <div className="hp">
            <div className="hp-fill" style={{ width: `${Math.max(0, a.hp / a.maxHp) * 100}%` }} />
            <span className="hp-text">
              {a.hp} / {a.maxHp}
            </span>
          </div>
          <div className="actor-name">{a.name}</div>
          {a.badge}
        </>
      ),
      mid: a.dropTarget ? <div className={`drop-zone ${a.dropActive ? "active" : ""} ${hover && a.dropTarget === `${hover.side}:${hover.index}` ? "aimed" : ""}`} data-target={a.dropTarget} /> : undefined,
    })),
    ...[...new Set(popups.map((p) => p.actorId))].map((id) => ({
      id,
      pop: (
        <div className="pop-stack">
          {popups
            .filter((p) => p.actorId === id)
            .map((p) => (
              <div key={p.key} className={`popup popup-${p.kind}`}>
                {p.text}
              </div>
            ))}
        </div>
      ),
    })),
  ];

  const done = battle.outcome !== "ongoing" && !busy;
  useEffect(() => {
    if (!done) return;
    playMusic(null);
    playSfx(battle.outcome === "won" || battle.outcome === "survived" ? "victory" : "defeat");
  }, [done, battle.outcome]);
  const outcomeText = { won: "勝利", survived: "撐過來了", survive_failed: "全員倒下……", lost: "戰敗", ongoing: "" }[battle.outcome];

  return (
    <div className={`bt ${selectedKind ? `targeting-${selectedKind}` : ""}`} onClick={onTargetClick}>
      <div className="bt-stage">
        <BattleStage
          sceneId={spec.ground}
          backdropUrl={`/assets/battle/${spec.ground}.jpg`}
          actors={actors}
          focus={focus}
          popups={[]}
          impacts={impacts}
          quality={settings.quality}
          htmlOverlays={false}
          anchorsRef={anchors}
        />
      </div>
      <StageOverlay anchors={anchors} layers={layers} />
      {fieldIndices.length > 0 ? (
        <div className="bt-fields">
          {fieldIndices.map((i) => {
            const e = battle.enemies[i]!;
            const u = view.enemies[i];
            const def = game.db.enemies[e.defId]!;
            if (!u || u.gone) return null;
            return (
              <div key={i} className={`bt-field ${selectedKind === "enemy" ? "active" : ""}`} data-target={`enemy:${i}`} title={def.canon}>
                <b>場地・{def.name}</b>
                <span className="bt-field-hp">
                  <span style={{ width: `${(u.hp / e.maxHp) * 100}%` }} />
                </span>
                <small>
                  {u.hp}/{e.maxHp}　打破場地才能解除效果
                </small>
              </div>
            );
          })}
        </div>
      ) : null}
      <BattleHud battle={battle} onMenu={() => setMenu(true)} />
      <PowerList battle={battle} />
      <PotionBar battle={battle} selected={selectedPotion} disabled={busy || done} onSelect={selectPotion} onUse={(slot) => onUsePotion(slot, null)} />
      {banner ? (
        <div key={banner.key} className={`bt-banner bt-banner-${banner.kind}`}>
          {banner.text}
        </div>
      ) : null}
      <div className="bt-qi" title="真氣：每回合 3 點，出牌消耗">
        <span>{battle.qi}</span>
        <small>/{battle.maxQi}</small>
      </div>
      <Hand battle={battle} disabled={busy || done} selected={selected} onSelect={selectCard} hover={hover} onHover={setHover} onPlay={onPlay} onDragKind={setDragKind} />
      <button type="button" className="ui-btn primary bt-end" disabled={busy || done} onClick={onEndTurn}>
        結束回合
      </button>
      {done ? (
        <div className="bt-result">
          <h2>{outcomeText}</h2>
          <button type="button" className="ui-btn primary" onClick={() => game.update((db, r) => concludeBattle(db, r))}>
            繼續
          </button>
        </div>
      ) : null}
      {tips ? (
        <div className="bt-tips" onClick={(e) => e.stopPropagation()}>
          <h3>提示</h3>
          {tips.map((t, i) => (
            <p key={i}>{t}</p>
          ))}
          <button type="button" className="ui-btn primary" onClick={() => setTips(null)}>
            知道了
          </button>
        </div>
      ) : null}
      {menu ? <GameMenu onClose={() => setMenu(false)} /> : null}
    </div>
  );
}
