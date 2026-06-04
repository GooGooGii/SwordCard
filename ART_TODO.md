# 卡圖待補清單

最後更新：2026-06-04（八幕擴充：新增 3 張戰鬥背景與 3 個 boss 肖像待補，見「六、八幕擴充美術」）

---

## 一、共用佔位圖（21 張） —— 🟢 已全部完成

以下 21 張卡原本共用相同的佔位圖，現已全部繪製並補齊獨立的專屬美術圖檔，經檢測已無任何佔位圖情況。

### 🟢 李逍遙（5 張）- 已完成
- `lxy_jianzhen` (劍陣 - 已補專屬水墨圖)
- `lxy_jiulong` (九龍訣 - 已補專屬水墨圖)
- `lxy_liepo` (裂魄斬 - 已補專屬水墨圖)
- `lxy_qingfeng` (清風御劍 - 已補專屬水墨圖)
- `lxy_zuilong` (醉龍翻江 - 已補專屬水墨圖)

### 🟢 趙靈兒（5 張）- 已完成
- `zl_huihun` (還魂咒 - 已補專屬水墨圖)
- `zl_leiguang` (雷光連擊 - 已補專屬水墨圖)
- `zl_lingxi` (靈息術 - 已補專屬水墨圖)
- `zl_shenlei` (神雷降世 - 已補專屬水墨圖)
- `zl_shuiling` (水靈護罩 - 已補專屬水墨圖)

### 🟢 林月如（5 張）- 已完成
- `lyr_kuaijian` (輕劍急刺 - 已補專屬水墨圖)
- `lyr_poqian` (破千謀 - 已補專屬水墨圖)
- `lyr_tianv` (飛花亂舞 - 已補專屬水墨圖)
- `lyr_tieyi` (鐵衣功 - 已補專屬水墨圖)
- `lyr_xuanjian` (旋劍花舞 - 已補專屬水墨圖)

### 🟢 阿奴（6 張）- 已完成
- `anu_baizu` (百足蠱 - 已補專屬水墨圖)
- `anu_baozhagu` (爆炸蠱 - 已補專屬水墨圖)
- `anu_duzhen` (毒針連射 - 已補專屬水墨圖)
- `anu_gushen` (蠱神附體 - 已補專屬水墨圖)
- `anu_guwang` (蠱王號令 - 已補專屬水墨圖)
- `anu_sanmao` (三毛蠱 - 已補專屬水墨圖)

---

## 二、詛咒牌（6 張） —— 🟢 已全部完成

遊戲中的特殊卡牌 `card_type="curse"`，已於 2026-06-01 生成去背水墨圖檔，並完成 Godot `.import` 配置及 smoke test 存在性斷言保護。
- `yao_zhai` (妖債)
- `xie_yin` (邪印)
- `tong_ji` (通緝)
- `hua_zhai` (花債)
- `jiu_zui` (醉魂)
- `gu_du` (殘蠱)

---

## 三、跨角色共用圖（待確認或待清理）

以下兩張卡 PNG 內容完全一樣，但兩張卡都有各自的定義。
若設計上本來就要共用同一張圖，請在 `game_data.gd` 的 `zl_bingxin` 加上 `art_id="lxy_bingxin"` 明確標示；
若兩個角色應有各自的圖，則 `zl_bingxin` 需補新圖。

| ID | 招式名 | 角色 |
|---|---|---|
| `lxy_bingxin` | 冰心訣 | 李逍遙 |
| `zl_bingxin` | 冰心訣 | 趙靈兒 |

---

### 🟢 待重製：卡圖含文字（2026-06 全卡盤點，共 18 張） —— 🟢 已全部完成

卡圖原則「**不要出現文字**」（標題／英文／浮水印／數值框／水墨題跋落款）。
例外：**符咒（符／法陣）上的符文字保留**（如 `lxy_tianshi` 天師符、`zl_shuiyin` 法陣）。
下列卡圖已全部於 2026-06-02 重製，去除了文字、卡框、浮水印等內容：

**A. 烤進卡圖的卡框／標題／英文／浮水印／數值**
| ID | 問題 | 狀態 |
|---|---|---|
| `zl_huihun` | 「迴魂咒 (Huihun Zhen)」+ 英文 + 整張卡框與說明 | 🟢 已重製 |
| `zl_leiguang` | 「紫金雷霆術」+「ATK 8 HP 4」數值框 + 卡框 | 🟢 已重製 |
| `lyr_tieyi` | 「鐵衣功 / Tieyi Gong」+ 英文敘述 + 底部版權浮水印 | 🟢 已重製 |
| `zl_bingxin` | 「清心咒」+「SR」稀有度標 + 卡框 | 🟢 已重製 |
| `zl_lingxi` | 「靈犀」+ 卡框 + 說明文字 | 🟢 已重製 |
| `zl_shenlei` | 「神雷」+ 裱框標題 | 🟢 已重製 |
| `zl_shuiling` | 「水靈盾／持寧」+ 紅色印章 | 🟢 已重製 |
| `lyr_xuanjian` | 「旋劍花舞」標題框 + 印章 | 🟢 已重製 |
| `zl_jingang` | 幡旗直書標題字（borderline，偏標題） | 🟢 已重製 |
| `tong_ji`（詛咒卡） | 裱框水墨 + 紅色落款印 | 🟢 已重製 |

**B. 水墨題跋／落款印章（畫上詩文題字、藝術家紅印，非符咒）**
| ID | 問題 | 狀態 |
|---|---|---|
| `anu_duwu` | 左上題字 | 🟢 已重製 |
| `anu_guwang` | 題字 + 紅印 | 🟢 已重製 |
| `anu_guxue` | 直書題字數行 | 🟢 已重製 |
| `anu_sanmao` | 左上題字 | 🟢 已重製 |
| `lyr_poqian` | 左下題字 | 🟢 已重製 |
| `lyr_tianv` | 左下題字 | 🟢 已重製 |
| `lyr_tongqianbiao` | 右上題字 | 🟢 已重製 |
| `lyr_qijuejianqi` | 右上角紅色落款印 | 🟢 已重製 (註) |

> 註：`lyr_qijuejianqi` 由於 AI 生成 quota 限制，暫以 `lyr_xuanjian` 的新繪水墨圖替代，皆為無落款印之純淨美術。

---

## 四、孤兒圖（有圖無卡，可清理或留待未來）

以下 PNG 存在於 `assets/art/cards/` 但目前 `game_data.gd` 沒有對應的卡牌定義。
不影響遊戲，可暫時保留（若未來會新增卡牌），或刪除清理。

| 孤兒圖檔 | 備註 |
|---|---|
| `anu_duohun` | 佔位圖 |
| `anu_sanshigu` | 與 `anu_wanyi` 同圖 |
| `anu_shuhun` | 與 `anu_jiedu` 同圖 |
| `anu_wangushitian` | 與 `anu_yufeng` 同圖 |
| `anu_wanyi_ls` | 佔位圖 |
| `anu_yanshazhou` | 佔位圖 |
| `lxy_jianshen` | 有圖 |
| `lxy_jinchan_ls` | 有圖 |
| `lxy_ningyuan_ls` | 有圖 |
| `lxy_tiangangqi` | 有圖 |
| `lxy_tianjian` | 有圖 |
| `lxy_xiaoyao_shenjian` | 有圖 |
| `lxy_yuanlinggui` | 有圖 |
| `lxy_zhenyuan` | 有圖 |
| `lyr_lielong` | 與 `lyr_zhanlong` 同圖 |
| `lyr_qijuejianqi` | 佔位圖 |
| `lyr_tongqianbiao` | 佔位圖 |
| `lyr_wanlikuang` | 佔位圖 |
| `lyr_yuanlinggui` | 與 `lyr_ningshen` 同圖 |
| `zl_bingzhou` | 與 `zl_fengxuebing` 同圖（兩者皆孤兒）|
| `zl_diliebeng` | 佔位圖 |
| `zl_fengxuebing` | 與 `zl_bingzhou` 同圖（兩者皆孤兒）|
| `zl_kuanglei` | 佔位圖 |
| `zl_mengshe_ls` | 與 `zl_mengshe` 同圖 |
| `zl_sanmeizhenhuo` | 與 `zl_yanzhou` 同圖 |
| `zl_taishan` | 與 `zl_tianlei` 同圖 |
| `zl_wuleizhou` | 與 `zl_leizhou` 同圖 |
| `zl_xuanfengzhou` | 有圖 |

## 五、借圖待補與專屬卡圖進度（2026-06）

本項目旨在為 27 張原本暫時「借圖（`art_id`）」的卡牌補齊專屬插畫。目前已完成全部 27 張卡牌，已無借圖情況。

### 🟢 已完成專屬卡圖（27 張）
- **李逍遙（4 張，御劍連擊）**：
  - `lxy_jianjue` (劍訣) - 🟢 已完成專屬水墨圖
  - `lxy_huijian` (揮劍引氣) - 🟢 已完成專屬水墨圖
  - `lxy_yufengbu` (御風步) - 🟢 已完成專屬水墨圖
  - `lxy_lianhuanjian` (連環御劍) - 🟢 已完成專屬水墨圖
- **趙靈兒（4 張，連咒）**：
  - `zl_xiaoleizhou` (小雷咒) - 🟢 已完成專屬水墨圖
  - `zl_yinlingfu` (引靈符) - 🟢 已完成專屬水墨圖
  - `zl_huguangzhou` (護光咒) - 🟢 已完成專屬水墨圖
  - `zl_lianzhuzhou` (連珠雷咒) - 🟢 已完成專屬水墨圖
- **林月如（4 張，鞭劍連擊）**：
  - `lyr_jici` (急刺) - 🟢 已完成專屬水墨圖
  - `lyr_huaci` (花刺引身) - 🟢 已完成專屬水墨圖
  - `lyr_qiebushan` (怯步閃) - 🟢 已完成專屬水墨圖
  - `lyr_shuangjianci` (雙劍連刺) - 🟢 已完成專屬水墨圖
- **阿奴（5 張，蠱毒連擊 + 毒引擎）**：
  - `anu_sandu` (散蠱) - 🟢 已完成專屬水墨圖
  - `anu_yindu` (引蠱) - 🟢 已完成專屬水墨圖
  - `anu_huguzhao` (護蠱罩) - 🟢 已完成專屬水墨圖
  - `anu_lianduzhen` (連環毒針) - 🟢 已完成專屬水墨圖
  - `anu_guzhang` (蠱瘴瀰漫) - 🟢 已完成專屬水墨圖
- **無門派/Colorless（10 張，共同牌）**：
  - `cl_xunjiezhan` (迅捷斬) - 🟢 已完成專屬水墨圖
  - `cl_hanfengjue` (寒鋒訣) - 🟢 已完成專屬水墨圖
  - `cl_hushenjue` (護身訣) - 🟢 已完成專屬水墨圖
  - `cl_qiaojin` (巧勁) - 🟢 已完成專屬水墨圖
  - `cl_zhimingfu` (致盲符) - 🟢 已完成專屬水墨圖
  - `cl_poshi` (破式) - 🟢 已完成專屬水墨圖
  - `cl_jinchuangtie` (金創藥帖) - 🟢 已完成專屬水墨圖
  - `cl_qimendunjia` (奇門遁甲) - 🟢 已完成專屬水墨圖
  - `cl_yunchou` (運籌帷幄) - 🟢 已完成專屬水墨圖
  - `cl_huacaijianyi` (華彩劍意) - 🟢 已完成專屬水墨圖

### 🔴 借圖待補（0 張）
已全部完成。

---

## 六、八幕擴充美術（2026-06，🔴 待補）

五幕擴充為八幕（依 PAL1 正史順序：餘杭 → 仙靈島 → 蘇州 → 將軍塚 → 試煉窟 → 鎖妖塔 → 苗疆 → 拜月）。
既有 5 張背景已重新對應到正確幕號，**3 個新場景缺專屬戰鬥背景**，目前 fallback 通用底 `battle_bg.png`。

### A. 戰鬥背景（3 張）🔴
| 檔名 | 場景 | 風格建議 | 狀態 |
|---|---|---|---|
| `assets/art/battle_bg_act_2.png` | 仙靈島 / 水月宮 | 雲霧繚繞的水中仙島、宮闕倒影、靈氣氤氳，水墨青碧調 | 🔴 待補（暫用通用底）|
| `assets/art/battle_bg_act_4.png` | 將軍塚 | 荒塚石碑、陰風殘旗、磷火幽光，蕭瑟灰褐調 | 🔴 待補（暫用通用底）|
| `assets/art/battle_bg_act_5.png` | 試煉窟 | 地底洞窟、五靈法陣石壁、幽光石筍，神秘幽藍調 | 🔴 待補（暫用通用底）|

> 既有背景對應：act1 餘杭 / act3 蘇州 / act6 鎖妖塔 / act7 苗疆 / act8 拜月（皆有專屬美術）。
> 補圖後執行 `godot --headless --path . --import` 重匯入即生效，程式已 `clamp(act, 1, 8)`。

### B. 新 Boss 肖像（3 個，1 已完成，2 待補）🟡
新增 3 個 boss 肖像（按 `portrait_path` 路徑新增即生效）：

| Boss ID | 顯示名 | 目前借用/狀態 | 風格建議 |
|---|---|---|---|
| `water_serpent` | 水靈蛇妖（仙靈島 boss）| `serpent_demon.png` | 青碧水靈巨蛇，靈島水族妖氣，呼應趙靈兒人蛇主題 |
| `tomb_general` | 塚中亡將（將軍塚 boss）| `ancient_evil_spirit.png` | 殘甲執戈的亡將魂魄，陰森戰魂氣息 |
| `zhenyu_mingwang` | 鎮獄明王（鎖妖塔 boss・正史）| 🟢 已完成（專屬美術） | 金剛怒目的鎮獄明王法相，鎖鏈降魔杵，莊嚴而威壓 |

### C. 新增 PAL1 小怪肖像（7 個）🟢 已全部完成
八幕擴充為各幕補充的 PAL1 風格小怪，已全部補齊獨立的專屬水墨肖像（`assets/art/enemies/<id>.png`）：

| 敵人 ID | 顯示名 | 出沒幕 | 狀態 | PAL1 出處 / 說明 |
|---|---|---|---|---|
| `wild_bee` | 十里坡野蜂 | 1 餘杭山間 | 🟢 已完成（專屬美術） | PAL1 十里坡名怪「蜜蜂」；成群黃黑野蜂，輕快靈動 |
| `cave_bat` | 噬血蝠 | 2 仙靈島 | 🟢 已完成（專屬美術） | 仙靈島洞窟蝙蝠；張翼噬血、幽暗洞穴感 |
| `water_imp` | 靈島水妖 | 2 仙靈島 | 🟢 已完成（專屬美術) | 仙靈島水族小妖；半透明水靈、青碧水氣 |
| `skeleton_soldier` | 塚中骷髏兵 | 4 將軍塚 | 🟢 已完成（專屬美術） | PAL1 經典不死系；殘甲白骨、執鏽刀 |
| `grave_fire` | 塚中鬼火 | 4 將軍塚 | 🟢 已完成（專屬美術） | PAL1「鬼火」；飄忽幽綠磷火、無實體 |
| `rock_guardian` | 試煉石靈 | 5 試煉窟 | 🟢 已完成（專屬美術） | PAL1「石頭怪」；岩石巨軀、厚重護甲感 |
| `trial_swordshade` | 試煉劍靈 | 5 試煉窟 | 🟢 已完成（專屬美術） | 試煉窟守護劍意；半透明御劍虛影 |

---

## 補圖規格

- 格式：PNG，存於 `assets/art/cards/<id>.png`（卡圖）或 `assets/art/<檔名>.png`（背景）
- 完成後補 `.import` 配置（`godot --headless --path . --import`）
