"""把 public/fonts/ 裡的每個 woff2 分片再裁成只含遊戲用到的字（tools/fonts.mjs 會呼叫）。

python tools/subset_fonts.py <用到的字的文字檔>
需要 fonttools 與 brotli（pip install fonttools brotli）。
"""
from __future__ import annotations

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

FONTS = Path(__file__).resolve().parents[1] / "public" / "fonts"


def main() -> int:
    text = Path(sys.argv[1]).read_text(encoding="utf-8")
    codepoints = {ord(c) for c in text}
    before = after = 0
    for path in sorted(FONTS.glob("*.woff2")):
        before += path.stat().st_size
        font = TTFont(path)
        cmap = font.getBestCmap() or {}
        keep = codepoints & set(cmap)
        options = subset.Options()
        options.flavor = "woff2"
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        sub = subset.Subsetter(options=options)
        sub.populate(unicodes=keep)
        sub.subset(font)
        font.flavor = "woff2"
        font.save(path)
        after += path.stat().st_size
    print(f"裁字：{before / 1024 / 1024:.2f} MB → {after / 1024 / 1024:.2f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
