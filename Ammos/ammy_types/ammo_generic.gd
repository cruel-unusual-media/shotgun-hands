class_name AmmoGeneric extends Node2D

## The projectile type used. Any scene can be placed here and will be instantiated as a projectile.
@export
var projectile_type : PackedScene
## The number of bullets fired by this
@export
var bullet_count : int = 1
## In degrees, the bullet spread, with bullets evenly placed along the spread.
## If it is left as 0 and multiple bullets are fired, the bullets will be arranged vertically instead.
## If there is only one bullet fired, this does nothing.
@export
var projectile_spread : float = 0
## In degrees, the amount that a projectile can vary from its position
@export
var projectile_inaccuracy : float = 0
## The speed of the projectile, in units/second. Will only override the speed of projectiles of the BasicBullet type.
@export
var speed : int = 1000
## The damage of this projectile. Will only override the damage of projectiles of the BasicBullet type.
@export
var damage : int = 1
## Time between shots
@export
var fire_delay : float
var can_fire : bool = true
@onready var delay_timer : Timer = $DelayTimer
## Max number of shots before reload is required. Set to -1 to make ammo unlimited.
@export
var max_ammo : int = -1
@onready var ammo : int = max_ammo



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(delay_timer):
		delay_timer.timeout.connect(_on_delay_timer_timeout)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Shoots a projectile if possible and returns false if it can't
func fire(dir : float) -> bool:
	if can_fire:
		if bullet_count == 1:
			send_bullet(dir + randf_range(-deg_to_rad(projectile_inaccuracy)/2, deg_to_rad(projectile_inaccuracy)/2), Vector2.ZERO)
		else:
			if projectile_spread > 0:
				var i = -deg_to_rad(projectile_spread)/2
				while i <= deg_to_rad(projectile_spread)/2:
					send_bullet(dir+i+randf_range(-deg_to_rad(projectile_inaccuracy)/2, deg_to_rad(projectile_inaccuracy)/2), Vector2.ZERO)
					
					i += deg_to_rad(projectile_spread)/(bullet_count-1)
			else:
				var i = -(bullet_count-1)*5
				while i <= (bullet_count-1)*5:
					var sidevec = Vector2.UP.rotated(dir)
					sidevec *= i
					send_bullet(dir+randf_range(-deg_to_rad(projectile_inaccuracy)/2, deg_to_rad(projectile_inaccuracy)/2), sidevec)
					i += 10
		#if bullet_count > 1 and projectile_spread > 0:
			#pass
		delay_timer.start(fire_delay)
		can_fire = false
		return true
	else:
		return false

func send_bullet(dir : float, startPos : Vector2) -> void:
	var bullet : Node2D = projectile_type.instantiate()
	if bullet is BasicBullet:
		bullet.velocity = Vector2(speed, 0).rotated(dir)
		bullet.damage_amount = damage
		
	add_child(bullet)
	if not bullet is BasicBullet:
		bullet.rotation = deg_to_rad(dir)
	bullet.global_position = global_position + startPos
	
	


func _on_delay_timer_timeout() -> void:
	if ammo > 0 or max_ammo == -1:
		can_fire = true
	else:
		print("Need a reload")

func reload() -> void:
	ammo = max_ammo
