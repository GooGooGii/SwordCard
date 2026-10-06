import { BARS, compose, STEPS_PER_BAR, TRACKS, type NoteEvent } from "./music";
import { drone, drum, flute, gong, makeReverb, noise, pluck, type Bus } from "./synth";

/**
 * 音訊入口（AUDIO-001）：程序化配樂與音效，全部用 WebAudio 即時合成。
 * - 瀏覽器規定要使用者互動後才能出聲：第一次點擊／按鍵時才建立 AudioContext
 * - 分頁切到背景時暫停，回來再繼續
 * - 畫面只呼叫 playMusic／playSfx／setVolumes
 */
export type SfxId = "click" | "card" | "hit" | "block" | "heal" | "strong" | "weak" | "break" | "combo" | "downed" | "victory" | "defeat" | "coin";

let ctx: AudioContext | null = null;
let musicGain: GainNode | null = null;
let sfxGain: GainNode | null = null;
let reverb: ConvolverNode | null = null;
let volumes = { music: 0.6, sfx: 0.8 };
let wanted: string | null = null;

interface Playing {
  id: string;
  gain: GainNode;
  events: NoteEvent[];
  stepSeconds: number;
  /** 下一個要排程的步（絕對步數，跨循環累加） */
  nextStep: number;
  startTime: number;
  stopDrone: ((at: number) => void) | null;
}
let current: Playing | null = null;
let timer: number | null = null;

function ensureContext(): AudioContext | null {
  if (ctx) return ctx;
  const Ctor = typeof window !== "undefined" ? (window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext) : undefined;
  if (!Ctor) return null;
  ctx = new Ctor();
  musicGain = ctx.createGain();
  musicGain.gain.value = volumes.music * 0.55;
  sfxGain = ctx.createGain();
  sfxGain.gain.value = volumes.sfx * 0.7;
  reverb = makeReverb(ctx);
  const wet = ctx.createGain();
  wet.gain.value = 0.6;
  reverb.connect(wet).connect(musicGain);
  musicGain.connect(ctx.destination);
  sfxGain.connect(ctx.destination);
  document.addEventListener("visibilitychange", () => {
    if (!ctx) return;
    if (document.hidden) void ctx.suspend();
    else void ctx.resume();
  });
  return ctx;
}

/** 第一次使用者互動：建立音訊並開始播放已經要求的曲子 */
function unlock() {
  const c = ensureContext();
  if (!c) return;
  void c.resume();
  if (wanted && current?.id !== wanted) startTrack(wanted);
  window.removeEventListener("pointerdown", unlock);
  window.removeEventListener("keydown", unlock);
}
if (typeof window !== "undefined") {
  window.addEventListener("pointerdown", unlock);
  window.addEventListener("keydown", unlock);
}

export function setVolumes(music: number, sfx: number): void {
  volumes = { music, sfx };
  if (ctx && musicGain && sfxGain) {
    musicGain.gain.setTargetAtTime(music * 0.55, ctx.currentTime, 0.1);
    sfxGain.gain.setTargetAtTime(sfx * 0.7, ctx.currentTime, 0.05);
  }
}

const cache = new Map<string, NoteEvent[]>();

function startTrack(id: string) {
  const def = TRACKS[id];
  if (!ctx || !musicGain || !def) return;
  const now = ctx.currentTime;
  // 舊曲淡出
  if (current) {
    const old = current;
    old.gain.gain.cancelScheduledValues(now);
    old.gain.gain.setValueAtTime(old.gain.gain.value, now);
    old.gain.gain.linearRampToValueAtTime(0, now + 1.2);
    old.stopDrone?.(now);
    window.setTimeout(() => old.gain.disconnect(), 1600);
  }
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0, now);
  gain.gain.linearRampToValueAtTime(1, now + 1.5);
  gain.connect(musicGain);
  let events = cache.get(id);
  if (!events) {
    events = compose(id, def);
    cache.set(id, events);
  }
  const bus: Bus = { ctx, out: gain, reverb };
  current = {
    id,
    gain,
    events,
    stepSeconds: 60 / def.tempo / 2,
    nextStep: 0,
    startTime: now + 0.15,
    stopDrone: def.drone ? drone(bus, def.root - 24, 0.045) : null,
  };
  if (timer === null) timer = window.setInterval(schedule, 40);
}

/** 往前排程 0.25 秒內的音符 */
function schedule() {
  if (!ctx || !current) return;
  const def = TRACKS[current.id]!;
  const bus: Bus = { ctx, out: current.gain, reverb };
  const loopSteps = BARS * STEPS_PER_BAR;
  const horizon = ctx.currentTime + 0.25;
  while (current.startTime + current.nextStep * current.stepSeconds < horizon) {
    const abs = current.nextStep;
    const step = abs % loopSteps;
    const t = current.startTime + abs * current.stepSeconds;
    for (const n of current.events) {
      if (n.step !== step) continue;
      const dur = n.len * current.stepSeconds;
      switch (n.voice) {
        case "lead":
          if (def.lead === "pluck") pluck(bus, t, n.midi, n.vel);
          else if (def.lead === "flute") flute(bus, t, n.midi, dur, n.vel);
          else if (Math.floor(abs / loopSteps) % 2 === 0) pluck(bus, t, n.midi, n.vel);
          else flute(bus, t, n.midi + 12, dur, n.vel * 0.9);
          break;
        case "bass":
          pluck(bus, t, n.midi, n.vel * 0.8, 1.8);
          break;
        case "kick":
        case "tom":
        case "tick":
          drum(bus, t, n.voice, n.vel);
          break;
        case "gong":
          gong(bus, t, n.vel);
          break;
      }
    }
    current.nextStep++;
  }
}

/** 切換配樂；同一首不會重頭播。尚未解鎖時先記下，第一次互動後開始 */
export function playMusic(id: string | null): void {
  wanted = id;
  if (!ctx) return;
  if (id === null) {
    if (current) {
      const old = current;
      old.gain.gain.setTargetAtTime(0, ctx.currentTime, 0.4);
      old.stopDrone?.(ctx.currentTime);
      current = null;
    }
    return;
  }
  if (current?.id === id) return;
  startTrack(id);
}

export function musicPlaying(): string | null {
  return current?.id ?? null;
}

/** 音效 */
export function playSfx(id: SfxId): void {
  if (!ctx || !sfxGain || ctx.state !== "running") return;
  const bus: Bus = { ctx, out: sfxGain, reverb: null };
  const t = ctx.currentTime + 0.01;
  switch (id) {
    case "click":
      pluck(bus, t, 84, 0.35, 0.25);
      break;
    case "card":
      noise(bus, t, 0.18, 0.25, 3200, 900);
      break;
    case "hit":
      drum(bus, t, "kick", 0.6);
      noise(bus, t, 0.08, 0.3, 1800, 500);
      break;
    case "block":
      pluck(bus, t, 88, 0.4, 0.5);
      pluck(bus, t + 0.02, 95, 0.25, 0.4);
      break;
    case "heal":
      [72, 76, 79, 84].forEach((m, i) => pluck(bus, t + i * 0.06, m, 0.35, 0.8));
      break;
    case "strong":
      [76, 83, 88].forEach((m) => pluck(bus, t, m, 0.45, 0.6));
      drum(bus, t, "kick", 0.7);
      break;
    case "weak":
      pluck(bus, t, 55, 0.4, 0.4);
      break;
    case "break":
      gong(bus, t, 0.7, 110);
      break;
    case "combo":
      [67, 72, 76, 79, 84, 88].forEach((m, i) => pluck(bus, t + i * 0.05, m, 0.4, 1));
      gong(bus, t + 0.3, 0.5);
      break;
    case "downed":
      [64, 60, 55].forEach((m, i) => pluck(bus, t + i * 0.12, m, 0.4, 1.2));
      break;
    case "victory":
      [72, 74, 76, 79, 81, 84].forEach((m, i) => pluck(bus, t + i * 0.09, m, 0.45, 1.4));
      break;
    case "defeat":
      [57, 55, 52, 45].forEach((m, i) => pluck(bus, t + i * 0.25, m, 0.45, 2));
      break;
    case "coin":
      pluck(bus, t, 91, 0.3, 0.3);
      pluck(bus, t + 0.07, 96, 0.3, 0.4);
      break;
  }
}
