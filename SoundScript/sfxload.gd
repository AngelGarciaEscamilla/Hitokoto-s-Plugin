class_name SFXLoad extends AudioStreamPlayer

func _ready():
	if AudioServer.get_bus_index(AudioManager.default_bus) != -1:
		bus = AudioManager.default_bus
	else:
		push_error("SFX bus not exist, create a new SFX bus")
	process_mode = Node.PROCESS_MODE_ALWAYS
