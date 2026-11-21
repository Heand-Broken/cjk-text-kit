@tool
extends EditorPlugin

## Editor entry point for the CJK Text addon.
##
## The plugin deliberately adds nothing to the editor UI. Enabling it is
## what registers the [CJKText] control so that it shows up in the "Add
## Node" dialog and can be used from scripts.

const VERSION := "1.0.0"


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass
