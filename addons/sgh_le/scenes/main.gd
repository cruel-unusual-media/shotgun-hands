@tool
extends Control

var current_scene_root : Node
var loaded_scene_path : String = "a"
var shown_room_name : String

var _is_current_scene_a_level : bool = false

@onready var undo_redo = EditorInterface.get_editor_undo_redo()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_control("main")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_scene_root = EditorInterface.get_edited_scene_root()
	_is_current_scene_a_level = current_scene_root is Level
	
	$main/not_a_level_warning.visible = !_is_current_scene_a_level
	$main/no_rooms_yet_warning.visible = _is_current_scene_a_level and current_scene_root.get_children().size() == 0
		

func _show_control(control_name : String) -> void:
	for _control in get_children():
		_control.visible = _control.name == control_name

func show_main_screen() -> void:
	_show_control("main")


func add_node_to_level(child : Node, parent : Node) -> void:
	parent.add_child(child)
	child.owner = current_scene_root

func open_room_creation_dialog() -> void:
	$room_creation_dialog.open_dialog()

func create_room(room_name : String) -> void:
	var _new_room_node : LevelRoom = LevelRoom.new()
	_new_room_node.name = room_name
	
	undo_redo.add_do_method(self, "add_node_to_level", _new_room_node, current_scene_root)
	undo_redo.add_undo_method(_new_room_node, "queue_free")
	undo_redo.commit_action()
	
	edit_room(room_name)
	
	$main.update_room_list()


func edit_room_idx(idx : int) -> void:
	edit_room(current_scene_root.get_children()[idx].name)

func edit_room(room_name : String) -> void:
	shown_room_name = room_name	
	$main.update_room_list()
	

var _scene_path : String = ""
func _scene_creation_path_entered(_path : String) -> void:
	_scene_path = _path

func create_new_level_scene() -> void:
	var _dialog : EditorFileDialog = EditorFileDialog.new()
	_dialog.title = "Pick a location for your level file"
	_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	_dialog.filters = PackedStringArray(["*.tscn ; Godot Scenes"])
	add_child(_dialog)
	_dialog.popup_file_dialog()
	
	#save the scene to the selected path
	_dialog.file_selected.connect(_scene_creation_path_entered)
	
	await _dialog.file_selected
	
	var _new_root_node : Level = Level.new() #setup scene to be created
	_new_root_node.name = _scene_path.get_file().get_basename().to_pascal_case()
	var _new_packed_scene : PackedScene = PackedScene.new()
	_new_packed_scene.pack(_new_root_node)
	
	ResourceSaver.save(_new_packed_scene, _scene_path)
	
	EditorInterface.open_scene_from_path(_scene_path) #open the scene in the editor
