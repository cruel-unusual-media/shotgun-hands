class_name PlayerUI extends CanvasLayer

@export
var player : PlayerCharacter

@onready
var health_bar = $Control/HBoxContainer/VBoxContainer/health_bar
@onready
var left_ammo = $Control/HBoxContainer/VBoxContainer/left_ammo
@onready
var right_ammo = $Control/HBoxContainer/VBoxContainer/right_ammo
@onready
var hype_rank = $Control/HBoxContainer/VBoxContainer/hype_rank
@onready
var hype_bar = $Control/HBoxContainer/VBoxContainer/hype_bar
@onready
var overheat_bar = $Control/HBoxContainer/VBoxContainer/overheat_bar



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(player.health_component):
		player.health_component.health_bar = health_bar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(player.health_component) and player.health_component.health_bar != health_bar:
		player.health_component.health_bar = health_bar
	
	left_ammo.text = "Left " + player.controller.primary_ammo.ammo_name + ": " + str(player.controller.primary_ammo.ammo)
	right_ammo.text = "Right " + player.controller.secondary_ammo.ammo_name + ": " + str(player.controller.secondary_ammo.ammo)
	overheat_bar.value = player.controller.overheat
