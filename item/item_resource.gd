class_name Item extends Asset

@export var id : int
@export var use_anim : String = "consumable"
@export var hold_anim : String = "item"
@export_range(0.0, 20, 0.1, "suffix: kg") var weight: float = 0.0
@export_range(0,9999) var value : float
@export_range(0,12) var time_use : float = 2
@export var description : TranslatorText

@export_group("item")
@export var can_use : bool = true
@export var is_disposable : bool = true
@export var size_collision : Vector3 = Vector3(0.2,0.2,0.2)
@export var sound_used : AudioStream
@export var sound_take : AudioStream
@export var sound_take_out : AudioStream
@export var propertys : Dictionary

@export_group("Consumable")
@export var to_received : String = "Life"
@export var scope_received : float 

@export_group("readable")
@export var title : StringName
@export var autor : StringName
@export var content : TranslatorText