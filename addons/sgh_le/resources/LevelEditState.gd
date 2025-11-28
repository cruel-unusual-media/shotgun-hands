extends Node
class_name LevelEditState

var selected_room : String

var selected_layer : String

var camera_pos : Vector2
var camera_zoom : Vector2

var level_start : LevelStart

var room_node_clickboxes : Dictionary[String, Array] = {}
