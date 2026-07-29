@tool
extends Node

var inventory : Inventory

var user

func _ready():
	user = get_parent()
	await get_tree().process_frame
	inventory = Hitokoto.find_node(user,"Inventory")


func _input(event:InputEvent) -> void:
	if !(user is Node3D):return
	if !("state" in user):return
	match user.state:
		Entity.IDLE:wheel_slots_select(event)
		Entity.WALK:wheel_slots_select(event)
		Entity.RUN:wheel_slots_select(event)


func wheel_slots_select(event: InputEvent) -> void:
	if !inventory:return
	if event is InputEventMouseButton && event.pressed:
		if inventory.in_inventory:return
		if event.button_index == 5 || event.button_index == 4:
			var slot_decreased : int = -1
			if event.button_index == 4:
				slot_decreased = 1
			var new_slot = inventory.current_slot+slot_decreased
			new_slot = wrapf(new_slot,0,inventory.slots.size())
			inventory.slot_select(new_slot)
