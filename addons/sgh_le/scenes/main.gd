@tool
extends Control

const tile_size : int = 32
const tilemap_scale : float = 2.0

var current_scene_root : Node
#var loaded_scene_path : String = "a"

var level_edit_states : Dictionary[Node, LevelEditState] = {}

var _is_current_scene_a_level : bool = false

@onready var undo_redo = EditorInterface.get_editor_undo_redo()

signal scene_changed

enum EditTool {SELECT, PAINT, PLACE_SPRITE, DRAW_COL}

var _paint_selected_atlas_coord : Vector2i = Vector2i.ZERO
var _drawing : bool = false
var _erasing : bool = false
var _stroke_add : Array[Vector2i] = []
var _stroke_erase : Array[Vector2i] = []

@onready var _selection_outline_panel = preload("res://addons/sgh_le/scenes/proxies/selection_outline_panel.tscn").instantiate()
var _selected_proxy : Node:
	set(x):
		_selected_proxy = x
		if _selected_proxy != null:
			EditorInterface.edit_node(_selected_proxy.get_meta("linked_node"))
		
var _moving_node : Node
var _move_grab_offset : Vector2

var _current_tool : EditTool = EditTool.SELECT:
	set(x):
		_current_tool = x
		
		_moving_node = null
		_selected_proxy = null
		
		$main/layers_margin_container/VBoxContainer/isolate_current.button_pressed = false
		
		match x:
			EditTool.SELECT:
				$main/tools_margin_container/tools.get_node("select").button_pressed = true
			EditTool.PAINT:
				$main/tools_margin_container/tools.get_node("paint").button_pressed = true
			EditTool.PLACE_SPRITE:
				$main/tools_margin_container/tools.get_node("add_sprite").button_pressed = true
				$main/sprite_selection.load_sprites()
			EditTool.DRAW_COL:
				$main/tools_margin_container/tools.get_node("draw_collision").button_pressed = true




var _previous_layer_name

var _selected_sprite_name : String = "Boxes.png":
	set(x):
		_selected_sprite_name = x
		$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/sprite_cursor.texture = load("res://Levels/Sprites/Decorations/" + x)

func _ready() -> void:
	scene_changed.connect(_scene_changed)
	_show_control("main")
	$main/VBoxContainer/SubViewportContainer.gui_input.connect(_viewport_input)
	add_child(_selection_outline_panel)


func _process(delta: float) -> void:
	if current_scene_root != EditorInterface.get_edited_scene_root():
		scene_changed.emit(EditorInterface.get_edited_scene_root())
	
	_is_current_scene_a_level = current_scene_root is Level
	
	$main/not_a_level_warning.visible = !_is_current_scene_a_level
	$main/no_rooms_yet_warning.visible = _is_current_scene_a_level and current_scene_root.get_children().size() == 0
	
	if !_is_current_scene_a_level:
		return
	
	$main/sprite_selection.visible = _current_tool == EditTool.PLACE_SPRITE
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/sprite_cursor.visible = _current_tool == EditTool.PLACE_SPRITE
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/sprite_cursor.position = get_global_space_mouse_position()
	
	if _current_tool == EditTool.PLACE_SPRITE:
		if Input.is_key_pressed(KEY_SHIFT):
			$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/sprite_cursor.position = $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/sprite_cursor.position.snappedf(4.0)
	
	$main/tile_selection.visible = _current_tool == EditTool.PAINT
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/tile_cursor.visible = _current_tool == EditTool.PAINT
	$main/layers_margin_container.visible = _current_tool == EditTool.PAINT
	$main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies/tile_cursor.position = (get_global_space_mouse_position() - Vector2((tile_size * tilemap_scale) / 2.0,(tile_size * tilemap_scale) / 2.0)).snappedf(tile_size * tilemap_scale) + Vector2((tile_size * tilemap_scale) / 2.0,(tile_size * tilemap_scale) / 2.0)
	if _current_tool == EditTool.PAINT:
		var _coord : Vector2i = Vector2i(get_global_space_mouse_position()) / Vector2i(tile_size * tilemap_scale, tile_size * tilemap_scale)
		if _drawing:
			get_current_room_proxy().get_node(get_currently_edited_layer_path()).set_cell(_coord, 0, _paint_selected_atlas_coord)
			if !_stroke_add.has(_coord):
				_stroke_add.append(_coord)
				
		elif _erasing:
			get_current_room_proxy().get_node(get_currently_edited_layer_path()).set_cell(_coord, -1)
			if !_stroke_erase.has(_coord):
				_stroke_erase.append(_coord)
				
	if Input.is_key_pressed(KEY_ESCAPE):
		_selected_proxy = null
		_moving_node = null
		if _current_tool != EditTool.SELECT:
			_current_tool = EditTool.SELECT
	
	
	_selection_outline_panel.visible = _selected_proxy != null
	
	if _moving_node:
		_moving_node.global_position = get_global_space_mouse_position() + _move_grab_offset
		_moving_node.get_meta("linked_node").global_position = _moving_node.global_position
	
	if _previous_layer_name != get_currently_edited_layer_name():
		_layer_changed(get_currently_edited_layer_name())
	
	level_edit_states[current_scene_root].selected_layer = get_currently_edited_layer_name()
	
	_previous_layer_name = get_currently_edited_layer_name()
	
	if get_current_room_proxy():
		get_current_room_proxy().get_node("main/main_front_tiles").visible = !$main/layers_margin_container/VBoxContainer/isolate_current.button_pressed or level_edit_states[current_scene_root].selected_layer == "main_front"
		get_current_room_proxy().get_node("main/main_back_tiles").visible = !$main/layers_margin_container/VBoxContainer/isolate_current.button_pressed or level_edit_states[current_scene_root].selected_layer == "main_back"
		get_current_room_proxy().get_node("foreground/foreground_tiles").visible = !$main/layers_margin_container/VBoxContainer/isolate_current.button_pressed or level_edit_states[current_scene_root].selected_layer == "foreground"
		get_current_room_proxy().get_node("background/background_tiles").visible = !$main/layers_margin_container/VBoxContainer/isolate_current.button_pressed or level_edit_states[current_scene_root].selected_layer == "background"


func _select_edit_mode(id : int) -> void:
	match id:
		0:
			_current_tool = EditTool.SELECT
		1:
			_current_tool = EditTool.PAINT
		2:
			_current_tool = EditTool.PLACE_SPRITE
		3:
			_current_tool = EditTool.DRAW_COL



func _load_new_level() -> void:
	print(" * Loading in new level")
	
	level_edit_states.get_or_add(current_scene_root, LevelEditState.new())
	
	var _new_level_proxy = _add_level_proxy(current_scene_root.name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies)
	for _room : LevelRoom in current_scene_root.get_children():
		var _room_proxy : LevelRoom = _add_room_proxy(_room.name, _new_level_proxy, _room)
		
		for _layer : Node2D in _room.get_children():
			var _layer_proxy : Node2D = _add_layer_proxy(_layer.name, _room_proxy, _layer)
			
			for _object in _layer.get_children():
				if _object is TileMapLayer:
					var _new_tilemaplayer_proxy : TileMapLayer = _add_tilemaplayer_proxy(_object.name, _layer_proxy, _object)
					_copy_tilemap(_object, _new_tilemaplayer_proxy)
				
				elif _object is LevelStart:
					var _new_level_start_proxy = _add_level_start_proxy(_layer_proxy, _object)
					_new_level_start_proxy.position = _object.position
				
				elif _object is Doorway:
					var _new_room_entrance_proxy = _add_room_entrance_proxy(_layer_proxy, _object, _object.global_position)
					_object.set_meta("linked_proxy", _new_room_entrance_proxy)
					_object._update_self()
				
				elif _object is Trigger:
					_add_trigger_proxy(_layer_proxy, _object, _object.global_position)
				
				elif _object is Sprite2D:
					_add_sprite_proxy(_layer_proxy, _object)
	
	edit_room_idx(0)


func _add_origin_sprite(parent_room_proxy : LevelRoom) -> void:
	var _origin_sprite : Sprite2D = Sprite2D.new()
	_origin_sprite.texture = preload("res://addons/sgh_le/textures/editor_origin.png")
	_origin_sprite.scale = Vector2(3,3)
	parent_room_proxy.add_child(_origin_sprite)


func _add_level_proxy(proxy_name : String, owner : Node) -> Node:
	#print("add level proxy node")
	var _new_level_proxy : Level = Level.new()
	owner.add_child(_new_level_proxy)
	_new_level_proxy.name = proxy_name
	_new_level_proxy.owner = owner
	
	return _new_level_proxy


func _add_room_proxy(proxy_name : String, owner : Node, linked_node : Node) -> Node:
	#print("add room proxy node")
	var _new_room_proxy : LevelRoom = LevelRoom.new()
	owner.add_child(_new_room_proxy)
	_new_room_proxy.name = proxy_name
	_new_room_proxy.owner = owner
	_new_room_proxy.set_meta("linked_node", linked_node)
	
	_add_origin_sprite(_new_room_proxy)
	
	return _new_room_proxy


func _add_layer_proxy(layer_name : String, room_proxy_parent : LevelRoom, linked_layer : Node2D) -> Node2D:
	#print("add layer proxy node")
	var _new_layer : Node2D = Node2D.new()
	_new_layer.name = layer_name
	_new_layer.set_meta("linked_node", linked_layer)
	room_proxy_parent.add_child(_new_layer)
	return _new_layer


func _add_tilemaplayer_proxy(tilemaplayer_name : String, parent_proxy : Node, linked_tilemaplayer : Node) -> TileMapLayer:
	#print("add tilemap proxy")
	var _new_tilemaplayer_proxy : TileMapLayer = TileMapLayer.new()
	_new_tilemaplayer_proxy.name = tilemaplayer_name
	_new_tilemaplayer_proxy.set_meta("linked_node", linked_tilemaplayer)
	parent_proxy.add_child(_new_tilemaplayer_proxy)
	_new_tilemaplayer_proxy.scale = Vector2(2,2)
	
	if tilemaplayer_name == "background_tiles":
		_new_tilemaplayer_proxy.modulate = Color(0.5, 0.5, 0.5, 1.0)
		_new_tilemaplayer_proxy.collision_enabled = false
	elif tilemaplayer_name == "foreground_tiles":
		_new_tilemaplayer_proxy.modulate = Color(1.0, 1.0, 1.0, 0.5)
		_new_tilemaplayer_proxy.collision_enabled = false
	
	match tilemaplayer_name:
		"main_back_tiles":
			_new_tilemaplayer_proxy.tile_set = preload("res://Tilesets/Resources/placeholder.tres")
		"main_front_tiles": 
			_new_tilemaplayer_proxy.tile_set = preload("res://Tilesets/Resources/placeholder_overlay.tres")
		_:
			_new_tilemaplayer_proxy.tile_set = preload("res://Tilesets/Resources/debug.tres")
	
	return _new_tilemaplayer_proxy


func _add_level_start_proxy(proxy_owner : Node, linked_node : Node) -> LevelStart:
	#print("adding level start proxy")
	var _new_level_start_proxy : LevelStart = preload("res://addons/sgh_le/scenes/proxies/level_start.tscn").instantiate()
	level_edit_states[current_scene_root].node_clickboxes.append(_new_level_start_proxy.get_node("clickbox"))
	proxy_owner.add_child(_new_level_start_proxy)
	_new_level_start_proxy.owner = proxy_owner
	_new_level_start_proxy.set_meta("linked_node", linked_node)
	
	level_edit_states[current_scene_root].level_start = _new_level_start_proxy
	
	return _new_level_start_proxy


func _add_room_entrance_proxy(parent_proxy : Node, linked_entrance : Node, at_position : Vector2) -> Doorway:
	print("adding proxy")
	var _new_level_entrance_proxy : Doorway = preload("res://addons/sgh_le/scenes/proxies/doorway.tscn").instantiate()
	_new_level_entrance_proxy._is_proxy = true
	level_edit_states[current_scene_root].node_clickboxes.append(_new_level_entrance_proxy.get_node("clickbox"))
	parent_proxy.add_child(_new_level_entrance_proxy)
	_new_level_entrance_proxy.owner = parent_proxy
	_new_level_entrance_proxy.set_meta("linked_node", linked_entrance)
	_new_level_entrance_proxy.global_position = at_position
	
	return _new_level_entrance_proxy

func _add_trigger_proxy(parent_proxy : Node, linked_trigger : Node, at_position : Vector2) -> Trigger:
	var _new_trigger_proxy : Trigger = preload("res://addons/sgh_le/scenes/proxies/trigger.tscn").instantiate()
	_new_trigger_proxy._is_proxy = true
	level_edit_states[current_scene_root].node_clickboxes.append(_new_trigger_proxy.get_node("clickbox"))
	parent_proxy.add_child(_new_trigger_proxy)
	_new_trigger_proxy.owner = parent_proxy
	_new_trigger_proxy.set_meta("linked_node", linked_trigger)
	_new_trigger_proxy.global_position = at_position
	
	return _new_trigger_proxy

func _add_sprite_proxy(parent_proxy : Node, linked_sprite : Sprite2D) -> Sprite2D:
	var _new_sprite_proxy : Sprite2D = Sprite2D.new()
	_new_sprite_proxy.texture = linked_sprite.texture
	_new_sprite_proxy.scale = Vector2(2.0, 2.0)
	_new_sprite_proxy.global_position = linked_sprite.global_position
	_add_clickbox_to_proxy(_new_sprite_proxy, _new_sprite_proxy.texture.get_size())
	
	parent_proxy.add_child(_new_sprite_proxy)
	_new_sprite_proxy.owner = parent_proxy
	_new_sprite_proxy.set_meta("linked_node", linked_sprite)
	
	return _new_sprite_proxy


func _copy_tilemap(from : TileMapLayer, to : TileMapLayer) -> void:
	var _used_cells = from.get_used_cells()
	
	for _cell : Vector2i in _used_cells:
		to.set_cell(_cell, from.get_cell_source_id(_cell), from.get_cell_atlas_coords(_cell), from.get_cell_alternative_tile(_cell))



func _scene_changed(new_scene : Node) -> void:
	current_scene_root = new_scene
	
	if current_scene_root is Level:
		if !level_edit_states.has(new_scene):
			_load_new_level()
		else:
			edit_room(level_edit_states[current_scene_root].selected_room)
	
		for _level_root in level_edit_states:
			_level_root.visible = _level_root == new_scene


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
	log_msg("Creating room \"" + room_name + "\"")
	var _new_room_node : LevelRoom = LevelRoom.new()
	_new_room_node.name = room_name
	
	undo_redo.add_do_method(self, "add_node_to_level", _new_room_node, current_scene_root)
	undo_redo.add_undo_method(_new_room_node, "queue_free")
	undo_redo.commit_action()
	
	var _room_proxy = _add_room_proxy(room_name, $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name)), _new_room_node)
	
	var _layers_to_be_made = ["background", "foreground"]
	
	var _create_layer_func = func(_layer_name : String) -> Node2D:
		var _new_layer : Node2D = Node2D.new()
		_new_layer.name = _layer_name
		add_node_to_level(_new_layer, _new_room_node)
		var _layer_proxy = _add_layer_proxy(_layer_name, _room_proxy, _new_layer)
		
		var _new_tilemap : TileMapLayer = TileMapLayer.new()
		_new_tilemap.tile_set = preload("res://Tilesets/Resources/placeholder.tres")
		_new_tilemap.name = _layer_name + "_tiles"
		_new_tilemap.scale = Vector2(2,2)
		add_node_to_level(_new_tilemap, _new_layer)
		_add_tilemaplayer_proxy(_layer_name + "_tiles", _layer_proxy, _new_tilemap)
		
		return _new_layer
	
	for _layer_name in _layers_to_be_made:
		var _new_layer = _create_layer_func.call(_layer_name)
		
		if _layer_name == "background":
			_new_layer.get_node("background_tiles").modulate = Color(0.5, 0.5, 0.5, 1.0)
			_new_layer.get_node("background_tiles").collision_enabled = false
		elif _layer_name == "foreground":
			_new_layer.get_node("foreground_tiles").modulate = Color(1.0, 1.0, 1.0, 0.5)
			_new_layer.get_node("foreground_tiles").collision_enabled = false
	
	var _new_main_layer : Node2D = Node2D.new()
	_new_main_layer.name = "main"
	add_node_to_level(_new_main_layer, _new_room_node)
	var _layer_proxy = _add_layer_proxy("main", _room_proxy, _new_main_layer)
	
	var _new_back_tilemap : TileMapLayer = TileMapLayer.new()
	_new_back_tilemap.tile_set = preload("res://Tilesets/Resources/placeholder.tres")
	_new_back_tilemap.name = "main_back_tiles"
	_new_back_tilemap.scale = Vector2(2,2)
	add_node_to_level(_new_back_tilemap, _new_main_layer)
	_add_tilemaplayer_proxy("main_back_tiles", _layer_proxy, _new_back_tilemap)
	
	var _new_front_tilemap : TileMapLayer = TileMapLayer.new()
	_new_front_tilemap.tile_set = preload("res://Tilesets/Resources/placeholder_overlay.tres")
	_new_front_tilemap.name = "main_front_tiles"
	_new_front_tilemap.scale = Vector2(2,2)
	add_node_to_level(_new_front_tilemap, _new_main_layer)
	_add_tilemaplayer_proxy("main_front_tiles", _layer_proxy, _new_front_tilemap)
	print(_new_front_tilemap.tile_set)
	
	edit_room(room_name)
	
	if current_scene_root.get_children().size() == 1: #if the room we just added was the first one
		_create_level_start(current_scene_root.get_node(level_edit_states[current_scene_root].selected_room + "/main"), _room_proxy)

func _create_level_start(owner_node : Node, room_proxy : Node) -> void:
	#print("creating level start")
	
	if level_edit_states[current_scene_root].level_start != null:
		printerr("Tried creating level start but it already exists in this level. Try moving the currently existing one.")
		return
		
	var _new_level_start : LevelStart = LevelStart.new()
	_new_level_start.name = "level_start"
	add_node_to_level(_new_level_start, owner_node)
	_add_level_start_proxy(room_proxy, _new_level_start)


func _create_doorway(parent_node : Node, parent_proxy : Node, at_position : Vector2):
	var _new_entrance : Doorway = Doorway.new()
	add_node_to_level(_new_entrance, parent_node)
	
	_new_entrance.global_position = at_position
	
	var _proxy_entrance = _add_room_entrance_proxy(parent_proxy, _new_entrance, at_position)
	
	_new_entrance.set_meta("linked_proxy", _proxy_entrance)


func _create_trigger(parent_node : Node, parent_proxy : Node, at_position : Vector2):
	var _new_trigger : Trigger = Trigger.new()
	add_node_to_level(_new_trigger, parent_node)
	_new_trigger.collision_layer = 4
	_new_trigger.collision_mask = 4
	var _trigger_collider = _new_trigger.setup_collider()
	add_node_to_level(_trigger_collider, _new_trigger)
	
	_new_trigger.global_position = at_position
	
	var _proxy_trigger = _add_trigger_proxy(parent_proxy, _new_trigger, at_position)
	
	_new_trigger.set_meta("linked_proxy", _proxy_trigger)


func _move_level_start(room_name : String, new_position : Vector2) -> void:
	log_msg("Moving level start to " + str(new_position) + " in \"" + room_name + "\"")
	var _new_proxy_parent = get_current_room_proxy().get_node("main")
	var _current_level_start_proxy : LevelStart = level_edit_states[current_scene_root].level_start
	
	var _new_parent = current_scene_root.get_node(room_name + "/main")
	var _current_level_start = _current_level_start_proxy.get_meta("linked_node")
	
	if _current_level_start_proxy.get_parent() != _new_proxy_parent:
		_current_level_start_proxy.reparent(_new_proxy_parent)
		_current_level_start.reparent(_new_parent)
		
	_current_level_start_proxy.position = new_position
	_current_level_start.position = new_position


func _place_currently_selected_sprite() -> void:
	log_msg("Placing \"" + _selected_sprite_name + "\"")
	var _new_sprite : Sprite2D = Sprite2D.new()
	_new_sprite.texture = load("res://Levels/Sprites/Decorations/" + _selected_sprite_name)
	add_node_to_level(_new_sprite, current_scene_root.get_node(get_current_room_name() + "/main"))
	
	if Input.is_key_pressed(KEY_SHIFT):
		_new_sprite.global_position = get_global_space_mouse_position().snappedf(4.0)
	else:
		_new_sprite.global_position = get_global_space_mouse_position()
	
	_new_sprite.scale = Vector2(2.0, 2.0)
	_add_sprite_proxy(get_current_room_proxy().get_node("main"), _new_sprite)


func _delete_current_room() -> void:
	log_msg("Deleting the current room")
	_selection_outline_panel.reparent(self, false)
	if current_scene_root.get_children().size() > 0:
		current_scene_root.get_node(level_edit_states[current_scene_root].selected_room).queue_free()
		get_current_room_proxy().queue_free()
	await get_tree().create_timer(0.1).timeout
	if current_scene_root.get_children().size() > 0:
		edit_room_idx(0)
	else:
		$main.update_room_list()


func _delete_selected_object() -> void:
	log_msg("Deleting object")
	_selection_outline_panel.reparent(self, false)
	
	if _selected_proxy.has_node("clickbox"):
		level_edit_states[current_scene_root].node_clickboxes.erase(_selected_proxy.get_node("clickbox"))
	
	_selected_proxy.get_meta("linked_node").get_parent().remove_child(_selected_proxy.get_meta("linked_node"))
	_selected_proxy.call_deferred("queue_free")


func _get_node_child_index(node : Node) -> int:
	var _index : int = 0
	for _ch in node.get_parent().get_children():
		if _ch == node:
			break
		
		_index += 1
	
	return _index

func _move_node_in_tree(node : Node, offset : int) -> void:
	node.get_parent().move_child(node, node.get_index() + offset)


func _push_selected_object_back() -> void:
	_move_node_in_tree(_selected_proxy, - 1)
	_move_node_in_tree(_selected_proxy.get_meta("linked_node"), - 1)
	
func _pull_selected_object_up() -> void:
	_move_node_in_tree(_selected_proxy, 1)
	_move_node_in_tree(_selected_proxy.get_meta("linked_node"), 1)


func edit_room_idx(idx : int) -> void:
	edit_room(current_scene_root.get_children()[idx].name)

func edit_room(room_name : String) -> void:
	level_edit_states[current_scene_root].selected_room = room_name
	$main.update_room_list()
	
	for _room in get_current_level_proxy().get_children():
		_room.visible = room_name == _room.name
	

var _scene_path : String = ""
func _scene_creation_path_entered(_path : String) -> void:
	_scene_path = _path

func create_new_level_scene() -> void:
	log_msg("Creating new level")
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

var _last_context_menu_open_pos : Vector2
func context_menu_option_chosen(id : int) -> void:
	match id:
		1:
			_move_level_start(level_edit_states[current_scene_root].selected_room, _last_context_menu_open_pos)
		2:
			$main/VBoxContainer/SubViewportContainer/SubViewport/editor_camera._return_to_origin()
		20:
			_delete_selected_object()
		21:
			_push_selected_object_back()
		22:
			_pull_selected_object_up()

func _show_node_context_menu() -> void:
	_last_context_menu_open_pos = get_global_space_mouse_position()
	$context_menu._update_node_context_menu()
	$context_menu.popup(Rect2i(get_global_mouse_position() + Vector2(0, 75), Vector2i(200, 400)))

func _show_context_menu() -> void:
	if !_is_current_scene_a_level or current_scene_root.get_children().size() == 0 or _current_tool != EditTool.SELECT:
		return
	
	_last_context_menu_open_pos = get_global_space_mouse_position()
	$context_menu._update_context_menu()
	$context_menu.popup(Rect2i(get_global_mouse_position() + Vector2(0, 75), Vector2i(200, 400)))

func get_currently_edited_layer_name() -> String:
	var _layer_buttons = $main/layers_margin_container/VBoxContainer
	
	if _layer_buttons.get_node("foreground").button_pressed:
		return "foreground"
	elif _layer_buttons.get_node("main/main-back").button_pressed:
		return "main_back"
	elif _layer_buttons.get_node("main/main-front").button_pressed:
		return "main_front"
	else:
		return "background"

func get_currently_edited_layer_path() -> String:
	var _layer_buttons = $main/layers_margin_container/VBoxContainer
	
	if _layer_buttons.get_node("foreground").button_pressed:
		return "foreground/foreground_tiles"
	elif _layer_buttons.get_node("main/main-back").button_pressed:
		return "main/main_back_tiles"
	elif _layer_buttons.get_node("main/main-front").button_pressed:
		return "main/main_front_tiles"
	else:
		return "background/background_tiles"

func _layer_changed(new_layer_name : String) -> void:
	match new_layer_name:
		"main_front":
			$main/tile_selection.load_tileset_source(preload("res://Tilesets/Resources/placeholder_overlay.tres").get_source(0))
		_:
			$main/tile_selection.load_tileset_source(preload("res://Tilesets/Resources/placeholder.tres").get_source(0))


func get_current_level_start() -> LevelStart:
	return null

func get_current_level_proxy() -> Level:
	return $main/VBoxContainer/SubViewportContainer/SubViewport/level_proxies.get_node(NodePath(current_scene_root.name))

func get_current_room_proxy() -> LevelRoom:
	return get_current_level_proxy().get_node(level_edit_states[current_scene_root].selected_room)

func get_current_room_name() -> String:
	return level_edit_states[current_scene_root].selected_room

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

func _stroke_lifted() -> void:
	var _tilemap_proxy = get_current_room_proxy().get_node(get_currently_edited_layer_path())
	var _linked_tilemap : TileMapLayer = _tilemap_proxy.get_meta("linked_node")
	
	for _cell : Vector2i in _stroke_add:
		_linked_tilemap.set_cell(_cell, _tilemap_proxy.get_cell_source_id(_cell), _paint_selected_atlas_coord, _tilemap_proxy.get_cell_alternative_tile(_cell))
	
	_stroke_add = []

func _erase_lifted() -> void:
	var _tilemap_proxy = get_current_room_proxy().get_node(get_currently_edited_layer_path())
	var _linked_tilemap : TileMapLayer = _tilemap_proxy.get_meta("linked_node")
	
	for _cell : Vector2i in _stroke_erase:
		_linked_tilemap.set_cell(_cell, -1)
	
	_stroke_erase = []

func _viewport_input(event) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and _erasing:
		_erase_lifted()
		_erasing = false
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drawing = event.pressed
			if !event.pressed:
				_moving_node = null
				if _current_tool == EditTool.PAINT:
					_stroke_lifted()
			else:
				if _current_tool == EditTool.SELECT:
					if !_click_clickbox_at_pos(get_global_space_mouse_position()):
						print("start selecting")
				
				elif _current_tool == EditTool.PLACE_SPRITE:
					_place_currently_selected_sprite()
					
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if _current_tool == EditTool.PAINT:
				_erasing = event.pressed
				
				if !event.pressed:
					if _current_tool == EditTool.PAINT:
						_erase_lifted()
			
			elif _current_tool == EditTool.SELECT:
				if event.pressed:
					_click_clickbox_at_pos(get_global_space_mouse_position(), false)
					if _selected_proxy:
						_show_node_context_menu()
					else:
						_show_context_menu()
	
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _selected_proxy and not _moving_node:
			_move_grab_offset = _selected_proxy.global_position - get_global_space_mouse_position()
			_moving_node = _selected_proxy


func _click_clickbox_at_pos(_clickpos : Vector2, allow_move : bool = true) -> Node:
	var _contestants : Array[Node] = []
	
	for _clickbox : Control in level_edit_states[current_scene_root].node_clickboxes:
		var _global_clickbox_begin = _clickbox.get_global_rect().position
		var _global_clickbox_end = _clickbox.get_global_rect().end

		if _clickpos.x >= _global_clickbox_begin.x and _clickpos.x <= _global_clickbox_end.x and _clickpos.y >= _global_clickbox_begin.y and _clickpos.y <= _global_clickbox_end.y:
			_contestants.append(_clickbox)
	
	if _contestants.size() > 0:
		var _result : Node = _contestants[0]
		
		for _contestant in _contestants:
			if _contestant.get_parent().get_index() > _result.get_parent().get_index():
				_result = _contestant
		
		return _clickbox_clicked(_result, allow_move)
		
	else:
		_selected_proxy = null
		return null
	

	
func log_msg(message : String) -> void:
	print(" * ", message)


func _clickbox_clicked(clickbox_control : Control, allow_move : bool = true) -> Node:
	if _selected_proxy == clickbox_control.get_parent() and allow_move:
		_move_grab_offset = clickbox_control.get_parent().global_position - get_global_space_mouse_position()
		_moving_node = clickbox_control.get_parent()
	else:
		_selection_outline_panel.reparent(clickbox_control, false)
		_selection_outline_panel.visible = true
		_selected_proxy = clickbox_control.get_parent()
	
	return _selected_proxy


func add_object_option_pressed(id : int) -> void:
	match id:
		0:
			log_msg("Add trigger to room \"" + get_current_room_name() + "\"")
			var _trigger_parent = current_scene_root.get_node(get_current_room_name() + "/main")
			var _trigger_proxy_parent = get_current_room_proxy().get_node("main")
			var _new_trigger = _create_trigger(_trigger_parent, _trigger_proxy_parent, _last_context_menu_open_pos)
		1:
			log_msg("Add doorway to room \"" + get_current_room_name() + "\"")
			var _entrance_parent = current_scene_root.get_node(get_current_room_name() + "/main")
			var _entrance_proxy_parent = get_current_room_proxy().get_node("main")
			var _new_entrance = _create_doorway(_entrance_parent, _entrance_proxy_parent, _last_context_menu_open_pos)

func _add_clickbox_to_proxy(parent_proxy : Node2D, box_size : Vector2) -> void:
	var _new_clickbox : ColorRect = ColorRect.new()
	_new_clickbox.color = Color.TRANSPARENT
	_new_clickbox.name = "clickbox"
	
	parent_proxy.add_child(_new_clickbox)
	level_edit_states[current_scene_root].node_clickboxes.append(_new_clickbox)
	
	_new_clickbox.anchor_left = 0.5
	_new_clickbox.anchor_right = 0.5
	_new_clickbox.anchor_top = 0.5
	_new_clickbox.anchor_bottom = 0.5
	_new_clickbox.offset_bottom = box_size.y / 2.0
	_new_clickbox.offset_right = box_size.x / 2.0
	_new_clickbox.offset_left = box_size.y / -2.0
	_new_clickbox.offset_right = box_size.y / -2.0
	_new_clickbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_new_clickbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	_new_clickbox.size = box_size
	_new_clickbox.position = box_size / -1.0
