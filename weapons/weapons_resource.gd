extends Asset

class_name Weapon

@export var fully_automatic : bool
@export_enum("melee","short","large","other") var type : String = "melee"
@export var type_weapon : String = "melee"
@export_enum("melee",
"general_ammo",
"9mm",".45",".22",".16",".12",) var type_ammo = "melee"
@export_category("Animation")
@export_category("stadistic Weapon")
@export var bullet_at_time : bool 
@export var propertys : Dictionary
@export_range(1,33) var shoot_bullet : int = 1
@export var charger : int:
    get:
        return abs(charger)
@export var current_charger : int:
    get:
        return abs(current_charger)
@export_range(0,50) var time_to_charger : float = 1
@export_range(0, 20,0.05,"exp") var weight : float = 0.9
@export_category("stadistic Weapon/Melee")
@export_range(0,999) var damage_amount : float 
@export_range(0,999) var knockback_amount : float 
@export_range(0,50) var scope : float = 5.0
@export_range(0,25) var delay_to_shoot : float = 1.0
@export_range(0,50) var trauma : float = 13.5
@export var velocity : float = 30.0
@export var sensibility_input : Vector2 = Vector2(0.7,0.7)
@export_range(40, 179,1,"exp") var aim_fov : float = 65
@export var bullet_size : Vector3 = Vector3(0.1,0.1,0.1)
@export var hitbox_size : Vector3 = Vector3(1.0,1.0,1.0)
@export var collision : Shape3D = BoxShape3D.new()
@export var data : Dictionary = {}
@export var bullet : PackedScene = preload("res://addons/Hitokoto´s Plugin/weapons/melee/bullet.tscn")


func current_charger_full() -> bool:
    return current_charger >= charger

func is_melee() -> bool:
    return type == "melee"