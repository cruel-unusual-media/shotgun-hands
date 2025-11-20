@tool
extends Control

var current_scene_root : Node
#var loaded_scene_path : String = "a"

var shown_room_names : Dictionary = {} #the rooms that are shown per level scene. Keeps context across scenes.
var editing_layers : Dictionary = {} #the layers that are being edited per level scene. Keeps context across scenes.
var level_starts : Dictionary = {} #proxies. Same thing as above

var _is_current_scene_a_level : bool = false

@onready var undo_redo = EditorInterface.get_editor_undo_redo()

signal scene_changed

enum EditTool {SELECT, PAINT, DRAW_COL}

var _current_tool : EditTool = EditTool.SELECT

func _ready() -> void:
	$main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera._right_clicked.connect(_show_context_menu)
	scene_changed.connect(_scene_changed)
	_show_control("main")


func _process(delta: float) -> void:
	if current_scene_root != EditorInterface.get_edited_scene_root():
		scene_changed.emit(EditorInterface.get_edited_scene_root())
	
	_is_current_scene_a_level = current_scene_root is Level
	
	$main/not_a_level_warning.visible = !_is_current_scene_a_level
	$main/no_rooms_yet_warning.visible = _is_current_scene_a_level and current_scene_root.get_children().size() == 0
	
	if _is_current_scene_a_level and !$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.find_child(current_scene_root.name):
		_load_currently_opened_level()
	
	
	
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/tile_cursor.visible = _current_tool == EditTool.PAINT
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/tile_cursor.position = (get_global_space_mouse_position() - Vector2(32,32)).snapped(Vector2(64,64)) + Vector2(32,32)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _current_tool == EditTool.PAINT:
		get_current_room_proxy().get_node("main/main_tiles").set_cell(Vector2i(get_global_space_mouse_position()) / Vector2i(64, 64), 0, Vector2i(0,0))

func _select_edit_mode(id : int) -> void:
	match id:
		0:
			_current_tool = EditTool.SELECT
		1:
			_current_tool = EditTool.PAINT
		2:
			_current_tool = EditTool.DRAW_COL



func _load_currently_opened_level() -> void:
	var _new_level_proxy = _add_level_proxy(current_scene_root.name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies)
	for _room : LevelRoom in current_scene_root.get_children():
		var _room_proxy : LevelRoom = _add_room_proxy(_room.name, _new_level_proxy, _room)
		
		for _layer : Node2D in _room.get_children():
			var _layer_proxy : Node2D = _add_layer_proxy(_layer.name, _room_proxy, _layer)
			
			for _object in _layer.get_children():
				if _object is TileMapLayer:
					_add_tilemaplayer_proxy(_object.name, _layer_proxy, _object)
	
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name)).print_tree_pretty()


func _add_level_proxy(proxy_name : String, owner : Node) -> Node:
	print("add level proxy node")
	var _new_level_proxy : Level = Level.new()
	owner.add_child(_new_level_proxy)
	_new_level_proxy.name = proxy_name
	_new_level_proxy.owner = owner
	
	return _new_level_proxy


func _add_room_proxy(proxy_name : String, owner : Node, linked_node : Node) -> Node:
	print("add room proxy node")
	var _new_room_proxy : LevelRoom = LevelRoom.new()
	owner.add_child(_new_room_proxy)
	_new_room_proxy.name = proxy_name
	_new_room_proxy.owner = owner
	_new_room_proxy.set_meta("linked_node", linked_node)
	
	return _new_room_proxy


func _add_layer_proxy(layer_name : String, room_proxy_parent : LevelRoom, linked_layer : Node2D) -> Node2D:
	print("add layer proxy node")
	var _new_layer : Node2D = Node2D.new()
	_new_layer.name = layer_name
	_new_layer.set_meta("linked_node", linked_layer)
	room_proxy_parent.add_child(_new_layer)
	return _new_layer


func _add_tilemaplayer_proxy(tilemaplayer_name : String, parent_proxy : Node, linked_tilemaplayer : Node) -> TileMapLayer:
	print("add tilemap proxy")
	var _new_tilemaplayer_proxy : TileMapLayer = TileMapLayer.new()
	_new_tilemaplayer_proxy.name = tilemaplayer_name
	_new_tilemaplayer_proxy.set_meta("linked_node", linked_tilemaplayer)
	parent_proxy.add_child(_new_tilemaplayer_proxy)
	_new_tilemaplayer_proxy.changed.connect(_update_linked_tilemaplayer.bind(_new_tilemaplayer_proxy))
	
	_new_tilemaplayer_proxy.tile_set = load("res://Tilesets/Resources/debug.tres")
	_new_tilemaplayer_proxy.set_cell(Vector2i(0,0), 0, Vector2i(0,0))
	
	return _new_tilemaplayer_proxy


func _add_level_start_proxy(proxy_owner : Node, linked_node : Node) -> LevelStart:
	print("adding level start proxy")
	var _new_level_start_proxy : LevelStart = LevelStart.new()
	proxy_owner.add_child(_new_level_start_proxy)
	_new_level_start_proxy.owner = proxy_owner
	_new_level_start_proxy.set_meta("linked_node", linked_node)
	
	var _test_sprite = Sprite2D.new()
	_test_sprite.texture = load("res://sh_logo.png")
	_new_level_start_proxy.add_child(_test_sprite)
	
	level_starts.get_or_add(current_scene_root)
	level_starts[current_scene_root] = _new_level_start_proxy
	
	return _new_level_start_proxy



func _update_linked_tilemaplayer(tilemap_proxy : TileMapLayer) -> void:
	print("update linked tilemap")
	var _linked_tilemap : TileMapLayer = tilemap_proxy.get_meta("linked_node")
	_linked_tilemap.get_used_cells()



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
	
	var _layers_to_be_made = ["foreground", "main", "background"]
	
	var _room_proxy = _add_room_proxy(room_name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name)), _new_room_node)
	
	for _layer_name in _layers_to_be_made:
		var _new_layer : Node2D = Node2D.new()
		_new_layer.name = _layer_name
		add_node_to_level(_new_layer, _new_room_node)
		var _layer_proxy = _add_layer_proxy(_layer_name, _room_proxy, _new_layer)
		
		var _new_tilemap : TileMapLayer = TileMapLayer.new()
		_new_tilemap.tile_set = preload("res://Tilesets/Resources/debug.tres")
		_new_tilemap.name = _layer_name + "_tiles"
		add_node_to_level(_new_tilemap, _new_layer)
		_add_tilemaplayer_proxy(_layer_name + "_tiles", _layer_proxy, _new_tilemap)
	
	edit_room(room_name)
	
	if current_scene_root.get_children().size() == 1: #if the room we just added was the first one
		$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/Sprite2D.reparent(_room_proxy)
		_create_level_start(current_scene_root.get_node(shown_room_names[current_scene_root] + "/main"), _room_proxy)

func _create_level_start(owner_node : Node, room_proxy : Node) -> void:
	print("creating level start")
	
	if level_starts.has(current_scene_root):
		printerr("Tried creating level start but it already exists in this level. Try moving the currently existing one.")
		return
		
	var _new_level_start : LevelStart = LevelStart.new()
	_new_level_start.name = "level_start"
	add_node_to_level(_new_level_start, owner_node)
	_add_level_start_proxy(room_proxy, _new_level_start)

func _move_level_start(room_name : String, new_position : Vector2) -> void:
	var _new_proxy_parent = get_current_room_proxy().get_node("main")
	var _current_level_start_proxy : LevelStart = level_starts[current_scene_root]
	
	var _new_parent = current_scene_root.get_node(room_name + "/main")
	var _current_level_start = _current_level_start_proxy.get_meta("linked_node")
	
	if _current_level_start_proxy.get_parent() != _new_proxy_parent:
		_current_level_start_proxy.reparent(_new_proxy_parent)
		_current_level_start.reparent(_new_parent)
		
	_current_level_start_proxy.position = new_position
	_current_level_start.position = new_position

func _delete_current_room() -> void:
	if current_scene_root.get_children().size() > 0:
		current_scene_root.get_node(shown_room_names[current_scene_root]).queue_free()
		get_current_room_proxy().queue_free()
	await get_tree().create_timer(0.1).timeout
	if current_scene_root.get_children().size() > 0:
		edit_room_idx(0)
	else:
		$main.update_room_list()


func edit_room_idx(idx : int) -> void:
	edit_room(current_scene_root.get_children()[idx].name)

func edit_room(room_name : String) -> void:
	shown_room_names.get_or_add(current_scene_root)
	shown_room_names[current_scene_root] = room_name
	$main.update_room_list()
	
	for _room in get_current_level_proxy().get_children():
		_room.visible = room_name == _room.name
	

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


func context_menu_option_chosen(id : int) -> void:
	match id:
		1:
			_move_level_start(shown_room_names[current_scene_root], get_global_space_mouse_position())
		6:
			$main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera._return_to_origin()

func _show_context_menu(at_position : Vector2i) -> void:
	if !_is_current_scene_a_level or current_scene_root.get_children().size() == 0:
		return
	
	$context_menu._update_context_menu()
	$context_menu.popup(Rect2i(at_position + Vector2i(0, 75), Vector2i(200, 400)))
	
func get_currently_edited_layer() -> int:
	return 1

func get_current_level_start() -> LevelStart:
	return null

func get_current_level_proxy() -> Level:
	return $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name))

func get_current_room_proxy() -> LevelRoom:
	return get_current_level_proxy().get_node(shown_room_names[current_scene_root])

func get_global_space_mouse_position() -> Vector2:
	var _mouse_pos_fac = ((get_local_mouse_position() - Vector2(0, $main/VBoxContainer/HBoxContainer.size.y)) / $main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.get_viewport_rect().size) - Vector2(0.5, 0.5) #some small addition for calibration due to god knows what
	return $main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.global_position + (_mouse_pos_fac * ($main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.get_viewport_rect().size / $main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.zoom))
	#return (get_global_mouse_position() + ($main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.position / 2.0) + 0.5 * get_viewport_rect().size) / $main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera.zoom

func get_currently_edited_tilemaplayer_proxy() -> TileMapLayer:
	return null

func _debug_func(id : int) -> void:
	match id:
		0:
			get_current_level_proxy().print_tree_pretty()
