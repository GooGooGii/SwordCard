import { useEffect, useRef, useState } from 'react';
import { enterLandscape, isTouchDevice } from '../platform/orientation';
import './mobile-orientation.css';

export function MobileOrientation() {
  const [portrait, setPortrait] = useState(() => isTouchDevice() && innerHeight > innerWidth);
  const [dismissed, setDismissed] = useState(false);
  const [manual, setManual] = useState(false);
  const [busy, setBusy] = useState(false);
  const pending = useRef(false);

  useEffect(() => {
    const update = () => {
      const next = isTouchDevice() && innerHeight > innerWidth;
      setPortrait(next);
      if (!next) setDismissed(false);
    };
    const start = (event: MouseEvent) => {
      if (isTouchDevice() && (event.target as Element)?.closest?.('.story-choice')) void request();
    };
    window.addEventListener('resize', update);
    document.addEventListener('click', start, true);
    return () => {
      window.removeEventListener('resize', update);
      document.removeEventListener('click', start, true);
    };
  }, []);

  async function request() {
    if (pending.current) return;
    pending.current = true;
    setBusy(true);
    const result = await enterLandscape();
    setManual(result === 'manual');
    setBusy(false);
    pending.current = false;
  }

  if (!portrait || dismissed) return null;
  return <aside className="mobile-orientation" role="dialog" aria-modal="true" aria-label="橫向遊玩">
    <div className="mobile-orientation-panel">
      <div className="mobile-orientation-phone" aria-hidden="true">↻</div>
      <h2>橫向遊玩</h2>
      <p>{manual ? '此瀏覽器無法自動轉向，請將手機轉為橫向。' : '點一下，切換為橫向全螢幕。'}</p>
      <button disabled={busy} onClick={() => void request()}>{busy ? '切換中…' : '橫向全螢幕'}</button>
      <button className="mobile-orientation-skip" onClick={() => setDismissed(true)}>先繼續查看</button>
    </div>
  </aside>;
}
