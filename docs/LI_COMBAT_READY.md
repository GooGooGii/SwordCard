# 李逍遙備戰姿勢 — CHARACTER-009

2026-10-05，Codex。使用者指出 D 模型在戰鬥時站太挺。原先 idle 僅是直立放手＋呼吸，並未製作備戰站姿；這輪保留 D 造型與正常比例，只重做骨架動作與交接。

## 改動

- 正式模型改為 `public/assets/characters/li_xiaoyao_style_d_ready_v2.glb`，舊版本保留，新 URL 避免快取。
- idle 重心下移約 11 cm、雙膝彎曲、前後错步約 37 cm，右手持劍前向戒備、左手抬起護身。呼吸保持腳位，沒有每輪站回直立。
- 使用兩段腿骨長度計算膝蓋方向，將雙腳踝固定在距地約 9.6 cm，鞋底接近地面；不是把整個模型簡單下移。
- attack 0.60 秒、hit 0.43 秒；所有動作從 ready 開始並回到 ready。保持既有正式 UI 動作切換時間與淡入淡出，不更改卡牌規則。
- 首版銜接驗證抓到 NLA 先前動作影響下一段動作編寫，root offset 被再次套用，攻擊／受擊起始會下沉。`build_actions` 編寫姿勢時停用 NLA／暫時卸下 active action，再插入獨立 clip 的 keyframes，解決重複位移。這是重建工具修正，未重新匯出其他角色。

## 證據

- [原本直立](previews/characters/li-style-d-v4/browser/li_xiaoyao-front45.png) → [新備戰姿勢](previews/characters/li-style-d-ready-v2/browser/li_xiaoyao-front45.png)。
- [正式桌機戰場](previews/characters/li-style-d-ready-v2/production/yueru-desktop.png)、[手機橫向](previews/characters/li-style-d-ready-v2/production/anu-wuhou-mobile.png)。
- [模型報告](previews/characters/li-style-d-ready-v2/browser/validation.json)：六方向＋十五個 idle/attack/hit 時點、14,194 triangles／20 bones／2048² 貼圖；0 browser errors／failed requests。
- QA 使用 `CHARACTER_QA_COMBAT_READY=1` 額外驗證雙膝彎曲（內角 90–165°）、腳踝距地、idle 腳位漂移、錯步深度與雙手抬起；attack/hit 首尾關節與 ready 的距離不超過 2.5 cm。閾值僅適用這名 1.75m 李逍遙 rig，其他角色需各自訂定。
- [正式報告](previews/characters/li-style-d-ready-v2/production/validation.json)：四張桌機／手機橫向、八張手牌／三張藥品／六遺物正式 HUD 效果，0 errors／HUD overflow。
- `npm run build` 通過，`npm test` 117 passed／1 skipped。手機仍是 Chromium 模擬，實體手機與使用者姿勢美術回饋待驗收。

## 範圍與交接

李逍遙備戰修正製作與上線 100%。[原私人網址](https://xiaoyao-private-play.googoo00166.chatgpt.site) 部署 `appgdep_6ac3a30700848191aed10c6ba9103466` succeeded；Sites source SHA `72df966f3df409cf8f0bdd5f99fb34ce687e4607`，版本 `appgprj_6ac335e5df98819185fb2d64d85bfff3~appgver_b3a17140e1a081918216931d4784da25`。保留原私人存取設定。

本輪修正李逍遙。其他四名角色仍是既有模型，尚未統一 D 或備戰動作；依 CHARACTER-004／005 後續重製，不能把本輪一名交付算成全隊完成。衣帶細小貼圖／蒙皮仍有簡化瑕疵，未宣稱完美還原。
