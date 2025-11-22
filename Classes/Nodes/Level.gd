extends Node2D
class_name Level

##Node that acts as a level.

#A lot of these values are @exports. This is because only exported values get saved when packing a scene. Thus, if we want the level editor to be able to store information, we need exports

@export var _level_start : LevelStart #set by the level editor
#
func _ready() -> void:
	initialize_level()
	#_level_start = $room1/LevelStart #ONLY HERE FOR DEBUGGING LEVEL, ONCE REAL LEVELS HAVE BEEN IMPLEMENTED THIS NEEDS TO GO


func initialize_level() -> void:
	for _room : LevelRoom in get_children():
		var _has_level_start : bool = false
		
		for _child in _room.get_node("main").get_children():
			if _child is LevelStart:
				_level_start = _child
				_has_level_start = true
				break
		
		_freeze_room(_room, !_has_level_start)
	
	var _new_player_instance = preload("res://Actors/Player/player.tscn").instantiate()
	#_level_start.add_sibling(_new_player_instance)
	_new_player_instance.position = _level_start.position
	
	PersistentUI.add_to_camera(_new_player_instance.get_node("Camera2D"))
	await get_tree().create_timer(0.5).timeout
	PersistentUI.return_to_root()


func enter_room(room_to_enter : LevelRoom, entrance : Doorway) -> void:
	if entrance.get_parent() != room_to_enter:
		GameLogger.printerr_as_script(self, "enter_room(): Specified entrance is not part of the specified room!")
	
	for _room : LevelRoom in get_children():
		if _room == room_to_enter:
			_room.process_mode = Node.PROCESS_MODE_ALWAYS
			_room.visible = true
		else:
			_room.process_mode = Node.PROCESS_MODE_DISABLED
			_room.visible = false


func _freeze_room(room : LevelRoom, state : bool) -> void:
	room.visible = !state
	match state:
		false:
			room.position.y = 0
			room.process_mode = Node.PROCESS_MODE_ALWAYS
		true:
			room.position.y = 10000
			room.process_mode = Node.PROCESS_MODE_DISABLED
