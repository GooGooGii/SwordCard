# -*- coding: utf-8 -*-
"""SwordCard 美術後處理管線：去背（rembg）＋ 放大（Real-ESRGAN）。

用法（repo 根目錄執行）：
    python tools/art_post.py <輸入檔或資料夾> [-o 輸出資料夾] [選項]

選項：
    -o / --out        輸出資料夾（預設 <輸入>_post/；單檔則同目錄加 _post 後綴）
    --scale {2,3,4}   放大倍率（預設 4）
    --max-size N      放大後長邊縮回 N px（預設 1024；0 = 不縮）
    --no-rembg        跳過去背（圖已是透明背景時用）
    --no-upscale      跳過放大
    --rembg-model M   rembg 模型（預設 isnet-anime，插畫最穩）
    --gpu N           Real-ESRGAN 用第 N 顆 GPU（-1 = 自動；本機 1 = RTX 4050）

依賴：
    pip install "rembg[gpu,cli]"        # 或 rembg[cpu,cli]
    tools/bin/realesrgan/realesrgan-ncnn-vulkan.exe
      ← https://github.com/xinntao/Real-ESRGAN/releases (realesrgan-ncnn-vulkan-20220424-windows.zip)

輸出一律 PNG（保留 alpha）。已在 assets/art/ 內的圖請先驗過再覆蓋。
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ESRGAN_EXE = REPO_ROOT / "tools" / "bin" / "realesrgan" / "realesrgan-ncnn-vulkan.exe"
IMG_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def collect_inputs(target: Path) -> list[Path]:
    if target.is_file():
        return [target]
    return sorted(p for p in target.iterdir() if p.suffix.lower() in IMG_EXTS)


def run_rembg(src: Path, dst: Path, session) -> None:
    from rembg import remove
    from PIL import Image

    with Image.open(src) as img:
        out = remove(img.convert("RGBA"), session=session)
        out.save(dst)


def run_esrgan(src: Path, dst: Path, scale: int, gpu: int) -> None:
    cmd = [
        str(ESRGAN_EXE),
        "-i", str(src),
        "-o", str(dst),
        "-n", "realesrgan-x4plus-anime",
        "-s", str(scale),
    ]
    if gpu >= 0:
        cmd += ["-g", str(gpu)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0 or not dst.exists():
        raise RuntimeError(f"Real-ESRGAN failed on {src.name}:\n{result.stderr[-500:]}")


def shrink_to(path: Path, max_size: int) -> None:
    from PIL import Image

    with Image.open(path) as img:
        if max(img.size) <= max_size:
            return
        ratio = max_size / max(img.size)
        new_size = (round(img.width * ratio), round(img.height * ratio))
        img.resize(new_size, Image.LANCZOS).save(path)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("input", type=Path)
    ap.add_argument("-o", "--out", type=Path, default=None)
    ap.add_argument("--scale", type=int, default=4, choices=(2, 3, 4))
    ap.add_argument("--max-size", type=int, default=1024)
    ap.add_argument("--no-rembg", action="store_true")
    ap.add_argument("--no-upscale", action="store_true")
    ap.add_argument("--rembg-model", default="isnet-anime")
    ap.add_argument("--gpu", type=int, default=-1)
    args = ap.parse_args()

    if not args.input.exists():
        print(f"input not found: {args.input}")
        return 1
    if not args.no_upscale and not ESRGAN_EXE.exists():
        print(f"missing {ESRGAN_EXE} — 下載方式見本檔 docstring")
        return 1

    inputs = collect_inputs(args.input)
    if not inputs:
        print("no images found")
        return 1

    out_dir = args.out
    if out_dir is None:
        base = args.input if args.input.is_dir() else args.input.parent
        out_dir = base.parent / (base.name + "_post") if args.input.is_dir() else base / "_post"
    out_dir.mkdir(parents=True, exist_ok=True)

    session = None
    if not args.no_rembg:
        from rembg import new_session
        session = new_session(args.rembg_model)

    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        for i, src in enumerate(inputs, 1):
            dst = out_dir / (src.stem + ".png")
            try:
                stage = src
                if not args.no_rembg:
                    cut = Path(tmp) / (src.stem + "_cut.png")
                    run_rembg(stage, cut, session)
                    stage = cut
                if not args.no_upscale:
                    run_esrgan(stage, dst, args.scale, args.gpu)
                    if args.max_size > 0:
                        shrink_to(dst, args.max_size)
                elif stage != dst:
                    from PIL import Image
                    with Image.open(stage) as img:
                        img.save(dst)
                print(f"[{i}/{len(inputs)}] {src.name} -> {dst}")
            except Exception as exc:  # 單張失敗不中斷整批
                failures += 1
                print(f"[{i}/{len(inputs)}] FAIL {src.name}: {exc}")

    print(f"done: {len(inputs) - failures} ok, {failures} failed -> {out_dir}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
