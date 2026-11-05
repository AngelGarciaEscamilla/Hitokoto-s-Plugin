@tool
extends Node

var default_bus : String = "SFX"
var default_bus_music : String = "Music"
var default_bus_cut_scene : String = "CutScene"
var default_bus_dialogue : String = "Dialogue"

var is_volume_fading : Dictionary = {}

var music : DynamicMusic = DynamicMusic.new()

func _ready():
	add_child(music)
	add_bus_name(default_bus)
	add_bus_name(default_bus_cut_scene)
	add_bus_name(default_bus_music)
	add_bus_name(default_bus_dialogue)
	add_bus_name("Default")
	AudioServer.remove_bus(AudioServer.get_bus_count()-1)


func add_bus_name(name:String) -> void:
	var index := AudioServer.get_bus_index(name)
	if index <= 0:
		var new_index = AudioServer.get_bus_count()
		AudioServer.add_bus(new_index)
		AudioServer.set_bus_name(new_index, name)
		AudioServer.set_bus_volume_db(new_index, 0.0)

func set_bus_db(bus:String,value:float,duration:float=1) -> void:
	if value <= 0.0:
		value = 0.01
	var index = AudioServer.get_bus_index(bus)
	if index < 0.0:
		push_error("bus "+bus+" don´t exist")
		return
	if is_volume_fading.get(bus) && is_volume_fading[bus]:return
	if index >= 0.0:
		is_volume_fading[bus] = false
	var tween_audio : Tween = get_tree().create_tween()
	var to_db : = linear_to_db(value)
	is_volume_fading[bus] = true
	tween_audio.tween_method(
		func(v):AudioServer.set_bus_volume_db(index, v),
		AudioServer.get_bus_volume_db(index),
		to_db,
		duration
	)
	await tween_audio.finished
	if value == 0.01:
		AudioServer.set_bus_volume_db(index, -80)
	is_volume_fading[bus] = false

func mute(bus:String,value:bool=true) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), value)

func play_music(stream:AudioStream,volume:float = 1.0,i:float = 1.0) -> void:
	if stream:
		music.play_music(stream,volume,i)
	else:
		music = DynamicMusic.new()
		add_child(music)
		music.play_music(stream,volume,i)

func stop_music() -> void:
	if music:
		music.stop_music()
