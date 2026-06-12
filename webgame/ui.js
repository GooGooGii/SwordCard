// SwordCard Web — UI 層（全程式碼建構，對齊 main.gd 的 screen 思路）
"use strict";

const app = document.getElementById("app");
const NODE_ICONS = { battle: "⚔", elite: "🔥", event: "❓", rest: "🏮", shop: "🪙", treasure: "📦", boss: "👹" };
const NODE_NAMES = { battle: "戰鬥", elite: "精英", event: "奇遇", rest: "休息", shop: "商店", treasure: "寶箱", boss: "頭目" };
const TYPE_NAMES = { attack: "攻擊", skill: "技能", power: "能力" };

let ui = { screen: "menu", selectedCard: -1, shop: null, pendingRewards: null, rewardNodeType: null };

function h(tag, cls, html) {
  const el = document.createElement(tag);
  if (cls) el.className = cls;
  if (html !== undefined) el.innerHTML = html;
  return el;
}

// ════════ 卡片 DOM（重製版：滿幅插圖 + 直書卡名 + 印章 + 屬性章）════════
const SEAL_CHARS = { attack: "攻", skill: "技", power: "能" };
function cardEl(view, opts) {
  const el = h("div", `card t-${view.t} r-${view.r}${opts && opts.big ? " bigger" : ""}`);
  const img = h("img", "art");
  img.src = `assets/cards/${view.cid}.png`;
  img.onerror = () => { img.style.display = "none"; };
  el.appendChild(img);
  const cost = opts && opts.costOverride !== undefined ? opts.costOverride : view.c;
  el.appendChild(h("div", "cost", String(cost)));
  if (view.el && ELEMENTS[view.el]) {
    const badge = h("div", "el-badge", ELEMENTS[view.el].n);
    badge.style.background = ELEMENTS[view.el].c;
    badge.title = `${ELEMENTS[view.el].n}屬性：剋制畏${ELEMENTS[view.el].n}的敵人（傷害 ×1.5）`;
    el.appendChild(badge);
  }
  el.appendChild(h("div", `vname${view.up ? " upgraded" : ""}`, view.n));
  el.appendChild(h("div", "desc", view.desc));
  const seal = h("div", "seal", SEAL_CHARS[view.t] || "卡");
  seal.title = `${TYPE_NAMES[view.t]} · ${view.r === "rare" ? "稀有" : view.r === "uncommon" ? "精良" : "基礎"}`;
  el.appendChild(seal);
  return el;
}

// ════════ 頂部狀態列 ════════
function topbar(showDeck) {
  const bar = h("div", "topbar");
  const ch = CHARACTERS[run.charId];
  bar.appendChild(h("span", "", `<b style="color:var(--gold-bright)">${ch.name}</b>`));
  bar.appendChild(h("span", "hp-text", `❤ ${run.hp}/${run.maxHp}`));
  bar.appendChild(h("span", "gold-text", `🪙 ${run.gold}`));
  for (const rid of run.relics) {
    const r = RELICS[rid];
    const chip = h("span", "relic-chip", r.icon);
    chip.title = `${r.n}：${r.d}`;
    bar.appendChild(chip);
  }
  for (let i = 0; i < run.potions.length; i++) {
    const p = POTIONS[run.potions[i]];
    const chip = h("span", "relic-chip potion-chip", p.icon);
    chip.title = `${p.n}：${p.d}（戰鬥中點擊使用）`;
    bar.appendChild(chip);
  }
  bar.appendChild(h("span", "spacer"));
  if (showDeck) {
    const deckBtn = h("button", "btn small", `牌組 (${run.deck.length})`);
    deckBtn.onclick = () => showDeckOverlay();
    bar.appendChild(deckBtn);
  }
  const quitBtn = h("button", "btn small", "回主選單");
  quitBtn.onclick = () => { saveRun(); renderMenu(); };
  bar.appendChild(quitBtn);
  return bar;
}

// ════════ 主選單 ════════
function renderMenu() {
  ui.screen = "menu";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/main_menu_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.style.justifyContent = "center";
  s.appendChild(h("div", "title-calligraphy", "劍卡奇緣"));
  s.appendChild(h("div", "subtitle", "仙劍卡牌 · 餘杭篇"));
  const btns = h("div", "", "");
  btns.id = "menu-buttons";
  if (hasSave()) {
    const cont = h("button", "btn primary", "繼續征途");
    cont.onclick = () => { if (loadRun()) renderMap(); };
    btns.appendChild(cont);
  }
  const start = h("button", "btn primary", "開始遊戲");
  start.onclick = renderCharSelect;
  btns.appendChild(start);
  s.appendChild(btns);
  s.appendChild(h("div", "subtitle", "<br>私人粉絲向原型 · 靈感來自仙劍奇俠傳"));
  app.appendChild(s);
}

// ════════ 角色選擇 ════════
function renderCharSelect() {
  ui.screen = "charselect";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/main_menu_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.style.justifyContent = "center";
  const title = h("h2", "", "選擇角色");
  title.style.cssText = "color:var(--gold-bright);letter-spacing:8px;font-size:30px;margin-bottom:24px;z-index:1";
  s.appendChild(title);
  const grid = h("div", "char-grid");
  for (const cid of ["li", "zhao", "lin", "anu"]) {
    const ch = CHARACTERS[cid];
    const card = h("div", "char-card");
    card.innerHTML = `<img src="assets/portraits/${ch.id === "li" ? "li_xiaoyao" : ch.id === "zhao" ? "zhao_linger" : ch.id === "lin" ? "lin_yueru" : "anu"}.png">
      <h3>${ch.name}</h3><div class="hp">❤ ${ch.hp}</div>
      <div class="style">${ch.style}</div>
      <div class="passive">被動：${ch.passive.label}</div>`;
    card.onclick = () => { startRun(cid); renderMap(); };
    grid.appendChild(card);
  }
  s.appendChild(grid);
  app.appendChild(s);
}

// ════════ 山水卷軸地圖：橫向手卷，左起餘杭、右至妖窟（boss）════════
const COL_W = 150;
function nodePos(l, i, count, innerH) {
  // 沿卷軸蜿蜒的路徑：x 依層推進、y 以正弦擺動 + 同層節點上下展開
  const x = 110 + l * COL_W;
  const mid = innerH * 0.52 + Math.sin(l * 1.15) * innerH * 0.1;
  const spread = innerH * 0.26;
  const y = count === 1 ? mid : mid + (i - (count - 1) / 2) * spread;
  return [x, Math.max(innerH * 0.14, Math.min(innerH * 0.88, y))];
}

function renderMap() {
  ui.screen = "map";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.background = "#171410";
  s.appendChild(topbar(true));
  const wrap = h("div", "scroll-wrap");
  const inner = h("div", "scroll-inner");
  const totalW = 110 + run.map.length * COL_W + 130;
  inner.style.width = `${totalW}px`;
  inner.appendChild(h("div", "scroll-title", "餘杭行旅圖"));

  const reach = reachableNodes().map(([l, i]) => `${l},${i}`);
  s.appendChild(wrap);
  wrap.appendChild(inner);
  app.appendChild(s); // 先掛上去才量得到高度
  const innerH = wrap.clientHeight || 600;
  inner.style.height = "100%";

  // 墨線路徑（SVG）：畫所有相鄰層可走的邊
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", "scroll-edges");
  svg.setAttribute("width", totalW);
  svg.setAttribute("height", innerH);
  for (let l = 0; l < run.map.length - 1; l++) {
    const cur = run.map[l], nxt = run.map[l + 1];
    for (let i = 0; i < cur.length; i++) {
      for (let j = 0; j < nxt.length; j++) {
        if (nxt.length > 1 && Math.abs(j - i) > 1) continue;
        const [x1, y1] = nodePos(l, i, cur.length, innerH);
        const [x2, y2] = nodePos(l + 1, j, nxt.length, innerH);
        const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
        const mx = (x1 + x2) / 2;
        path.setAttribute("d", `M${x1} ${y1} C${mx} ${y1}, ${mx} ${y2}, ${x2} ${y2}`);
        path.setAttribute("fill", "none");
        path.setAttribute("stroke", "rgba(40,32,20,.55)");
        path.setAttribute("stroke-width", "2.5");
        path.setAttribute("stroke-dasharray", "1 7");
        path.setAttribute("stroke-linecap", "round");
        svg.appendChild(path);
      }
    }
  }
  inner.appendChild(svg);

  for (let l = 0; l < run.map.length; l++) {
    for (let i = 0; i < run.map[l].length; i++) {
      const node = run.map[l][i];
      const [x, y] = nodePos(l, i, run.map[l].length, innerH);
      const el = h("div", `map-node${node.type === "boss" ? " boss-node" : ""}`, NODE_ICONS[node.type]);
      el.style.left = `${x}px`;
      el.style.top = `${y}px`;
      el.appendChild(h("div", "nlabel", NODE_NAMES[node.type]));
      if (node.done) el.classList.add("done");
      if (l === run.layer && i === run.nodeIdx) el.classList.add("current");
      if (reach.includes(`${l},${i}`)) {
        el.classList.add("reachable");
        el.onclick = () => enterNode(l, i);
      }
      inner.appendChild(el);
    }
  }
  // 視窗捲到目前位置附近
  const focusL = Math.max(0, run.layer);
  wrap.scrollLeft = Math.max(0, 110 + focusL * COL_W - wrap.clientWidth * 0.35);
}

function enterNode(l, i) {
  run.layer = l;
  run.nodeIdx = i;
  const node = run.map[l][i];
  node.done = true;
  // 戰鬥節點不在進入時存檔：重新整理會回到戰前地圖重打，而不是白拿過關
  if (!["battle", "elite", "boss"].includes(node.type)) saveRun();
  switch (node.type) {
    case "battle": {
      const tier = l <= 2 ? "easy" : l <= 5 ? "mid" : "hard";
      startBattle(pick(ENCOUNTERS[tier]));
      ui.rewardNodeType = "battle";
      ui.selectedCard = -1;
      renderBattle();
      break;
    }
    case "elite":
      startBattle([pick(ENCOUNTERS.elitePool)], { elite: true });
      ui.rewardNodeType = "elite";
      ui.selectedCard = -1;
      renderBattle();
      break;
    case "boss":
      startBattle([ENCOUNTERS.boss], { boss: true });
      ui.rewardNodeType = "boss";
      ui.selectedCard = -1;
      renderBattle();
      break;
    case "event": renderEvent(pick(EVENTS)); break;
    case "rest": renderRest(); break;
    case "shop": ui.shop = buildShop(); renderShop(); break;
    case "treasure": renderTreasure(); break;
  }
}

// ════════ 戰鬥 ════════
function renderBattle() {
  ui.screen = "battle";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/battle_bg_act_1.png)";
  s.appendChild(topbarBattle());

  const field = h("div", "battle-field");
  // 玩家
  const pSide = h("div", "side player-side");
  const ch = CHARACTERS[run.charId];
  const pc = h("div", "combatant");
  pc.id = "player-combatant";
  const pImg = h("img", "portrait");
  pImg.src = `assets/portraits/${ch.id === "li" ? "li_xiaoyao" : ch.id === "zhao" ? "zhao_linger" : ch.id === "lin" ? "lin_yueru" : "anu"}.png`;
  pc.appendChild(pImg);
  pc.appendChild(h("div", "cname", ch.name));
  pc.appendChild(playerHpBar());
  pc.appendChild(playerStatusRow());
  pSide.appendChild(pc);
  field.appendChild(pSide);

  // 敵人
  const eSide = h("div", "side enemy-side");
  battle.enemies.forEach((en, idx) => {
    const c = h("div", `combatant${battle.enemies.length >= 3 || en.scale < 0.9 ? " small" : ""}`);
    c.id = `enemy-${idx}`;
    if (en.hp <= 0) c.classList.add("dead");
    c.appendChild(intentEl(en));
    const img = h("img", "portrait");
    img.src = `assets/enemies/${en.img}.png`;
    // 原圖已面向左（朝玩家）的不翻；其餘翻轉面向玩家
    const flip = en.def.facingLeft ? "" : "scaleX(-1) ";
    img.style.transform = `${flip}scale(${Math.min(en.scale, 1.15)})`;
    if (en.def.tint) img.style.filter = en.def.tint;
    c.appendChild(img);
    const nameRow = h("div", "cname", en.name);
    const wel = weakElOf(en);
    if (wel && ELEMENTS[wel]) {
      const chip = h("span", "weak-chip", ` 畏${ELEMENTS[wel].n}`);
      chip.style.color = ELEMENTS[wel].c;
      chip.style.marginLeft = "6px";
      chip.title = `以${ELEMENTS[wel].n}屬性攻擊可造成 1.5 倍傷害`;
      nameRow.appendChild(chip);
    }
    c.appendChild(nameRow);
    c.appendChild(enemyHpBar(en));
    c.appendChild(enemyStatusRow(en));
    c.onclick = () => onEnemyClick(idx);
    eSide.appendChild(c);
  });
  field.appendChild(eSide);
  s.appendChild(field);

  // HUD
  const hud = h("div", "battle-hud");
  hud.appendChild(h("div", "energy-orb", `${battle.energy}<span style="font-size:13px">/${battle.maxEnergy}</span>`));
  const drawInfo = h("div", "pile-info", `抽牌堆 ${battle.draw.length}`);
  const discInfo = h("div", "pile-info", `棄牌堆 ${battle.discard.length}`);
  hud.appendChild(drawInfo);
  hud.appendChild(discInfo);
  s.appendChild(hud);

  const endBtn = h("button", "btn primary end-turn", ui.endConfirm ? `再按確認 · 剩 ${battle.energy} 靈力` : "結束回合");
  endBtn.onclick = () => {
    // 還有靈力且有可打的卡 → 第一下先確認（對齊 Godot 版防呆）
    const hasPlayable = battle.hand.some((inst) => effectiveCost(cardView(inst)) <= battle.energy);
    if (!ui.endConfirm && battle.energy > 0 && hasPlayable) {
      ui.endConfirm = true;
      renderBattle();
      clearTimeout(ui.endConfirmTimer);
      ui.endConfirmTimer = setTimeout(() => {
        if (ui.endConfirm && !battle.over) { ui.endConfirm = false; doEndTurn(); }
      }, 1500);
      return;
    }
    ui.endConfirm = false;
    clearTimeout(ui.endConfirmTimer);
    doEndTurn();
  };
  s.appendChild(endBtn);

  // Boss 定場詩
  if (battle.isBossFight && battle.turn <= 2) {
    s.appendChild(h("div", "boss-poem", battle.enemies[0].phased
      ? "狐裘換骨月無光，魅影重重欲斷腸"
      : "青鱗蔽月妖風起，雷火照山蛇影寒"));
  }

  s.appendChild(h("div", "turn-banner", `第 ${battle.turn} 回合${battle.isBossFight ? " · 頭目戰" : ""}`));

  const log = h("div", "battle-log");
  log.innerHTML = battle.log.slice(-14).map((m) => `<div>${m}</div>`).join("");
  s.appendChild(log);
  log.scrollTop = log.scrollHeight;

  // 手牌（扇形排列，對齊 hand_fan.gd 的弧線感）
  const hand = h("div", "hand-area");
  const n = battle.hand.length;
  const mid = (n - 1) / 2;
  battle.hand.forEach((inst, idx) => {
    const view = cardView(inst);
    const cost = effectiveCost(view);
    const el = cardEl(view, { costOverride: cost });
    const off = idx - mid;
    el.style.setProperty("--rot", `${off * 4}deg`);
    el.style.setProperty("--ty", `${off * off * 3.5}px`);
    if (cost > battle.energy) el.classList.add("unaffordable");
    if (ui.selectedCard === idx) el.classList.add("selected");
    el.onclick = (ev) => { ev.stopPropagation(); onCardClick(idx); };
    hand.appendChild(el);
  });
  s.appendChild(hand);

  if (ui.selectedCard >= 0) {
    s.appendChild(h("div", "target-hint", "點選目標敵人"));
  }
  app.appendChild(s);

  if (battle.over) showBattleResult();
}

function topbarBattle() {
  const bar = h("div", "topbar");
  const ch = CHARACTERS[run.charId];
  bar.appendChild(h("span", "", `<b style="color:var(--gold-bright)">${ch.name}</b>`));
  bar.appendChild(h("span", "hp-text", `❤ ${battle.player.hp}/${battle.player.maxHp}`));
  bar.appendChild(h("span", "gold-text", `🪙 ${run.gold}`));
  for (const rid of run.relics) {
    const r = RELICS[rid];
    const chip = h("span", "relic-chip", r.icon);
    chip.title = `${r.n}：${r.d}`;
    bar.appendChild(chip);
  }
  run.potions.forEach((pid, i) => {
    const p = POTIONS[pid];
    const chip = h("span", "relic-chip potion-chip", p.icon);
    chip.title = `${p.n}：${p.d}（點擊使用）`;
    chip.onclick = () => { if (usePotion(i)) afterAction(); };
    bar.appendChild(chip);
  });
  bar.appendChild(h("span", "spacer"));
  bar.appendChild(h("span", "", `<span style="color:var(--text-muted);font-size:13px">${ch.passive.label}</span>`));
  return bar;
}

function playerHpBar() {
  const p = battle.player;
  const wrap = h("div", "");
  const bar = h("div", "hp-bar");
  const fill = h("div", "fill");
  fill.style.width = `${Math.max(0, (p.hp / p.maxHp) * 100)}%`;
  bar.appendChild(fill);
  wrap.appendChild(bar);
  wrap.appendChild(h("div", "hp-num", `${Math.max(0, p.hp)} / ${p.maxHp}`));
  return wrap;
}

function enemyHpBar(en) {
  const wrap = h("div", "");
  const bar = h("div", "hp-bar");
  const fill = h("div", "fill");
  fill.style.width = `${Math.max(0, (en.hp / en.maxHp) * 100)}%`;
  bar.appendChild(fill);
  wrap.appendChild(bar);
  wrap.appendChild(h("div", "hp-num", `${Math.max(0, en.hp)} / ${en.maxHp}`));
  return wrap;
}

function statusChips(obj) {
  const row = h("div", "status-row");
  if (obj.block > 0) row.appendChild(h("span", "status-chip block", `護體 ${obj.block}`));
  if (obj.poison > 0) row.appendChild(h("span", "status-chip poison", `蠱毒 ${obj.poison}`));
  if (obj.weak > 0) row.appendChild(h("span", "status-chip weak", `虛弱 ${obj.weak}`));
  if (obj.vuln > 0) row.appendChild(h("span", "status-chip vuln", `破綻 ${obj.vuln}`));
  return row;
}
function playerStatusRow() {
  const p = battle.player;
  const row = statusChips(p);
  if (p.power > 0) row.appendChild(h("span", "status-chip power", `力量 ${p.power}`));
  if (p.thorns > 0) row.appendChild(h("span", "status-chip power", `荊棘 ${p.thorns}`));
  if (p.nextAttackMult > 0) row.appendChild(h("span", "status-chip power", `蓄劍 ×${p.nextAttackMult}`));
  return row;
}
function enemyStatusRow(en) {
  const row = statusChips(en);
  if (en.strength > 0) row.appendChild(h("span", "status-chip power", `力量 ${en.strength}`));
  if (en.thorns > 0) row.appendChild(h("span", "status-chip power", `反甲 ${en.thorns}`));
  if (en.stun > 0) row.appendChild(h("span", "status-chip weak", `暈眩 ${en.stun}`));
  return row;
}

function intentEl(en) {
  if (en.hp <= 0) return h("div", "intent", "—");
  const act = enemyIntent(en);
  const dmg = predictIntentDamage(en);
  let txt = `意圖：${act.intent}`;
  if (dmg > 0) txt += ` <span class="dmg">${dmg}</span>`;
  const blk = act.fx.filter((e) => e.k === "block").reduce((s, e) => s + e.a, 0);
  if (blk > 0) txt += ` <span style="color:var(--block-blue)">防${blk}</span>`;
  if (en.def.passive && !en.enraged) {
    txt += `<br><span style="color:var(--text-muted);font-size:11px">${en.def.passive.label}</span>`;
  }
  return h("div", "intent", txt);
}

function onCardClick(idx) {
  if (battle.over) return;
  const inst = battle.hand[idx];
  const view = cardView(inst);
  if (effectiveCost(view) > battle.energy) return;
  if (needsTarget(view) && aliveEnemies().length > 1) {
    ui.selectedCard = ui.selectedCard === idx ? -1 : idx;
    renderBattle();
    return;
  }
  const tgt = battle.enemies.indexOf(aliveEnemies()[0]);
  playWithAnim(idx, tgt);
}

function onEnemyClick(idx) {
  if (ui.selectedCard < 0) return;
  if (battle.enemies[idx].hp <= 0) return;
  const cardIdx = ui.selectedCard;
  ui.selectedCard = -1;
  playWithAnim(cardIdx, idx);
}

// 出牌動畫：卡片殘影從手牌飛向目標 + 攻擊卡玩家突進
function playWithAnim(handIdx, targetIdx) {
  const inst = battle.hand[handIdx];
  if (!inst) return false;
  const view = cardView(inst);
  const srcEl = document.querySelectorAll(".hand-area .card")[handIdx];
  const srcRect = srcEl ? srcEl.getBoundingClientRect() : null;
  const isAtk = view.t === "attack";
  const targetsEnemy = needsTarget(view) || view.fx.some((e) => e.k.includes("_all") && e.k !== "heal_party");
  if (!playCard(handIdx, targetIdx)) return false;
  afterAction();
  if (srcRect) {
    const ghost = cardEl(view);
    ghost.classList.add("card-ghost");
    ghost.style.left = `${srcRect.left}px`;
    ghost.style.top = `${srcRect.top}px`;
    document.body.appendChild(ghost);
    const tgtEl = targetsEnemy
      ? (document.getElementById(`enemy-${targetIdx}`) || document.getElementById("player-combatant"))
      : document.getElementById("player-combatant");
    const tgtRect = tgtEl ? tgtEl.getBoundingClientRect() : null;
    requestAnimationFrame(() => requestAnimationFrame(() => {
      if (tgtRect) {
        ghost.style.left = `${tgtRect.left + tgtRect.width / 2 - 70}px`;
        ghost.style.top = `${tgtRect.top + tgtRect.height * 0.25}px`;
      }
      ghost.style.transform = "scale(.3) rotate(10deg)";
      ghost.style.opacity = "0";
    }));
    setTimeout(() => ghost.remove(), 440);
  }
  if (isAtk) {
    const pEl = document.getElementById("player-combatant");
    if (pEl) { pEl.classList.add("lunge-r"); setTimeout(() => pEl.classList.remove("lunge-r"), 380); }
  }
  return true;
}

// 敵人回合：逐隻向左撲擊的突進動畫
function doEndTurn() {
  const actors = battle.enemies.map((e, i) => (e.hp > 0 && e.stun <= 0 ? i : -1)).filter((i) => i >= 0);
  endTurn();
  afterAction();
  actors.forEach((i, k) => setTimeout(() => {
    const el = document.getElementById(`enemy-${i}`);
    if (el && !el.classList.contains("dead")) {
      el.classList.add("lunge-l");
      setTimeout(() => el.classList.remove("lunge-l"), 380);
    }
  }, 120 + k * 220));
}

function afterAction() {
  ui.endConfirm = false;
  ui.selectedCard = -1;
  const events = battle.events.splice(0);
  renderBattle();
  // 浮動數字 + 受擊震動（事件在結算時收集、渲染後依序播放）
  events.forEach((ev, i) => {
    setTimeout(() => {
      const anchor = ev.who === "p"
        ? document.getElementById("player-combatant")
        : document.getElementById(`enemy-${ev.who}`);
      if (!anchor) return;
      const r = anchor.getBoundingClientRect();
      const pop = h("div", `popup-num ${ev.t === "heal" ? "heal" : ev.t === "block" ? "blk" : ev.t === "crit" ? "crit" : "dmg"}`);
      pop.textContent = ev.t === "crit" ? `剋！-${ev.n}` : ev.t === "dmg" ? `-${ev.n}` : `+${ev.n}`;
      pop.style.left = `${r.left + r.width * (0.3 + Math.random() * 0.4)}px`;
      pop.style.top = `${r.top + r.height * 0.3}px`;
      document.body.appendChild(pop);
      window._popupsSpawned = (window._popupsSpawned || 0) + 1;
      setTimeout(() => pop.remove(), 950);
      if (ev.t === "dmg" || ev.t === "crit") {
        anchor.classList.remove("shake");
        void anchor.offsetWidth; // 重觸發動畫
        anchor.classList.add("shake");
      }
    }, i * 140);
  });
}

function showBattleResult() {
  if (battle.won) {
    const rewards = battleRewards(ui.rewardNodeType);
    run.gold += rewards.gold;
    ui.pendingRewards = rewards;
    saveRun();
    const ov = h("div", "overlay");
    const panel = h("div", "panel");
    panel.appendChild(h("h2", "", ui.rewardNodeType === "boss" ? "妖氛盡掃" : "戰鬥勝利"));
    panel.appendChild(h("p", "flavor", `獲得 ${rewards.gold} 銅錢`));
    if (rewards.relic) {
      const r = RELICS[rewards.relic];
      run.relics.push(rewards.relic);
      panel.appendChild(h("p", "flavor", `獲得遺物【${r.n}】——${r.d}`));
    }
    if (rewards.potion && run.potions.length < 3) {
      run.potions.push(rewards.potion);
      panel.appendChild(h("p", "flavor", `拾得藥品【${POTIONS[rewards.potion].n}】`));
    }
    panel.appendChild(h("p", "flavor", "選擇一張卡牌加入牌組："));
    const row = h("div", "card-row");
    for (const cid of rewards.cards) {
      const view = cardView(mkInst(cid));
      const el = cardEl(view, { big: true });
      el.onclick = () => {
        run.deck.push(mkInst(cid));
        finishNode();
      };
      row.appendChild(el);
    }
    panel.appendChild(row);
    const skip = h("button", "btn small", "都不要");
    skip.onclick = finishNode;
    panel.appendChild(skip);
    ov.appendChild(panel);
    app.appendChild(ov);
  } else {
    const ov = h("div", "overlay");
    const panel = h("div", "panel");
    panel.appendChild(h("h2", "", "壯志未酬"));
    panel.appendChild(h("p", "flavor", `${CHARACTERS[run.charId].name} 倒在了餘杭的山道上。<br>江湖路遠，再來一局。`));
    const btn = h("button", "btn primary", "回主選單");
    btn.onclick = renderMenu;
    panel.appendChild(btn);
    ov.appendChild(panel);
    app.appendChild(ov);
  }
}

function finishNode() {
  if (ui.rewardNodeType === "boss") { renderVictory(); return; }
  saveRun();
  renderMap();
}

function renderVictory() {
  clearSave();
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/main_menu_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.style.justifyContent = "center";
  s.appendChild(h("div", "title-calligraphy", "餘杭平妖"));
  const ch = CHARACTERS[run.charId];
  const ending = {
    li: "李逍遙收劍而立，山風拂過十里坡。仙靈島的方向，有人在等他。",
    zhao: "趙靈兒望著湖心倒影，輕聲唸動安魂咒。她知道，自己的路才剛開始。",
    lin: "林月如把劍負回背上，揚眉一笑：「就這點本事？走，下一個。」",
    anu: "阿奴吹了聲口哨，蠱蟲歸袖。她蹦蹦跳跳地踏上歸途，南疆的星星很亮。",
  }[run.charId];
  const sub = h("div", "subtitle", `<br>${ending}<br><br>蛇妖既滅，餘杭重歸太平。<br>—— 第一幕 · 終 ——`);
  sub.style.lineHeight = "2.2";
  sub.style.textAlign = "center";
  s.appendChild(sub);
  const btn = h("button", "btn primary", "回主選單");
  btn.style.cssText = "margin-top:30px;z-index:1";
  btn.onclick = renderMenu;
  s.appendChild(btn);
  app.appendChild(s);
}

// ════════ 奇遇 ════════
function renderEvent(ev) {
  ui.screen = "event";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/event_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.appendChild(topbar(true));
  const ovWrap = h("div", "", "");
  ovWrap.style.cssText = "flex:1;display:flex;align-items:center;justify-content:center;z-index:1;width:100%";
  const panel = h("div", "panel");
  panel.style.maxWidth = "620px";
  panel.style.textAlign = "center";
  panel.appendChild(h("h2", "", ev.title));
  panel.appendChild(h("p", "flavor", ev.text));
  const col = h("div", "choice-col");
  for (const choice of ev.choices) {
    const btn = h("button", "btn", choice.label);
    if (choice.needGold && run.gold < choice.needGold) btn.disabled = true;
    btn.onclick = () => resolveEventChoice(choice);
    col.appendChild(btn);
  }
  panel.appendChild(col);
  ovWrap.appendChild(panel);
  s.appendChild(ovWrap);
  app.appendChild(s);
}

function resolveEventChoice(choice) {
  const fx = choice.fx;
  const msgs = [];
  if (fx.heal) { run.hp = Math.min(run.maxHp, run.hp + fx.heal); msgs.push(`回復 ${fx.heal} 點生命`); }
  if (fx.hp && fx.hp < 0) { run.hp = Math.max(1, run.hp + fx.hp); msgs.push(`失去 ${-fx.hp} 點生命`); }
  if (fx.gold) { run.gold = Math.max(0, run.gold + fx.gold); msgs.push(fx.gold > 0 ? `獲得 ${fx.gold} 銅錢` : `花費 ${-fx.gold} 銅錢`); }
  if (fx.potion && run.potions.length < 3) {
    const pid = pick(Object.keys(POTIONS));
    run.potions.push(pid);
    msgs.push(`獲得藥品【${POTIONS[pid].n}】`);
  }
  if (fx.relic) {
    const rid = randomRelic();
    if (rid) { run.relics.push(rid); msgs.push(`獲得遺物【${RELICS[rid].n}】`); }
  }
  saveRun();
  if (fx.cardReward) { showCardRewardOverlay(() => { saveRun(); renderMap(); }); return; }
  showToastOverlay(msgs.length ? msgs.join("，") : "你轉身離去，什麼也沒帶走。", () => renderMap());
}

function showToastOverlay(text, onClose) {
  const ov = h("div", "overlay");
  const panel = h("div", "panel");
  panel.appendChild(h("p", "flavor", text));
  const btn = h("button", "btn primary", "繼續");
  btn.onclick = onClose;
  panel.appendChild(btn);
  ov.appendChild(panel);
  app.appendChild(ov);
}

function showCardRewardOverlay(onDone) {
  const ov = h("div", "overlay");
  const panel = h("div", "panel");
  panel.appendChild(h("h2", "", "卡牌獎勵"));
  const row = h("div", "card-row");
  for (const cid of cardChoices()) {
    const view = cardView(mkInst(cid));
    const el = cardEl(view, { big: true });
    el.onclick = () => { run.deck.push(mkInst(cid)); ov.remove(); onDone(); };
    row.appendChild(el);
  }
  panel.appendChild(row);
  const skip = h("button", "btn small", "都不要");
  skip.onclick = () => { ov.remove(); onDone(); };
  panel.appendChild(skip);
  ov.appendChild(panel);
  app.appendChild(ov);
}

// ════════ 休息 ════════
function renderRest() {
  ui.screen = "rest";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/event_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.appendChild(topbar(true));
  const wrap = h("div", "", "");
  wrap.style.cssText = "flex:1;display:flex;align-items:center;justify-content:center;z-index:1;width:100%";
  const panel = h("div", "panel");
  panel.style.textAlign = "center";
  panel.appendChild(h("h2", "", "山間客棧"));
  panel.appendChild(h("p", "flavor", "燈籠在簷下輕晃，一壺熱茶冒著白氣。難得的喘息。"));
  const col = h("div", "choice-col");
  const healAmt = Math.round(run.maxHp * 0.3) + (hasRelic("jiuhulu") ? 10 : 0);
  const healBtn = h("button", "btn", `歇息（回復 ${healAmt} 點生命）`);
  healBtn.onclick = () => {
    run.hp = Math.min(run.maxHp, run.hp + healAmt);
    saveRun();
    showToastOverlay(`一覺醒來，神清氣爽。回復 ${healAmt} 點生命。`, renderMap);
  };
  col.appendChild(healBtn);
  const upBtn = h("button", "btn", "打坐練功（升級一張卡牌）");
  upBtn.onclick = () => showUpgradeOverlay();
  col.appendChild(upBtn);
  panel.appendChild(col);
  wrap.appendChild(panel);
  s.appendChild(wrap);
  app.appendChild(s);
}

function showUpgradeOverlay() {
  const ov = h("div", "overlay");
  const panel = h("div", "panel");
  panel.appendChild(h("h2", "", "選擇要升級的卡牌"));
  const grid = h("div", "deck-grid");
  run.deck.forEach((inst) => {
    if (inst.up) return;
    const view = cardView(inst);
    const el = cardEl(view);
    el.style.margin = "0";
    el.onclick = () => {
      inst.up = true;
      ov.remove();
      saveRun();
      const upView = cardView(inst);
      showToastOverlay(`【${upView.n}】領悟更深——${upView.desc}`, renderMap);
    };
    grid.appendChild(el);
  });
  panel.appendChild(grid);
  const back = h("button", "btn small", "返回");
  back.style.marginTop = "14px";
  back.onclick = () => ov.remove();
  panel.appendChild(back);
  ov.appendChild(panel);
  app.appendChild(ov);
}

// ════════ 商店 ════════
function renderShop() {
  ui.screen = "shop";
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/event_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.appendChild(topbar(true));
  const wrap = h("div", "", "");
  wrap.style.cssText = "flex:1;display:flex;align-items:center;justify-content:center;z-index:1;width:100%;overflow-y:auto";
  const panel = h("div", "panel");
  panel.style.textAlign = "center";
  panel.appendChild(h("h2", "", "雲來客商"));
  panel.appendChild(h("p", "flavor", `「客官請看，都是好東西。」　你有 🪙 ${run.gold}`));

  const row = h("div", "card-row");
  ui.shop.cards.forEach((item, idx) => {
    if (!item) return;
    const view = cardView(mkInst(item.cid));
    const box = h("div", "shop-item");
    const el = cardEl(view);
    el.style.margin = "0";
    box.appendChild(el);
    const buy = h("button", "btn small", `🪙 ${item.price}`);
    buy.disabled = run.gold < item.price;
    buy.onclick = () => {
      run.gold -= item.price;
      run.deck.push(mkInst(item.cid));
      ui.shop.cards[idx] = null;
      saveRun();
      renderShop();
    };
    box.appendChild(buy);
    row.appendChild(box);
  });
  panel.appendChild(row);

  const row2 = h("div", "card-row");
  ui.shop.potions.forEach((item, idx) => {
    if (!item) return;
    const p = POTIONS[item.pid];
    const box = h("div", "shop-item");
    box.appendChild(h("div", "", `<span class="relic-chip potion-chip" style="width:44px;height:44px;font-size:21px">${p.icon}</span><br><b>${p.n}</b><br><span style="font-size:12px;color:var(--text-dim)">${p.d}</span>`));
    const buy = h("button", "btn small", `🪙 ${item.price}`);
    buy.disabled = run.gold < item.price || run.potions.length >= 3;
    buy.onclick = () => {
      run.gold -= item.price;
      run.potions.push(item.pid);
      ui.shop.potions[idx] = null;
      saveRun();
      renderShop();
    };
    box.appendChild(buy);
    row2.appendChild(box);
  });
  if (ui.shop.relic) {
    const r = RELICS[ui.shop.relic];
    const box = h("div", "shop-item");
    box.appendChild(h("div", "", `<span class="relic-chip" style="width:44px;height:44px;font-size:21px">${r.icon}</span><br><b>${r.n}</b><br><span style="font-size:12px;color:var(--text-dim)">${r.d}</span>`));
    const buy = h("button", "btn small", `🪙 ${ui.shop.relicPrice}`);
    buy.disabled = run.gold < ui.shop.relicPrice;
    buy.onclick = () => {
      run.gold -= ui.shop.relicPrice;
      run.relics.push(ui.shop.relic);
      ui.shop.relic = null;
      saveRun();
      renderShop();
    };
    box.appendChild(buy);
    row2.appendChild(box);
  }
  panel.appendChild(row2);

  if (!ui.shop.removed) {
    const rm = h("button", "btn small", `除卡服務（🪙 ${ui.shop.removePrice}）`);
    rm.disabled = run.gold < ui.shop.removePrice;
    rm.onclick = () => showRemoveOverlay();
    panel.appendChild(rm);
  }
  const leave = h("button", "btn primary", "離開");
  leave.style.marginLeft = "14px";
  leave.onclick = () => { saveRun(); renderMap(); };
  panel.appendChild(leave);
  wrap.appendChild(panel);
  s.appendChild(wrap);
  app.appendChild(s);
}

function showRemoveOverlay() {
  const ov = h("div", "overlay");
  const panel = h("div", "panel");
  panel.appendChild(h("h2", "", "選擇要移除的卡牌"));
  const grid = h("div", "deck-grid");
  run.deck.forEach((inst, idx) => {
    const el = cardEl(cardView(inst));
    el.style.margin = "0";
    el.onclick = () => {
      run.gold -= ui.shop.removePrice;
      run.deck.splice(idx, 1);
      ui.shop.removed = true;
      ov.remove();
      saveRun();
      renderShop();
    };
    grid.appendChild(el);
  });
  panel.appendChild(grid);
  const back = h("button", "btn small", "返回");
  back.style.marginTop = "14px";
  back.onclick = () => ov.remove();
  panel.appendChild(back);
  ov.appendChild(panel);
  app.appendChild(ov);
}

// ════════ 寶箱 ════════
function renderTreasure() {
  const rid = randomRelic();
  const gold = 30 + Math.floor(Math.random() * 21);
  run.gold += gold;
  let msg = `打開塵封的木箱——獲得 ${gold} 銅錢`;
  if (rid) { run.relics.push(rid); msg += `，以及遺物【${RELICS[rid].n}】：${RELICS[rid].d}`; }
  saveRun();
  app.innerHTML = "";
  const s = h("div", "screen");
  s.style.backgroundImage = "url(assets/bg/event_bg.png)";
  s.appendChild(h("div", "scrim"));
  s.appendChild(topbar(true));
  app.appendChild(s);
  showToastOverlay(msg, renderMap);
}

// ════════ 牌組瀏覽 ════════
function showDeckOverlay() {
  const ov = h("div", "overlay");
  const panel = h("div", "panel");
  panel.appendChild(h("h2", "", `牌組（${run.deck.length} 張）`));
  const grid = h("div", "deck-grid");
  for (const inst of run.deck) {
    const el = cardEl(cardView(inst));
    el.style.margin = "0";
    grid.appendChild(el);
  }
  panel.appendChild(grid);
  const back = h("button", "btn small", "關閉");
  back.style.marginTop = "14px";
  back.onclick = () => ov.remove();
  panel.appendChild(back);
  ov.appendChild(panel);
  app.appendChild(ov);
}

// ════════ 啟動 ════════
renderMenu();
