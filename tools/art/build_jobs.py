"""由 prompts/*.json 組出 run_jobs.py 用的 jobs 檔。風格前綴與角色造型集中在這裡，確保全遊戲一致。

python tools/art/build_jobs.py   # 產生 tools/art/jobs/*.json
"""
from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
JOBS = HERE / "jobs"

STYLE = ("Chinese xianxia fantasy card illustration in a detailed painted environment, never a plain studio backdrop, "
         "semi-realistic painterly digital painting with visible brushwork, soft cinematic lighting, rich harmonious colors, "
         "dramatic dynamic composition, polished game art, no text, no letters, no watermark, no border")

# 卡圖的場景：第一版全都落在「霧夜竹林＋樓閣」，看起來每張都一樣。依屬性挑場景，沒有屬性的依卡名雜湊挑，
# 場景都取自仙劍一的旅程（十里坡、仙靈島、蘇州、隱龍窟、鎖妖塔、苗疆…），並且日夜晴雨錯開。
ENV_BY_ELEMENT = {
    "wind": ["on a windswept grassy cliff above a sea of clouds at midday", "in a swaying bamboo grove on a bright breezy morning"],
    "thunder": ["on a storm-lashed mountain peak under dark thunderclouds", "on a pagoda rooftop in a night thunderstorm"],
    "water": ["on a misty lake with lotus flowers at dawn", "beside a waterfall in a jade green gorge"],
    "fire": ["in a volcanic cave glowing with lava", "on a battlefield at dusk under a blood red sunset"],
    "earth": ["in a red sandstone canyon at golden hour", "inside an ancient stone tomb lit by torches"],
}
ENVS = [
    "on the sunny grassy slopes of Shilipo with wildflowers",
    "in a peach blossom forest on a fairy island with falling petals",
    "on a canal street of ancient Suzhou with stone bridges at sunset",
    "in the courtyard of a martial arts manor in the afternoon",
    "inside a damp limestone cave with green glowing crystals",
    "inside a dark demon locking tower with chains and talismans",
    "in a Miao mountain village with stilt houses and terraced fields",
    "in a snowy pine forest on Shushan mountain",
    "at a seaside fishing harbor in the morning",
    "in a moonlit graveyard with ghost fire",
    "on a desert road with dunes under a clear blue sky",
    "in an ancient temple hall with golden Buddha statues and incense smoke",
]

# 角色造型（與 3D 模型、劇情立繪共用同一份描述，REDESIGN §6.1 同一張臉原則）
COSTUMES = {
    "LXY": "Li Xiaoyao, a cheerful 18-year-old Chinese young swordsman with a high black ponytail tied with a light blue ribbon, "
           "light blue-grey cross-collar short jacket over a white inner robe, dark brown sash, dark navy trousers",
    "LER": "Zhao Linger, a gentle 16-year-old Chinese girl with very long straight black hair and two small hair loops tied with light blue ribbons, "
           "light blue and white layered hanfu dress with a pink sash",
    "LYR": "Lin Yueru, a spirited 18-year-old Chinese swordswoman with a long black ponytail tied with a crimson ribbon, "
           "crimson and white fitted martial outfit with a sash, confident eyes",
    "ANU": "Anu, a lively 16-year-old girl of the Miao (Hmong) ethnic minority of southwest China with East Asian features, an ornate silver headdress and silver necklaces, "
           "deep purple and indigo embroidered Miao jacket and pleated skirt, bright eyes",
    "WUHOU": "the Queen of Nanzhao, a dignified beautiful woman in flowing white and water-blue royal robes with a silver crown",
}


def expand(text: str) -> str:
    for key, desc in COSTUMES.items():
        text = text.replace(key, desc)
    return text


def seed_of(name: str) -> int:
    h = 2166136261
    for ch in name:
        h = ((h ^ ord(ch)) * 16777619) & 0xFFFFFFFF
    return h % 100000


# 第二版裡自己畫了外框（白邊、黑邊、金框，像「卡中卡」）的卡：換種子重出，並明講要滿版
RESEED = {"item_trialfruit", "li_myriad", "ling_blizzard", "ling_earthfire", "ling_snowdemon", "ling_thunder", "thought", "wuhou_staff", "yue_phoenix"}
FULL_BLEED = "full-bleed scene filling the whole image edge to edge, no frame, no card border"
# 換種子後仍有圓角白邊的：發佈時每邊裁掉 9% 再縮放（run_jobs.py 的 publish.crop）
CROP = {"item_trialfruit": 0.09, "ling_blizzard": 0.09, "ling_earthfire": 0.09, "ling_snowdemon": 0.09, "thought": 0.09, "wuhou_staff": 0.09}


def card_env(card_id: str, scene: str) -> str:
    """場景：依卡圖描述裡的屬性字眼挑，否則依卡名雜湊挑（固定，不會每次出圖都換）"""
    text = scene.lower()
    for element, keywords in {
        "wind": ["wind", "gale", "whirlwind"],
        "thunder": ["thunder", "lightning"],
        "water": ["water", "ice", "frost", "snow"],
        "fire": ["fire", "flame", "burn"],
        "earth": ["earth", "rock", "stone", "boulder"],
    }.items():
        if any(k in text for k in keywords):
            options = ENV_BY_ELEMENT[element]
            return options[seed_of(card_id) % len(options)]
    return ENVS[seed_of(card_id) % len(ENVS)]


def cards() -> list[dict]:
    prompts = json.loads((HERE / "prompts" / "cards.json").read_text(encoding="utf-8"))
    jobs = []
    for card_id, scene in prompts.items():
        jobs.append({
            "out": f"source_art/cards/{card_id}.png",
            "prompt": f"{expand(scene)}, {card_env(card_id, scene)}. {STYLE}" + (f", {FULL_BLEED}." if card_id in RESEED else "."),
            "width": 960,
            "height": 640,
            "seed": seed_of(card_id + "#2" if card_id in RESEED else card_id),
            "publish": {"path": f"public/assets/cards/{card_id}.jpg", "width": 480, "height": 320, "quality": 84, **({"crop": CROP[card_id]} if card_id in CROP else {})},
        })
    return jobs


def main() -> None:
    JOBS.mkdir(exist_ok=True)
    groups = {"cards": cards()}
    extra = HERE / "prompts" / "assets.json"
    if extra.exists():
        for group, items in json.loads(extra.read_text(encoding="utf-8")).items():
            groups[group] = [
                {
                    **item,
                    "prompt": expand(item["prompt"]),
                    "seed": item.get("seed", seed_of(item["out"])),
                }
                for item in items
            ]
    for name, jobs in groups.items():
        (JOBS / f"{name}.json").write_text(json.dumps(jobs, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"{name}: {len(jobs)} jobs")


if __name__ == "__main__":
    main()
