@tool
extends Node


###########################################################################################################################
#MOST OF THE FOLLOWINGS FUNCTION ARE FOR SAVE SETTINGS AND NOT FOR SET SETTINGS

#evey time uses the setters or change config will make call apply make sure of not called or change it very often
###########################################################################################################################

signal load_settings

enum Lenguage {EN,ES,PT,FR,JA,AR,RU}

var settings 

var save_setting : SaveSettings = SaveSettings.new()
var settings_path_save : String = save_setting.path

#######################################################################################################################################
#LOADER
################################################################################################################################


func _ready() -> void:
	if Engine.is_editor_hint():return
	var path = Hitokoto.find_script_path("settings")
	if FileAccess.file_exists(path):
		settings = load(Hitokoto.find_script_path("settings")).new()
	load_archive()

func save() -> void:
	if !Hitokoto.verified_file_exist(save_setting):
		save_setting = SaveSettings.new()
		save_setting.save_settings()
	Hitokoto.has(settings,"config",func():
		save_setting.settings = settings.config)
	save_setting.save_settings()

func reboot() -> void:
	Hitokoto.eliminate_dir_path(GameSettings.settings_path_save)

func load_archive()-> void:
	if !ResourceLoader.exists(GameSettings.settings_path_save):
		apply()
		return
	save_setting = ResourceLoader.load(GameSettings.settings_path_save)
	if !Hitokoto.verified_file_exist(save_setting):return
	Hitokoto.has(settings,"config",func():
		settings.config = save_setting.settings)
	if !Engine.is_editor_hint():
		apply()

func apply() -> void:
	emit_signal("load_settings")
	Hitokoto.method(settings,"apply")

##########################################################################################################################
#GETTING
#########################################################################################################

func get_setting(path:String= "") -> Variant:
	if settings && !("config" in settings):return
	if path.is_empty():
		return settings.config
	var separator := "/"
	var keys = path.split(separator)
	var current = settings.config
	for key in keys:
		if current is Dictionary && current.has(key):
			current = current[key]
		else:
			return null
	return current

func has_setting(path:String) -> Variant:
	if settings && !("config" in settings):return
	var separator := "/"
	var keys = path.split(separator)
	var current = settings.config
	for key in keys:
		if current is Dictionary && current.has(key):
			return true
	return false

func get_volume(bus:String) -> float:
	if !Hitokoto.method(settings,"get_volume",[bus]):
		return 1.0
	return Hitokoto.method(settings,"get_volume",[bus])

func get_current_lenguage() -> int:
	if !Hitokoto.method(settings,"get_current_lenguage"):
		return Lenguage.EN
	return Hitokoto.method(settings,"get_current_lenguage")

func is_subtitles() -> bool:
	return Hitokoto.method(settings,"is_subtitles")

func get_sensibility_input() -> Vector2:
	if Hitokoto.method(settings,"get_sensibility_input") == null:
		return Vector2(1.0,1.0)
	return Hitokoto.method(settings,"get_sensibility_input")

func get_key(key:String) -> String:
	return Hitokoto.method(settings,"get_key",[key])

################################################################################################################################
##SETTING
####################################################################################################################################

func set_setting(path:String, value:Variant) -> void:
	if !settings or !("config" in settings):
		return
	if path.is_empty():
		return
	var keys := path.split("/")
	var current = settings.config
	for i in range(keys.size()):
		var key := keys[i]
		if i == keys.size() - 1:
			if current is Dictionary:
				current[key] = value
			else:
				push_error("Invalid path: " + path)
			return
		else:
			if current is Dictionary and current.has(key):
				current = current[key]
			else:
				push_error("Not found setting with path " + path)
				return


func set_key(key:String,value:String) -> void:
	Hitokoto.method(settings,"set_key",[key])


func set_resolution(x:int,y:int) -> void:
	Hitokoto.method(settings,"set_resolution",[x,y])

func set_lenguage(index :  int) -> void:
	Hitokoto.method(settings,"set_lenguage",[index])

func set_subtitles(value:bool) -> void:
	Hitokoto.method(settings,"set_subtitles",[value])

#####################################################################################################################
#TOOLS
#######################################################################################################################

var seen := {}

func key_repeat() -> bool:
	if Hitokoto.method(settings,"controls"):
		for v in Hitokoto.method(settings,"controls").values():
			if v in seen:
				return true
			seen[v] = true
		seen = {}
		return false
	return false
