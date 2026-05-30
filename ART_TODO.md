# 卡圖待補清單

共 **30 張**卡片需要補圖，分兩類：

---

## 一、共用佔位圖（21 張）

以下 21 張卡的圖檔 MD5 相同（`6280feb97b822c3afc00cac86e401318`，493,175 bytes），
實際上全部使用同一張佔位圖，每張都需獨立製圖。

### 李逍遙（5 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `lxy_jianzhen` | 劍陣 | uncommon | 攻擊 |
| `lxy_jiulong` | 九龍訣 | rare | 攻擊 |
| `lxy_liepo` | 裂魄斬 | uncommon | 攻擊 |
| `lxy_qingfeng` | 清風御劍 | uncommon | 技能 |
| `lxy_zuilong` | 醉龍翻江 | rare | 攻擊 |

### 趙靈兒（5 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `zl_huihun` | 回魂咒 | rare | 技能 |
| `zl_leiguang` | 雷光連擊 | basic | 攻擊 |
| `zl_lingxi` | 靈息術 | uncommon | 技能 |
| `zl_shenlei` | 神雷降世 | rare | 攻擊（全體） |
| `zl_shuiling` | 水靈護罩 | uncommon | 技能 |

### 林月如（6 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `lyr_kuaijian` | 輕劍急刺 | uncommon | 攻擊 |
| `lyr_poqian` | 破千謀 | uncommon | 攻擊 |
| `lyr_tianv` | 天女散花 | uncommon | 攻擊（全體） |
| `lyr_tieyi` | 鐵衣功 | rare | 技能 |
| `lyr_xuanjian` | 旋劍花舞 | basic | 攻擊 |

### 阿奴（6 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `anu_baizu` | 百足蠱 | uncommon | 技能 |
| `anu_baozhagu` | 爆炸蠱 | uncommon | 攻擊 |
| `anu_duzhen` | 毒針連射 | uncommon | 攻擊 |
| `anu_gushen` | 蠱神附體 | rare | 能力 |
| `anu_guwang` | 蠱王號令 | uncommon | 技能 |
| `anu_sanmao` | 三毛蠱 | uncommon | 技能 |

---

## 二、完全缺圖（8 張）

以下卡片在 `assets/art/cards/` 中找不到對應 PNG，遊戲內會顯示空白。
皆為後期新增的全體型招式。

### 李逍遙（2 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `lxy_xuanfengjian` | 旋風劍氣 | uncommon | 攻擊（全體） |
| `lxy_qunying` | 群英斬 | rare | 攻擊（全體） |

### 趙靈兒（3 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `zl_leizhen` | 天雷陣 | uncommon | 攻擊（全體） |
| `zl_xuanbingfeng` | 玄冰封 | uncommon | 技能（全體） |
| `zl_shuifeng` | 水靈封印 | uncommon | 攻擊 |

### 林月如（2 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `lyr_xuanfengzhan` | 旋風連斬 | uncommon | 攻擊（全體） |
| `lyr_pojian` | 破陣劍勢 | uncommon | 技能（全體） |

### 阿奴（2 張）

| ID | 招式名 | 稀有度 | 類型 |
|---|---|---|---|
| `anu_duwuman` | 毒霧漫天 | uncommon | 技能（全體） |
| `anu_qundubao` | 群蟲爆 | rare | 攻擊（全體） |

---

## 補圖規格

- 尺寸：與現有卡圖一致（檢查任一已有圖的解析度）
- 格式：PNG，存於 `assets/art/cards/<id>.png`
- 完成後記得同步 `.import` 配置（`godot --headless --path . --import`）
