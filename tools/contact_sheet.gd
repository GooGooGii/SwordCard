extends SceneTree
# 卡圖風格一致性盤點工具（IMPROVEMENT_PLAN P3-13）
# 把 assets/art/cards/*.png 按檔名前綴（角色）拼成數張網格大圖，輸出 res://_contact_<group>.png。
# 肉眼掃網格挑出水墨濃淡 / 線條風格違和的卡，登記 ART_TODO §14 待重生成。
#
# 跑法：godot --headless --path . -s tools/contact_sheet.gd
# （純 Image 操作，不需要 rendering，可加 --headless）

const CELL: Vector2i = Vector2i(192, 192)
const COLS: int = 10
const GROUPS: Dictionary = {
	"lxy": "lixiaoyao", "zl": "zhaolinger", "lyr": "linyueru", "anu": "anu", "cl": "colorless",
}

func _initialize() -> void:
	var dir: DirAccess = DirAccess.open("res://assets/art/cards")
	if dir == null:
		push_error("cards dir not found")
		quit(1)
		return
	var by_group: Dictionary = {}
	for f: String in dir.get_files():
		if not f.ends_with(".png"):
			continue
		var prefix: String = f.split("_")[0]
		var group: String = String(GROUPS.get(prefix, "other"))
		if not by_group.has(group):
			by_group[group] = []
		(by_group[group] as Array).append(f)
	for group: String in by_group.keys():
		var files: Array = by_group[group]
		files.sort()
		var rows: int = int(ceil(float(files.size()) / COLS))
		var sheet: Image = Image.create(COLS * CELL.x, rows * CELL.y, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("202830"))
		var missing: int = 0
		for i: int in range(files.size()):
			var abs_path: String = ProjectSettings.globalize_path("res://assets/art/cards/%s" % files[i])
			var img: Image = Image.load_from_file(abs_path)
			if img == null or img.is_empty():
				missing += 1
				continue
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(CELL.x, CELL.y, Image.INTERPOLATE_BILINEAR)
			var dst: Vector2i = Vector2i((i % COLS) * CELL.x, (i / COLS) * CELL.y)
			sheet.blend_rect(img, Rect2i(Vector2i.ZERO, CELL), dst)
		var out: String = "res://_contact_%s.png" % group
		sheet.save_png(out)
		print("[contact] %s: %d cards (%d load-failed) -> %s" % [group, files.size(), missing, out])
	print("[contact] done")
	quit(0)
