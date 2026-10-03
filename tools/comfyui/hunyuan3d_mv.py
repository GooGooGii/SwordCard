"""四視角參考圖 → Hunyuan3D-2mv（ComfyUI 內建節點）→ GLB 形體（無貼圖）。

前置：
  1. ComfyUI 已啟動（API 模式即可），例如 StabilityMatrix 的 ComfyUI：
       <ComfyUI>/venv/Scripts/python.exe <ComfyUI>/main.py --port 8188 --reserve-vram 0.9 --disable-auto-launch
  2. <ComfyUI>/models/checkpoints/hunyuan3d-dit-v2-mv-turbo.safetensors
     （Hugging Face tencent/Hunyuan3D-2mv 的 hunyuan3d-dit-v2-mv-turbo/model.fp16.safetensors，4.93 GB）

用法：
  python tools/comfyui/hunyuan3d_mv.py <四視角資料夾> <輸出.glb> [--seed N] [--octree 380] [--steps 5]

四視角資料夾內需有 front.png / left.png / back.png / right.png（白底、人物置中、同一比例）。
視角定義（已對照官方範例 assets/example_mv_images/1）：left＝人物面向畫面左、露出「人物自己的左側身」。
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
CHECKPOINT = "hunyuan3d-dit-v2-mv-turbo.safetensors"
VIEWS = ("front", "left", "back", "right")


def workflow(images: dict[str, str], seed: int, steps: int, cfg: float, octree: int, prefix: str) -> dict:
    nodes: dict[str, dict] = {
        "ckpt": {"class_type": "ImageOnlyCheckpointLoader", "inputs": {"ckpt_name": CHECKPOINT}},
    }
    cond_inputs: dict[str, list] = {}
    for view in VIEWS:
        nodes[f"load_{view}"] = {"class_type": "LoadImage", "inputs": {"image": images[view]}}
        nodes[f"enc_{view}"] = {
            "class_type": "CLIPVisionEncode",
            "inputs": {"clip_vision": ["ckpt", 1], "image": [f"load_{view}", 0], "crop": "none"},
        }
        cond_inputs[view] = [f"enc_{view}", 0]
    nodes["cond"] = {"class_type": "Hunyuan3Dv2ConditioningMultiView", "inputs": cond_inputs}
    nodes["latent"] = {"class_type": "EmptyLatentHunyuan3Dv2", "inputs": {"resolution": 3072, "batch_size": 1}}
    nodes["sample"] = {
        "class_type": "KSampler",
        "inputs": {
            "model": ["ckpt", 0], "positive": ["cond", 0], "negative": ["cond", 1],
            "latent_image": ["latent", 0], "seed": seed, "steps": steps, "cfg": cfg,
            "sampler_name": "euler", "scheduler": "normal", "denoise": 1.0,
        },
    }
    nodes["decode"] = {
        "class_type": "VAEDecodeHunyuan3D",
        "inputs": {"samples": ["sample", 0], "vae": ["ckpt", 2], "num_chunks": 8000, "octree_resolution": octree},
    }
    nodes["mesh"] = {"class_type": "VoxelToMesh", "inputs": {"voxel": ["decode", 0], "algorithm": "surface net", "threshold": 0.6}}
    nodes["save"] = {"class_type": "SaveGLB", "inputs": {"mesh": ["mesh", 0], "filename_prefix": prefix}}
    return nodes


def _request(path: str, payload: dict | None = None) -> dict:
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(SERVER + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("views_dir", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--seed", type=int, default=12345)
    ap.add_argument("--steps", type=int, default=5)  # turbo 版官方範例 5 步
    ap.add_argument("--cfg", type=float, default=1.0)
    ap.add_argument("--octree", type=int, default=380)  # 官方範例 380；顯存不足改 256
    ap.add_argument("--timeout", type=int, default=3600)
    args = ap.parse_args()

    tag = f"swordcard_{uuid.uuid4().hex[:8]}"
    input_dir = COMFY_ROOT / "input" / tag
    input_dir.mkdir(parents=True, exist_ok=True)
    images: dict[str, str] = {}
    for view in VIEWS:
        src = args.views_dir / f"{view}.png"
        if not src.exists():
            print(f"缺少 {src}")
            return 1
        shutil.copy(src, input_dir / src.name)
        images[view] = f"{tag}/{src.name}"

    prefix = f"3d/{tag}"
    prompt = workflow(images, args.seed, args.steps, args.cfg, args.octree, prefix)
    prompt_id = _request("/prompt", {"prompt": prompt, "client_id": tag})["prompt_id"]
    print(f"queued {prompt_id}")
    start = time.time()
    while time.time() - start < args.timeout:
        history = _request(f"/history/{prompt_id}")
        if prompt_id in history:
            entry = history[prompt_id]
            status = entry.get("status", {})
            if status.get("status_str") == "error":
                print(json.dumps(status, ensure_ascii=False, indent=1)[:4000])
                return 1
            outputs = sorted((COMFY_ROOT / "output" / "3d").glob(f"{tag}*.glb"))
            if outputs:
                args.output.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy(outputs[-1], args.output)
                print(f"done in {time.time() - start:.0f}s → {args.output}")
                return 0
        time.sleep(5)
    print("timeout")
    return 1


if __name__ == "__main__":
    sys.exit(main())
