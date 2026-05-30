# SwordCard Art Guide

## Current Art Direction

- Style: 2D painted xianxia fantasy, ink-wash atmosphere with readable game UI contrast.
- Palette: ink blue, charcoal, muted teal, jade green, antique gold, restrained red/purple accents.
- Use: private fan prototype, not public or commercial release.
- **戰鬥角色肖像設計 (Battle Character Design)**:
  - **風格簡化 (Simplified Style)**: 戰鬥中角色肖像改為 **正常比例、手繪插畫國風水墨風格**（比例同 Slay the Spire 角色，特徵鮮明、線條簡潔、色彩飽和度適度降低），而非 Q 版。與選角時的寫實水墨全身肖像區隔。
  - **左右對立構圖 (StS Layout)**: 角色居左面向右，敵人在右面向左。
  - **動態姿勢 (Dynamic Poses)**: 每個主角需要 6 種戰鬥動作姿勢，均為**強制去背/透明背景**：
    1. `idle` (待命): 基礎防守或準備架勢。
    2. `attack` (攻擊): 物理攻擊，武器揮斬或前傾出招。
    3. `cast` (施法): 單手施法指引、仙術掐指訣或引導能量。
    4. `block` (擋格): 側身護體，伴隨八卦或盾牌架勢。
    5. `low_hp` (命危): 半蹲、捂傷口喘息。
    6. `downed` (倒地): 閉眼昏迷倒下。

## Background Assets

Current generated backgrounds:

- `main_menu_bg.png`  
  Used by main menu and character select.
- `battle_bg.png`  
  Legacy fallback used by the battle scene.
- `battle_bg_act_1.png`  
  Used by act 1 battles.
- `battle_bg_act_2.png`  
  Used by act 2 battles.
- `battle_bg_act_3.png`  
  Used by act 3 battles.
- `battle_bg_act_4.png`  
  Used by act 4 battles.
- `battle_bg_act_5.png`  
  Used by act 5 battles.
- `event_bg.png`  
  Used by route, rest, event, reward, and result screens.
- `map_bg_ink.png`  
  Used by the route map screen.

Target size:

- 1280 x 720
- Route map: 1280 x 1800
- PNG
- No text, no logos, no watermarks
- Keep central negative space for UI panels

## Planned Event Story Illustrations

Suggested paths:

- `assets/art/events/[event_id].png`
  - Event IDs correspond to the types in `EventData.gd` (e.g., `shrine`, `spring`, `talisman_cache`, `treasure_chest`, `tavern_acquaintance`, `sword_tomb`, `miao_healer`, etc.)

Target:

- 1280 x 720 PNG (to fit the game resolution)
- Style: 2D painted xianxia fantasy, classic PAL1 scene-oriented story illustrations (e.g., encountering a wandering sage, the mystical moonlit pool, an ancient furnace, or the mysterious Baiyue Altar).
- Composition: Restrained detail in the center/sides where event options and dialogue text boxes are overlaid, ensuring text remains highly legible.

## Planned Character Portraits


Suggested paths:

- `assets/art/portraits/li_xiaoyao.png`
- `assets/art/portraits/zhao_linger.png`
- `assets/art/portraits/lin_yueru.png`
- `assets/art/portraits/anu.png`

Target:

- 768 x 1024 portrait PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，以便與遊戲戰鬥及主選單背景完美融合。

## Planned Enemy Portraits

Suggested paths:

- `assets/art/enemies/bandit.png`
- `assets/art/enemies/beast.png`
- `assets/art/enemies/gu_cultist.png`
- `assets/art/enemies/moon_worshipper.png`
- `assets/art/enemies/sword_spirit.png`
- `assets/art/enemies/fox_spirit.png`
- `assets/art/enemies/serpent_demon.png`
- `assets/art/enemies/centipede_lord.png`
- `assets/art/enemies/witch_queen.png`

Target:

- 768 x 768 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，便於在戰鬥場景中渲染。
- Clear silhouette
- Readable at small in-game size

## Planned Battle Character Portraits

Suggested paths:

- `assets/art/battle_characters/[character_id]_[pose].png`
  - Poses: `idle`, `attack`, `cast`, `block`, `low_hp`, `downed`
  - Character IDs: `li_xiaoyao`, `zhao_linger`, `lin_yueru`, `anu`

Target:

- 768 x 768 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景。
- 角色朝向：面朝右方（StS 戰鬥左側玩家向）。

## Planned Potion Icons

Suggested paths:

- `assets/art/potions/huichun_dan.png` (回春丹)
- `assets/art/potions/lingli_dan.png` (靈力丹)
- `assets/art/potions/huti_fu.png` (護體符)
- `assets/art/potions/jiedu_san.png` (解毒散)
- `assets/art/potions/lingshe_dan.png` (靈蛇膽)
- `assets/art/potions/hugu_jiu.png` (虎骨酒)
- `assets/art/potions/jinchuang_yao.png` (金瘡藥)
- `assets/art/potions/tianling_dan.png` (天靈丹)
- `assets/art/potions/xianren_xue.png` (仙人遺血)
- `assets/art/potions/yuehun_cao.png` (月魂草)
- `assets/art/potions/baihua_xianniang.png` (百花仙釀)

Target:

- 512 x 512 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，便於在戰鬥列及商店中渲染。
- Style: 2D hand-painted Chinese ink-wash style, watercolor texture, clean ink outlines, matching the relic style.

## Planned UI Assets

Suggested paths:

- `assets/ui/card_frame_attack.png`
- `assets/ui/card_frame_skill.png`
- `assets/ui/card_frame_power.png`
- `assets/ui/node_battle.png` ( Crossed Chinese Swords - 水墨雙劍 )
- `assets/ui/node_shop.png` ( Copper Coin - 水墨金銅錢 )
- `assets/ui/node_black_shop.png` ( Dark Copper Coin - 暗黑紫煙銅錢 )
- `assets/ui/node_event.png` ( Mysterious Scroll - 國風水墨古卷 )
- `assets/ui/node_rest.png` ( Campfire - 篝火營地 )
- `assets/ui/node_boss.png` ( Yaoguai Demon Mask - 猙獰山魈魔臉 )

Target:

## 美術狀態 (Art Status)

> **現況**：所有新增卡牌與專屬遺物已成功補齊對應的美術資源，並已移除代碼中的「借圖」暫代方案。

### 美術統計

| 類別 | 缺圖數 | 狀態 | 優先級 |
|---|---|---|---|
| 流派 / 新機制卡（CARD_DESIGN ch.3-4） | 0 | 已完成專屬插圖 | 🟢 已完成 |
| 等級解鎖卡（LevelSystem） | 0 | 已完成專屬插圖 | 🟢 已完成 |
| 角色專武遺物 | 0 | 已補齊專屬圖示 | 🟢 已完成 |
| **合計** | **0** | | |

### 🔴 流派／新機制卡（8 張）

所有卡片皆已補齊專屬 2D 水墨國風插畫：
- `anu_cuifeng` (淬鋒蠱刃)
- `anu_wuyuezhan` (巫月斬)
- `anu_xuerenwu` (血刃亂舞)
- `lxy_wanjianguizong` (萬劍歸宗)
- `lyr_fenghuan` (鳳鳴反擊)
- `lyr_yuehua` (月華護體)
- `zl_shuiyin` (水靈封印)
- `zl_ganlin` (甘霖咒)

### 🟡 等級解鎖卡（27 張）

所有解鎖卡牌皆已擁有專屬卡圖，不再依賴其他卡牌插畫：
- **李逍遙 (8 張)**: `lxy_tiangangqi` (天罡戰氣)、`lxy_ningyuan_ls` (凝神歸元)、`lxy_yuanlinggui` (元靈歸心術)、`lxy_zhenyuan` (真元護體)、`lxy_tianjian` (天劍)、`lxy_jinchan_ls` (金蟬脫殼)、`lxy_xiaoyao_shenjian` (逍遙神劍)、`lxy_jianshen` (劍神)。
- **趙靈兒 (8 張)**: `zl_xuanfengzhou` (旋風咒)、`zl_wuleizhou` (五雷咒)、`zl_sanmeizhenhuo` (三昧真火)、`zl_fengxuebing` (風雪冰天)、`zl_diliebeng` (地裂天崩)、`zl_mengshe_ls` (夢蛇)、`zl_taishan` (泰山壓頂)、`zl_kuanglei` (狂雷)。
- **林月如 (5 張)**: `lyr_tongqianbiao` (銅錢鏢)、`lyr_qijuejianqi` (七訣劍氣)、`lyr_yuanlinggui` (元靈歸心術)、`lyr_lielong` (裂龍式)、`lyr_wanlikuang` (萬里狂沙)。
- **阿奴 (6 張)**: `anu_sanshigu` (三屍蠱)、`anu_yanshazhou` (炎殺咒)、`anu_shuhun` (贖魂)、`anu_duohun` (奪魂)、`anu_wanyi_ls` (萬蟻蝕象)、`anu_wangushitian` (萬蠱蝕天)。

### 🟡 遺物（2 件）

兩件流派錨點專屬武器已成功配置專屬圖示，並移除了程序繪製 fallback 顯示：
- `wuyue_shendao` (巫月神刀): 阿奴刀流錨點。
- `fengming_dao` (鳳鳴刀): 林月如刀流錨點。

## Card Layering Convention

Card UI should follow a fixed rendering stack so art replacements do not require layout rewrites:

1. Card art at the bottom
2. Card frame above the art
3. Decorative overlays above the frame
4. Text as the topmost layer

Decorative overlays include the mana badge, rarity badge, name plaque, and rules-panel ornaments. When replacing the three card frames with ink-wash versions, keep those elements as separate overlays unless they must be baked into the frame for a specific visual effect.

