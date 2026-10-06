import * as THREE from "three";
import { PAL_FORMATION } from "../formation";

const noise = /* glsl */ `
  float grainHash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
  float grainNoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(grainHash(i), grainHash(i + vec2(1., 0.)), f.x),
      mix(grainHash(i + vec2(0., 1.)), grainHash(i + vec2(1., 1.)), f.x), f.y);
  }
`;

// 以隨半徑改變的角速度搬運噪聲，細浪會隨大股水流捲入，不是旋轉等距圓環。
const vortexFlow = /* glsl */ `
  vec2 swirlPoint(vec2 q, float t) {
    float r = length(q);
    float turn = 2.5 * log(r + .35) - t * .42 / (.55 + r);
    float c = cos(turn), s = sin(turn);
    return mat2(c, -s, s, c) * q;
  }
  float vortexEdge(vec2 q, float t) {
    vec2 flow = swirlPoint(q, t);
    float ragged = (grainNoise(flow * 3.0) - .5) * .48 + (grainNoise(flow * 8.0) - .5) * .16;
    return 1.0 - smoothstep(1.08, 1.84, length(q) + ragged);
  }
  float waterHeight(vec2 p, vec2 center, float t) {
    vec2 q = p - center;
    float r = length(q);
    vec2 flow = swirlPoint(q, t);
    float swirl = grainNoise(flow * vec2(5.0, 12.0));
    float edge = vortexEdge(q, t);
    // 翻湧水面抬至袍角，外圈浪脊與中央的淺凹形成可見高差。
    float basin = .23 - .06 * exp(-r * r * 4.0);
    float chop = (swirl - .5) * .075 + sin(r * 14.0 - t * 1.3) * .016;
    return sin(p.y * 7.0 + t * .5) * .008 + edge * (basin + chop);
  }
`;

const vertex = /* glsl */ `
  varying vec3 worldPoint;
  varying vec3 worldNormal;
  void main() {
    vec4 p = modelMatrix * vec4(position, 1.0);
    worldPoint = p.xyz;
    worldNormal = normalize(mat3(modelMatrix) * normal);
    gl_Position = projectionMatrix * viewMatrix * p;
  }
`;

/** DOS 血池的紅色橫向波紋和赤鬼王腳下的金色旋流；不是貼在平面上的插畫。 */
export function bloodWaterMaterial() {
  return new THREE.ShaderMaterial({
    name: "blood-pool-ripples",
    uniforms: {
      time: { value: 0 },
      vortex: { value: new THREE.Vector2(PAL_FORMATION.enemyCenter[0], PAL_FORMATION.enemyCenter[2]) },
      deep: { value: new THREE.Color("#39090d") },
      blood: { value: new THREE.Color("#96242a") },
      crest: { value: new THREE.Color("#b84737") },
      gold: { value: new THREE.Color("#e4b440") },
      foam: { value: new THREE.Color("#fff3b5") },
    },
    vertexShader: /* glsl */ `
      uniform float time;
      uniform vec2 vortex;
      varying vec3 worldPoint;
      ${noise}
      ${vortexFlow}
      void main() {
        vec4 world = modelMatrix * vec4(position, 1.0);
        world.y += waterHeight(world.xz, vortex, time);
        worldPoint = world.xyz;
        gl_Position = projectionMatrix * viewMatrix * world;
      }
    `,
    fragmentShader: /* glsl */ `
      uniform float time;
      uniform vec2 vortex;
      uniform vec3 deep, blood, crest, gold, foam;
      varying vec3 worldPoint;
      ${noise}
      ${vortexFlow}
      void main() {
        vec2 p = worldPoint.xz;
        vec2 q = p - vortex;
        float r = length(q);
        vec2 fluid = swirlPoint(q, time);
        // 金白旋流外圍的血水也被拖動，不能在金色邊界外立刻恢復直線浪。
        vec2 waterP = mix(p, fluid + vortex, 1.0 - smoothstep(1.5, 2.8, r));
        float drift = time * .28;
        float turbulence = grainNoise(waterP * vec2(2.5, 6.0) + vec2(drift * .12, 0.));
        float flow = waterP.y * 17.0 + sin(waterP.x * 2.4 + drift) * .65 + turbulence * 1.5;
        float waves = sin(flow - drift) * .5 + .5;
        float wavelet = sin(waterP.y * 43.0 + sin(waterP.x * 6.0) - drift * 1.7) * .5 + .5;
        float brush = grainNoise(waterP * vec2(8.0, 39.0));
        vec3 color = mix(deep, blood, .40 + .24 * grainNoise(p * .8));
        color = mix(color, crest, smoothstep(.66, .98, waves) * (.1 + .30 * turbulence));
        color += crest * smoothstep(.9, 1.0, wavelet) * brush * .1;
        color *= .90 + brush * .16;
        float broad = grainNoise(fluid * vec2(2.5, 5.0));
        float streak = grainNoise(fluid * vec2(7.0, 23.0) + broad * 2.0);
        float fine = grainNoise(fluid * vec2(16.0, 48.0));
        float mask = vortexEdge(q, time);
        // 填滿的金白水體，暗金流帶穿過其中；外緣與血水自然混合。
        vec3 liquid = mix(gold * .42, gold, .4 + broad * .6);
        float whiteWater = smoothstep(.42, .8, streak + broad * .24);
        float core = 1.0 - smoothstep(.15, 1.1, r);
        liquid = mix(liquid, foam, .12 + core * .46 + whiteWater * .27);
        float flecks = smoothstep(.69, .9, fine) * smoothstep(.45, .7, streak);
        liquid = mix(liquid, foam, flecks * .7);
        // 根據真正頂點起伏的坡度做掠射亮紋，避免單純把金色畫在平板上。
        float h = waterHeight(p, vortex, time);
        vec2 slope = vec2(waterHeight(p + vec2(.025, 0.), vortex, time) - h,
          waterHeight(p + vec2(0., .025), vortex, time) - h) / .025;
        vec3 normal = normalize(vec3(-slope.x, 1., -slope.y));
        float light = dot(normal, normalize(vec3(-.45, .8, .35)));
        liquid *= .78 + light * .24;
        liquid += foam * pow(max(0., dot(normal, normalize(vec3(-.25, .95, .2)))), 18.) * whiteWater * .12;
        color = mix(color, liquid, mask);
        gl_FragColor = vec4(color, 1.0);
        #include <colorspace_fragment>
      }
    `,
    toneMapped: false,
  });
}

/** 碎裂紅褐岩岸：同一材質涵蓋頂面與斷面，斷面依幾何法線變暗。 */
export function bloodRockMaterial() {
  return new THREE.ShaderMaterial({
    name: "blood-pool-rock",
    uniforms: {
      rock: { value: new THREE.Color("#55362b") },
      edge: { value: new THREE.Color("#231717") },
    },
    vertexShader: vertex,
    fragmentShader: /* glsl */ `
      uniform vec3 rock, edge;
      varying vec3 worldPoint, worldNormal;
      ${noise}
      vec2 hash(vec2 p) {
        return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
      }
      void main() {
        vec2 p = worldPoint.xz * 2.1;
        vec2 cell = floor(p), f = fract(p);
        float nearest = 8.0, next = 8.0;
        vec2 id = cell;
        for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
          vec2 tile = cell + vec2(float(x), float(y));
          vec2 d = vec2(float(x), float(y)) + hash(tile) * .7 + .15 - f;
          float dist = dot(d, d);
          if (dist < nearest) { next = nearest; nearest = dist; id = tile; }
          else next = min(next, dist);
        }
        float crack = smoothstep(.012, .048, next - nearest);
        float mottling = hash(id).x * .28 + .82;
        float grain = grainNoise(worldPoint.xz * 35.0) * .13;
        float stains = grainNoise(worldPoint.xz * 3.0) * .18 + .81;
        float top = smoothstep(.3, .9, worldNormal.y);
        float strata = sin(worldPoint.y * 67.0 + grainNoise(p * 4.0) * 2.0) * .05;
        vec3 color = mix(edge, rock * mottling, .22 + .78 * crack);
        color *= (mix(.38 + strata, .95, top) + grain) * stains;
        color += rock * smoothstep(.045, .11, next - nearest) * .1 * top;
        gl_FragColor = vec4(color, 1.0);
        #include <colorspace_fragment>
      }
    `,
    toneMapped: false,
  });
}

/** 木橋的沿紋磨損；保留 standard 材質的既有燈光／陰影與 instancing。 */
export function bloodBridgeMaterial() {
  const material = new THREE.MeshStandardMaterial({ color: "#60452f", roughness: 1 });
  material.onBeforeCompile = (shader) => {
    shader.vertexShader = `varying vec3 plankPoint;\n${shader.vertexShader}`
      .replace("#include <begin_vertex>", "#include <begin_vertex>\nplankPoint = position;");
    shader.fragmentShader = `varying vec3 plankPoint;\n${noise}\n${shader.fragmentShader}`
      .replace("#include <color_fragment>", `#include <color_fragment>
        float fiber = sin(plankPoint.x * 99.0 + sin(plankPoint.z * 12.0) * .8) * .5 + .5;
        float wear = grainNoise(plankPoint.xz * vec2(25., 3.));
        diffuseColor.rgb *= .62 + wear * .25 + fiber * .23;
      `);
  };
  material.customProgramCacheKey = () => "blood-pool-wood-grain-v1";
  return material;
}
