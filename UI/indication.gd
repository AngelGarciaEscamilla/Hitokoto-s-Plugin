@tool
@icon("res://addons/Hitokoto's Plugin/icons/indication.png")
class_name IndicationAlert extends Area3D

var timer : Timer = Timer.new()

var canvas : CanvasLayer = CanvasLayer.new()

@export var activate : bool 
@export var time_indication : float = 5.0
@export var indication_interface_scene : PackedScene = preload("res://addons/Hitokoto's Plugin/UI/indication.tscn")
@export var indication : TranslatorText
@export var mission : Mission
@export var in_objetive : String
var indication_interface : IndicationInterface = indication_interface_scene.instantiate()

var visibility : VisibleOnScreenEnabler3D = VisibleOnScreenEnabler3D.new()

var one_time : bool 

func _ready() -> void:
	MissionManager.fail_mission.connect(func(value):delete_indication())
	monitorable = false
	Hitokoto.save(self)
	add_child(visibility)
	body_entered.connect(enter)
	set_collision_layer_value(3,true)
	set_collision_layer_value(4,true)
	set_collision_mask_value(3,true)
	set_collision_mask_value(4,true)

func enter(body:Node3D) -> void:
	if !(body == Hitokoto.get_player_3d()):return
	if !mission:
		if activate:
			start_indication()
	else:
		if in_objetive.is_empty():
			if mission.state == mission.MissionState.ACTIVE:
				start_indication()
		else:
			if mission.state == mission.MissionState.ACTIVE && mission.get_objetive(in_objetive):
				start_indication()

func start_indication() -> void:
	if indication && !one_time:
		create_indication()
		method(indication_interface,"set_indication",[indication.current_lenguage_text()])
		timer.start()
		Hitokoto.remove_save(self)
		if !get_shapes():return
		for i in get_shapes():
			i.disabled = true

func get_shapes() -> Array[CollisionShape3D]:
	var shapes : Array[CollisionShape3D]
	for child in get_children():
		if child is CollisionShape3D:
			shapes.append(child)
	return shapes
			

func create_indication() -> void:
	add_child(canvas)
	canvas.add_child(timer)
	timer.wait_time = time_indication
	timer.timeout.connect(delete_indication)
	canvas.layer = -1
	canvas.add_child(indication_interface)

func method(node:Node,method:String,args := []) -> void:
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() > args.size():
			return
		if args && !get_method_node_args(node,method):
			args = []
		node.callv(method,args)

func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []


func delete_indication() -> void:
	if indication_interface:
		await method(indication_interface,"exit")
		indication_interface.queue_free()



