// Node 煙霧測試：node webgame/test_smoke.js
// 將 data.js + engine.js 與下方測試本體串成同一段 eval（const 不跨 eval 作用域）。
"use strict";
const fs = require("fs");
const path = require("path");
global.localStorage = { getItem: () => null, setItem: () => {}, removeItem: () => {} };
const game = ["data.js", "engine.js"].map((f) => fs.readFileSync(path.join(__dirname, f), "utf8")).join("\n");
const body = fs.readFileSync(__filename, "utf8").split("// ==== TEST" + " BODY ====")[1];
eval(game + "\n" + body);
process.exit(0); // 測試本體只在上面的 eval 裡跑，不讓 Node 再執行一次下方原始碼
/* 以下為測試本體，不直接執行 */
// ==== TEST BODY ====

let failures = 0;
function check(cond, msg) { if (!cond) { failures++; console.log("FAIL: " + msg); } }

// 1. 全卡片描述生成不炸 + effects kind 都有對應描述（含升級版）
for (const cid of Object.keys(CARDS)) {
  const v = cardView(mkInst(cid));
  check(v.desc && !v.desc.includes("undefined"), `card desc broken: ${cid} → ${v.desc}`);
  for (const e of CARDS[cid].fx) check(FX_DESC[e.k], `card ${cid} has fx kind without desc: ${e.k}`);
  const vu = cardView(mkInst(cid, true));
  check(vu.desc && !vu.desc.includes("undefined"), `upgraded desc broken: ${cid}`);
}

// 2. 角色資料完整：starter/pool 的卡都存在、starter 12 張
for (const chId of Object.keys(CHARACTERS)) {
  const ch = CHARACTERS[chId];
  for (const cid of [...ch.starter, ...ch.pool]) check(CARDS[cid], `${chId} 引用不存在的卡 ${cid}`);
  check(ch.starter.length === 12, `${chId} starter 應為 12 張，實際 ${ch.starter.length}`);
}

// 3. 遭遇組引用的敵人都存在
for (const tier of ["easy", "mid", "hard"]) {
  for (const grp of ENCOUNTERS[tier]) for (const eid of grp) check(ENEMIES[eid], `encounter 引用不存在的敵人 ${eid}`);
}
check(ENEMIES[ENCOUNTERS.boss], "boss 不存在");

// 4. 四角色各模擬三場戰鬥（貪婪 policy：打得起就打，單體丟第一個活敵）
function simBattle(enemyIds, opts) {
  startBattle(enemyIds, opts);
  let guard = 0;
  while (!battle.over && guard++ < 200) {
    let played = true;
    while (played && !battle.over) {
      played = false;
      for (let i = 0; i < battle.hand.length; i++) {
        const view = cardView(battle.hand[i]);
        if (effectiveCost(view) <= battle.energy) {
          const tgt = battle.enemies.findIndex((e) => e.hp > 0);
          if (playCard(i, tgt)) { played = true; break; }
        }
      }
    }
    if (!battle.over) endTurn();
  }
  check(battle.over, `戰鬥 200 迴圈未結束 (${enemyIds})`);
  return battle.won;
}

for (const chId of Object.keys(CHARACTERS)) {
  startRun(chId);
  const w1 = simBattle(["bandit"]);
  startRun(chId);
  const w2 = simBattle(["viper", "green_snake"]);
  startRun(chId);
  const w3 = simBattle(["red_eye_demon"], { boss: true });
  console.log(`${CHARACTERS[chId].name}: vs山賊=${w1 ? "勝" : "敗"} vs雙蛇=${w2 ? "勝" : "敗"} vs蛇妖男(boss)=${w3 ? "勝" : "敗"}`);
}

// 5. 地圖生成 30 次：層數與 boss 層
for (let i = 0; i < 30; i++) {
  const map = generateMap();
  check(map.length === 10, "地圖應為 10 層（9+boss）");
  check(map[9].length === 1 && map[9][0].type === "boss", "最後一層應為 boss");
}

// 6. boss phase 2 觸發
startRun("li");
startBattle(["red_eye_demon"], { boss: true });
const boss = battle.enemies[0];
boss.hp = Math.floor(boss.maxHp / 2);
dealRawDamageToEnemy(boss, 1);
check(boss.phased && boss.name === "狐妖女", "boss 半血應切換 phase 2");

// 7. 升級邏輯：數值卡加數值、無數值卡減費
const up1 = cardView(mkInst("lxy_yujian", true));
check(up1.fx[0].a === 10, `御劍術+ 應為 10 傷，實際 ${up1.fx[0].a}`);
const up2 = cardView(mkInst("lxy_xujian", true));
check(up2.c === 0, `蓄劍式+ 應減費為 0，實際 ${up2.c}`);

if (failures > 0) { console.log(`\n${failures} 項失敗`); process.exit(1); }
console.log("\nwebgame node smoke test passed.");
