@tool
class_name Furniture extends Area3D

var peopleNum : int

var collisionArea : CollisionShape3D = CollisionShape3D.new()
@export_range(1.0,10.0,0.01) var size_area : float = 1.0:
	set(value):
		size_area = value
		update_gizmos()

func _ready():
	pass 

func _process(delta):
	pass
