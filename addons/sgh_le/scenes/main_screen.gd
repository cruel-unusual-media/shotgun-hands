@tool
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/file.get_popup().id_pressed.connect(_on_file_option_pressed)


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

func _on_rooms_button_down() -> void:
	get_parent().show_room_list()

func _on_file_option_pressed(id : int) -> void:
	match id:
		0:
			get_parent().create_new_level_scene()
