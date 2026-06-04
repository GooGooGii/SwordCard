# 卡圖待補清單

最後更新：2026-06-04（已補齊全部 27 張借圖卡牌的專屬插畫）

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

## 補圖規格

- 格式：PNG，存於 `assets/art/cards/<id>.png`
- 完成後補 `.import` 配置（`godot --headless --path . --import`）
