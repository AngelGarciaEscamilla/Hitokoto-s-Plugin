@tool
class_name CrouchState extends Component

var is_crouching : bool
@export var can_crouch : bool = true
@export var speed_crouch : float = 1.5

var scale_y : float
var collision_y_position : float
var collision : CollisionShape3D
var collision_shape : Shape3D:
	get():
		return collision_shape.duplicate()


var inventory : Inventory

signal is_crouch(state:bool)

func _ready() -> void:
	set_user()
	if valid_user("PhysicsBody3D"):
		call_deferred("find_sibling")

func find_sibling() -> void:
	for child in user.get_children():
		if child is CollisionShape3D && !(child.shape is SeparationRayShape3D):
			collision = child
			create_collision()
		if child is Inventory:
			inventory = child

func create_collision() -> void:
	scale_y = collision.scale.y
	collision_shape = collision.shape
	collision_y_position = collision.position.y

func collision_in_crouch() -> void:
	if Engine.is_editor_hint():return
	collision.shape = null
	collision.shape = collision_shape
	if collision_shape is CapsuleShape3D || collision_shape is CylinderShape3D:
		var height = collision.shape.height + collision.shape.radius /5
		collision.position.y = -height /5
		collision.shape.height = collision_shape.height / 1.72
	else:
		collision.scale.y = scale_y / 2
		collision.position.y = -scale_y / 2

func collision_in_normal() -> void:
	if Engine.is_editor_hint():return
	if !collision:return
	collision.scale.y = scale_y
	collision.shape = collision_shape
	collision.position.y = collision_y_position


func _physics_process(delta:float) -> void:
	if Engine.is_editor_hint():return
	if !user:return
	if !has_state():return
	if !valid_user("PhysicsBody3D"):return
	if !user.is_on_floor() || user.state == Humanoid.EXAMINE || user.state == Entity.RUN || user.state == Humanoid.FALLEN:
		is_crouching = false
	if !is_crouching:
		collision_in_normal()
	else:
		if "SPEED_CURRENT_LIMIT" in user && speed_crouch > 0:
			user.SPEED_CURRENT_LIMIT = speed_crouch
		collision_in_crouch()


func crouch() -> void:
	if !valid_user("PhysicsBody3D"):return
	if !can_crouch || ("can_move" in user && !user.can_move):return
	if is_crouching:
		var to = Vector3(user.global_position.x,user.global_position.y+(0.5+(user.scale.y/2)),user.global_position.z)
		if ray_hits(user.global_position,to):
			return
		user_has("state",func():user.state = Entity.IDLE)
		is_crouching = false
	else:
		if inventory && inventory.current_item && inventory.current_item.weight > 0:
			return
		is_crouching = true
	emit_signal("is_crouch",is_crouching)

func ray_hits(from: Vector3, to: Vector3, excluded_nodes: Array = []) -> bool:
	var space_state = user.get_world_3d().direct_space_state
	var exclude_rids: Array = []
	for n in excluded_nodes:
		if n is CollisionObject3D:
			exclude_rids.append(n.get_rid())
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 0xFFFFFFFF
	while true:
		query.exclude = exclude_rids
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return false
		var collider = result.collider
		if collider is PhysicalBone3D:
			if collider is CollisionObject3D:
				exclude_rids.append(collider.get_rid())
			continue
		for n in excluded_nodes:
			if collider == n or n.is_ancestor_of(collider):
				if collider is CollisionObject3D:
					exclude_rids.append(collider.get_rid())
				continue
		return true
	return true
