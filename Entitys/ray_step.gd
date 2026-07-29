extends RayCast3D


@export var step_target : Node3D
@export var interpolation : float = 7.5
var init_pos : Vector3

var exclude : Array[Node3D]

func _ready() -> void:
	init_pos = step_target.transform.origin
	if get_parent() is Node:
		add_exceptions_from_parent(get_parent())

func add_exceptions_from_parent(node: Node):
	for child in node.get_children():
		if child is CollisionObject3D:
			add_exception(child)
		add_exceptions_from_parent(child)

func _physics_process(delta: float) -> void:
	var collider = get_collider()
	if !collider:
		step_target.transform.origin = init_pos
		return
	var hint_point = get_collision_point()
	step_target.global_position.y = lerp(
		step_target.global_position.y,
		hint_point.y,
		interpolation * delta
	)
