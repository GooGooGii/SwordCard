import * as THREE from "three";

/**
 * 手繪遠景投影（matte painting）：從「靜止鏡頭」把一張背景畫投影到簡單的 3D 幾何上
 * （地面＋遠景牆）。鏡頭停在靜止位置時，畫面和原圖完全一樣；鏡頭移動時，
 * 近處地面與遠景牆依真實深度產生視差，角色的影子也落在真的地面上。
 * 移植自舊專案 SwordCard 的 BattleScenery3D（Godot），改用 Three.js 的投影鏡頭矩陣。
 */

export interface BackdropLayout {
  /** 地面與遠景牆的交界，以原圖由上往下的比例表示（0..1）。取場地最遠的那條邊。 */
  wallV: number;
}

const vertexShader = /* glsl */ `
  varying vec3 vWorld;
  void main() {
    vec4 world = modelMatrix * vec4(position, 1.0);
    vWorld = world.xyz;
    gl_Position = projectionMatrix * viewMatrix * world;
  }
`;

const fragmentShader = /* glsl */ `
  uniform sampler2D painting;
  uniform mat4 projectorViewProjection;
  uniform vec4 cover; // 畫面 0..1 → 原圖 uv：uv = cover.xy + screen01 * cover.zw
  varying vec3 vWorld;
  void main() {
    vec4 clip = projectorViewProjection * vec4(vWorld, 1.0);
    vec2 screen01 = clip.xy / clip.w * 0.5 + 0.5;
    // 鏡頭推移超出原圖時鏡射取樣，避免邊緣像素被拉成長條
    vec2 uv = cover.xy + screen01 * cover.zw;
    uv = 1.0 - abs(1.0 - mod(uv, 2.0));
    gl_FragColor = texture2D(painting, uv);
    #include <colorspace_fragment>
  }
`;

/** CSS background-size: cover 的對應：原圖等比放大蓋滿畫面、置中裁切。 */
export function coverTransform(imageAspect: number, viewAspect: number): THREE.Vector4 {
  if (viewAspect > imageAspect) {
    const k = imageAspect / viewAspect; // 畫面較寬：上下被裁
    return new THREE.Vector4(0, 0.5 - 0.5 * k, 1, k);
  }
  const k = viewAspect / imageAspect; // 畫面較高：左右被裁
  return new THREE.Vector4(0.5 - 0.5 * k, 0, k, 1);
}

/** 畫面上某一點（0..1，原點在左下）射出的視線打到地面 y=0 的位置。 */
export function screenToGround(camera: THREE.PerspectiveCamera, screen01: THREE.Vector2): THREE.Vector3 | null {
  const ray = new THREE.Raycaster();
  ray.setFromCamera(new THREE.Vector2(screen01.x * 2 - 1, screen01.y * 2 - 1), camera);
  const hit = new THREE.Vector3();
  return ray.ray.intersectPlane(new THREE.Plane(new THREE.Vector3(0, 1, 0), 0), hit);
}

/**
 * 建立投影用的地面與遠景牆。projector 必須是「靜止鏡頭」：已設好位置、朝向與 aspect，
 * 並呼叫過 updateMatrixWorld / updateProjectionMatrix。
 */
export function buildBackdrop(
  painting: THREE.Texture,
  projector: THREE.PerspectiveCamera,
  layout: BackdropLayout,
): THREE.Group {
  const image = painting.image as { width: number; height: number };
  const cover = coverTransform(image.width / image.height, projector.aspect);
  const viewProjection = new THREE.Matrix4().multiplyMatrices(projector.projectionMatrix, projector.matrixWorldInverse);
  const material = new THREE.ShaderMaterial({
    uniforms: {
      painting: { value: painting },
      projectorViewProjection: { value: viewProjection },
      cover: { value: cover },
    },
    vertexShader,
    fragmentShader,
    side: THREE.DoubleSide,
  });

  // 原圖上的交界線 → 畫面座標（扣掉 cover 裁切）→ 打到地面的深度
  const wallScreenY = (1 - layout.wallV - cover.y) / cover.w;
  const wallHit = screenToGround(projector, new THREE.Vector2(0.5, wallScreenY));
  const wallZ = wallHit ? wallHit.z : -30;

  const group = new THREE.Group();
  group.name = "Backdrop";
  const groundDepth = 60;
  const groundNear = projector.position.z + 10;
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(80, groundNear - wallZ), material);
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(0, 0, (groundNear + wallZ) / 2);
  ground.receiveShadow = true;
  ground.name = "BackdropGround";
  const wall = new THREE.Mesh(new THREE.PlaneGeometry(120, groundDepth), material);
  wall.position.set(0, groundDepth / 2, wallZ);
  wall.name = "BackdropWall";
  group.add(ground, wall);
  return group;
}
