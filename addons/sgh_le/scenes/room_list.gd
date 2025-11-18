@tool
extends Control

func build_room_list() -> void:
	pass


func _on_back_to_main_button_down() -> void:
	get_parent().show_main_screen()
