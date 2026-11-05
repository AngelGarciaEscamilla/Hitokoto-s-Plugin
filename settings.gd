extends Node


var config = {
	"accessibility": {
		"lenguage" : GameSettings.Lenguage.EN,
		"subtitles" : true
	},
	"audio": {
		"music_volume": 1,
		"sfx_volume": 1,
		"cutscene_volume": 1,
		"dialogue_volume": 1
	},
	"video": {
		"fullscreen": false,
		"borderless" : false,
		"resolution": Vector2i(1280, 720),
	},
	"controls": {
		"sensibility":Vector2(1.0,1.0),
		"skip":"g",
		"up":"w",
		"down":"s",
		"left":"a",
		"right":"d",
		"jump": "Space",
		"run": "Shift",
		"crouch": "control",
		"inventory":"v",
		"interacted" : "e",
		"shoot": "Mouse1",
		"use": "q",
		"undo_item": "1",
		"read_item": "2",
		"aim": "Mouse2",
		"charger" : "r"
	}}

func apply() -> void:
	var fullscreen = config["video"]["fullscreen"]
	var raw_res = config["video"]["resolution"]
	var volumeSFX = config["audio"]["sfx_volume"]
	var volumeMUSIC = config["audio"]["music_volume"]
	var volumeCUTSCENE = config["audio"]["cutscene_volume"]
	var volumeDIALOGUE = config["audio"]["dialogue_volume"]
	DisplayServer.window_set_size(raw_res)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(raw_res)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioManager.default_bus), volumeSFX)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioManager.default_bus_music), volumeMUSIC)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioManager.default_bus_cut_scene), volumeCUTSCENE)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioManager.default_bus_dialogue), volumeDIALOGUE)

#GET

func get_current_volume(bus:String) -> float:
	return config["audio"][bus.to_lower()+"_volume"]

func get_current_lenguage() -> float:
	return config["accessibility"]["lenguage"]

func is_subtitles() -> bool:
	return config["accessibility"]["subtitles"]

func get_sensibility_input() -> Vector2:
	return config["controls"]["sensibility"]

func get_key(key:String) -> String:
	return config["controls"][key]

func controls() -> Dictionary:
	return config["controls"]

func set_key(key:String,value:String) -> void:
	config["controls"][key] = value

func set_setting(section:String,setting:String,value) -> void:
	config[section][setting] = value

func set_resolution(x:int,y:int) -> void:
	var new_resolution : Vector2i = Vector2i(x,y)
	config["video"]["resolution"] = new_resolution
	DisplayServer.window_set_size(new_resolution)

func set_lenguage(index : float) -> void:
	config["accessibility"]["lenguage"] = index

func set_subtitles(value:bool) -> void:
	config["accessibility"]["subtitles"] = value