@tool
extends Node

var failure_timer : Timer = Timer.new()

@export var missions: Dictionary = {}

@export var current_scene_node : Node

var current_mission : Mission

var player : Node

signal init_mission(mission:Mission)
signal complete_mission(mission:Mission)
signal fail_mission(mission:Mission)

func _ready() -> void:
	init_mission.connect(init_mission_)

func add_mission(mission:Mission) -> void:
	missions[mission.mission_id] = mission

func start_mission(id:String) -> void:
	if missions.has(id):
		if missions[id].state == missions[id].MissionState.ACTIVE:return
		missions[id].start()

func complete_objective(id: String,objective:String) -> void:
	if missions.has(id):
		missions[id].complete_objective(objective)

func get_mission(id:String) -> Mission:
	if missions.has(id):
		return missions[id]
	return null

func get_active_missions() -> Array:
	var mission_activate = []
	for m in missions.values():
		if m.state == Mission.MissionState.ACTIVE:
			mission_activate.append(m)
	return mission_activate

func get_active_missions_names() -> Array:
	var mission_activate = []
	for m in missions.values():
		if m.state == Mission.MissionState.ACTIVE:
			mission_activate.append(m.mission_id)
	return mission_activate

func get_failed_missions() -> Array:
	var mission_activate = []
	for m in missions.values():
		if m.state == Mission.MissionState.FAILED:
			mission_activate.append(m)
	return mission_activate

func _process(delta:float) -> void:
	if !get_active_missions() || !current_mission:return
	if !(get_pivote_node(current_mission.limit_target) && current_mission):return
	if !on_near_from_target(player,current_mission.range_player,get_pivote_node(current_mission.limit_target)):
		current_mission.fail_mission()

func get_pivote_node(limit_target: NodePath) -> Node:
	if limit_target.is_empty():return null
	if get_tree().current_scene.get_children():
		return get_tree().current_scene.get_child(0).get_node_or_null(limit_target)
	return null

func on_near_from_target(user: Node3D,distance:float,target:Node3D) -> bool:
	if distance < 0:return true
	if !user || !target: return false
	return user.global_position.distance_squared_to(target.global_position) <= distance * distance


func start_timer_failure(time:float) -> void:
	add_child(failure_timer)
	failure_timer.ignore_time_scale = true
	failure_timer.wait_time = time
	failure_timer.timeout.connect(failure_timeout)
	failure_timer.start()

func get_time_left_failure() -> float:
	if failure_timer && failure_timer.is_inside_tree() && !failure_timer.is_stopped():
		return failure_timer.time_left
	return 0

func stop_timer_failure():
	failure_timer.stop()
	if failure_timer.is_inside_tree():
		failure_timer.queue_free()

func failure_timeout() -> void:
	if !current_mission:
		push_error("not exist a current mission to failure with timeout")
		return
	current_mission.fail_mission()
	stop_timer_failure()

func init_mission_(mission:Mission) -> void:
	current_mission = mission
	if mission.mode.to_lower() == "3D".to_lower():
		player = Hitokoto.get_player_3d()
	else:
		player = Hitokoto.get_player_2d()

func fail_screen(packed:PackedScene) -> void:
	if packed:
		add_child(packed.instantiate())
