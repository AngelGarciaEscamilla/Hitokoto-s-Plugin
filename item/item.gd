@tool
@icon("res://addons/Hitokoto´s Plugin/icons/item.png")
class_name ItemObject extends StaticBody3D

var alignment_node : AlignmentUser = AlignmentUser.new()
@onready var size_collision : Vector3 = Vector3(1,1,1)
@onready var collision = CollisionShape3D.new()

var object : Node
@export var call_method_interacter : String = "examine"
@export var examin_anim : String = "takeItem"
@export_node_path() var alignment_path
var alignment : Node3D
var is_visible : VisibleOnScreenEnabler3D = VisibleOnScreenEnabler3D.new()
@export var item : Item:
	set(value):
		item = value
		if object && object.is_inside_tree():
			object.queue_free()
			collision.queue_free()
			object = null
		if value && value.scene:
			object = value.scene.instantiate()
			collision = CollisionShape3D.new()
			create_collision()
			create_object_item()
@export var animation : bool = true
@export var duration_take : float = 0.5
@export var duration_save : float = 0.5

var sound_take : SFX = SFX.new()

var alignment_object : bool 

var body_ : Player

func _ready() -> void:
	if !item:return
	add_child(alignment_node)
	alignment_node.finished_alignment.connect(take_anim)
	add_child(sound_take)
	Hitokoto.save(self)
	call_deferred("set_alignament")
	layers()

func create_object_item() -> void:
	if object && !object.is_inside_tree():
		object = item.scene.instantiate()
		add_child(object)


func set_alignament() -> void:
	if !alignment_path: 
		push_error("dont found alignament "+str(self))
		return
	if has_node(alignment_path):
		alignment = get_node(alignment_path)

func layers() -> void:
	self.set_collision_layer_value(2,true)
	self.set_collision_mask_value(2,true)

func _physics_process(delta:float) -> void:
	if Engine.is_editor_hint():
		call_deferred("create_object_item")
	
	if alignment_object && body_ && "hand_target" in body_:
		object.global_position = body_.hand_target.global_position
		object.global_rotation = body_.hand_target.global_rotation

func create_collision() -> void:
	if !item:return
	add_child(collision)
	collision.shape = BoxShape3D.new()
	collision.scale = item.size_collision


func i(body: Node) -> void:
	var inventory : Inventory
	for child in body.get_children():
		if child is Inventory:
			inventory = child
	if !inventory:return
	if !(!inventory.inventory_full && inventory.has_slot_interactive()):
		return
	if !inventory.inventory_full && !inventory.is_using_item():
		body_ = body
		if animation:
			if inventory.current_slot != inventory.slot_interactive:
				inventory.slot_select(inventory.slot_interactive)
			alignment_node.alignment = alignment
			alignment_node.play_alignment(body)
		else:
			give_item()
			dissapear()


func take_anim():
	if !body_.has_method(call_method_interacter):return
	method(body_,"freeze",[true])
	method(body_,call_method_interacter,[examin_anim,duration_take+duration_save])
	await get_tree().process_frame
	if "state" in body_ && body_.state != Humanoid.EXAMINE:
		stop()
		return
	await get_tree().create_timer(duration_take).timeout
	alignment_object = true
	give_item()
	if duration_save >= 0.1:
		await get_tree().create_timer(duration_save-0.1).timeout
	if !body_ || ("state" in body_ && body_.state != Humanoid.EXAMINE):
		stop()
		dissapear()
		return
	alignment_object = false
	method(body_,"freeze",[false])
	dissapear()

func stop() -> void:
	alignment_object = false
	method(body_,"freeze",[false])

func give_item() -> void:
	if body_:
		for child in body_.get_children():
			if child is Inventory:
				method(object,"take")
				child.give_item(item.duplicate())
				break

func has_inventory(body:Node) -> Inventory:
	for child in body.get_children():
		if child is Inventory:
			return child
	return null

func dissapear() -> void:
	queue_free()

func method(node:Node,method:String,args := []) -> void:
	if !node:return
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() != args.size():
			return
		if args && !get_method_node_args(node,method):
			args = []
		node.callv(method,args)


func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []
