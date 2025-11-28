@tool
@icon("res://addons/sgh_le/textures/Trigger.svg")
extends Area2D
class_name Trigger

var _is_proxy : bool = false
@export_multiline var trigger_label : String = "New trigger": ##Put whatever you want here, to make it clear what this trigger does.
	set(x):
		trigger_label = x
		if !_is_proxy:
			_update_self()
@export var trigger_size : Vector2i = Vector2i(40,40): ##The size of the hitbox of this trigger.
	set(x):
		trigger_size = x
		if !_is_proxy:
			_update_self()

@export_group("Entry")
@export var entry_action_target_object : Node
@export var entry_action : Action:
	set(x):
		entry_action = x
		if !_is_proxy:
			_update_self()

@export_group("Exit")
@export var exit_action_target_object : Node
@export var exit_action : Action:
	set(x):
		exit_action = x
		if !_is_proxy:
			_update_self()

signal trigger_entered
signal trigger_exited

func _ready() -> void:
	if !Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	
func setup_collider() -> CollisionShape2D: ##to be called and used by the level editor, on non-proxies
	var _new_collision_shape : CollisionShape2D = CollisionShape2D.new()
	_new_collision_shape.shape = RectangleShape2D.new()
	_new_collision_shape.shape.size = Vector2(40,40)
	_new_collision_shape.name = "collider"
	
	return _new_collision_shape

func _update_self() -> void: #should only be called on non-proxies
	if !Engine.is_editor_hint():
		return
	
	get_node("collider").shape.size = trigger_size
	
	if !has_meta("linked_proxy"):
		return

	var _linked_proxy : Trigger = get_meta("linked_proxy")
		
	_linked_proxy.trigger_label = trigger_label
	_linked_proxy.trigger_size = trigger_size
	_linked_proxy._update_proxy_self()
		

func _update_proxy_self() -> void:
	if !_is_proxy:
		print("update proxy self requested while I am not a proxy")
		return
		
	get_node("clickbox").size = trigger_size
	get_node("clickbox").position = trigger_size / -2.0
	get_node("VBoxContainer/label").text = trigger_label
	
	if entry_action is DoorwayAction:
		get_node("VBoxContainer/type").text = "Doorway"
	elif entry_action is FreezeAction:
		get_node("VBoxContainer/type").text = "Freeze"
	else:
		get_node("VBoxContainer/type").text = "<None>"
	
func _on_body_entered(_body) -> void:
	trigger_entered.emit()
	_execute_entry_action()

func _on_body_exited(_body) -> void:
	trigger_exited.emit()
	_execute_exit_action()

func _execute_entry_action() -> void:
	if entry_action is DoorwayAction:
		if entry_action_target_object is not Doorway:
			GameLogger.printerr_as_script(self, "Cannot enter room because target object for DoorwayAction is not a Doorway object")
			return
		
		get_tree().get_first_node_in_group("level_root").enter_room(entry_action_target_object)

func _execute_exit_action() -> void:
	pass
