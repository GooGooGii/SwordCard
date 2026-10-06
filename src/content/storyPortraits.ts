/** PAL1 DOS-based story portraits. Expressions must be redrawn from these identities. */
export interface StoryPortrait {
  base: string;
  expressions?: Partial<Record<string, string>>;
}
export const STORY_PORTRAITS: Record<string, StoryPortrait> = {
  li_xiaoyao: { base: "/assets/portraits/canon-v1/li_xiaoyao.webp" },
  zhao_linger: { base: "/assets/portraits/canon-v1/zhao_linger.webp" },
  lin_yueru: { base: "/assets/portraits/canon-v1/lin_yueru.webp" },
  anu: { base: "/assets/portraits/canon-v1/anu.webp" },
  drunk: { base: "/assets/portraits/canon-v1/drunk.webp" },
};
