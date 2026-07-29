@tool
class_name Clock extends Node3D

@export var hand_minute : Node3D
@export var hand_hour : Node3D

func _ready():
	hand_hour.rotation_degrees.x = GameTime.get_hour_hand_rotate()
	hand_minute.rotation_degrees.x = GameTime.get_minute_hand_rotate()
	GameTime.on_minute_tick.connect(set_hands)

func set_hands() -> void:
	hand_hour.rotation_degrees.x = GameTime.get_hour_hand_rotate()
	hand_minute.rotation_degrees.x = GameTime.get_minute_hand_rotate()
