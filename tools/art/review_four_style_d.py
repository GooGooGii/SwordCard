"""Create QA contact sheets; generated artwork is never repainted/overwritten."""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/previews/characters/four-style-d-v1'
OUT.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/msjh.ttc', 23)
small = ImageFont.truetype('C:/Windows/Fonts/msjh.ttc', 17)
records = [
    ('zhao_linger', '趙靈兒', 94, ['雙髮束與細藍帶', '白立領、白袖、深藍胸片', '藍紫長裙與正常比例'],
     'docs/art-references/story-portraits/linger-dos-ending.png',
     'https://pimg.1px.tw/gi780602/1597030303-3036141762-g.png'),
    ('lin_yueru', '林月如', 94, ['低束髮、左肩髮束、英氣臉型', '紫白勁裝、深色領邊', '短衣長褲、金褐腰帶'],
     'docs/art-references/story-portraits/dos-cast.jpg',
     'https://pimg.1px.tw/gi780602/1597030217-931464320-g.jpg'),
    ('anu', '阿奴', 95, ['綠帽、紅褐帶、雙羽飾', '黑辮與綠白上衣', '紅褐短裝、赤足輪廓'],
     'docs/art-references/characters/anu-dos-ending.jpg',
     'https://fairysword.dearchibi.com/wp-content/uploads/2010/04/pal03.jpg'),
    ('wuhou', '巫后', 93, ['黑色盤髮與成熟氣質', '紅袍、金褐滾邊、淺色內領', '長袍輪廓；綠杖頭另做'],
     'docs/art-references/characters/wuhou-dos-reveal.webp',
     'https://codingman.cc/images/pal-dos-walkthrough/ch8-08-wuhou-reveal.webp'),
]
board = Image.new('RGB', (1600, 1120), '#eeeae2')
d = ImageDraw.Draw(board)
d.text((28, 12), 'STYLE D｜原作特徵比對 → 四角色 2D 建模來源', font=font, fill='#222222')
d.text((28, 45), '百分比為人工視覺評估；未量測像素相似度。背面／不可見細節為重建推測。', font=small, fill='#555555')
manifest = {'date': '2026-10-06', 'generator': 'built-in imagegen',
    'approval': 'User authorized autonomous 2D generation then >90% visual review before 3D',
    'score_kind': 'subjective assessment of visible original identity features; not a measured similarity metric',
    'style_memory': {'source': 'source_art/characters/li_xiaoyao/sheet_style_d_v2.png',
        'render_mode': 'mixed', 'ground': 'neutral-gray', 'alpha': True,
        'identity': 'STYLE D, normal 7–7.5-head proportions, matte simplified hand-painted game material',
        'avoid': ['chibi', 'big head/short limbs', 'generic xianxia costume', 'rejected doll_v2/v3']},
    'characters': []}
for i, (cid, name, score, features, ref, url) in enumerate(records):
    x = i * 400
    sheet_version = 'v2' if cid == 'lin_yueru' else 'v1'
    sheet_path = f'source_art/characters/{cid}/sheet_style_d_{sheet_version}.png'
    sheet = Image.open(ROOT / sheet_path).convert('RGBA')
    front = sheet.crop((0, 0, sheet.width // 2, sheet.height // 2))
    box = front.getchannel('A').getbbox()
    front = front.crop(box)
    front.thumbnail((345, 595), Image.Resampling.LANCZOS)
    board.paste(front, (x + (400-front.width)//2, 112), front)
    d.text((x+22, 78), f'{name}｜主觀 {score}%', font=font, fill='#222222')
    original = Image.open(ROOT / ref).convert('RGB')
    if cid == 'lin_yueru':
        original = original.crop((original.width//2, original.height//2, original.width, original.height))
    original.thumbnail((340, 175), Image.Resampling.NEAREST)
    board.paste(original, (x+(400-original.width)//2, 734))
    d.text((x+22, 708), 'PAL1 DOS 原作參照', font=small, fill='#555555')
    for j, feature in enumerate(features):
        d.text((x+22, 931+j*30), feature, font=small, fill='#222222')
    d.text((x+22, 1040), '2D 通過；3D 仍需多面／動作驗收', font=small, fill='#555555')
    manifest['characters'].append({'id': cid, 'name': name, 'assessment_percent': score,
        'visible_features': features, 'source': url, 'version': 'PAL1 DOS',
        'sheet': sheet_path,
        'revision': 'v1 high bun rejected at detailed review; v2 low gathered hair replaces it' if cid == 'lin_yueru' else 'first sheet',
        'unverified': 'back structure, exact facial geometry, fine clothing details outside original view',
        'mesh_seed': 10672 if cid == 'lin_yueru' else 10661+i, 'mesh_steps': 5, 'mesh_octree': 320})
board.save(OUT / 'reference-comparison.jpg', quality=93)
(OUT / 'visual-review.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(OUT / 'reference-comparison.jpg')

# This board is made only from actual browser GLB captures, never concept art.
browser = ROOT / 'docs/previews/characters/four-style-d-final/browser'
if all((browser / f'{r[0]}-front45.png').exists() for r in records):
    model_board = Image.new('RGB', (1600, 650), '#211c18')
    md = ImageDraw.Draw(model_board)
    md.text((28, 16), 'STYLE D｜四角色真正 3D 模型・Three.js 實際畫面', font=font, fill='#eeeae2')
    for i, (cid, name, *_rest) in enumerate(records):
        snap = Image.open(browser / f'{cid}-front45.png').convert('RGB')
        snap = snap.crop((140, 85, 580, 665)).resize((400, 528), Image.Resampling.LANCZOS)
        model_board.paste(snap, (i*400, 73))
        md.text((i*400+26, 605), name, font=font, fill='#eeeae2')
    model_board.save(browser.parent / 'models-overview.jpg', quality=94)
    print(browser.parent / 'models-overview.jpg')
