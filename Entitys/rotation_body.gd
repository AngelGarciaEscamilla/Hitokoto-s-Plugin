class_name RotationBone3D extends SkeletonModifier3D

@export var bone_name : String
@export var rotation_speed : float = 360

var bone_index : int = -1
var skeleton : Skeleton3D

var current_rotation : Quaternion = Quaternion.IDENTITY
@export var target_rotation : Quaternion = Quaternion.IDENTITY

func _process_modification_with_delta(delta):
	skeleton = get_skeleton()
	if !skeleton: return
	bone_index = skeleton.find_bone(bone_name)
	if bone_index < 0: return
	var angle_diff = current_rotation.angle_to(target_rotation)
	if angle_diff > 0.001:
		var max_angle = deg_to_rad(rotation_speed) * delta
		var t = min(1.0, max_angle / angle_diff)
		current_rotation = current_rotation.slerp(target_rotation, t)
	var rest_pose = skeleton.get_bone_rest(bone_index)
	var rotation_basis = Basis(current_rotation)
	var modified_basis = rotation_basis * rest_pose.basis
	skeleton.set_bone_pose(bone_index, Transform3D(modified_basis, rest_pose.origin))
