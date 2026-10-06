import { describe, expect, it } from "vitest";
import { cardDef } from "../../src/core/cards";
import { describeCard, describeIntent } from "../../src/core/describe";
import { flattenStory } from "../../src/core/run/story";
import type { StoryStep } from "../../src/core/run/types";
import { STORY_BACKGROUNDS } from "../../src/content/backgrounds";
import { NPCS } from "../../src/content/characters";
import { GAME_DB } from "../../src/content";
import cardPrompts from "../../tools/art/prompts/cards.json";
import assetPrompts from "../../tools/art/prompts/assets.json";

/** 資料檢查：所有參照都對得上，每章都走得完（REDESIGN §7.4 紀律）。 */

const db = GAME_DB;
/** public/ 底下已存在的檔案（網址形式，例如 /assets/enemies/bee.png） */
const existing = new Set(Object.keys(import.meta.glob("../../public/assets/**/*.{png,jpg,glb}")).map((k) => k.replace("../../public", "")));

/** 劇本的所有步驟（含所有選項與分支） */
function allSteps(steps: StoryStep[]): StoryStep[] {
  return steps.flatMap((s) => {
    if ("choice" in s) return [s, ...s.choice.flatMap((c) => allSteps(c.then))];
    if ("when" in s) return [s, ...allSteps(s.then), ...allSteps(s.otherwise ?? [])];
    return [s];
  });
}

describe("卡牌", () => {
  it("每張牌都有卡圖提示詞", () => {
    const missing = Object.keys(db.cards).filter((id) => !(id in cardPrompts));
    expect(missing).toEqual([]);
  });

  it("卡面文字（自動產生）沒有缺字：每張牌、升級版、每個敵人意圖", () => {
    const bad = (s: string) => !s.trim() || /undefined|NaN|null|\[object/.test(s);
    for (const def of Object.values(db.cards)) {
      expect(bad(describeCard(def, db)), `${def.id}: ${describeCard(def, db)}`).toBe(false);
      if (def.upgrade) {
        const up = cardDef(db, def.id, true);
        expect(bad(describeCard(up, db)), `${def.id}+`).toBe(false);
        expect(up.name.endsWith("＋"), `${def.id} 升級名`).toBe(true);
      }
    }
    for (const e of Object.values(db.enemies)) for (const m of e.moves) expect(bad(describeIntent(m)), `${e.id}/${m.id}`).toBe(false);
  });

  it("起始牌組與角色的合擊牌都存在", () => {
    for (const [charId, ids] of Object.entries(db.starters)) {
      for (const id of ids) expect(db.cards[id], `${charId}: ${id}`).toBeDefined();
    }
    for (const c of Object.values(db.characters)) expect(db.cards[c.comboCard], c.comboCard).toBeDefined();
  });
});

describe("敵人", () => {
  it("召喚、接續、場地被動都指向存在的敵人", () => {
    for (const e of Object.values(db.enemies)) {
      for (const m of e.moves) if (m.summon) expect(db.enemies[m.summon], `${e.id} summons ${m.summon}`).toBeDefined();
      if (e.successor) expect(db.enemies[e.successor], `${e.id} → ${e.successor}`).toBeDefined();
      for (const p of e.passives ?? []) {
        if (p.kind === "undying_while" || (p.kind === "regen" && p.fieldId)) {
          expect(db.enemies[p.fieldId!], `${e.id} field ${p.fieldId}`).toBeDefined();
        }
        if (p.kind === "phase2") for (const id of p.moves) expect(e.moves.some((m) => m.id === id), `${e.id} phase2 ${id}`).toBe(true);
      }
      for (const id of e.stealable ?? []) expect(db.cards[id], `${e.id} steal ${id}`).toBeDefined();
      if (!e.isField) expect(e.moves.length, `${e.id} has no moves`).toBeGreaterThan(0);
    }
  });

  it("每隻敵人都有立繪（或 3D 模型）的出圖工作", () => {
    const jobs = assetPrompts as Record<string, { publish?: { path: string } }[]>;
    const planned = new Set(Object.values(jobs).flat().map((j) => j.publish?.path.replace(/^public/, "")));
    const missing = Object.values(db.enemies)
      .filter((e) => !e.isField)
      .filter((e) => !planned.has(e.model) && !existing.has(e.model))
      .map((e) => e.id);
    expect(missing).toEqual([]);
  });
});

describe("劇情背景與章節地圖", () => {
  const jobs = assetPrompts as Record<string, { publish?: { path: string } }[]>;
  const planned = new Set(Object.values(jobs).flat().map((j) => j.publish?.path.replace(/^public/, "")));

  it("每張劇情背景都有出圖工作或已交付", () => {
    const images = [...new Set(Object.values(STORY_BACKGROUNDS).map((b) => b.image))];
    expect(images.filter((url) => !planned.has(url) && !existing.has(url))).toEqual([]);
  });

  it("每章的地圖都有出圖工作或已交付", () => {
    expect(db.chapters.map((c) => c.map).filter((url) => !planned.has(url) && !existing.has(url))).toEqual([]);
  });
});

describe("劇本", () => {
  it("說話者、背景、獎勵都對得上", () => {
    for (const story of Object.values(db.stories)) {
      expect(STORY_BACKGROUNDS[story.bg], `${story.id} bg ${story.bg}`).toBeDefined();
      for (const step of allSteps(story.steps)) {
        if ("who" in step) expect(step.who in db.characters || step.who in NPCS, `${story.id}: ${step.who}`).toBe(true);
        if ("bg" in step) expect(STORY_BACKGROUNDS[step.bg], `${story.id} bg ${step.bg}`).toBeDefined();
        if ("reward" in step) {
          for (const id of step.reward.cards ?? []) expect(db.cards[id], `${story.id} card ${id}`).toBeDefined();
          if (step.reward.relic) expect(db.relics[step.reward.relic], `${story.id} relic`).toBeDefined();
        }
      }
    }
  });

  it("沒有被任何節點用到的劇本", () => {
    const used = new Set<string>();
    for (const ch of db.chapters) {
      for (const node of ch.nodes) {
        if (node.story) used.add(node.story);
        if (node.battle?.intro) used.add(node.battle.intro);
        if (node.battle?.outro) used.add(node.battle.outro);
      }
    }
    const unused = Object.keys(db.stories).filter((id) => !used.has(id));
    expect(unused).toEqual([]);
  });

  it("每個選項至少有一句話（不會選了之後什麼都沒發生）", () => {
    for (const story of Object.values(db.stories)) {
      for (const step of allSteps(story.steps)) {
        if ("choice" in step) for (const c of step.choice) expect(c.then.length, `${story.id}: ${c.text}`).toBeGreaterThan(0);
      }
    }
  });

  it("展開後的每條路線都能播放", () => {
    for (const story of Object.values(db.stories)) {
      const lines = flattenStory(story.steps, [], {});
      expect(lines.length, story.id).toBeGreaterThan(0);
    }
  });
});

describe("章節", () => {
  it("節點參照都存在，起點走得到終點", () => {
    for (const ch of db.chapters) {
      const ids = new Set(ch.nodes.map((n) => n.id));
      expect(ids.has(ch.start), `${ch.id} start`).toBe(true);
      expect(ids.has(ch.end), `${ch.id} end`).toBe(true);
      for (const node of ch.nodes) {
        for (const next of node.next) expect(ids.has(next), `${ch.id}/${node.id} → ${next}`).toBe(true);
        if (node.kind === "story" || node.kind === "event") expect(db.stories[node.story!], `${node.id} story`).toBeDefined();
        if (node.kind === "battle") {
          const b = node.battle!;
          for (const e of b.enemies) expect(db.enemies[e], `${ch.id}/${node.id} enemy ${e}`).toBeDefined();
          expect(b.enemies.length).toBeLessThanOrEqual(3);
          for (const s of [b.intro, b.outro]) if (s) expect(db.stories[s], `${node.id} ${s}`).toBeDefined();
          if (b.reward?.relic) expect(db.relics[b.reward.relic], `${node.id} relic`).toBeDefined();
        }
      }
      // 從起點出發，每個節點都走得到；終點走得到
      const seen = new Set<string>([ch.start]);
      const queue = [ch.start];
      while (queue.length) {
        const id = queue.shift()!;
        const node = ch.nodes.find((n) => n.id === id)!;
        for (const next of node.next) if (!seen.has(next)) (seen.add(next), queue.push(next));
      }
      expect([...ids].filter((id) => !seen.has(id)), `${ch.id} unreachable`).toEqual([]);
      // 終點之外，每個節點都有下一步（不會走進死路）
      const deadEnds = ch.nodes.filter((n) => n.id !== ch.end && n.next.length === 0).map((n) => n.id);
      expect(deadEnds, `${ch.id} dead ends`).toEqual([]);
    }
  });

  it("每章 5–10 個節點（含支線）、戰鬥 3–7 場（REDESIGN §2）", () => {
    for (const ch of db.chapters) {
      const battles = ch.nodes.filter((n) => n.kind === "battle").length;
      expect(ch.nodes.length, ch.id).toBeGreaterThanOrEqual(5);
      expect(ch.nodes.length, ch.id).toBeLessThanOrEqual(10);
      expect(battles, ch.id).toBeGreaterThanOrEqual(3);
      expect(battles, ch.id).toBeLessThanOrEqual(7);
    }
  });
});
