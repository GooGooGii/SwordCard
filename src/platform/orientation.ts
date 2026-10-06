type LockableOrientation = ScreenOrientation & { lock?: (orientation: 'landscape') => Promise<void> };

export function isTouchDevice(): boolean {
  return window.matchMedia('(hover: none) and (pointer: coarse)').matches;
}

/** Invoke directly from a user click: browsers require transient activation. */
export async function enterLandscape(): Promise<'locked' | 'manual'> {
  const orientation = screen.orientation as LockableOrientation | undefined;
  if (!orientation?.lock) return 'manual';
  try {
    if (!document.fullscreenElement) {
      if (!document.documentElement.requestFullscreen) return 'manual';
      await document.documentElement.requestFullscreen();
    }
    await orientation.lock('landscape');
    return 'locked';
  } catch {
    // Fullscreen and orientation can be denied by browser, OS or embedding policy.
    return 'manual';
  }
}
