import type { EnemyDef } from "../../core/types";
import { EARLY_ENEMIES } from "./early";
import { byId } from "./helpers";
import { LATE_ENEMIES } from "./late";
import { MIDDLE_ENEMIES } from "./middle";

export const ALL_ENEMIES: EnemyDef[] = [...EARLY_ENEMIES, ...MIDDLE_ENEMIES, ...LATE_ENEMIES];
export const ENEMIES: Record<string, EnemyDef> = byId(ALL_ENEMIES);
