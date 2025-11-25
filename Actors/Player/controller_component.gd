extends Node2D

@onready var player : CharacterBody2D = get_parent()
var hitbox : CollisionShape2D
var hitbox_default_size : float
var hitbox_default_pos : Vector2
var head_check : Area2D
var friction : int = 10
var can_shotgun_jump = false
var shotgun_jump_count = 0
@export
var shotgun_jump_max = 2

@export
var recticle : PlayerRecticle
## The ammo launched by the primary fire. Should be a child of the recticle.
@export
var primary_ammo : AmmoGeneric
## The ammo launched by the secondary fire. Should be a child of the recticle.
@export
var secondary_ammo : AmmoGeneric
## Mercy time between two inputs that allows shotgun jumping
@export
var shotgun_jump_timer : Timer
## Timer for how long a reload takes
@export
var reload_timer : Timer
var reloading : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox = player.get_node("Collidor")
	head_check = player.get_node("HeadCheck")
	hitbox_default_size = hitbox.shape.size.y
	hitbox_default_pos = hitbox.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if not player.state == player.SLIDING:
			if player.state == player.CROUCHING:
				player.velocity.x += direction * player.SPEED*0.5*delta
				player.velocity.x = clamp(player.velocity.x, -player.SPEED*0.5, player.SPEED*0.5)
				player.sprite.flip_h = direction < 0
			else:
				player.velocity.x += direction * player.SPEED*2*delta
				if player.is_on_floor():
					player.velocity.x = clamp(player.velocity.x, -player.SPEED, player.SPEED)
				else:
					if player.velocity.x == clamp(player.velocity.x, -player.SPEED*1.25, player.SPEED*1.25):
						pass
					else:
						player.velocity.x -= direction * player.SPEED*2*delta
				player.sprite.flip_h = direction < 0
			if player.is_on_floor() and not player.state == player.CROUCHING:
				player.state = player.MOVING
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		if player.is_on_floor():
			player.state = player.IDLE
	
	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		player.state = player.JUMPING
	
	if player.is_on_floor():
		handle_crouch()
		shotgun_jump_count = 0
	else:
		if player.velocity.y < 0:
			player.state = player.JUMPING
		else:
			player.state = player.FALLING
	
	handle_fire()
	


	player.move_and_slide()


func handle_crouch():
	if Input.is_action_pressed("move_crouch") or head_check.get_overlapping_bodies().size() > 0:
		if not (player.state == player.CROUCHING or player.state == player.SLIDING):
			hitbox.position.y = hitbox_default_pos.y/2
			hitbox.shape.size.y = hitbox_default_size/2
			
			player.state = player.CROUCHING
			if player.velocity.x != 0 and Input.is_action_pressed("move_crouch"):
				player.state = player.SLIDING
				player.velocity.x = sign(player.velocity.x) * player.SPEED*1.25
				
		else:
			if player.state == player.CROUCHING:
				if player.velocity.x != 0 and Input.is_action_pressed("move_crouch"):
					player.state = player.SLIDING
					player.velocity.x = sign(player.velocity.x) * player.SPEED*0.75
			elif player.state == player.SLIDING:
				player.velocity.x = move_toward(player.velocity.x, 0, friction)
				if player.velocity.x == 0 or Input.is_action_just_released("move_crouch"):
					player.state = player.CROUCHING
	else:
		hitbox.position.y = hitbox_default_pos.y
		hitbox.shape.size.y = hitbox_default_size
		if (player.state == player.CROUCHING or player.state == player.SLIDING):
			player.state = player.IDLE
	
	
	
	
	#if direction != 0:
		#player.state = player.SLIDING

func handle_fire() -> void:
	var shot = false
	var shots = 0
	if Input.is_action_pressed("fire_left"):
		shot = primary_ammo.fire(recticle.normal.angle())
		if shot:
			shots += 1
	if Input.is_action_pressed("fire_right"):
		shot = secondary_ammo.fire(recticle.normal.angle())
		if shot:
			shots += 1
	if not player.is_on_floor() and shot:
		shotgun_jump_timer.start()
		can_shotgun_jump = true
		shots -= 1
	if can_shotgun_jump and not player.is_on_floor() and shot and shotgun_jump_count < shotgun_jump_max and shots >= 1:
		if recticle.normal.y > 0:
			player.velocity.y = min(0, player.velocity.y)
		player.velocity -= recticle.normal*800
		shotgun_jump_count += 1
	if Input.is_action_just_pressed("fire_reload"):
		reload_timer.start()


func _on_shotgun_jump_timer_timeout() -> void:
	can_shotgun_jump = false


func _on_reload_timer_timeout() -> void:
	primary_ammo.reload()
	secondary_ammo.reload()
	reloading = false
