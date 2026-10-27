@tool
class_name InterpolationState extends Component



var value_anim : Array[float] = []

@export var animation_paths : Array[String] = ["parameters/locomotion/blend_position","parameters/locomotion/advance/blend_position",
"parameters/fall/blend_amount","parameters/fallen/blend_amount"]
@export var blend_speed : float = 7.0

var current_animations : Array[int] = []

var index_walk : int = 1
var index_idle : int 

var crouch : CrouchState 
var inventory : Inventory
var animation_tree : AnimationTree
var fall : FallState

func _ready():
	if get_parent() is Node3D:
		set_user()
		call_deferred("find_sibling")


func find_sibling():
	crouch = find_node(user,"CrouchState")
	inventory = find_node(user,"Inventory")
	fall = find_node(user,"FallState")
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

var current_speed = Vector2.ZERO
var target_speed
var strafe_acc = 3
var smooth_fall : float
var smooth_fallen : float
var value_aim : float
var value_shoot : float
var value_charger : float
var value_repos : float
var value_examine : float
var current_weapon_anim : Weapon

var value_hold_item : float
var value_use_item : float
var current_item_anim : Item

var anim_examine : String

var current_velocity : float

func _process(delta:float) -> void:
	if Engine.is_editor_hint() || !animation_tree: return
	if user.strafe:
		target_speed = Vector2(user.input_dir.x,-user.input_dir.y).normalized()
	else:
		target_speed = Vector2(0,user.direction.length()).normalized()
		if user.current_state == Entity.State.IDLE:
			target_speed = Vector2.ZERO
	current_speed = current_speed.move_toward(-target_speed,strafe_acc*delta)
	var strafe_input = Vector2(current_speed.x,-current_speed.y)
	var blend := 1.0 - exp(-blend_speed * delta)

	smooth_fall = lerp(smooth_fall,float(!user.is_on_floor() && user.collidable),0.1)
	smooth_fallen = lerp(smooth_fallen,float("current_state" in user && user.current_state == Humanoid.State.FALLEN),0.1)
	value_examine = lerp(value_examine,float("current_state" in user && user.current_state == Humanoid.State.EXAMINE && !anim_examine.is_empty()),blend)
	value_aim = lerp(value_aim,float(inventory.aim),blend)
	value_shoot = lerp(value_shoot,float(inventory.is_shooting),blend)
	value_charger = lerp(value_charger,float(inventory.is_charging()),blend)
	value_repos = lerp(value_repos,1.0,blend)

	animation_tree.set(animation_paths[0],strafe_input)
	current_velocity = lerp(current_velocity,user.velocity.length(),7.0 * delta)
	animation_tree.set(animation_paths[1],current_velocity)
	animation_tree.set(animation_paths[2],smooth_fall)
	animation_tree.set(animation_paths[3],smooth_fallen)
	animation_tree.set("parameters/"+anim_examine+"/blend_amount",value_examine)
	if current_weapon_anim && current_weapon_anim != inventory.current_weapon:
		var tween = create_tween().set_parallel(true)
		var type = current_weapon_anim.type_weapon
		var paths = [
			"parameters/aim" + type + "/blend_amount",
			"parameters/repos" + type + "/blend_amount",
			"parameters/shoot" + type + "/blend_amount",
			"parameters/charger" + type + "/blend_amount"
		]
		for path in paths:
			if animation_tree.get(path) != null:
				tween.tween_property(animation_tree, path, 0.0, blend)
	if inventory && inventory.current_weapon:
		current_weapon_anim = inventory.current_weapon
		animation_tree.set("parameters/aim"+inventory.current_weapon.type_weapon+"/blend_amount",value_aim)
		animation_tree.set("parameters/shoot"+inventory.current_weapon.type_weapon+"/blend_amount",value_shoot)
		animation_tree.set("parameters/charger"+inventory.current_weapon.type_weapon+"/blend_amount",value_charger)
		animation_tree.set("parameters/repos"+inventory.current_weapon.type_weapon+"/blend_amount",value_repos)
		
	value_hold_item = lerp(value_hold_item,float(inventory && inventory.current_asset_in_hand()),blend)
	value_use_item = lerp(value_use_item,float(inventory && inventory.is_using),blend)
	if inventory && inventory.current_item:
		if !current_item_anim:
			current_item_anim = inventory.current_item
		animation_tree.set("parameters/"+inventory.current_item.hold_anim+"/blend_amount",value_hold_item)
		animation_tree.set("parameters/"+inventory.current_item.use_anim+"/blend_amount",value_use_item)
	if current_item_anim:
		animation_tree.set("parameters/"+current_item_anim.hold_anim+"/blend_amount",value_hold_item)
		animation_tree.set("parameters/"+current_item_anim.use_anim+"/blend_amount",value_use_item)
