// 把卡牌資料（主人、屬性、類型、動作、稀有度）匯出成 JSON，給卡圖合成用（tools/art/cards_compose.py）。
// node tools/art/cards_meta.mjs   → tools/art/prompts/cards_meta.json
import { createServer } from "vite";
import { writeFileSync } from "node:fs";

const vite = await createServer({ server: { middlewareMode: true, hmr: false }, appType: "custom", logLevel: "error" });
try {
  const { GAME_DB } = await vite.ssrLoadModule("/src/content/index.ts");
  const meta = Object.fromEntries(
    Object.values(GAME_DB.cards).map((c) => [c.id, { name: c.name, owner: c.owner, element: c.element ?? null, type: c.type, motion: c.motion, rarity: c.rarity, target: c.target }]),
  );
  writeFileSync("tools/art/prompts/cards_meta.json", JSON.stringify(meta, null, 1));
  console.log(`${Object.keys(meta).length} cards`);
} finally {
  await vite.close();
}
