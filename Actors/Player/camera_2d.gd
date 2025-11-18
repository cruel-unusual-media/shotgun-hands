extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move camera to adjacent to cursor
	var mPos = get_local_mouse_position()
	position = mPos/2#(get_local_mouse_position())/2
	
