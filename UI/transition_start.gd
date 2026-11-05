
class_name TransitionStart extends Component

@export var transition_scene : PackedScene

var transition_start : Node

func _ready():
	if transition_scene:
		transition_start = transition_scene.instantiate()
		add_child(transition_start)
		if transition_start.has_method("exit"):
			await transition_start.exit()
			queue_free()

