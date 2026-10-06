"""四視角參考圖的「邊緣外擴填色」：把人物邊緣的顏色往外推滿整張背景，存成 *_pad.png。

投影貼圖時，生成網格的輪廓和參考圖常差幾個像素；背景是白色的話，對不準的邊緣
（馬尾、褲管）會沾上白色。外擴後對不準只會取到相鄰的頭髮或衣服顏色。
做法：推拉式金字塔填色（push-pull），只用 numpy 與 Pillow。

python tools/art/pad_views.py <views 資料夾>
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def _resize_bilinear(image: np.ndarray, width: int, height: int) -> np.ndarray:
    channels = [
        np.asarray(Image.fromarray(image[..., c].astype(np.float32), "F").resize((width, height), Image.BILINEAR))
        for c in range(image.shape[2])
    ]
    return np.stack(channels, axis=-1).astype(np.float64)


def push_pull(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    """rgb: HxWx3 float，alpha: HxW 0..1。回傳填滿背景的 rgb。"""
    levels = []
    color, weight = rgb * alpha[..., None], alpha.copy()
    while min(weight.shape) > 2:
        levels.append((color, weight))
        h, w = weight.shape
        h2, w2 = h // 2, w // 2
        color = color[: h2 * 2, : w2 * 2].reshape(h2, 2, w2, 2, 3).sum(axis=(1, 3))
        weight = weight[: h2 * 2, : w2 * 2].reshape(h2, 2, w2, 2).sum(axis=(1, 3))
    filled = color / np.maximum(weight, 1e-6)[..., None]
    for color, weight in reversed(levels):
        h, w = weight.shape
        up = _resize_bilinear(filled, w, h)  # 雙線性：邊緣顏色平滑往外延伸，不會出現色塊
        known = np.clip(weight, 0.0, 1.0)[..., None]
        own = color / np.maximum(weight, 1e-6)[..., None]
        filled = own * known + up * (1.0 - known)
    return filled


def main() -> int:
    folder = Path(sys.argv[1])
    for rgba_path in sorted(folder.glob("*_rgba.png")):
        view = rgba_path.name.removesuffix("_rgba.png")
        rgba = np.asarray(Image.open(rgba_path).convert("RGBA")).astype(np.float64) / 255.0
        # 只信任實心像素，並往內縮 2px：去背的半透明邊緣常混著白底，一起重新填
        solid = Image.fromarray(((rgba[..., 3] > 0.5) * 255).astype(np.uint8), "L").filter(ImageFilter.MinFilter(5))
        alpha = (np.asarray(solid) > 127).astype(np.float64)
        filled = push_pull(rgba[..., :3], alpha)
        out = np.clip(filled * 255.0 + 0.5, 0, 255).astype(np.uint8)
        Image.fromarray(out, "RGB").save(folder / f"{view}_pad.png")
        print(f"{view}_pad.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
