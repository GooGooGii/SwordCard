import * as THREE from "three";
import { coverTransform, screenToGround } from "../backdrop";

export interface PaintingSize { width: number; height: number }
/** 原圖像素位置，原點左上；和美術工具的座標相同。 */
export interface PaintingPoint { x: number; y: number }
export interface GroundPlacement {
  position: [number, number, number];
  /** 置中 cover 裁切之後的畫面位置，原點左上，0..1。 */
  screen: PaintingPoint;
  /** 手機比例裁掉的邊緣錨點仍可取得世界位置，但會標為不可見。 */
  visible: boolean;
}

/**
 * 把畫中的道具落腳點對到舞台地面。傳入已更新矩陣的靜止投影鏡頭，
 * 不用出招時正在移動的鏡頭，避免道具跟著鏡頭滑動。
 * 只算座標，不建立或修改任何場景美術。
 */
export function paintingPointToGround(
  projector: THREE.PerspectiveCamera, image: PaintingSize, point: PaintingPoint,
): GroundPlacement | null {
  const values = [image.width, image.height, point.x, point.y, projector.aspect];
  if (!values.every(Number.isFinite) || image.width <= 0 || image.height <= 0 || projector.aspect <= 0) return null;
  if (point.x < 0 || point.y < 0 || point.x > image.width || point.y > image.height) return null;
  const cover = coverTransform(image.width / image.height, projector.aspect);
  const x = (point.x / image.width - cover.x) / cover.z;
  const y = (1 - point.y / image.height - cover.y) / cover.w;
  const hit = screenToGround(projector, new THREE.Vector2(x, y));
  if (!hit) return null;
  return {
    position: [hit.x, hit.y, hit.z],
    screen: { x, y: 1 - y },
    visible: x >= 0 && x <= 1 && y >= 0 && y <= 1,
  };
}
