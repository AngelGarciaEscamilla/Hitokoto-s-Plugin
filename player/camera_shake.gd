
extends Camera3D
class_name CameraShake3D

@onready var c = self.get_parent()

@export var t_r_r : float = 1
var trauma : float = 0.0

var can = false

@export var max_x : float = 25.0
@export var max_y : float = 25.0
@export var max_z : float = 12.0

@export var noise: FastNoiseLite = FastNoiseLite.new()
@export var noise_speed = 10.0
var time : float = 0.0
var timer : int = 0

@onready var initial_rot_x : float = c.rotation_degrees.x
@onready var initial_rot_z : float = c.rotation_degrees.z
@onready var initial_rot_y : float = c.rotation_degrees.y

func _ready():
	c = self

func _process(delta:float) -> void:
	time += delta
	trauma = max( trauma - delta * t_r_r, 0.0)
	if c:
		c.rotation_degrees.x = max_x * get_shake_intensity() * get_noise_from_seed(0)
		c.rotation_degrees.y = max_y * get_shake_intensity() * get_noise_from_seed(1)



func add_trauma(trauma_am) -> void:
	if c:
		initial_rot_x = c.rotation_degrees.x
		initial_rot_z = c.rotation_degrees.z
		initial_rot_y = c.rotation_degrees.y
	
	can = true
	trauma = clamp(trauma + trauma_am, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)
