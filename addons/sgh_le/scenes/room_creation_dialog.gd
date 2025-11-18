@tool
extends Window


func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	$MarginContainer/VBoxContainer/HBoxContainer/create_room.disabled = $MarginContainer/VBoxContainer/room_name.text.length() < 4

func open_dialog() -> void:
	visible = true
	$MarginContainer/VBoxContainer/room_name.text = ""
	popup_centered(Vector2i(300, 150))


func _close_dialog() -> void:
	visible = false

func _on_create_room_button_down() -> void:
	get_parent().create_room($MarginContainer/VBoxContainer/room_name.text)
	_close_dialog()

func _on_cancel_button_down() -> void:
	_close_dialog()
