class_name WeaponItem extends RigidBody3D

@export var weapon : Weapon

func i(body:Node3D) -> void:
	if !weapon:return
	var inventory : Inventory = find_node(body,"Inventory")
	var interact : Interact = find_node(body,"Interact")
	if !inventory || !interact:return
	if !inventory.is_interacted():
		interact.desactivate_interact(1)
	else:
		return
	inventory.add_current_weapon(weapon)
	caught()

func caught() -> void:
	queue_free()

func find_node(node: Node, class_type:String) -> Node:
	if node.is_class(class_type):
		return node
	for child in node.get_children():
		if child.name == class_type || child.name == class_type+node.name:
			return child
		var result = find_node(child, class_type)
		if result:
			return result
	return null

func save() -> void:
	Hitokoto.save(self)

func set_propertys(contacts : int = 1)-> void:
	set_collision_layer_value(1,false)
	set_collision_mask_value(1,false)
	set_collision_layer_value(5,true)
	set_collision_mask_value(5,true)
	set_collision_layer_value(7,true)
	set_collision_mask_value(7,true)
	freeze = self.get_parent() is Marker3D || self.get_parent() is BoneAttachment3D
	contact_monitor = true
	max_contacts_reported = contacts
