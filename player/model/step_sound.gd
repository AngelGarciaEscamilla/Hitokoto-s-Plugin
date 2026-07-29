class_name StepSound extends BoneAttachment3D

@export var foot_ray : RayCast3D
@export var default_sound_step : Array[AudioStream]
@export var steps : Array[SoundGroupStep]
var foot_collide : bool 
var audio_step : SFX = SFX.new()

signal step(collider:Node3D)

func _ready() -> void:
	step.connect(step_function)
	add_child(audio_step)

func _process(delta: float) -> void:
	if !foot_ray:return
	if foot_ray.is_colliding():
		if foot_ray.get_collider() is PhysicalBone3D:
			foot_ray.add_exception(foot_ray.get_collider())
		if !foot_collide:
			emit_signal("step",foot_ray.get_collider())
			foot_collide = true
	if !foot_ray.is_colliding():
		foot_collide = false

func step_function(collider:Node3D) -> void:
	var no_step : bool = true
	for step_data in steps:
		if collider.is_in_group(step_data.group):
			play_sound(step_data.get_random_sound())
			no_step = false
			break
		else:
			continue
	if no_step:
		play_sound(get_random_element(default_sound_step))

func play_sound(audio:AudioStream) -> void:
	audio_step.stream = audio
	audio_step.play()


func get_random_element(array:Array) -> Variant:
	if array.size() == 1:
		return array[0]
	if array.is_empty():
		return null
	return array[randi() % array.size()-1]
