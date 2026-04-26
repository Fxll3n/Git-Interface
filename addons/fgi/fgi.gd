@tool
extends EditorPlugin

var path: String = ProjectSettings.globalize_path("res://")
var dock: EditorDock

func _enter_tree() -> void:
	dock = EditorDock.new()
	dock.name = "Git"
	dock.default_slot = EditorDock.DOCK_SLOT_LEFT_UR
	var dock_content = preload("uid://ivjdq3iu1k6r").instantiate()
	dock.add_child(dock_content)
	add_dock(dock)


func _exit_tree() -> void:
	if dock != null:
		remove_dock(dock)
		dock.queue_free()
		dock = null
