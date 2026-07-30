@tool
class_name Entity extends CharacterBody3D

enum Direction {IDLE=0,FORWARD=1,RIGHT=3,LEFT=7,BACK=5,FORWARD_RIGHT=2,BACK_RIGHT=4,BACK_LEFT=6,FORWARD_LEFT=8}

@export var stadistics : Dictionary = {
	"Life" : 200,
	"Life_limit": [0,200],
	"Energy": 20,
	"Energy_limit":[0,20],
}
@export_range(0,50) var blend_speed : float = 11.0
@export_range(0,50) var friction : float = 0.0
@export_range(0.0,20,0.1) var WALK_SPEED : float = 2.5
@export_range(0,50) var JUMP_SIZE : float = 19.0:
	set(value):
		JUMP_SIZE = value
		var fall : FallState = get_fall()
		if fall:
			fall.JUMP_SIZE = JUMP_SIZE

func get_fall(node: Node = self) -> FallState:
	for child in node.get_children():
		if child is FallState:
			return child

		var fall : FallState = get_fall(child)
		if fall:
			return fall

	return null

@export_range(0.0,20,0.1) var RUN_SPEED : float = 4.0
var CURRENT_SPEED_LIMIT : float = 0.0
var CURRENT_SPEED : float = 0.0
@export var accel : float = 4.0

@export_category("Model")
var collision : CollisionShape3D = CollisionShape3D.new()
@export var model_scene : PackedScene:
	set(value):
		model_scene = value
		if model && model.is_inside_tree():
			model.queue_free()
			model = null
		if model_scene:
			model = model_scene.instantiate()
		create_model()
@export var collision_shape : Shape3D = CapsuleShape3D.new():
	set(value):
		collision_shape = value
		collision.shape = collision_shape

@export var collidable : bool = true:
	set(value):
		collidable = value
		collision.disabled = !value
		emit_signal("set_move")

@export var can_move : bool = true:
	set(value):
		can_move = value
		emit_signal("set_move")

@export var can_run : bool = true:
	set(value):
		can_run = value
		if !value:
			run(false)
	get:
		return can_run
	
var model : Node3D
var animation_tree : AnimationTree
var skeleton : Skeleton3D 
@export_category("bone")
@export var look_at_target : bool = true
@export var bone_neck : String
@export var bone_torso : String
var torso_index : int
var neck_index : int
var neck : Marker3D = Marker3D.new()

@export var name_path : String
@export var function_path : String = "update_target_location"

enum {IDLE,WALK,RUN,FALL}
var state : int = IDLE:
	set(value):
		if lock_state:return
		var old_state : int = state
		state = value
		if state == IDLE:
			var smooth_idle_x = create_tween()
			var smooth_idle_z = create_tween()
			smooth_idle_x.tween_property(self,"velocity:x",0.0,0.2)
			smooth_idle_z.tween_property(self,"velocity:z",0.0,0.2)
		var speed_state : Array = [0,WALK_SPEED,RUN_SPEED]
		if state < FALL:
			CURRENT_SPEED_LIMIT = speed_state[state]
		emit_signal("in_state",old_state,state)

var nav_agent = NavigationAgent3D.new()
var interpolation : InterpolationState = InterpolationState.new()

const WALKPATH : String = "parameters/walk/blend_amount"
const RUNPATH : String = "parameters/run/blend_amount"
const IDLEPATH : String = "parameters/idle/blend_amount"
const FALLPATH : String = "parameters/fall/blend_amount"

const PARAMETERSPATH : String = "parameters/"
const BLENDAMOUNTPATH : String = "/blend_amount"

var lock_state : bool
var kick_knockback : bool
var touch_target : bool

var tween_animation : Tween

signal in_state(old_state,new_state)
signal setting_stadistic
signal received_damage(damage:float)
signal dead
signal set_move
signal in_target


func setup_references_entity() -> void:
	if model_scene:
		animation_tree = find_node(model,"AnimationTree")
		skeleton = find_node(model,"Skeleton3D")
		if neck && !neck.is_inside_tree():
			model.call_deferred("add_child",neck)
			neck.rotation_degrees.y = 180
		call_deferred("find_bones")
	else:
		push_warning("dont found a model scene")


func find_bones() -> void:
	if model_scene && model:
		neck_index = skeleton.find_bone(bone_neck)
		torso_index  = skeleton.find_bone(bone_torso)

func create_collision() -> void:
	if collision && !collision.is_inside_tree():
		add_child(collision)

func agent() -> void:
	add_child(nav_agent)
	add_to_group(name_path)

func create_model() -> void:
	if model_scene:
		create_collision()
		add_child(model)
		if "user" in model:
			model.user = self
		setup_references_entity()



###############################################################################################################################################
#NAVIGATION AND TARGET
###############################################################################################################################################


func get_direction() -> int:
	if velocity.length() < 0.01:
		return 0

	var local_vel: Vector3 = global_transform.basis.inverse() * velocity

	var x := axis(local_vel.x)
	var z := axis(local_vel.z)
	var dir = Vector2i(x, z)

	if dir == Vector2i(0, -1):
		return 1
	if dir == Vector2i(1, 0):
		return 3
	if dir == Vector2i(-1, 0):
		return 7
	if dir == Vector2i(-1, -1):
		return 8
	if dir == Vector2i(1, -1):
		return 2
	if dir == Vector2i(1, 1):
		return 4
	if dir == Vector2i(-1, 1):
		return 6
	if dir == Vector2i(0, 1):
		return 5
	return 0


func axis(v: float, t := 0.25) -> int:
	if v > t:
		return 1
	if v < -t:
		return -1
	return 0

func apply_knockback(from_position: Vector3, force: float, force_jump: float = 0.1) -> void:
	method(model, "apply_knockback", [force])
	kick_knockback = true
	var direction = global_transform.origin - from_position
	direction = direction.normalized()
	velocity += direction * force
	velocity.y = force_jump 
	await until_stopped()
	kick_knockback = false

func until_stopped():
	while velocity.length() > 0.01:
		await get_tree().process_frame

func get_side(target: Vector3) -> float:
	var forward = -global_transform.basis.z
	var direction = (target - global_transform.origin).normalized()
	var cross = forward.cross(direction)
	return cross.y

func get_body_in_front() -> Node3D:
	var forward = -global_transform.basis.z.normalized()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Node3D:
			var dir = (collider.global_transform.origin - global_transform.origin).normalized()
			var dot = forward.dot(dir)
			if dot > 0.7:
				return collider
	return null

func get_body() -> Node3D:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Node3D:
			if collider.global_position.y < global_position.y-(scale.y):
				continue
			return collider

	return null

func movement_direction(direction:Vector3,delta:float) -> void:
	if !can_move || kick_knockback:return
	match state:
		IDLE:increase_energy(delta)
		WALK:increase_energy(delta)
		RUN:decreased_energy(delta)
	if is_exhausted():
		state = WALK
		return
	if is_on_wall() && is_on_floor():
		var n := get_wall_normal()
		var dir := direction.normalized()
		var dot := dir.dot(n)
		if dot < -0.9 && is_on_floor():
			velocity -= n * velocity.dot(n)
			state = IDLE
			return
	if direction:
		var target_x = direction.x * (CURRENT_SPEED_LIMIT - friction)
		var target_z = direction.z * (CURRENT_SPEED_LIMIT - friction)
		velocity.x = move_toward(velocity.x, target_x, accel * delta)
		velocity.z = move_toward(velocity.z, target_z, accel * delta)
		if state == IDLE:
			state = WALK
	else:
		if state == WALK || state == RUN:
			state = IDLE

func movement_model(target:Node3D,velocity:Vector2,delta:float) -> void:
	if get_direction() == Direction.RIGHT && (neck.rotation_degrees.y > 90):
		return
	if get_direction() == Direction.LEFT && (neck.rotation_degrees.y < -90):
		return
	var move_direction = -target.global_basis.z * velocity.y + -target.global_basis.x * velocity.x
	if get_direction() == Direction.BACK || get_direction() == Direction.BACK_RIGHT || get_direction() == Direction.BACK_LEFT:
		move_direction = target.global_basis.z * velocity.y + target.global_basis.x * velocity.x
	var last_direction = Vector3.BACK
	if move_direction.length() > 0.2:
		last_direction = move_direction
	var target_angle = Vector3.BACK.signed_angle_to(last_direction,Vector3.UP)
	var main_keys = (get_direction() == Direction.BACK) || (get_direction() == Direction.FORWARD)
	var neck_back : bool = (neck.rotation_degrees.y < -90 || neck.rotation_degrees.y > 90)
	var laterals_keys = (get_direction() == Direction.RIGHT) || (get_direction() == Direction.LEFT  || 
	get_direction() == Direction.FORWARD_RIGHT) || (get_direction() == Direction.FORWARD_LEFT || get_direction() == Direction.BACK_RIGHT) || (get_direction() == Direction.BACK_LEFT)
	if model:
		var current_angle = (model.global_rotation.y)
		var interval_angle = blend_speed*delta
		if main_keys:
			model.global_rotation.y = (lerp_angle((current_angle),target_angle,interval_angle))
			return
		if !neck_back && laterals_keys:
			model.global_rotation.y = (lerp_angle((current_angle),target_angle,interval_angle))

func run(value:bool):
	if !can_run || !is_on_floor() || is_walk_back():
		return
	if value:
		if velocity.length() > 0.2:
			state = RUN
		else:
			state = IDLE
	else:
		if velocity.length() > 0.2:
			state = WALK
		else:
			state = IDLE

func round_number(value: float) -> float:
	var rounded = round(value * 100) / 100
	if abs(rounded) < 0.01:
		return 0.0
	return rounded

func lerp_angle_op(from: float, to: float, weight: float) -> float:
	var diff = wrapf(to - from, -PI, PI)

	if diff >= 0:
		diff -= TAU
	else:
		diff += TAU

	return from + diff * weight

func move_node_3d(node:Node3D,to_node:Node3D) -> void:
	var g = node.global_transform
	remove_child(node)
	node.global_transform = g
	to_node.add_child(node)

func move_node(node:Node,to_node:Node) -> void:
	remove_child(node)
	to_node.add_child(node)

func update_target_location(target_location:Vector3) -> void:
	nav_agent.set_target_position(target_location)

func look_axis_y(target: Vector3, speed_rotation: float = 1):
	var my_position = global_transform.origin
	target.y = my_position.y
	var direction = target - my_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var forward = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var cross = forward.cross(direction)
	var measurement = cross.y
	if abs(measurement) > 0.1:
		if measurement > 0:
			method(model, "over_shoulder_view", [Vector3.LEFT])
		else:
			method(model, "over_shoulder_view", [Vector3.RIGHT])
	var current_basis = global_transform.basis
	var target_rotation = Basis().looking_at(direction, Vector3.UP)
	global_transform.basis = current_basis.slerp(
		target_rotation,
		(speed_rotation * 10) * get_process_delta_time()
	).orthonormalized()

func go_to(destination:Node3D,delta:float,transition:float=1) -> void:
	if !destination || !can_move || kick_knockback: return
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location-current_location).normalized()
	if round_number_vector(global_position,true) == round_number_vector(destination.global_position,true):
		state = IDLE
		emit_signal("in_target")
		touch_target = true
		await get_tree().create_timer(1.5).timeout
		if touch_target:
			touch_target = false
		return
	else:
		if look_at_target && !touch_target:
			look_axis_y(next_location,transition)
	movement_direction(new_velocity,delta)
	get_tree().call_group(name_path,function_path,destination.global_position)



static func round_number_vector(vec:Vector3,y_null:bool=false) -> Vector3:
	var xround = round(vec.x * 3) / 3.0
	var yround = round(vec.y * 3) / 3.0
	var zround = round(vec.z * 3) / 3.0
	if y_null:
		yround = 0
	return Vector3(xround,yround,zround)

func is_walk_back() -> bool:
	return get_direction() == Direction.BACK || get_direction() == Direction.BACK_RIGHT || get_direction() == Direction.BACK_LEFT

func is_walk() -> bool:
	return get_direction() == Direction.FORWARD || get_direction() == Direction.FORWARD_RIGHT || get_direction() == Direction.FORWARD_LEFT


###############################################################################################################################################
#ANIMATION
###############################################################################################################################################

func has_animation(animation:String) -> bool:
	var anim : String = PARAMETERSPATH+animation+BLENDAMOUNTPATH
	var node_tr : AnimationNodeBlendTree = animation_tree.tree_root
	return node_tr.has_node(animation)

func play(animation:String,time:float=0.0,interpolation:float=0.2) -> void:
	var anim : String = PARAMETERSPATH+animation+BLENDAMOUNTPATH
	if !animation_tree:return
	if animation_tree[anim] == 1.0:return
	tween_animation = create_tween()
	tween_animation.tween_method(
	func(value):
		animation_tree.set(anim, value),
	animation_tree[anim], 1.0, interpolation)
	tween_animation.tween_callback(tween_animation.kill)
	await tween_animation.finished
	await get_tree().create_timer(time).timeout
	
func stop(animation:String,interpolation:float=0.2) -> void:
	var value_init : float = animation_tree[PARAMETERSPATH+animation+BLENDAMOUNTPATH]
	tween_animation = create_tween()
	tween_animation.tween_method(
	func(value):
		animation_tree.set(PARAMETERSPATH + animation + BLENDAMOUNTPATH, value),
	value_init, 0.0, interpolation)
	tween_animation.tween_callback(tween_animation.kill)

#########################################################################################################
#STADISTICS
#########################################################################################################

func is_exhausted() -> bool:
	if get_stadistic("Energy") <= get_stadistic("Energy_limit")[0]:
		return true
	return false

func set_stadistic(path:String,value:Variant) -> void:
	path = find_key(stadistics,path)
	if !get_stadistic(path):return
	if !path.contains("_limit"):
		if stadistics.has(path+"_limit"):
			stadistics[path] = clamp(stadistics[path],stadistics[path+"_limit"][0],stadistics[path+"_limit"][1])
		if !stadistics.has(path+"_limit"):
			stadistics[path] = clamp(stadistics[path],0,9999)
		stadistics[path] += value
	else:
		stadistics[path][1] += value
	emit_signal("setting_stadistic",value)

func get_stadistic(path:String) -> Variant:
	if !stadistics.has(path):return null
	return stadistics[find_key(stadistics,path)]

func find_key(dict:Dictionary, key:String) -> String:
	var search = key.to_lower()
	for k in dict.keys():
		if k.to_lower() == search:
			return k
	return ""

func take_damage(damage: float) -> void:
	if !get_stadistic("Life"):return
	emit_signal("received_damage",damage)
	set_stadistic("Life",-damage)
	method(model,"received_damage",[damage])
	if get_stadistic("Life") < 1:
		death()

func death() -> void:
	var inv = find_inventory(self)
	emit_signal("dead")
	if inv:
		inv.set_physics_process(false)
		inv.set_process_input(false)
	set_physics_process(false)
	set_process_input(false)
	method(model,"death")

func eliminate() -> void:
	var inv = find_inventory(self)
	if inv:
		if "inventory" in model && model.inventory is Array:
			model.inventory = inv.get_items()
	move_node_3d(model,get_tree().current_scene)
	queue_free()

func find_inventory(node: Node) -> Inventory:
	if node is Inventory:
		return node
	for child in node.get_children():
		var result = find_inventory(child)
		if result:
			return result
	return null


#########################################################################################################
#TOOLS
#########################################################################################################


func increase_energy(delta: float) -> void:
	if state != RUN:
		set_stadistic("Energy",0.6 * delta)

func decreased_energy(delta: float) -> void:
	if state == RUN && !is_walk_back():
		set_stadistic("Energy",-delta)

func set_childrens(value:bool) -> void:
	for i in get_children():
		i.set_physics_process(value)
		i.set_process(value)
		i.set_process_input(value)

static func get_random_element(array: Array) -> Variant:
	if array.size() == 1:
		return array[0]
	if array.is_empty():
		return null
	return array[randi() % array.size()-1]


func find_node(node:Node,type:String) -> Variant:
	for child in node.get_children():
		if child.is_class(type):
			return child
		for grandchild in child.get_children():
			if grandchild.is_class(type):
				return grandchild
	return null


func smooth_look_at(node: Node3D, target: Vector3, duration: float = 1.0):
	var start_basis = node.global_transform.basis
	var end_basis = node.global_transform.looking_at(target, Vector3.UP).basis
	var tween := get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var node_path := node.get_path()
	tween.tween_method(
		func(value):
			var n = get_node_or_null(node_path)
			if n:
				n.global_transform.basis = start_basis.slerp(end_basis, value),
		0.0, 1.0, duration / 10
	)

func method(node:Node,method:String,args := []) -> void:
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() > args.size():
			return
		if args && !get_method_node_args(node,method):
			args = []
		await node.callv(method,args)

func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []
