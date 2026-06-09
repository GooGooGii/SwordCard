"""一次性美術降採樣：把過大的卡牌/敵人圖降到遊戲實際需要的尺寸。
卡牌 -> 最長邊 512、敵人 -> 最長邊 768。保留 alpha 與長寬比，只縮不放。
原圖留在 git 歷史可還原。用法：python tools/downscale_art.py
"""
import glob
import os
from PIL import Image

# 目標最長邊（依各類別遊戲內實際顯示尺寸定，皆遠大於顯示、肉眼無損）：
#   卡牌 顯示 ~140-360 / 敵人 ~290 / 特效 render ~130-390(+縮放) / 藥水 ~48 / 遺物 icon
# 不動：背景(全螢幕)、肖像(選角全身)、事件插圖(全螢幕背景 1280×720)
TARGETS = [
    ("assets/art/cards", 512),
    ("assets/art/enemies", 768),
    ("assets/art/effects", 768),
    ("assets/art/potions", 256),
    ("assets/art/relics", 256),
]

def main() -> None:
    total_before = 0
    total_after = 0
    n = 0
    for folder, target in TARGETS:
        for path in sorted(glob.glob(os.path.join(folder, "*.png"))):
            before = os.path.getsize(path)
            with Image.open(path) as im:
                im = im.convert("RGBA")
                w, h = im.size
                longest = max(w, h)
                if longest <= target:
                    continue
                scale = target / float(longest)
                nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
                out = im.resize((nw, nh), Image.LANCZOS)
            out.save(path, "PNG", optimize=True)
            after = os.path.getsize(path)
            total_before += before
            total_after += after
            n += 1
            print(f"  {w}x{h}->{nw}x{nh}  {before/1048576:.1f}->{after/1048576:.1f}MB  {os.path.basename(path)}")
    print(f"\n降採樣 {n} 個檔：{total_before/1048576:.0f} MB -> {total_after/1048576:.0f} MB（省 {(total_before-total_after)/1048576:.0f} MB）")

if __name__ == "__main__":
    main()
