"""Z-Image Turbo 圖生圖：用一張「手動塗好形狀」的底圖引導出圖（文字描述修不好造型時用，例如阿奴的帽形）。

python tools/art/img2img.py <底圖.png> <輸出資料夾> --prompt "..." [--denoise 0.55] [--seeds 1 2 3]

ComfyUI 要先開著（tools/art/start_comfyui.ps1）。底圖會複製到 ComfyUI 的 input/。
"""
from __future__ import annotations

import argparse
import shutil
import sys
import time
import uuid
from pathlib import Path

SWORDCARD_TOOLS = Path(r"C:\Users\USER\source\repos\SwordCard\tools\comfyui")
sys.path.insert(0, str(SWORDCARD_TOOLS))
import zimage_txt2img as z  # noqa: E402


def workflow(image_name: str, prompt: str, seed: int, denoise: float, steps: int, prefix: str) -> dict:
    wf = z.workflow(prompt, 64, 64, seed, steps, prefix)
    del wf["latent"]
    wf["load"] = {"class_type": "LoadImage", "inputs": {"image": image_name}}
    wf["encode"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["load", 0], "vae": ["vae", 0]}}
    wf["sample"]["inputs"]["latent_image"] = ["encode", 0]
    wf["sample"]["inputs"]["denoise"] = denoise
    return wf


def run(src: Path, out: Path, prompt: str, seed: int, denoise: float, steps: int, timeout: int = 900) -> bool:
    name = f"xy_i2i_{uuid.uuid4().hex[:8]}{src.suffix}"
    shutil.copy(src, z.COMFY_ROOT / "input" / name)
    tag = f"xiaoyao_{uuid.uuid4().hex[:8]}"
    pid = z._request("/prompt", {"prompt": workflow(name, prompt, seed, denoise, steps, tag), "client_id": tag})["prompt_id"]
    start = time.time()
    while time.time() - start < timeout:
        history = z._request(f"/history/{pid}")
        if pid in history:
            if history[pid].get("status", {}).get("status_str") == "error":
                print(str(history[pid]["status"])[:2000])
                return False
            outputs = sorted((z.COMFY_ROOT / "output").glob(f"{tag}*.png"))
            if outputs:
                out.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(outputs[-1]), out)
                print(f"{out} ({time.time() - start:.0f}s)", flush=True)
                return True
        time.sleep(2)
    print(f"timeout: {out}")
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--prompt", required=True)
    ap.add_argument("--denoise", type=float, default=0.55)
    ap.add_argument("--seeds", type=int, nargs="+", default=[1])
    ap.add_argument("--steps", type=int, default=9)
    ap.add_argument("--prefix", default="i2i")
    a = ap.parse_args()
    ok = all([run(a.src, a.out_dir / f"{a.prefix}_d{int(a.denoise * 100)}_s{s}.png", a.prompt, s, a.denoise, a.steps) for s in a.seeds])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
