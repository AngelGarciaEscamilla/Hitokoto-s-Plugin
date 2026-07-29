class_name LoadScene extends Control

var procces : Array
var percentage : float
var status : int
var new_scene : String 
var screen : Node

func _ready() -> void:
	screen = get_parent()
	new_scene  = Hitokoto.new_scene_match
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ResourceLoader.load_threaded_request(new_scene)

func _process(delta: float) -> void:
	status = ResourceLoader.load_threaded_get_status(new_scene,procces)
	if "percentage" in screen:
		screen.percentage = procces[0] * 100
	if status ==  ResourceLoader.THREAD_LOAD_LOADED:
		if screen.has_method("exit"):
			await screen.exit()
		get_tree().call_deferred("change_scene_to_packed",ResourceLoader.load_threaded_get(new_scene))
