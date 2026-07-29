@tool
class_name FallState extends Component

var dialogue_sibling : DialogueManager

var timer_fall : Timer = Timer.new()
var timer_get_up : Timer = Timer.new()

var fall_sfx : SFX = SFX.new()
var jump_sfx : SFX = SFX.new()

var init_fall : bool = true
var in_floor : bool = true
var fallen : bool
var dialogue_fall_reproduce : bool
var is_in_free_fall : bool

var strength_impact : float

var global_event : InputEvent

@export var fallen_enabled : bool = true
@export var can_jump : bool = true

@export var dialogue_fall : DialogueData

@export var JUMP_SIZE : float = 19.0
@export_range(0,99,0.1) var time_fall : float = 3.0:
	set(value):
		time_fall = value
		timer_fall.wait_time = time_fall
@export_range(0,99,0.1) var time_get_up : float = 7.5:
	set(value):
		time_get_up = value
		timer_get_up.wait_time = time_get_up
@export var cooldown_jump : float = 1.0

var limit_time_fall : float = 60
var state_before : int
var state_before_jump : int
var state_before_jump_input : int = -1
var can_move_before : bool
var cam_move_before : bool
var no_share_jump : bool

signal fallen_down
signal get_up
signal in_freefall
signal is_push
signal jump

signal kick_fall(strentgh:float)
signal impact_with_floor(strenght:float)
signal in_air(i:bool)

func _ready() -> void:
	set_user()
	dialogue_sibling = find_dialogue_manager_sibling()
	create_timer_fall()
	create_sound_fall()
	if !Engine.is_editor_hint():
		call_deferred("find_push_sense_sibling")
	await get_tree().process_frame

func find_dialogue_manager_sibling() -> DialogueManager:
	for child in user.get_children():
		if child is DialogueManager:
			return child
	return null

func find_push_sense_sibling() -> void:
	for child in user.get_children():
		if child is PushSense:
			child.push.connect(push)


func create_timer_fall() -> void:
	add_child(timer_fall)
	timer_fall.wait_time = time_fall
	timer_get_up.wait_time = time_get_up
	add_child(timer_get_up)
	timer_get_up.timeout.connect(timeout_get_up)
	timer_fall.timeout.connect(timeout_fall)

func create_sound_fall() -> void:
	add_child(fall_sfx)
	add_child(jump_sfx)

func timeout_fall() -> void:
	if !fallen_enabled:return
	emit_signal("in_freefall")
	method(user,"set_ik_bones",[false])
	is_in_free_fall = true

func jump_action(delta:float) -> void:
	if !(user is Node3D && user.is_on_floor() && can_jump) || no_share_jump:return
	emit_signal("jump")
	timer_fall.start()
	state_before_jump_input = user.state
	user_has("state",func():user.state = Humanoid.FALL)
	method(user,"jump")
	user_has("velocity",func():user.velocity.y += (JUMP_SIZE *10) * delta)
	no_share_jump = true
	await get_tree().create_timer(cooldown_jump).timeout
	no_share_jump = false

func impact_floor() -> void:
	if !user is CharacterBody3D:return
	if user.get_slide_collision_count() > 0:
		if strength_impact > 0:
			emit_signal("impact_with_floor",strength_impact)
		strength_impact = 0
	if user.is_on_floor():
		dialogue_fall_reproduce = false
		if is_in_free_fall:
			fallen_action()
			if dialogue_sibling:
				dialogue_sibling.stop_dialogue()
		else:
			user_has("state",func():
				if user.state != Humanoid.FALLEN:
					if state_before_jump_input >= 0:
						user.state = state_before_jump_input
					else:
						if state_before_jump == Entity.WALK || state_before_jump == Entity.RUN:
							user.state = Entity.IDLE
						else:
							user.state = state_before_jump
						)
		is_in_free_fall = false
		timer_fall.stop()
		fallen = true
		init_fall = true

func user_has_collision() -> bool:
	if !(user is PhysicsBody3D):
		return false
	for child in user.get_children():
		if child is CollisionShape3D && !child.disabled:
			return true
	return false


func _input(event:InputEvent) -> void:
	global_event = event

func free_fall_() -> void:
	if dialogue_fall_reproduce:return
	if dialogue_sibling && dialogue_fall:
		dialogue_sibling.stop_dialogue()
		dialogue_sibling.reproduce_dialogue(dialogue_fall)
		dialogue_fall_reproduce = true
		
func _physics_process(delta:float) -> void:
	if Engine.is_editor_hint():return
	if !user:return
	if user_has_collision():
		if !user.is_on_floor():
			in_floor = false
			if init_fall:
				emit_signal("in_air",true)
				timer_fall.start()
				init_fall = false
			user.velocity += user.get_gravity() * delta
			user_has("state",func():
				if user.state != Humanoid.FALLEN:
					user.state = Entity.FALL)
	else:
		if !in_floor:
			emit_signal("in_air",false)
			in_floor = true
	if !("state" in user):return
	match user.state:
		Entity.FALL:
			strength_impact += 10 * delta
			if !is_in_free_fall:
				method(user,"movement",[delta])
			impact_floor()
		Humanoid.FALLEN:
			user_has("can_move",func():
				can_move_before = user.can_move
				user.can_move = false)
			user_has("cam_move",func():
				cam_move_before = user.cam_move
				user.cam_move = false)
			if "velocity" in user:
				user.velocity = Vector3.ZERO
			start_fallen()


func in_free_fall() -> bool:
	return is_in_free_fall || !timer_get_up.is_stopped()


func _process(delta:float) -> void:
	if Engine.is_editor_hint():return
	if !user:return
	if !("state" in user):return
	match user.state:
		Entity.FALL:
			if !is_in_free_fall:
				if user.has_method("camera_move"):
					user.camera_move(global_event)
			else:
				free_fall_()

func start_fallen() -> void:
	if fallen:
		timer_fall.stop()
		timer_get_up.start()
		fallen = false

func fallen_action() -> void:
	if !fallen_enabled:return
	fallen = true
	timer_fall.stop()
	emit_signal("fallen_down")
	user_has("lock_state",func():user.lock_state = false)
	user_has("state",func():
		state_before = user.state
		user.state = Humanoid.FALLEN)

func stop_timers() -> void:
	timer_fall.stop()
	timer_get_up.stop()

func jump_forward(forward_range: float, jump_force: float) -> void:
	if user.state == Entity.FALL || user.is_on_wall():return
	if user is Entity:
		if user.is_walk_back() || user.get_direction() == Entity.Direction.IDLE:return
	var forward = -user.transform.basis.z.normalized()
	user.velocity.y = jump_force
	user.velocity.x = forward.x * forward_range
	user.velocity.z = forward.z * forward_range

func timeout_get_up() -> void:
	to_idle()

func to_idle() -> void:
	method(user,"set_ik_bones",[true])
	emit_signal("get_up")
	is_in_free_fall = false
	user_has("can_move",func():
		if state_before == Humanoid.EXAMINE:
			user.can_move = true
		else:
			user.can_move = !can_move_before)
	user_has("cam_move",func():
		if state_before == Humanoid.EXAMINE:
			user.cam_move = true
		else:
			user.cam_move = !cam_move_before)
	user_has("state",func():user.state = Entity.IDLE)
	stop_timers()

func push(strenght:float) -> void:
	method(user,"set_ik_bones",[false])
	fallen_action()
	emit_signal("kick_fall",strenght)
