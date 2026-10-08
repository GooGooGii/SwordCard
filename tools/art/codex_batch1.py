"""第一批（主角）交給 Codex 出圖：每個角色一個 codex exec，附影片截圖與造型參考。

python tools/art/codex_batch1.py [角色id ...] [--first]   # 預設四人全做；已有 11 張的角色跳過；--first 只畫底圖先確認

Codex 用桌面版內附的 codex.exe（npm 版 CLI 太舊，不支援帳號目前的模型）。
簡報範本：tools/art/codex_batch1.md；參考圖：docs/art-references/codex-batch1/。
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REFS = ROOT / "docs" / "art-references" / "codex-batch1"
TEST = ROOT / "source_art" / "cine" / "codex-test"
LOG = Path(os.environ["TEMP"]) / "xiaoyao_codex_batch1.txt"

CAST = {
    "li_xiaoyao": dict(
        name="李逍遙", weapon="右手持一把樸素的直劍",
        desc="李逍遙，19 歲青年，開朗帶點痞氣、俊朗。黑髮高馬尾用白布條綁，前髮蓬鬆。米色粗織連帽披肩披在雙肩，炭灰交領上衣、白色內領，"
             "棕色皮腰帶、斜背皮帶，深灰長褲、布綁腿、深色布靴。（附圖是影片裡的他，以及你先前畫對的頭像）",
        images=[REFS / "li-linger-closeup.jpg", REFS / "li-fullbody-inventory.jpg", TEST / "li_xiaoyao.png"]),
    "zhao_linger": dict(
        name="趙靈兒", weapon="雙手空著、指尖帶一點淡藍靈光（她用仙術）",
        desc="趙靈兒，17 歲少女，溫柔純淨、很美。頭頂兩個小圓髻、髻上垂長的淡藍絲帶，其餘長髮披下。白色寬袖交領上衣，"
             "寶藍色高腰圍裙式長裙，胸前小小的白色刺繡紋，白色襯裙。（附圖是影片裡的她，以及你先前畫對的頭像）",
        images=[REFS / "li-linger-closeup.jpg", REFS / "linger-back.jpg", TEST / "zhao_linger.png"]),
    "lin_yueru": dict(
        name="林月如", weapon="右手持一把細長的直劍（紅色劍鞘）",
        desc="林月如，18 歲，蘇州林家堡大小姐、劍術好手，英氣自信、很美。長黑髮大多披下，一條長辮子垂在左肩前，側分瀏海。"
             "米白色短袖交領上衣，深紫色寬腰帶（小金飾），深紫色長布片從腰帶垂到小腿一側（不對稱），從一邊肩膀斜披到胸前的深紫披帶，"
             "米白寬褲，深紫長靴與綁腿。附圖：影片裡的她（臉與畫風），以及使用者核准的服裝圖（服裝以它為準，但臉要換成影片那種寫實 CG）。",
        images=[REFS / "yueru-arena-closeup.jpg", REFS / "yueru-li-arena.jpg", REFS / "yueru-costume-approved.png"]),
    "anu": dict(
        name="阿奴", weapon="手拿一根細長彎曲的木杖",
        desc="阿奴，16 歲白苗族公主，活潑俏皮、甜美（纖細的少女，不是小孩）。**造型完全照附圖第一張的公仔**（使用者給的標準答案）："
             "帽子是奶黃色的矮圓筒帽、底部一圈橘色帶、正面一顆紅色寶石飾；帽頂左右兩角各有一撮白色蓬鬆的毛，像新月一樣往外、往下捲"
             "（是柔軟的毛，**不是往上翹的角**，不要畫成維京頭盔）。很長的黑色直髮披下、側瀏海。胸前苗族銀項圈與垂飾；"
             "黃色短袖、橘色袖口；白色上衣外罩綠色交叉的無袖背心與綠色腰帶（銀扣、橘色流蘇），白色短裙，一條長長的綠色飄帶從腰後垂下；"
             "綠色腳環、赤腳；細長木杖。臉要換成影片截圖那種寫實 CG，不要公仔或娃娃臉。附圖：公仔（造型）、影片截圖（畫風）。",
        images=[REFS / "anu-user-figure.png", REFS / "li-linger-closeup.jpg"]),
}


def codex_exe() -> Path:
    exes = sorted((Path(os.environ["LOCALAPPDATA"]) / "OpenAI" / "Codex" / "bin").rglob("codex.exe"), key=lambda p: p.stat().st_mtime)
    return exes[-1]


def log(msg: str) -> None:
    with LOG.open("a", encoding="utf-8") as f:
        f.write(msg + "\n")


FIRST_ONLY = "--first" in sys.argv


def main(only: list[str]) -> int:
    template = (ROOT / "tools" / "art" / "codex_batch1.md").read_text(encoding="utf-8")
    exe = codex_exe()
    for cid, c in CAST.items():
        if only and cid not in only:
            continue
        out = ROOT / "source_art" / "cine" / "codex" / cid
        out.mkdir(parents=True, exist_ok=True)
        if len(list(out.glob("*.png"))) >= 11:
            log(f"skip {cid} (done)")
            continue
        brief = template.replace("{NAME}", c["name"]).replace("{ID}", cid).replace("{DESC}", c["desc"]).replace("{WEAPON}", c["weapon"])
        prompt = "以下是出圖任務說明，照做（附圖是畫風與造型的標準答案）：\n\n" + brief
        if FIRST_ONLY:
            prompt += "\n\n**這次只畫 1 號 portrait.png**（先讓使用者確認造型），其餘 10 張先不要畫。"
        args = [str(exe), "exec", "-C", str(ROOT), prompt, "-i", *[str(p) for p in c["images"]]]
        log(f"=== {cid} start {time.strftime('%H:%M')}")
        with LOG.open("a", encoding="utf-8") as f:
            code = subprocess.run(args, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
        log(f"=== {cid} done exit={code} files={len(list(out.glob('*.png')))} {time.strftime('%H:%M')}")
    return 0


if __name__ == "__main__":
    sys.exit(main([a for a in sys.argv[1:] if not a.startswith("--")]))
