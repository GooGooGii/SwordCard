import type { ControlStatus, StatusBag } from "../types";

/**
 * 仙劍一的控制類狀態（REDESIGN 戰鬥強化，2026-10-08）：
 * - 定身 stun：跳過下一次行動（敵人：該回合意圖作廢；隊員：該回合不能出他的牌）
 * - 昏睡 sleep：同定身，但受到傷害就醒
 * - 封印 seal：不能施法（敵人：只能攻擊或防禦；隊員：不能出仙術牌）
 * - 混亂 confuse：目標錯亂（敵人：單體攻擊可能打到自己人；隊員：單體牌的目標隨機）
 * 欄位在 StatusBag 是可選的（舊存檔沒有），一律透過這裡讀寫。
 */
export const CONTROL: readonly ControlStatus[] = ["stun", "seal", "sleep", "confuse"];

export function isControl(status: string): status is ControlStatus {
  return (CONTROL as readonly string[]).includes(status);
}

export function ctl(bag: StatusBag, status: ControlStatus): number {
  return bag[status] ?? 0;
}

export function addCtl(bag: StatusBag, status: ControlStatus, amount: number): number {
  bag[status] = Math.max(0, ctl(bag, status) + amount);
  return bag[status]!;
}

/** 定身或昏睡中：這次輪到他時不能行動 */
export function incapacitated(bag: StatusBag): boolean {
  return ctl(bag, "stun") > 0 || ctl(bag, "sleep") > 0;
}

/** 受到實際傷害：昏睡解除 */
export function wake(bag: StatusBag): boolean {
  if (ctl(bag, "sleep") <= 0) return false;
  bag.sleep = 0;
  return true;
}

/** 定身、昏睡會不會生效：抗性期間無效；頭目不吃定身與昏睡（封印、混亂照常） */
export function resistsDisable(bag: StatusBag, status: ControlStatus, isBoss = false): boolean {
  if (status !== "stun" && status !== "sleep") return false;
  return isBoss || (bag.steady ?? 0) > 0;
}

/** 定身／昏睡層數歸零的那一刻給 1 回合抗性 */
export function grantSteady(bag: StatusBag): void {
  if (ctl(bag, "stun") <= 0 && ctl(bag, "sleep") <= 0) bag.steady = 1;
}

export function clearControl(bag: StatusBag): void {
  for (const s of CONTROL) if (bag[s]) bag[s] = 0;
}
