"""劇情頭像（電影感 CG 版）：選定底圖 → 主角用圖生圖做五種表情（同一張臉）→ 去背發布到 public/assets/portraits/cine-v1/。

python tools/art/portraits_cine.py expressions   # 主角表情（需 ComfyUI）
python tools/art/portraits_cine.py publish       # 去背、縮圖、存 WebP

底圖由 tools/art/cine_cast.py 的描述出圖（source_art/portraits/cine-v1/<id>_s<seed>.png），
選哪個種子寫在 PICK。表情從底圖圖生圖，所以衣服、髮型、臉都跟底圖一樣。
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from cine_cast import CAST, EXPRESSIONS, MAIN, portrait_prompt  # noqa: E402

SRC = ROOT / "source_art" / "portraits" / "cine-v1"
DST = ROOT / "public" / "assets" / "portraits" / "cine-v1"
# 選定的底圖種子（沒寫就用 11）
PICK: dict[str, int] = {"zhao_linger": 29, "lin_yueru": 29, "anu": 29, "aunt": 17, "shenggu": 17, "wuwang": 13}
# 表情圖生圖的重繪強度：太低表情不變，太高臉會換人
EXPR_DENOISE = 0.56
EXPR_SEED = 5


def base_path(cid: str) -> Path:
    return SRC / f"{cid}_s{PICK.get(cid, 11)}.png"


def expressions() -> int:
    import img2img

    ok = True
    for cid in MAIN:
        for expr in EXPRESSIONS:
            out = SRC / f"{cid}_{expr}.png"
            if out.exists():
                continue
            ok &= img2img.run(base_path(cid), out, portrait_prompt(cid, expr), EXPR_SEED, EXPR_DENOISE, 9)
    return 0 if ok else 1


def publish() -> int:
    from PIL import Image
    from rembg import new_session, remove

    session = new_session("birefnet-general")
    DST.mkdir(parents=True, exist_ok=True)
    items = [(cid, base_path(cid)) for cid in CAST]
    items += [(f"{cid}_{expr}", SRC / f"{cid}_{expr}.png") for cid in MAIN for expr in EXPRESSIONS]
    for name, src in items:
        dst = DST / f"{name}.webp"
        if not src.exists():
            print(f"缺底圖：{src}")
            continue
        if dst.exists() and dst.stat().st_mtime > src.stat().st_mtime:
            continue
        image = remove(Image.open(src).convert("RGB"), session=session)
        bbox = image.getbbox()
        if bbox:
            image = image.crop(bbox)
        image.thumbnail((640, 960), Image.LANCZOS)
        image.save(dst, "WEBP", quality=86, method=4)
        print(dst.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit({"expressions": expressions, "publish": publish}[sys.argv[1]]())
