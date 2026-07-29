@tool
class_name Interact extends Component

var ray_collider : Node3D
var ray : Area3D = Area3D.new()

var collision : CollisionShape3D = CollisionShape3D.new()

@export var method_interact : String = "i"
var target_interact : Node:
	set(value):
		target_interact = value
		create_ray_interact()

@export var can_interact : bool = true
var can_interact_no_share : bool = true
@export var distance_interact : float = 2.5:
	set(value):
		distance_interact = value
		collision.scale = Vector3(value,value,value) 

var is_colliding : bool 
var collider_index : int 

signal collider(collider:Node3D)

func _ready() -> void:
	set_user()
	collision.scale = Vector3(distance_interact,distance_interact,distance_interact) 
	target_interact = user

func create_ray_interact() -> void:
	if target_interact:
		ray = Area3D.new()
		if user:
			user.call_deferred("add_child",(ray))
			ray.call_deferred("add_child",(collision))
			ray.set_collision_layer_value(2,true)
			ray.set_collision_mask_value(2,true)
			ray.set_collision_layer_value(7,true)
			ray.set_collision_mask_value(7,true)
			ray.set_collision_layer_value(1,false)
			ray.set_collision_mask_value(1,false)
		collision.shape = BoxShape3D.new()
		collision.debug_color = Color.BLUE

func _process(delta:float) -> void:
	if valid_user("Node3D") && target_interact && ray && ray.is_inside_tree():
		ray.global_rotation = Vector3.ZERO

func get_bodies() -> Array[Node3D]:
	if !ray || !ray.monitoring:return []
	var f : Array[Node3D] = []
	for i in ray.get_overlapping_bodies():
		if (i.get_parent() is Marker3D || i.get_parent() is BoneAttachment3D):continue
		if i is CollisionObject3D && !(i is PhysicalBone3D) && !(i == user):
			f.append(i)
	return f

func interact(index:int=0) -> void:
	if !valid_user("Node3D") && target_interact && ray && ray.is_inside_tree():
		return
	if !can_interact || !can_interact_no_share:return
	if (index < 0 || index > get_bodies().size()-1) || !get_bodies():
		return
	if ray_hits(user.global_transform.origin,get_bodies()[index].global_transform.origin,[user,get_bodies()[index]]):
		return
	ray_collider = get_bodies()[index]
	interact_object(ray_collider)

func interact_object(obj:Node3D) -> void:
	if !obj:return
	method(obj,method_interact,[user])

func desactivate_interact(duration : float) -> void:
	ray.monitoring = false
	await get_tree().create_timer(duration).timeout
	ray.monitoring = true

func ray_hits(from: Vector3, to: Vector3, excluded_nodes: Array = []) -> bool:
	var space_state = user.get_world_3d().direct_space_state
	var exclude_rids: Array = []
	for n in excluded_nodes:
		if n is CollisionObject3D:
			exclude_rids.append(n.get_rid())
	while true:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = exclude_rids
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.collision_mask = 0xFFFFFFFF
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			return false
		var collider = result.collider
		if collider is PhysicalBone3D:
			exclude_rids.append(collider.get_rid())
			continue
		var ignore := false
		for n in excluded_nodes:
			if collider == n or n.is_ancestor_of(collider):
				ignore = true
				break
		if ignore:
			if collider is CollisionObject3D:
				exclude_rids.append(collider.get_rid())
			continue
		return true
	return true


func is_child_of_excluded(node: Node, excluded_nodes: Array) -> bool:
	for ex in excluded_nodes:
		if node == ex or node.is_ancestor_of(ex) or ex.is_ancestor_of(node):
			return true
	return false


func _exit_tree() -> void:
	if ray && ray.is_inside_tree():
		ray.queue_free()
	ray = null
