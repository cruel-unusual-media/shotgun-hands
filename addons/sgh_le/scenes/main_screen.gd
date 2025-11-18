@tool
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/file.get_popup().id_pressed.connect(_on_file_option_pressed)
	$HBoxContainer/rooms.get_popup().id_pressed.connect(_room_option_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_toggle_toolbar_enabled(get_parent()._is_current_scene_a_level)


func _toggle_toolbar_enabled(state : bool = true) -> void:
	$HBoxContainer/file.disabled = false
	$HBoxContainer/rooms.disabled = !state
	$HBoxContainer/level_config.disabled = !state
	

func _toggle_level_configuration(state : bool) -> void:
	if state:
		$level_configuration.show()
		$level_configuration.popup_centered(Vector2i(400, 300))
	else:
		$level_configuration.hide()

func _on_level_config_button_down() -> void:
	if get_parent().loaded_scene_path != "":
		_toggle_level_configuration(true)
		$HBoxContainer/level_config.release_focus()


func _on_level_config_close_button_down() -> void:
	_toggle_level_configuration(false)


func _room_option_pressed(id : int) -> void:
	match id:
		0:
			get_parent().open_room_creation_dialog()
		_:
			get_parent().edit_room_idx(id - 1)


func update_room_list() -> void:
	var _rooms_popup : PopupMenu = $HBoxContainer/rooms.get_popup()
	
	for idx in _rooms_popup.item_count - 2:
		_rooms_popup.remove_item(_rooms_popup.item_count - 1)
	
	var _id : int = 1
	for room : LevelRoom in get_parent().current_scene_root.get_children():
		var _label : String = ""
		
		if get_parent().shown_room_name == room.name:
			_label = "> "
		
		_label += room.name
		
		_rooms_popup.add_item(_label, _id)
		_id += 1

func _on_file_option_pressed(id : int) -> void:
	match id:
		0:
			get_parent().create_new_level_scene()

func _create_first_room() -> void:
	get_parent().open_room_creation_dialog()
