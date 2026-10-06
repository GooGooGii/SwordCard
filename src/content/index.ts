import type { GameDb } from "../core/run/db";
import { CARDS, STARTERS } from "./cards";
import { CHAPTERS } from "./chapters";
import { CHARACTERS } from "./characters";
import { ENEMIES } from "./enemies";
import { RELICS } from "./relics";
import { STORIES } from "./stories";

/** 整個遊戲的內容資料庫：core 的 reducer 只透過它讀內容 */
export const GAME_DB: GameDb = {
  cards: CARDS,
  enemies: ENEMIES,
  characters: CHARACTERS,
  chapters: CHAPTERS,
  stories: STORIES,
  relics: RELICS,
  starters: Object.fromEntries(Object.entries(STARTERS).map(([id, list]) => [id, [...list]])) as GameDb["starters"],
};
