class_name AlignmentUser extends Component
var alignment : Node3D

var body_ : Node3D

var alignment_anim : Tween
var align_target: Vector3
@export_range(0.2,15,0.1) var align_speed : float = 0.25
var aligning := false
var save_strafe : bool
var look_at : bool
var global_delta : float

signal finished_alignment
signal start_alignment

func _ready() -> void:
	set_user()

func play_alignment(body: Node3D) -> void:
	if !body:
		push_error("not found a valid body")
		return
	if !alignment:
		push_error("invalid alignment")
		return
	if body.has_method("started_alignment"):
		for m in body.get_method_list():
			if m.name == "started_alignment":
				if m.args.size() == 0:
					body.started_alignment()
	emit_signal("start_alignment")
	walk_in(body)
	has(body,"cam_move",false)
	tween_transform(body,alignment.global_transform)
	await get_tree().create_timer(0.2).timeout
	body.set_meta("alignment",self)

func tween_transform(body: CharacterBody3D, alignment: Transform3D) -> void:
	body_ = body
	align_target = Vector3(
		alignment.origin.x,
		body.global_position.y,
		alignment.origin.z
	)
	aligning = true
	look_at = true
	if "strafe" in body:
		save_strafe = body.strafe
	has(body,"strafe",true)

func call_signal() -> void:
	if body_.has_method("stop_alignment"):
		for m in body_.get_method_list():
			if m.name == "stop_alignment":
				if m.args.size() == 0:
					body_.stop_alignment()
	walk_out(body_)
	has(body_,"cam_move",true)
	emit_signal("finished_alignment")

func _physics_process(delta:float) -> void:
	global_delta = delta
	if look_at && body_:
		body_.set_model_relative_to_target()
		look_axis_y(body_,user.global_position,30)
	if !aligning:
		return
	if body_.test_move(body_.global_transform, Vector3.ZERO) \
	|| ("state" in body_ && body_.state != Entity.WALK):
		stop_alignment()
		return
	var to_target := align_target - body_.global_position
	var distance := to_target.length()
	if distance < 0.05:
		stop_alignment()
		call_signal()
		return
	var direction := to_target.normalized()
	method(body_,"movement_direction",[direction,delta])
	if !body_.has_method("movement_direction"):
		body_.velocity.x = direction.x * align_speed
		body_.velocity.z = direction.z * align_speed
		body_.move_and_slide()


func stop_alignment() -> void:
	aligning = false
	has(body_,"strafe",save_strafe)
	body_.set_meta("alignment",null)
	body_.velocity.x = 0
	body_.velocity.z = 0
	has(body_,"cam_move",true)
	walk_out(body_)
	look_at = false

func walk_in(body:Node) -> void:
	has(body,"state",Entity.WALK)
	has(body,"lock_state",true)

func walk_out(body:Node) -> void:
	has(body,"lock_state",false)

func look_axis_y(node: Node3D, target: Vector3, speed_rotation: float) -> void:
	var my_position := node.global_transform.origin
	target.y = my_position.y
	var direction := target - my_position
	if direction.length_squared() < 0.0001:
		return
	direction = direction.normalized()
	var current_q := node.global_transform.basis.get_rotation_quaternion()
	var target_q := Quaternion(Basis().looking_at(direction, Vector3.UP))
	var t := speed_rotation * get_process_delta_time()
	var result_q := current_q.slerp(target_q, t)
	node.global_transform.basis = Basis(result_q)
