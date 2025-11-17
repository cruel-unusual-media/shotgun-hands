extends Node2D
class_name Level

##Node that acts as a level.

var _level_start : LevelStart

func _ready() -> void:
	_level_start = $room1/LevelStart
