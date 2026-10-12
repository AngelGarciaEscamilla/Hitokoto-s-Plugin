extends Node3D

@export var ray_length: float = 2.0
@export var interpolation : float = 7.5
@export var collision_mask: int = 1
@export var steps_normal : int = 5
@export var user : Node3D 
var exclude_list: Array = []

func _ready() -> void:
	if !user && (get_parent().get_parent() is Node3D):
		user = get_parent().get_parent()
	if get_parent() is Node3D:
		add_physics_children(get_parent(), exclude_list)
		exclude_list.append(self)

func add_physics_children(node: Node, exclude_list: Array) -> void:
	for child in node.get_children():
		if child is PhysicsBody3D || child is PhysicalBone3D:
			exclude_list.append(child)
		add_physics_children(child, exclude_list)

func _process(delta: float) -> void:
	if !user:return
	if !user.is_on_floor():return
	var space_state :PhysicsDirectSpaceState3D = user.get_world_3d().direct_space_state
	var origin :Vector3 = user.global_position
	var end :Vector3 = origin + Vector3.DOWN * ray_length
	var query :PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = collision_mask
	query.exclude = exclude_list
	var result : Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return
	var target_position: Vector3 = result.position
	global_position.y = lerp(
		global_position.y,
		target_position.y-abs(result["normal"].z/steps_normal),
		interpolation * delta
	)
