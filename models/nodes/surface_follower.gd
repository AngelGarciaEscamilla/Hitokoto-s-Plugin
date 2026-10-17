extends Node3D

@export var activate : bool = true
@export var ray_length: float = 2.0
@export var interpolation : float = 7.5
@export var collision_mask: int = 1
@export var steps_normal : int = 5
@export var user : Node3D 

@export var rays : Array[RayCast3D] = []
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
	if !user || !activate:return
	if !user.is_on_floor():return
	var lowest_ray : RayCast3D = null
	var lowest_y : float = INF
	for ray in rays:
		if ray.is_colliding():
			var hit_point = ray.get_collision_point()
			if hit_point.y < lowest_y:
				lowest_y = hit_point.y
				lowest_ray = ray
	if !lowest_ray:return
	var target_position: float = lowest_y
	global_position.y = lerp(
		global_position.y,
		target_position,
		interpolation * delta
	)
