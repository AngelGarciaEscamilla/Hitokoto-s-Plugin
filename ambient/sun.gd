@tool
@icon("res://addons/Hitokoto's Plugin/icons/Sun.png")
class_name Sun extends Node3D

var sun_orbit : Node3D = Node3D.new()
var moon_orbit : Node3D = Node3D.new()

var sun_light : DirectionalLight3D = DirectionalLight3D.new()
var moon_light : DirectionalLight3D = DirectionalLight3D.new()
var minutes : Timer = Timer.new()

@export_range(0.001,60.0,0.1) var waiting_time : float = 2.0
@export_range(0.0,15.0,0.05) var sun_intensity : float = 0.5:
	set(value):
		sun_intensity = value
		sun_light.light_energy = sun_intensity
@export_range(0.0,15.0,0.05) var moon_intensity : float = 0.2:
	set(value):
		moon_intensity = value
		moon_light.light_energy = moon_intensity
@export var continuous_time : bool = true

@export var color_light_sun : Color = Color.WHITE:
	set(value):
		color_light_sun = value
		sun_light.light_color = color_light_sun
@export var color_light_moon : Color = Color(0.416, 0.51, 0.816):
	set(value):
		color_light_moon = value
		moon_light.light_color = color_light_moon
@export var rotate_moon_y: float = 0.0:
	set(value):
		rotate_moon_y = value
		moon_orbit.rotation.y = deg_to_rad(value)
@export var rotate_moon_z: float = 0.0:
	set(value):
		rotate_moon_z = value
		moon_orbit.rotation.z = deg_to_rad(value)

func _ready() -> void:
	add_child(sun_orbit)
	add_child(moon_orbit)
	add_to_group("sun")
	Hitokoto.save(self)
	create_sun_light()
	create_moon_light()
	create_timer()

func create_timer() -> void:
	add_child(minutes)
	minutes.timeout.connect(pass_minute)
	minutes.wait_time = waiting_time
	minutes.start()

func create_moon_light():
	moon_orbit.add_child(moon_light)
	var m = MeshInstance3D.new()
	moon_light.add_child(m)
	m.mesh = BoxMesh.new()
	moon_light.position.y += 1
	moon_light.rotation_degrees.x = -90
	moon_light.shadow_enabled = true
	moon_light.set_layer_mask_value(19,true)
	moon_light.light_color = color_light_moon
	moon_light.light_energy = moon_intensity
	moon_orbit.rotation.z = deg_to_rad(rotate_moon_y)

func create_sun_light() -> void:
	sun_orbit.add_child(sun_light)
	sun_light.position.y -= 1
	sun_light.set_layer_mask_value(19,true)
	sun_light.rotation_degrees.x = 90
	sun_light.shadow_enabled = true
	sun_light.light_energy = sun_intensity
	sun_light.light_color = color_light_sun
	

func pass_minute() -> void:
	if Engine.is_editor_hint() || !continuous_time:return
	var minute : int = GameTime.get_minutes() + 1
	var hours : int = GameTime.get_hours()
	GameTime.set_time(hours,minute)
	minutes.start()


func _process(delta: float) -> void:
	var up_direction: Vector3 = global_basis.y.normalized()
	var weight := delta
	if up_direction.y > 0.0:
		sun_light.light_energy = lerp(
			sun_light.light_energy,
			0.0,
			weight
		)

		moon_light.light_energy = lerp(
			moon_light.light_energy,
			moon_intensity,
			weight
		)
	else:
		moon_light.light_energy = lerp(
			moon_light.light_energy,
			0.0,
			weight
		)

		sun_light.light_energy = lerp(
			sun_light.light_energy,
			sun_intensity,
			weight
		)
