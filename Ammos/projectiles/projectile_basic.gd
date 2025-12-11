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
		print(velocity.y)
		print(gravity)
	
	position += velocity*delta



## If entering a body it will bounce
func _on_body_entered(body: Node2D) -> void:
	if can_bounce:
		velocity.y = -velocity.y
		velocity.y /= 2
	else:
		destroy_self()

func destroy_self() -> void:
	on_destroy.emit()
	queue_free()
