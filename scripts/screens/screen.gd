class_name Screen
extends RefCounted

# Phase 1 refactor 基底：每個 screen 自己負責建構 UI 並掛到 main.root。
# Main 持有 current_screen 參照、確保 RefCounted 不被提前釋放。
# 流程：main._show(SomeScreen.new())
#       └─ attach(main) → _build() → main.root.add_child(...)

var main: Main = null

func attach(main_node: Main) -> void:
	main = main_node
	var control: Control = _build()
	if control != null:
		main.root.add_child(control)

# 子類覆寫：建出整個 screen 的 root Control 並回傳。
func _build() -> Control:
	return null
