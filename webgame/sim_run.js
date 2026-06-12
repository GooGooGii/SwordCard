// 全程 run 模擬器：node webgame/sim_run.js [runs]
// 會玩的人 policy：斬殺優先、致命先擋、毒角色先鋪毒、休息/商店/選卡有腦。
"use strict";
const fs = require("fs");
const path = require("path");
global.localStorage = { getItem: () => null, setItem: () => {}, removeItem: () => {} };
const game = ["data.js", "engine.js"].map((f) => fs.readFileSync(path.join(__dirname, f), "utf8")).join("\n");
const body = fs.readFileSync(__filename, "utf8").split("// ==== SIM" + " BODY ====")[1];
eval(game + "\n" + body);
process.exit(0);
/* 以下為模擬本體，只在 eval 內執行 */
// ==== SIM BODY ====

const N = parseInt(process.argv[2] || "200", 10);

// ── 戰鬥 policy ──
function cardScore(view, en) {
  // 粗略效益分
  let s = 0;
  for (const e of view.fx) {
    switch (e.k) {
      case "damage": s += e.a * (e.hits || 1); break;
      case "damage_all": s += e.a * (e.hits || 1) * aliveEnemies().length; break;
      case "poison": case "poison_all": s += e.a * 2.2; break;
      case "block": s += e.a * 0.8; break;
      case "heal": s += e.a * 0.6; break;
      case "draw": s += e.a * 2; break;
      case "energy": s += e.a * 2; break;
      case "power": case "power_per_turn": s += e.a * 4; break;
      case "poison_engine": s += e.a * 5; break;
      case "weak": case "weak_all": case "vulnerable": case "vulnerable_all": s += e.a * 3; break;
      case "poison_burst": s += (en ? en.poison : 0) * e.a; break;
      case "thorns": s += e.a * 1.5; break;
      default: s += 4;
    }
  }
  return s / Math.max(1, effectiveCost(view));
}

function incomingDamage() {
  let total = 0;
  for (const en of aliveEnemies()) total += predictIntentDamage(en);
  return total;
}

function damageOf(view, en) {
  let d = 0;
  for (const e of view.fx) {
    if (e.k === "damage") d += attackDamage(e.a, en, view.t === "attack") * (e.hits || 1);
    if (e.k === "damage_all") d += attackDamage(e.a, en, view.t === "attack") * (e.hits || 1);
    if (e.k === "poison_burst") d += en.poison * e.a;
    if (e.k === "damage_poison_bonus") d += attackDamage(e.a + en.poison * e.per, en, true);
    if (e.k === "damage_debuff_bonus") d += attackDamage(e.a + (en.weak + en.vuln) * e.per, en, true);
  }
  return d;
}

function playTurn() {
  let guard = 0;
  while (!battle.over && guard++ < 60) {
    const alive = aliveEnemies();
    if (!alive.length) return;
    // 1. 斬殺檢查：手上有牌能直接殺掉某敵就打
    let killPlay = null;
    for (let i = 0; i < battle.hand.length; i++) {
      const view = cardView(battle.hand[i]);
      if (effectiveCost(view) > battle.energy) continue;
      for (const en of alive) {
        if (damageOf(view, en) >= en.hp + en.block) { killPlay = [i, battle.enemies.indexOf(en)]; break; }
      }
      if (killPlay) break;
    }
    if (killPlay) { if (!playCard(killPlay[0], killPlay[1])) break; continue; }
    // 2. 否則挑分數最高的可打卡，目標選毒最多(毒爆)或血最少
    let best = null, bestScore = -1;
    for (let i = 0; i < battle.hand.length; i++) {
      const view = cardView(battle.hand[i]);
      if (effectiveCost(view) > battle.energy) continue;
      const tgtEn = view.fx.some((e) => e.k === "poison_burst" || e.k === "damage_poison_bonus")
        ? alive.reduce((a, b) => (a.poison > b.poison ? a : b))
        : alive.reduce((a, b) => (a.hp < b.hp ? a : b));
      // 致命威脅時防禦牌加權
      const threat = incomingDamage() - battle.player.block;
      let sc = cardScore(view, tgtEn);
      if (threat >= battle.player.hp * 0.5 && view.fx.some((e) => e.k === "block")) sc += 15;
      if (sc > bestScore) { bestScore = sc; best = [i, battle.enemies.indexOf(tgtEn)]; }
    }
    if (!best) return;
    if (!playCard(best[0], best[1])) return;
    // 用藥：血低於 35% 喝回春丹
    if (battle.player.hp < battle.player.maxHp * 0.35) {
      const idx = run.potions.indexOf("huichun_dan");
      if (idx >= 0) usePotion(idx);
    }
  }
}

function simBattleSmart(enemyIds, opts) {
  startBattle(enemyIds, opts);
  let guard = 0;
  const t0 = battle.turn;
  while (!battle.over && guard++ < 80) {
    playTurn();
    if (!battle.over) endTurn();
  }
  return { won: battle.won, turns: battle.turn - t0 + 1 };
}

// ── run policy ──
function pickNode() {
  const opts = reachableNodes();
  if (!opts.length) return null;
  const hpRatio = run.hp / run.maxHp;
  const score = ([l, i]) => {
    const t = run.map[l][i].type;
    if (t === "boss") return 0;
    if (t === "rest") return hpRatio < 0.6 ? 100 : 20;
    if (t === "elite") return hpRatio > 0.75 ? 60 : 5;
    if (t === "treasure") return 70;
    if (t === "shop") return run.gold > 80 ? 50 : 15;
    if (t === "event") return 40;
    return 30; // battle
  };
  return opts.reduce((a, b) => (score(a) >= score(b) ? a : b));
}

function pickCard(choices) {
  if (run.deck.length >= 22) return null; // 控牌組大小
  const rank = { rare: 3, uncommon: 2, basic: 1 };
  let best = null, bestS = -1;
  for (const cid of choices) {
    const c = CARDS[cid];
    let s = rank[c.r] * 10;
    if (c.t === "power") s += 6;
    if (c.fx.some((e) => e.k.startsWith("damage_all"))) s += 4;
    if (s > bestS) { bestS = s; best = cid; }
  }
  return best;
}

function simRun(chId) {
  startRun(chId);
  let fights = 0, totalTurns = 0;
  while (true) {
    const node = pickNode();
    if (!node) return { won: false, layer: run.layer, reason: "no-path", fights, totalTurns };
    const [l, i] = node;
    run.layer = l; run.nodeIdx = i;
    const type = run.map[l][i].type;
    run.map[l][i].done = true;
    if (type === "battle" || type === "elite" || type === "boss") {
      const tier = l <= 2 ? "easy" : l <= 5 ? "mid" : "hard";
      const ids = type === "boss" ? [ENCOUNTERS.boss] : type === "elite" ? [pick(ENCOUNTERS.elitePool)] : pick(ENCOUNTERS[tier]);
      const r = simBattleSmart(ids, { elite: type === "elite", boss: type === "boss" });
      fights++; totalTurns += r.turns;
      if (!r.won) return { won: false, layer: l, reason: type, fights, totalTurns, hp: 0 };
      const rewards = battleRewards(type);
      run.gold += rewards.gold;
      if (rewards.relic) run.relics.push(rewards.relic);
      if (rewards.potion && run.potions.length < 3) run.potions.push(rewards.potion);
      const picked = pickCard(rewards.cards);
      if (picked) run.deck.push(mkInst(picked));
      if (type === "boss") return { won: true, layer: l, fights, totalTurns, hp: run.hp };
    } else if (type === "rest") {
      if (run.hp < run.maxHp * 0.7) run.hp = Math.min(run.maxHp, run.hp + Math.round(run.maxHp * 0.3));
      else { const c = run.deck.find((x) => !x.up && CARDS[x.cid].t === "attack") || run.deck.find((x) => !x.up); if (c) c.up = true; }
    } else if (type === "shop") {
      const shop = buildShop();
      if (shop.relic && run.gold >= shop.relicPrice) { run.gold -= shop.relicPrice; run.relics.push(shop.relic); }
      for (const it of shop.potions) if (it && run.gold >= it.price && run.potions.length < 3) { run.gold -= it.price; run.potions.push(it.pid); }
    } else if (type === "treasure") {
      run.gold += 40;
      const rid = randomRelic();
      if (rid) run.relics.push(rid);
    } else if (type === "event") {
      run.hp = Math.min(run.maxHp, run.hp + 8); // 粗略：事件平均小賺
    }
  }
}

const stats = {};
for (const chId of Object.keys(CHARACTERS)) {
  const s = { wins: 0, deaths: {}, deathLayers: [], fightTurns: 0, fights: 0, bossHp: [] };
  for (let i = 0; i < N; i++) {
    const r = simRun(chId);
    if (r.won) { s.wins++; s.bossHp.push(r.hp); }
    else { s.deaths[r.reason] = (s.deaths[r.reason] || 0) + 1; s.deathLayers.push(r.layer); }
    s.fightTurns += r.totalTurns; s.fights += r.fights;
  }
  stats[chId] = s;
  const avgLayer = s.deathLayers.length ? (s.deathLayers.reduce((a, b) => a + b, 0) / s.deathLayers.length).toFixed(1) : "-";
  const avgBossHp = s.bossHp.length ? (s.bossHp.reduce((a, b) => a + b, 0) / s.bossHp.length).toFixed(0) : "-";
  console.log(`${CHARACTERS[chId].name}: 清關 ${(s.wins / N * 100).toFixed(0)}% | 死因 ${JSON.stringify(s.deaths)} | 平均死亡層 ${avgLayer} | 過關剩HP ${avgBossHp}/${CHARACTERS[chId].hp} | 平均戰鬥 ${(s.fightTurns / s.fights).toFixed(1)} 回合`);
}
