/** Keep fog and clipping beyond the still life when portrait framing pulls back. */
export function titleFraming(width: number, height: number) {
  const aspect = Math.max(1, width) / Math.max(1, height);
  const fit = Math.max(1, 1.35 / aspect);
  return { fit, fogNear: 12 * fit, fogFar: 23 * fit, cameraFar: 50 * fit };
}
