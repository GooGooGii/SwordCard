# Playable character 3D delivery

> 2026-10-05 使用者美術驗收未通過：主角群風格詭異、與原作差距過大。5/5 與以下 100% 僅是技術交付紀錄，不能作為造型還原通過。來源風格不一致、投影／蒙皮邊緣與戰場辨識問題見 [復核文件](CHARACTER_STYLE_REVIEW.md)。正式模型尚未替換，CHARACTER-003–006 待重製。

2026-10-05, Codex. All five playable characters now have animated GLBs (5/5, 100% implementation): existing Li Xiaoyao / Zhao Linger, plus this delivery Lin Yueru / Anu / Wuhou. The first playable web version is the acceptance target; user visual fine-tuning and physical phone performance remain separate.

| lin_yueru | 14,140 | 20 | 2048² × 1 | idle / attack / hit |
| anu | 14,164 | 20 | 2048² × 1 | idle / attack / hit |
| wuhou | 14,058 | 20 | 2048² × 1 | idle / attack / hit |

Budgets include weapon geometry. Each GLB is approximately 1.5 MB, with Y-up and front +Z. The stage keeps its existing PAL1 camera, formation, target boxes, entry motions and animation API. No battle rules or chapter progression changed. Existing partyStyle=3d selects these models automatically; the 2D option is preserved.

PAL1 originals were viewed before generation: [sources and retained costume features](art-references/characters/README.md). The latest user authorization permits autonomous generation and integration after visual comparison; similarity is subjective, not a measured score. Lin uses a purple martial tunic and slim sword, Anu a small cap / green top / burgundy skirt / knife, Wuhou a red robe / gold trim / green-headed staff. Existing 2D first-pass artwork is retained for the optional fallback and can be visually harmonized following user playtest.

Four-view source sheets are unchanged. import_turnaround.py extracts projection inputs; the shared Hunyuan3D MV turbo queue produces meshes. Blender cleans and reduces the surface, bakes one texture, adds a humanoid rig and three clips. pal_weights.py excludes hands and hanging sleeves while removing arm influence from central lower garments. pal_weapons.py supplies pointed swords, a curved knife and a jade-headed staff. Existing Li/Zhao model files were not rebuilt. Config outputs remain isolated candidates in source_art/characters/<id>/raw_candidate_pal1_v1.glb; after acceptance they are copied to public/assets/characters/<id>.glb.

Verification:

- npm run build and 112 tests passed (1 skipped).
- [Browser model report](previews/characters/browser/validation.json): 3 models, 18 six-view captures, 24 attack/hit frames, valid finite animated bounds, all asset budgets and clips passed, 0 browser errors / failed requests. Actual images were reviewed.
- [Production UI report](previews/characters/release/validation.json): 4 desktop / mobile-landscape captures, 3 party members, 3 medicine cards, 6 relics, 8 hand cards, 0 browser errors / HUD overflow; final GLBs loaded from the production build without candidate routing.
- [Mobile flow](previews/characters/mobile-flow/validation.json): touch new story, map, battle, reload, clipboard export, clean-context import and invalid import rejection; 9 checks passed.
- Mobile captures are Chromium viewport/touch simulations, not physical Android/iPhone GPU tests.

The formal App.tsx implementation written by Claude was reviewed and integrated under RELEASE-001, including Codex's empty-device save-import fix; no previous Claude source content was discarded. The CLI remains unavailable due to expired OAuth, so this delivery was implemented and verified by Codex.
