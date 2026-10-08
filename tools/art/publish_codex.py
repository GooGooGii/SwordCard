"""把 Codex 依影片樣本畫的角色圖（source_art/cine/codex/<id>/）去背發布到遊戲用的路徑。

python tools/art/publish_codex.py [角色id ...]

- portrait.png／portrait_<表情>.png → public/assets/portraits/cine-v1/<id>[_<表情>].webp（劇情頭像）
- standee.png → public/assets/characters/<id>_standee.webp；pose_<動作>.png → <id>_pose_<動作>.webp（戰鬥立繪與姿勢）
路徑和本機出圖版相同，遊戲程式不用改。缺的檔案就保留原本的圖。
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "source_art" / "cine" / "codex"
PORTRAITS = ROOT / "public" / "assets" / "portraits" / "cine-v1"
CHARACTERS = ROOT / "public" / "assets" / "characters"
EXPRS = ("smile", "angry", "surprise", "sad", "resolve")
POSES = ("attack", "cast", "guard", "hit")


def targets(cid: str) -> list[tuple[Path, Path]]:
    d = SRC / cid
    pairs = [(d / "portrait.png", PORTRAITS / f"{cid}.webp")]
    pairs += [(d / f"portrait_{e}.png", PORTRAITS / f"{cid}_{e}.webp") for e in EXPRS]
    pairs += [(d / "standee.png", CHARACTERS / f"{cid}_standee.webp")]
    pairs += [(d / f"pose_{p}.png", CHARACTERS / f"{cid}_pose_{p}.webp") for p in POSES]
    return pairs


def main(ids: list[str]) -> int:
    from PIL import Image
    from rembg import new_session, remove

    session = new_session("birefnet-general")
    ids = ids or sorted(p.name for p in SRC.iterdir() if p.is_dir())
    for cid in ids:
        for src, dst in targets(cid):
            if not src.exists():
                print(f"缺：{src.relative_to(ROOT)}")
                continue
            image = remove(Image.open(src).convert("RGB"), session=session)
            if bbox := image.getbbox():
                image = image.crop(bbox)
            image.thumbnail((640, 960), Image.LANCZOS)
            image.save(dst, "WEBP", quality=88, method=4)
            print(f"{src.relative_to(ROOT)} → {dst.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
