/**
 * WebAudio 合成器：撥弦（近似古箏）、笛、鼓、鑼、持續低音。全部即時合成，沒有音檔、沒有授權問題。
 */
export interface Bus {
  ctx: AudioContext;
  out: AudioNode;
  /** 殘響送出（音樂用；音效可以不送） */
  reverb: AudioNode | null;
}

export const midiToHz = (m: number) => 440 * 2 ** ((m - 69) / 12);

function connect(bus: Bus, node: AudioNode, wet = 0.25) {
  node.connect(bus.out);
  if (bus.reverb && wet > 0) {
    const send = bus.ctx.createGain();
    send.gain.value = wet;
    node.connect(send).connect(bus.reverb);
  }
}

/** 撥弦：三角波＋鋸齒波，經過快速收的低通濾波，像古箏的撥奏 */
export function pluck(bus: Bus, t: number, midi: number, vel = 0.5, decay = 1.4) {
  const { ctx } = bus;
  const f = midiToHz(midi);
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0, t);
  gain.gain.linearRampToValueAtTime(vel * 0.32, t + 0.004);
  gain.gain.exponentialRampToValueAtTime(0.0008, t + decay);
  const filter = ctx.createBiquadFilter();
  filter.type = "lowpass";
  filter.frequency.setValueAtTime(Math.min(9000, f * 9), t);
  filter.frequency.exponentialRampToValueAtTime(Math.max(300, f * 1.6), t + decay * 0.5);
  filter.Q.value = 2;
  for (const [type, level, detune] of [["triangle", 1, 0], ["sawtooth", 0.35, 4]] as const) {
    const osc = ctx.createOscillator();
    osc.type = type;
    osc.frequency.value = f;
    osc.detune.value = detune;
    const g = ctx.createGain();
    g.gain.value = level;
    osc.connect(g).connect(filter);
    osc.start(t);
    osc.stop(t + decay + 0.05);
  }
  filter.connect(gain);
  connect(bus, gain, 0.3);
}

/** 笛：正弦波＋微弱泛音，帶顫音與氣聲 */
export function flute(bus: Bus, t: number, midi: number, dur: number, vel = 0.5) {
  const { ctx } = bus;
  const f = midiToHz(midi);
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0, t);
  gain.gain.linearRampToValueAtTime(vel * 0.2, t + 0.07);
  gain.gain.setValueAtTime(vel * 0.2, t + Math.max(0.08, dur - 0.12));
  gain.gain.linearRampToValueAtTime(0, t + dur + 0.15);
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.value = f;
  const over = ctx.createOscillator();
  over.type = "triangle";
  over.frequency.value = f * 2;
  const overGain = ctx.createGain();
  overGain.gain.value = 0.08;
  const lfo = ctx.createOscillator();
  lfo.frequency.value = 5.2;
  const lfoGain = ctx.createGain();
  lfoGain.gain.setValueAtTime(0, t);
  lfoGain.gain.linearRampToValueAtTime(f * 0.006, t + 0.35);
  lfo.connect(lfoGain).connect(osc.frequency);
  osc.connect(gain);
  over.connect(overGain).connect(gain);
  for (const o of [osc, over, lfo]) {
    o.start(t);
    o.stop(t + dur + 0.2);
  }
  connect(bus, gain, 0.4);
}

/** 鼓：kick＝低沉的大鼓；tom＝手鼓；tick＝木魚般的輕擊 */
export function drum(bus: Bus, t: number, kind: "kick" | "tom" | "tick", vel = 0.6) {
  const { ctx } = bus;
  const spec = { kick: [130, 42, 0.32], tom: [230, 140, 0.18], tick: [900, 700, 0.05] }[kind];
  const osc = ctx.createOscillator();
  osc.type = kind === "tick" ? "square" : "sine";
  osc.frequency.setValueAtTime(spec[0]!, t);
  osc.frequency.exponentialRampToValueAtTime(spec[1]!, t + spec[2]!);
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(vel * (kind === "tick" ? 0.08 : 0.55), t);
  gain.gain.exponentialRampToValueAtTime(0.001, t + spec[2]! + 0.05);
  osc.connect(gain);
  osc.start(t);
  osc.stop(t + spec[2]! + 0.1);
  connect(bus, gain, kind === "kick" ? 0.08 : 0.15);
}

/** 鑼：幾個不成整數倍的泛音，長長地衰減 */
export function gong(bus: Bus, t: number, vel = 0.5, base = 92) {
  const { ctx } = bus;
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0, t);
  gain.gain.linearRampToValueAtTime(vel * 0.3, t + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.0008, t + 3.2);
  for (const [ratio, level] of [[1, 1], [1.48, 0.6], [2.31, 0.4], [3.17, 0.25]] as const) {
    const osc = ctx.createOscillator();
    osc.frequency.value = base * ratio;
    const g = ctx.createGain();
    g.gain.value = level;
    osc.connect(g).connect(gain);
    osc.start(t);
    osc.stop(t + 3.3);
  }
  connect(bus, gain, 0.5);
}

/** 雜訊爆發（出牌的刷聲、受擊） */
export function noise(bus: Bus, t: number, dur: number, vel: number, from: number, to: number) {
  const { ctx } = bus;
  const buffer = ctx.createBuffer(1, Math.max(1, Math.floor(ctx.sampleRate * dur)), ctx.sampleRate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;
  const src = ctx.createBufferSource();
  src.buffer = buffer;
  const filter = ctx.createBiquadFilter();
  filter.type = "bandpass";
  filter.frequency.setValueAtTime(from, t);
  filter.frequency.exponentialRampToValueAtTime(to, t + dur);
  filter.Q.value = 1.2;
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(vel, t);
  gain.gain.exponentialRampToValueAtTime(0.001, t + dur);
  src.connect(filter).connect(gain);
  src.start(t);
  connect(bus, gain, 0.1);
}

/** 持續低音（洞窟、鬼域的氛圍）：回傳停止函式 */
export function drone(bus: Bus, midi: number, level = 0.05): (at: number) => void {
  const { ctx } = bus;
  const gain = ctx.createGain();
  gain.gain.setValueAtTime(0, ctx.currentTime);
  gain.gain.linearRampToValueAtTime(level, ctx.currentTime + 2);
  const filter = ctx.createBiquadFilter();
  filter.type = "lowpass";
  filter.frequency.value = 380;
  const oscs = [-7, 7].map((detune) => {
    const o = ctx.createOscillator();
    o.type = "sawtooth";
    o.frequency.value = midiToHz(midi);
    o.detune.value = detune;
    o.connect(filter);
    o.start();
    return o;
  });
  filter.connect(gain);
  connect(bus, gain, 0.5);
  return (at: number) => {
    gain.gain.cancelScheduledValues(at);
    gain.gain.setValueAtTime(gain.gain.value, at);
    gain.gain.linearRampToValueAtTime(0, at + 1.5);
    for (const o of oscs) o.stop(at + 1.6);
  };
}

/** 殘響：用衰減的雜訊產生脈衝響應 */
export function makeReverb(ctx: AudioContext, seconds = 2.6): ConvolverNode {
  const rate = ctx.sampleRate;
  const len = Math.floor(rate * seconds);
  const impulse = ctx.createBuffer(2, len, rate);
  for (let ch = 0; ch < 2; ch++) {
    const data = impulse.getChannelData(ch);
    for (let i = 0; i < len; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / len) ** 2.4;
  }
  const conv = ctx.createConvolver();
  conv.buffer = impulse;
  return conv;
}
