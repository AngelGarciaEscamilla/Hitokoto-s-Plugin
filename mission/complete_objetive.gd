@tool
@icon("res://addons/Hitokoto's Plugin/icons/indication.png")
class_name CompleteObjetive extends Area3D

@export var id_mission : String 
@export var objective : String 

signal complete_objetive(id_mission,objetive)

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

func enter(body) -> void:
	if !(body == Hitokoto.get_player_3d()) || id_mission.is_empty():return
	if !objective.is_empty() && MissionManager.get_mission(id_mission) && MissionManager.get_mission(id_mission).state == Mission.MissionState.ACTIVE:
		MissionManager.complete_objective(id_mission,objective)
		emit_signal("complete_objetive",id_mission,objective)
		queue_free()

