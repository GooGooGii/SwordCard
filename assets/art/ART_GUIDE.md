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
  Used by the battle scene.
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

## Planned UI Assets

Suggested paths:

- `assets/ui/card_frame_attack.png`
- `assets/ui/card_frame_skill.png`
- `assets/ui/card_frame_power.png`
- `assets/ui/node_battle.png`
- `assets/ui/node_rest.png`
- `assets/ui/node_event.png`
- `assets/ui/node_boss.png`

Target:

- Prefer PNG for painterly frames and icons
- Keep icon silhouettes simple enough for Android screen sizes
