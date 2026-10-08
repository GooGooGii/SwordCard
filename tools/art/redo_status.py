"""人臉美術重做（Codex 依影片樣本出圖）的進度清單：掃 source_art/cine/codex/ 的實際檔案，改寫 docs/ART_REDO_CHECKLIST.md。

python tools/art/redo_status.py        # 更新清單並印出摘要

清單是「檔案在不在」自動算的，不用手動打勾；額度用完中斷後，重跑這支就知道從哪裡接。
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CODEX = ROOT / "source_art" / "cine" / "codex"
OUT = ROOT / "docs" / "ART_REDO_CHECKLIST.md"
sys.path.insert(0, str(Path(__file__).parent))
from cine_cast import CAST, MAIN  # noqa: E402

MAIN_FILES = ["portrait.png"] + [f"portrait_{e}.png" for e in ("smile", "angry", "surprise", "sad", "resolve")] + ["standee.png"] + [
    f"pose_{p}.png" for p in ("attack", "cast", "guard", "hit")]
SUPPORTING = [c for c in CAST if c not in MAIN]
# 人形敵人（有人臉；怪物類維持本機出圖即可）
HUMAN_ENEMIES = [
    "axe_warrior", "baiyue", "black_thief", "black_wizard", "cleaver_granny", "drunk_arhat", "du_niangzi", "fat_miao", "gai_luojiao",
    "grey_lama", "hammer_warrior", "ji_sanniang", "jiang_qing", "jiangshi_king", "kick_thug", "knife_thug", "lin_tiannan", "miao_fist",
    "miao_spear", "red_ghost_king", "red_lama", "royal_guard", "shi_elder", "snake_linger", "spy_miao", "staff_monk", "sword_guard",
    "toad_mother", "yueru_sword", "yueru_whip", "zombie_soldier", "caiyi_moth", "fox_spirit",
]


def cards_with_people() -> list[str]:
    prompts = json.loads((ROOT / "tools" / "art" / "prompts" / "cards.json").read_text(encoding="utf-8"))
    pat = re.compile(r"LXY|LER|LYR|ANU|WUHOU|\b(man|woman|girl|boy|monk|swordsman|old|warrior|person|people|figure)\b")
    return [k for k, v in prompts.items() if pat.search(v)]


def mark(done: bool) -> str:
    return "[x]" if done else "[ ]"


def main() -> int:
    lines: list[str] = []
    total = done = 0

    def item(path: Path, label: str) -> None:
        nonlocal total, done
        ok = path.exists()
        total += 1
        done += ok
        lines.append(f"- {mark(ok)} {label}")

    lines += ["## 第一批：主角四人（每人 11 張）", "", "輸出：`source_art/cine/codex/<id>/`；指令：`python tools/art/codex_batch1.py`（只補缺的）→ `python tools/art/publish_codex.py <id>`", ""]
    for cid in MAIN:
        have = sum((CODEX / cid / f).exists() for f in MAIN_FILES)
        published = (ROOT / "public" / "assets" / "characters" / f"{cid}_pose_hit.webp").stat().st_mtime > (CODEX / cid / "pose_hit.png").stat().st_mtime \
            if (CODEX / cid / "pose_hit.png").exists() else False
        lines.append(f"### {CAST[cid].split(',')[0]}（`{cid}`）：{have}/11{'，已發布到遊戲' if published else ''}")
        for f in MAIN_FILES:
            item(CODEX / cid / f, f)
        lines.append("")

    lines += ["## 第二批：配角劇情頭像（每人 1 張）", "", "輸出：`source_art/cine/codex/<id>/portrait.png`（腳本待寫：照 codex_batch1 的做法）", ""]
    for cid in SUPPORTING:
        item(CODEX / cid / "portrait.png", f"`{cid}` {CAST[cid][:40]}…")
    lines.append("")

    lines += ["## 卡圖：不由 Codex 出圖", "", "主角卡由 CARD-001（另一個 Claude Code 工作階段）用主角姿勢去背圖合成，第一批發布後重跑 `python tools/art/cards_compose.py compose` 就會換成寫實臉。", ""]

    lines += [f"## 第三批：人形敵人（{len(HUMAN_ENEMIES)} 張）", "", "輸出：`source_art/cine/codex/enemies/<id>.png`（發布到 public/assets/enemies/<id>.webp）", ""]
    for eid in HUMAN_ENEMIES:
        item(CODEX / "enemies" / f"{eid}.png", f"`{eid}`")
    lines.append("")

    head = [
        "# 人臉美術重做清單（依影片樣本，由 Codex 出圖）",
        "",
        "> 自動產生：`python tools/art/redo_status.py`（依檔案是否存在打勾）。不要手改勾選。",
        "> 背景：2026-10-08 使用者指出劇情頭像是 Pixar 卡通臉、不像影片樣本；本機模型做不到樣本的寫實 CG，改由 Codex 帶參考圖出圖。",
        "> 額度：Codex Plus，實測約每張 0.5% 的 5 小時／每週額度。每週額度重置時接著做。",
        "> 不用重做：劇情背景、地圖、戰場、怪物類敵人、無人物卡圖（本機已出、沒有人臉問題）。巫后依使用者指示暫不做。",
        "",
        f"**總進度：{done}/{total}**",
        "",
    ]
    OUT.write_text("\n".join(head + lines) + "\n", encoding="utf-8")
    print(f"{done}/{total} → {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
