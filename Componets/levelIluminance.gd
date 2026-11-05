
class_name IluminanceLevel extends Component

#SUBVIEWPORT
@onready var sub_viewport : SubViewport = SubViewport.new()
@onready var light_detection : Node3D = Node3D.new()
@onready var cam_iluminace : Camera3D = Camera3D.new()
@onready var iluminace_mesh : MeshInstance3D = MeshInstance3D.new()
@onready var iluminace_color : ColorRect = ColorRect.new()

@export var isDisabled : bool = false
@export var timeToUpdateIluminance : float = 1
@export var limitToShadow : float = 0.3

var in_shadow : bool

var level : float 

func _ready() -> void:
	if !Engine.is_editor_hint():
		create_ilumance_nodes()

func create_ilumance_nodes() -> void:
	if isDisabled:return
	user = get_parent()
	add_child(sub_viewport)
	add_child(iluminace_color)
	sub_viewport.add_child(light_detection)
	sub_viewport.size = Vector2(1,1)
	light_detection.add_child(cam_iluminace)
	light_detection.add_child(iluminace_mesh)
	iluminace_mesh.scale = Vector3(0.5,0.5,0.5)
	iluminace_mesh.mesh = SphereMesh.new()
	iluminace_mesh.set_layer_mask_value(1,false)
	iluminace_mesh.set_layer_mask_value(20,true)
	if user is Entity:
		light_detection.global_position = user.global_position
	cam_iluminace.global_position.y = 1
	cam_iluminace.rotation_degrees.x = -90.0
	cam_iluminace.fov = 50
	cam_iluminace.far = 20
	cam_iluminace.size = 4

func _process(delta : float ) -> void:
	set_process(!Engine.is_editor_hint())
	if !isDisabled:
		get_iluminance_player(limitToShadow)

func get_iluminance_player(limit:float) -> void:
	await get_tree().create_timer(timeToUpdateIluminance).timeout
	if user is Node3D:
		light_detection.global_position = user.global_position
	var texture : Texture = sub_viewport.get_texture()
	var color : Color = get_average_color(texture)
	iluminace_color.color = color
	level = color.get_luminance()
	if level < limit:
		in_shadow = true
	in_shadow = false

static func get_average_color(texture: ViewportTexture) -> Color:
	var image : Image = texture.get_image()
	image.resize(1, 1)
	return image.get_pixel(0, 0)
