class_name SaveManager
extends RefCounted

const SAVE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func save(run_state: RunState) -> bool:
	if run_state == null or run_state.character == null:
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("無法寫入存檔：%s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(run_state.to_dict(), "\t"))
	file.close()
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
	if parsed is Dictionary:
		return parsed as Dictionary
	push_warning("存檔內容無法解析。")
	return {}

static func clear() -> void:
	if not has_save():
		return
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	dir.remove("savegame.json")
