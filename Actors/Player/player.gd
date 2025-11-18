extends CharacterBody2D


const SPEED = 500.0
const JUMP_VELOCITY = -600.0

enum {IDLE, MOVING, FALLING, JUMPING, SHOOTING_IDLE, SHOOTING_MOVING, SHOOTING_FALLING, SHOTGUN_JUMP, CROUCHING, SLIDING}

var state = IDLE # State is used to determine the currently used animation
@onready var shootTarget : Node2D = $Target
var prevState = IDLE
@onready var sprite = $AnimatedSprite2D


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
		CROUCHING:
			sprite.play("crouch")
