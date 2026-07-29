
extends Resource

class_name SaveGame

@export var index : int = 0

@export_category("Scene")

@export var save_scenes : Dictionary
@export var current_scene : String
@export var values: Dictionary
@export var missions : Dictionary
@export var current_weather : GameTime.Weather
var save_path : String = "user://save/save_game.tres"

@export_category("Time")
@export var calendar : Dictionary

func _ready() -> void:
	load_game()

func save_game() -> void:
	ensure_save_folder()
	var save_path_base : String
	var char_count : int = 0
	for char in save_path:
		if char == ".":
			break
		char_count += 1
	save_path_base = save_path.insert(char_count,"_"+str(index))
	ResourceSaver.save(self,save_path_base)
	save_path_base = ""

func load_game() -> void:
	var data = SaveGame.new()
	data = ResourceLoader.load(save_path)

func ensure_save_folder():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("save"):
		dir.make_dir("save")
