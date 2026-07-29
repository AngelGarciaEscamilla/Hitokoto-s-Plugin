@tool
@icon("res://addons/Hitokoto's Plugin/icons/ammo.png")
class_name Ammo extends Area3D

@export var ammo : int = 1
@onready var sound_effect : SFX = SFX.new()
@export var sound : AudioStream 


@export_enum("melee",
"general_ammo",
"9mm",".45",".22",".16",".12",) var type_ammo = "9mm"

var ammo_type = {
	"general_ammo" : 0,
	"9mm" : 0,
	".45" : 0,
	".22" : 0,
	".16" : 0,
	".12" : 0,
}

signal take_ammo(type_ammo:String)



func _ready() -> void:
	Hitokoto.save(self)
	call_deferred("create_sound")
	self.body_entered.connect(body_enter)

func create_sound() -> void:
	get_parent().add_child(sound_effect)
	if sound_effect.is_inside_tree():
		sound_effect.global_position = global_position
	sound_effect.stream = sound


func body_enter(body) -> void:
	if !(body is PhysicsBody3D):return
	if body.get_children():
		for child in body.get_children():
			if child is Inventory:
				child.add_ammo(ammo,type_ammo)
				emit_signal("take_ammo",type_ammo)
				destroy()

func destroy() -> void:
	if !Engine.is_editor_hint():
		sound_effect.play()
		if sound_effect:
			await get_tree().create_timer((sound_effect.stream.get_length())).timeout
		call_deferred("queue_free")

func get_shapes() -> Array[CollisionShape3D]:
	var shapes : Array[CollisionShape3D]
	for child in get_children():
		if child is CollisionShape3D:
			shapes.append(child)
	return shapes
