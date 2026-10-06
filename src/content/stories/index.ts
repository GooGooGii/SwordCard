import type { StoryDef } from "../../core/run/types";
import { CH1_STORIES } from "./ch1";
import { CH2_STORIES } from "./ch2";
import { CH3_STORIES } from "./ch3";
import { CH4_STORIES } from "./ch4";
import { CH5_STORIES } from "./ch5";
import { CH6_STORIES } from "./ch6";
import { CH7_STORIES } from "./ch7";
import { FINALE_STORIES } from "./finale";
import { PROLOGUE_STORIES } from "./prologue";

export const ALL_STORIES: StoryDef[] = [
  ...PROLOGUE_STORIES,
  ...CH1_STORIES,
  ...CH2_STORIES,
  ...CH3_STORIES,
  ...CH4_STORIES,
  ...CH5_STORIES,
  ...CH6_STORIES,
  ...CH7_STORIES,
  ...FINALE_STORIES,
];

export const STORIES: Record<string, StoryDef> = Object.fromEntries(ALL_STORIES.map((s) => [s.id, s]));
