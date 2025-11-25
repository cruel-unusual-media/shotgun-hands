@tool
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

@export var enter_target_object : Node
@export var enter_action : Action

@export var exit_target_object : Node
@export var exit_action : Action

signal trigger_entered
signal trigger_exited

func _ready() -> void:
	if !Engine.is_editor_hint():
		get_parent().get_parent().get_parent().submit_doorway(self)
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	

func setup_collider() -> CollisionShape2D: #to be called and used by the level editor
	print("add collider node")
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
		
	var _linked_proxy : Doorway = get_meta("linked_proxy")
		
	_linked_proxy.trigger_label = trigger_label
	_linked_proxy.trigger_size = trigger_size
	_linked_proxy._update_proxy_self()
		

func _update_proxy_self() -> void:
	get_node("clickbox").size = trigger_size
	get_node("clickbox").position = trigger_size / -2.0
	get_node("Label").text = trigger_label

func _on_body_entered(_body) -> void:
	trigger_entered.emit()

func _on_body_exited(_body) -> void:
	print("emit exited")
	trigger_exited.emit()
