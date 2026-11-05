class_name SoundGroupStep extends Resource


@export var group : String
@export var sounds : Array[AudioStream]

func get_random_sound() -> Variant:
	var array : Array = sounds
	if array.size() == 1:
		return array[0]
	if array.is_empty():
		return null
	return array[randi() % array.size()-1]