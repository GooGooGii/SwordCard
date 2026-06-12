// SwordCard Web — 戰鬥引擎 + Run 狀態（對齊 battle_controller.gd / effect_resolver.gd 的規則）
"use strict";

let _uidSeq = 1;
function mkInst(cid, up) { return { uid: _uidSeq++, cid, up: !!up }; }
function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}
function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

// ════════ Run 狀態 ════════
const run = {
  active: false, charId: null, hp: 0, maxHp: 0, gold: 99,
  deck: [], relics: [], potions: [],
  map: null, layer: -1, nodeIdx: -1, // 目前所在
  victory: false,
};

function hasRelic(id) { return run.relics.includes(id); }

function startRun(charId) {
  const ch = CHARACTERS[charId];
  run.active = true;
  run.charId = charId;
  run.maxHp = ch.hp;
  run.hp = ch.hp;
  run.gold = 99;
  run.deck = ch.starter.map((cid) => mkInst(cid));
  run.relics = [];
  run.potions = [];
  run.map = generateMap();
  run.layer = -1;
  run.nodeIdx = -1;
  run.victory = false;
  saveRun();
}

// ════════ 地圖生成：9 層 ×3 節點 + boss ════════
function generateMap() {
  const LAYERS = 9;
  const map = [];
  for (let l = 0; l < LAYERS; l++) {
    const row = [];
    for (let i = 0; i < 3; i++) {
      let type;
      if (l === 0) type = "battle";
      else if (l === 4 && i === 1) type = "treasure";
      else if (l === 7) type = i === 1 ? "rest" : pick(["battle", "shop", "event"]);
      else {
        const roll = Math.random();
        if (l >= 3 && roll < 0.13) type = "elite";
        else if (roll < 0.30) type = "event";
        else if (roll < 0.40) type = "rest";
        else if (roll < 0.50) type = "shop";
        else type = "battle";
      }
      row.push({ type, done: false });
    }
    map.push(row);
  }
  // 保底：第 7 層至少一個 rest（上面已保證 i==1）
  map.push([{ type: "boss", done: false }]);
  return map;
}

function reachableNodes() {
  // 回傳下一層可走的 [layer, idx] 列表
  const next = run.layer + 1;
  if (!run.map || next >= run.map.length) return [];
  const row = run.map[next];
  if (row.length === 1) return row.map((_, i) => [next, i]); // boss 層全可達
  if (run.layer < 0) return row.map((_, i) => [next, i]);    // 起點全可選
  const out = [];
  for (let i = 0; i < row.length; i++) {
    if (Math.abs(i - run.nodeIdx) <= 1) out.push([next, i]);
  }
  return out;
}

// ════════ 戰鬥狀態 ════════
let battle = null;

function makeEnemy(eid, opts) {
  const def = ENEMIES[eid];
  const elite = opts && opts.elite;
  const hp = Math.round(def.hp * (elite ? 1.45 : 1));
  return {
    eid, def, name: (elite ? "精英·" : "") + def.name, elite: !!elite,
    maxHp: hp, hp, block: 0, poison: 0, weak: 0, vuln: 0, strength: elite ? 3 : 0,
    thorns: 0, stun: 0, actionIdx: Math.floor(Math.random() * def.actions.length),
    phased: false, actCount: 0, enraged: false,
    img: def.img, scale: def.scale || 1,
  };
}

function enemyActions(en) {
  return en.phased && en.def.phase2 ? en.def.phase2.actions : en.def.actions;
}
function enemyIntent(en) { return enemyActions(en)[en.actionIdx]; }

// 敵人下一招的預測傷害（給 intent badge 用，對齊 predict_enemy_damage）
function predictIntentDamage(en) {
  const act = enemyIntent(en);
  let total = 0;
  for (const e of act.fx) {
    if (e.k !== "damage") continue;
    const hits = e.hits || 1;
    let d = e.a + en.strength;
    if (en.weak > 0) d = Math.floor(d * 0.75);
    if (battle && battle.player.vuln > 0) d = Math.floor(d * 1.5);
    total += d * hits;
  }
  return total;
}

function startBattle(enemyIds, opts) {
  const ch = CHARACTERS[run.charId];
  battle = {
    enemies: enemyIds.map((eid) => makeEnemy(eid, opts)),
    isBossFight: !!(opts && opts.boss),
    player: {
      hp: run.hp, maxHp: run.maxHp, block: 0, poison: 0, weak: 0, vuln: 0, power: 0, thorns: 0,
      nextAttackMult: 0, blockPerTurn: 0, powerPerTurn: 0, turnDamageAll: 0, poisonEngine: 0,
      blockPerAttack: 0, selfBlockBonus: 0, drawOnAttack: 0, drawOnSkill: 0, poisonOnAttack: 0,
    },
    energy: 3, maxEnergy: 3,
    draw: shuffle(run.deck.map((i) => ({ ...i }))), discard: [], hand: [], exhausted: [],
    turn: 0, log: [], events: [], over: false, won: false,
    firstAttackPlayed: false, linCounterUsed: false,
    goldStolen: 0,
  };
  // 被動：開戰觸發
  if (ch.passive.kind === "battle_start_power") battle.player.power += ch.passive.a;
  if (ch.passive.kind === "battle_start_enemy_poison") {
    for (const en of battle.enemies) en.poison += ch.passive.a;
    blog(`${ch.name} 下蠱！全體敵人中 ${ch.passive.a} 層蠱毒`);
  }
  if (hasRelic("guijiafu")) battle.player.block += 6;
  if (hasRelic("shedan")) for (const en of battle.enemies) en.poison += 2;
  startPlayerTurn();
  return battle;
}

function blog(msg) { battle.log.push(msg); if (battle.log.length > 60) battle.log.shift(); }
// 戰鬥事件（UI 浮動數字/震動用）：{t:'dmg'|'heal'|'block'|'crit', who:'p'|敵 index, n:數值}
function emit(t, who, n) { if (battle) battle.events.push({ t, who, n }); }
function weakElOf(en) {
  return en.phased && en.def.phase2 ? (en.def.phase2.weakEl || null) : (en.def.weakEl || null);
}

function drawCards(n) {
  for (let i = 0; i < n; i++) {
    if (battle.hand.length >= 10) return;
    if (battle.draw.length === 0) {
      if (battle.discard.length === 0) return;
      battle.draw = shuffle(battle.discard);
      battle.discard = [];
      blog("棄牌堆洗回抽牌堆");
    }
    battle.hand.push(battle.draw.pop());
  }
}

function startPlayerTurn() {
  const p = battle.player;
  battle.turn += 1;
  battle.energy = battle.maxEnergy;
  p.block = 0;
  battle.firstAttackPlayed = false;
  battle.linCounterUsed = false;
  // 每回合 power 引擎
  if (p.powerPerTurn > 0) { p.power += p.powerPerTurn; blog(`靈犀漸明，攻擊力 +${p.powerPerTurn}`); }
  if (p.blockPerTurn > 0) gainBlock(p.blockPerTurn);
  if (p.poisonEngine > 0) {
    for (const en of battle.enemies) if (en.hp > 0) en.poison += p.poisonEngine;
    blog(`蠱瘴瀰漫，全體敵人蠱毒 +${p.poisonEngine}`);
  }
  if (p.turnDamageAll > 0) {
    for (const en of battle.enemies) if (en.hp > 0) dealRawDamageToEnemy(en, p.turnDamageAll);
    blog(`五雷轟頂，全體敵人受 ${p.turnDamageAll} 點雷傷`);
    checkBattleEnd();
  }
  // 玩家蠱毒 tick
  if (p.poison > 0) {
    p.hp -= p.poison;
    blog(`你受到 ${p.poison} 點蠱毒傷害`);
    p.poison -= 1;
    if (p.hp <= 0) { defeat(); return; }
  }
  drawCards(5 + (hasRelic("yinhundie") ? 1 : 0));
}

function effectiveCost(view) {
  let cost = view.c;
  if (view.t === "attack" && !battle.firstAttackPlayed) {
    const passive = CHARACTERS[run.charId].passive;
    if (passive.kind === "first_attack_cost") cost -= 1;
    if (hasRelic("chunjun")) cost -= 1;
  }
  return Math.max(0, cost);
}

function gainBlock(n) {
  const p = battle.player;
  n += p.selfBlockBonus;
  p.block += n;
  emit("block", "p", n);
  // 林月如被動：每回合第一次獲得護體 → 反擊
  const passive = CHARACTERS[run.charId].passive;
  if (passive.kind === "first_block_counter" && !battle.linCounterUsed) {
    battle.linCounterUsed = true;
    const target = battle.enemies.find((e) => e.hp > 0);
    if (target) {
      dealRawDamageToEnemy(target, passive.a);
      blog(`月如反擊！${target.name} 受 ${passive.a} 點傷害`);
      checkBattleEnd();
    }
  }
}

// 純數值傷害（不吃 power/weak/vuln，例如荊棘/雷引擎/毒）
function dealRawDamageToEnemy(en, dmg) {
  const blocked = Math.min(en.block, dmg);
  en.block -= blocked;
  en.hp -= dmg - blocked;
  emit("dmg", battle.enemies.indexOf(en), dmg);
  checkPhase(en);
}

// 玩家攻擊單段傷害計算（el：卡片屬性，剋制敵人「畏」屬性 ×1.5）
function attackDamage(base, en, isAttackCard, el) {
  const p = battle.player;
  let d = base + p.power + (isAttackCard && hasRelic("liehuoling") ? 1 : 0);
  if (p.nextAttackMult > 0 && isAttackCard) d *= p.nextAttackMult;
  if (p.weak > 0) d = Math.floor(d * 0.75);
  if (en.vuln > 0) d = Math.floor(d * 1.5);
  if (el && weakElOf(en) === el) d = Math.floor(d * 1.5);
  return d;
}

function hitEnemy(en, base, opts) {
  // opts: {isAttackCard, pierce, raw, el}
  const el = opts && opts.el;
  const isCrit = !!(el && weakElOf(en) === el);
  const dmg = opts && opts.raw ? base : attackDamage(base, en, opts && opts.isAttackCard, el);
  let remain = dmg;
  if (!(opts && opts.pierce)) {
    const blocked = Math.min(en.block, remain);
    en.block -= blocked;
    remain -= blocked;
  }
  en.hp -= remain;
  emit(isCrit ? "crit" : "dmg", battle.enemies.indexOf(en), dmg);
  // 五毒淬刃：攻擊無護體敵人每段 +1 毒
  if (opts && opts.isAttackCard && battle.player.poisonOnAttack > 0 && en.block === 0 && en.hp > 0) {
    en.poison += battle.player.poisonOnAttack;
  }
  checkPhase(en);
  return dmg;
}

function checkPhase(en) {
  if (en.hp > 0 && !en.phased && en.def.phase2 && en.hp * 2 < en.maxHp) {
    en.phased = true;
    en.actionIdx = 0;
    en.name = en.def.phase2.name;
    en.img = en.def.phase2.img;
    blog(`${en.def.name} 倒下之際妖氣翻湧——${en.def.phase2.name} 現身！`);
  }
}

function aliveEnemies() { return battle.enemies.filter((e) => e.hp > 0); }

// ════════ 出牌 ════════
function playCard(handIdx, targetIdx) {
  if (battle.over) return false;
  const inst = battle.hand[handIdx];
  if (!inst) return false;
  const view = cardView(inst);
  const cost = effectiveCost(view);
  if (cost > battle.energy) return false;
  let target = battle.enemies[targetIdx];
  if (needsTarget(view) && (!target || target.hp <= 0)) {
    const alive = aliveEnemies();
    if (alive.length === 1) target = alive[0];
    else return false; // 多敵需指定目標
  }
  battle.energy -= cost;
  battle.hand.splice(handIdx, 1);

  const p = battle.player;
  const isAtk = view.t === "attack";
  let consumedMult = false;

  for (const e of view.fx) {
    switch (e.k) {
      case "damage": {
        const hits = e.hits || 1;
        for (let h = 0; h < hits; h++) {
          if (target.hp <= 0) break;
          const d = hitEnemy(target, e.a, { isAttackCard: isAtk, pierce: e.pierce, el: view.el });
          blog(`${view.n} → ${target.name} 受 ${d} 點傷害`);
        }
        if (isAtk) consumedMult = true;
        // 敵方反甲
        if (isAtk && target.thorns > 0) {
          damagePlayer(target.thorns, { raw: true });
          blog(`${target.name} 的反甲刺出 ${target.thorns} 點傷害`);
        }
        break;
      }
      case "damage_all": {
        const hits = e.hits || 1;
        for (let h = 0; h < hits; h++) {
          for (const en of aliveEnemies()) {
            const d = hitEnemy(en, e.a, { isAttackCard: isAtk, el: view.el });
            blog(`${view.n} → ${en.name} 受 ${d} 點傷害`);
          }
        }
        if (isAtk) consumedMult = true;
        break;
      }
      case "consume_energy_damage_all": {
        const times = battle.energy;
        battle.energy = 0;
        for (let i = 0; i < times; i++) {
          for (const en of aliveEnemies()) hitEnemy(en, e.a, { isAttackCard: isAtk, el: view.el });
        }
        blog(`${view.n} 耗盡 ${times} 點靈力，全體敵人共受 ${times} 輪 ${e.a} 點傷害`);
        if (isAtk) consumedMult = true;
        break;
      }
      case "damage_debuff_bonus": {
        const bonus = (target.weak + target.vuln) * e.per;
        const d = hitEnemy(target, e.a + bonus, { isAttackCard: isAtk, el: view.el });
        blog(`${view.n} → ${target.name} 受 ${d} 點傷害（debuff 加成 +${bonus}）`);
        consumedMult = true;
        break;
      }
      case "damage_debuff_bonus_all": {
        for (const en of aliveEnemies()) {
          const bonus = (en.weak + en.vuln) * e.per;
          const d = hitEnemy(en, e.a + bonus, { isAttackCard: isAtk, el: view.el });
          blog(`${view.n} → ${en.name} 受 ${d} 點傷害`);
        }
        consumedMult = true;
        break;
      }
      case "damage_poison_bonus": {
        const bonus = target.poison * e.per;
        const d = hitEnemy(target, e.a + bonus, { isAttackCard: isAtk, el: view.el });
        blog(`${view.n} → ${target.name} 受 ${d} 點傷害（蠱毒加成 +${bonus}）`);
        consumedMult = true;
        break;
      }
      case "poison_burst": {
        const layers = target.poison;
        if (layers > 0) {
          target.poison = 0;
          dealRawDamageToEnemy(target, layers * e.a);
          blog(`引爆 ${layers} 層蠱毒！${target.name} 受 ${layers * e.a} 點傷害`);
        } else blog(`${target.name} 身上沒有蠱毒可引爆`);
        break;
      }
      case "poison_multiply":
        target.poison *= e.a;
        blog(`${target.name} 蠱毒翻倍 → ${target.poison} 層`);
        break;
      case "block": gainBlock(e.a); break;
      case "block_multiply": p.block *= e.a; blog(`護體翻倍 → ${p.block}`); break;
      case "heal": p.hp = Math.min(p.maxHp, p.hp + e.a); emit("heal", "p", e.a); break;
      case "draw": drawCards(e.a); break;
      case "energy": battle.energy += e.a; break;
      case "self_damage": damagePlayer(e.a, { raw: true }); break;
      case "power": p.power += e.a; break;
      case "poison": target.poison += e.a; break;
      case "poison_all": for (const en of aliveEnemies()) en.poison += e.a; break;
      case "weak": target.weak += e.a; break;
      case "weak_all": for (const en of aliveEnemies()) en.weak += e.a; break;
      case "vulnerable": target.vuln += e.a; break;
      case "vulnerable_all": for (const en of aliveEnemies()) en.vuln += e.a; break;
      case "cure_debuff": p.poison = 0; p.weak = 0; p.vuln = 0; blog("負面狀態盡除"); break;
      case "thorns": p.thorns += e.a; break;
      case "next_attack_mult": p.nextAttackMult = e.a; break;
      case "power_per_turn": p.powerPerTurn += e.a; break;
      case "block_per_turn": p.blockPerTurn += e.a; break;
      case "turn_damage_all": p.turnDamageAll += e.a; break;
      case "poison_engine": p.poisonEngine += e.a; break;
      case "block_per_attack": p.blockPerAttack += e.a; break;
      case "self_block_bonus": p.selfBlockBonus += e.a; break;
      case "draw_on_attack": p.drawOnAttack += e.a; break;
      case "draw_on_skill": p.drawOnSkill += e.a; break;
      case "poison_on_attack": p.poisonOnAttack += e.a; break;
      case "steal": battle.goldStolen += e.a; blog(`偷到 ${e.a} 銅錢`); break;
      case "stun": {
        if (Math.random() < (e.chance || 1)) { target.stun += e.a; blog(`${target.name} 暈眩了！`); }
        else blog(`${target.name} 抵抗了暈眩`);
        break;
      }
    }
    if (battle.over) break;
  }

  if (consumedMult && p.nextAttackMult > 0) {
    blog(`蓄劍式釋放，傷害 ×${p.nextAttackMult}`);
    p.nextAttackMult = 0;
  }
  // 出牌觸發引擎
  if (isAtk) {
    battle.firstAttackPlayed = true;
    if (p.blockPerAttack > 0) gainBlock(p.blockPerAttack);
    if (p.drawOnAttack > 0) drawCards(p.drawOnAttack);
  }
  if (view.t === "skill" && p.drawOnSkill > 0) drawCards(p.drawOnSkill);

  // 牌去向
  if (view.t === "power" || view.ex) battle.exhausted.push(inst);
  else battle.discard.push(inst);

  if (p.hp <= 0) { defeat(); return true; }
  checkBattleEnd();
  return true;
}

function usePotion(slot) {
  if (!battle || battle.over) return false;
  const pot = run.potions[slot];
  if (!pot) return false;
  const def = POTIONS[pot];
  const p = battle.player;
  const target = aliveEnemies()[0];
  for (const e of def.fx) {
    switch (e.k) {
      case "heal": p.hp = Math.min(p.maxHp, p.hp + e.a); break;
      case "energy": battle.energy += e.a; break;
      case "block": gainBlock(e.a); break;
      case "cure_debuff": p.poison = 0; p.weak = 0; p.vuln = 0; break;
      case "damage": if (target) dealRawDamageToEnemy(target, e.a); break;
      case "vulnerable": if (target) target.vuln += e.a; break;
      case "weak": if (target) target.weak += e.a; break;
    }
  }
  blog(`使用 ${def.n}`);
  run.potions.splice(slot, 1);
  checkBattleEnd();
  return true;
}

// ════════ 敵人回合 ════════
function damagePlayer(dmg, opts) {
  const p = battle.player;
  let remain = dmg;
  if (!(opts && opts.pierce) && !(opts && opts.raw)) {
    const blocked = Math.min(p.block, remain);
    p.block -= blocked;
    remain -= blocked;
  } else if (opts && opts.raw) {
    // raw：直接扣血（反噬/反甲）
  } else {
    // pierce：無視護體
  }
  p.hp -= remain;
  emit("dmg", "p", remain);
  return remain;
}

function endTurn() {
  if (battle.over) return;
  const p = battle.player;
  // 棄手牌
  battle.discard.push(...battle.hand);
  battle.hand = [];
  // 玩家 debuff 衰減
  if (p.weak > 0) p.weak -= 1;
  if (p.vuln > 0) p.vuln -= 1;

  // 敵人行動
  for (const en of battle.enemies) {
    if (en.hp <= 0) continue;
    // 蠱毒 tick
    if (en.poison > 0) {
      en.hp -= en.poison;
      blog(`${en.name} 受 ${en.poison} 點蠱毒侵蝕`);
      en.poison -= 1;
      if (en.hp <= 0) { blog(`${en.name} 毒發身亡！`); checkPhase(en); continue; }
    }
    if (en.stun > 0) { en.stun -= 1; blog(`${en.name} 暈眩中，無法行動`); continue; }
    en.block = 0;
    const act = enemyIntent(en);
    for (const e of act.fx) {
      switch (e.k) {
        case "damage": {
          const hits = e.hits || 1;
          for (let h = 0; h < hits; h++) {
            let d = e.a + en.strength;
            if (en.weak > 0) d = Math.floor(d * 0.75);
            if (p.vuln > 0) d = Math.floor(d * 1.5);
            const dealt = damagePlayer(d, { pierce: e.pierce });
            blog(`${en.name} 的「${act.intent}」造成 ${dealt} 點傷害`);
          }
          // 玩家荊棘
          if (p.thorns > 0) {
            dealRawDamageToEnemy(en, p.thorns);
            blog(`荊棘反彈 ${p.thorns} 點傷害給 ${en.name}`);
          }
          break;
        }
        case "block": en.block += e.a; blog(`${en.name} 獲得 ${e.a} 點護體`); break;
        case "poison": p.poison += e.a; blog(`${en.name} 對你施加 ${e.a} 層蠱毒`); break;
        case "weak": p.weak += e.a; blog(`${en.name} 使你虛弱 ${e.a} 層`); break;
        case "vulnerable": p.vuln += e.a; blog(`${en.name} 使你破綻 ${e.a} 層`); break;
        case "enemy_thorns": en.thorns += e.a; blog(`${en.name} 獲得 ${e.a} 點反甲`); break;
        case "enemy_strength": en.strength += e.a; blog(`${en.name} 攻擊力 +${e.a}！`); break;
        case "strip_block": p.block = 0; blog(`${en.name} 碎甲！你的護體歸零`); break;
      }
      if (p.hp <= 0) break;
    }
    if (p.hp <= 0) { defeat(); return; }
    // enrage_after 被動
    en.actCount += 1;
    if (en.def.passive && en.def.passive.kind === "enrage_after" && !en.enraged
      && en.actCount >= en.def.passive.turns) {
      en.enraged = true;
      en.strength += en.def.passive.a;
      blog(`${en.name} 狂暴了！力量 +${en.def.passive.a}`);
    }
    // debuff 衰減 + 換下一招
    if (en.weak > 0) en.weak -= 1;
    if (en.vuln > 0) en.vuln -= 1;
    en.actionIdx = (en.actionIdx + 1) % enemyActions(en).length;
  }
  checkBattleEnd();
  if (!battle.over) startPlayerTurn();
}

function checkBattleEnd() {
  if (battle.over) return;
  if (aliveEnemies().length === 0) {
    battle.over = true;
    battle.won = true;
    run.hp = battle.player.hp;
    if (hasRelic("nuwashi")) run.hp = Math.min(run.maxHp, run.hp + 6);
  }
}

function defeat() {
  battle.over = true;
  battle.won = false;
  run.hp = 0;
  clearSave();
}

// 戰鬥獎勵
function battleRewards(nodeType) {
  const isElite = nodeType === "elite";
  const isBoss = nodeType === "boss";
  let gold = isBoss ? 100 : isElite ? 55 : 25 + Math.floor(Math.random() * 11);
  if (hasRelic("qiandai")) gold += 15;
  gold += battle.goldStolen;
  const rewards = { gold, cards: cardChoices(), relic: null, potion: null };
  if (isElite || isBoss) rewards.relic = randomRelic();
  else if (Math.random() < 0.2 && run.potions.length < 3) rewards.potion = pick(Object.keys(POTIONS));
  return rewards;
}

function cardChoices() {
  const ch = CHARACTERS[run.charId];
  const pool = [...ch.pool];
  const out = [];
  const wantColorless = Math.random() < 0.12;
  for (let i = 0; i < 3; i++) {
    let src = pool;
    if (wantColorless && i === 2) src = [...COLORLESS_POOL];
    // 稀有度加權抽取
    const weighted = [];
    for (const cid of src) {
      const r = CARDS[cid].r;
      const w = r === "rare" ? 2 : r === "uncommon" ? 6 : 3;
      for (let j = 0; j < w; j++) weighted.push(cid);
    }
    let cid = pick(weighted);
    while (out.includes(cid)) cid = pick(weighted);
    out.push(cid);
  }
  return out;
}

function randomRelic() {
  const owned = new Set(run.relics);
  const avail = Object.keys(RELICS).filter((id) => !owned.has(id));
  if (avail.length === 0) return null;
  return pick(avail);
}

// ════════ 商店 ════════
function buildShop() {
  const prices = { basic: 45, uncommon: 70, rare: 110 };
  const cards = cardChoices().map((cid) => ({ cid, price: prices[CARDS[cid].r] }));
  const potions = shuffle(Object.keys(POTIONS)).slice(0, 2).map((pid) => ({ pid, price: POTIONS[pid].price }));
  const relic = randomRelic();
  return { cards, potions, relic, relicPrice: 120, removePrice: 75, removed: false };
}

// ════════ 存檔 ════════
function saveRun() {
  if (!run.active) return;
  try {
    localStorage.setItem("swordcard_save", JSON.stringify({
      charId: run.charId, hp: run.hp, maxHp: run.maxHp, gold: run.gold,
      deck: run.deck, relics: run.relics, potions: run.potions,
      map: run.map, layer: run.layer, nodeIdx: run.nodeIdx,
    }));
  } catch (e) { /* localStorage 不可用就算了 */ }
}
function loadRun() {
  try {
    const raw = localStorage.getItem("swordcard_save");
    if (!raw) return false;
    const d = JSON.parse(raw);
    Object.assign(run, d);
    run.active = true;
    run.victory = false;
    _uidSeq = Math.max(..._uidSeq ? [_uidSeq] : [1], ...run.deck.map((c) => c.uid)) + 1;
    return true;
  } catch (e) { return false; }
}
function hasSave() { try { return !!localStorage.getItem("swordcard_save"); } catch (e) { return false; } }
function clearSave() { try { localStorage.removeItem("swordcard_save"); } catch (e) { } }
