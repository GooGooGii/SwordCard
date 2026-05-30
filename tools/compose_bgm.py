#!/usr/bin/env python3
"""SwordCard BGM 合成器。

原創 chiptune 風格作曲，全部用 Python stdlib 合成（無外部依賴）。
輸出 14 個 WAV 到 assets/audio/bgm/。

用法：python tools/compose_bgm.py
"""

import math
import os
import struct
import wave
from typing import Callable, List, Tuple

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "bgm")

# A 羽調五聲音階（A minor pentatonic / yu mode）—— 仙俠味
# MIDI: A2=45 ... G5=79
PENTA = [33, 36, 38, 40, 43, 45, 48, 50, 52, 55, 57, 60, 62, 64, 67, 69, 72, 74, 76, 79]
#         A1  C2  D2  E2  G2  A2  C3  D3  E3  G3  A3  C4  D4  E4  G4  A4  C5  D5  E5  G5


def note_freq(midi: int) -> float:
    return 440.0 * (2 ** ((midi - 69) / 12.0))


def envelope(i: int, n: int, attack: float, release: float) -> float:
    t = i / SAMPLE_RATE
    dur = n / SAMPLE_RATE
    if t < attack:
        return t / attack if attack > 0 else 1.0
    if t > dur - release:
        return max(0.0, (dur - t) / release) if release > 0 else 0.0
    return 1.0


def sine(freq: float, dur: float, vol: float = 0.3, attack: float = 0.02, release: float = 0.08) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    two_pi_f = 2 * math.pi * freq
    for i in range(n):
        t = i / SAMPLE_RATE
        out[i] = math.sin(two_pi_f * t) * vol * envelope(i, n, attack, release)
    return out


def square(freq: float, dur: float, vol: float = 0.15, attack: float = 0.005, release: float = 0.03) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    period = SAMPLE_RATE / freq
    for i in range(n):
        s = 1.0 if (i % period) < (period / 2) else -1.0
        out[i] = s * vol * envelope(i, n, attack, release)
    return out


def triangle(freq: float, dur: float, vol: float = 0.2, attack: float = 0.005, release: float = 0.03) -> List[float]:
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    period = SAMPLE_RATE / freq
    for i in range(n):
        phase = (i % period) / period
        s = 4 * abs(phase - 0.5) - 1
        out[i] = s * vol * envelope(i, n, attack, release)
    return out


def pluck(freq: float, dur: float, vol: float = 0.35, decay: float = 4.0) -> List[float]:
    """模擬古箏 / 琵琶撥奏：指數衰減的混合波形"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    two_pi_f = 2 * math.pi * freq
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-decay * t)
        s = (math.sin(two_pi_f * t)
             + 0.4 * math.sin(two_pi_f * 2 * t)
             + 0.15 * math.sin(two_pi_f * 3 * t))
        out[i] = s * vol * env / 1.55
    return out


def pad(freq: float, dur: float, vol: float = 0.12) -> List[float]:
    """長音 pad：基音 + 五度 + 八度的混合 sine，慢起音慢收"""
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    attack = min(0.3, dur * 0.25)
    release = min(0.4, dur * 0.3)
    two_pi_f = 2 * math.pi * freq
    for i in range(n):
        t = i / SAMPLE_RATE
        s = (math.sin(two_pi_f * t)
             + 0.5 * math.sin(two_pi_f * 1.5 * t)
             + 0.3 * math.sin(two_pi_f * 2 * t))
        out[i] = s * vol * envelope(i, n, attack, release) / 1.8
    return out


def noise_hit(dur: float, vol: float = 0.25) -> List[float]:
    """簡單白噪敲擊 —— 鼓 / 鈸 用"""
    import random
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    decay = 12.0
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-decay * t)
        out[i] = (random.random() * 2 - 1) * vol * env
    return out


# ---------- 序列 / 混音 helpers ----------

Instrument = Callable[[float, float], List[float]]


def mix_into(buf: List[float], samples: List[float], offset_sec: float) -> None:
    offset = int(SAMPLE_RATE * offset_sec)
    end = min(offset + len(samples), len(buf))
    for i in range(end - offset):
        buf[offset + i] += samples[i]


def seq(buf: List[float], start_sec: float, bpm: float,
        items: List[Tuple], instrument: Instrument, vol: float = 1.0) -> float:
    """items: list of (penta_idx 或 None, beats)，None = rest"""
    beat_sec = 60.0 / bpm
    t = start_sec
    for idx, beats in items:
        dur = beats * beat_sec
        if idx is not None and dur > 0:
            freq = note_freq(PENTA[idx])
            samples = instrument(freq, dur)
            if vol != 1.0:
                samples = [s * vol for s in samples]
            mix_into(buf, samples, t)
        t += dur
    return t


def make_buf(duration_sec: float) -> List[float]:
    return [0.0] * int(SAMPLE_RATE * duration_sec)


def write_wav(filename: str, buf: List[float]) -> None:
    path = os.path.join(OUT_DIR, filename)
    # Normalize
    peak = max(abs(s) for s in buf) if buf else 1.0
    if peak > 0.95:
        scale = 0.95 / peak
        buf = [s * scale for s in buf]
    # 16-bit PCM
    data = struct.pack('<' + 'h' * len(buf), *[max(-32768, min(32767, int(s * 32767))) for s in buf])
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(data)
    size_kb = os.path.getsize(path) / 1024
    print(f"  [OK] {filename} ({len(buf)/SAMPLE_RATE:.1f}s, {size_kb:.0f} KB)")


# ============================================================
# 14 個 track 的作曲
# ============================================================

# PENTA indices reminder:
# 0: A1   1: C2   2: D2   3: E2   4: G2
# 5: A2   6: C3   7: D3   8: E3   9: G3
# 10: A3  11: C4  12: D4  13: E4  14: G4
# 15: A4  16: C5  17: D5  18: E5  19: G5


def compose_title() -> None:
    """主選單：慢、空靈、雲穀鶴峰風"""
    bpm = 56
    dur = 60.0 / bpm * 16  # 4 小節
    buf = make_buf(dur)
    # Pad：A3 持續、E3 持續（每 2 拍切換）
    for i, idx in enumerate([10, 13, 10, 13, 10, 13, 10, 13]):
        seq(buf, 60.0 / bpm * i * 2, bpm, [(idx, 2)], pad, vol=1.0)
    # 主旋律：稀疏 pluck，pentatonic
    melody = [(15, 1), (None, 1), (17, 0.5), (15, 0.5), (14, 1),
              (13, 1), (None, 1), (11, 0.5), (13, 0.5), (15, 2),
              (None, 1), (14, 0.5), (13, 0.5), (11, 1), (10, 1),
              (None, 1), (15, 1), (13, 1), (10, 2)]
    seq(buf, 0, bpm, melody, pluck, vol=0.9)
    write_wav("title.wav", buf)


def compose_bestiary() -> None:
    """敵將圖鑑：靜態畫面，回憶感"""
    bpm = 50
    dur = 60.0 / bpm * 12
    buf = make_buf(dur)
    for i, idx in enumerate([8, 10, 8, 10, 8, 10]):
        seq(buf, 60.0 / bpm * i * 2, bpm, [(idx, 2)], pad, vol=1.1)
    melody = [(13, 1.5), (15, 0.5), (14, 2), (13, 1), (11, 1),
              (10, 2), (None, 2), (13, 1), (11, 0.5), (10, 0.5), (8, 3)]
    seq(buf, 0, bpm, melody, pluck, vol=0.8)
    write_wav("bestiary.wav", buf)


def compose_map_act1() -> None:
    """第一幕：餘杭春日，輕快"""
    bpm = 96
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    # 低音 walk
    bass = [(5, 1), (8, 1), (10, 1), (8, 1)] * 4
    seq(buf, 0, bpm, bass, triangle, vol=0.7)
    # 主旋律
    melody = [(13, 0.5), (15, 0.5), (14, 0.5), (13, 0.5), (11, 0.5), (10, 0.5), (11, 1),
              (13, 0.5), (15, 0.5), (17, 1), (15, 0.5), (13, 0.5), (14, 2),
              (15, 0.5), (17, 0.5), (18, 0.5), (17, 0.5), (15, 1), (13, 1),
              (15, 0.5), (13, 0.5), (11, 0.5), (10, 0.5), (11, 1), (13, 2)]
    seq(buf, 0, bpm, melody, pluck, vol=0.85)
    write_wav("map_act1.wav", buf)


def compose_map_act2() -> None:
    """第二幕：神木林，神秘"""
    bpm = 72
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    bass = [(3, 2), (5, 2), (3, 2), (8, 2)] * 2
    seq(buf, 0, bpm, bass, pad, vol=1.0)
    melody = [(11, 1), (13, 1), (15, 1), (13, 1), (11, 2), (10, 2),
              (13, 1), (15, 1), (17, 0.5), (15, 0.5), (13, 1), (15, 2), (13, 2),
              (10, 1), (11, 1), (10, 6)]
    seq(buf, 0, bpm, melody, pluck, vol=0.8)
    write_wav("map_act2.wav", buf)


def compose_map_act3() -> None:
    """第三幕：鎖妖塔，陰森"""
    bpm = 64
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    # 低沉 pad
    for i in range(4):
        seq(buf, 60.0 / bpm * i * 4, bpm, [(3, 4)], pad, vol=1.3)
    # 不協和的高音點綴（用半音差）
    melody = [(13, 0.5), (11, 0.5), (13, 1), (10, 2), (None, 2),
              (15, 0.5), (13, 0.5), (11, 1), (10, 2), (None, 2),
              (13, 1), (11, 1), (10, 1), (8, 1), (5, 4)]
    seq(buf, 0, bpm, melody, pluck, vol=0.7)
    write_wav("map_act3.wav", buf)


def compose_map_act4() -> None:
    """第四幕（預留）：靈山，崇高"""
    bpm = 60
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    bass = [(5, 4), (8, 4), (10, 4), (5, 4)]
    seq(buf, 0, bpm, bass, pad, vol=1.1)
    melody = [(15, 2), (17, 1), (15, 1), (13, 2), (15, 2),
              (17, 1), (18, 1), (19, 2), (17, 2),
              (15, 1), (13, 1), (15, 2), (10, 4)]
    seq(buf, 0, bpm, melody, pluck, vol=0.85)
    write_wav("map_act4.wav", buf)


def compose_map_act5() -> None:
    """第五幕（預留）：終局，凌雲壯志"""
    bpm = 80
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    bass = [(5, 1), (10, 1), (8, 1), (5, 1)] * 4
    seq(buf, 0, bpm, bass, triangle, vol=0.8)
    melody = [(15, 1), (17, 1), (18, 0.5), (17, 0.5), (15, 1),
              (13, 1), (15, 1), (17, 2),
              (18, 1), (19, 1), (18, 0.5), (17, 0.5), (15, 1),
              (17, 1), (15, 1), (13, 2),
              (15, 1), (13, 1), (11, 1), (10, 1), (15, 4)]
    seq(buf, 0, bpm, melody, pluck, vol=0.9)
    write_wav("map_act5.wav", buf)


def compose_battle_normal() -> None:
    """一般戰鬥：勢如破竹風"""
    bpm = 140
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    # 強烈 bass ostinato
    bass = [(0, 0.5), (5, 0.5), (0, 0.5), (5, 0.5)] * 8
    seq(buf, 0, bpm, bass, triangle, vol=0.9)
    # 鼓點
    import random
    random.seed(1)
    for i in range(16):
        mix_into(buf, noise_hit(0.08, vol=0.18), 60.0 / bpm * i)
    # 方波主旋律
    melody = [(10, 0.5), (13, 0.5), (15, 0.5), (13, 0.5), (10, 0.5), (13, 0.5), (15, 1),
              (15, 0.5), (17, 0.5), (15, 0.5), (13, 0.5), (10, 0.5), (8, 0.5), (10, 1),
              (10, 0.5), (13, 0.5), (15, 0.5), (17, 0.5), (18, 0.5), (17, 0.5), (15, 1),
              (15, 0.5), (13, 0.5), (10, 0.5), (8, 0.5), (10, 0.5), (8, 0.5), (5, 1)]
    seq(buf, 0, bpm, melody, square, vol=0.8)
    write_wav("battle_normal.wav", buf)


def compose_battle_boss() -> None:
    """Boss 戰：禦劍伏魔風，更快更重"""
    bpm = 156
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    # 低沉 bass
    bass = [(0, 0.25), (0, 0.25), (3, 0.5), (0, 0.25), (0, 0.25), (5, 0.5)] * 8
    seq(buf, 0, bpm, bass, square, vol=0.7)
    # 緊密鼓點
    import random
    random.seed(2)
    for i in range(32):
        mix_into(buf, noise_hit(0.05, vol=0.15), 60.0 / bpm * i * 0.5)
    # 高音威脅旋律
    melody = [(15, 0.25), (17, 0.25), (15, 0.5), (13, 0.5), (10, 0.5),
              (15, 0.25), (17, 0.25), (18, 0.5), (17, 1),
              (15, 0.25), (17, 0.25), (15, 0.5), (13, 0.5), (15, 0.5),
              (17, 0.25), (18, 0.25), (19, 0.5), (17, 1),
              (13, 0.5), (15, 0.5), (17, 0.5), (15, 0.5),
              (13, 0.5), (10, 0.5), (8, 0.5), (10, 0.5),
              (15, 0.5), (13, 0.5), (10, 0.5), (5, 0.5), (10, 2)]
    seq(buf, 0, bpm, melody, square, vol=0.75)
    write_wav("battle_boss.wav", buf)


def compose_shop() -> None:
    """商店：富甲一方，輕快"""
    bpm = 110
    dur = 60.0 / bpm * 16
    buf = make_buf(dur)
    bass = [(5, 0.5), (8, 0.5), (10, 0.5), (8, 0.5)] * 8
    seq(buf, 0, bpm, bass, triangle, vol=0.7)
    melody = [(13, 0.5), (15, 0.5), (17, 0.5), (15, 0.5), (13, 1), (11, 1),
              (15, 0.5), (17, 0.5), (18, 0.5), (17, 0.5), (15, 2),
              (13, 0.5), (15, 0.5), (13, 0.5), (11, 0.5), (10, 1), (13, 1),
              (11, 0.5), (10, 0.5), (8, 0.5), (10, 0.5), (11, 2)]
    seq(buf, 0, bpm, melody, pluck, vol=0.85)
    write_wav("shop.wav", buf)


def compose_event() -> None:
    """奇遇：中立、略帶懸念"""
    bpm = 78
    dur = 60.0 / bpm * 14
    buf = make_buf(dur)
    bass = [(5, 2), (3, 2), (8, 2), (5, 2)] * 2
    seq(buf, 0, bpm, bass[:8], pad, vol=1.0)
    melody = [(13, 1), (15, 0.5), (14, 0.5), (13, 1), (11, 1),
              (15, 1), (13, 1), (11, 0.5), (10, 0.5), (11, 1),
              (13, 0.5), (11, 0.5), (10, 1), (8, 1), (10, 3)]
    seq(buf, 0, bpm, melody, pluck, vol=0.8)
    write_wav("event.wav", buf)


def compose_rest() -> None:
    """休息：寧靜"""
    bpm = 52
    dur = 60.0 / bpm * 12
    buf = make_buf(dur)
    bass = [(5, 4), (8, 4), (10, 4)]
    seq(buf, 0, bpm, bass, pad, vol=1.2)
    melody = [(13, 2), (15, 1), (13, 1), (11, 2),
              (10, 1), (11, 1), (13, 2),
              (15, 1), (13, 1), (10, 2)]
    seq(buf, 0, bpm, melody, pluck, vol=0.7)
    write_wav("rest.wav", buf)


def compose_victory() -> None:
    """勝利：上揚 fanfare"""
    bpm = 100
    dur = 60.0 / bpm * 8
    buf = make_buf(dur)
    bass = [(5, 1), (10, 1), (5, 1), (10, 1)] * 2
    seq(buf, 0, bpm, bass, triangle, vol=0.8)
    melody = [(10, 0.5), (13, 0.5), (15, 1), (17, 0.5), (18, 0.5), (19, 1),
              (17, 0.5), (15, 0.5), (17, 1), (15, 1), (13, 1),
              (15, 0.5), (17, 0.5), (18, 0.5), (19, 0.5), (15, 2)]
    seq(buf, 0, bpm, melody, square, vol=0.85)
    # 加 pluck 點綴
    seq(buf, 0, bpm, [(15, 2), (17, 2), (15, 2), (10, 2)], pluck, vol=0.5)
    write_wav("victory.wav", buf)


def compose_defeat() -> None:
    """戰敗：下降、悲涼"""
    bpm = 50
    dur = 60.0 / bpm * 10
    buf = make_buf(dur)
    bass = [(5, 4), (3, 4), (0, 2)]
    seq(buf, 0, bpm, bass, pad, vol=1.2)
    melody = [(15, 2), (13, 1), (11, 1), (10, 2),
              (11, 1), (10, 1), (8, 2),
              (10, 1), (8, 1), (5, 4)]
    seq(buf, 0, bpm, melody, pluck, vol=0.75)
    write_wav("defeat.wav", buf)


# ============================================================
# 主程式
# ============================================================

def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"Output: {os.path.abspath(OUT_DIR)}")
    print("Composing 14 tracks ...")
    tracks = [
        ("title", compose_title),
        ("bestiary", compose_bestiary),
        ("map_act1", compose_map_act1),
        ("map_act2", compose_map_act2),
        ("map_act3", compose_map_act3),
        ("map_act4", compose_map_act4),
        ("map_act5", compose_map_act5),
        ("battle_normal", compose_battle_normal),
        ("battle_boss", compose_battle_boss),
        ("shop", compose_shop),
        ("event", compose_event),
        ("rest", compose_rest),
        ("victory", compose_victory),
        ("defeat", compose_defeat),
    ]
    for name, fn in tracks:
        fn()
    print(f"Done. {len(tracks)} tracks written.")


if __name__ == "__main__":
    main()
