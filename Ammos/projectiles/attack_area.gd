class_name AttackArea extends Area2D

@export
var damage : int
@export
var can_parry : bool
signal hit_target(target : DamagableComponent)
signal hit_object
signal parried_attack

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func disable() -> void:
	monitorable = false
	monitoring = false
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = true

func enable() -> void:
	monitorable = true
	monitoring = true
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = false

func on_hit(target : DamagableComponent) -> void:
	hit_target.emit(target)
	hit_object.emit()

func on_parry() -> void:
	parried_attack.emit()
