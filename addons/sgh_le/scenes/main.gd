@tool
extends Control

var current_scene_root : Node
#var loaded_scene_path : String = "a"

var shown_room_names : Dictionary = {}
var editing_layers : Dictionary = {}

var _is_current_scene_a_level : bool = false

@onready var undo_redo = EditorInterface.get_editor_undo_redo()

signal scene_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera._right_clicked.connect(_show_context_menu)
	scene_changed.connect(_scene_changed)
	_show_control("main")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_scene_root != EditorInterface.get_edited_scene_root():
		scene_changed.emit(EditorInterface.get_edited_scene_root())
	
	_is_current_scene_a_level = current_scene_root is Level
	
	$main/not_a_level_warning.visible = !_is_current_scene_a_level
	$main/no_rooms_yet_warning.visible = _is_current_scene_a_level and current_scene_root.get_children().size() == 0
	
	if _is_current_scene_a_level and !$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.find_child(current_scene_root.name):
		var _new_level_proxy = _add_level_proxy(current_scene_root.name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies)
		for _room : LevelRoom in current_scene_root.get_children():
			_add_room_proxy(_room.name, _new_level_proxy)
		
		$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.print_tree()
		

func _add_level_proxy(proxy_name : String, owner : Node) -> Node:
	print("add level proxy node")
	var _new_level_proxy : Level = Level.new()
	owner.add_child(_new_level_proxy)
	_new_level_proxy.name = proxy_name
	_new_level_proxy.owner = owner
	
	return _new_level_proxy


func _add_room_proxy(proxy_name : String, owner : Node) -> Node:
	print("add room proxy node")
	var _new_room_proxy : LevelRoom = LevelRoom.new()
	owner.add_child(_new_room_proxy)
	_new_room_proxy.name = proxy_name
	_new_room_proxy.owner = owner
	
	return _new_room_proxy
		


func _scene_changed(new_scene : Node) -> void:
	current_scene_root = new_scene
	if current_scene_root is Level:
		edit_room_idx(0)


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
	
	var _new_foreground_tilemap : TileMapLayer = TileMapLayer.new()
	_new_foreground_tilemap.name = "foreground"
	var _new_background_tilemap : TileMapLayer = TileMapLayer.new()
	_new_background_tilemap.name = "background"
	var _new_custom_layer : Node2D = Node2D.new()
	_new_custom_layer.name = "custom"
	var _new_custom_static_body : StaticBody2D = StaticBody2D.new()
	_new_custom_static_body.name = "custom_static_collision"
	
	add_node_to_level(_new_foreground_tilemap, _new_room_node)
	add_node_to_level(_new_background_tilemap, _new_room_node)
	add_node_to_level(_new_custom_layer, _new_room_node)
	add_node_to_level(_new_custom_static_body, _new_custom_layer)
	
	_add_room_proxy(room_name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name)))
	
	edit_room(room_name)


func _delete_current_room() -> void:
	if current_scene_root.get_children().size() > 0:
		current_scene_root.get_node(shown_room_names[current_scene_root]).queue_free()
	await get_tree().create_timer(0.1).timeout
	edit_room_idx(0)


func edit_room_idx(idx : int) -> void:
	edit_room(current_scene_root.get_children()[idx].name)

func edit_room(room_name : String) -> void:
	shown_room_names.get_or_add(current_scene_root)
	shown_room_names[current_scene_root] = room_name	
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


func _show_context_menu(at_position : Vector2i) -> void:
	if !_is_current_scene_a_level:
		return
	
	$context_menu.popup(Rect2i(at_position + Vector2i(0, 75), Vector2i(200, 400)))
	
func get_currently_edited_layer() -> int:
	return 1
	
