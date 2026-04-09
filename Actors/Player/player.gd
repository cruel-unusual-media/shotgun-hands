class_name PlayerCharacter extends CharacterBody2D


const SPEED = 1000.0
const JUMP_VELOCITY = -600.0

enum {IDLE, MOVING, FALLING, JUMPING, SHOOTING_IDLE, SHOOTING_MOVING, SHOOTING_FALLING, SHOTGUN_JUMP, CROUCHING, SLIDING}

var state = JUMPING # State is used to determine the currently used animation
#@onready var shootTarget : Node2D = $Target
var prevState = IDLE
@onready var sprite = $AnimatedSprite2D
@onready var controller : PlayerController = $ControllerComponent
@onready var health_component : HealthComponent = $HealthComponent

func _physics_process(delta: float) -> void:
	# Code was moved to $ControllerComponent
	if prevState != state:
		stateChanged(state)
	prevState = state
	

func stateChanged(newState):
	match newState:
		IDLE:
			sprite.play("idle")
		MOVING:
			sprite.play("run")
		JUMPING:
			sprite.play("jump")
		FALLING:
			sprite.play("jump")
		CROUCHING:
			sprite.play("crouch")
			
		SLIDING:
			sprite.play("crouch")

func slow_frame(time_scale : float, duration : float) -> void:
	Engine.time_scale = time_scale
	var tmr = get_tree().create_timer(duration*time_scale)
	#print("The frame do be freezin'")
	await(tmr.timeout)
	#print("The frame don't be freezin'")
	Engine.time_scale = 1.0
