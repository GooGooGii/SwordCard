// 將已驗證 production 建置交給隔離的 Sites checkout；不推送主專案 Git 工作。
import { cpSync, existsSync, lstatSync, mkdirSync, readFileSync, realpathSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = realpathSync(fileURLToPath(new URL("../../", import.meta.url)));
const source = join(root, "dist");
if (!existsSync(join(source, "index.html"))) throw new Error("先完成 npm run build 與測試");
const identity = JSON.parse(readFileSync(new URL("./site.json", import.meta.url), "utf8"));
const checkout = join(root, "hosting", "mobile");
mkdirSync(join(checkout, ".openai"), { recursive: true });
const realCheckout = realpathSync(checkout);
if (relative(root, realCheckout) !== join("hosting", "mobile")) throw new Error("部署副本超出指定工作目錄");
const manifestPath = join(checkout, ".openai", "hosting.json");
const existing = existsSync(manifestPath) ? JSON.parse(readFileSync(manifestPath, "utf8")) : {};
if (existing.project_id && existing.project_id !== identity.project_id) throw new Error("保留既有 Sites project_id，禁止覆寫不同站點");
const manifest = { ...existing, project_id: identity.project_id, static: { directory: "dist" } };
writeFileSync(`${manifestPath}.tmp`, `${JSON.stringify(manifest, null, 2)}\n`);
renameSync(`${manifestPath}.tmp`, manifestPath);

const destination = resolve(realCheckout, "dist");
if (dirname(destination) !== realCheckout || lstatSync(destination, { throwIfNoEntry: false })?.isSymbolicLink()) throw new Error("部署 dist 路徑不安全");
// 明確解析並檢查絕對目標後才清除自己的舊建置，沒有跨 shell 搬移／刪除。
rmSync(destination, { recursive: true, force: true });
cpSync(source, destination, { recursive: true });
writeFileSync(join(checkout, ".gitignore"), ".sites-local/\n*.tar.gz\n");
writeFileSync(join(checkout, "README.md"), "# SwordCard 私人手機試玩\n\n這是 Three.js 網頁版的 production 靜態建置。原始專案與多人協作 Git 工作在 SwordCard；此 checkout 僅供 Sites 發佈。遊戲存檔保存在各瀏覽器的 localStorage，可由遊戲內匯出／匯入搬移。\n");
console.log(JSON.stringify({ checkout, project_id: identity.project_id, url: identity.url }));
