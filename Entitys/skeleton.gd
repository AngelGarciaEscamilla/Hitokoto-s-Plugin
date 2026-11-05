

class_name DelayTarget3D extends Node3D

@export var target: Node3D
@export var follow_speed := 12.0

func _process(delta):
	if !target:
		return
	var q_current: Quaternion = global_transform.basis.get_rotation_quaternion()
	var q_target: Quaternion = target.global_transform.basis.get_rotation_quaternion()
	var q_new := q_current.slerp(q_target, follow_speed * delta)
	var t := global_transform
	t.basis = Basis(q_new)
	global_transform = t
