# PAL1 playable character model references

2026-10-05, Codex. User authorized autonomous completion and self-review on this date; no extra per-image confirmation is required. These originals were actually viewed before generating the sheets. The resemblance assessment is visual judgment, not a measured 90% score.

| Character | Original reference / version | Features retained |
|---|---|---|
| 林月如 | [PAL1 DOS battle](https://codingman.cc/images/pal-dos-walkthrough/ch2-07-contest-battle-start.webp), local ../all-scenes/lin_arena.webp; [Softstar official sword figurine](https://www.softstar.net.cn/Uploads/Editor/2017-12-08/5a2a37cb810b4.jpg), [official article](https://www.softstar.net.cn/index.php?s=/Wap/Article/detail/id/269.html) | Purple split martial tunic, ivory sleeves/trousers, gold sash, black half-up hair, slim straight sword. Official figure refines small sprite details. |
| 阿奴 | [PAL1 DOS ending](https://fairysword.dearchibi.com/wp-content/uploads/2010/04/pal03.jpg), [version source](https://fairysword.dearchibi.com/xian-jian-qi-xia-zhuan-pal-game-downloads); DOS battle ../all-scenes/nuwa_temple.webp | Small green cap with red band and white feathers, dark braids, jade/ochre top, burgundy lower garment, bare feet, small curved knife. |
| 巫后 | [PAL1 DOS reveal](https://codingman.cc/images/pal-dos-walkthrough/ch8-08-wuhou-reveal.webp); [DOS water battle](https://codingman.cc/images/pal-dos-walkthrough/ch8-09-shuimoshou-battle.webp), local ../all-scenes/water_maze.webp | Dominant red outer robe, gold edging, pale inner garment, compact black hair bun, green-headed staff. |

The existing game standees supplied facial identity and painterly texture style only. Their different costume palettes did not override PAL1 references. Four-view sheets were generated with the imagegen skill and stored unchanged under source_art/characters/<id>/sheet_pal1_v1.png. The extraction tool prepares projection views for mesh conversion. Hunyuan3D MV turbo generates the base mesh; Blender cleans, reduces, projects textures, rigs and exports animated glTF.

Candidates use source_art/characters/<id>/raw_candidate_pal1_v1.glb before game integration. Browser six-view and animation captures are in docs/previews/characters/browser; the final formal-game screenshots include three medicine cards and six relics. User fine-tuning follows the completed first playable delivery.
