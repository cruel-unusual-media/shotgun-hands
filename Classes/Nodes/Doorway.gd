@tool
extends Node2D
class_name Doorway

var _is_proxy : bool = false
@export var doorway_label : String = "New doorway": ##The label with which this doorway will be identified.
	set(x):
		doorway_label = x
		if !_is_proxy:
			_update_self()
@export var doorway_size : Vector2i = Vector2i(40,40): ##The size of the hitbox of this doorway. Touching this hitbox will send you to the doorway with label [param target_label] in [param target_room], depending on the other properties of this doorway.
	set(x):
		doorway_size = x
		if !_is_proxy:
			_update_self()

func _ready() -> void:
	if !Engine.is_editor_hint():
		get_parent().get_parent().get_parent().submit_doorway(self)
	
	
func _update_self() -> void: #should only be called on non-proxies
	if !Engine.is_editor_hint():
		return
	
	if !has_meta("linked_proxy"):
		return
		
	var _linked_proxy : Doorway = get_meta("linked_proxy")
		
	_linked_proxy.doorway_label = doorway_label
	_linked_proxy.doorway_size = doorway_size
	_linked_proxy._update_proxy_self()
		

func _update_proxy_self() -> void:
	get_node("Label").text = doorway_label
