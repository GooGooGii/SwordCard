class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://savegame.json"
const SAVE_TMP_PATH: String = "user://savegame.json.tmp"
const SAVE_CORRUPT_PATH: String = "user://savegame.corrupt.json"
const SAVE_VERSION: int = 1

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func save(run_state: RunState) -> bool:
	if run_state == null or run_state.character == null:
		return false
	var payload: Dictionary = run_state.to_dict()
	payload["save_version"] = SAVE_VERSION
	var tmp: FileAccess = FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_warning("無法寫入存檔暫存檔：%s" % SAVE_TMP_PATH)
		return false
	tmp.store_string(JSON.stringify(payload, "\t"))
	tmp.close()
	# 原子替換：先寫 .tmp 再覆蓋正式檔，避免寫到一半當機留下半截存檔
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_warning("無法存取 user:// 目錄")
		return false
	if has_save():
		dir.remove("savegame.json")
	var rename_err: int = dir.rename("savegame.json.tmp", "savegame.json")
	if rename_err != OK:
		push_warning("存檔改名失敗：error=%d" % rename_err)
		return false
	return true

static func load_save() -> Dictionary:
	if not has_save():
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is not Dictionary:
		push_error("存檔內容無法解析，已備份到 %s" % SAVE_CORRUPT_PATH)
		_backup_corrupt(text)
		return {}
	var data: Dictionary = parsed as Dictionary
	var version: int = int(data.get("save_version", 1))
	if version > SAVE_VERSION:
		push_warning("存檔版本 %d 比目前支援的 %d 新，可能不相容" % [version, SAVE_VERSION])
	return data

static func _backup_corrupt(text: String) -> void:
	var backup: FileAccess = FileAccess.open(SAVE_CORRUPT_PATH, FileAccess.WRITE)
	if backup == null:
		return
	backup.store_string(text)
	backup.close()

static func clear() -> void:
	if not has_save():
		return
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("savegame.json")
