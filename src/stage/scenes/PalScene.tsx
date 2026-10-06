import { useFrame } from '@react-three/fiber';
import { useEffect, useMemo } from 'react';
import { buildPalScenery } from './palScenery';
import type { PalSceneId } from './palSceneRecipes';

export default function PalScene({ id, quality }: { id: PalSceneId; quality: 'high' | 'low' }) {
  const scenery = useMemo(() => ({ ...buildPalScenery(id), leases: 0 }), [id]);
  useFrame(({ clock }) => scenery.update(clock.elapsedTime, quality === 'low'));
  useEffect(() => {
    scenery.leases++;
    return () => {
      scenery.leases--;
      // Per-resource lease: a new scene cannot cancel disposal of the old one.
      queueMicrotask(() => { if (scenery.leases === 0) scenery.dispose(); });
    };
  }, [scenery]);
  return <primitive object={scenery.group} dispose={null} />;
}
