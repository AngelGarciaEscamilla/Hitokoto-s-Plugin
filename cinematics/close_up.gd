@tool
@icon("res://addons/Hitokoto's Plugin/icons/close_up.webp")
class_name CloseUp extends Area3D

var body_ : Node
var current_camera : Camera3D 

var transition : Node

@export var transition_scene : PackedScene
@export var cam_path : NodePath:
	set(value):
		cam_path = value
var camera : Camera3D
@export var captured_mouse : bool = true
@export var size_area : Vector3 = Vector3.ONE:
	set(value):
		size_area = value
		update_gizmos()

func _ready() -> void:
	create_area()
	set_signals()


func set_signals() -> void:
	self.body_entered.connect(enter)
	self.body_exited.connect(exit)
	set_collision_layer_value(4,true)
	set_collision_layer_value(4,true)

func create_area():
	self.monitorable = false

func enter(body:Node3D):
	camera = get_node_or_null(cam_path)
	if !camera:
		return
	if !body_:
		body_ = Hitokoto.get_player_3d()
	if body != body_:return
	current_camera = get_viewport().get_camera_3d()
	tween_enter(body)

func exit(body:Node3D):
	if !camera:return
	if body != body_:return
	await tween_exit(body)
	if camera.current:
		tween_exit(body)

func tween_enter(body) -> void:
	if !transition_scene:
		intro()
		return
	transition = transition_scene.instantiate()
	add_child(transition)
	if transition:
		await transition.enter()
	if !get_overlapping_bodies().has(body):
		exit_()
		return
	intro()
	if transition:
		await transition.exit()

func tween_exit(body) -> void:
	if !transition_scene:
		exit_()
		return
	if transition:
		await transition.enter()
	exit_()
	if transition:
		await transition.exit()
		transition.queue_free()

func intro() -> void:
	if !captured_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera.current = false
	camera.make_current()

func exit_() -> void:
	if !captured_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	current_camera.make_current()
