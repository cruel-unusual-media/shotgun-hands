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
	add_separator("Layers")
	add_radio_check_item("Foreground", 3)
	set_item_checked(3, get_parent().get_currently_edited_layer() == 0)
	add_radio_check_item("Main", 4)
	set_item_checked(4, get_parent().get_currently_edited_layer() == 1)
	add_radio_check_item("Background", 5)
	set_item_checked(5, get_parent().get_currently_edited_layer() == 2)
