extends Action
class_name DoorwayAction

@export_group("Description")
@export_multiline var description : String = "This action sends the player to the target doorway object."

@export_group("")
@export var initial_velocity : Vector2 = Vector2.ZERO ##Velocity that the player will have immediately after getting transported to the target doorway. (UNIMPLEMENTED)
