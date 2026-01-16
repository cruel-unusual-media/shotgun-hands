extends AttackArea

## Projectile Velocity
@export
var velocity : Vector2
## Set to true to make the projectile react to gravity
@export
var can_fall : bool
## Number of times the projectile will bounce off bodies before destroying.
@export
var bounces : int
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
	if bounces > 0:
		
		pass
		
		#velocity.y = -velocity.y
		#velocity.y /= 2
	else:
		destroy_self()

func destroy_self() -> void:
	on_destroy.emit()
	queue_free()


func _on_hit_target(target: DamagableComponent) -> void:
	piercing -= 1
	if piercing < 0:
		destroy_self()


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if bounces > 0:
		bounces -= 1
		var body_shape_owner_id = body.shape_find_owner(body_shape_index)
		var body_shape_owner = body.shape_owner_get_owner(body_shape_owner_id)
		var body_shape_2d = body.shape_owner_get_shape(body_shape_owner_id, 0)
		var body_global_transform = body_shape_owner.global_transform
		
		var area_shape_owner_id = shape_find_owner(local_shape_index)
		var area_shape_owner = shape_owner_get_owner(area_shape_owner_id)
		var area_shape_2d = shape_owner_get_shape(area_shape_owner_id, 0)
		var area_global_transform = area_shape_owner.global_transform
		
		var collision_points = area_shape_2d.collide_and_get_contacts(area_global_transform,
										body_shape_2d,
										body_global_transform)
		var avg : Vector2 = Vector2.ZERO
		var avd : float = 0
		for item in collision_points:
			print(item)
			avd += 1
			avg += item
		avg /= avd
		avg -= global_position
		print(velocity)
		velocity = -velocity.rotated(velocity.angle_to(-avg)*2)
		print(velocity)
