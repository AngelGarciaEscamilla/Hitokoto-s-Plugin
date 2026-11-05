extends Node3D

@export var activate : bool = true
@export var ray_length: float = 2.0
@export var interpolation : float = 7.5
@export var collision_mask: int = 1
@export var steps_normal : int = 5
@export var user : Node3D 

@export var rays : Array[RayCast3D] = []

func _ready() -> void:
	if !user && (get_parent().get_parent() is Node3D):
		user = get_parent().get_parent()

func _process(delta: float) -> void:
	if !user || !activate:return
	if !user.is_on_floor():return
	var target_ray : RayCast3D = null
	var target_y : float = INF
	for ray in rays:
		if ray.is_colliding():
			var hit_point = ray.get_collision_point()
			if hit_point.y < target_y:
				target_y = hit_point.y
				target_ray = ray
	if !target_ray:return
	var target_position: float = target_y
	global_position.y = lerp(
		global_position.y,
		target_position,
		interpolation * delta
	)
	position.y = clamp(position.y,-1.5,1.5)
