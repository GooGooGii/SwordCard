"""美術批次產生器：讀 jobs JSON，逐張呼叫 ComfyUI（Z-Image Turbo）出圖，已存在的跳過（可中斷續跑）。

python tools/art/run_jobs.py <jobs.json> [<jobs2.json> ...]

jobs.json：[{ "out": "source_art/...png", "prompt": "...", "width": 768, "height": 512, "seed": 1,
              "publish": { "path": "public/assets/...jpg", "width": 768, "height": 512, "quality": 86,
                           "cutout": false } }]
- out 是原始輸出（PNG）；publish 是遊戲用的版本（縮圖、轉 JPEG，或 cutout=true 去背存 PNG）。
- ComfyUI 要先開著（見 tools/art/start_comfyui.ps1）。
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SWORDCARD_TOOLS = ROOT / "tools" / "comfyui"
sys.path.insert(0, str(SWORDCARD_TOOLS))
import zimage_txt2img  # noqa: E402  (SwordCard 的 ComfyUI 客戶端)

_rembg_session = None


def publish(job: dict) -> None:
    from PIL import Image

    spec = job.get("publish")
    if not spec:
        return
    src = ROOT / job["out"]
    dst = ROOT / spec["path"]
    dst.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(src)
    if spec.get("cutout"):
        global _rembg_session
        from rembg import new_session, remove

        if _rembg_session is None:
            _rembg_session = new_session("birefnet-general")
        image = remove(image.convert("RGB"), session=_rembg_session)
        bbox = image.getbbox()
        if bbox:
            image = image.crop(bbox)
        image.thumbnail((spec.get("width", 768), spec.get("height", 768)), Image.LANCZOS)
        # 去背圖存 WebP（保留透明，比 PNG 小很多）；副檔名是 .png 才存 PNG
        if dst.suffix == ".webp":
            image.save(dst, "WEBP", quality=86, method=4)
        else:
            image.save(dst, optimize=True)
        return
    image = image.convert("RGB")
    if spec.get("crop"):
        # 模型自己畫了外框（圓角白邊）時，每邊裁掉一定比例
        k = spec["crop"]
        w, h = image.size
        image = image.crop((int(w * k), int(h * k), int(w * (1 - k)), int(h * (1 - k))))
    if spec.get("width") and spec.get("height"):
        image = image.resize((spec["width"], spec["height"]), Image.LANCZOS)
    image.save(dst, quality=spec.get("quality", 86), optimize=True)


def main() -> int:
    jobs: list[dict] = []
    for path in sys.argv[1:]:
        jobs.extend(json.loads(Path(path).read_text(encoding="utf-8")))
    todo = [j for j in jobs if not (ROOT / j["out"]).exists()]
    print(f"{len(jobs)} jobs, {len(todo)} to render", flush=True)
    for job in jobs:
        if (ROOT / job["out"]).exists() and job.get("publish") and not (ROOT / job["publish"]["path"]).exists():
            publish(job)
    start = time.time()
    for n, job in enumerate(todo, 1):
        out = ROOT / job["out"]
        out.parent.mkdir(parents=True, exist_ok=True)
        ok = zimage_txt2img.run_job({**job, "out": str(out)}, steps=job.get("steps", 9), timeout=900)
        if ok:
            publish(job)
        elapsed = time.time() - start
        print(f"[{n}/{len(todo)}] {'ok ' if ok else 'ERR'} {job['out']}  ({elapsed / n:.0f}s/張)", flush=True)
    print("done", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
