"""主角戰鬥立繪（電影感 CG）：站姿 + 攻擊／施法／護身／受擊四種姿勢，去背發布到 public/assets/characters/。

python tools/art/standees_cine.py base      # 站姿（txt2img，兩個種子）
python tools/art/standees_cine.py poses     # 姿勢（從選定站姿圖生圖，衣服與臉跟站姿一致）
python tools/art/standees_cine.py publish   # 去背、縮圖、存 WebP

站姿檔名沿用 <id>_standee.webp（characters.ts 不用改）；姿勢檔是 <id>_pose_<動作>.webp（src/content/heroArt.ts）。
戰鬥中主角在右下、面向左上的敵人，所以一律畫成「面向畫面左方」。
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from cine_cast import CAST, MAIN, STYLE  # noqa: E402

SRC = ROOT / "source_art" / "cine" / "characters"
DST = ROOT / "public" / "assets" / "characters"

FRAME = ("Full body character standee for a turn-based battle, the whole body from head to feet visible with margin, "
         "body turned three-quarter toward the viewer's left, plain flat light grey background, no ground, no shadow.")
WEAPON = {
    "li_xiaoyao": "holding a plain steel jian sword",
    "zhao_linger": "empty hands, a faint soft blue glow of spiritual magic around her fingers",
    "lin_yueru": "holding a long slender jian sword",
    "anu": "holding a thin gnarled wooden staff",
}
STANCE = "standing in a relaxed ready combat stance"
POSES = {
    "attack": "lunging forward in a fierce attack toward the left, weapon swinging forward, dynamic action pose, hair and clothes flowing",
    "cast": "casting a spell, one hand thrust forward toward the left with glowing magical light, other hand forming a hand seal, clothes billowing",
    "guard": "bracing defensively, weapon or arms raised in front of the body to block, knees bent, determined",
    "hit": "recoiling from a heavy blow, leaning back and staggering, pained grimace, one arm up",
}
PICK: dict[str, int] = {"zhao_linger": 19, "lin_yueru": 19}


def prompt(cid: str, pose: str | None = None) -> str:
    action = POSES[pose] if pose else STANCE
    return f"{STYLE} {FRAME} {CAST[cid]} {WEAPON[cid]}, {action}."


def base_path(cid: str) -> Path:
    return SRC / f"{cid}_standee_s{PICK.get(cid, 3)}.png"


def base() -> int:
    jobs = [
        {"out": str((SRC / f"{cid}_standee_s{s}.png").relative_to(ROOT)).replace("\\", "/"), "prompt": prompt(cid), "width": 832, "height": 1216, "seed": s}
        for cid in MAIN for s in (3, 19)
    ]
    path = ROOT / "tools" / "art" / "jobs" / "standees_cine.json"
    path.write_text(json.dumps(jobs, ensure_ascii=False, indent=1), encoding="utf-8")
    import run_jobs

    sys.argv = ["run_jobs.py", str(path)]
    return run_jobs.main()


def poses() -> int:
    """姿勢用文字直接出圖（同一份服裝描述、同一個種子）。實測圖生圖保留了站姿的骨架，動作幾乎不會變。"""
    import run_jobs

    jobs = [
        {"out": str((SRC / f"{cid}_pose_{pose}.png").relative_to(ROOT)).replace("\\", "/"), "prompt": prompt(cid, pose),
         "width": 1024, "height": 1216, "seed": PICK.get(cid, 3)}
        for cid in MAIN for pose in POSES
    ]
    path = ROOT / "tools" / "art" / "jobs" / "poses_cine.json"
    path.write_text(json.dumps(jobs, ensure_ascii=False, indent=1), encoding="utf-8")
    sys.argv = ["run_jobs.py", str(path)]
    return run_jobs.main()


def publish() -> int:
    from PIL import Image
    from rembg import new_session, remove

    session = new_session("birefnet-general")
    items = [(f"{cid}_standee", base_path(cid)) for cid in MAIN] + [(f"{cid}_pose_{p}", SRC / f"{cid}_pose_{p}.png") for cid in MAIN for p in POSES]
    for name, src in items:
        if not src.exists():
            print(f"缺：{src}")
            continue
        image = remove(Image.open(src).convert("RGB"), session=session)
        if bbox := image.getbbox():
            image = image.crop(bbox)
        image.thumbnail((640, 960), Image.LANCZOS)
        image.save(DST / f"{name}.webp", "WEBP", quality=86, method=4)
        print(name)
    return 0


if __name__ == "__main__":
    sys.exit({"base": base, "poses": poses, "publish": publish}[sys.argv[1]]())
