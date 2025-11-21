@tool
extends PopupMenu


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_context_menu()
	id_pressed.connect(get_parent().context_menu_option_chosen)

func _update_context_menu() -> void:
	clear()
	
	add_submenu_node_item("Add object...", $add_object, 0)
	add_item("Place level start here", 1)
	add_item("Return to level origin", 6)
