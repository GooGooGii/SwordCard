# 卡圖待補清單

最後更新：重新掃描 `assets/art/cards/` 與 `game_data.gd` 後的完整結果。

---

## 一、共用佔位圖（21 張）

以下 21 張卡的圖檔 MD5 完全相同（同一張佔位圖），每張都需獨立製圖。

### 李逍遙（5 張）

| ID | 招式名 | 稀有度 |
|---|---|---|
| `lxy_jianzhen` | 劍陣 | uncommon |
| `lxy_jiulong` | 九龍訣 | rare |
| `lxy_liepo` | 裂魄斬 | uncommon |
| `lxy_qingfeng` | 清風御劍 | uncommon |
| `lxy_zuilong` | 醉龍翻江 | rare |

### 趙靈兒（5 張）

| ID | 招式名 | 稀有度 |
|---|---|---|
| `zl_huihun` | 還魂咒 | rare |
| `zl_leiguang` | 雷光連擊 | basic |
| `zl_lingxi` | 靈息術 | uncommon |
| `zl_shenlei` | 神雷降世 | rare |
| `zl_shuiling` | 水靈護罩 | uncommon |

### 林月如（5 張）

| ID | 招式名 | 稀有度 |
|---|---|---|
| `lyr_kuaijian` | 輕劍急刺 | uncommon |
| `lyr_poqian` | 破千謀 | uncommon |
| `lyr_tianv` | 飛花亂舞 | uncommon |
| `lyr_tieyi` | 鐵衣功 | rare |
| `lyr_xuanjian` | 旋劍花舞 | basic |

### 阿奴（6 張）

| ID | 招式名 | 稀有度 |
|---|---|---|
| `anu_baizu` | 百足蠱 | uncommon |
| `anu_baozhagu` | 爆炸蠱 | uncommon |
| `anu_duzhen` | 毒針連射 | uncommon |
| `anu_gushen` | 蠱神附體 | rare |
| `anu_guwang` | 蠱王號令 | uncommon |
| `anu_sanmao` | 三毛蠱 | uncommon |

---

## 二、跨角色共用圖（需確認）

以下兩張卡 PNG 內容完全一樣，但兩張卡都有各自的定義。
若設計上本來就要共用同一張圖，請在 `game_data.gd` 的 `zl_bingxin` 加上 `art_id="lxy_bingxin"` 明確標示；
若兩個角色應有各自的圖，則 `zl_bingxin` 需補新圖。

| ID | 招式名 | 角色 |
|---|---|---|
| `lxy_bingxin` | 冰心訣 | 李逍遙 |
| `zl_bingxin` | 冰心訣 | 趙靈兒 |

---

## 三、孤兒圖（有圖無卡，可清理或留待未來）

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

---

## 補圖規格

- 格式：PNG，存於 `assets/art/cards/<id>.png`
- 完成後補 `.import` 配置（`godot --headless --path . --import`）
