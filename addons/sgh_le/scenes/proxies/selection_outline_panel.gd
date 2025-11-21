@tool
extends Panel

var _time : float = 0.0

func _process(delta: float) -> void:
	_time += delta
	
	$fill.self_modulate.a = (sin(_time * 10.0) + 1.0) / 2.0
