@tool
@icon("res://addons/Hitokoto´s Plugin/icons/Enviroment.png")
class_name SkyAmbient extends WorldEnvironment

func _ready() -> void:
	environment = preload("res://addons/Hitokoto´s Plugin/shaders/clouds.tres")