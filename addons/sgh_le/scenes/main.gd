@tool
extends Control

var loaded_scene_path : String = ""
var loaded_room_name : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_screen("main")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _show_screen(control_name : String) -> void:
	for _control in get_children():
		_control.visible = _control.name == control_name

func _load_level(path : String) -> void:
	pass
