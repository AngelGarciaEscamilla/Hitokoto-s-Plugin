@tool
class_name Voice extends AudioStreamPlayer3D

func _ready() -> void:
	if AudioServer.get_bus_index(AudioManager.default_bus_dialogue) != -1:
		bus = AudioManager.default_bus_dialogue
	else:
		push_error("SFX bus not exist")

func _physics_process(delta:float) -> void:
	if get_parent() == get_tree().current_scene:
		return
	if get_parent() is Node:
		var user = get_parent().get_parent()
		if !(user is Node3D):return
		global_transform.origin = user.global_transform.origin
	if get_parent() is Node3D:
		global_transform.origin = get_parent().global_transform.origin

func queue_free():
	pass