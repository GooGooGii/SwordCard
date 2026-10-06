import { useEffect } from "react";
import { completeStory } from "../core/run";
import { setVolumes } from "../platform/audio";
import { useSettings } from "../game/settings";
import { game, useRun } from "../game/store";
import { BattleScreen } from "./battle/BattleScreen";
import { MapScreen } from "./map/MapScreen";
import { InnScreen } from "./screens/InnScreen";
import { RewardScreen } from "./screens/RewardScreen";
import { BattleLostScreen, ChapterIntroScreen, EndingScreen } from "./screens/SmallScreens";
import { StoryScreen } from "./story/StoryScreen";
import "./ui.css";

/** 正式遊戲：依行程的 pending 決定顯示哪個畫面（狀態全在 core，畫面只讀） */
export function GameRoot() {
  const run = useRun();
  const settings = useSettings();
  useEffect(() => setVolumes(settings.music, settings.sfx), [settings.music, settings.sfx]);
  if (!run) return null;
  const p = run.pending;
  let screen;
  switch (p.kind) {
    case "chapter_intro":
      screen = <ChapterIntroScreen key={`ch${p.chapter}`} run={run} />;
      break;
    case "map":
      screen = <MapScreen run={run} />;
      break;
    case "story":
      screen = (
        <StoryScreen
          key={`${p.nodeId}:${p.storyId}`}
          storyId={p.storyId}
          flags={run.flags}
          onDone={(choices) => game.update((db, r) => completeStory(db, r, choices))}
        />
      );
      break;
    case "battle":
      screen = <BattleScreen key={`${p.nodeId}:${p.attempt}`} run={run} />;
      break;
    case "battle_lost":
      screen = <BattleLostScreen run={run} />;
      break;
    case "reward":
      screen = <RewardScreen key={p.nodeId} run={run} />;
      break;
    case "inn":
      screen = <InnScreen run={run} />;
      break;
    case "ending":
      screen = <EndingScreen run={run} />;
      break;
  }
  return (
    <div className="game-root" style={{ ["--ui-scale" as string]: settings.fontScale }}>
      {screen}
    </div>
  );
}
