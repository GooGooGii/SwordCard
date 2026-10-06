import * as THREE from 'three';
import { PAL_SCENE_RECIPES, type PalSceneId } from './palSceneRecipes';
import { palSurface } from './palSurface';
import { addPalProps } from './palProps';

export function buildPalScenery(id: PalSceneId) {
  const recipe = PAL_SCENE_RECIPES[id];
  const group = new THREE.Group(); group.name = `pal-${id}`;
  const material = palSurface(recipe);
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(40, 40), material);
  ground.rotation.x = -Math.PI / 2; ground.position.y = -.012;
  ground.name = 'pal-ground'; group.add(ground);
  addPalProps(group, recipe);
  let disposed = false;
  return {
    group,
    update(time: number, reducedMotion = false) { material.uniforms.time!.value = reducedMotion ? 0 : time; },
    dispose() {
      if (disposed) return; disposed = true;
      group.traverse(object => {
        if (!(object instanceof THREE.Mesh)) return;
        object.geometry.dispose();
        const materials = Array.isArray(object.material) ? object.material : [object.material];
        materials.forEach(item => item.dispose());
      });
    },
  };
}
