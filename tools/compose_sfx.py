#!/usr/bin/env python3
"""SwordCard SFX 合成器。

原創音效，全部用 Python stdlib 合成（無外部依賴）。
輸出占位 WAV 到 assets/audio/sfx/。風格走 8-bit / chiptune，能聽即可；
想換成厚實音色，丟同名 `.ogg` 進 assets/audio/sfx/ 就會自動取代（`.ogg` 優先）。

用法：python tools/compose_sfx.py
"""

import math
import os
import random
import struct
import wave
from typing import List

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")


# ---------- 基本波形 ----------

def note_freq(midi: float) -> float:
    return 440.0 * (2 ** ((midi - 69) / 12.0))


def _env(i: int, n: int, attack: float, release: float) -> float:
    t = i / SAMPLE_RATE
    dur = n / SAMPLE_RATE
    if attack > 0 and t < attack:
        return t / attack
    if release > 0 and t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0


def sine(freq: float, dur: float, vol: float = 0.35,
         attack: float = 0.005, release: float = 0.05) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    w = 2 * math.pi * freq
    for i in range(n):
        out[i] = math.sin(w * i / SAMPLE_RATE) * vol * _env(i, n, attack, release)
    return out


def square(freq: float, dur: float, vol: float = 0.2,
           attack: float = 0.003, release: float = 0.02) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    period = SAMPLE_RATE / freq
    for i in range(n):
        s = 1.0 if (i % period) < (period / 2) else -1.0
        out[i] = s * vol * _env(i, n, attack, release)
    return out


def triangle(freq: float, dur: float, vol: float = 0.28,
             attack: float = 0.003, release: float = 0.02) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    period = SAMPLE_RATE / freq
    for i in range(n):
        phase = (i % period) / period
        s = 4 * abs(phase - 0.5) - 1
        out[i] = s * vol * _env(i, n, attack, release)
    return out


def pluck(freq: float, dur: float, vol: float = 0.4, decay: float = 6.0) -> List[float]:
    """撥奏：指數衰減的混合泛音（古箏 / 琵琶感）"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    w = 2 * math.pi * freq
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-decay * t)
        s = (math.sin(w * t)
             + 0.4 * math.sin(2 * w * t)
             + 0.15 * math.sin(3 * w * t))
        out[i] = s * vol * env / 1.55
    return out


def noise(dur: float, vol: float = 0.3, decay: float = 12.0) -> List[float]:
    """白噪敲擊 —— 指數衰減"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    for i in range(n):
        env = math.exp(-decay * i / SAMPLE_RATE)
        out[i] = (random.random() * 2 - 1) * vol * env
    return out


def sweep(f_start: float, f_end: float, dur: float, vol: float = 0.3,
          wave_fn: str = "sine", attack: float = 0.005, release: float = 0.04) -> List[float]:
    """頻率掃描：f_start → f_end（線性）"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        frac = i / max(1, n - 1)
        freq = f_start + (f_end - f_start) * frac
        phase += 2 * math.pi * freq / SAMPLE_RATE
        if wave_fn == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_fn == "triangle":
            s = (2 / math.pi) * math.asin(math.sin(phase))
        else:
            s = math.sin(phase)
        out[i] = s * vol * _env(i, n, attack, release)
    return out


def noise_sweep(dur: float, vol: float = 0.3, decay: float = 8.0) -> List[float]:
    """帶低通感的噪音掃 —— 用簡單一階低通把白噪變柔（劍揮 / 風聲）"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    prev = 0.0
    for i in range(n):
        frac = i / max(1, n - 1)
        # 截止頻率隨時間上升再下降（中段最亮）
        alpha = 0.05 + 0.5 * math.sin(math.pi * frac)
        raw = random.random() * 2 - 1
        prev = prev + alpha * (raw - prev)
        env = math.exp(-decay * frac) * (frac ** 0.5 if frac < 0.3 else 1.0)
        out[i] = prev * vol * env
    return out


# ---------- 混音 / 輸出 ----------

def mix(*layers: List[float]) -> List[float]:
    n = max((len(l) for l in layers), default=0)
    out = [0.0] * n
    for layer in layers:
        for i in range(len(layer)):
            out[i] += layer[i]
    return out


def cat(*layers: List[float]) -> List[float]:
    out: List[float] = []
    for layer in layers:
        out.extend(layer)
    return out


def write_wav(filename: str, buf: List[float]) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    peak = max((abs(s) for s in buf), default=1.0)
    if peak > 0.95:
        scale = 0.95 / peak
        buf = [s * scale for s in buf]
    data = struct.pack('<' + 'h' * len(buf),
                       *[max(-32768, min(32767, int(s * 32767))) for s in buf])
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(data)
    size_kb = os.path.getsize(path) / 1024
    print(f"  [OK] {filename} ({len(buf)/SAMPLE_RATE:.2f}s, {size_kb:.0f} KB)")


# ============================================================
# 11 個 SFX
# ============================================================

def sfx_card_attack() -> List[float]:
    """攻擊牌：劍揮的破空聲 + 高→低音掃"""
    swish = noise_sweep(0.26, vol=0.45, decay=7.0)
    tone = sweep(1400, 380, 0.22, vol=0.18, wave_fn="triangle")
    return mix(swish, tone)


def sfx_card_skill() -> List[float]:
    """技能牌：柔和上揚的氣勁 whoosh"""
    rise = sweep(300, 900, 0.3, vol=0.22, wave_fn="sine")
    air = noise_sweep(0.3, vol=0.18, decay=5.0)
    return mix(rise, air)


def sfx_card_power() -> List[float]:
    """能力牌：上行琶音 shimmer（聚氣 / buff）"""
    notes = [60, 64, 67, 72]  # C E G C 大三和弦
    buf: List[float] = []
    step = 0.09
    full = [0.0] * int(SAMPLE_RATE * (step * len(notes) + 0.3))
    for k, m in enumerate(notes):
        tone = pluck(note_freq(m), 0.35, vol=0.32, decay=4.0)
        off = int(SAMPLE_RATE * step * k)
        for i in range(len(tone)):
            if off + i < len(full):
                full[off + i] += tone[i]
    return full


def sfx_card_draw() -> List[float]:
    """抽牌：輕快的紙張 flick"""
    return noise_sweep(0.12, vol=0.3, decay=18.0)


def sfx_hit() -> List[float]:
    """命中：低頻 thud + 噪音爆破"""
    thud = sweep(180, 60, 0.18, vol=0.5, wave_fn="sine", attack=0.001, release=0.06)
    crack = noise(0.12, vol=0.35, decay=22.0)
    return mix(thud, crack)


def sfx_block() -> List[float]:
    """格擋：金屬護體 clink（非諧泛音）"""
    base = note_freq(76)
    layers = [
        sine(base, 0.3, vol=0.25, attack=0.001, release=0.2),
        sine(base * 2.76, 0.25, vol=0.16, attack=0.001, release=0.18),
        sine(base * 5.4, 0.2, vol=0.1, attack=0.001, release=0.15),
        noise(0.06, vol=0.18, decay=30.0),
    ]
    return mix(*layers)


def sfx_heal() -> List[float]:
    """治療：溫柔上行三音 chime"""
    notes = [67, 71, 74]  # G B D
    full = [0.0] * int(SAMPLE_RATE * 0.55)
    step = 0.1
    for k, m in enumerate(notes):
        tone = sine(note_freq(m), 0.4, vol=0.26, attack=0.02, release=0.3)
        off = int(SAMPLE_RATE * step * k)
        for i in range(len(tone)):
            if off + i < len(full):
                full[off + i] += tone[i]
    return full


def sfx_debuff() -> List[float]:
    """負面狀態（毒 / 弱 / 破綻）：陰暗下行 + 拍頻"""
    a = sweep(440, 220, 0.4, vol=0.22, wave_fn="sine")
    b = sweep(445, 223, 0.4, vol=0.18, wave_fn="sine")  # 微失諧 → beating
    return mix(a, b)


def sfx_button() -> List[float]:
    """UI 點擊：短促 blip"""
    return triangle(660, 0.07, vol=0.3, attack=0.002, release=0.04)


def sfx_victory() -> List[float]:
    """勝利：明亮上行琶音"""
    notes = [60, 64, 67, 72, 76]  # C E G C E
    full = [0.0] * int(SAMPLE_RATE * 1.2)
    step = 0.13
    for k, m in enumerate(notes):
        tone = pluck(note_freq(m), 0.6, vol=0.34, decay=3.0)
        off = int(SAMPLE_RATE * step * k)
        for i in range(len(tone)):
            if off + i < len(full):
                full[off + i] += tone[i]
    return full


def sfx_defeat() -> List[float]:
    """戰敗：低沉下行小調"""
    notes = [62, 60, 57, 53]  # D C A F → 下行
    full = [0.0] * int(SAMPLE_RATE * 1.5)
    step = 0.28
    for k, m in enumerate(notes):
        tone = sine(note_freq(m - 12), 0.7, vol=0.3, attack=0.02, release=0.4)
        off = int(SAMPLE_RATE * step * k)
        for i in range(len(tone)):
            if off + i < len(full):
                full[off + i] += tone[i]
    return full


SFX = {
    "card_attack": sfx_card_attack,
    "card_skill": sfx_card_skill,
    "card_power": sfx_card_power,
    "card_draw": sfx_card_draw,
    "hit": sfx_hit,
    "block": sfx_block,
    "heal": sfx_heal,
    "debuff": sfx_debuff,
    "button": sfx_button,
    "victory": sfx_victory,
    "defeat": sfx_defeat,
}


def main() -> None:
    random.seed(20260603)  # 固定 seed → 可重現的占位音效
    print(f"合成 {len(SFX)} 個 SFX 到 {os.path.normpath(OUT_DIR)} ...")
    for name, fn in SFX.items():
        write_wav(name + ".wav", fn())
    print("完成。")


if __name__ == "__main__":
    main()
