"""電影感 CG 造型的單一來源（2026-10-06 使用者定的新美術方向，參考 docs/art-references/aaa-fan-video/ 與阿奴公仔）。
劇情頭像、戰鬥立繪、卡圖都從這裡取角色描述，讓同一個角色在各處是同一張臉、同一套衣服。

年齡與外觀以 PAL1 正史為準：主角是青年／少女，長輩要有年紀（皺紋、白髮），不要每個人都畫成漂亮年輕人。
"""

STYLE = (
    "3D CG character render from a next-gen 3A Chinese wuxia game cinematic, Unreal Engine 5 MetaHuman quality, "
    "stylized idealized CG like a high-end game trailer, subsurface skin shading, realistic fabric textures with visible weave and stitching, "
    "natural soft key light from the left, East Asian features, normal realistic proportions. "
    "Not a real photograph, not cosplay, not anime, not cartoon, not chibi. No text, no watermark."
)

PORTRAIT = (
    "Waist-up portrait for a visual-novel dialogue scene, facing three-quarter toward the viewer's left, looking at the conversation partner, "
    "arms relaxed, head and full hair visible with space above the head, plain light grey studio background."
)

# id → 外觀（服裝特徵照使用者給的參考）
CAST: dict[str, str] = {
    "li_xiaoyao": (
        "Li Xiaoyao, handsome cheerful 19-year-old young man, a little cheeky. Black hair in a high ponytail tied with a white cloth band, loose bangs. "
        "Rough beige hand-woven hooded shawl-cape draped over both shoulders; dark charcoal grey cross-collar tunic with white inner collar; "
        "brown leather belt and a leather strap across the chest."
    ),
    "zhao_linger": (
        "Zhao Ling'er, gentle graceful 17-year-old young woman, pure and kind, beautiful. Black hair with two small round buns on top and long hair flowing down, "
        "long light-blue silk ribbons hanging from the buns. White cross-collar silk top with wide sleeves; royal blue high-waisted apron-style dress "
        "with a small white embroidered emblem on the chest."
    ),
    "lin_yueru": (
        "Lin Yueru, proud beautiful 18-year-old swordswoman of the Lin family of Suzhou, confident. Long black hair mostly down with a single long braid "
        "draped forward over her left shoulder, soft side bangs. Cream off-white short-sleeved cross-collar tunic, a dark plum-purple sash-robe draped "
        "diagonally across the chest from one shoulder, wide dark plum-purple waist belt with a small gold ornament. Sword hilt with red scabbard behind her back."
    ),
    "anu": (
        "A'nu, playful sweet 16-year-old White Miao tribe princess (slim teenage girl, not a child). Short cream-yellow cloth cap shaped like a short cylinder, "
        "a bit wider at the flat top, orange band around the bottom, small silver ornament at the front, two white fluffy fur tufts curling outward from the "
        "top left and right. Very long straight dark brown hair worn loose, side bangs. Large ornate silver Miao neck collar with hanging pendants; "
        "white short-sleeved blouse with orange-yellow sleeve cuffs; sleeveless green overdress with white zigzag trim and a wide green sash."
    ),
    # ── 配角 ──
    "aunt": (
        "Aunt Li (Li Dayang), Li Xiaoyao's aunt and innkeeper of a small Yuhang inn, a sturdy plump middle-aged woman clearly in her late forties, visible wrinkles and crow's feet, slightly sagging cheeks, sharp-tongued but kind, "
        "black hair with grey strands in a tight bun with a wooden hairpin, plain dark red cotton jacket with rolled sleeves, faded blue apron."
    ),
    "drunk": (
        "The Drunken Sword Immortal, a scruffy unshaven middle-aged swordsman about 45, bushy eyebrows, upturned moustache and chin beard, half-lidded amused eyes, "
        "messy hair under a blue-grey Taoist cap, loose blue-grey Taoist robe with white cross collar worn sloppily, a big wine gourd hanging at his side."
    ),
    "granny": (
        "Granny (Lao Lao), Zhao Ling'er's grandmother on Fairy Island, a kind dignified old woman about 70, wrinkled face, white hair in a neat bun with a jade pin, "
        "plain pale grey-blue layered robe, holding a wooden walking stick, serene."
    ),
    "miao_leader": (
        "The Black Miao raider leader, a fierce scarred man about 40 with East Asian features, black headwrap, dark indigo Black Miao tunic with red cross-stitch trim, "
        "silver earrings, leather armour pieces, curved blade, menacing sneer."
    ),
    "fat_miao": (
        "A fat Black Miao bully, a heavy-set man about 35 with East Asian features, round greedy face, black headwrap, dark indigo Miao jacket straining at the belly, "
        "silver chain, smug grin."
    ),
    "tang_yu": (
        "Tang Yu, earnest honest 18-year-old Shushan disciple, clean-cut face, black topknot, plain light blue disciple robe with white collar, sword at his back."
    ),
    "wuwang": (
        "The King of Nanzhao, a dignified kingly man about 50 with a neat black beard streaked grey, small simple gold crown on a topknot, plain deep red royal robe with gold trim at the collar, "
        "weary but noble expression."
    ),
    "lin_tiannan": (
        "Lin Tiannan, master of the Lin family martial clan of Suzhou and Yueru's father, a stern dignified man about 52, long black beard with grey, "
        "topknot with a silver crown, dark navy brocade robe, upright martial bearing."
    ),
    "liu_jinyuan": (
        "Liu Jinyuan, the newly crowned imperial top scholar, a refined pale gentle young man about 22, thin face, scholar's black gauze cap, "
        "elegant pale cyan scholar's robe, holding a folding fan, bookish."
    ),
    "caiyi": (
        "Caiyi, a butterfly spirit who became a human woman, gentle beautiful young woman about 22 with tender sad eyes, hair in a soft side bun with a butterfly hairpin, "
        "flowing pastel pink and lavender silk dress with faint butterfly-wing embroidery."
    ),
    "shi_zhanglao": (
        "Elder Shi, a sinister old Black Miao shaman about 65, gaunt wrinkled face, thin white goatee, black headwrap with silver pendants, "
        "dark layered robe with bone and silver charms, cold eyes."
    ),
    "sword_saint": (
        "The Sword Saint of Shushan, an ancient serene master about 80, long flowing white hair and long white beard, kind piercing eyes, "
        "white and pale grey Taoist robe, an aura of calm."
    ),
    "shenggu": (
        "Shenggu (the Holy Aunt), a mysterious Miao sorceress clearly in her late fifties, lined aged face with wrinkles, sharp knowing eyes, grey-streaked black hair under a black headwrap with silver ornaments, "
        "dark indigo robe with intricate silver embroidery, many silver bangles, solemn."
    ),
    "gai_luojiao": (
        "Gai Luojiao, a seductive dangerous Black Miao sorceress about 28, sly smile, black hair with silver Miao hair ornaments, "
        "dark purple Miao dress with silver trim and spider-web embroidery, heavy silver necklace."
    ),
    "baiyue": (
        "The Moon Worship Cult Leader, the main villain, a tall commanding handsome man about 40, cold arrogant eyes, long straight black hair loose to the waist, "
        "black and deep crimson priestly robe with silver crescent moon emblems, high collar."
    ),
    "ji_sanniang": (
        "Ji Sanniang, a bold charming female thief about 30, mischievous smile, black hair in a high bun with a red ribbon, "
        "fitted crimson night-thief outfit with black trim, dagger at her belt."
    ),
    "zhixiu": (
        "Master Zhixiu, an old Buddhist abbot about 70, shaven head with ordination marks, long white eyebrows, gentle wrinkled face, "
        "orange-red and brown kasaya robe, prayer beads."
    ),
    "villager": (
        "An ordinary Yuhang villager, a weathered middle-aged man about 45, kind tired face, short stubble, simple grey-brown cotton clothes, cloth headband."
    ),
}

# 劇本用到的表情（src/content/stories/lines.ts 的 Expr）
EXPRESSIONS: dict[str, str] = {
    "smile": "warm open smile, happy bright eyes",
    "angry": "angry frown, furrowed brows, gritted teeth, glaring",
    "surprise": "shocked surprised expression, wide eyes, mouth slightly open",
    "sad": "sad sorrowful expression, downcast eyes, brows raised in the middle, on the verge of tears",
    "resolve": "determined resolute expression, firm mouth, intense focused eyes",
}

MAIN = ("li_xiaoyao", "zhao_linger", "lin_yueru", "anu")


def portrait_prompt(cid: str, expression: str | None = None) -> str:
    face = f" Facial expression: {EXPRESSIONS[expression]}." if expression else " Calm natural expression."
    return f"{STYLE} {PORTRAIT} {CAST[cid]}{face}"
