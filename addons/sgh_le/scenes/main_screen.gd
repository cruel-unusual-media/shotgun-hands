@tool
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/HBoxContainer/file.get_popup().id_pressed.connect(_on_file_option_pressed)
	$VBoxContainer/HBoxContainer/rooms.get_popup().id_pressed.connect(_room_option_pressed)
	$VBoxContainer/HBoxContainer/debug.get_popup().id_pressed.connect(get_parent()._debug_func)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_toggle_toolbar_enabled(get_parent()._is_current_scene_a_level)


func _toggle_toolbar_enabled(state : bool = true) -> void:
	$VBoxContainer/HBoxContainer/file.disabled = false
	$VBoxContainer/HBoxContainer/rooms.disabled = !state
	$VBoxContainer/HBoxContainer/level_config.disabled = !state
	$VBoxContainer/SubViewportContainer.visible = state
	$tools_margin_container.visible = state
	

func _toggle_level_configuration(state : bool) -> void:
	if state:
		$level_configuration.show()
		$level_configuration.popup_centered(Vector2i(400, 300))
	else:
		$level_configuration.hide()

func _on_level_config_button_down() -> void:
	_toggle_level_configuration(true)
	$VBoxContainer/HBoxContainer/level_config.release_focus()


func _on_level_config_close_button_down() -> void:
	_toggle_level_configuration(false)


func _room_option_pressed(id : int) -> void:
	match id:
		0:
			get_parent().open_room_creation_dialog()
		1:
			var _confirmation_dialog : ConfirmationDialog = ConfirmationDialog.new()
			_confirmation_dialog.ok_button_text = "Delete"
			_confirmation_dialog.dialog_text = "Are you sure you want to delete the current room?"
			_confirmation_dialog.title = "Delete Room?"
			add_child(_confirmation_dialog)
			_confirmation_dialog.popup_centered(Vector2i(200,100))
			_confirmation_dialog.get_ok_button().pressed.connect(get_parent()._delete_current_room)

		_:
			get_parent().edit_room_idx(id - 2)


func update_room_list() -> void:
	#print("update room list")
	var _rooms_popup : PopupMenu = $VBoxContainer/HBoxContainer/rooms.get_popup()
	
	for idx in _rooms_popup.item_count - 3:
		_rooms_popup.remove_item(_rooms_popup.item_count - 1)
	
	var _id : int = 2
	for room : LevelRoom in get_parent().current_scene_root.get_children():		
		_rooms_popup.add_radio_check_item(room.name, _id)
		if room.name == get_parent().level_edit_states[get_parent().current_scene_root].selected_room:
			_rooms_popup.set_item_checked(_id + 1, true)
		_id += 1

func _on_file_option_pressed(id : int) -> void:
	match id:
		0:
			get_parent().create_new_level_scene()

func _create_first_room() -> void:
	get_parent().open_room_creation_dialog()
