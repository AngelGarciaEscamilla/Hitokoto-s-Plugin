class_name Bullet extends Area3D


var timer = Timer.new()

var damage : float 
var scope : float
var velocity : float
var forward 
var user : Node3D

signal damage_body(body)

func _ready() -> void:
	if scope == 0:return
	add_child(timer)
	timer.timeout.connect(destroy)
	timer.wait_time = scope
	timer.start()

func _process(delta):
	global_position += forward * velocity * delta

func _on_body_entered(body:Node3D) -> void:
	if body == user:return
	method(body,"get_attack",[user])
	method(body,"take_damage",[damage])
	emit_signal("damage_body",body)
	destroy()

func method(user:Node,method:String,args := []) -> void:
	if user && user.has_method(method):
		if get_method_node_args(user,method).size() != args.size():
			return
		if args && !get_method_node_args(user,method):
			args = []
		user.callv(method,args)

func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []

func destroy() -> void:
	await get_tree().process_frame
	queue_free()
