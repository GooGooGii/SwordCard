// 登記為 ready 的地面圖必須存在。不改 app 的 tsconfig／Node 型別設定。
// 執行：node tools/stage/verify-scene-assets.mjs
import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { isAbsolute, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));
const publicRoot = resolve(root, "public");
// catalog 保持純資料＋函式，只含 type import；不載入 DOM 或 Three.js。
// Node 24 直接移除 TypeScript 型別，不依賴編譯器的 runtime API。
const { listBattleScenes, resolveBattleScene } = await import(
  pathToFileURL(resolve(root, "src/stage/scenes/catalog.ts")).href
);
const scenes = listBattleScenes();
const ready = scenes.filter((scene) => scene.ready);
if (ready.length === 0) throw new Error("沒有可用的回退場景");

for (const scene of ready) {
  const presentation = resolveBattleScene(scene.id);
  const url = presentation.backdropUrl;
  if (!url.startsWith("/assets/") || /[?#]/.test(url)) throw new Error(`場景 ${scene.id} 不是本機資產路徑：${url}`);
  const path = resolve(publicRoot, `.${url}`);
  const rel = relative(publicRoot, path);
  if (rel.startsWith("..") || isAbsolute(rel)) throw new Error(`場景 ${scene.id} 超出 public 目錄`);
  if (!existsSync(path) || !statSync(path).isFile()) throw new Error(`場景 ${scene.id} 缺少地面圖：${url}`);
  const header = readFileSync(path).subarray(0, 3);
  if (!header.equals(Buffer.from([0xff, 0xd8, 0xff]))) throw new Error(`場景 ${scene.id} 的地面圖不是 JPEG：${url}`);
  console.log(`[READY] ${scene.id}: ${url}`);
}
console.log(`Scene assets verified: ${ready.length} ready, ${scenes.length - ready.length} pending.`);
const environments = scenes.filter(scene => scene.environment !== null);
console.log(`Complete 3D environments: ${environments.length}/${scenes.length} (${(100 * environments.length / scenes.length).toFixed(1)}%). Image availability does not mean 3D completion.`);
// 可供任務清單／CI 讀取，避免把 23 張圖片誤記為 23 個完整 3D 地面。
const reportPath = process.argv[2];
if (reportPath) writeFileSync(reportPath, JSON.stringify({
  sceneCount: scenes.length,
  readyAssets: ready.length,
  pendingAssets: scenes.length - ready.length,
  complete3D: environments.length,
  complete3DPercent: Number((100 * environments.length / scenes.length).toFixed(1)),
  scenes,
}, null, 2));
