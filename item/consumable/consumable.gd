class_name Consumable extends Node3D

signal consuming

func use(user:Entity,inventory:Inventory,current_item:Item) -> void:
	user.set_stadistic(current_item.to_received,current_item.scope_received)
	inventory.remove_item(inventory.current_item_index)
	inventory.unequip_current_item()
	emit_signal("consuming")
