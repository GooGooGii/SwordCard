import type { ChapterDef } from "../../core/run/types";
import { CH1, CH2, CH3, PROLOGUE } from "./early";
import { CH4, CH5, CH6, CH7, FINALE } from "./late";

/** 全九章，依正史順序（REDESIGN §3） */
export const CHAPTERS: ChapterDef[] = [PROLOGUE, CH1, CH2, CH3, CH4, CH5, CH6, CH7, FINALE];
