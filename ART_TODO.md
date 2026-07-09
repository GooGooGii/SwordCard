# 卡圖待補清單

最後更新：2026-06-11（依實際資產盤點更新：Boss 劇情圖已全數完成，剩餘缺口聚焦 phase 2 肖像、1 張敵圖與 3 張通用特效圖）

> **目前優先順序**（依實際資產盤點，2026-06-11）：
> 1. §6C Boss phase 2 圖 ×2 落檔（`tomb_general` / `centipede_lord`，概念圖已生成）
> 2. §14A-2 敵人借圖名實不符 ×1（`jumping_frog`）
> 3. §15 通用招式特效圖 ×3（`fx_shield` / `fx_heal_glow` / `fx_power_circle`）
> 4. §5 無門派卡圖重製 ×6（非缺檔，屬風格清理）

---

## 〇、奇遇事件插畫待補（Event Redesign）

| 檔名 | 事件 | 目前狀態 | 建議風格 |
|---|---|---|---|
| `assets/art/events/shushan_vault.png` | 蜀山秘府（稀有奇遇） | 🟢 已完成（專屬美術） | 仙家洞府秘境：山壁裂縫後別有洞天，蟠桃酒缸 + 鎮府法寶靈光 + 滿壁劍訣，蜀山仙氣、金光內斂，水墨國風與既有事件插畫一致 |

> 規格同既有事件插畫：橫幅構圖，`UIFactory` 會自動載入 `assets/art/events/<variant>.png` 當標題下 banner（760×200）與結算面板小圖（660×160）。補圖後 `godot --headless --path . --import` 重匯入即生效。其餘 10 個由扁平改寫成分支樹的事件沿用原有插畫，無須補圖。

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
| `anu_shuhun` | 🟢 已完成專屬水墨圖 (2026-06-14)，不再與 `anu_jiedu` 同圖 |
| `anu_wangushitian` | 🟢 已完成專屬水墨圖 (2026-06-14)，不再與 `anu_yufeng` 同圖 |
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
| `zl_mengshe_ls` | 🟢 已完成專屬水墨圖 (2026-06-14)，不再與 `zl_mengshe` 同圖 |
| `zl_sanmeizhenhuo` | 與 `zl_yanzhou` 同圖 |
| `zl_taishan` | 🟢 已完成專屬水墨圖 (2026-06-14)，不再與 `zl_tianlei` 同圖 |
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

### 🟢 已完成專屬卡圖（2026-06-10 新增，6 張）
已補齊專屬去背水墨圖檔並移除代碼中 `art_id` 借用：
- `lxy_xiangcheng` (御劍相承) - 🟢 已完成專屬水墨圖
- `lxy_jianqizonghen` (劍氣縱橫) - 🟢 已完成專屬水墨圖
- `lxy_yujianxinjue` (御劍心訣) - 🟢 已完成專屬水墨圖
- `zl_juling` (聚靈訣) - 🟢 已完成專屬水墨圖
- `zl_lingguangpuzhao` (靈光普照) - 🟢 已完成專屬水墨圖
- `zl_lingxijue` (靈息訣) - 🟢 已完成專屬水墨圖

### 🟢 已完成專屬卡圖（2 張，2026-06-10 新增）
- `zl_wanlingshi` (萬靈噬) - 🟢 已完成專屬水墨圖
- `lyr_tiegu` (鐵骨樁) - 🟢 已完成專屬水墨圖

### 🟢 已完成專屬卡圖（2026-06-10 / 06-11 新增與重繪）
已完成從向量占位圖重繪，並符合 Art Guide 水墨去背風格：
- `cl_chenxi_poshi` (趁隙破勢) - 🟢 已完成專屬水墨圖 (2026-06-11 重製)
- `cl_wutongjue` (無痛訣) - 🟢 已完成專屬水墨圖 (2026-06-11 重製)
- `cl_shipaijue` (噬牌訣) - 🟢 已完成專屬水墨圖 (2026-06-11 重製)
- `cl_fenjinjue` (焚盡訣) - 🟢 已完成專屬水墨圖 (2026-06-11 重製)
- `anu_guxue_shixin` (蠱血噬心) - 🟢 已完成專屬水墨圖
- `lyr_suohun` (索魂十三劍) - 🟢 已完成專屬水墨圖

### 🔴 待重製無門派卡圖（6 張，2026-06-11 盤點，額度受限待補）
因 AI 繪圖額度耗盡，暫時保留舊有卡圖。待額度恢復後需重製以符合「無人物、無文字/印章」規範：
- `cl_qimendunjia` (奇門遁甲) - 🔴 待重製（目前含有英文標籤 QIAN, KUN 等）
- `cl_jinchuangtie` (金創藥帖) - 🔴 待重製（目前含有「草药灵丹」簡體中文字）
- `cl_hanfengjue` (寒鋒訣) - 🔴 待重製（目前含有正面臉部模糊的持劍人物）
- `cl_poshi` (覷破空門) - 🔴 待重製（目前含有正面人物與 AI 殘印）
- `cl_zhimingfu` (致盲符) - 🔴 待重製（目前含有正面遮眼人物）
- `cl_hushenjue` (金鐘護體) - 🔴 待重製（目前含有正面人物剪影）


### 🟢 已完成藥品圖示（3 瓶，2026-06-10 新增 — build-enabler 藥品）
- `fenshen_dan` (分身丹) - 🟢 已完成專屬水墨圖
- `xianren_yitui` (仙人遺蛻) - 🟢 已完成專屬水墨圖
- `hunyuan_dan` (混元丹) - 🟢 已完成專屬水墨圖

### 🟢 遺物圖示更新（2026-06-11 新增，14 件）
已全部補齊專屬水墨去背圖檔：
- `xiaoyao_ling` (逍遙令) - 🟢 已完成專屬水墨圖
- `zhen_hun_ling` (鎮魂鈴) - 🟢 已完成專屬水墨圖
- `ning_shen_yu` (凝神玉) - 🟢 已完成專屬水墨圖
- `jin_zhong_zhao` (金鐘罩) - 🟢 已完成專屬水墨圖
- `jin_gang_zuo` (金剛座) - 🟢 已完成專屬水墨圖
- `tong_ling_yu` (通靈玉) - 🟢 已完成專屬水墨圖
- `ding_hun_zhu` (定魂珠) - 🟢 已完成專屬水墨圖
- `shehun_guling` (攝魂蠱鈴) - 🟢 已完成專屬水墨圖
- `xueji_guan` (血棘冠) - 🟢 已完成專屬水墨圖
- `xuanwu_zhongjia` (玄武重甲) - 🟢 已完成專屬水墨圖
- `kuangzhan_fu` (狂戰護符) - 🟢 已完成專屬水墨圖
- `guixi_xuanjia` (龜息玄甲) - 🟢 已完成專屬水墨圖
- `yehuo_lu` (業火爐) - 🟢 已完成專屬水墨圖
- `hu_shen_fu` (護身符) - 🟢 已完成專屬水墨圖 (2026-06-14 新增)




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
| `tomb_general` | 塚中亡將 | 赤鬼王 | 🟢 已補 | 🟢 已補 | 🟢 `phase_2_portrait_path` 已接入 |
| `witch_queen` | 山靈巫后 | 火麒麟（phase 2：火眼麒麟） | 🟢 已補 | 🟢 已補 | 🟢 `phase_2_portrait_path` 已接入 |
| `centipede_lord` | 蜈蚣大王 | 石長老 | 🟢 已補 | 🟢 已補 | 🟢 `phase_2_portrait_path` 已接入 |

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

## 七之二、PAL1 對齊新增小怪（🟢 已完成專屬美術）

依 PAL1 各地點正史補的 9 隻小怪，已於 2026-06-09 補齊各自的去背水墨專屬圖，
並將 `game_data.gd` 的 `portrait_path` 改回各自 id。

| 敵人 ID | 顯示名 | 出沒幕 | 狀態 | 美術方向 |
|---|---|---|---|---|
| `bee_cocoon` | 蜂蛹 | 1 | 🟢 已完成（專屬美術） | 米色繭狀蜂蛹，掛在枝上、半透蠕動感（十里坡）|
| `leaf_sprite` | 綠葉小妖 | 1 | 🟢 已完成（專屬美術） | 嫩綠葉片組成的小妖精，最低階草系雜兵 |
| `grass_sprite` | 草精 | 2 | 🟢 已完成（專屬美術） | 仙靈島藤草凝成的小精怪，纏蔓造型 |
| `thug` | 打手 | 3 | 🟢 已完成（專屬美術） | 蘇州市井惡霸打手，粗布短打、拳套悶棍 |
| `miao_maiden` | 長鞭苗女 | 2,7,8 | 🟢 已完成（專屬美術） | 苗疆女戰士，長鞭+毒鏢、苗銀飾，民族風 |
| `octopus_imp` | 短腿章魚 | 8 | 🟢 已完成（專屬美術） | 水底迷宮短腿章魚怪，圓身多腕 |
| `clam_spirit` | 蚌殼精 | 8 | 🟢 已完成（專屬美術） | 巨蚌開合、內含珍珠光，高防水族 |
| `conch_maiden` | 海螺女 | 8 | 🟢 已完成（專屬美術） | 海螺殼下的女妖，音波攻擊、鱗甲 |
| `turtle_demon` | 傻仔龜 | 8 | 🟢 已完成（專屬美術） | 憨態大龜怪，厚殼縮防、噴水 |
| `gambler` | 賭棍 | 3 | 🟢 已完成（專屬美術） | 蘇州賭坊潑皮，骰盅、油滑市井裝 |
| `lecher_thief` | 淫賊 | 3 | 🟢 已完成（專屬美術） | 鼠目猥瑣的登徒子小賊，夜行衣 |
| `rat_demon` | 鼠妖 | 3 | 🟢 已完成（專屬美術） | 城中下水道鼠妖，灰毛尖牙、群聚 |
| `bully` | 惡霸 | 3 | 🟢 已完成（專屬美術） | 蘇州市井惡霸頭目，膀大腰圓、仗勢欺人 |
| `earth_imp` | 小土鬼 | 4 | 🟢 已完成（專屬美術） | 將軍塚泥土凝成的小鬼，矮胖、土黃 |
| `blood_worm` | 血口蟲 | 4 | 🟢 已完成（專屬美術） | 塚中血口蠕蟲，環節腥紅、噴血毒 |
| `venom_spider` | 五毒蜘蛛 | 5 | 🟢 已完成（專屬美術） | 試煉窟五彩劇毒蜘蛛，毒絲蛛網 |
| `fire_toad` | 食火蟾 | 5 | 🟢 已完成（專屬美術） | 試煉窟噴火大蟾，赤紅鼓腹、火舌 |

> 目前剩餘需補的敵圖不再包含本段 9 隻；若新增同類小怪，仍沿用
> `assets/art/enemies/<id>.png` + `portrait_path` 直指專屬圖的流程。

---

## 八、UI / 地圖節點圖示（🟢 已全部完成）

地圖節點圖示由 `scripts/map_node_icon.gd` 繪製：優先載入 `res://assets/ui/node_<type>.png`，
找不到才用程式繪製的 fallback。下列圖示已全部完成：

| 檔名 | 用途 | 目前狀態 | 風格建議 |
|---|---|---|---|
| `assets/ui/node_elite.png` | 精英節點（A1/A3/A8 難度新增）| 🟢 已完成（專屬美術） | 染血雙劍與妖將面具結合，與既有節點 icon 風格一致，與 boss 骷髏頭區分開來 |

> 補圖後執行 `godot --headless --path . --import` 重匯入即生效；`map_node_icon._load_node_texture()`
> 會自動優先採用。legend 顏色已設為 `Color("e2728c")`（暗紅）、節點標記為「精」。

## 八之二、敵人意圖圖示（🟢 已全部完成，2026-06-08）

戰鬥中敵人頭頂意圖已改為「圖示制」（仿 Slay the Spire）。所有 7 個意圖圖示皆已補齊：

| 檔名 | 意圖類別 | 目前狀態 | 對應 effect | 風格建議 |
|---|---|---|---|---|
| `assets/ui/intent/attack.png` | 攻擊 | 🟢 已完成 | damage / damage_all | 出鞘利刃／劍尖，紅金色調 |
| `assets/ui/intent/defend.png` | 防守 | 🟢 已完成 | block | 護盾／護體靈光，青藍色調 |
| `assets/ui/intent/control.png` | 控制 | 🟢 已完成 | stun / silence / berserk | 鎖鏈纏繞或封印符咒（眩暈星亦可），紫色調 |
| `assets/ui/intent/debuff.png` | 異常 | 🟢 已完成 | poison / weak / vulnerable（含 _all）| 向下骷髏／毒滴，暗綠色調 |
| `assets/ui/intent/buff.png` | 強化 | 🟢 已完成 | power | 向上箭頭／攥拳氣勁，橙紅色調 |
| `assets/ui/intent/heal.png` | 治療 | 🟢 已完成 | heal / heal_party | 十字／綠色生機靈光 |
| `assets/ui/intent/summon.png` | 召喚 | 🟢 已完成 | summon | 召喚法陣／鬼影浮現，幽紫色調 |

規格：**64×64 透明 PNG**，扁平簡潔可在 16–22px 縮放下辨識，水墨／國風色感與既有 UI 一致。
補圖後執行 `godot --headless --path . --import` 重匯入即生效（程式 `UIFactory.load_texture` 會自動採用）。

## 九、道具／藥品圖示優化（🟢 已全部完成）

| 檔名 | 用途 | 目前狀態 | 備註 |
|---|---|---|---|
| `assets/art/potions/fentian_zhu.png` | 藥品「焚天珠」 | 🟢 已重製（專屬美術） | 升級為精緻 3D 立體水墨火球風格，帶有毒氣與火花特效 |

---

## 十、現行敘事插畫派清單（後續轉折衷派）

工作定義：人物主導、完整場景、偏劇照式敘事構圖的卡圖，後續統一往「折衷派」收斂
（保留完成度與戲劇張力，但減少過滿場景，回到 `ART_GUIDE` 強調的器物 / 術式 / 意境主導）。

> 2026-06-07：原本那批極簡派卡圖已先重繪回較完整的 `ART_GUIDE` 方向；
> 本節列的是下一階段要優化成折衷派的敘事插畫稿，不和極簡派重繪混在一起。

- 李逍遙：`lxy_feilong`、`lxy_huijian`、`lxy_jianjue`、`lxy_jianzhen`、`lxy_jianshen`、`lxy_jiulong`、`lxy_jiushen`、`lxy_lianhuanjian`、`lxy_liepo`、`lxy_linghuo`、`lxy_qingfeng`、`lxy_tiangangqi`、`lxy_tianjian`、`lxy_wanjian`、`lxy_wanjianguizong`、`lxy_xianfeng`、`lxy_xiaoyao_shenjian`、`lxy_xiaoyao_you`、`lxy_yuanlinggui`、`lxy_yufengbu`、`lxy_yujian`、`lxy_zhenyuan`、`lxy_zuilong`、`lxy_zuimeng`
- 趙靈兒：`zl_bingzhou`、`zl_diliebeng`、`zl_fengling`、`zl_fengxuebing`、`zl_ganlin`、`zl_guanyin`、`zl_huanyu`、`zl_huguangzhou`、`zl_huihun`、`zl_jingang`、`zl_kuanglei`、`zl_leiguang`、`zl_lianzhuzhou`、`zl_lingguang`、`zl_lingxi`、`zl_mengshe`、`zl_mengshe_ls`、`zl_nvwa`、`zl_sanmeizhenhuo`、`zl_shenlei`、`zl_shuiling`、`zl_shuiyin`、`zl_taishan`、`zl_tianlei`、`zl_wuqi`、`zl_xiaoleizhou`、`zl_xuanbing`、`zl_xuanfengzhou`、`zl_yanzhou`、`zl_yinlingfu`
- 林月如：`lyr_bianying`、`lyr_fanji`、`lyr_fenghuan`、`lyr_huaci`、`lyr_jici`、`lyr_jinchan`、`lyr_juesha`、`lyr_kuaijian`、`lyr_lianhuan`、`lyr_lielong`、`lyr_ningshen`、`lyr_poqian`、`lyr_qiankun`、`lyr_qiebushan`、`lyr_qijianzhi`、`lyr_qijuejianqi`、`lyr_shenfa`、`lyr_shuangjianci`、`lyr_tianv`、`lyr_tieyi`、`lyr_tongqianbiao`、`lyr_wanlikuang`、`lyr_xuanjian`、`lyr_yiyang`、`lyr_yuanlinggui`、`lyr_yuehua`、`lyr_zhanlong`
- 阿奴：`anu_baizu`、`anu_baozhagu`、`anu_cuifeng`、`anu_cuihua`、`anu_duohun`、`anu_duwu`、`anu_duzhen`、`anu_gudaocui`、`anu_guijiang`、`anu_guling`、`anu_gushen`、`anu_guwang`、`anu_guxue`、`anu_guzhang`、`anu_huguzhao`、`anu_jiedu`、`anu_jishigu`、`anu_lianduzhen`、`anu_lingxue`、`anu_mihun`、`anu_sandu`、`anu_sanshigu`、`anu_shuhun`、`anu_wangushitian`、`anu_wangyou`、`anu_wanyi`、`anu_wanyi_ls`、`anu_wuyuezhan`、`anu_xuerenwu`、`anu_yanshazhou`、`anu_yindu`

---

## 十一、Boss 擊敗劇情圖（🟢 已全數完成，2026-06-11 盤點）

擊敗各幕 Boss 後，全螢幕顯示一張**劇情插畫**（過場用），玩家**點一下任意處**即淡出跳過、續接戰利品流程。
程式已接好（`main.gd:_show_boss_story`）；目前 9 張劇情圖皆已落在 `assets/art/story/`，進遊戲即可直接使用。

- 路徑：`assets/art/story/<boss_id>.png`（新資料夾 `assets/art/story/`）
- **不需去背**：這是全幅劇情插畫（會鋪滿黑底全螢幕顯示），請畫完整背景、勿留透明。
- 建議尺寸：橫向滿版（對齊遊戲 16:9，如 1920×1080 或 1280×720），KEEP_ASPECT 置中顯示
- 風格：水墨 / 劇照式單幅敘事圖，呼應該 Boss 在 PAL1 劇情中的關鍵場景或擊敗後的轉折

| boss_id | 顯示名 | 對應幕 | 建議劇情場景 |
|---|---|---|---|
| `miao_chieftain` | 黑苗頭領 | 苗疆系 | 苗寨衝突落幕、黑苗頭領伏誅 |
| `centipede_lord` | 石長老（蜈蚣精） | — | 蜈蚣巨妖崩解、洞窟脫困 |
| `witch_queen` | 火麒麟 | — | 火麒麟現形與鎮服的靈獸場面 |
| `red_eye_demon` | 蛇妖男 | — | 妖蛇巢穴決戰收場 |
| `tomb_general` | 赤鬼王 | 將軍塚 | 將軍塚亡將歸於塵土 |
| `zombie_general` | 殭屍王 | — | 屍王潰滅、邪氣消散 |
| `zhenyu_mingwang` | 鎮獄明王 | 鎖妖塔 | 鎖妖塔頂層、明王鎮壓 |
| `baiyue_lord` | 拜月教主 | 拜月決戰（終幕） | 拜月教主敗亡、水魔獸最終形態（可考慮二連圖） |
| `moon_worshipper` | 拜月教徒 | 拜月系 | 拜月教壇場景、教徒潰散 |

> 2026-06-11 實際檔案盤點：`miao_chieftain`、`centipede_lord`、`witch_queen`、`red_eye_demon`、`tomb_general`、`zombie_general`、`zhenyu_mingwang`、`baiyue_lord`、`moon_worshipper` 共 9 張皆已存在於 `assets/art/story/`。
> 9 個 boss_id 來源見 `scripts/ascension.gd` 的 `BOSS_IDS` + `is_boss_id()`。
> 終幕 `baiyue_lord`（act 8）擊敗即通關，其劇情圖等同 ending 場景，優先度最高。

---

## 十二、敵人肖像去背修正（🟢 15 張已完成，2026-06-10）

下列敵人肖像原本**沒有真正的透明背景**——背景（棋盤格／灰底）被烤進不透明像素
（四角 alpha=255、透明像素 0%），戰鬥中 `ground_portrait` 會把整張矩形連灰底畫出、
敵人身後出現灰方塊。**已用 BgRemover（rembg `birefnet-general` 模型）重新去背**為 RGBA 透明，
覆蓋回 `assets/art/enemies/<id>.png` 並重新 import。模型比較（isnet-general-use / u2net /
birefnet-general）後選 birefnet——邊緣最乾淨、無灰色 halo、水墨細節（花藤/鎖鏈/白袍）保留最好。

| 檔名 | 敵人 |
|---|---|
| `thug` | 山賊 |
| `thief` | 盜賊 |
| `tree_demon` | 樹妖 |
| `turtle_demon` | 傻仔龜 |
| `flower_spirit` | 花妖 |
| `xing_tian` | 刑天 |
| `bee_cocoon` | 蜂蛹 |
| `grass_sprite` | 草精 |
| `leaf_sprite` | 綠葉小妖 |
| `octopus_imp` | 章魚怪 |
| `clam_spirit` | 蚌精 |
| `conch_maiden` | 海螺女 |
| `miao_maiden` | 苗女 |
| `black_impermanence` | 黑無常 |
| `white_impermanence` | 白無常 |

> 其餘 45 張敵人肖像已是真去背（四角 alpha=0），無需處理。
> 盤點方式：PIL 掃 `assets/art/enemies/*.png`，四角 alpha 全 255 且透明像素 <8% 即判定未去背。

---

## 十三、水墨風選單美術（🟢 已全部完成，2026-06-10 — 選單質感升級用）

選單已做「美術與程式層」水墨化，已成功生成並導入這 5 張去背/無縫水墨資源，在遊戲中呈現優雅的手繪水墨體驗：

- **宣紙底紋 texture**（`assets/art/ui/paper_texture.png`，可平鋪）：🟢 已完成。鋪在面板底，取代純色，增加紙張顆粒感。
- **卷軸九宮格邊框**（`assets/art/ui/scroll_frame.png`，9-slice）：🟢 已完成。給主面板當外框，增添古典捲軸質感。
- **毛筆筆觸分隔線**（`assets/art/ui/brush_divider.png`）：🟢 已完成。取代金線，呈現大氣流暢的書法毛筆分隔線。
- **角落水墨花紋**（`assets/art/ui/corner_ink.png`，四角鏡像）：🟢 已完成。面板四角點綴墨竹與雲紋。
- **主選單題字**（`assets/art/ui/title_swordcard.png`）：🟡 **需重出**（2026-06-11）。
  事故記錄：① 最初的 1040×250 青銅毛筆版（「劍」字＋SwordCard，效果最佳）**未入庫即被去背流程覆蓋，已遺失**；
  ② 後續兩版去背輸出（403d534 與工作區 00:23 版）**全透明 0 可見像素**（去背流程把整張洗掉）。
  目前已還原 b9a8651 的 512×256 細白字版頂著（偏單薄）。重出建議：按最初青銅毛筆版方向、
  ≥1024 寬、深色描邊（淺色天空底上要可讀）、輸出後用 PIL 檢查 `alpha>40 像素數 > 0` 再入庫。

---

## 十四、總體檢報告衍生需求（2026-06-10，詳見 `docs/IMPROVEMENT_PLAN_2026-06.md`）

### A. 卡圖風格一致性重生成（🔴 已盤點，11 張待重生成 — 2026-06-11）
用 `tools/contact_sheet.gd` 拼出全卡網格肉眼掃描完成（anu / lyr 大致統一；
**2026-06-10 新增的 StS 對照批 6 張裡有 5 張整批跑成「扁平 icon 風」**，與水墨場景式插畫違和最重）。
重生成方向：滿幅水墨場景式、去背、無文字，對齊各角色既有主色（李藍金劍氣 / 趙藍紫雷 / 林赤鞭 / 阿奴墨綠蠱）。

| ID | 卡名 | 問題 | 優先 |
|---|---|---|---|
| `lxy_yujian` | 御劍術（**起始卡×3，曝光最高**）| 圖面呈金色雙心圖案，與「御劍」意象不符 | 高 |
| `cl_huacaijianyi` | 華彩劍意 | 彩虹星雲照片感，完全脫離水墨 | 高 |
| `cl_chenxi_poshi` | 趁隙破勢 | 灰底扁平飛鏢 icon 風 | 高 |
| `cl_fenjinjue` | 焚盡訣 | 金黃雙符扁平 icon 風 | 高 |
| `cl_shipaijue` | 噬牌訣 | 黑底膠囊/卡牌咬痕 icon 風 | 高 |
| `cl_wutongjue` | 無痛訣 | 青色圓圈 icon 風 | 高 |
| `lyr_suohun` | 索魂十三劍 | 白底紫色扁平符紋 | 中 |
| `zl_wanlingshi` | 萬靈噬 | 🟢 已完成專屬水墨圖 (2026-06-14 重製) | — |
| `zl_yanzhou` | 炎咒 | 黑底寫實火焰，無水墨質感 | 中 |
| `lxy_jianjue` | 劍訣 | 飽和藍人像插畫風，脫離水墨色域 | 中 |
| `lxy_jianqizonghen` | 劍氣縱橫 | 白底極簡物件式，與場景式混排突兀 | 低 |
| `lyr_tianv` | 飛花亂舞 | 黑底金環 icon 感（建議原尺寸複核後再定）| 低 |

> 複核方式：`godot --headless --path . -s tools/contact_sheet.gd` 重新輸出 `_contact_*.png` 網格比對。

### A-2. 敵人借圖名實不符（🔴 待補 1 張，2026-06-11 戰鬥畫面比對發現）

| 敵人 ID | 顯示名 | 目前借用 | 問題 | 建議風格 |
|---|---|---|---|---|
| `jumping_frog` | 跳跳蛙 | `water_imp.png`（舊狀態） | 🟢 已改回專屬肖像並接入 `assets/art/enemies/jumping_frog.png` | PAL1 鎖妖塔「跳跳蛙」方向完成：綠皮大蛙、後腿蓄力跳躍姿態、去背水墨 |

### B. 終幕結局頁變體圖（🟡 可選，低優先）
`baiyue_lord` 擊敗即通關，計劃依 `event_flags` / 隊伍組成出 2–3 種結語（IMPROVEMENT_PLAN P1-3 ④）。
基礎版共用 §11 的 `assets/art/story/baiyue_lord.png` 一張即可；
若日後想讓不同結局配不同圖，再補 `baiyue_lord_ending_<variant>.png` 變體（規格同 §11，不去背、16:9 滿版）。

### C. 明確「不需要美術」的報告項（避免誤領工單）
- 地圖節點強化（P1-4）：放大、襯底、描邊、呼吸動畫全部程式繪製。
- 幕間字卡（P1-3）：沿用 8 幕戰鬥背景＋程式暗角＋文字，無需新圖。
- 卡面改版（P1-5）、征途錄（P2-6）、成就（P2-7）：沿用既有 UI 樣式與程序化圖示。
- 戰鬥背景色域統一（P3-14）：對既有 8 張背景批次後製（LUT/暗角），非新圖。

---

## 十五、通用招式特效圖（🔴 3 張待補，2026-06-11 — 動畫架構已就緒，見 `docs/ANIM_PLAN.md`）

P1 通用分類 fallback 特效已上線（無專屬動畫的 121 張卡自動套用）。劍光斬 / 毒擊
複用既有 `ink_slash.png` / `poison_needle.png`；下列 3 類目前**退化為 flash 純動作回饋**，
補圖放進 `assets/art/effects/` 即自動升級（程式接點已寫好、不需改碼）：

| 檔名 | 用途 | 建議風格 |
|---|---|---|
| `assets/art/effects/fx_shield.png` | 護體類卡（block）：護盾浮現於角色前方淡出 | 🟢 已完成：半透明水墨氣盾／金色符文罩，居中圓形構圖 |
| `assets/art/effects/fx_heal_glow.png` | 治療類卡（heal）：靈光自腳下上飄 | 🟢 已完成：綠金色靈氣光暈、向上飄散的光點，柔和水墨 |
| `assets/art/effects/fx_power_circle.png` | 能力牌（power）啟動：法陣於腳下亮起 | 🟢 已完成：金色道家法陣／八卦光環，俯視圓陣構圖 |

> 皆**需去背（透明 PNG）**、建議 512×512。P2 高光卡特效另需 `fx_ember`（焚盡訣餘燼）、
> `fx_five_spirits`（萬靈噬五色靈光）、`fx_ghost_flame`（冥河鬼火）、`fx_crack_mark`
> （趁隙破勢裂痕）4 張，優先度次之，詳見 `docs/ANIM_PLAN.md` P2 表。

---

## 十六、新遺物圖示（🔴 11 件待補，2026-07-09 遺物設計優化批次）

遺物設計優化（`docs/design/RELIC_DESIGN.md`，源自 STS 遺物參考表差距分析）新增 11 件遺物。
圖檔路徑：`assets/art/relics/<id>.png`，**去背水墨**（RGBA 透明、主體居中），與 §「遺物圖示更新」既有 14 件同規格；
載不到圖會自動 fallback 程序化圖示（`relic_icon.gd`），**不阻擋上線**，可分批補。

| id | 名稱 | 類型 | 建議意象 |
|---|---|---|---|
| `mu_jian` | 木劍 | 李逍遙 common 專武 | 樸拙木劍，淡棕木紋，少年習劍的第一把劍（PAL1 初始武器） |
| `yuenv_jian` | 越女劍 | 趙靈兒 common 專武 | 纖細古劍、青碧劍穗，靈氣繚繞水色調 |
| `linjia_jiansui` | 林家劍穗 | 林月如 common 專武 | 赤紅劍穗流蘇結飾，英氣俠女佩飾 |
| `baigu_nang` | 百蠱囊 | 阿奴 common 專武 | 苗銀紋繡布囊、微露蟲影，墨綠底苗疆風 |
| `kaishan_fu` | 開山符 | common 通用 | 硃砂「開山」符籙，金橙色劈石氣勁 |
| `poyao_sha` | 破妖砂 | common 通用 | 掌中一撮金砂揚出，破邪光點 |
| `tongqian_jian` | 銅錢劍 | common 通用 | 紅繩串銅錢成劍形，民俗法器 |
| `yu_puti_zhu` | 玉菩提珠 | rare 取捨遺物 | 溫潤玉質菩提念珠（正史：鎮獄明王身上九顆），金光內斂帶一絲佛威 |
| `kezhan_yaopai` | 客棧腰牌 | uncommon run 層 | 木製客棧腰牌刻紋（餘杭客棧意象），繫繩 |
| `qiankun_dai` | 乾坤袋 | uncommon run 層 | 鼓脹錦囊、銅錢隱現，袋口束繩金線 |
| `xingshen_cha` | 醒神茶 | uncommon run 層 | 青瓷茶盞、裊裊熱氣凝成靈光 |

> 完成後 `godot --headless --path . --import` 重匯入即生效。

---

## 補圖規格

- 格式：PNG，存於 `assets/art/cards/<id>.png`（卡圖）或 `assets/art/<檔名>.png`（背景）；UI 圖示存 `assets/ui/<檔名>.png`，藥品圖示存 `assets/art/potions/<檔名>.png`，Boss 劇情圖存 `assets/art/story/<boss_id>.png`
- **去背規範**：
  - **需去背（透明背景 RGBA）**：卡圖、藥品圖、遺物圖示、UI／意圖 icon、敵人／角色肖像（主體居中、四周透明）。
  - **不需去背（畫滿背景）**：戰鬥背景、地圖背景、**Boss 劇情圖**。
  - 去背工具可用 `C:\Users\sean.wu\source\repos\BgRemover`。
- 完成後補 `.import` 配置（`godot --headless --path . --import`）
