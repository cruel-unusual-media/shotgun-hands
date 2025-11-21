class_name BasicBullet extends Node2D

@export
var damage_amount : int
@export
var velocity : Vector2

@export_flags_2d_physics
var collision_mask : int

@onready var bullet_ray = $RayCast2D
@onready var bullet_vis = $Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bullet_ray.collision_mask = collision_mask


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	bullet_ray.target_position = velocity*delta
	bullet_vis.rotation = velocity.angle()
	bullet_vis.polygon[1].x = velocity.length()*delta
	bullet_vis.polygon[2].x = velocity.length()*delta
	
	bullet_ray.force_raycast_update()
	if bullet_ray.is_colliding():
		var col = bullet_ray.get_collider()
		if col is DamagableComponent:
			col.get_hit(damage_amount)
		queue_free()
	
	position += velocity*delta
	
