@tool
@icon("res://addons/Hitokoto's Plugin/icons/Sun.png")
class_name Sun extends Marker3D

var sun_light : DirectionalLight3D = DirectionalLight3D.new()
var moon_light : DirectionalLight3D = DirectionalLight3D.new()
var minutes : Timer = Timer.new()

@export_range(0.001,60.0,0.1) var waiting_time : float = 2.0
@export_range(0.10,15.0,0.05) var moon_intensity : float = 0.2
@export var continuous_time : bool = true

@export var color_light_sun : Color = Color.WHITE:
	set(value):
		color_light_sun = value
		sun_light.light_color = color_light_sun
@export var color_light_moon : Color = Color.WHITE:
	set(value):
		color_light_moon = value
		moon_light.light_color = color_light_moon

func _ready() -> void:
	add_to_group("sun")
	Hitokoto.save(self)
	create_sun_light()
	create_moon_light()
	create_timer()
	call_deferred("pass_minute")

func create_timer() -> void:
	add_child(minutes)
	minutes.timeout.connect(pass_minute)
	minutes.wait_time = waiting_time
	minutes.start()

func create_moon_light():
	add_child(moon_light)
	moon_light.position.y += 1
	moon_light.rotation_degrees.x = -90
	moon_light.shadow_enabled = true
	moon_light.set_layer_mask_value(19,true)
	moon_light.light_energy = moon_intensity

func create_sun_light() -> void:
	add_child(sun_light)
	sun_light.position.y -= 1
	sun_light.set_layer_mask_value(19,true)
	sun_light.rotation_degrees.x = 90
	sun_light.shadow_enabled = true

func _process(delta:float) -> void:
	moon_light.light_energy = moon_intensity
	var direction = -self.global_transform.basis.y.normalized()

func pass_minute() -> void:
	if Engine.is_editor_hint() || !continuous_time:return
	var minute : int = GameTime.get_minutes() + 1
	var hours : int = GameTime.get_hours()
	GameTime.set_time(hours,minute)
	minutes.start()
