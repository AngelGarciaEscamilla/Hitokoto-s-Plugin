@tool
class_name BulbLight extends SpotLight3D

enum TransMode {
	LINEAR,
	SINE,
	QUINT,
	QUART,
	QUAD,
	EXPO,
	ELASTIC,
	CUBIC,
	CIRC,
	BOUNCE,
	BACK,
	SPRING,
}

enum EaseMode {
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	EASE_OUT_IN,
}

@export var trans : TransMode = TransMode.LINEAR
@export var ease : EaseMode = EaseMode.EASE_IN
@export var interpolation_duration : float = 1.0
@export var on : bool: 
	set(value):
		on = value
		call_deferred("value",on)
@export_range(0.0,50.0,0.1,"or_less", "or_greater") var range_light : float = 12.0:
	set(value):
		if on:
			light_energy = value
		range_light = value
		if bulb_material:
			bulb_material.emission_energy_multiplier = value
@export var automatic_mode : bool
@export_range(0,23) var hour_off: int = 6
@export_range(0,59) var minute_off: int = 30
@export_range(0,23) var hour_on: int = 17
@export_range(0,59) var minute_on: int = 30
@export var sound_on : AudioStream
@export var sound_off : AudioStream

@export_category("Material")
@export var index_material : int 
@export var bulb_material : StandardMaterial3D:
	set(value):
		bulb_material = value
		call_deferred("update_material_mesh")
@export var mesh : Mesh = SphereMesh.new():
	set(value):
		mesh = value
		bulb.mesh = mesh
		call_deferred("update_material_mesh")

var is_on : bool
var bulb : MeshInstance3D = MeshInstance3D.new()
var sfx : SFX = SFX.new()

func _ready() -> void:
	on_minute_tick()
	GameTime.on_minute_tick.connect(on_minute_tick)
	add_child(sfx)
	add_child(bulb)


func _physics_process(delta:float) -> void:
	if bulb_material:
		bulb_material.emission = light_color

func value(state:bool) -> void:
	var sounds = [sound_off,sound_on]
	play_sfx(sounds[int(state)])
	var light: float = range_light if state else 0.0
	var interpolation := create_tween() \
		.set_trans(TransMode[TransMode.keys()[trans]]) \
		.set_ease(EaseMode[EaseMode.keys()[ease]])
	interpolation.tween_method(func(value):
		light_energy = value
		if bulb_material:
			bulb_material.emission_energy_multiplier = value
		,light_energy,
		light,
		interpolation_duration)

func update_material_mesh() -> void:
	if bulb_material:
		bulb_material.emission_enabled = true
		bulb_material.emission_energy_multiplier = 0
	if mesh && (index_material < mesh.get_surface_count()):
		bulb.mesh.surface_set_material(index_material,bulb_material)

func on_minute_tick() -> void:
	if automatic_mode && GameTime.get_sun():
		on = GameTime.is_time_between(hour_on,minute_on,hour_off,minute_off)

func play_sfx(sound:AudioStream) -> void:
	if !sfx:return
	sfx.stream = sound
	sfx.play()

