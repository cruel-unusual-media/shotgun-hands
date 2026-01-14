class_name HealthComponent extends Node2D

@export
var health_max : int = 10
var health_cur : int
@export
var health_bar : ProgressBar
signal on_death

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_cur = health_max


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.value = health_cur
		health_bar.max_value = health_max

func take_damage(damage : int) -> void:
	health_cur -= damage
	health_cur = clamp(health_cur, 0, health_max)
	if health_cur <= 0:
		on_death.emit()
	print("I was hit for " + str(damage) + " Damage")

func recover_health(healed : int) -> void:
	health_cur += healed
	health_cur = clamp(health_cur, 0, health_max)
	
