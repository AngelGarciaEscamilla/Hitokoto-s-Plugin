extends Node3D

@export var ray_length: float = 1.5
@export var interpolation : float = 2.5
@export var collision_mask: int = 1
@export var offset_angle : bool = true
@export var user : Node3D

var angle_degrees : float 

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
