@tool
extends EditorPlugin

var editor_startup_scene_instance
var editor_open : bool = false

var _parameters_plugin

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	_parameters_plugin = load("res://addons/sgh_le/parameters.gd").new()
	add_inspector_plugin(_parameters_plugin)
	
	#add tab to top of editor
	editor_startup_scene_instance = load("res://addons/sgh_le/scenes/main.tscn").instantiate()
	EditorInterface.get_editor_main_screen().add_child(editor_startup_scene_instance)
	editor_startup_scene_instance.visible = false
	pass

func _exit_tree() -> void:
	if editor_startup_scene_instance:
		editor_startup_scene_instance.queue_free()
	pass


func _has_main_screen():
	return true


func _get_plugin_name():
	return "SGH Level Editor"

func _make_visible(state):
	if editor_startup_scene_instance:
		editor_startup_scene_instance.visible = state
		editor_open = state

func _process(delta: float) -> void:
	_parameters_plugin.hide_parameters = editor_open
