extends Node

var verbose : bool = false

func toggle_verbose(state : bool = true):
	verbose = state

func print_as_script(script_owner : Node, message : String) -> void:
	print(get_game_runtime_string(), " <" + script_owner.get_script().get_path() + "> - " + message)

func printerr_as_script(script_owner : Node, message : String) -> void:
	printerr(get_game_runtime_string(), " <" + script_owner.get_script().get_path() + "> - " + message)

func print_verbose_as_script(script_owner : Node, message : String) -> void:
	if verbose:
		print(get_game_runtime_string(), " V <" + script_owner.get_script().get_path() + "> - ", message)

func print_verbose_as_autoload(autoload_instance : Node, message : String) -> void:
	if verbose:
		print(get_game_runtime_string(), " V [" + autoload_instance.name + "] - ", message)

func print_as_autoload(autoload_instance : Node, message : String) -> void:
	print(get_game_runtime_string(), " [" + autoload_instance.name + "] - ", message)

func printerr_as_autoload(autoload_instance : Node, error : String) -> void:
	printerr(get_game_runtime_string(), " [" + autoload_instance.name + "] - ", error)

func get_game_runtime_string() -> String:
	var time_msec = Time.get_ticks_msec()
	var result : String
	
	result = _pad_number(time_msec / 1000 / 60 / 60, 3) + "." + _pad_number((time_msec / 1000 / 60) % 60, 2) + "." + _pad_number((time_msec / 1000) % 60, 2) + "." + _pad_number(time_msec % 1000, 3)
	
	return result

func _pad_number(num : int, padding_amount : int) -> String:
	var result : String = str(num)
	for i in padding_amount - result.length():
		result = "0" + result
	
	return result
