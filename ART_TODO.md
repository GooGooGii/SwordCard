# 卡圖待補清單

最後更新：2026-06-07（PAL1 boss 正史對位校正：蛇妖男 / 殭屍王 / 赤鬼王 / 火麒麟 / 石長老，並補蛇妖男、狐妖女、赤鬼王、火麒麟、石長老新立繪）

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

本項目旨在為 28 張原本暫時「借圖（`art_id`）」的卡牌補齊專屬插畫。目前已完成全部 28 張卡牌，已無借圖情況。

### 🟢 已完成專屬卡圖（28 張）
- **李逍遙（5 張，御劍連擊與劍宗）**：
  - `lxy_jianjue` (劍訣) - 🟢 已完成專屬水墨圖
  - `lxy_huijian` (揮劍引氣) - 🟢 已完成專屬水墨圖
  - `lxy_yufengbu` (御風步) - 🟢 已完成專屬水墨圖
  - `lxy_lianhuanjian` (連環御劍) - 🟢 已完成專屬水墨圖
  - `lxy_qingyan_zhuying` (青煙竹影) - 🟢 已完成專屬水墨圖
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

### 🟢 已完成專屬卡圖（6 張，阿奴 鬼／冥／蝶 主題，2026-06-07）
苗巫邪術·厲鬼冥河與蝶毒群控系列，已補齊專屬水墨圖：
- `anu_guiling_zhuansheng` (鬼靈轉生) - 🟢 已完成
- `anu_minghe_yindu` (冥河引渡) - 🟢 已完成
- `anu_suoming_egui` (幽魂噬影，原名索命厲鬼) - 🟢 已完成
- `anu_youming_shigu` (幽冥蝕骨) - 🟢 已完成
- `anu_guihuo_liaoyuan` (鬼火燎原) - 🟢 已完成
- `anu_huadie_guimeng` (化蝶歸夢) - 🟢 已完成

建議風格：青幽鬼火、冥河亡魂、厲鬼索命、群蝶化夢等氛圍，與既有水墨一致。

### 🟢 借圖待補（0 張）
目前所有卡牌的專屬美術皆已補齊，無借圖與佔位圖情況。

---

## 六、八幕擴充美術（2026-06，🟡 Boss phase 2 尚未全數補齊）

五幕擴充為八幕（依 PAL1 正史順序：餘杭 → 仙靈島 → 蘇州 → 將軍塚 → 試煉窟 → 鎖妖塔 → 苗疆 → 拜月）。
目前狀態：
- 8 張戰鬥背景已補齊。
- 一階 boss 肖像已大致補齊，並已開始依 PAL1 正史進行對位校正。
- boss 的 phase 2 專屬圖仍有少數未落檔 / 未接入程式。

### A. 戰鬥背景（3 張）🟢 已全部完成
| 檔名 | 場景 | 風格建議 | 狀態 |
|---|---|---|---|
| `assets/art/battle_bg_act_2.png` | 仙靈島 / 水月宮 | 雲霧繚繞的水中仙島、宮闕倒影、靈氣氤氳，水墨青碧調 | 🟢 已完成（專屬美術） |
| `assets/art/battle_bg_act_4.png` | 將軍塚 | 荒塚石碑、陰風殘旗、磷火幽光，蕭瑟灰褐調 | 🟢 已完成（專屬美術） |
| `assets/art/battle_bg_act_5.png` | 試煉窟 | 地底洞窟、五靈法陣石壁、幽光石筍，神秘幽藍調 | 🟢 已完成（專屬美術） |

> 既有背景對應：act1 餘杭 / act3 蘇州 / act6 鎖妖塔 / act7 苗疆 / act8 拜月（皆有專屬美術）。
> 補圖後執行 `godot --headless --path . --import` 重匯入即生效，程式已 `clamp(act, 1, 8)`。

### B. 新 Boss 肖像（3 個）🟢 已全部完成
新增 3 個 boss 肖像（按 `portrait_path` 路徑新增即生效）：

| Boss ID | 顯示名 | 目前借用/狀態 | 風格建議 |
|---|---|---|---|
| `miao_chieftain` | 黑苗頭領（仙靈島 boss）| 🟢 已完成（專屬美術） | 手持苗刀、面容兇惡的黑苗頭領，統領黑苗士兵血洗仙靈島，陰險霸氣 |
| `tomb_general` | 塚中亡將（將軍塚 boss）| 🟢 已完成（專屬美術） | 殘甲執戈的亡將魂魄，陰森戰魂氣息 |
| `zhenyu_mingwang` | 鎮獄明王（鎖妖塔 boss・正史）| 🟢 已完成（專屬美術） | 金剛怒目的鎮獄明王法相，鎖鏈降魔杵，莊嚴而威壓 |

### C. PAL1 Boss 正史校正（2026-06-07）
將先前偏原創或非 PAL1 正式 boss 的對位，調整為更貼近原作正史的版本；先保留既有 `enemy.id` 以避免存檔、掉落與難度索引全面改動。

| 既有 ID | 舊顯示名 | 新顯示名 / 對位 | 一階圖 | 二階圖 | 程式接入 |
|---|---|---|---|---|---|
| `red_eye_demon` | 赤眼山魈 | 蛇妖男（phase 2：狐妖女） | 🟢 已補 | 🟢 已補 | 🟢 `phase_2_portrait_path` 已接入 |
| `zombie_general` | 殭屍大帥 | 殭屍王 | 🟡 名稱已校正，圖可再重製 | ⬜ 尚未規劃 | ⬜ 尚未接入 |
| `tomb_general` | 塚中亡將 | 赤鬼王 | 🟢 已補 | 🟡 已生成概念圖，待落檔 `assets/art/enemies/tomb_general_phase2.png` | ⬜ 尚未接入 |
| `witch_queen` | 山靈巫后 | 火麒麟（phase 2：火眼麒麟） | 🟢 已補 | 🟢 已補 | 🟢 `phase_2_portrait_path` 已接入 |
| `centipede_lord` | 蜈蚣大王 | 石長老 | 🟢 已補 | 🟡 已生成概念圖，待落檔 `assets/art/enemies/centipede_lord_phase2.png` | ⬜ 尚未接入 |

相關程式位置：
- `scripts/game_data.gd`：boss 對位名稱、招式文案、phase 2 顯示名與換圖路徑
- `scripts/relic_catalog.gd`：對應 boss 專屬遺物名稱與描述同步校正
- `docs/PAL1_CANON.md`：八幕 boss 對照更新為 PAL1 正史版本

### D. 新增 PAL1 小怪肖像（7 個）🟢 已全部完成
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

## 七、多元小怪擴充（31 個，🟢 已全部完成）

為了對齊 PAL1 中的經典小怪，擴充了 31 個經典敵人。所有 31 個敵人均已繪製並補齊獨立的專屬美術去背水墨圖檔（`assets/art/enemies/<id>.png`）。

| 敵人 ID | 顯示名 | 出沒幕 | 狀態 | PAL1 出處 / 說明 |
|---|---|---|---|---|
| `thief` | 小偷 | 1, 3 | 🟢 已完成（專屬美術） | 經典苗疆小偷/盜賊，技能包含偷竊玩家金錢 |
| `tree_demon` | 樹妖 | 2, 7 | 🟢 已完成（專屬美術） | 經典樹妖怪，技能以纏繞與毒素為主 |
| `xing_tian` | 刑天 | 5, 6 | 🟢 已完成（專屬美術） | 巨大無頭戰神，手持巨斧，擁有高傷害與重擊能力 |
| `black_impermanence` | 黑無常 | 4, 6 | 🟢 已完成（專屬美術） | 地府勾魂使者，使用哭喪棒與鬼火攻擊，帶虛弱與破綻 |
| `white_impermanence` | 白無常 | 4, 6 | 🟢 已完成（專屬美術） | 地府勾魂使者，使用索命鏈與陰毒，能吸取玩家靈力 |
| `viper` | 毒蛇 | 1, 2 | 🟢 已完成（專屬美術） | 經典紅/綠小蛇，造成毒素傷害 |
| `man_eating_flower` | 狂暴食人花 | 2, 7 | 🟢 已完成（專屬美術） | 經典食人花，擁有強力的撕咬與流血/毒素效果 |
| `cleaver_granny` | 菜刀婆婆 | 3, 4 | 🟢 已完成（專屬美術） | 手持菜刀的怨靈老婆婆，高防守與多次割裂 |
| `flying_skull` | 飛頭蠻 | 4, 6 | 🟢 已完成（專屬美術） | 漂浮的骷髏頭，噴吐鬼火與詛咒 |
| `gourd_sage` | 靈葫仙翁 | 5, 6 | 🟢 已完成（專屬美術） | 葫蘆化身的老翁，能給自己防禦與反射傷害 |
| `puppet_girl` | 傀儡女 | 7, 8 | 🟢 已完成（專屬美術） | 被絲線操控的傀儡少女，具備連擊與多重防禦 |
| `green_snake` | 綠松蛇 | 1 | 🟢 已完成（專屬美術） | 十里坡經典綠色小蛇，以叮咬與微量毒素為主 |
| `grass_spider` | 草蛛 | 1 | 🟢 已完成（專屬美術） | 隱藏在草叢中的小蜘蛛，噴吐蛛網造成虛弱 |
| `lantern_ghost` | 燈籠怪 | 1 | 🟢 已完成（專屬美術） | 飄浮的紅燈籠妖怪，噴吐小火球與致盲 |
| `hydra_snake` | 九頭蛇 | 3 | 🟢 已完成（專屬美術） | 擁用意象的多頭蛇，造成多次中毒攻擊 |
| `flying_snake` | 飛蛇 | 3 | 🟢 已完成（專屬美術） | 有翼的飛蛇，行動敏捷，容易造成破綻 |
| `baby_toad` | 小蛤蟆 | 2 | 🟢 已完成（專屬美術） | 靈島水邊的小青蛙，吐舌攻擊 |
| `poison_toad` | 毒蟾蜍 | 3 | 🟢 已完成（專屬美術） | 劇毒的大蟾蜍，噴灑毒霧 |
| `vampire_giant` | 吸血巨人 | 4 | 🟢 已完成（專屬美術） | 巨大的吸血殭屍，吸取玩家生命值 |
| `scorpion` | 毒蠍子 | 5 | 🟢 已完成（專屬美術） | 試煉窟中的毒蠍，尾刺帶有烈性劇毒 |
| `female_thief` | 女飛賊 | 3 | 🟢 已完成（專屬美術） | 身手敏捷的女賊，會偷取玩家金錢並迅速防守 |
| `birdman` | 鳥人 | 7 | 🟢 已完成（專屬美術） | 雙翼的人型怪物，俯衝風刃攻擊 |
| `demihuman_villager` | 半妖村民 | 7 | 🟢 已完成（專屬美術） | 被魔氣侵蝕的半人半妖村民，狂暴亂擊 |
| `five_eyed_demon` | 五眼魔 | 6 | 🟢 已完成（專屬美術） | 擁有多隻魔眼的怪物，凝視造成強力虛弱與破綻 |
| `unicorn_demon` | 獨角獸 | 6 | 🟢 已完成（專屬美術） | 鎖妖塔的獨角怪獸，雷霆撞擊 |
| `pincer_demon` | 夾子怪 | 6 | 🟢 已完成（專屬美術） | 巨鉗怪獸，能重擊玩家並削弱格擋 |
| `jumping_frog` | 跳跳蛙 | 6 | 🟢 已完成（專屬美術） | 鎖妖塔的奇異青蛙，跳躍踩踏 |
| `fire_kirin_whelp` | 火麒麟幼獸 | 5 | 🟢 已完成（專屬美術） | 火麒麟的年幼後代，吐息帶火焰與灼燒 |
| `ice_beast` | 冰青獸 | 5 | 🟢 已完成（專屬美術） | 冰原上的青色靈獸，冰甲防禦與寒冰吐息 |
| `man_eater_beast` | 食人獸 | 8 | 🟢 已完成（專屬美術） | 拜月教壇周圍的巨大凶獸，吞噬重擊 |
| `two_headed_snake` | 雙頭蛇 | 8 | 🟢 已完成（專屬美術） | 雙頭毒蛇，兩次連擊並附帶劇毒 |

---

## 八、UI / 地圖節點圖示（🟢 已全部完成）

地圖節點圖示由 `scripts/map_node_icon.gd` 繪製：優先載入 `res://assets/ui/node_<type>.png`，
找不到才用程式繪製的 fallback。下列圖示已全部完成：

| 檔名 | 用途 | 目前狀態 | 風格建議 |
|---|---|---|---|
| `assets/ui/node_elite.png` | 精英節點（A1/A3/A8 難度新增）| 🟢 已完成（專屬美術） | 染血雙劍與妖將面具結合，與既有節點 icon 風格一致，與 boss 骷髏頭區分開來 |

> 補圖後執行 `godot --headless --path . --import` 重匯入即生效；`map_node_icon._load_node_texture()`
> 會自動優先採用。legend 顏色已設為 `Color("e2728c")`（暗紅）、節點標記為「精」。

## 九、道具／藥品圖示優化（🟢 已全部完成）

| 檔名 | 用途 | 目前狀態 | 備註 |
|---|---|---|---|
| `assets/art/potions/fentian_zhu.png` | 藥品「焚天珠」 | 🟢 已重製（專屬美術） | 升級為精緻 3D 立體水墨火球風格，帶有毒氣與火花特效 |

---

## 補圖規格

- 格式：PNG，存於 `assets/art/cards/<id>.png`（卡圖）或 `assets/art/<檔名>.png`（背景）；UI 圖示存 `assets/ui/<檔名>.png`，藥品圖示存 `assets/art/potions/<檔名>.png`
- 完成後補 `.import` 配置（`godot --headless --path . --import`）
