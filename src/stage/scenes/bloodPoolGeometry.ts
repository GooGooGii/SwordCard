import * as THREE from "three";
import { mergeGeometries } from "three/addons/utils/BufferGeometryUtils.js";

export type ShorePoint = readonly [number, number];

/** 水面細分集中在 Boss 周圍，遠處用疏網格；同一張網面沒有疊片接縫。 */
export function bloodWaterGeometry() {
  const geometry = new THREE.PlaneGeometry(48, 48, 80, 80);
  const positions = geometry.getAttribute("position");
  const spread = (value: number) => Math.sign(value) * Math.pow(Math.abs(value) / 24, 2.3) * 24;
  for (let i = 0; i < positions.count; i++) {
    positions.setXY(i, spread(positions.getX(i)) - 1.9, spread(positions.getY(i)) + 1.2);
  }
  positions.needsUpdate = true;
  geometry.computeBoundingSphere();
  return geometry;
}

export const BLOOD_POOL_SHORE: readonly ShorePoint[] = [
  [-.12, .35], [.48, -.16], [1.8, -.32], [3.7, -.22], [4.5, .4],
  [4.24, 1.4], [3.65, 2.26], [2.85, 2.7], [1.25, 2.64], [.38, 2.1], [-.18, 1.24],
];

/** 岩岸上面與角色腳底同高；斷面伸向低 0.34 公尺的血水。 */
export function shoreGeometry(points: readonly ShorePoint[], top = -.012, bottom = -.43) {
  const outline = points.map(([x, z]) => new THREE.Vector2(x, -z));
  const topGeometry = new THREE.ShapeGeometry(new THREE.Shape(outline)).toNonIndexed();
  topGeometry.deleteAttribute("uv");
  topGeometry.rotateX(-Math.PI / 2).translate(0, top, 0);
  const vertices: number[] = [];
  const center = points.reduce((sum, [x, z]) => sum.add(new THREE.Vector2(x, z)), new THREE.Vector2()).divideScalar(points.length);
  for (let i = 0; i < points.length; i++) {
    const [x, z] = points[i]!;
    const [nx, nz] = points[(i + 1) % points.length]!;
    const mx = (x + nx) / 2 + Math.sin(i * 4.2) * .035;
    const mz = (z + nz) / 2 + Math.cos(i * 3.7) * .035;
    const mid = top - .06;
    const bx = THREE.MathUtils.lerp(mx, center.x, -.02);
    const bz = THREE.MathUtils.lerp(mz, center.y, -.02);
    vertices.push(x, top, z, nx, top, nz, mx, mid, mz);
    vertices.push(x, top, z, mx, mid, mz, bx, bottom, bz);
    vertices.push(mx, mid, mz, nx, top, nz, bx, bottom, bz);
    vertices.push(nx, top, nz, nx, bottom, nz, bx, bottom, bz);
    vertices.push(x, top, z, bx, bottom, bz, x, bottom, z);
  }
  const sides = new THREE.BufferGeometry();
  sides.setAttribute("position", new THREE.Float32BufferAttribute(vertices, 3));
  sides.computeVertexNormals();
  const result = mergeGeometries([topGeometry, sides])!;
  topGeometry.dispose();
  sides.dispose();
  result.computeBoundingSphere();
  return result;
}

/** 共用 geometry／material 的 instancing，骨籬與木橋不因數量增加 draw calls。 */
export function instances(name: string, geometry: THREE.BufferGeometry, material: THREE.Material, transforms: THREE.Matrix4[], castShadow = false) {
  const mesh = new THREE.InstancedMesh(geometry, material, transforms.length);
  mesh.name = name;
  transforms.forEach((matrix, i) => mesh.setMatrixAt(i, matrix));
  mesh.instanceMatrix.needsUpdate = true;
  mesh.castShadow = castShadow;
  mesh.receiveShadow = true;
  mesh.computeBoundingSphere();
  return mesh;
}

export function transform(position: THREE.Vector3, scale: THREE.Vector3, rotation = new THREE.Euler()) {
  return new THREE.Matrix4().compose(position, new THREE.Quaternion().setFromEuler(rotation), scale);
}

export function segment(from: THREE.Vector3, to: THREE.Vector3, radius: number) {
  const delta = to.clone().sub(from);
  return new THREE.Matrix4().compose(
    from.clone().add(to).multiplyScalar(.5),
    new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), delta.clone().normalize()),
    new THREE.Vector3(radius, delta.length(), radius),
  );
}

/** 小型頭骨造型：頭蓋、顎骨及兩個眼窩各做 instance；不借用敵人或角色資產。 */
export function skullGeometry() {
  const dome = new THREE.SphereGeometry(1, 10, 7).toNonIndexed();
  dome.scale(.12, .13, .11);
  const jaw = new THREE.BoxGeometry(.15, .045, .095).toNonIndexed();
  jaw.translate(0, -.115, .025);
  const result = mergeGeometries([dome, jaw])!;
  dome.dispose();
  jaw.dispose();
  return result;
}
