extends Node3D

var user : Node
var inventory : Array

@export var physics_bones : PhysicalBoneSimulator3D
@export var skeleton : Skeleton3D


func death() -> void:
	physics_bones.physical_bones_start_simulation()
	user.eliminate()

func in_freefall() -> void:
	physics_bones.physical_bones_start_simulation()
	user.inventory.slot_select(user.inventory.slot_interactive,true)

func push() -> void:
	physics_bones.physical_bones_start_simulation()
	user.inventory.slot_select(user.inventory.slot_interactive,true)

func get_up() -> void:
	physics_bones.physical_bones_stop_simulation()
