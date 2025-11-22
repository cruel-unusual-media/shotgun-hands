extends Node2D
class_name LevelRoom

func initialize() -> void:
	pass

func get_doorway_with_label(label : String) -> Doorway:
	for _node in get_node("main").get_children():
		if _node is Doorway:
			if _node.doorway_label == label:
				return _node
	
	return null
