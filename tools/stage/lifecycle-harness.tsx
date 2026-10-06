// 僅開發服務的獨立 QA 入口，不加入遊戲 production 入口。
import { StrictMode, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { BattleStage } from '../../src/stage/BattleStage';
import { BATTLE_SCENE_IDS } from '../../src/stage/scenes/catalog';

function Harness() {
  const [scene, setScene] = useState('blood_pool');
  const [active, setActive] = useState(true);
  const [quality, setQuality] = useState<'high' | 'low'>('low');
  const [target, setTarget] = useState<HTMLSpanElement | null>(null);
  return <>
    <div style={{ height: 42, display: 'flex', gap: 10, alignItems: 'center' }}>
      <button onClick={() => setScene('blood_pool')}>blood_pool</button>
      <button onClick={() => setScene('shilipo')}>shilipo</button>
      <select aria-label="scene" value={scene} onChange={e => setScene(e.target.value)}>{BATTLE_SCENE_IDS.map(id => <option key={id}>{id}</option>)}</select>
      <button onClick={() => setActive(a => !a)}>{active ? 'hide' : 'show'}</button>
      <button onClick={() => setQuality(q => q === 'low' ? 'high' : 'low')}>{quality}</button>
      <span ref={setTarget} />
    </div>
    <div hidden={!active} style={{ width: '100vw', height: 'calc(100vh - 42px)' }}>
      <BattleStage sceneId={scene} active={active} quality={quality} actors={[]} focus={null} popups={[]} perfTarget={target} htmlOverlays={false} />
    </div>
  </>;
}

createRoot(document.getElementById('root')!).render(<StrictMode><Harness /></StrictMode>);
