import * as THREE from "three";

/**
 * 國風厚塗的 3D 著色：分階明暗（toon）＋輪廓光。
 * AI 生成的模型來源不一，統一換成這個材質，讓所有角色像同一隻手畫出來的。
 */

let toneRamp: THREE.DataTexture | null = null;

/** 3 階明暗：暗部不死黑（保留 0.42），中間調寬，亮部乾淨。 */
function getToneRamp(): THREE.DataTexture {
  if (toneRamp) return toneRamp;
  const steps = [107, 186, 255];
  const data = new Uint8Array(steps.length * 4);
  steps.forEach((v, i) => data.set([v, v, v, 255], i * 4));
  toneRamp = new THREE.DataTexture(data, steps.length, 1, THREE.RGBAFormat);
  toneRamp.minFilter = THREE.NearestFilter;
  toneRamp.magFilter = THREE.NearestFilter;
  toneRamp.generateMipmaps = false;
  toneRamp.needsUpdate = true;
  return toneRamp;
}

export interface ToonOptions {
  rimColor?: THREE.ColorRepresentation;
  rimStrength?: number;
  rimPower?: number;
}

export function makeToonMaterial(source: THREE.Material, options: ToonOptions = {}): THREE.MeshToonMaterial {
  const src = source as THREE.MeshStandardMaterial;
  const material = new THREE.MeshToonMaterial({
    map: src.map ?? null,
    color: src.color ? src.color.clone() : new THREE.Color(0xffffff),
    gradientMap: getToneRamp(),
    transparent: src.transparent,
    alphaTest: src.alphaTest,
    side: src.side,
  });
  const rimColor = new THREE.Color(options.rimColor ?? "#ffe2b0");
  const rimStrength = options.rimStrength ?? 0.35;
  const rimPower = options.rimPower ?? 3.0;
  material.onBeforeCompile = (shader) => {
    shader.uniforms.rimColor = { value: rimColor };
    shader.uniforms.rimStrength = { value: rimStrength };
    shader.uniforms.rimPower = { value: rimPower };
    shader.fragmentShader = shader.fragmentShader
      .replace(
        "#include <common>",
        "#include <common>\nuniform vec3 rimColor;\nuniform float rimStrength;\nuniform float rimPower;",
      )
      .replace(
        "#include <emissivemap_fragment>",
        [
          "#include <emissivemap_fragment>",
          "float rimFacing = 1.0 - saturate(dot(normalize(vViewPosition), normal));",
          "totalEmissiveRadiance += rimColor * rimStrength * pow(rimFacing, rimPower);",
        ].join("\n"),
      );
  };
  material.name = `${source.name || "material"}_toon`;
  return material;
}

/** 把模型裡所有網格換成國風著色，並開啟投影與收影。 */
export function applyToon(root: THREE.Object3D, options: ToonOptions = {}): void {
  root.traverse((node) => {
    const mesh = node as THREE.Mesh;
    if (!mesh.isMesh) return;
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    mesh.material = Array.isArray(mesh.material)
      ? mesh.material.map((m) => makeToonMaterial(m, options))
      : makeToonMaterial(mesh.material, options);
  });
}
