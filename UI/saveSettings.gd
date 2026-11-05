@tool
extends Resource

class_name SaveSettings

@export var settings : Dictionary
var path = "user://save/settings.tres"

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	ensure_save_folder()
	ResourceSaver.save(self,path)

func load_settings() -> void:
	var data = SaveSettings.new()
	data = ResourceLoader.load(path)

func ensure_save_folder():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("save"):
		dir.make_dir("save")