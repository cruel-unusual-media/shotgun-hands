@tool
extends EditorInspectorPlugin

#Plugin used to hide node parameters from the level editors that they do not need, hopefully preventing errors. 
#Only has effect when objects are selected through the level editor.

var hide_parameters : bool = false #set by the main plugin. Do not touch.

var _exposed_parameter_names : Array[String] = [
	"doorway_label",
	"doorway_size",
	"can_enter",
	"can_exit",
	"z_doorway",
	"target_doorway_label",
	"target_doorway_room_name"
]

func _can_handle(object):
	return true

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
		if name in _exposed_parameter_names:
			return false
		else:
			return hide_parameters
