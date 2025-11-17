@tool
extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
