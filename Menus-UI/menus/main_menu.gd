extends Control


func _on_play_button_button_down() -> void:
	SceneManager.switch_to_menu(GlobalEnums.Menus.LEVEL_SELECTION)
