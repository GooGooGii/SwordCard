import { describe, expect, it } from "vitest";
import { titleFraming } from "../../src/menu/titleFraming";

describe("title still-life framing", () => {
  it.each([[1280,720], [844,390], [390,727], [360,800]])(
    "keeps the manuscript ahead of fog and clipping at %ix%i",
    (width,height) => {
      const framing = titleFraming(width,height);
      const objectDistance = Math.hypot(6.3,7.3) * framing.fit;
      expect(objectDistance).toBeLessThan(framing.fogNear);
      expect(framing.fogFar).toBeLessThan(framing.cameraFar);
    }
  );
  it("preserves the approved landscape fog distances", () => {
    expect(titleFraming(844,390)).toEqual({fit:1,fogNear:12,fogFar:23,cameraFar:50});
  });
});
