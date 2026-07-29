class_name TestScript extends Node

@export var quiet : bool 
@export var c : CutScene
# @export_node_path() var b_node : NodePath
# @export_node_path() var a_node : NodePath

var fps = Label.new()

var pressed_annotations : bool

var toggle : bool

func _ready() -> void:
	add_child(fps)
	if !quiet:
		get_child(0).play("new_animation")

func exit() -> void:
	# player.inventory.load_item(preload("res://addons/Hitokoto's Plugin/item/consumable/juice_in_stock.tres"))
	# b.on()
	if c:
		if !toggle:
			c.play()
			toggle = true
		else:
			c.stop()
			toggle = false
	# get_child(0).stop()

func _process(delta):
	if Input.is_action_just_pressed("test"):
		exit()
