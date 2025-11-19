@tool
extends Camera2D

var _panning : bool = false

signal _right_clicked(pos : Vector2i)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().get_parent().get_parent().gui_input.connect(viewport_input)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Control/background.material.set_shader_parameter("camera_position", global_position)
	$Control/background.material.set_shader_parameter("camera_zoom", zoom.x)
	
	var _viewport_size : Vector2 = Vector2(get_viewport().size) / zoom
	$Control.size = _viewport_size
	$Control.position = _viewport_size / -2.0
	
	#zoom -= Vector2(delta / 20.0, delta / 20.0)

func viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= 1.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 0.9
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_right_clicked.emit(event.global_position)
	
	if event is InputEventMouseMotion:
		if _panning:
			position -= event.relative / zoom
