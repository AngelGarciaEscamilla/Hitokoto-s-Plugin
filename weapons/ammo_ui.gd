extends Control

@export var label : Label
var inv : Inventory

func find_inv() -> void:
	if Hitokoto.get_player_3d():
		inv = find_inventory(Hitokoto.get_player_3d())

func find_inventory(node: Node) -> Inventory:
	if node is Inventory:
		return node
	for child in node.get_children():
		var result = find_inventory(child)
		if result:
			return result
	return null

func _process(delta):
	if inv:
		if inv.is_interacted():
			label.text = str(inv.current_slot)+" interactive"
			return
		if inv.get_current_weapon():
			label.text = str(inv.current_slot)+" / "+str(inv.get_current_weapon().name.current_lenguage_text())+" : "+str(inv.get_current_weapon().current_charger)+" // 
			"+str(inv.get_current_weapon().type_ammo)+" : "+str(inv.get_current_ammo())
	else:
		find_inv()
