class_name DamagableComponent extends Area2D

signal hit_for(damage_amount : int)
@export
var health_component : HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
  

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	if area is AttackArea:
		get_hit(area.damage)
		area.on_hit(self)


func get_hit(damage):
	hit_for.emit(damage)
	health_component.take_damage(damage)
