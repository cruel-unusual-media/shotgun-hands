@tool
extends Control

var loaded_scene_path : String = "a"
var shown_room_name : String

var _is_current_scene_a_level : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_control("main")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_is_current_scene_a_level = EditorInterface.get_edited_scene_root() is Level
	$main/not_a_level_warning.visible = !_is_current_scene_a_level

		

func _show_control(control_name : String) -> void:
	for _control in get_children():
		_control.visible = _control.name == control_name


func show_room_list() -> void:
	$room_list.build_room_list()
	_show_control("room_list")

func show_main_screen() -> void:
	_show_control("main")

func create_new_level_scene() -> void:
	print("create new level")
