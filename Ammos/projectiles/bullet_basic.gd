class_name BasicBullet extends Node2D

@export
var damage_amount : int
@export
var velocity : Vector2
@export
var parryable = true

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
	bullet_vis.polygon[1].x = velocity.length()*delta/2
	bullet_vis.polygon[2].x = velocity.length()*delta/2
	
	bullet_ray.force_raycast_update()
	if bullet_ray.is_colliding():
		var col = bullet_ray.get_collider()
		if col is DamagableComponent:
			col.get_hit(damage_amount)
			queue_free()
		elif col is AttackArea:
			if col.can_parry and parryable:
				col.on_parry()
				collision_mask = col.collision_mask - 0b0001000000000000
				bullet_ray.collision_mask = collision_mask
				velocity = Vector2.from_angle(col.rotation+randf_range(-PI/3, PI/3))*velocity.length()*1.25
				damage_amount *= 2
				parryable = false
				#print(name + " Was parried")
				
			elif col.can_parry:
				pass
			else:
				queue_free()
		else:
			queue_free()
	
	position += velocity*delta
	
