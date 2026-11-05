class_name OrbitTarget extends Node3D

@export var enabled: bool = true
@export var blend_target : float = 0.1
@export var target: Node3D
@export var distance: float = 4.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -70.0
@export var max_pitch: float = 45.0

var yaw := 0.0
var pitch := 0.0

var inv : Inventory

func _ready():
	await get_tree().process_frame
	inv = Hitokoto.find_node(get_parent(),"Inventory")

func _input(event):
	if inv && inv.in_inventory:return
	if !enabled:return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity

		pitch = clamp(
			pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

func _process(delta):
	if !target:
		return
	if target:
		global_position = lerp(global_position,target.global_position,blend_target)
	rotation = Vector3(pitch, yaw, 0)
