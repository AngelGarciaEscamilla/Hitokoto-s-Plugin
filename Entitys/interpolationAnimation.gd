@tool
class_name InterpolationState extends Component


####################################################################################################################
#if is share a animation with the array "animations" here for example "test" this same for default be 0.0 if the user is not in the state of tha animation
#please use for that list of animations array , individual animations
#####################################################################################################################


const PARAMETERSPATH : String = "parameters/"
const BLENDAMOUNTPATH : String = "/blend_amount"
const WALKBACKWARDPATH : String = "parameters/walkbackward/blend_amount"
const WALKPATH : String = "parameters/walk/blend_amount"

var value_anim : Array[float] = []

@export var blend_speed : float = 7.0
@export var enabled_ready_animations : bool = true
@export var animations : Array[String] = ["idle","walk","run","fall","fallen","test","test","test","test","test","test","test"
		,"walk_backward","strafe_left","strafe_right","crouch","crouch_walk","crouch_walk_back","crouch_strafe_left","crouch_strafe_right",]:
		set(value):
			animations = value
			value_anim.resize(animations.size()-1)
			value_anim.fill(0.0)


var current_animations : Array[int] = []

var index_walk : int = 1
var index_idle : int 

var crouch : CrouchState 
var inventory : Inventory
var animation_tree : AnimationTree

func _ready():
	if get_parent() is Node3D:
		set_user()
		call_deferred("find_sibling")
		value_anim.resize(animations.size()-1)
		value_anim.fill(0.0)


func find_sibling():
	crouch = find_node(user,"CrouchState")
	inventory = find_node(user,"Inventory")
	animation_tree = find_node(user,"AnimationTree")

func find_node(node: Node, class_type:String) -> Node:
	if node.is_class(class_type):
		return node
	for child in node.get_children():
		if child.name == class_type || child.name == class_type+node.name:
			return child
		var result = find_node(child, class_type)
		if result:
			return result
	return null
	
func _process(delta:float) -> void:
	if Engine.is_editor_hint() || !animation_tree: return
	handle_animation(delta)
	update_animations()

func interpolate_anim_value(path: String, start_value: float, end_value: float, duration: float) -> void:
	var tween := create_tween()
	animation_tree[PARAMETERSPATH+path+BLENDAMOUNTPATH] = start_value
	tween.tween_property(animation_tree, path, end_value, duration)

func get_animation_value(path:String) -> float:
	return animation_tree[PARAMETERSPATH+path+BLENDAMOUNTPATH]

func animation_value(path:String,value_in_dictionary:int) -> void:
	if !animation_tree:return
	var anim : String = PARAMETERSPATH+path+BLENDAMOUNTPATH
	var node_tr : AnimationNodeBlendTree = animation_tree.tree_root
	if !node_tr.has_node(path):
		return
	animation_tree[PARAMETERSPATH+path+BLENDAMOUNTPATH] = value_anim[value_in_dictionary]

func comprobate_state_anim(x:int,delta:float) -> void:
	if !user.model_scene: return
	for i in value_anim.size()-1:
		var interpolation : float = 0.0
		if i == x || i in current_animations:
			interpolation = 1.0
			if !(i in current_animations):
				current_animations.append(i)
		if !(i == x):
			current_animations.erase(i)
		value_anim[i] = lerp(value_anim[i],interpolation,delta)

func set_animation(index:int,value:String) -> void:
	if index >= 0 || index < animations.size():
		animations[index] = value

func get_animation(index:int) -> String:
	if index >= 0 || index < animations.size():
		return animations[index]
	return ""

func handle_animation(delta:float) -> void:
	if !user.model_scene: return
	var blend_speed_normalized : float = blend_speed * delta
	if !has_state():return
	match user.state:
		Entity.IDLE:comprobate_state_anim(index_idle,blend_speed_normalized)
		Entity.WALK:comprobate_state_anim(index_walk,blend_speed_normalized)
		Entity.RUN:comprobate_state_anim(2,blend_speed_normalized)
		Entity.FALL:comprobate_state_anim(3,blend_speed_normalized)
		Humanoid.FALLEN:comprobate_state_anim(4,blend_speed_normalized)
		Humanoid.EXAMINE:comprobate_state_anim(5,blend_speed_normalized)
	if !("state_hands" in user):return
	if (inventory.is_interacted() && !inventory.current_item):
		state_hands_value_zero(0.1,delta)
		return
	match user.state_hands:
		Humanoid.REPOS:
			comprobate_state_anim(6,blend_speed_normalized)
		Humanoid.AIM:
			comprobate_state_anim(7,blend_speed_normalized)
		Humanoid.CHARGING:
			comprobate_state_anim(8,blend_speed_normalized)
		Humanoid.HOLDITEM:
			comprobate_state_anim(9,blend_speed_normalized)
		Humanoid.USEITEM:
			comprobate_state_anim(10,blend_speed_normalized)
		Humanoid.SHOOT:
			comprobate_state_anim(11,blend_speed_normalized)
	
	
func state_hands_value_zero(interpolation:float,delta:float) -> void:
	if !get_animation(6).is_empty():
		value_anim[6] = lerp(value_anim[6],0.0,interpolation)
	if !get_animation(7).is_empty():
		value_anim[7] = lerp(value_anim[7],0.0,interpolation)
	if !get_animation(8).is_empty():
		value_anim[8] = lerp(value_anim[8],0.0,interpolation)
	if !get_animation(9).is_empty():
		value_anim[9] = lerp(value_anim[9],0.0,interpolation)
	if !get_animation(10).is_empty():
		value_anim[10] = lerp(value_anim[10],0.0,interpolation)
	if !get_animation(11).is_empty():
		value_anim[11] = lerp(value_anim[11],0.0,interpolation)

func update_animations() -> void:
	if !user.model_scene: return
	for anim in animations.size()-1:
		animation_value(animations[anim],anim)
	if !enabled_ready_animations:return
	if crouch:
		if !crouch.is_crouching:
			normal_anims()
		else:
			index_idle = 15
			if get_direction() == 0:
				index_walk = 16
			if is_walk_back():
				index_walk = 17
			if "strafe" in user && user.strafe:
				if get_direction() == 7:
					index_walk = 18
				if get_direction() == 3:
					index_walk = 19
			if is_walk():
				index_walk = 16
	else:normal_anims()

func normal_anims() -> void:
	index_idle = 0
	index_walk = 1
	if is_walk_back():
		index_walk = 12
	if "strafe" in user && user.strafe:
		if get_direction() == 7:
			index_walk = 13
		if get_direction() == 3:
			index_walk = 14
	if is_walk():
		index_walk = 1

func get_direction() -> int:
	if !("velocity" in user):
		return -1
	if user.velocity.length() < 0.01:
		return 0

	var local_vel: Vector3 = user.global_transform.basis.inverse() * user.velocity

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
	elif v < -t:
		return -1
	return 0

func is_walk_back() -> bool:
	return get_direction() == 5|| get_direction() == 4|| get_direction() == 6

func is_walk() -> bool:
	return get_direction() == 1|| get_direction() == 2 || get_direction() == 8
