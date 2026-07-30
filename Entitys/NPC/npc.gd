@tool
@icon("res://addons/Hitokoto´s Plugin/icons/npcr.png")
class_name NPC extends Humanoid

enum Behaviour {REST,WALK,TALKING,FALL,FALLEN}

var not_change_property_freeze : Dictionary = {}
var move_head : bool = true
var rotate_to_target : bool
var is_freeze : bool 
var target_rotation_y := 0.0
@export var target_look : Node3D
@export var target : NodePath
@export var old_target : Node
@export var timeline : Timeline:
	set(value):
		timeline = value
		dialogue.timeline = timeline
@export var run_motion : bool:
	set(value):
		run_motion = value
		call_deferred("run",run_motion)
@export var inherited_global_rotation : bool = true
@export var knockback_interrupt : float = 2.5
@export var limit_look : float = 75
var current_behaviour : Behaviour = Behaviour.REST

func _ready() -> void:
	Hitokoto.save(self) 
	in_target.connect(in_target_node)
	add_child(interpolation)
	call_deferred("create_dialogue")
	if !Engine.is_editor_hint():
		create_fall()
		fall.get_up.connect(get_up)
	settings_layers()
	create_inventory()
	create_interact()
	add_child(push_sense)
	push_sense.push.connect(push)
	dead.connect(death_entity)
	set_model_relative_to_target()

func create_interact() -> void:
	add_child(interact)

func create_inventory():
	inventory.use_inventory = false
	add_child(inventory)
	inventory.current_slot = slot
	inventory.hand_target = hand_target
	inventory.gun_attachment = gun_attachment

func freeze(value:bool) -> void:
	state = IDLE
	if is_freeze == value:return
	current_behaviour = Behaviour.REST
	velocity = Vector3.ZERO
	var propertys : Dictionary = {
		"can_move":can_move,
		"inventory.can_change_slot":inventory.can_change_slot,}
	if value :
		for prop in propertys.keys():
			if !propertys[prop]:
				not_change_property_freeze[prop] = propertys[prop]
	is_freeze = value
	can_move = !value
	inventory.can_change_slot = !value
	if !value:
		for prop in not_change_property_freeze.keys():
			if prop.contains("inventory."):
				prop = prop.replace("inventory.","")
				inventory[prop] = not_change_property_freeze[prop]
			self[prop] = not_change_property_freeze[prop]



func update_propietys() -> void:
	timeline = dialogue.timeline.duplicate()
	slot = inventory.current_slot
	ammo = inventory.ammo
	inventory_slots = inventory.inventory_slots
	slots = inventory.slots

func create_dialogue() -> void:
	create_dialogue_manager()
	dialogue.init_dialogue.connect(init_dialogue)
	dialogue.finished_dialogue.connect(end_dialogue)
	dialogue.timeline = timeline

func settings_layers() -> void:
	self.set_collision_mask_value(4,true)
	self.set_collision_layer_value(4,true)

func _physics_process(delta:float) -> void:
	if Engine.is_editor_hint():
		return
	if !interrupt_movement:
		if get_body_in_front() && get_body_in_front().has_method("apply_knockback") && velocity.length() > 0.1:
			var position: Vector3 = global_position
			var forward = -global_transform.basis.z
			position += forward * 1
			get_body_in_front().apply_knockback(position,knockback_interrupt)
	match state:
		Entity.WALK:go_to(get_node_or_null(target),delta)
		Entity.RUN:go_to(get_node_or_null(target),delta)
	if !is_on_floor():
		if !fall.is_in_free_fall:
			current_behaviour = Behaviour.FALL
		else:
			current_behaviour = Behaviour.FALLEN
	else:
		if current_behaviour == Behaviour.FALL:
			current_behaviour = Behaviour.REST
	move_and_slide()
	if rotate_to_target:
		rotation.y = lerp_angle(
			rotation.y,
			target_rotation_y,
			delta * 8.0
		)

		if abs(angle_difference(rotation.y, target_rotation_y)) < 0.01:
			rotation.y = target_rotation_y
			rotate_to_target = false

func _process(delta:float) -> void:
	if Engine.is_editor_hint():
		return
	var local_vel: Vector3 = global_transform.basis.inverse() * velocity
	var input_vec := Vector2(local_vel.x, local_vel.z)
	if input_vec.length() > 0.05:
		input_vec = input_vec.normalized()
	else:
		input_vec = Vector2.ZERO
	if get_node_or_null(target) && can_move:
		var target_pos: Vector3 = get_node_or_null(target).global_position
		var direction = (target_pos - global_position).normalized()
		movement_direction(direction,delta)
	if !is_freeze:
		movement_model(self,input_vec,delta)
	process_behaviour()
	if target_look:
		cam_target.rotation.y = clamp(cam_target.rotation.y,-deg_to_rad(limit_look),deg_to_rad(limit_look))
		smooth_look_at(cam_target, target_look.global_position, 1)
	else:
		reposition_head()
	call_deferred("animation_rotate_look",delta)


func reposition_head() -> void:
	var tween :Tween = create_tween()
	tween.tween_property(cam_target,"rotation",Vector3.ZERO,0.5)
	set_model_relative_to_target()
	tween.tween_callback(tween.kill)

func init_dialogue(dialogue:DialogueData) -> void:
	if (dialogue in dialogues_damage):
		return
	current_behaviour = Behaviour.TALKING
	state = IDLE
	if interrupt_movement:
		old_target = get_node_or_null(target)
		target = NodePath()
	if !dialogue.propertys.has("look_at_user"):return
	var user : Node3D = get_node_or_null(dialogue.user_path)
	if user == self || !user:
		if dialogue.propertys.has("reposition_head"):
			target_look = null
			reposition_head()
		return
	if user is Node3D:
		target_look = user

func end_dialogue(dialogue:DialogueData) -> void:
	if dialogue.propertys.has("reposition_head"):
		target_look = null
		reposition_head()
	current_behaviour = Behaviour.REST
	if interrupt_movement && old_target:
		target = old_target.get_path()


###############################################################################
#BEHAVIOR
############################################################################################

func push(strenght:float) -> void:
	current_behaviour = Behaviour.FALLEN

func get_up() -> void:
	current_behaviour = Behaviour.REST

func process_behaviour() -> void:
	if current_behaviour != Behaviour.REST:return
	if !in_destination():
		if get_node_or_null(target):
			move_to_position(get_node_or_null(target).get_path())
	else:
		if is_on_floor():
			state = IDLE

func move_to_position(target_:NodePath)->void:
	if !target || !can_move || !(Hitokoto.get_navigation_mesh() && Hitokoto.get_navigation_mesh().navigation_mesh) || in_destination():return
	current_behaviour = Behaviour.WALK
	target = target_
	await get_tree().create_timer(0.35).timeout
	run(run_motion)

func in_target_node() -> void:
	current_behaviour = Behaviour.REST
	if inherited_global_rotation && velocity.length() > 0.1:
		target_rotation_y = get_node(target).rotation.y
		rotate_to_target = true

func in_destination() -> bool:
	if get_node_or_null(target):
		return round_number_vector(global_position,true) == round_number_vector(get_node_or_null(target).global_position,true)
	return false



############################################################################################
#STADISTICS
############################################################################################

func death_entity() -> void:
	Hitokoto.remove_save(self)
	inventory.hide_inventory()
	inventory.drop_all_items()
