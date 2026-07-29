@tool
class_name Humanoid extends Entity

var inventory : Inventory = Inventory.new()
var interact : Interact = Interact.new()
var push_sense : PushSense = PushSense.new()
var fall : FallState = FallState.new()
var dialogue : DialogueManager = DialogueManager.new()

var timer_kill_rot = Timer.new()

enum ViewMode {
	CLOSE,
	FAR
}

@export var view_mode: ViewMode = ViewMode.FAR:
	set(value):
		view_mode = value
@export var max_rotate_head : float = 90.0
@export var rotation_self_duration: float = 0.2
@export_range(0,180,0.1,"prefer_slider") var max_angle : float = 45
@export_range(0.0,15,0.1) var measurement_shoulder : float = 1.0
@export var distance_interact : float = 3.0:
	set(value):
		distance_interact = value
		interact.distance_interact = distance_interact
@export var resistance_push : float = 7.5:
	set(value):
		resistance_push = value
		push_sense.strenght_limit = value

@export var fall_damage_threshold : float = 15.0

@export_range(0,99,0.1) var time_get_up : float = 7.5:
	set(value):
		time_get_up = value
		fall.time_get_up = time_get_up
@export_range(0,99,0.1) var time_fall : float = 3.0:
	set(value):
		time_fall = value
		fall.time_fall = time_fall
@export_range(0,99) var cooldown_jump : float = 1:
	set(value):
		cooldown_jump = value
		fall.cooldown_jump = cooldown_jump

@export var strafe : bool
@export var interrupt_movement : bool = true
@export var fall_damage : bool = true
@export var fallen_enabled : bool = true:
	set(value):
		fallen_enabled = value
		fall.fallen_enabled = fallen_enabled

@export var can_jump : bool = true:
	set(value):
		can_jump = value
		fall.can_jump = can_jump
@export var can_crouch : bool = true:
	set(value):
		can_crouch = value

@export_category("Inventory")
@export var only_interact : bool:
	set(value):
		only_interact = value
		inventory.call_deferred("just_interact",value)
@export var save_slot : bool = true
@export var can_change_slot : bool = true:
	set(value):
		can_change_slot = value
		inventory.can_change_slot = can_change_slot
@export var slot : int

@export var slot_interactive : int:
	set(value):
		slot_interactive = value
		inventory.slot_interactive = value
@export var default : Weapon = load("res://addons/Hitokoto´s Plugin/weapons/melee/fist.tres"):
	set(value):
		default = value
		inventory.default = value
@export var slots : Array[Asset] = []:
	set(value):
		slots = value
		inventory.slots = slots
@export var gun_attachment : Array[Array] = [
	[2,"holster_left","melee"],[1,"holster_right","melee"],[2,"holster_left","short"],[1,"holster_right","short"],[2,"gun_upper_back","large"],[1,"gun_shoulder","large"]
]

@export var ammo : Dictionary = {
	"melee" : 0,
	"general_ammo" : 0,
	"9mm" : 0,
	".45" : 0,
	".22" : 0,
	".16" : 0,
	".12" : 0,
}:
	set(value):
		ammo = value
		inventory.ammo = ammo
@export var inventory_slots : Array[Item] = []:
	set(value):
		inventory_slots = value
		inventory.inventory_slots = inventory_slots

var rotation_body : Quaternion

@export_category("Expressions")
@export var limit_distance_dialogue : bool = true:
	set(value):
		limit_distance_dialogue = value
		dialogue.limit_distance_dialogue = limit_distance_dialogue
@export var enabled_dialogue_damage : bool = true
@export var dialogues_damage : Array[DialogueData]
@export var exhausted_dialogue : DialogueData
@export var dialogue_fall : DialogueData:
	set(value):
		dialogue_fall = value
		fall.dialogue_fall = dialogue_fall


var neck_ik : SkeletonModifier3D
var torso_ik : SkeletonModifier3D
var cam_target : Marker3D = Marker3D.new()
var target_sight : Node3D = Node3D.new()
var holster_right : Node3D
var holster_left : Node3D
var gun_upper_back : Node3D
var gun_shoulder : Node3D
var hand_target : Node3D
var head_pos : Node3D
var head_mesh : Node3D


enum {EXAMINE=4,FALLEN=6}
enum {REPOS,AIM,SHOOT,CHARGING,HOLDITEM,USEITEM}

var state_hands : int

var dot : float
var measurement : float 

var neck_rotation : Vector3
var rotate_motion : Tween
var model_rot : Tween

var stop_tween : bool
var over_shoulder : bool 
var to_target_model : bool
var reproducing_dialogue_damage : bool

var current_anim_examine : String

signal in_cutscene
signal out_cutscene
signal in_limit_

signal finish_examine(anim:String,disrupted:bool)

func setup_signals_humanoid() -> void:
	var pause_callable = Callable(self, "pause")
	if !GameTime.in_pause_game.is_connected(pause_callable):
		GameTime.in_pause_game.connect(pause_callable)

func create_target_camera() -> void:
	if cam_target && !cam_target.is_inside_tree():
		add_child(cam_target)
		cam_target.position.y = 0.01
	if target_sight && !target_sight.is_inside_tree():
		cam_target.add_child(target_sight)
		target_sight.position.z = 0.5

func create_fall() -> void:
	add_child(fall)
	fall.in_freefall.connect(func():
		method(model,"in_freefall"))
	fall.get_up.connect(func():method(model,"get_up"))
	fall.fallen_down.connect(func():method(model,"fallen"))
	fall.jump.connect(func():
		method(model,"jump"))
	fall.impact_with_floor.connect(func(value):
		method(model,"impact_floor",[value])
		damage_impact(value))
	fall.kick_fall.connect(func(value):
		method(model,"push",[value])
		damage_impact(value))
	fall.JUMP_SIZE = JUMP_SIZE

func pause(value:bool) -> void:
	neck.rotation = neck_rotation
	rotate_model_assign()

func damage_impact(strenght:float) -> void:
	if !fall_damage:return
	if fall_damage_threshold < 0.0:return
	if strenght > fall_damage_threshold:
		take_damage(strenght)

func take_damage(damage: float) -> void:
	if !get_stadistic("Life"):return
	emit_signal("received_damage",damage)
	set_stadistic("Life",-damage)
	reproduce_damage_dialogue()
	await get_tree().create_timer(0.05).timeout
	if get_stadistic("Life") < 1:
		death()

func setup_mesh_references() -> void:
	if model && skeleton:
		add_child(timer_kill_rot)
		timer_kill_rot.wait_time = 0.35
		timer_kill_rot.timeout.connect(func():
			if rotate_motion && rotate_motion.is_running():
				rotate_motion.kill())
		holster_right = get_attachment("right")
		holster_left = get_attachment("left")
		gun_upper_back = get_attachment("upperback")
		gun_shoulder = get_attachment("shoulder")
		hand_target = get_attachment("hand")
		head_pos = get_attachment("head")
		neck_ik = find_node_name_reference(skeleton,"SkeletonModifier3D","neck_ik")
		torso_ik = find_node_name_reference(skeleton,"SkeletonModifier3D","torso_ik")

func get_attachment(word_key:String) -> Variant:
	if !find_node_name_reference(skeleton,"BoneAttachment3D",word_key).get_children():
		return find_node_name_reference(skeleton,"BoneAttachment3D",word_key)
	return find_node_name_reference(skeleton,"BoneAttachment3D",word_key).get_child(0)

func find_node_name_reference(node:Node,type:String,name:String) -> Variant:
	for child in node.get_children():
		if child.is_class(type) && child.name.to_upper().contains(name.to_upper()):
			return child
		else:
			for child_step_2 in child.get_children():
				if child_step_2.is_class(type) && child.name.to_upper().contains(name):
					return child
	return null

func i() -> void:
	dialogue.start_conversation()

func move_door() -> void:
	method(model,"move_door")

func create_model() -> void:
	if model_scene:
		add_child(model)
		if "user" in model:
			model.user = self
		setup_references_entity()
		create_collision()
		setup_signals_humanoid()
		setup_mesh_references()
		create_target_camera()
		call_deferred("agent")
		call_deferred("set_bones_names")

func create_collision() -> void:
	if collision && !collision.is_inside_tree():
		add_child(collision)

func set_bones_names() -> void:
	if neck_ik:
		neck_ik.bone_name = bone_neck
	if torso_ik:
		torso_ik.bone_name = bone_torso

###############################################################################################################################################
#TOOLS
###############################################################################################################################################

func run(value:bool) -> void:
	if !is_on_floor():return
	if strafe:
		if get_direction() == Direction.LEFT || get_direction() == Direction.RIGHT:
			return
	if !can_run || !is_on_floor() || is_walk_back():
		return
	if value:
		if velocity.length() > 0.1:
			state = RUN
		else:
			state = IDLE
	else:
		if velocity.length() > 0.1:
			state = WALK
		else:
			state = IDLE

func create_inventory() -> void:
	add_child(inventory)
	inventory.current_slot = slot
	inventory.hand_target = hand_target
	inventory.gun_attachment = gun_attachment


# func load_propietys() -> void:
# 	inventory.ammo = ammo
# 	inventory.inventory_slots = inventory_slots
# 	inventory.slots = slots

# func update_propietys() -> void:
# 	if save_slot:
# 		slot = inventory.current_slot
# 	ammo = inventory.ammo
# 	inventory_slots = inventory.inventory_slots
# 	slots = inventory.slots

func examine(anim : String,animation_duration:float=0.0) -> void:
	if state == Entity.WALK || state == Entity.IDLE:
		if !has_animation(anim):
			return
		if interpolation:
			interpolation.set_animation(5,anim)
		current_anim_examine = anim
		state = Humanoid.EXAMINE
		# lock_state = true
		velocity = Vector3.ZERO
		set_ik_bones(false,animation_duration)
		if animation_duration > 0:
			await get_tree().create_timer(animation_duration).timeout
			examin_stop()

func examin_stop() -> void:
	emit_signal("finish_examine",current_anim_examine)
	current_anim_examine = ""
	if state == Humanoid.EXAMINE:
		state = Humanoid.IDLE
		

func hide_head() -> void:
	if !head_mesh:
		return
	set_mesh_transparency_recursive(head_mesh, 1.0)

func set_mesh_transparency_recursive(node: Node, alpha: float) -> void:
	if node is MeshInstance3D:
		node.transparency = alpha

	for child in node.get_children():
		set_mesh_transparency_recursive(child, alpha)

func show_head() -> void:
	if head_mesh:
		head_mesh.transparency = 0

func init_cutscene() -> void:
	emit_signal("in_cutscene")
	set_ik_bones(false)

func exit_cutscene() -> void:
	emit_signal("out_cutscene")
	set_ik_bones(true)

func set_ik_bones(value:bool,time:float = 0.0) -> void:
	for child in skeleton.get_children():
		if child is SkeletonIK3D:
			if child.is_in_group("pass_ik"):continue
			if "stop_ik" in child && !value:
				child.stop_ik(time)
				continue
			if "play_ik" in child && value:
				child.play_ik()
				continue
			child.active = value

func talking(dialogue:DialogueData) -> void:
	method(model,"talking",[dialogue])
	if "ik_bones" in dialogue.propertys:
		set_ik_bones(dialogue.propertys["ik_bones"],dialogue.duration)


###############################################################################################################################################
#ANIMATION
###############################################################################################################################################

func started_alignment() -> void:
	neck.rotation = Vector3.ZERO
	stop_rotate()

func stop_rotate() -> void:
	stop_tween = true
	if rotate_motion:
		rotate_motion.kill()
	await get_tree().process_frame
	stop_tween = false

func advancing_to_wall() -> bool:
	return dot < -0.97

func get_body_down(distance :float = 1.2,excluded_nodes: Array = []) -> Node3D:
	var space_state = get_world_3d().direct_space_state
	var exclude_rids: Array = []
	for n in excluded_nodes:
		if n is CollisionObject3D:
			exclude_rids.append(n.get_rid())
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * distance)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFFFFFF
	while true:
		query.exclude = exclude_rids
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return null
		var collider = result.collider
		if collider is PhysicalBone3D:
			if collider is CollisionObject3D:
				exclude_rids.append(collider.get_rid())
			continue
		for n in excluded_nodes:
			if collider == n or n.is_ancestor_of(collider):
				if collider is CollisionObject3D:
					exclude_rids.append(collider.get_rid())
				continue
		return collider
	return null

func exclude_body_physics() -> void:
	if !is_on_floor():
		if (get_body_down() is CharacterBody3D) || !get_body_down():
			floor_max_angle = 0.0
		else:
			floor_max_angle = deg_to_rad(max_angle)

func movement_direction(direction:Vector3,delta:float) -> void:
	call_deferred("exclude_body_physics")
	if is_walk_back() && state == RUN:
		state = WALK
	if fall.in_free_fall():
		return
	match state:
		IDLE:increase_energy(delta)
		WALK:increase_energy(delta)
		RUN:decreased_energy(delta)
	if is_exhausted():
		state = WALK
		return
	if !can_move:return
	if interrupt_movement:
		if is_on_wall() && is_on_floor():
			var n := get_wall_normal()
			n.y = 0
			n = n.normalized()
			var dir := direction
			dir.y = 0
			dir = dir.normalized()
			var rdot := dir.dot(n)
			dot = rdot
			if dot < -0.9:
				velocity -= (n * velocity.dot(n))
				state = IDLE
				return
		if velocity.length() > 0.1:
			var n := get_wall_normal()
			n.y = 0
			n = n.normalized()
			var dir := direction
			dir.y = 0
			dir = dir.normalized()
			var rdot := dir.dot(n)
			dot = rdot
	if direction:
		var target_x = direction.x * (CURRENT_SPEED_LIMIT)
		var target_z = direction.z * (CURRENT_SPEED_LIMIT)
		velocity.x = move_toward(velocity.x, target_x, accel * delta)
		velocity.z = move_toward(velocity.z, target_z, accel * delta)
		if state == IDLE && dot > -0.9:
			state = WALK
	else:
		if state == WALK || state == RUN:
			state = IDLE


func movement_model(target: Node3D, velocity: Vector2, delta: float) -> void:
	if advancing_to_wall():
		return
	if strafe:
		if (get_direction() == Direction.RIGHT || get_direction() == Direction.LEFT) && !is_walk():
			set_model_relative_to_target()
			return
	if get_direction() == Direction.RIGHT && (neck.rotation_degrees.y > 90):
		return
	if get_direction() == Direction.LEFT && (neck.rotation_degrees.y < -90):
		return
	var move_direction = -target.global_basis.z * velocity.y + -target.global_basis.x * velocity.x
	if get_direction() == Direction.BACK || get_direction() == Direction.BACK_RIGHT || get_direction() == Direction.BACK_LEFT:
		move_direction = target.global_basis.z * velocity.y + target.global_basis.x * velocity.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	var last_direction = Vector3.BACK
	if move_direction.length() > 0.2:
		last_direction = move_direction
	var target_angle = Vector3.BACK.signed_angle_to(last_direction,Vector3.UP)
	var main_keys = (get_direction() == Direction.BACK) || (get_direction() == Direction.FORWARD)
	var neck_back : bool = (neck.rotation_degrees.y < -90 || neck.rotation_degrees.y > 90)
	var laterals_keys = (get_direction() == Direction.RIGHT) || (get_direction() == Direction.LEFT  || 
	get_direction() == Direction.FORWARD_RIGHT) || (get_direction() == Direction.FORWARD_LEFT || get_direction() == Direction.BACK_RIGHT) || (get_direction() == Direction.BACK_LEFT)
	var current_angle = (model.global_rotation.y)
	var interval_angle = blend_speed*delta
	if model && !(model_rot && model_rot.is_running()):
		if main_keys:
			model.global_rotation.y = (lerp_angle((current_angle),target_angle,interval_angle))
			return
		if !neck_back && laterals_keys:
			model.global_rotation.y = (lerp_angle((current_angle),target_angle,interval_angle))

func animation_rotate_look(delta:float)  -> void:
	if !model:return
	neck.look_at(target_sight.global_position,Vector3.UP,true)
	neck_rotation = neck.rotation
	measurement = -measurement_shoulder
	over_shoulder = is_on_over_shoulder_view(neck.rotation_degrees)
	if over_shoulder:
		if can_move:
			if model.rotation.y > 0:
				measurement = abs(measurement)
			if measurement > 0:
				method(model,"over_shoulder_view",[Vector3.RIGHT])
			else:
				method(model,"over_shoulder_view",[Vector3.LEFT])
			var current_angle = (model.global_rotation.y)
			var interval_angle = blend_speed*delta
			if (view_mode == ViewMode.CLOSE  || (view_mode == ViewMode.FAR && state == WALK)) && !stop_tween :
				if !(model_rot && model_rot.is_running()):
					set_ik_bones(false,rotation_self_duration)
					rotate_motion = create_tween()
					timer_kill_rot.start()
					rotate_motion.tween_property(model,"rotation:y",model.rotation.y-measurement,rotation_self_duration)
	neck.rotation.y = clamp(neck.rotation.y,-1,1)
	rotate_model_assign()

func is_on_over_shoulder_view(marker_rotation_degrees: Vector3,tolerance:float=0.0) -> bool:
	var max = max_rotate_head
	if state == IDLE:
		return marker_rotation_degrees.y < -max-tolerance || marker_rotation_degrees.y > max+tolerance
	return marker_rotation_degrees.y < -max-tolerance || marker_rotation_degrees.y > max+tolerance

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
	set_ik_bones(false,0.2)
	var current_basis = global_transform.basis
	var target_rotation = Basis().looking_at(direction, Vector3.UP)
	global_transform.basis = current_basis.slerp(
		target_rotation,
		(speed_rotation * 10) * get_process_delta_time()
	).orthonormalized()

func rotate_model_assign() -> void:
	rotation_body = Quaternion.from_euler(Vector3(deg_to_rad(-neck.rotation_degrees.x),deg_to_rad(neck.rotation_degrees.y),0.0))
	if !inventory.aim:
		torso_in_view()
	else:
		torso_in_stroke()

func torso_in_view() -> void:
	if neck_ik && torso_ik:
		torso_ik.target_rotation = skeleton.get_bone_rest(torso_index).basis.get_rotation_quaternion()
		neck_ik.target_rotation = rotation_body
	else:
		if !(neck_index == -1):
			skeleton.set_bone_pose_rotation(neck_index,rotation_body)

func torso_in_stroke() -> void: 
	if neck_ik && torso_ik:
		neck_ik.target_rotation = skeleton.get_bone_rest(neck_index).basis.get_rotation_quaternion()
		torso_ik.target_rotation = rotation_body
	else:
		if !(torso_index == -1):
			skeleton.set_bone_pose_rotation(torso_index,rotation_body)

func set_model_relative_to_target() -> void:
	if model_rot && model_rot.is_running():
		return
	to_target_model = true
	model_rot = create_tween()
	model_rot.tween_property(model,"rotation:y",0.0,0.2)
	await model_rot.finished
	to_target_model = false




###############################################################################################################################################
#DIALOGUE
###############################################################################################################################################

func create_dialogue_manager() -> void:
	add_child(dialogue)

func reproduce_damage_dialogue() -> void:
	if !enabled_dialogue_damage && dialogue.is_talking:return
	if reproducing_dialogue_damage:return
	reproducing_dialogue_damage = true
	var dialogue_damage := get_random_element(dialogues_damage)
	dialogue.reproduce_dialogue(dialogue_damage)
	await get_tree().create_timer(dialogue_damage.duration+0.1).timeout
	reproducing_dialogue_damage = false


func reproduce_exhausted_dialogue() -> void:
	if is_exhausted():
		if !dialogue.is_talking:
			dialogue.reproduce_dialogue(exhausted_dialogue)
