class_name AlignmentUser extends Component

@export var speed_rotation : float = 30
var alignment : Node3D
var alignment_anim : Tween
var align_target: Vector3
var aligning : bool= false
var save_strafe : bool
var look_at : bool
var global_delta : float

var emisor : Node
var call_method : String

signal finished_alignment

func _ready() -> void:
	set_user()

func play_alignment(alignment_emisor:Node,emisor_node:Node=null,call_method_name:String="") -> void:
	alignment = alignment_emisor
	if !alignment:
		push_error("invalid alignment")
		return
	if !user.is_on_floor():
		return
	if emisor_node.has_method("started_alignment"):
		emisor_node.started_alignment()
	emisor = emisor_node
	call_method = call_method_name
	walk_in(user)
	has(user,"cam_move",false)
	tween_transform(alignment.global_transform)
	await get_tree().create_timer(0.2).timeout
	user.set_meta("alignment",self)
	if user.has_method("set_model_relative_to_target"):
		user.set_model_relative_to_target()

func tween_transform(alignment: Transform3D) -> void:
	align_target = Vector3(
		alignment.origin.x,
		user.global_position.y,
		alignment.origin.z
	)
	aligning = true
	look_at = true
	if "strafe" in user:
		save_strafe = user.strafe
	has(user,"strafe",true)

func call_signal() -> void:
	if user.has_method("stop_alignment"):
		for m in user.get_method_list():
			if m.name == "stop_alignment":
				if m.args.size() == 0:
					user.stop_alignment()
	walk_out(user)
	has(user,"cam_move",true)
	method(emisor,call_method)

func _physics_process(delta: float) -> void:
	global_delta = delta

	if look_at && emisor :
		look_axis_y(emisor.global_position, speed_rotation)
	if !aligning:
		return
	if user.test_move(user.global_transform, Vector3.ZERO) || ("current_state" in user && user.current_state != Entity.State.WALK):
		stop_alignment()
		return
	var to_target : Vector3 = align_target - user.global_position
	to_target.y = 0.0
	var distance : float = to_target.length()
	if distance < 0.05:
		end_alignment()
		await look_axis_y_tween(emisor.global_position, 0.2)
		call_signal()
		return
	var direction : Vector3 = to_target.normalized()
	if "input_dir" in user:
		var forward_dot = direction.dot(user.global_basis.z)
		var right_dot = direction.dot(user.global_basis.x)
		user.input_dir = Vector2(right_dot, forward_dot)
	method(user, "movement_direction", [direction, delta])
	user.move_and_slide()

func stop_alignment() -> void:
	if emisor.has_method("stop_alignment"):
		emisor.stop_alignment()
	end_alignment()

func end_alignment() -> void:
	aligning = false
	has(user,"strafe",save_strafe)
	user.set_meta("alignment",null)
	user.velocity.x = 0
	user.velocity.z = 0
	has(user,"cam_move",true)
	walk_out(user)
	look_at = false

func walk_in(body:Node) -> void:
	has(body,"current_state",Entity.State.WALK)
	has(body,"lock_state",true)

func walk_out(body:Node) -> void:
	has(body,"lock_state",false)

func look_axis_y_tween(target: Vector3, duration: float) -> void:
	var my_position: Vector3 = user.global_transform.origin
	target.y = my_position.y
	var direction: Vector3 = target - my_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var current_q: Quaternion = user.global_transform.basis.get_rotation_quaternion()
	var target_q: Quaternion = Quaternion(Basis().looking_at(direction, Vector3.UP))
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(weight: float):
			var interpolated_q = current_q.slerp(target_q, weight)
			user.global_transform.basis = Basis(interpolated_q),
		0.0, 
		1.0, 
		duration
	)
	await tween.finished

func look_axis_y(target: Vector3, speed_rotation: float) -> void:
	var my_position :Vector3 = user.global_transform.origin
	target.y = my_position.y
	var direction :Vector3 = target - my_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var current_q :Quaternion = user.global_transform.basis.get_rotation_quaternion()
	var target_q :Quaternion = Quaternion(Basis().looking_at(direction, Vector3.UP))
	var t :float = speed_rotation * get_process_delta_time()
	var result_q :Quaternion = current_q.slerp(target_q, t)
	user.global_transform.basis = Basis(result_q)
