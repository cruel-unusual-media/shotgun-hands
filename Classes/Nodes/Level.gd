@icon("res://sh_logo.png")
extends Node2D
class_name Level

##Node that acts as a level.

#A lot of these values are @exports. This is because only exported values get saved when packing a scene. Thus, if we want the level editor to be able to store information, we need exports

@export var _level_start : LevelStart #set by the level editor

var _can_enter_doorways : bool = true
var _last_entered_doorway : Doorway

func _ready() -> void:
	if !Engine.is_editor_hint():
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
	add_child(_new_player_instance)
	_new_player_instance.global_position = _level_start.global_position
	
	PersistentUI.add_to_camera(_new_player_instance.get_node("Camera2D"))
	await get_tree().create_timer(0.5).timeout
	PersistentUI.return_to_root()


func enter_room(doorway : Doorway) -> void:
	for _room in get_children():
		if _room is not LevelRoom:
			continue
		
		if _room == doorway.get_parent().get_parent():
			_freeze_room(_room, false)
		else:
			_freeze_room(_room, true)
	
	PlayerState.player_instance.global_position = doorway.global_position

func _freeze_room(room : LevelRoom, state : bool) -> void:
	room.visible = !state
	match state:
		false:
			room.position.y = 0
			room.set_deferred("process_mode", Node.PROCESS_MODE_ALWAYS)
		true:
			room.position.y = 10000
			room.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _doorway_exited(doorway : Doorway) -> void:
	print(doorway, _last_entered_doorway)
	if doorway == _last_entered_doorway:
		return
	
	_set_can_enter_doorways(true) 
	print("doorway exited")

func _set_can_enter_doorways(state : bool) -> void:
	_can_enter_doorways = state
