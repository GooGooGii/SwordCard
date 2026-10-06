# 素材與工具授權帳本（REDESIGN §9.2）

> 本作是《仙劍奇俠傳》（大宇資訊）的**私人同人作品**：不公開散佈、不營利；分享網址要加存取控制與 noindex。
> 角色、地名、招式名、劇情事件屬原著；台詞全部重寫，沒有使用原作的圖、音樂與文字檔。

## 美術（AI 生成，本機執行）
| 項目 | 用途 | 授權／條款 | 備註 |
|---|---|---|---|
| Z-Image Turbo（ComfyUI，nvfp4 權重） | 卡圖、敵人與角色立繪、頭像、劇情背景、章節地圖 | 依模型發布頁的授權（**待查證確切條款**） | 本機出圖；提示詞在 `tools/art/` |
| Qwen3 4B（文字編碼器） | Z-Image 的提示詞編碼 | 依模型發布頁（**待查證**） | |
| Hunyuan3D-2mv | 李逍遙、趙靈兒等 3D 模型 | 騰訊混元 3D 2.0 社群授權 | 只在本機（私有）使用 |
| rembg（BiRefNet-general） | 立繪去背 | rembg：MIT；BiRefNet：MIT | |
| Blender | 3D 後製、綁骨、動作 | GPL（工具本身；產出的模型不受 GPL 約束） | |

## 字型（自帶、依用到的字裁切）
| 字型 | 用途 | 授權 |
|---|---|---|
| 霞鶩文楷 TC（LXGW WenKai TC） | 標題、卡名 | SIL Open Font License 1.1 |
| Noto Serif TC | 內文 | SIL Open Font License 1.1 |

兩者都透過 `@fontsource` 套件取得，裁切由 `tools/fonts.mjs`、`tools/subset_fonts.py`（fontTools）完成；OFL 允許修改與一起散佈。

## 音樂與音效
全部用 WebAudio 即時合成（`src/platform/`），五聲音階的旋律由程式依固定種子產生，沒有使用任何既有樂曲或音檔。

## 程式庫（執行時）
| 套件 | 授權 |
|---|---|
| React、React DOM | MIT |
| three.js | MIT |
| @react-three/fiber、@react-three/drei、@react-three/postprocessing | MIT |
| postprocessing | Zlib |
| zod | MIT |
| Capacitor（core、android、app） | MIT |

開發工具（Vite、Vitest、TypeScript、Playwright、fontTools）只在開發時使用，不隨遊戲散佈。
