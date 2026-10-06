// 自帶字型（離線可用，REDESIGN §6.4）：掃描遊戲裡用到的所有字，只複製含有這些字的 woff2 分片。
// 字型：霞鶩文楷 TC（標題、卡名）、Noto Serif TC（內文），皆 OFL 授權，來自 @fontsource。
//   node tools/fonts.mjs   → public/fonts/*.woff2、src/fonts.css
// 劇本或介面文字改了要重跑（npm run android:sync 會自動跑）。
import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const FONTS = [
  { pkg: "lxgw-wenkai-tc", weights: [400] },
  { pkg: "noto-serif-tc", weights: [400, 700] },
];

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out);
    else if (/\.(tsx?|css)$/.test(name)) out.push(p);
  }
  return out;
}

// 用到的字：程式碼與內容裡的所有字元，加上 ASCII 可見字元
const used = new Set();
for (const file of [...walk("src"), "index.html"]) for (const ch of readFileSync(file, "utf8")) used.add(ch.codePointAt(0));
for (let c = 0x20; c < 0x7f; c++) used.add(c);

function parseRange(text) {
  return text.split(",").map((part) => {
    const [a, b] = part.trim().replace(/^U\+/i, "").split("-");
    const lo = parseInt(a, 16);
    return [lo, b ? parseInt(b, 16) : lo];
  });
}

const outDir = "public/fonts";
if (existsSync(outDir)) rmSync(outDir, { recursive: true });
mkdirSync(outDir, { recursive: true });
const covered = new Set();
let css = "/* 由 tools/fonts.mjs 產生，不要手改。只含遊戲用到的字（@fontsource，OFL 授權）。 */\n";
let bytes = 0;
let files = 0;
for (const { pkg, weights } of FONTS) {
  const base = join("node_modules", "@fontsource", pkg);
  for (const weight of weights) {
    const source = readFileSync(join(base, `${weight}.css`), "utf8");
    for (const block of source.match(/@font-face\s*{[^}]*}/g) ?? []) {
      const family = /font-family:\s*'([^']+)'/.exec(block)?.[1];
      const woff2 = /url\(\.\/files\/([^)]+\.woff2)\)/.exec(block)?.[1];
      const rangeText = /unicode-range:\s*([^;]+);/.exec(block)?.[1];
      if (!family || !woff2 || !rangeText) continue;
      const ranges = parseRange(rangeText);
      const hits = [...used].filter((c) => ranges.some(([lo, hi]) => c >= lo && c <= hi));
      if (hits.length === 0) continue;
      for (const c of hits) covered.add(`${pkg}:${c}`);
      copyFileSync(join(base, "files", woff2), join(outDir, woff2));
      bytes += statSync(join(outDir, woff2)).size;
      files++;
      css += `@font-face{font-family:'${family}';font-style:normal;font-display:swap;font-weight:${weight};src:url(/fonts/${woff2}) format('woff2');unicode-range:${rangeText.trim()};}\n`;
    }
  }
}
writeFileSync("src/fonts.css", css);
// 再把每個分片裁成只含用到的字（大多數分片只用到幾個字，可以從約 8 MB 降到 1 MB 多）
const charsFile = join(outDir, ".used-chars.txt");
writeFileSync(charsFile, [...used].map((c) => String.fromCodePoint(c)).join(""));
const py = spawnSync("python", ["tools/subset_fonts.py", charsFile], { stdio: "inherit" });
rmSync(charsFile);
if (py.status !== 0) console.warn("裁字失敗（需要 pip install fonttools brotli），保留未裁的分片");
// 中日韓字元裡，內文字型沒涵蓋到的（會退回系統字型）
const missing = [...used].filter((c) => c > 0x2e80 && !covered.has(`noto-serif-tc:${c}`)).map((c) => String.fromCodePoint(c));
console.log(`字型分片 ${files} 個（裁字前 ${(bytes / 1024 / 1024).toFixed(2)} MB）；用到 ${used.size} 個字元${missing.length ? `；內文字型缺：${missing.join("")}` : ""}`);
