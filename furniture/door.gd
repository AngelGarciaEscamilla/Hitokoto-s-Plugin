@tool
@icon("res://addons/Hitokoto's Plugin/icons/door.png")
class_name Door extends StaticBody3D

@export var examin_anim : String = "test"
@export var call_method_kicker : String = "examine"
@export var animation_kick : bool = true
@export var closed : bool:
	set(value):
		closed = value
		call_deferred("set_alignment")
		collision.disabled = !value
		await call_deferred("set_door_faces",!value)
		if value:
			call_deferred("anim_door",0,door_back,null,0.2)

var alignment_node : AlignmentUser = AlignmentUser.new()
@export var door_open : AudioStream
@export var door_kick : AudioStream
@export var door_to_pound : AudioStream

@export var degrees_open_door : float = 90
@export var velocity_to_pound : float = 4
@export var interpolation : float = 1.0

@export_node_path() var alignment_path : NodePath
var alignment : Node3D
@export var duration_kick : float = 1.0

var visibility : VisibleOnScreenEnabler3D = VisibleOnScreenEnabler3D.new()

@export var hinge : PackedScene = preload("res://addons/Hitokoto's Plugin/furniture/hinge.tscn"):
	set(value):
		hinge = value
		if door_tree && door_tree.is_inside_tree():
			door_tree.queue_free()
			door_tree = null
		if value:
			door_tree = hinge.instantiate()
		create_hinge()
@onready var door_tree : Node
@onready var door : StaticBody3D 
@onready var piv : StaticBody3D = StaticBody3D.new()

var door_front : RayCast3D 
var door_back : RayCast3D
var collision : CollisionShape3D = CollisionShape3D.new()
var sfx : SFX = SFX.new()
var door_anim :Tween 
var body_ : Node3D

signal kick

func _ready() -> void:
	Hitokoto.save(self)
	if hinge:
		door_tree = hinge.instantiate()
		create_hinge()
	add_child(visibility)
	add_child(alignment_node)
	add_child(collision)
	collision.shape = BoxShape3D.new()
	self.set_collision_layer_value(2,true)
	self.set_collision_layer_value(1,false)
	alignment_node.finished_alignment.connect(kick_anim)

func set_alignment() -> void:
	if !alignment_path: 
		push_error("dont found alignment"+str(self))
		return
	if has_node(alignment_path):
		alignment = get_node(alignment_path)

func create_hinge():
	if door_tree:
		add_child(door_tree)
		setting_door()


func setting_door():
	if !door_tree:return
	if door_tree.find_child("Door").find_child("doorFront") is RayCast3D:
		door_front = door_tree.find_child("Door").find_child("doorFront")
	if door_tree.find_child("Door").find_child("doorBack") is RayCast3D:
		door_back = door_tree.find_child("Door").find_child("doorBack")
	if door_tree.find_child("SFX") is AudioStreamPlayer3D:
		sfx = door_tree.find_child("SFX")
	door = door_tree.find_child("Door")


func _physics_process(delta):
	if Engine.is_editor_hint():
		setting_door()
	ray_collider()

func set_door_faces(value:bool) -> void:
	if door_tree:
		door_front.enabled = value
		door_back.enabled = value

func get_door_faces() -> bool:
	return door_front.enabled && door_back.enabled

var move_door : bool

func ray_collider() -> void:
	if !door_tree:return
	if !door:return
	var rays : Dictionary = {
		door_back:degrees_open_door,
		door_front:-degrees_open_door}
	for part in rays.keys():
		if !part:return
		if part.is_colliding() && get_door_faces():
			if !move_door:
				if is_equal_approx(door.rotation.y,deg_to_rad(rays[part])):
					return
				method(part.get_collider(),"move_door")
				move_door = true
			anim_door(rays[part],part,part.get_collider(),interpolation)

func anim_door(degrees:float,ray:RayCast3D,user:Node,interpolation:float = 1.0) -> void:
	if !door:return
	if is_instance_valid(door_anim):
		door_anim.kill()
	door_anim = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	door_anim.tween_property(door,"rotation:y",deg_to_rad(degrees),interpolation)
	door_anim.tween_callback(func():
		move_door = false
		init_anim(ray,user))

func i(r:Node3D) -> void:
	if !closed:return
	var inventory : Inventory
	for child in r.get_children():
		if child is Inventory:
			inventory = child
	if animation_kick && alignment:
		alignment_node.alignment = alignment
		alignment_node.play_alignment(r)
		if inventory:
			inventory.slot_select(inventory.slot_interactive)
	if !animation_kick:
		play_effect_sound(sfx,door_kick)
		if inventory:
			inventory.slot_select(inventory.slot_interactive)
		if door_kick:
			await get_tree().create_timer(door_kick.get_length()).timeout
		emit_signal("kick")
	body_ = r

func init_anim(ray:RayCast3D,user:Node) -> void:
	if (user is PhysicalBone3D) || !user:return
	if "velocity" in user:
		if user.velocity.length() > velocity_to_pound:
			play_effect_sound(sfx,door_to_pound)
			return
	play_effect_sound(sfx,door_open)

func play_effect_sound(sfx:SFX,audio:AudioStream) -> void:
	if sfx:return
	sfx.stream = audio
	sfx.play()

func kick_anim() -> void:
	if !body_.has_method(call_method_kicker):return
	method(body_,"freeze",[true])
	method(body_,call_method_kicker,[examin_anim,duration_kick])
	await get_tree().create_timer(duration_kick).timeout
	emit_signal("kick")
	method(body_,"freeze",[false])

func method(node:Node,method:String,args := []) -> void:
	if !node:return
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() != args.size():
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
