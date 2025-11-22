extends Node2D
class_name Level

##Node that acts as a level.

#A lot of these values are @exports. This is because only exported values get saved when packing a scene. Thus, if we want the level editor to be able to store information, we need exports

@export var _level_start : LevelStart #set by the level editor

var _can_enter_doorways : bool = true
var _last_entered_doorway : Doorway

func _ready() -> void:
	initialize_level()
	#_level_start = $room1/LevelStart #ONLY HERE FOR DEBUGGING LEVEL, ONCE REAL LEVELS HAVE BEEN IMPLEMENTED THIS NEEDS TO GO


func initialize_level() -> void:
	for _room : LevelRoom in get_children():
		var _has_level_start : bool = false
		
		for _child in _room.get_node("main").get_children():
			if _child is LevelStart:
				print("found level start")
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


func enter_room(room_to_enter_name : String, doorway_label : String, origin_doorway : Doorway) -> void:
	_last_entered_doorway = origin_doorway
	
	print(_can_enter_doorways)
	if !_can_enter_doorways:
		return
	
	_can_enter_doorways = false
	var room_to_enter : LevelRoom = get_node(room_to_enter_name)
	var doorway : Doorway = room_to_enter.get_doorway_with_label(doorway_label)
	
	if doorway.get_parent().get_parent() != room_to_enter:
		GameLogger.printerr_as_script(self, "enter_room(): Specified entrance is not part of the specified room!")
		return
		
	for _room in get_children():
		if _room is not LevelRoom:
			continue
		
		if _room == room_to_enter:
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


func submit_doorway(doorway : Doorway) -> void:
	print("submit ", doorway)
	if doorway.can_enter:
		doorway.doorway_entered.connect(enter_room.bind(doorway.target_doorway_room_name, doorway.target_doorway_label, doorway))
	
	doorway.doorway_exited.connect(func(): _doorway_exited(doorway))

func _doorway_exited(doorway : Doorway) -> void:
	print(doorway, _last_entered_doorway)
	if doorway == _last_entered_doorway:
		return
	
	_set_can_enter_doorways(true) 
	print("doorway exited")

func _set_can_enter_doorways(state : bool) -> void:
	_can_enter_doorways = state
