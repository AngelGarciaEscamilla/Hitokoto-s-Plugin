class_name InventoryPanel extends Control

@export var details_item : Label 
@export var items_list : ItemList

var tween_show :Tween 
var tween_hide :Tween 

var user : Inventory

func _ready():
	modulate = Color.TRANSPARENT

func set_description(description : String) -> void:
	details_item.text = description

func get_item_list() -> ItemList:
	return items_list

func _on_button_pressed():
	user = get_parent()
	user.unequip_current_item()


func _on_button_2_pressed():
	items_list.deselect_all()

func show() -> void:
	if is_instance_valid(tween_hide):
		tween_hide.kill()
	tween_show = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_show.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_show.tween_property(self,"modulate",Color.WHITE,0.2)
	tween_show.tween_callback(func():
		tween_show.kill())

func hide() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(tween_show):
		tween_show.kill()
	tween_hide = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_hide.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_hide.tween_property(self,"modulate",Color.TRANSPARENT,0.1)