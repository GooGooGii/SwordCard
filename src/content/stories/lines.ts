import type { CharId } from "../../core/types";
import type { Reward, StoryDef, StoryStep } from "../../core/run/types";

/**
 * 劇本的簡寫。台詞全部是本作重寫（REDESIGN §5：忠於正史事件，不照抄原作劇本）。
 * 表情：平常（不寫）、smile 笑、angry 怒、surprise 驚、sad 哀、resolve 決意。
 */
export type Expr = "smile" | "angry" | "surprise" | "sad" | "resolve";
type Line = (text: string, expr?: Expr) => StoryStep;

const speaker =
  (who: string): Line =>
  (say, expr) =>
    expr ? { who, say, expr } : { who, say };

// 主角
export const li = speaker("li_xiaoyao");
export const ling = speaker("zhao_linger");
export const yue = speaker("lin_yueru");
export const anu = speaker("anu");
export const wuhou = speaker("wuhou");
// 配角（id 對應 content/characters.ts 的 NPCS）
export const aunt = speaker("aunt");
export const drunk = speaker("drunk");
export const granny = speaker("granny");
export const miaoLeader = speaker("miao_leader");
export const fatMiao = speaker("fat_miao");
export const linTiannan = speaker("lin_tiannan");
export const jinyuan = speaker("liu_jinyuan");
export const caiyi = speaker("caiyi");
export const shi = speaker("shi_zhanglao");
export const saint = speaker("sword_saint");
export const shenggu = speaker("shenggu");
export const gai = speaker("gai_luojiao");
export const baiyue = speaker("baiyue");
export const sanniang = speaker("ji_sanniang");
export const zhixiu = speaker("zhixiu");
export const villager = speaker("villager");
export const tangyu = speaker("tang_yu");
export const wuwang = speaker("wuwang");

export const n = (narrate: string): StoryStep => ({ narrate });
export const bg = (id: string): StoryStep => ({ bg: id });
export const music = (id: string): StoryStep => ({ music: id });
export const join = (id: CharId): StoryStep => ({ join: id });
export const leave = (id: CharId, permanent = false): StoryStep => (permanent ? { leave: id, permanent } : { leave: id });
export const reward = (r: Reward): StoryStep => ({ reward: r });
export const bond = (id: CharId, amount: number): StoryStep => ({ bond: id, amount });
export const flag = (name: string): StoryStep => ({ flag: name });
export const when = (name: string, then: StoryStep[], otherwise?: StoryStep[]): StoryStep =>
  otherwise ? { when: name, then, otherwise } : { when: name, then };
export const choice = (...options: [string, StoryStep[]][]): StoryStep => ({
  choice: options.map(([text, then]) => ({ text, then })),
});
export const healAll: StoryStep = { heal: "full" };

export const story = (id: string, background: string, steps: StoryStep[], bgm?: string): StoryDef =>
  bgm ? { id, bg: background, music: bgm, steps } : { id, bg: background, steps };
