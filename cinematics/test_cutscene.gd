extends Node3D

var data : Array


func _ready() -> void:
	for i in data:
		if i is Humanoid:
			i.inventory.slot_select(i.inventory.slot_interactive)
			i.set_model_relative_to_target()
			i.examine("run",4)

