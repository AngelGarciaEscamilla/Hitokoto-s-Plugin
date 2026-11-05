@tool
@icon("res://addons/Hitokoto´s Plugin/icons/indication.png")
class_name MissionStarter extends Area3D

@export var mission : Mission 

signal start

var visibility : VisibleOnScreenEnabler3D = VisibleOnScreenEnabler3D.new()

func _ready():
	monitorable = false
	Hitokoto.save(self)
	body_entered.connect(enter)
	add_child(visibility)
	set_collision_layer_value(3,true)
	set_collision_layer_value(4,true)
	set_collision_mask_value(3,true)
	set_collision_mask_value(4,true)

func enter(body:Node) -> void:
	if mission && body == Hitokoto.get_player_3d():
		emit_signal("start")
		MissionManager.add_mission(mission)
		MissionManager.start_mission(mission.mission_id)
		queue_free()

