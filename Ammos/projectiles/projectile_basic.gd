extends AttackArea

## Projectile Velocity
@export
var velocity : Vector2
## Set to true to make the projectile react to gravity
@export
var can_fall : bool
## Set to true to make the projectile bounce off bodies.
@export
var can_bounce : bool
## How many times the projectile pierces through an object before being destroyed.
@export
var piercing : int = 0

@export
var base : Node2D

signal on_destroy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if can_fall:
		velocity.y += gravity*delta
		#print(velocity.y)
		#print(gravity)
	if is_instance_valid(base):
		base.position += velocity*delta
	else:
		position += velocity*delta



## If entering a body it will bounce
func _on_body_entered(body: Node2D) -> void:
	if can_bounce:
		print("body entered")
		velocity.y = -velocity.y
		velocity.y /= 2
	else:
		destroy_self()

func destroy_self() -> void:
	on_destroy.emit()
	queue_free()


func _on_hit_target(target: DamagableComponent) -> void:
	piercing -= 1
	print("hit")
	if piercing < 0:
		destroy_self()
