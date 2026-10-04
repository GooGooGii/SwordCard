"""Z-Image Turbo 文生圖（ComfyUI 內建節點，參數照官方 blueprint）。

前置：ComfyUI 已啟動（見 launch_without_av.py），且有
  models/diffusion_models/z_image_turbo_*.safetensors
  models/text_encoders/qwen_3_4b*.safetensors
  models/vae/ae.safetensors

用法：
  python tools/comfyui/zimage_txt2img.py --prompt "..." --out out.png [--width 1344 --height 768 --seed 1]
  python tools/comfyui/zimage_txt2img.py --batch jobs.json   # [{"prompt":..,"out":..,"width":..,"height":..,"seed":..}, ...]
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import time
import urllib.request
import uuid
from pathlib import Path

COMFY_ROOT = Path(r"C:\AI\StabilityMatrix\Data\Packages\ComfyUI")
SERVER = "http://127.0.0.1:8188"
UNET = "z_image_turbo_nvfp4.safetensors"
TEXT_ENCODER = "qwen_3_4b_fp4_mixed.safetensors"
VAE = "ae.safetensors"


def workflow(prompt: str, width: int, height: int, seed: int, steps: int, prefix: str) -> dict:
    return {
        "unet": {"class_type": "UNETLoader", "inputs": {"unet_name": UNET, "weight_dtype": "default"}},
        "clip": {"class_type": "CLIPLoader", "inputs": {"clip_name": TEXT_ENCODER, "type": "lumina2", "device": "default"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": VAE}},
        "shift": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["unet", 0], "shift": 3.0}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["clip", 0], "text": prompt}},
        "neg": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["pos", 0]}},
        "latent": {"class_type": "EmptySD3LatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "sample": {
            "class_type": "KSampler",
            "inputs": {
                "model": ["shift", 0], "positive": ["pos", 0], "negative": ["neg", 0], "latent_image": ["latent", 0],
                "seed": seed, "steps": steps, "cfg": 1.0, "sampler_name": "res_multistep", "scheduler": "simple", "denoise": 1.0,
            },
        },
        "decode": {"class_type": "VAEDecode", "inputs": {"samples": ["sample", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["decode", 0], "filename_prefix": prefix}},
    }


def _request(path: str, payload: dict | None = None) -> dict:
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(SERVER + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())


def run_job(job: dict, steps: int, timeout: int) -> bool:
    tag = f"swordcard_{uuid.uuid4().hex[:8]}"
    prompt = workflow(job["prompt"], int(job.get("width", 1024)), int(job.get("height", 1024)),
                      int(job.get("seed", 1)), steps, tag)
    prompt_id = _request("/prompt", {"prompt": prompt, "client_id": tag})["prompt_id"]
    start = time.time()
    while time.time() - start < timeout:
        history = _request(f"/history/{prompt_id}")
        if prompt_id in history:
            status = history[prompt_id].get("status", {})
            if status.get("status_str") == "error":
                print(json.dumps(status, ensure_ascii=False)[:3000])
                return False
            outputs = sorted((COMFY_ROOT / "output").glob(f"{tag}*.png"))
            if outputs:
                out = Path(job["out"])
                out.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(outputs[-1]), out)
                print(f"{out} ({time.time() - start:.0f}s)")
                return True
        time.sleep(2)
    print(f"timeout: {job['out']}")
    return False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt")
    ap.add_argument("--out")
    ap.add_argument("--width", type=int, default=1024)
    ap.add_argument("--height", type=int, default=1024)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--steps", type=int, default=9)
    ap.add_argument("--batch", type=Path)
    ap.add_argument("--timeout", type=int, default=1200)
    args = ap.parse_args()
    if args.batch:
        jobs = json.loads(args.batch.read_text(encoding="utf-8"))
    else:
        jobs = [{"prompt": args.prompt, "out": args.out, "width": args.width, "height": args.height, "seed": args.seed}]
    ok = all([run_job(job, args.steps, args.timeout) for job in jobs])
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
