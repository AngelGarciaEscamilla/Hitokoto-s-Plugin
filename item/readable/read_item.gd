class_name ReadItem extends Node3D

@export var panel_scene : PackedScene = preload("res://addons/Hitokoto´s Plugin/item/readPanel.tscn")
var panel : ReadPanel = panel_scene.instantiate()

signal read
signal undo_read

func use(user,inventory:Inventory,item:Item) -> void:
	if !(user is Player):return
	add_child(panel)
	inventory.is_using = true
	user.freeze(true)
	slow_motion()
	panel.set_title(item.title)
	panel.set_autor(item.autor)
	panel.set_content(item.content)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("read")

func undo_use(user,inventory:Inventory,item:Item) -> void:
	if !(user is Player):return
	undo_slow_motion()
	panel.queue_free()
	user.freeze(false)
	inventory.inventory.deselect(inventory.current_item_index)
	inventory.is_using = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inventory.reboot_asset_in_hand()
	emit_signal("undo_read")

func slow_motion() -> void:
	Engine.time_scale = 0.2

func undo_slow_motion() -> void:
	Engine.time_scale = 1.0
