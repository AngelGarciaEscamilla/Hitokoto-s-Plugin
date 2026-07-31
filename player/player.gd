@tool
@icon("res://addons/Hitokoto´s Plugin/icons/player.png")
class_name Player extends Humanoid

enum KeyAction {JUST_PRESSED,PRESSED,RELEASED}


#NODE3D
var node_camera :Node3D = Node3D.new()


#MESHINSTANCE
var screen_take_damage : ScreenCallBack = ScreenCallBack.new()

#PACKEDSCENES
@export var inventory_scene : PackedScene:
	set(value):
		inventory_scene = value 
		inventory.inventory_scene = inventory_scene
@export var death_screen : PackedScene 
@export var damage_screen : PackedScene
#EXPORTS
#################################################################
@export var focus_node : Node3D:
	set(value):
		focus_node = value
		if !focus_node:
			if reposition_head && reposition_head.is_running():return
			reposition_head = create_tween()
			reposition_head.tween_property(cam_target, "rotation", Vector3.ZERO, 0.3)
@export var basis_target : NodePath
var lock_view : bool:
	set(value):
		lock_view = value
		self_yaw = self.rotation.y
@export var use_inventory : bool = true:
	set(value):
		use_inventory = value
		inventory.use_inventory = use_inventory
@export_category("Camera")
var current_sensibility_cam : Vector2
@export var limit_cam : float = 80
@export var lock_horizontal_view : bool 
@export var camera_input : bool = true
@export var mouse_captured : bool = true:
	set(value):
		mouse_captured = value
		if Engine.is_editor_hint():return
		call_deferred("captured_mouse",value)
@export var max_rotate_cam_target : Vector2 = Vector2(-0.8,1)
@export var sensibility_cam : Vector2 = Vector2(1.0,1.0)


@export_category("Keys")
@export var idle_jump : bool
@export var up_key : String
@export var down_key : String
@export var right_key : String
@export var left_key : String
@export var run_key : String

@export var shoot_key : String:
	set(value):
		shoot_key = value

@export var inventory_key : String:
	set(value):
		inventory_key = value

@export var charger_key : String:
	set(value):
		charger_key = value

@export var jump_key : String:
	set(value):
		jump_key = value

@export var interact_key : String:
	set(value):
		interact_key = value
		
@export var aim_key : String:
	set(value):
		aim_key = value

@export var undo_key : String:
	set(value):
		undo_key = value

@export var use_key : String:
	set(value):
		use_key = value

var cam_move : bool = true
var is_freeze : bool 
var not_change_property_freeze : Dictionary = {}
var blocked_direction : String

var mouse_input : Vector2
var self_yaw : float 
var last_press_time := 0.0
var press_count := 0

var global_event : InputEvent

var reposition_head : Tween

signal key_pressed(key:String,action:int)

func _ready() -> void:
	set_move.connect(func():lock_view = !can_move)
	Hitokoto.save(self)
	MissionManager.fail_mission.connect(failure)
	create_components()
	create_inventory()
	create_interact()
	create_dialogue_manager()
	print_stack()
	print_debug("Start Player"+":"+OS.get_name())
	received_damage.connect(take_damage_player)
	dead.connect(death_player)
	if !Engine.is_editor_hint():
		captured_mouse(mouse_captured)
		create_fall()
		setting_node()
		create_screen_damage()
	set_model_relative_to_target()

func create_screen_damage() -> void:
	add_child(screen_take_damage)
	screen_take_damage.screen_scene = damage_screen

func create_components() -> void:
	add_child(push_sense)
	add_child(interpolation)

func init_cutscene() -> void:
	focus_node = null
	emit_signal("in_cutscene")
	set_ik_bones(false)

func exit_cutscene() -> void:
	focus_node = null
	emit_signal("out_cutscene")
	set_ik_bones(true)

###############################################################################
#INPUT
###############################################################################

func inventory_button() -> void:
	if InputMap.has_action(inventory_key) && Input.is_action_just_released(inventory_key):
		inventory.hide_inventory()
	if InputMap.has_action(inventory_key):
		if Input.is_action_pressed(inventory_key):
			inventory.show_inventory()
		remove_item_button()
	if InputMap.has_action(use_key) && Input.is_action_just_pressed(use_key) && inventory.is_using:
		inventory.undo_use_item()

func remove_item_button() -> void:
	if !InputMap.has_action(undo_key):return
	if Input.is_action_just_pressed(undo_key):
		inventory.remove_item(inventory.current_item_index)

func used_button() -> void:
	if !InputMap.has_action(use_key):return
	if Input.is_action_just_pressed(use_key):
		inventory.used_item(inventory.current_item)

func charger_button() -> void:
	if !InputMap.has_action(charger_key):return
	if Input.is_action_just_pressed(charger_key):
		inventory.charger_current_slot()

func aim_button() -> void:
	if !InputMap.has_action(aim_key):return
	if Input.is_action_just_pressed(aim_key):
		inventory.aim = true
	if Input.is_action_just_released(aim_key):
		inventory.aim = false

func shoot_button() -> void:
	if !InputMap.has_action(shoot_key):return
	if Input.is_action_pressed(shoot_key):
		inventory.shoot()
	else:
		inventory.undo_shoot()
	
func interact_state() -> void:
	match state:
		Entity.IDLE:
			if InputMap.has_action(interact_key) && Input.is_action_just_pressed(interact_key):
				interact.interact(interact.collider_index)
		Entity.WALK:
			if InputMap.has_action(interact_key) && Input.is_action_just_pressed(interact_key):
				interact.interact(interact.collider_index)

func jump_button(delta: float):
	if Input.is_action_pressed(down_key):return
	if key_input(jump_key,KeyAction.JUST_PRESSED):
		fall.jump_action(delta)

func run_button() -> void:
	if key_input(run_key,KeyAction.JUST_PRESSED):
		run(true)
	if key_input(run_key,KeyAction.RELEASED):
		run(false)

###############################################################################
#CREATE_TREE_____________________________________________________________________
###############################################################################

func create_interact() -> void:
	add_child(interact)

func setting_node() -> void:
	current_sensibility_cam = sensibility_cam
	self.set_collision_mask_value(4,true)
	self.set_collision_layer_value(4,true)
	await get_tree().process_frame
	lock_view = !can_move


###############################################################################
#MOVEMENT_____________________________________________________________________
########################################################################################

func freeze(value:bool) -> void:
	state = IDLE
	if is_freeze == value:return
	var propertys : Dictionary = {
		"can_move":can_move,
		"cam_move":cam_move,
		"can_change_slot":can_change_slot,
		"use_inventory":use_inventory}
	if value :
		for prop in propertys.keys():
			if !propertys[prop]:
				not_change_property_freeze[prop] = propertys[prop]
	is_freeze = value
	can_move = !value
	cam_move = !value
	can_change_slot = !value
	use_inventory = !value
	if !value:
		for prop in not_change_property_freeze.keys():
			self[prop] = not_change_property_freeze[prop]


func captured_mouse(value:bool) -> void:
	if value:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func camera_move(event: InputEvent) -> void:
	if !cam_target || !cam_move || !camera_input || focus_node:return
	global_event = event
	if event is InputEventMouseMotion:
		if !lock_horizontal_view:
			cam_target.rotation.x -= event.relative.y * current_sensibility_cam.x / 1000
			cam_target.rotation.x = clamp(cam_target.rotation.x, max_rotate_cam_target.x, max_rotate_cam_target.y)
			self.rotation.y -= event.relative.x * current_sensibility_cam.y / 1000
		else:
			if key_input(up_key) || key_input(down_key):
				self.rotation.y -= event.relative.x * current_sensibility_cam.y / 1000
		if lock_view && view_mode == ViewMode.CLOSE:
			var delta_angle = angle_difference(self_yaw, rotation.y)
			delta_angle = clamp(delta_angle, -deg_to_rad(limit_cam), deg_to_rad(limit_cam))
			rotation.y = self_yaw + delta_angle
		mouse_input = event.relative
		var should_rotate_model := false
		if model:
			if lock_view && view_mode == ViewMode.CLOSE:
				var min_rot = round_number(self_yaw - deg_to_rad(limit_cam))
				var max_rot = round_number(self_yaw + deg_to_rad(limit_cam))
				var rotate_model = round_number(self.rotation.y)
				if !(rotate_model <= min_rot || rotate_model >= max_rot):
					should_rotate_model = true
			else:
				should_rotate_model = true
		if (key_input(up_key) && model && (!lock_view)):
			should_rotate_model = true
		if lock_view:
			model.global_rotation.y = self_yaw
		if should_rotate_model:
			model_rot_with_per_bodie()

func model_rot_with_per_bodie() -> void:
	model.rotation.y += global_event.relative.x * current_sensibility_cam.y / 1000

func movement(delta: float) -> void:
	var input_dir = Input.get_vector(left_key, right_key, up_key, down_key)
	var target = basis_target
	if target.is_empty():
		target = self.get_path()
	var direction = (get_node(target).global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var local_vel: Vector3 = global_transform.basis.inverse() * velocity
	var input_vec := Vector2(local_vel.x, local_vel.z)
	if input_vec.length() > 0.05:
		input_vec = input_vec.normalized()
	else:
		input_vec = Vector2.ZERO
	movement_direction(direction,delta)
	movement_model(cam_target,input_vec,delta)


func _physics_process(delta:float) -> void:
	if Engine.is_editor_hint():return
	interact_state()
	match state:
		IDLE:
			run_button()
			shoot_button()
			used_button()
			inventory_button()
			charger_button()
			if idle_jump:
				jump_button(delta)
		WALK:
			inventory_button()
			used_button()
			charger_button()
			shoot_button()
			run_button()
			jump_button(delta)
		RUN:
			inventory_button()
			shoot_button()
			run_button()
			charger_button()
			jump_button(delta)
	move_and_slide()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():return
	movement(delta)
	animation_rotate_look(delta)
	if focus_node:
		var target_pos = focus_node.global_transform.origin
		look_axis_y(target_pos)
		smooth_look_at(cam_target, target_pos)

func _input(event:InputEvent) -> void:
	if Engine.is_editor_hint():return
	match state:
		IDLE:
			camera_move(event)
			aim_button()
		WALK:
			camera_move(event)
			aim_button()
		RUN:camera_move(event)
	if input_movement():
		if in_alignment():
			get_meta("alignment").stop_alignment()

func input_movement() -> bool:
	return key_input(up_key,KeyAction.PRESSED) || key_input(down_key,KeyAction.PRESSED) \
	|| key_input(left_key,KeyAction.PRESSED) \
	|| key_input(right_key,KeyAction.PRESSED) || \
	key_input(jump_key,KeyAction.PRESSED) || (get_crouch() && get_crouch().is_crouching)

func key_input(key:String,index:int=1) -> bool:
	if !InputMap.has_action(key):return false
	emit_signal("key_pressed",key,index)
	match index:
		0:return Input.is_action_just_pressed(key)
		1:return Input.is_action_pressed(key)
		2:return Input.is_action_just_released(key)
	return false


########################################################################################
#lIFE AND STADISTICS
########################################################################################


func death_player() -> void:
	Hitokoto.can_save = false
	inventory.hide_inventory()
	if death_screen:
		add_child(death_screen.instantiate())
	Hitokoto.remove_save(self)

func take_damage_player(damage:float) -> void:
	screen_take_damage.play({"damage":damage})
	inventory.hide_inventory(true)

func failure(mission:Mission) -> void:
	if mission.failure_screen:
		inventory.hide_inventory()
		var keys = [up_key, down_key, left_key, right_key]
		Hitokoto.can_save = false
		cam_move = false
		await get_tree().create_timer(0.1).timeout
		can_move = false
		interact.can_interact = false
		for key in keys:
			if InputMap.has_action(key):
				Input.action_release(key)##################
		velocity = Vector3.ZERO
		state = IDLE

func started_alignment() -> void:
	var restart_cam_target : Tween = create_tween()
	restart_cam_target.tween_property(cam_target,"rotation",Vector3.ZERO,0.05)
	stop_rotate()
