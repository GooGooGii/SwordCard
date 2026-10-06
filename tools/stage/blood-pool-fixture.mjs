// QA 專用：在 Node 用正式 core 建立較擁擠的存檔，不改正式遊戲程式。
import { createServer } from "vite";

export async function bloodPoolFixture() {
  const vite = await createServer({ server: { middlewareMode: true, hmr: false }, appType: "custom", logLevel: "error" });
  try {
    const { GAME_DB: db } = await vite.ssrLoadModule("/src/content/index.ts");
    const { devJump } = await vite.ssrLoadModule("/src/game/devJump.ts");
    const { beginBattle } = await vite.ssrLoadModule("/src/core/run/run.ts");
    const { addCardToRun } = await vite.ssrLoadModule("/src/core/run/rewards.ts");
    const { buildBloodPoolScenery } = await vite.ssrLoadModule("/src/stage/scenes/bloodPool.ts");
    const { inspectSceneryBudget } = await vite.ssrLoadModule("/src/stage/scenes/budget.ts");
    let run = await devJump(db, 3, "c3_bloodpool");
    run.relics = ["wine_gourd", "jade_buddha", "wind_pearl", "thunder_pearl", "earth_pearl", "seven_star_sword"];
    const medicines = Object.values(db.cards).filter((c) => c.type === "item" && c.effects.some((e) => e.kind === "heal" || e.kind === "cleanse" || e.kind === "gain_qi")).slice(0, 3);
    if (medicines.length !== 3) throw new Error("QA requires three existing medicine/item cards");
    for (const card of medicines) addCardToRun(db, run, card.id);
    run = beginBattle(db, run, "c3_bloodpool", 0);
    const battle = run.pending.battle;
    const all = [...battle.hand, ...battle.draw];
    const medicineIds = medicines.map((m) => m.id);
    const medicineInstances = medicineIds.map((id) => all.find((c) => c.defId === id));
    if (medicineInstances.some((c) => !c)) throw new Error("medicine not found in QA deck");
    const nonItems = all.filter((c) => !medicineIds.includes(c.defId));
    // 三張藥品與五張招式全部在手牌中，法寶以正式開場效果形成護體／氣勢／飛劍 HUD。
    battle.hand = [...nonItems.slice(0, 3), ...medicineInstances, ...nonItems.slice(3, 5)];
    const handIds = new Set(battle.hand.map((c) => c.uid));
    battle.draw = all.filter((c) => !handIds.has(c.uid));
    const scenery = buildBloodPoolScenery();
    const budget = inspectSceneryBudget(scenery.group);
    scenery.dispose();
    return {
      save: JSON.stringify({ version: 1, savedAt: Date.now(), run }),
      report: { party: run.party, medicines: medicines.map((m) => m.name), relics: run.relics, handCount: battle.hand.length, budget },
    };
  } finally {
    await vite.close();
  }
}
