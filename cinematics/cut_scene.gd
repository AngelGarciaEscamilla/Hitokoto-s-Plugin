class_name CutScene extends Node3D

@export var property_data_name : String = "data"
@export var packed_scene : PackedScene
@export var data : Array[NodePath]

var scene : Node
var current_camera : Camera3D 
var data_positions: Array 

var is_playing : bool

var player : Node
var cam : Camera3D
var anim : AnimationPlayer

signal enter
signal exit

func get_data_nodes() -> Array[Node]:
	var data_nodes : Array
	for node in data:
		data_nodes.append(get_node(node))
		method(get_node(node),"init_cutscene",[])
	return data_nodes

func add_current_cutscene() -> void:
	var data_nodes : Array = get_data_nodes()
	if property_data_name in scene:
		scene[property_data_name] = data_nodes
	add_child(scene)

func freeze_data_nodes() -> void:
	for node in data:
		if "cam_target" in get_node(node) && get_node(node).cam_target is Node3D:
			get_node(node).cam_target.rotation.x = 0
		method(get_node(node),"freeze",[true])

func setting_nodes_in_cutscene() -> void:
	if !scene:return
	for child in scene.get_children():
		if child is AnimationPlayer:
			anim = child
		if child is Path3D:
			for i in data:
				var node = get_node(i)
				if !child.get_children():return
				var child_follower = child.get_child(0)
				if !child_follower.get_children():return
				var child_marker = child_follower.get_child(0)
				if child_marker.name.to_lower().contains(node.name.to_lower()):
					data_positions.append([child_marker,node])
		if child is Marker3D:
			for i in data:
				var node = get_node(i)
				if child.name.to_lower().contains(node.name.to_lower()):
					data_positions.append([child,node])

func play() -> void:
	if is_playing:
		scene.queue_free()
	data_positions = []
	emit_signal("enter")
	scene = packed_scene.instantiate()
	freeze_data_nodes()
	add_current_cutscene()
	setting_nodes_in_cutscene()
	cam = find_camera(scene)
	current_camera = find_camera(Hitokoto.get_player_3d())
	if !current_camera:
		current_camera = get_viewport().get_camera_3d()
	if anim:
		for animation in anim.get_animation_list():
			if animation == "RESET":continue
			anim.play(animation)
			break
	is_playing = true

func stop() -> void:
	is_playing = false
	emit_signal("exit")
	for node in data:

		method(get_node(node),"exit_cutscene",[])
	for node in data:
		method(get_node(node),"freeze",[false])
	current_camera.make_current()
	scene.queue_free()

func _process(delta:float) -> void:
	if !is_playing:return
	for node in data_positions:
		if node:
			node[1].global_position = node[0].global_position
			node[1].global_rotation.y = node[0].global_rotation.y
			node[1].global_rotation.x = node[0].global_rotation.x
	if cam:
		cam.make_current()


##############################################################################################################################################################################################
#METHODS
##############################################################################################################################################################################################

func find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node
	for child in node.get_children():
		var result = find_camera(child)
		if result:
			return result
	return null


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
