class_name PlayerController extends Node2D	

@onready var player : CharacterBody2D = get_parent()
var hitbox : CollisionShape2D
var hitbox_default_size : float
var hitbox_default_pos : Vector2
var head_check : Area2D
var friction : int = 10
var can_shotgun_jump: bool = false
var shotgun_jump_count: int = 0
var jump_horizontal_boost: bool = true
@export
var shotgun_jump_max: int = 2

@export
var recticle : PlayerRecticle
## The ammo launched by the primary fire. Should be a child of the recticle.
@export
var primary_ammo : AmmoGeneric
## The ammo launched by the secondary fire. Should be a child of the recticle.
@export
var secondary_ammo : AmmoGeneric
## Melee attack area
@export
var melee_area : AttackArea
## Mercy time between two inputs that allows shotgun jumping
@export
var shotgun_jump_timer : Timer
## Timer for how long a reload takes
@export
var reload_timer : Timer
var reloading : bool = false
@export
var melee_timer : Timer
@export
var jump_horizontal_boost_timer: Timer
## The focus that the camera and shooting revolves around
@export
var player_focus : Node2D
@onready var focus_def_y = player_focus.position.y
var can_melee : bool = true

var overheat : float = 0.0
const OVERHEAT_DROP_RATE : float = 1/1.7
const OVERHEATED_DECAY_TIME : float = 12
var overheated : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox = player.get_node("Collidor")
	head_check = player.get_node("HeadCheck")
	hitbox_default_size = hitbox.shape.size.y
	hitbox_default_pos = hitbox.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not overheated:
		overheat -= OVERHEAT_DROP_RATE * delta
		if overheat <= 0:
			overheat = 0
	
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
		#print(player.get_gravity())

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if player.state != player.SLIDING:
			if player.state == player.CROUCHING:
				player.velocity.x += direction * player.SPEED*0.5*delta
				player.velocity.x = clampf(player.velocity.x, -player.SPEED*0.5, player.SPEED*0.5)
				player.sprite.flip_h = direction < 0
			else:
				var _additional_velocity: float = direction * player.SPEED*2*delta
				if (not player.is_on_floor() and sign(player.velocity.x) == direction):
					_additional_velocity *= 0.2  	
				player.velocity.x += _additional_velocity
					
				player.velocity.x = clampf(player.velocity.x, -player.SPEED, player.SPEED)

				player.sprite.flip_h = direction < 0
			if player.is_on_floor() and not player.state == player.CROUCHING:
				player.state = player.MOVING
	else:
		if (player.is_on_floor()):
			player.state = player.IDLE
			player.velocity.x = move_toward(player.velocity.x, 0, player.GROUND_DECELERATION)
		else:
			player.velocity.x = move_toward(player.velocity.x, 0, player.AIR_DECELERATION)
	
	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		player.state = player.JUMPING
		jump_horizontal_boost_timer.start(0.3)
	
	if (direction and player.velocity.x < 100 and jump_horizontal_boost):
		player.velocity.x += direction * 100
		jump_horizontal_boost=false;
		jump_horizontal_boost_timer.stop()
	
	
	if player.is_on_floor():
		handle_crouch()
		shotgun_jump_count = 0
	else:
		if player.velocity.y < 0:
			player.state = player.JUMPING
		else:
			player.state = player.FALLING
		end_crouch()
	
	handle_fire()
	
	player.move_and_slide()


func handle_crouch():
	if Input.is_action_pressed("move_crouch") or head_check.get_overlapping_bodies().size() > 0:
		if not (player.state == player.CROUCHING or player.state == player.SLIDING):
			hitbox.position.y = hitbox_default_pos.y/2
			hitbox.shape.size.y = hitbox_default_size/2
			player_focus.position.y = focus_def_y/2
			
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
		player_focus.position.y = focus_def_y
		if (player.state == player.CROUCHING or player.state == player.SLIDING):
			player.state = player.IDLE
	
	
	
	
	#if direction != 0:
		#player.state = player.SLIDING

func end_crouch() -> void:
	hitbox.position.y = hitbox_default_pos.y
	hitbox.shape.size.y = hitbox_default_size
	player_focus.position.y = focus_def_y


func handle_fire() -> void:	
	if not reloading and not overheated:
		var shot: bool = false
		
		if Input.is_action_pressed("fire_left"):
			var shot_left = primary_ammo.fire(recticle.normal.angle())
			
			if shotgun_jump_timer.is_stopped():
				if shot_left:
					shotgun_jump_timer.start()
			else:
				if shot_left:
					can_shotgun_jump = true;
					shot = shot_left
			
		if Input.is_action_pressed("fire_right"):
			var shot_right = secondary_ammo.fire(recticle.normal.angle())
			
			if shotgun_jump_timer.is_stopped():
				if shot_right:
					shotgun_jump_timer.start()
			else:
				if shot_right:
					can_shotgun_jump = true;
					shot = shot or shot_right
		
		if shot:
			if shotgun_jump_timer.is_stopped():
				shotgun_jump_timer.start()
			overheat += 1
		
		if overheat >= 8:
			begin_overheat()
		
		if not player.is_on_floor() and can_shotgun_jump and shotgun_jump_count < shotgun_jump_max:
			if recticle.normal.y > 0:
				player.velocity.y = min(0, player.velocity.y)
			player.velocity -= recticle.normal * 450
			shotgun_jump_count += 1
			shotgun_jump_timer.stop()
			can_shotgun_jump = false
		
		if Input.is_action_just_pressed("fire_reload"):
			reloading = true
			reload_timer.start()
	
	if Input.is_action_just_pressed("fire_melee") and can_melee:
		melee_area.enable()
		var tmr = get_tree().create_timer(0.3)
		tmr.timeout.connect(melee_area.disable)
		melee_timer.start()
		can_melee = false

func begin_overheat() -> void:
	overheated = true
	overheat = 8
	melee_area.damage = 150
	melee_timer.wait_time = 0.2
	var overtween = get_tree().create_tween()
	overtween.tween_property(self, "overheat", 0, OVERHEATED_DECAY_TIME)
	overtween.tween_property(self, "overheated", false, 0)
	overtween.tween_property(melee_area, "damage", 50, 0)
	overtween.tween_property(melee_timer, "wait_time", 0.5, 0)


func _on_shotgun_jump_timer_timeout() -> void:
	can_shotgun_jump = false
	GameLogger.print_as_autoload(self, "shotgun_jump_timer ended")


func _on_reload_timer_timeout() -> void:
	primary_ammo.reload()
	secondary_ammo.reload()
	reloading = false


func _on_melee_cooldown_timeout() -> void:
	can_melee = true


func _on_jump_horizontal_boost_timer_timeout() -> void:
	jump_horizontal_boost = true;
