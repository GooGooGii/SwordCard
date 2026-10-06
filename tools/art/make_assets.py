"""產生 prompts/assets.json：敵人立繪（去背 PNG）與劇情頭像（去背 PNG，主角六種表情）。

python tools/art/make_assets.py   # 寫出 prompts/assets.json
python tools/art/build_jobs.py    # 再展開成 jobs/enemies.json、jobs/portraits.json

敵人的外觀依 DOS 版原作（名稱與出沒地點見 src/content/enemies/*.ts 的 canon 欄位）。
立繪一律「面向右、四分之三側身、純色背景」，方便去背後立在 3D 舞台左上方、面朝我方。
"""
from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

STANDEE = ("full body game enemy standee, three-quarter view facing right, whole body visible from head to feet, "
           "isolated on a plain flat light grey background, no ground, no shadow, Chinese xianxia fantasy, "
           "semi-realistic painterly digital painting with visible brushwork, soft lighting, rich colors, "
           "polished game art, no text, no watermark")
PORTRAIT = ("waist-up character portrait for a visual novel, facing slightly to the side, looking toward the viewer, "
            "isolated on a plain flat light grey background, Chinese xianxia fantasy, semi-realistic painterly digital painting, "
            "visible brushwork, soft cinematic lighting, polished game art, no text, no watermark")

# id: (描述, 寬高比 "tall" | "wide")
ENEMIES: dict[str, tuple[str, str]] = {
    # 序章
    "grass_imp": ("a small mischievous green grass imp made of leaves and vines with glowing yellow eyes", "tall"),
    "leaf_sprite": ("a floating green leaf fairy spirit with leaf wings swirling with a small whirlwind", "tall"),
    "bee": ("a giant demonic honey bee with a glowing red venomous stinger, hovering", "wide"),
    "wine_jar": ("an animated old clay wine jar monster with a red paper seal, little stubby legs and a grinning mouth, wine fumes", "tall"),
    "lantern": ("a haunted floating red paper lantern ghost with a ghostly blue flame face", "tall"),
    "cocoon": ("a giant pale silk cocoon monster wriggling, with a grub head peeking out", "tall"),
    "miao_fist": ("a muscular brawler, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing and a black turban, bare-knuckle fighting stance", "tall"),
    "fat_miao": ("a huge fat warrior, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing with silver ornaments, holding a curved crescent blade", "tall"),
    # 第一章
    "knife_thug": ("a scruffy Chinese street thug with a saber, ragged grey clothes, sneering", "tall"),
    "kick_thug": ("a burly Chinese street ruffian martial artist in a kicking stance, bare arms, brown clothes", "tall"),
    "yueru_whip": ("Lin Yueru, a spirited 18-year-old Chinese swordswoman with a long black ponytail tied with a crimson ribbon, crimson and white fitted martial outfit, cracking a long golden whip, angry fierce expression", "tall"),
    "yueru_sword": ("Lin Yueru, a spirited 18-year-old Chinese swordswoman with a long black ponytail tied with a crimson ribbon, crimson and white fitted martial outfit, holding a slender sword in a dueling stance, determined", "tall"),
    "snake_linger": ("a gentle girl with very long black hair whose lower body is a huge white serpent tail with shimmering scales, goddess Nuwa lineage, sad golden eyes, moonlight", "tall"),
    # 第二章
    "furball": ("a round black furry puffball monster with big eyes and tiny fangs", "wide"),
    "green_snake": ("a green venomous snake coiled and rearing to strike", "wide"),
    "red_snake": ("a crimson venomous snake rearing with dripping purple venom", "wide"),
    "red_slime": ("a red gelatinous slime monster wearing a tattered little cloak, splitting in two", "wide"),
    "hydra": ("a fearsome nine-headed serpent hydra with red scales breathing fire", "wide"),
    "tiger": ("a huge fierce white-browed tiger with glaring eyes, snarling", "wide"),
    "snake_man": ("a half-man half-snake demon, muscular pale man's upper body with green scales and a long snake tail, fangs, evil green eyes", "tall"),
    "fox_spirit": ("a seductive fox spirit woman with fox ears and several fluffy fox tails, purple robes crackling with thunder magic", "tall"),
    # 第三章
    "staff_monk": ("a sturdy Buddhist warrior monk with a shaved head holding a long wooden staff", "tall"),
    "red_lama": ("a Tibetan lama in red robes chanting with prayer beads", "tall"),
    "grey_lama": ("a stern lama in grey robes in a palm-strike stance, vajra posture", "tall"),
    "zombie": ("a Chinese jiangshi hopping zombie in a Qing official hat and robes with a yellow paper talisman, rotting green skin, arms outstretched", "tall"),
    "ripper": ("a headless ghost with a ripped open chest and long claws, tattered burial clothes", "tall"),
    "cleaver_granny": ("a creepy hunchbacked old ghost granny holding a bloody meat cleaver, wild white hair", "tall"),
    "flying_head": ("a floating severed ghost head with long trailing black hair and sharp teeth", "wide"),
    "zombie_soldier": ("an undead ancient Sui dynasty soldier in rusted armor holding a spear, glowing eyes", "tall"),
    "white_ghost": ("Bai Wuchang the white impermanence ghost, tall pale figure in white robes and a tall white hat, long red tongue, chain", "tall"),
    "jiangshi_king": ("a giant undead Sui dynasty general zombie king in ornate rusted armor and helmet, red glowing eyes, long claws", "tall"),
    "red_demon": ("a hulking red-skinned horned demon ogre wreathed in flames", "tall"),
    "blue_demon": ("a hulking blue-skinned horned demon ogre covered in frost", "tall"),
    "blood_bug": ("a disgusting blood-sucking worm bug with a round toothy mouth, dark red", "wide"),
    "red_ghost_king": ("PAL1 DOS Red Ghost King, pale East Asian human face, black moustache and pointed beard, tall tilted dark cap with muted gold bands, oversized dark umber robe with wide sleeves, grey crossed collar and red edging, compact kneeling pose with one knee raised and hands resting on the knees, smooth unmarked forehead, no horns, no fangs, no armour", "tall"),
    # 第四章
    "miao_spear": ("a spearman, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing, holding a long spear", "tall"),
    "sword_guard": ("a temple guard swordsman, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing and dark armor", "tall"),
    "earth_imp": ("a small mischievous earth goblin made of dirt and clay throwing fire", "tall"),
    "feifei": ("a chubby round pink piglet-like little monster, cute but annoying", "wide"),
    "ji_sanniang": ("a heroic female thief in a black night-walker outfit with a mask, throwing darts, red plum blossom ornament", "tall"),
    "black_thief": ("a female thief in a black outfit and face veil, holding throwing knives", "tall"),
    "fire_toad": ("a giant fire-eating toad with orange skin breathing flames", "wide"),
    "ice_toad": ("a giant blue toad exhaling icy frost", "wide"),
    "red_centipede": ("a giant red centipede with venomous fangs and poisonous mist", "wide"),
    "toad_mother": ("a wild-haired demon woman in tattered robes, the golden toad ghost mother, casting curses", "tall"),
    "golden_toad": ("an enormous golden toad monster with warty gold skin and a huge mouth", "wide"),
    "shi_elder": ("an old hunchbacked human elder sorcerer with a long grey beard, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing robes, holding a snake-head staff, sinister", "tall"),
    # 第五章
    "lin_tiannan": ("a dignified middle-aged Chinese martial arts grandmaster with a goatee in rich blue robes, holding a long sword", "tall"),
    "caiyi_moth": ("a gentle beautiful butterfly spirit woman with large translucent pastel butterfly wings and flowing robes", "tall"),
    "small_spider": ("a large black spider with red markings", "wide"),
    "web_spider": ("a large rainbow-colored spider spinning glowing silk", "wide"),
    "tree_imp": ("a small walking tree demon with a gnarled bark face and branch arms", "tall"),
    "black_spider": ("a huge black spider demon with a woman's face crackling with thunder", "wide"),
    "du_niangzi": ("a beautiful but terrifying spider demon queen, a woman's upper body and six hairy black spider legs, crackling with thunder", "tall"),
    # 第六章
    "drunk_arhat": ("a drunken arhat monk with a big belly holding a wine gourd, staggering drunken fist stance", "tall"),
    "thunder_imp": ("a small blue thunder god imp with a drum and hammer, crackling lightning, flying", "tall"),
    "hammer_warrior": ("a heavily armored warrior with a giant golden hammer", "tall"),
    "xingtian": ("Xingtian the headless giant with eyes on his chest and mouth on his belly, holding an axe and shield", "tall"),
    "sickle_weasel": ("a weasel demon with sickle blades for arms, swift wind", "wide"),
    "hop_frog": ("a big green frog demon jumping, comical", "wide"),
    "axe_warrior": ("a giant demon warrior with a huge battle axe, dark armor", "tall"),
    "jiang_qing": ("an old hermit swordsman with a very long beard dragging on the floor, holding a seven-star sword", "tall"),
    "tiangui": ("the heavenly ghost emperor, a towering horned demon king on a throne of bones, dark robes, hellfire", "tall"),
    "mingwang": ("a colossal three-headed six-armed guardian wisdom king statue come alive, wearing a necklace of glowing jade bodhi beads", "tall"),
    "wind_dragon": ("a long Chinese dragon made of swirling green wind", "wide"),
    "earth_dragon": ("a long Chinese dragon with rocky brown earthen scales", "wide"),
    "poison_dragon": ("a long Chinese dragon with sickly purple poisonous scales dripping venom", "wide"),
    "thunder_dragon": ("a long Chinese dragon with violet scales crackling with lightning", "wide"),
    "ice_dragon": ("a long Chinese dragon with icy blue crystalline scales breathing frost", "wide"),
    "gold_dragon": ("a long Chinese dragon with gleaming golden metal scales", "wide"),
    "fire_dragon": ("a long Chinese dragon with crimson scales wreathed in fire", "wide"),
    # 第七章
    "birdman": ("a bird-man demon with eagle head and wings holding lightning", "tall"),
    "purple_phoenix": ("a purple phoenix bird spreading its wings", "wide"),
    "orangutan": ("a huge fierce orangutan beast casting earth magic, pounding its chest", "tall"),
    "golden_phoenix": ("a majestic golden-winged phoenix with blazing golden feathers spreading enormous wings", "wide"),
    "spy_miao": ("a spy martial artist with nunchaku, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing", "tall"),
    "fire_jiao": ("a fire jiao dragon serpent wreathed in flames", "wide"),
    "thunder_wyrm": ("a thunder wyrm dragon with crackling purple lightning", "wide"),
    "root": ("a writhing mass of evil tree roots with a face", "wide"),
    "qilin": ("a fierce fire qilin beast with burning mane, flaming eyes, scales and hooves", "wide"),
    "water_beast": ("a colossal eight-headed water serpent monster rising from a flood, dark blue scales", "tall"),
    # 終章
    "earth_spider": ("a giant brown earth spider with a puppet worm on its back", "wide"),
    "poison_centipede": ("a giant five-poison centipede, black and purple, venomous", "wide"),
    "purple_hydra": ("a purple nine-headed hydra serpent", "wide"),
    "poison_scorpion": ("a giant five-poison scorpion with glowing venomous tail", "wide"),
    "black_wizard": ("a sorcerer casting a curse, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing robes with bone ornaments", "tall"),
    "royal_guard": ("a Nanzhao royal guard in red and gold armor with a rattan shield and curved blade, blank puppet eyes", "tall"),
    "gai_luojiao": ("Gai Luojiao, a seductive human priestess of the Miao (Hmong) ethnic minority with East Asian features, ornate black and red embroidered tribal clothing, silver ornaments, holding a snake", "tall"),
    "earth_beast": ("a colossal earth demon beast like a bull ogre covered in rock armor", "tall"),
    "tree_demon": ("a monstrous ancient tree demon with a twisted face in the trunk and writhing branch arms", "tall"),
    "baiyue": ("the Moon Worship Cult Master, a tall cold handsome sorcerer with long black hair, black robes with a silver moon emblem, dark aura", "tall"),
}

# 劇情頭像。主角六種表情（REDESIGN §5）；配角一張。描述沿用 build_jobs.py 的 COSTUMES token。
EXPRESSIONS = {
    "": "calm neutral expression",
    "smile": "warm smiling expression",
    "angry": "angry frowning expression",
    "surprise": "surprised wide-eyed expression",
    "sad": "sad teary expression",
    "resolve": "determined resolute expression",
}
HEROES = {"li_xiaoyao": "LXY", "zhao_linger": "LER", "lin_yueru": "LYR", "anu": "ANU", "wuhou": "WUHOU"}
NPCS = {
    "aunt": "Aunt Li, a stout middle-aged Chinese innkeeper woman with her hair in a bun, apron over plain clothes, strong and kind",
    "drunk": "the Drunken Sword Immortal, a scruffy unkempt Taoist with messy hair and stubble, carrying a red lacquered wine gourd and a sword",
    "granny": "the old grandmother of Shuiyue palace, a wise white-haired old woman in white and pale blue robes",
    "miao_leader": "a cold tribe leader, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing and a black turban, holding a curved blade",
    "fat_miao": "a huge fat warrior, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing with silver ornaments",
    "lin_tiannan": "Lin Tiannan, a dignified middle-aged martial arts master with a goatee in rich blue robes",
    "liu_jinyuan": "Liu Jinyuan, a gentle young scholar in pale scholar robes and hat",
    "caiyi": "Caiyi, a gentle beautiful young woman with pastel butterfly hairpins and soft robes",
    "shi_zhanglao": "Elder Shi, an old hunchbacked human sorcerer with a long grey beard, a man of the Miao (Hmong) ethnic minority of southwest China with East Asian features, wearing black indigo-dyed tribal clothing robes, holding a snake-head staff",
    "sword_saint": "the Sword Saint of Shushan, an old immortal swordsman with long white hair and beard in white robes",
    "shenggu": "Shenggu, a wise middle-aged Miao shaman woman with herbs and silver ornaments",
    "gai_luojiao": "Gai Luojiao, a seductive human priestess of the Miao (Hmong) ethnic minority with East Asian features, black and red embroidered tribal clothing, silver ornaments",
    "baiyue": "the Moon Worship Cult Master, a cold handsome sorcerer with long black hair in black robes with a silver moon emblem",
    "ji_sanniang": "Ji Sanniang, a heroic female thief in a black night outfit with a red plum blossom hair ornament",
    "zhixiu": "Abbot Zhixiu, a kind elderly Buddhist abbot with a white beard and kasaya robe",
    "villager": "an ordinary Chinese villager in plain cotton clothes",
    "tang_yu": "Tang Yu, a polite young Han Chinese swordsman from Dali with a blue-green sword",
    "wuwang": "the King of Nanzhao, a middle-aged Miao king in red and gold royal robes with a crown",
}


def enemy_jobs() -> list[dict]:
    jobs = []
    for eid, (desc, shape) in ENEMIES.items():
        w, h = (832, 1088) if shape == "tall" else (1152, 832)
        standee = STANDEE
        if eid == "red_ghost_king":
            standee = STANDEE.replace("whole body visible from head to feet", "entire high cap and crouched robe silhouette visible, no water or vortex baked into the cutout")
        jobs.append({
            "out": f"source_art/enemies/{eid}.png",
            "prompt": f"{desc}. {standee}.",
            "width": w,
            "height": h,
            "publish": {"path": f"public/assets/enemies/{eid}.webp", "width": 640, "height": 768, "cutout": True},
        })
    return jobs


def portrait_jobs() -> list[dict]:
    jobs = []
    for cid, token in HEROES.items():
        for expr, look in EXPRESSIONS.items():
            suffix = f"_{expr}" if expr else ""
            jobs.append({
                "out": f"source_art/portraits/{cid}{suffix}.png",
                "prompt": f"{token}, {look}. {PORTRAIT}.",
                "width": 832,
                "height": 1088,
                # 同一角色用同一個種子：只換表情，臉比較不會跑掉
                "seed": sum(ord(c) for c in cid) * 97 % 100000,
                "publish": {"path": f"public/assets/portraits/{cid}{suffix}.webp", "width": 640, "height": 840, "cutout": True},
            })
    for nid, desc in NPCS.items():
        jobs.append({
            "out": f"source_art/portraits/{nid}.png",
            "prompt": f"{desc}. {PORTRAIT}.",
            "width": 832,
            "height": 1088,
            "publish": {"path": f"public/assets/portraits/{nid}.webp", "width": 640, "height": 840, "cutout": True},
        })
    return jobs


HERO_STANDEE = ("full body character standee, three-quarter view facing left, whole body visible from head to feet, "
                "standing in a ready combat stance, isolated on a plain flat light grey background, no ground, no shadow, "
                "Chinese xianxia fantasy, semi-realistic painterly digital painting with visible brushwork, soft lighting, "
                "polished game art, no text, no watermark")


def standee_jobs() -> list[dict]:
    """可操作角色的 2D 全身立繪：3D 模型未交付前在戰鬥中代替（面向左，朝左上方的敵人）。"""
    return [
        {
            "out": f"source_art/characters/{cid}_standee.png",
            "prompt": f"{token}. {HERO_STANDEE}.",
            "width": 832,
            "height": 1216,
            "seed": sum(ord(c) for c in cid) * 97 % 100000,
            "publish": {"path": f"public/assets/characters/{cid}_standee.webp", "width": 640, "height": 960, "cutout": True},
        }
        for cid, token in HEROES.items()
    ]


SCENE = ("wide establishing shot background painting for a visual novel, eye level, no people, no characters, "
         "Chinese xianxia fantasy, ancient China, semi-realistic painterly digital painting with visible brushwork, "
         "soft cinematic lighting, rich harmonious colors, calm lower third, no text, no watermark")
MAP = ("hand-painted antique Chinese silk scroll map seen from above, ink and mineral pigments on aged silk, "
       "mountains rivers and landmarks drawn as small illustrations, no text, no labels, no letters, no watermark")

# 劇情背景（docs/ART_LIST.md，src/content/backgrounds.ts）
STORY: dict[str, str] = {
    "yuhang_inn_hall": "the main hall of a small seaside Chinese inn, wooden tables and benches, a counter with wine jars, a staircase to the second floor, a window showing the sea, warm morning light",
    "yuhang_inn_front": "the front of a small Chinese inn on a seaside town street, a plain blank cloth wine flag with no writing, a fishing harbor with boats in the distance, early morning",
    "xianling_fog": "a small rowing boat's view into thick white sea fog, faint island silhouette and strange glowing lights in the mist",
    "xianling_pool": "a hidden clear pool deep in a peach blossom forest on a fairy island, falling pink petals, mist, magical serene atmosphere",
    "shuiyue_palace": "the main hall of Shuiyue Palace on a fairy island, white jade corridors, flowing gauze curtains, surrounding water pools, moonlight white and water blue",
    "shilipo_path": "a mountain path on a grassy hillside called Shilipo, wildflowers, distant mountains, bushes with buzzing bees, sunny afternoon",
    "mountain_temple": "inside a ruined small mountain god temple, broken roof tiles with light beams, an altar table, faded deity statue, cobwebs",
    "shuiyue_ruin": "the ruined Shuiyue Palace after a massacre, collapsed doors, burnt gauze curtains, scattered weapons, overcast grey sky, no bodies",
    "suzhou_outskirts": "a road outside ancient Suzhou with willow trees, a stone bridge over a canal, a small tea stall, the city wall in the distance",
    "suzhou_street": "a busy ancient Suzhou street with a red silk martial arts contest stage in the middle, banners, distant crowd silhouettes",
    "lin_manor": "the courtyard of a grand martial arts clan manor, a training ground with weapon racks, high walls, elegant halls",
    "yinlong_cave": "a damp cold limestone cave with stalactites, dripping water, eerie green glow, rock walls like snake scales",
    "baihe_village": "a quiet village by a misty white river with bamboo houses and a water wheel",
    "yufo_temple": "a lonely Buddhist mountain temple hall with a white jade Buddha statue and incense burner",
    "heishui_town": "a dark town at night with shut doors covered in yellow paper talismans, fog, a black river",
    "general_tomb": "an ancient general's tomb corridor lined with armored stone figures, torches, a stone sarcophagus",
    "blood_pool": "an underground cavern with a bubbling dark red blood pool, bones, eerie red light",
    "guiyin_mountain": "a gloomy mountain path with white funeral banners, dead trees, grey purple sky",
    "guiyin_altar": "a black stone altar on a mountain top carved with sinister runes, ghostly blue fire",
    "yangzhou_night": "ancient Yangzhou at night, red lanterns over a canal, tiled rooftops, a night market",
    "toad_mountain": "a swampy mountain valley with green poisonous fog and strange rocks",
    "mountain_inn": "a shabby wilderness inn at the foot of a mountain, thatched roof, hitching post, a wine flag",
    "capital_mansion": "an elegant scholar official's mansion interior, a study connected to a bedroom, scrolls, a candle beside a sickbed, a courtyard outside the window",
    "spider_forest": "a dark forest with white spider silk hanging between trees, a huge dead tree with a hollow",
    "shushan": "Shushan sword sect mountains floating above a sea of clouds, stone stairs, cranes flying",
    "demon_tower": "inside the Demon Locking Tower, circular stone walls, heavy chains, talismans, endless darkness",
    "tower_top": "the open top of a tall pagoda tower, huge dragon pillars, storm clouds and lightning",
    "shenggu_house": "a wooden house in Miao mountains with hanging herbs, a bamboo fence, a hillside outside",
    "sacred_forest": "a sacred forest of colossal ancient trees with golden light beams through the leaves",
    "dali_town": "a painterly illustration, not a photograph, of ancient Dali city with snowy Cangshan mountains, Erhai lake, white Bai style roofs, cracked dry earth from drought, soft painted clouds",
    "qilin_cave": "a volcanic cave with lava streams and molten rock pillars, heat haze",
    "nuwa_shrine": "an ancient stone shrine with a statue of goddess Nuwa with a human head and serpent body",
    "nanzhao_city": "the city of Nanzhao with Miao style towers and streets, red ochre walls",
    "nanzhao_palace": "the outer hall of the Nanzhao royal palace, red ochre palace buildings, Miao totem pillars",
    "nanzhao_flood": "the outskirts of Nanzhao city drowning in a raging flood under torrential rain",
    "dali_white_miao": "a White Miao stilt house interior with silver ornaments, a bamboo bed, warm light",
    "trial_cave": "a trial cave with stone walls carved with glowing abstract geometric serpent patterns and spirals, no letters, no written characters",
    "nuwa_temple": "the sacred hall of a Nuwa temple with a warm pool reflecting skylight, holy white light",
    "nanzhao_throne": "the throne hall of the Nanzhao palace with a throne and curtains, sinister tree roots crawling from cracks in the floor",
    "nanzhao_altar": "a high altar on top of a palace overlooking a lake and a city under a full moon",
}

MAPS: dict[str, str] = {
    "prologue": "a small seaside fishing town on the west, a misty fairy island in the eastern sea, grassy hills and a small mountain temple to the south",
    "ch1": "a fairy island in the east sea, an official road westward, the canal city of Suzhou and a grand manor",
    "ch2": "the outskirts of Suzhou, a mountain with a dark cave, a village beside a white river",
    "ch3": "a temple on a mountain, a dark riverside town, a graveyard and an ancient tomb mound",
    "ch4": "a gloomy mountain with an altar, the canal city of Yangzhou, a toad shaped mountain, a lonely inn",
    "ch5": "a grand manor, the imperial capital with walls, a dark forest",
    "ch6": "Shushan mountains above clouds, a tall pagoda tower, a small house in southern mountains",
    "ch7": "a sacred forest, Dali city by a lake, a volcano cave, an ancient shrine, the city of Nanzhao",
    "finale": "a mountain village, a trial cave, a temple, a royal palace by a lake",
}


GROUND = ("seen from a high camera angle looking down at about 50 degrees, the ground fills the entire frame, "
          "no sky, no horizon, the middle of the frame is an open clear area, tall objects only near the edges, "
          "light from the upper left, painterly Chinese fantasy game battle background, semi-realistic digital painting, "
          "visible brushwork, rich colors, no people, no characters, no text, no watermark")

# 戰場地面（SCENE-001 第一版，TASKS 交付規格 B）；Codex 之後可依原作參照覆蓋精修
BATTLE: dict[str, str] = {
    "yuhang_inn": "the wooden plank floor inside an old Chinese inn, tables benches and wine jars pushed to the edges",
    "xianling": "lush fairy island grass with scattered peach blossom petals, a winding stone path, small clear pools near the edges",
    "suzhou_road": "an ancient road of packed earth and worn paving stones outside Suzhou, willow trees and a canal bank at the edges",
    "lin_arena": "a large wooden martial arts contest platform with red cloth trim, weapon racks at the edges, courtyard tiles beyond",
    "yinlong_cave": "a wet limestone cave floor with puddles, stalagmites at the edges, faint green glow",
    "baihe": "riverside village grass and dirt with a misty white river along one edge, bamboo fence",
    "graveyard": "a desolate graveyard ground with dead grass and fog, old tombstones and broken coffins at the edges",
    "general_tomb": "ancient stone tomb floor tiles with carved patterns, armored stone soldier statues and torches at the edges",
    "blood_pool": "a dark cavern floor of red stone with bones, a bubbling pool of dark blood along one edge",
    "guiyin": "dark mountain rock ground with withered grass, white funeral banners at the edges, gloomy purple light",
    "yangzhou": "a stone paved street at night beside a canal, red lanterns and shop fronts at the edges",
    "toad_hill": "swampy muddy ground with green puddles, toxic green fog, strange rocks at the edges",
    "ministry": "an elegant mansion courtyard of grey stone tiles at night, potted plants and a covered corridor at the edges",
    "spider_forest": "a dark forest floor of roots and dead leaves, thick white spider webs between trees at the edges",
    "demon_tower": "the dark stone floor of a demon locking tower with a large carved circular seal, iron chains and talismans at the edges",
    "tower_top": "the tiled roof platform at the top of a pagoda, huge carved dragon pillars at the edges, stormy light",
    "sacred_forest": "a sacred forest floor with giant mossy tree roots, ferns, patches of golden sunlight",
    "qilin_cave": "black volcanic rock floor with glowing lava cracks, heat haze, rock pillars at the edges",
    "water_maze": "flooded ground under shallow churning water with submerged stones, debris, rain ripples",
    "trial_cave": "a stone cave floor carved with glowing blue ancient runes, crystal formations at the edges",
    "nuwa_temple": "a white marble temple floor with serpent patterns, a warm pool and pillars at the edges, soft holy light",
    "nanzhao_palace": "a royal courtyard of red ochre stone tiles, Miao totem pillars and bronze drums at the edges",
}


def battle_jobs() -> list[dict]:
    return [
        {
            "out": f"source_art/battle/{sid}.png",
            "prompt": f"{desc}, {GROUND}.",
            "width": 1600,
            "height": 896,
            "publish": {"path": f"public/assets/battle/{sid}.jpg", "width": 1600, "height": 896, "quality": 85},
        }
        for sid, desc in BATTLE.items()
    ]


def story_jobs() -> list[dict]:
    return [
        {
            "out": f"source_art/story/{sid}.png",
            "prompt": f"{desc}. {SCENE}.",
            "width": 1536,
            "height": 864,
            "publish": {"path": f"public/assets/story/{sid}.jpg", "width": 1536, "height": 864, "quality": 84},
        }
        for sid, desc in STORY.items()
    ]


def map_jobs() -> list[dict]:
    return [
        {
            "out": f"source_art/maps/{cid}.png",
            "prompt": f"{desc}. {MAP}.",
            "width": 1536,
            "height": 864,
            "publish": {"path": f"public/assets/maps/{cid}.jpg", "width": 1536, "height": 864, "quality": 84},
        }
        for cid, desc in MAPS.items()
    ]


def main() -> None:
    out = {"standees": standee_jobs(), "enemies": enemy_jobs(), "portraits": portrait_jobs(), "story": story_jobs(), "maps": map_jobs(), "battle": battle_jobs()}
    (HERE / "prompts" / "assets.json").write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print({k: len(v) for k, v in out.items()})


if __name__ == "__main__":
    main()
