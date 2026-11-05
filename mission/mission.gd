class_name Mission extends Resource


enum MissionState { INACTIVE, ACTIVE, COMPLETED, FAILED }

@export var mission_id: String
@export var description: String
@export var objectives: Array[String]
@export var objectives_complete : Array[String]
@export var dependence_key : String
@export var dependence_value : Variant
@export var state: MissionState = MissionState.INACTIVE
@export var save_game : bool
@export var range_player : float = 30.0
@export var limit_target: NodePath
@export var objective_timer : String
@export var timer_failure : float
@export var failure_screen : PackedScene 
@export_enum("3D","2D") var mode : String = "3D"

var piv : Node

func start() -> void:
	MissionManager.emit_signal("init_mission",self)
	if !save_game:
		Hitokoto.can_save = false
	state = MissionState.ACTIVE

func complete_objective(objective:String) -> void:
	if state != MissionState.ACTIVE:return
	objectives_complete.append(objective)
	if objectives_complete == objectives:complete()
	if !objective_timer.is_empty():
		if get_objetive(objective_timer) && timer_failure > 0.0:
			MissionManager.start_timer_failure(timer_failure)
		else:
			MissionManager.stop_timer_failure()

func complete() -> void:
	if !dependence_key.is_empty():
		Hitokoto.set_var(dependence_key,dependence_value)
	if !save_game:
		Hitokoto.can_save = true
	MissionManager.emit_signal("complete_mission",self)
	state = MissionState.COMPLETED

func fail_mission() -> void:
	state = MissionState.FAILED
	MissionManager.emit_signal("fail_mission",self)
	MissionManager.fail_screen(failure_screen)


func get_objetive(name:String) -> bool:
	var index : int = -1
	for objective in objectives_complete:
		index += 1
		if objective == name:
			return true
		if index >= objectives.size():
			push_error("not found a objetive with a name of " + name + " in mission " + mission_id)
	return false
