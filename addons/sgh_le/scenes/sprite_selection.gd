@tool
extends FoldableContainer

var _base_path : String = "res://Levels/Sprites/Decorations/"

func load_sprites() -> void:
	print("load sprites")
	_clear_self()
	
	for _sprite_path : String in DirAccess.get_files_at(_base_path):
		if _sprite_path.get_extension() == "import":
			continue
		
		var _new_button = Button.new()
		_new_button.icon = load(_base_path + _sprite_path)
		_new_button.flat = true
		_new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_new_button.expand_icon = true
		_new_button.custom_minimum_size.y = 70
		_new_button.button_down.connect(func(): get_parent().get_parent()._selected_sprite_name = _sprite_path)
		$ScrollContainer/VBoxContainer.add_child(_new_button)
		
func _clear_self() -> void:
	for _child in $ScrollContainer/VBoxContainer.get_children():
		_child.queue_free()
