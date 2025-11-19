extends Node2D

@onready var player : CharacterBody2D = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		player.velocity.x = direction * player.SPEED
		player.sprite.flip_h = direction < 0
		if player.is_on_floor():
			player.state = player.MOVING
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED)
		if player.is_on_floor():
			player.state = player.IDLE
	
	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		player.state = player.JUMPING
	
	if player.is_on_floor() and Input.is_action_pressed("move_crouch"):
		player.state = player.CROUCHING
		if direction != 0:
			player.state = player.SLIDING


	player.move_and_slide()
