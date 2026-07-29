class_name PushSense extends Component

var area : Area3D = Area3D.new()
var radius : CollisionShape3D = CollisionShape3D.new()


@export var enabled = true:
	set(value):
		enabled = value
		area.monitoring = enabled
		radius.disabled = !enabled
@export_flags_3d_navigation var layers =  1 << 8:
	set(value):
		layers = value
		area.collision_layer = layers
@export_flags_3d_navigation var masks =  1 << 8:
	set(value):
		masks = value
		area.collision_mask = masks

@export var strenght_limit : float = 7.5

var collision : CollisionShape3D

signal push(intensity:float)

func _ready():
	set_user()
	if !valid_user("Node3D"):return
	call_deferred("find_sibling")

func find_sibling() -> void:
	if Engine.is_editor_hint():return
	radius.shape = SphereShape3D.new()
	radius.debug_color = Color.RED
	radius.scale = Vector3(2,2,2)
	user.call_deferred("add_child",area)
	if area:
		area.call_deferred("add_child",radius)
		area.collision_mask = masks
		area.collision_layer = layers
		area.body_entered.connect(enter)

func enter(body:Node3D) -> void:
	if body.has_method("get_linear_velocity"):
		var kick_strength : float = body.linear_velocity.length()
		if kick_strength > strenght_limit:
			method(user,"push",[kick_strength])
			emit_signal("push",kick_strength)

func _exit_tree():
	if is_instance_valid(area):
		area.queue_free()
	area = null
