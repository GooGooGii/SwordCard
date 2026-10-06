import { Rng, seedFromString } from "../core/rng";

/**
 * 程序化配樂（REDESIGN §9.1、決策 2026-10-04）：五聲音階，每首曲子由固定種子「作曲」一次，
 * 之後循環播放（所以是一首固定的曲子，不是每次都不一樣的亂數）。
 * 調式：宮 0-2-4-7-9、商 0-2-5-7-10、角 0-3-5-8-10、徵 0-2-5-7-9、羽 0-3-5-7-10。
 */
const MODES = {
  gong: [0, 2, 4, 7, 9],
  shang: [0, 2, 5, 7, 10],
  jue: [0, 3, 5, 8, 10],
  zhi: [0, 2, 5, 7, 9],
  yu: [0, 3, 5, 7, 10],
} as const;

export interface TrackDef {
  mode: keyof typeof MODES;
  /** 主音（MIDI） */
  root: number;
  /** 每分鐘八分音符的一半（四分音符拍速） */
  tempo: number;
  /** 旋律樂器 */
  lead: "pluck" | "flute" | "both";
  /** 旋律密度 0..1 */
  density: number;
  drums: "none" | "light" | "battle" | "boss";
  /** 持續低音（氛圍曲） */
  drone?: boolean;
  bass: boolean;
}

export const TRACKS: Record<string, TrackDef> = {
  title: { mode: "gong", root: 62, tempo: 66, lead: "both", density: 0.45, drums: "none", bass: true },
  yuhang: { mode: "gong", root: 62, tempo: 86, lead: "pluck", density: 0.6, drums: "none", bass: true },
  suzhou: { mode: "zhi", root: 67, tempo: 92, lead: "both", density: 0.6, drums: "light", bass: true },
  cave: { mode: "yu", root: 57, tempo: 62, lead: "pluck", density: 0.3, drums: "none", drone: true, bass: false },
  ghost: { mode: "yu", root: 52, tempo: 54, lead: "flute", density: 0.28, drums: "none", drone: true, bass: false },
  journey: { mode: "shang", root: 64, tempo: 78, lead: "both", density: 0.5, drums: "light", bass: true },
  butterfly: { mode: "gong", root: 65, tempo: 64, lead: "flute", density: 0.5, drums: "none", bass: true },
  tower: { mode: "jue", root: 48, tempo: 58, lead: "pluck", density: 0.35, drums: "none", drone: true, bass: true },
  nanzhao: { mode: "zhi", root: 62, tempo: 82, lead: "both", density: 0.55, drums: "light", bass: true },
  finale: { mode: "yu", root: 62, tempo: 70, lead: "both", density: 0.45, drums: "light", drone: true, bass: true },
  battle: { mode: "shang", root: 64, tempo: 132, lead: "pluck", density: 0.7, drums: "battle", bass: true },
  boss: { mode: "yu", root: 62, tempo: 140, lead: "pluck", density: 0.75, drums: "boss", drone: true, bass: true },
  sad: { mode: "yu", root: 57, tempo: 56, lead: "flute", density: 0.35, drums: "none", bass: true },
  ending: { mode: "gong", root: 60, tempo: 64, lead: "both", density: 0.45, drums: "none", bass: true },
};

export interface NoteEvent {
  step: number;
  midi: number;
  /** 長度（步數，一步＝八分音符） */
  len: number;
  vel: number;
  voice: "lead" | "bass" | "kick" | "tom" | "tick" | "gong";
}

export const STEPS_PER_BAR = 8;
export const BARS = 8;

/** 依種子作曲：8 小節旋律（句尾落在主音或屬音）、低音、打擊 */
export function compose(id: string, def: TrackDef): NoteEvent[] {
  const rng = new Rng(seedFromString(`xiaoyao-music-${id}`));
  const scale = MODES[def.mode];
  // 兩個八度的音階（MIDI）
  const ladder: number[] = [];
  for (let oct = 0; oct < 2; oct++) for (const s of scale) ladder.push(def.root + 12 * oct + s);
  ladder.push(def.root + 24);
  const events: NoteEvent[] = [];
  // 旋律：前四小節是「問句」，後四小節重複前兩小節再變化結尾（AABA' 的感覺）
  let degree = 5;
  const phrase: NoteEvent[] = [];
  for (let bar = 0; bar < 4; bar++) {
    for (let s = 0; s < STEPS_PER_BAR; s++) {
      const strong = s % 4 === 0;
      if (rng.next() > def.density * (strong ? 1.3 : 0.8)) continue;
      degree = Math.max(0, Math.min(ladder.length - 1, degree + rng.pick([-2, -1, -1, 1, 1, 2, 0])));
      const len = strong && rng.next() < 0.5 ? 2 : 1;
      phrase.push({ step: bar * STEPS_PER_BAR + s, midi: ladder[degree]!, len, vel: strong ? 0.75 : 0.55, voice: "lead" });
    }
  }
  // 問句結尾停在屬音（第 3 級），答句結尾回到主音
  phrase.push({ step: 3 * STEPS_PER_BAR + 6, midi: ladder[3]!, len: 2, vel: 0.7, voice: "lead" });
  events.push(...phrase);
  for (const n of phrase) {
    if (n.step < 2 * STEPS_PER_BAR) events.push({ ...n, step: n.step + 4 * STEPS_PER_BAR });
  }
  for (let bar = 6; bar < 8; bar++) {
    for (let s = 0; s < STEPS_PER_BAR; s += 2) {
      if (rng.next() > def.density) continue;
      degree = Math.max(0, Math.min(ladder.length - 1, degree + rng.pick([-1, 1, -2, 0])));
      events.push({ step: bar * STEPS_PER_BAR + s, midi: ladder[degree]!, len: 2, vel: 0.6, voice: "lead" });
    }
  }
  events.push({ step: 7 * STEPS_PER_BAR + 4, midi: ladder[5]!, len: 4, vel: 0.75, voice: "lead" });
  // 低音：每小節第一拍主音或屬音，第五步加一個
  if (def.bass) {
    const progression = [0, 0, 3, 0, 0, 2, 3, 0];
    for (let bar = 0; bar < BARS; bar++) {
      const midi = def.root - 12 + scale[progression[bar]!]!;
      events.push({ step: bar * STEPS_PER_BAR, midi, len: 4, vel: 0.6, voice: "bass" });
      if (def.drums === "battle" || def.drums === "boss") events.push({ step: bar * STEPS_PER_BAR + 4, midi, len: 2, vel: 0.5, voice: "bass" });
    }
  }
  // 打擊
  for (let bar = 0; bar < BARS; bar++) {
    const base = bar * STEPS_PER_BAR;
    if (def.drums === "light") {
      events.push({ step: base, midi: 0, len: 1, vel: 0.45, voice: "tom" });
      events.push({ step: base + 5, midi: 0, len: 1, vel: 0.3, voice: "tom" });
    } else if (def.drums === "battle" || def.drums === "boss") {
      for (const s of def.drums === "boss" ? [0, 3, 4, 6] : [0, 4]) events.push({ step: base + s, midi: 0, len: 1, vel: 0.7, voice: "kick" });
      for (const s of [2, 6]) events.push({ step: base + s, midi: 0, len: 1, vel: 0.5, voice: "tom" });
      for (let s = 1; s < STEPS_PER_BAR; s += 2) events.push({ step: base + s, midi: 0, len: 1, vel: 0.4, voice: "tick" });
    }
  }
  if (def.drums !== "none") events.push({ step: 0, midi: 0, len: 1, vel: 0.35, voice: "gong" });
  return events.sort((a, b) => a.step - b.step);
}
