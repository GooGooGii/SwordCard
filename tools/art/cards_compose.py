"""主角卡圖合成（CARD-001）：主角姿勢去背圖 ＋ 無人場景 ＋ 屬性光效 → public/assets/cards/<id>.jpg

python tools/art/cards_compose.py bg        # 用 ComfyUI 出無人場景（source_art/cine/cards_bg/，已出的跳過）
python tools/art/cards_compose.py compose   # 合成並發布（隨時可重跑：主角圖換新後重跑就好）
python tools/art/cards_compose.py compose li_strike ling_wind   # 只做指定的卡

為什麼合成而不是整張文生圖：本機 Z-Image 畫不出使用者要的寫實臉（會變 Pixar 圓臉），
主角臉由出圖 agent／Codex 畫在 public/assets/characters/<id>_pose_*.webp，卡圖直接用那幾張，
所以卡上的主角永遠和劇情頭像、戰鬥立繪是同一張臉、同一套衣服。
道具卡（無主）與巫后卡（使用者指示先不重做巫后）不在這裡，維持 build_jobs.py 的文生圖。
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
from build_jobs import card_env, seed_of  # noqa: E402

META = json.loads((HERE / "prompts" / "cards_meta.json").read_text(encoding="utf-8"))
SCENES = json.loads((HERE / "prompts" / "cards.json").read_text(encoding="utf-8"))
BG_DIR = ROOT / "source_art" / "cine" / "cards_bg"
POSES = ROOT / "public" / "assets" / "characters"
# Codex 的原圖（出圖 agent 還沒發布進遊戲前，卡圖先直接用它；去背結果快取在 CUTOUTS）
CODEX = ROOT / "source_art" / "cine" / "codex"
CUTOUTS = ROOT / "source_art" / "cine" / "cards_cutout"
OUT = ROOT / "public" / "assets" / "cards"
HEROES = ("li_xiaoyao", "zhao_linger", "lin_yueru", "anu")
W, H = 960, 640  # 合成用的解析度；發布縮成 480×320

BG_STYLE = ("cinematic environment concept from a next-gen 3A Chinese wuxia game cutscene, Unreal Engine 5, realistic materials, "
            "dramatic cinematic lighting, atmospheric depth, completely empty of people and creatures, no characters, no silhouettes, "
            "the right half of the frame is open space, no text, no letters, no watermark, no border")
ELEMENT_FX = {
    "wind": ("a swirling pale green wind vortex with leaves and streaks of air", (120, 230, 160)),
    "thunder": ("crackling violet lightning bolts and storm sparks in the air", (190, 150, 255)),
    "water": ("arcs of glittering blue water and drifting ice crystals in the air", (120, 200, 255)),
    "fire": ("roaring vermilion flames and flying embers in the air", (255, 140, 60)),
    "earth": ("floating ochre rock fragments and golden dust in the air", (230, 180, 90)),
    None: ("faint drifting golden motes of spiritual energy in the air", (255, 220, 150)),
}
# 取景：（人物高度／卡高、人物中心 x、頭頂 y）
FRAMES = ((1.32, 0.60, 0.05), (1.75, 0.63, 0.02), (2.25, 0.66, -0.02))
# 卡的動作 → 用哪張姿勢圖
# 卡的動作 → 可用的姿勢圖（依卡名固定挑一張；standee 是備戰站姿）
POSE_OF = {"strike": ("attack", "attack", "standee"), "cast": ("cast",), "guard": ("guard", "standee")}


def hero_cards() -> list[str]:
    return [cid for cid, m in META.items() if m["owner"] in HEROES and cid in SCENES]


def bg_prompt(cid: str) -> str:
    m = META[cid]
    fx = ELEMENT_FX[m["element"]][0] if m["type"] in ("spell", "combo") or m["element"] else ""
    scene = card_env(cid, SCENES[cid])
    return f"{scene}{', ' + fx + ' on the left side' if fx else ''}. {BG_STYLE}."


def bg(ids: list[str] | None = None) -> int:
    import run_jobs

    jobs = [
        {"out": f"source_art/cine/cards_bg/{cid}.png", "prompt": bg_prompt(cid), "width": W, "height": H, "seed": seed_of(cid + "#bg")}
        for cid in (ids or hero_cards())
    ]
    path = HERE / "jobs" / "cards_bg.json"
    path.write_text(json.dumps(jobs, ensure_ascii=False, indent=1), encoding="utf-8")
    sys.argv = ["run_jobs.py", str(path)]
    return run_jobs.main()


def _glow(size: tuple[int, int], center: tuple[float, float], radius: float, color: tuple[int, int, int], strength: float):
    from PIL import Image, ImageDraw, ImageFilter

    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*color, int(255 * strength)))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.6))


def _sparks(size: tuple[int, int], color: tuple[int, int, int], seed: int, origin: tuple[float, float]):
    """屬性光點：從出招的手往左前方噴出的細小光粒"""
    from PIL import Image, ImageDraw, ImageFilter

    rnd = random.Random(seed)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    ox, oy = origin
    for _ in range(70):
        ang = math.radians(rnd.uniform(150, 230))
        dist = rnd.uniform(20, size[0] * 0.45)
        x, y = ox + math.cos(ang) * dist, oy + math.sin(ang) * dist * 0.6
        r = rnd.uniform(1.2, 3.6)
        a = int(rnd.uniform(120, 255) * (1 - dist / (size[0] * 0.5)))
        d.ellipse((x - r, y - r, x + r, y + r), fill=(*color, max(0, a)))
    return layer.filter(ImageFilter.GaussianBlur(0.8))


_session = None


def hero_image(owner: str, pose: str) -> Path | None:
    """先找 Codex 原圖（自己去背、快取），沒有才用遊戲裡已發布的姿勢圖。"""
    global _session
    raw = CODEX / owner / ("standee.png" if pose == "standee" else f"pose_{pose}.png")
    if raw.exists():
        cached = CUTOUTS / owner / f"{raw.stem}.png"
        if not cached.exists() or cached.stat().st_mtime < raw.stat().st_mtime:
            from PIL import Image
            from rembg import new_session, remove

            if _session is None:
                _session = new_session("birefnet-general")
            image = remove(Image.open(raw).convert("RGB"), session=_session)
            if bbox := image.getbbox():
                image = image.crop(bbox)
            cached.parent.mkdir(parents=True, exist_ok=True)
            image.save(cached)
        return cached
    published = POSES / (f"{owner}_standee.webp" if pose == "standee" else f"{owner}_pose_{pose}.webp")
    return published if published.exists() else None


def compose_one(cid: str) -> bool:
    from PIL import Image, ImageEnhance, ImageFilter, ImageOps

    m = META[cid]
    owner = m["owner"]
    options = POSE_OF.get(m["motion"], ("attack",))
    pose = options[seed_of(cid + "#pose") % len(options)]
    bg_path = BG_DIR / f"{cid}.png"
    hero_path = hero_image(owner, pose)
    if not bg_path.exists() or hero_path is None:
        print(f"缺：{bg_path.name if not bg_path.exists() else f'{owner} {pose}'}")
        return False
    color = ELEMENT_FX[m["element"]][1]
    canvas = Image.open(bg_path).convert("RGB").resize((W, H), Image.LANCZOS)
    # 背景稍微壓暗、退焦，讓人物跳出來
    canvas = ImageEnhance.Brightness(canvas.filter(ImageFilter.GaussianBlur(1.2))).enhance(0.82).convert("RGBA")

    hero = Image.open(hero_path).convert("RGBA")
    # 卡面是橫的：人物取膝蓋以上，頭頂貼近上緣。同一角色只有五張姿勢圖，
    # 每張卡依卡名固定挑一種取景（中景／近景／特寫），避免二十幾張卡都一樣
    frame = FRAMES[seed_of(cid + "#frame") % len(FRAMES)]
    scale = H * frame[0] / hero.height
    hero = hero.resize((int(hero.width * scale), int(hero.height * scale)), Image.LANCZOS)
    x = int(W * frame[1] - hero.width / 2)
    y = int(H * frame[2])
    # 人物配合場景：依背景平均亮度調亮度，再用屬性色從「出招那一側」（左）打輪廓光
    from PIL import ImageChops, ImageStat

    bg_lum = ImageStat.Stat(canvas.convert("L")).mean[0] / 255
    hero_rgb = ImageEnhance.Brightness(hero.convert("RGB")).enhance(0.78 + bg_lum * 0.35)
    hero = Image.merge("RGBA", (*hero_rgb.split(), hero.getchannel("A")))
    alpha = hero.getchannel("A")
    shifted = ImageChops.offset(alpha, 7, 0)
    left_edge = ImageChops.subtract(alpha, shifted).filter(ImageFilter.GaussianBlur(2.5))
    rim = Image.new("RGBA", hero.size, (*color, 0))
    rim.putalpha(left_edge.point(lambda v: int(v * 0.85)))
    # 地面陰影：腳不在畫面裡，用人物下方的暗影代替
    shadow = Image.new("RGBA", hero.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.45)))
    canvas.alpha_composite(shadow, (x + 18, y + 14))
    canvas.alpha_composite(hero, (x, y))
    canvas.alpha_composite(rim, (x, y))

    # 屬性光：出招的手大約在人物左側、胸口高度
    hand = (x + hero.width * 0.22, y + hero.height * 0.32)
    strength = 0.55 if m["type"] in ("spell", "combo") else 0.32
    canvas.alpha_composite(_glow((W, H), hand, 70 if m["type"] in ("spell", "combo") else 45, color, strength))
    canvas.alpha_composite(_sparks((W, H), color, seed_of(cid), hand))

    # 統一調色：輕微暗角 + 暖色電影感
    vignette = Image.new("L", (W, H), 0)
    vignette.paste(255, (0, 0, W, H))
    mask = ImageOps.invert(_glow((W, H), (W / 2, H / 2), W * 0.42, (255, 255, 255), 1.0).getchannel("A"))
    dark = Image.new("RGBA", (W, H), (8, 6, 4, 0))
    dark.putalpha(mask.point(lambda v: int(v * 0.55)))
    canvas.alpha_composite(dark)

    out = canvas.convert("RGB").resize((480, 320), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / f"{cid}.jpg", quality=86, optimize=True)
    return True


def compose(ids: list[str]) -> int:
    targets = ids or hero_cards()
    ok = sum(compose_one(cid) for cid in targets)
    print(f"合成 {ok}/{len(targets)}")
    return 0 if ok == len(targets) else 1


if __name__ == "__main__":
    cmd = sys.argv[1]
    sys.exit(bg(sys.argv[2:]) if cmd == "bg" else compose(sys.argv[2:]))
