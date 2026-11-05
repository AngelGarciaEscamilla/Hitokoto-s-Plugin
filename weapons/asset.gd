class_name Asset extends Resource


@export var img : Texture
@export var name : TranslatorText = TranslatorText.new()
@export var scene : PackedScene
@export var duration_anim : float = 0.2
@export var select_anim : String = "select"
@export var deselect_anim : String = "deselect"
@export_multiline var note : String