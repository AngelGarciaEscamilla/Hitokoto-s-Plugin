extends Node3D

@export var user : Node3D


#0= IK
#1= RAY
#2= Target or step
#3= bone attachment
#4= bone name

#setting the interpolation for the foot planting

@export var foots : Array[Array]
@export var skeleton: Skeleton3D
@export var interpolation : float = 30.0
@export var add_position_ray : Vector3 = Vector3(0,0.25,0.0)
var bones_idx : Array[int]
var bone_left_idx: int
var bone_right_idx: int

var anim : Tween

func _ready() -> void:
	for i in foots:
		bones_idx.append(skeleton.find_bone(i[4]))
		get_node_or_null(i[0]).start()
	var root = get_parent().get_parent().get_parent().get_parent()
	if !(root is Window) && !user:
		user = root
	_add_user_exceptions(user)

func _add_user_exceptions(node: Node) -> void:
	if !node:return
	if node is CollisionObject3D:
		for i in foots:
			get_node_or_null(i[1]).add_exception(node)
	for child in node.get_children():
		_add_user_exceptions(child)

func _physics_process(delta: float) -> void:
	if !user:return
	for i in range(foots.size()):
		var ik : SkeletonIK3D = get_node_or_null(foots[i][0])
		var ray : RayCast3D = get_node_or_null(foots[i][1])
		var target : Node3D = get_node_or_null(foots[i][2])
		var attachment : Node3D = get_node_or_null(foots[i][3])
		var new_pos_ray : Vector3 = attachment.global_transform.origin
		new_pos_ray += add_position_ray
		ray.global_transform.origin = new_pos_ray
		_adjust_foot_height(ray, target, bones_idx[i], delta)
		ik.influence = lerp(ik.influence,float(user.is_on_floor()),interpolation * delta)

func _adjust_foot_height(ray: RayCast3D, target: Node3D, bone_idx: int, delta: float) -> void:
	var anim_bone_pose: Transform3D = skeleton.get_bone_global_pose(bone_idx)
	var anim_world_pos: Vector3 = skeleton.global_transform * anim_bone_pose.origin
	var target_pos: Vector3 = anim_world_pos
	var anim_world_transform = skeleton.global_transform * anim_bone_pose
	if ray.is_colliding():
		var hit_point = ray.get_collision_point()
		target_pos.y = max(anim_world_pos.y, hit_point.y)
		var normal: Vector3 = ray.get_collision_normal()
		var slope_rotation = Quaternion(Vector3.UP, normal)
		var target_quat = slope_rotation * anim_world_transform.basis.get_rotation_quaternion()
		var current_quat = target.global_basis.get_rotation_quaternion()
		target.global_basis = Basis(current_quat.slerp(target_quat, interpolation * delta))
	else:
		var current_quat = target.global_basis.get_rotation_quaternion()
		var target_quat = anim_world_transform.basis.get_rotation_quaternion()
		target.global_basis = Basis(current_quat.slerp(target_quat, interpolation * delta))
	target.global_position = target.global_position.lerp(target_pos, interpolation * delta)
	