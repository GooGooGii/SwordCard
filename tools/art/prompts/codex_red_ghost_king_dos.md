# ART-001B — 赤鬼王 DOS 原作重繪

2026-10-05，Codex；內建 imagegen，透明背景。使用者已確認原作參照並指示「按原作繪製，不像就再重繪」。

參照：`docs/art-references/blood-pool-dos-battle.png`；已實際查看 DOS Boss 戰並展示來源，詳見 `docs/art-references/red_ghost_king.md`。

候選保存在 `public/assets/enemies/candidates/red_ghost_king_dos_v2.webp`，正式 `red_ghost_king.webp` 等候選實機驗收後再處理。原始 PNG 存 `source_art/enemies/codex/`（沿用大型原圖忽略規則）。WebP 只做無損格式編碼，保留相同尺寸與所有 RGBA 像素，未裁切、縮放或手動改圖。

## v1 最終提示詞

```text
Use case: stylized-concept / identity-preserving high-resolution redraw.
Asset type: a single transparent 2D enemy standee for a Three.js PAL1 fan game.
Reference image 1 is a PAL1 DOS gameplay screenshot. Redraw ONLY the large human-shaped Red Ghost King (赤鬼王) at the LEFT of that screenshot, preserving his actual DOS silhouette, clothing, colors, facing and crouched posture with exceptional fidelity. The three small heroes on the right, water, terrain, and UI are reference context only and must be omitted.

Subject and invariants: a pale sallow middle-aged East Asian man's face in three-quarter view looking toward screen-right, arched black brows, narrow stern eyes, black moustache and short pointed black beard; no animal or monster facial redesign. A very tall soft charcoal-black cap leans slightly backward to the upper left, with a narrow muted golden-yellow band framing the forehead and one small golden band across the upper part; this is a simple cloth cap, NOT a crown, not a hat with wings. A voluminous dark umber/charcoal robe with very large rounded sleeves, a grey inner crossed collar and narrow faded dark-red piping along the robe opening, a flat dark sash at the waist. Preserve the original simple cloth layers and folds; no fantasy armor, jewelry or invented decorative gold embroidery.
Pose: match the screenshot's broad, compact crouched/kneeling stance: left silhouette elbow extended out to the left under a big rounded sleeve, left-side fist resting at the waist; opposite arm held low near the front thigh. Torso leans slightly forward, face turned right. The robe gathers in broad folds around the bent knee at lower right. The lower robe terminates in the compact uneven hem visible above the blood vortex; DO NOT invent standing legs, boots or extra exposed skin. The tall hat, human face, wide sleeves, and compact draped knee must remain readily recognizable from the DOS sprite.

Style: faithful high-definition redraw of the original 1995 DOS sprite in restrained Chinese painterly game art, visible subtle brush strokes, clear small-scale silhouette and face, grounded cloth textures, soft warm illumination from upper left. Do not modernize, beautify into a young idol, or turn him into a generic sorcerer or demon. Maintain original grey/black/umber, muted gold and narrow dark red palette.
Composition: one single complete character cutout, large centered in a portrait image with a little transparent margin around every edge. Hat and the full visible robe hem both intact, no cropping. Match the original three-quarter right-facing view, not a frontal portrait. Entire background must have real transparency. No water, no pool, no scenery, no ground shadow, no smoke, no flames, no golden platform, no glow ring baked into the character; the existing 3D scene supplies the vortex. No other characters, no text or watermark. Specifically NO horns, NO fangs, NO wings, NO muscular naked demon, NO armor, NO staff, NO weapon, NO modern anime costume.
```

## v2 — 單一細節修正

v1 多出原作參照無法確認的黑色眉心記號，因此未採用；用內建 imagegen 移除，保留帽、服裝、姿態與透明背景。v2 參照為 v1 原圖與同一張 DOS 遊戲圖。

```text
Use case: precise-object-edit, faithful PAL1 DOS Red Ghost King cutout.
Image 1 is the edit target: our transparent high-definition redraw. Image 2 is the already approved PAL1 DOS gameplay identity reference; only the large character at left matters.
Make ONE narrowly targeted correction to Image 1: completely remove the black teardrop-shaped mark on the middle of his forehead, replacing it with natural unmarked pale sallow skin and the same painterly shading. Do not add a third eye, emblem, jewelry or markings.
Preserve absolutely everything else in Image 1: the face identity, moustache and pointed beard, stern right-facing gaze, tilted tall dark cap with muted gold bands, cap shape and height, big dark brown sleeves, grey crossed collar and narrow red piping, dark sash, hands, compact kneeling robe silhouette and cloth folds, exact composition and transparent background. Keep the entire hat and robe hem intact. This is a local correction, not a new character design. No horns, fangs, naked muscles, weapons, scenery, pool, shadows or extra effects. Output one clean standee on real transparency.
```
