@tool
extends FoldableContainer


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func load_tileset_source(tileset_source : TileSetAtlasSource) -> void:
	_clear_self()
	
	for _tile_idx : int in tileset_source.get_tiles_count():
		var _new_button = Button.new()
		var _new_atlas_tex = AtlasTexture.new()
		_new_atlas_tex.atlas = tileset_source.texture
		_new_atlas_tex.region = tileset_source.get_tile_texture_region(tileset_source.get_tile_id(_tile_idx), 0)
		_new_button.icon = _new_atlas_tex
		_new_button.flat = true
		_new_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_new_button.expand_icon = true
		_new_button.custom_minimum_size.y = 70
		_new_button.button_down.connect(func(): get_parent().get_parent()._paint_selected_atlas_coord = tileset_source.get_tile_id(_tile_idx))
		$ScrollContainer/VBoxContainer.add_child(_new_button)
		
func _clear_self() -> void:
	for _child in $ScrollContainer/VBoxContainer.get_children():
		_child.queue_free()
