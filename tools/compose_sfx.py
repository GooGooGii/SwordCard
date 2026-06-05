#!/usr/bin/env python3
"""SwordCard SFX 合成器。

原創音效，全部用 Python stdlib 合成（無外部依賴、無版權問題）。
輸出短音效 WAV 到 assets/audio/sfx/。

用法：python tools/compose_sfx.py

風格：仙俠 + 復古 chiptune，短促、清楚。對應 SfxManager.play_sfx(id) 的 id。
"""

import math
import os
import random
import struct
import wave
from typing import List

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")


# ---------- 基礎波形 ----------

def _env(i: int, n: int, attack: float, release: float) -> float:
    t = i / SAMPLE_RATE
    dur = n / SAMPLE_RATE
    if attack > 0 and t < attack:
        return t / attack
    if release > 0 and t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0


def sine(freq: float, dur: float, vol: float = 0.4, attack: float = 0.005, release: float = 0.04) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    w = 2 * math.pi * freq
    return [math.sin(w * (i / SAMPLE_RATE)) * vol * _env(i, n, attack, release) for i in range(n)]


def square(freq: float, dur: float, vol: float = 0.25, attack: float = 0.003, release: float = 0.03) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    period = SAMPLE_RATE / freq
    out = [0.0] * n
    for i in range(n):
        s = 1.0 if (i % period) < (period / 2) else -1.0
        out[i] = s * vol * _env(i, n, attack, release)
    return out


def triangle(freq: float, dur: float, vol: float = 0.3, attack: float = 0.003, release: float = 0.03) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    period = SAMPLE_RATE / freq
    out = [0.0] * n
    for i in range(n):
        phase = (i % period) / period
        out[i] = (4 * abs(phase - 0.5) - 1) * vol * _env(i, n, attack, release)
    return out


def sweep(f0: float, f1: float, dur: float, vol: float = 0.35, wave_type: str = "sine",
          attack: float = 0.004, release: float = 0.05) -> List[float]:
    """頻率滑音（f0 → f1，指數插值）"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        frac = i / max(1, n - 1)
        freq = f0 * ((f1 / f0) ** frac)
        phase += 2 * math.pi * freq / SAMPLE_RATE
        if wave_type == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        elif wave_type == "triangle":
            s = 2 / math.pi * math.asin(math.sin(phase))
        else:
            s = math.sin(phase)
        out[i] = s * vol * _env(i, n, attack, release)
    return out


def noise(dur: float, vol: float = 0.3, decay: float = 12.0, lowpass: float = 0.0) -> List[float]:
    """白噪敲擊（指數衰減）。lowpass>0 時做簡單一階低通，聲音更悶（thud 用）。"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    prev = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        raw = (random.random() * 2 - 1)
        if lowpass > 0.0:
            prev = prev + lowpass * (raw - prev)
            raw = prev
        out[i] = raw * vol * math.exp(-decay * t)
    return out


def mix(a: List[float], b: List[float], offset_sec: float = 0.0) -> List[float]:
    off = int(SAMPLE_RATE * offset_sec)
    n = max(len(a), off + len(b))
    out = [0.0] * n
    for i in range(len(a)):
        out[i] += a[i]
    for i in range(len(b)):
        out[off + i] += b[i]
    return out


def cat(*chunks: List[float]) -> List[float]:
    out: List[float] = []
    for c in chunks:
        out.extend(c)
    return out


def write_wav(filename: str, buf: List[float]) -> None:
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
    print(f"  [OK] {filename} ({len(buf) / SAMPLE_RATE * 1000:.0f}ms, {size_kb:.0f} KB)")


# ============================================================
# 音效定義
# ============================================================

def sfx_card_play() -> None:
    """打牌：清脆的紙牌劃過 + 短促上揚"""
    random.seed(10)
    swish = noise(0.09, vol=0.18, decay=28.0, lowpass=0.5)
    chirp = sweep(520, 880, 0.10, vol=0.16, wave_type="triangle")
    write_wav("card_play.wav", mix(swish, chirp, 0.01))


def sfx_attack_hit() -> None:
    """命中：低沉撞擊 + 短噪爆"""
    random.seed(11)
    thud = sine(140, 0.14, vol=0.5, attack=0.001, release=0.10)
    crack = noise(0.10, vol=0.32, decay=22.0)
    low = sweep(300, 90, 0.12, vol=0.3, wave_type="square")
    write_wav("attack_hit.wav", mix(mix(thud, crack), low))


def sfx_heal() -> None:
    """治療：柔和上行琶音（仙氣）"""
    a = sine(523, 0.12, vol=0.3)            # C5
    b = sine(659, 0.12, vol=0.3)            # E5
    c = sine(784, 0.20, vol=0.32, release=0.12)  # G5
    shimmer = sine(1568, 0.22, vol=0.08, attack=0.05, release=0.15)  # 高泛音
    body = cat(a, b, c)
    write_wav("heal.wav", mix(body, shimmer, 0.06))


def sfx_player_hurt() -> None:
    """被打：刺耳低頻 + 噪擊"""
    random.seed(12)
    hit = sweep(220, 70, 0.16, vol=0.42, wave_type="square")
    grit = noise(0.13, vol=0.30, decay=16.0, lowpass=0.3)
    write_wav("player_hurt.wav", mix(hit, grit))


def sfx_block() -> None:
    """護體：金屬清脆叮聲（格擋）"""
    random.seed(13)
    clink = triangle(1320, 0.10, vol=0.3, release=0.08)
    ring = sine(1760, 0.22, vol=0.18, attack=0.002, release=0.18)
    tick = noise(0.03, vol=0.14, decay=40.0)
    write_wav("block.wav", mix(mix(clink, ring), tick))


def sfx_end_turn() -> None:
    """結束回合：沉穩兩音確認"""
    a = triangle(392, 0.10, vol=0.28)   # G4
    b = triangle(294, 0.16, vol=0.30, release=0.10)   # D4
    write_wav("end_turn.wav", cat(a, b))


def sfx_victory() -> None:
    """勝利：上揚小號角"""
    notes = [
        square(523, 0.12, vol=0.24),   # C5
        square(659, 0.12, vol=0.24),   # E5
        square(784, 0.12, vol=0.24),   # G5
        square(1047, 0.32, vol=0.28, release=0.2),  # C6
    ]
    body = cat(*notes)
    sparkle = sine(1568, 0.4, vol=0.08, attack=0.1, release=0.25)
    write_wav("victory.wav", mix(body, sparkle, 0.3))


def sfx_defeat() -> None:
    """戰敗：下行悲涼"""
    notes = [
        triangle(440, 0.18, vol=0.3),   # A4
        triangle(349, 0.18, vol=0.3),   # F4
        triangle(262, 0.45, vol=0.32, release=0.3),  # C4
    ]
    low = sine(98, 0.7, vol=0.18, attack=0.05, release=0.4)  # G2 悶底
    write_wav("defeat.wav", mix(cat(*notes), low))


def sfx_boss_phase() -> None:
    """Boss 變身：陰森上湧 + 低吼"""
    random.seed(14)
    swell = sweep(80, 320, 0.5, vol=0.4, wave_type="square", attack=0.1, release=0.2)
    growl = sweep(140, 60, 0.45, vol=0.3, wave_type="triangle")
    hiss = noise(0.4, vol=0.12, decay=4.0, lowpass=0.2)
    write_wav("boss_phase.wav", mix(mix(swell, growl), hiss))


def sfx_summon() -> None:
    """召喚：魔法閃現上行 + 微光"""
    a = sweep(330, 990, 0.28, vol=0.28, wave_type="triangle", release=0.12)
    sparkle1 = sine(1320, 0.18, vol=0.12, attack=0.02, release=0.14)
    sparkle2 = sine(1760, 0.16, vol=0.10, attack=0.02, release=0.12)
    out = mix(a, sparkle1, 0.10)
    out = mix(out, sparkle2, 0.18)
    write_wav("summon.wav", out)


def sfx_potion() -> None:
    """喝藥：咕嘟氣泡 + 圓潤收尾"""
    random.seed(15)
    out = [0.0] * 0
    # 三個下行小氣泡
    bubbles = cat(
        sine(700, 0.05, vol=0.22, release=0.03),
        sine(560, 0.05, vol=0.22, release=0.03),
        sine(620, 0.05, vol=0.22, release=0.03),
    )
    glug = sweep(480, 360, 0.18, vol=0.2, wave_type="sine", release=0.1)
    write_wav("potion.wav", mix(glug, bubbles, 0.02))


def sfx_button() -> None:
    """UI 按鈕：輕點"""
    write_wav("button.wav", triangle(660, 0.05, vol=0.22, release=0.035))


def sfx_card_select() -> None:
    """選牌 / 抬起：短上揚"""
    write_wav("card_select.wav", sweep(440, 660, 0.07, vol=0.18, wave_type="triangle"))


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Output: {os.path.abspath(OUT_DIR)}")
    sfx = [
        sfx_card_play, sfx_attack_hit, sfx_heal, sfx_player_hurt, sfx_block,
        sfx_end_turn, sfx_victory, sfx_defeat, sfx_boss_phase, sfx_summon,
        sfx_potion, sfx_button, sfx_card_select,
    ]
    print(f"Composing {len(sfx)} SFX ...")
    for fn in sfx:
        fn()
    print(f"Done. {len(sfx)} SFX written.")


if __name__ == "__main__":
    main()
