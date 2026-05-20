# SwordCard Development Plan

## Project Direction

SwordCard is a private fan prototype built with Godot 4 for Windows and Android. It uses the four main Chinese Paladin 1 characters and move names as a learning/demo project, not for public release or commercial distribution.

The game direction is a xianxia card battler inspired by Slay the Spire: turn-based combat, draw/discard piles, energy, enemy intents, character-specific decks, and expandable card rewards.

## Current Version: Core Battle Prototype

Implemented:

- Godot 4 project setup.
- Main menu.
- Character selection.
- Single battle scene.
- Victory and defeat result screen.
- Four playable characters:
  - 李逍遙
  - 趙靈兒
  - 林月如
  - 阿奴
- Character-specific starting decks using original-style move names.
- Enemy pool:
  - 山賊頭目
  - 山林妖獸
  - 蠱毒妖人
  - 拜月教徒
- Core card battle loop:
  - Draw 5 cards each turn.
  - Recover 3 energy each turn.
  - Play cards by clicking.
  - Discard hand at end of turn.
  - Reshuffle discard pile when draw pile is empty.
  - Enemy intent and enemy action sequence.
- Effects:
  - Damage
  - Block
  - Heal
  - Poison
  - Weak
  - Vulnerable
  - Draw
  - Energy gain
  - Self damage
  - Combat power
  - Consume-energy damage
  - Poison burst

## Current Version: Mini Run

Goal: turn the single battle prototype into a short playable run.

Implemented:

- Run state that persists between battles:
  - Selected character
  - Current HP
  - Current deck
  - Encounter index
- 4 route-map layers:
  - First 3 layers each offer 2 route choices.
  - Final layer is a fixed small boss fight.
- Route node types:
  - Battle
  - Rest
  - Event
  - Boss
- Rest nodes restore 25% max HP.
- Event nodes offer:
  - Heal 8 HP.
  - Lose 6 HP and gain 1 random reward card.
  - Gain +1 damage for the rest of the run.
  - Remove 1 card from the current deck, while keeping at least 5 cards.
  - Upgrade 1 card.
- Post-battle card reward screen:
  - Show 3 random reward cards.
  - Player chooses 1 card to add to deck.
  - Player may skip the reward.
- Route progress screen:
  - Show current layer number.
  - Show player HP and deck size.
  - Show available enemy route choices.
- Deck changes persist across the run.
- HP persists between fights.
- Deck view overlay is available from progress, battle, and reward screens.

## Deck View

Implemented:

- Shows the current run deck without leaving the current screen.
- Displays total deck size and card type summary.
- Displays duplicate card counts.
- Displays upgradeable card count.
- Uses the same card coloring as battle and reward cards.
- Can be opened from:
  - Progress screen
  - Battle screen
  - Card reward screen

Still planned:

- Sorting and filtering by card type.
- Group duplicate cards with counts.
- Show draw pile, hand, discard pile, and exhausted pile separately during battle.

## Deck Management

Implemented:

- Card rewards are unique within a single reward choice set.
- Event node can remove one card from the current run deck.
- Removal mode reuses the deck overlay and advances after a card is selected.
- Deck removal is blocked at 5 cards to avoid invalid tiny decks.
- Rest and event nodes can upgrade one card.
- Upgraded cards display `+` and improve numeric effects.

Still planned:

- Dedicated card removal events with cost/benefit variants.
- Transform cards.
- Show card counts as grouped stacks instead of repeated individual cards.

## Card Upgrades

Implemented:

- Cards track whether they are upgraded.
- Upgraded cards display a `+` suffix.
- Upgraded cards clone safely through deck setup and rewards.
- Numeric effects are strengthened:
  - Damage, block, and heal gain a percentage-style bump.
  - Draw, energy, weak, poison, vulnerable, and power gain fixed increases.
  - Consume-energy and poison-burst scaling increase.

Still planned:

- Bespoke upgrade text per card.
- Upgrade preview before selecting a card.
- Card art or frame treatment for upgraded cards.

## Character Passives

Implemented passive abilities:

- 李逍遙: first attack card each battle costs 1 less energy.
- 趙靈兒: heal 3 HP at the start of each battle.
- 林月如: first time she gains block each turn, deal 3 damage.
- 阿奴: enemies start each battle with 3 poison.

These passives are implemented through battle setup, card cost, and card-play hooks without adding special effect definitions to individual cards.

## UI Improvements

Implemented polish:

- Improved card layout for battle and reward cards.
- Clearer colors by card type:
  - Attack
  - Skill
  - Power
- Disabled styling for unaffordable cards.
- Simple xianxia-themed panel and button colors.
- More readable player HUD and enemy intent text.
- Battle feedback text for damage, healing, block, poison, weak, and vulnerable changes.
- Enemy intent text badges:
  - Attack
  - Defense
  - Status

Still planned:

- Add simple card play animation.
- Add damage/heal floating text.
- Add real background art and portraits.
- Replace text intent badges with icons once art direction is stable.

## Art Pipeline

Implemented:

- Created project art directories:
  - `assets/art`
  - `assets/ui`
- Added generated xianxia-style background assets:
  - `assets/art/main_menu_bg.png`
  - `assets/art/battle_bg.png`
  - `assets/art/event_bg.png`
- Wired backgrounds into the main menu, character select, route, event, reward, result, and battle screens.
- Added `assets/art/ART_GUIDE.md` with asset naming and size targets.
- Made panels semi-transparent so background art remains visible under UI.

Still planned:

- Character portraits for the four playable characters.
- Enemy portraits.
- Card frames for attack, skill, and power cards.
- Route node icons for battle, rest, event, and boss.
- More bespoke event illustrations.

## Verification Checklist

Before considering the next version complete:

- Godot project loads from CLI:
  - `godot --headless --path C:\Users\USER\source\repos\SwordCard --quit`
- Main scene starts without errors.
- Each character can complete a 4-battle run.
- Card rewards correctly modify the current deck.
- HP persists between battles.
- Victory appears after the boss.
- Defeat appears when player HP reaches 0.
- No warnings are promoted into blocking errors.

## Later Ideas

- Better map visuals with connected nodes and route history.
- More event variants and event art.
- Shops.
- Relics or accessories.
- Story event nodes.
- Save/load.
- Better card art and character portraits.
- Android export testing on a real device.
