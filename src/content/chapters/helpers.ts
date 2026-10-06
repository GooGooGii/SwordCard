import type { BattleNode, NodeDef } from "../../core/run/types";

/** 章節節點的簡寫。pos 是章節地圖上的位置（0..1，左上為原點）。 */
type Pos = [number, number];

export const storyNode = (id: string, label: string, pos: Pos, next: string[], story = id): NodeDef => ({ id, kind: "story", label, pos, next, story });

export const eventNode = (id: string, label: string, pos: Pos, next: string[], story = id): NodeDef => ({ id, kind: "event", label, pos, next, story, optional: true });

export const battleNode = (id: string, label: string, pos: Pos, next: string[], battle: BattleNode, optional = false): NodeDef =>
  optional ? { id, kind: "battle", label, pos, next, battle, optional } : { id, kind: "battle", label, pos, next, battle };

export const innNode = (id: string, name: string, pos: Pos, next: string[]): NodeDef => ({ id, kind: "inn", label: name, pos, next, inn: { name } });
