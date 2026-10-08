import {
  availableNodes,
  beginChapter,
  buyCard,
  completeStory,
  concludeBattle,
  enterNode,
  leaveInn,
  member,
  newRun,
  rest,
  retryBattle,
  takeReward,
  updateBattle,
  train,
  type GameDb,
  type RunState,
} from "../../src/core/run";
import { playBattle } from "./policy";

/**
 * 整局自動通關（BALANCE-001）：用 core 的 reducer 從序章打到結局，記錄每場戰鬥。
 * mode：
 * - normal：選牌拿第一張、客棧休息並升級／買牌（「普通玩家」）
 * - worst：一律跳過選牌、客棧只休息（「最差牌組」，REDESIGN §2.1：最差牌組也要能通關）
 */
export interface BattleRecord {
  chapter: string;
  node: string;
  enemies: string[];
  attempt: number;
  outcome: string;
  turns: number;
  hpBefore: number;
  hpAfter: number;
  maxHp: number;
  deck: number;
}

export interface RunReport {
  finished: boolean;
  battles: BattleRecord[];
  defeats: number;
  assisted: number;
  coinsEnd: number;
  stuckAt: string | null;
}

const partyHp = (run: RunState) => run.party.reduce((s, id) => s + member(run, id).hp, 0);
const partyMax = (run: RunState) => run.party.reduce((s, id) => s + member(run, id).maxHp, 0);
const deckSize = (run: RunState) => run.party.reduce((s, id) => s + member(run, id).deck.length, 0) + run.shared.length;

/**
 * favor：偏好的流派（docs/ARCHETYPES.md 的 archetype key）。給了就模擬「專心走這條流派」的玩家：
 * 選牌、買牌、練功都先挑這個流派的牌；沒有才照普通玩家。用來比較各流派的強弱（流派平衡）。
 */
export function playGame(db: GameDb, seed: number, mode: "normal" | "worst", maxSteps = 4000, favor?: string): RunReport {
  const favored = (id: string | null | undefined) => !!favor && !!id && db.cards[id]?.archetype === favor;
  let run = newRun(db, seed, "standard");
  const battles: BattleRecord[] = [];
  let defeats = 0;
  let assisted = 0;
  for (let step = 0; step < maxSteps; step++) {
    const p = run.pending;
    switch (p.kind) {
      case "chapter_intro":
        run = beginChapter(run);
        break;
      case "map": {
        const options = availableNodes(db, run);
        if (options.length === 0) return { finished: false, battles, defeats, assisted, coinsEnd: run.coins, stuckAt: `${db.chapters[run.chapter]!.id}: no nodes` };
        // 最差牌組不打支線；普通玩家照地圖順序（支線戰鬥也打）
        const pick = mode === "worst" ? (options.find((n) => !n.optional) ?? options[0]!) : options[0]!;
        run = enterNode(db, run, pick.id);
        break;
      }
      case "story":
        run = completeStory(db, run, []);
        break;
      case "battle": {
        const before = partyHp(run);
        const result = playBattle(db, p.battle, 60);
        if (result.state.outcome === "ongoing") return { finished: false, battles, defeats, assisted, coinsEnd: run.coins, stuckAt: `${db.chapters[run.chapter]!.id}/${p.nodeId}: 60 回合沒打完` };
        run = updateBattle(run, result.state, result.played);
        const node = p.nodeId;
        run = concludeBattle(db, run);
        const after = run.pending.kind === "battle_lost" ? 0 : partyHp(run);
        battles.push({
          chapter: db.chapters[run.chapter]?.id ?? "end",
          node,
          enemies: p.battle.enemies.map((e) => e.defId),
          attempt: p.attempt,
          outcome: result.state.outcome,
          turns: result.turns,
          hpBefore: before,
          hpAfter: after,
          maxHp: partyMax(run),
          deck: deckSize(run),
        });
        break;
      }
      case "battle_lost": {
        defeats++;
        const losses = run.losses[p.nodeId] ?? 0;
        if (losses >= 2) assisted++;
        if (losses >= 6) return { finished: false, battles, defeats, assisted, coinsEnd: run.coins, stuckAt: `${db.chapters[run.chapter]!.id}/${p.nodeId}` };
        run = retryBattle(db, run, losses >= 2);
        break;
      }
      case "reward":
        run = takeReward(db, run, p.choices.map((g) => (mode === "worst" ? null : (g.find(favored) ?? g[0] ?? null))));
        break;
      case "inn": {
        // 歇腳二選一：血量低於七成休息，否則練功（最差牌組一律休息）
        const hurt = run.party.some((id) => member(run, id).hp < member(run, id).maxHp * 0.7);
        const candidate = run.party.flatMap((id) => member(run, id).deck).find((c) => !c.upgraded && db.cards[c.defId]?.upgrade && favored(c.defId))
          ?? run.party.flatMap((id) => member(run, id).deck).find((c) => !c.upgraded && db.cards[c.defId]?.upgrade && db.cards[c.defId]!.rarity !== "starter")
          ?? run.party.flatMap((id) => member(run, id).deck).find((c) => !c.upgraded && db.cards[c.defId]?.upgrade);
        if (!p.rested && (hurt || mode === "worst" || !candidate)) {
          if (run.party.some((id) => member(run, id).hp < member(run, id).maxHp)) run = rest(run);
        } else if (!p.rested && candidate) run = train(db, run, candidate.uid);
        if (mode === "normal") {
          const inn = () => run.pending as Extract<RunState["pending"], { kind: "inn" }>;
          const preferred = inn().stock.findIndex((s) => !s.sold && s.price <= run.coins && favored(s.card));
          const buy = preferred >= 0 ? preferred : favor ? -1 : inn().stock.findIndex((s) => !s.sold && s.price <= run.coins);
          if (buy >= 0) run = buyCard(db, run, buy);
        }
        run = leaveInn(db, run);
        break;
      }
      case "ending":
        return { finished: true, battles, defeats, assisted, coinsEnd: run.coins, stuckAt: null };
    }
  }
  return { finished: false, battles, defeats, assisted, coinsEnd: run.coins, stuckAt: "max steps" };
}
