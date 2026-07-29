class_name LoadScreenBumper extends Control

var procces : Array
var scene_load_status : int

var new_scene : String = Hitokoto.new_scene_match

var video_random : int = randf_range(1,limit)

var bumper_start : bool = false
var on_transition : bool = false

@export var key_skip : String 

var transition = preload("res://addons/Hitokoto's Plugin/resources/bumpers/transition.ogv")

@onready var bumper : VideoStreamPlayer = $bumper
@onready var timer : Timer = $Timer
@onready var in_ : ColorRect = $in
@onready var advertence : Text = $Label

@export var video_list : Dictionary = {
	1:null,
	2:preload("res://addons/Hitokoto's Plugin/resources/bumpers/testing.ogv"),
	3:null,
	4:null,
	5:null,
	6:null,
}

var limit : int = video_list.size()

var start : bool = false

func _ready() -> void:
	randomize()
	call_deferred("setting_tree")
	ResourceLoader.load_threaded_request(new_scene)

func create_transition() -> void:
	in_.color = Color(0, 0, 0)
	in_.size = get_viewport().get_visible_rect().size
	var tween :Tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(in_,"self_modulate",Color(1, 1, 1, 0),1.5)
	tween.tween_callback(in_.queue_free)

func setting_tree() -> void:
	bumper.size = get_viewport().get_visible_rect().size
	advertence.text_extra = key_skip
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	start_to_the_bumpers()
	if Input.is_action_just_pressed(key_skip) && InputMap.has_action(key_skip) && scene_is_loaded():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().call_deferred("change_scene_to_packed",ResourceLoader.load_threaded_get(new_scene))

func scene_is_loaded() -> bool:
	var scene_load_status = ResourceLoader.load_threaded_get_status(new_scene,procces)
	return scene_load_status ==  ResourceLoader.THREAD_LOAD_LOADED

func start_to_the_bumpers() -> void:
	if start:
		return
	create_transition()
	timer.start()
	start = true

func start_bumper() -> void:
	if !video_list[video_random]:
		replay_bumper_random()
		return
	bumper.stream = video_list[video_random]
	bumper.play()
	bumper_start = true

func _on_video_stream_player_finished() -> void:
	if !on_transition:
		bumper.stream = transition
		bumper.play()
		on_transition = true
		return
	replay_bumper_random()
	on_transition = false

func replay_bumper_random() -> void:
	video_random = randf_range(1,limit)
	bumper_start = false
	start_bumper()

func _on_timer_timeout() -> void: 
	bumper.stream = transition
	bumper.play()
	on_transition = true
