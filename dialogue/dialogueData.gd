class_name DialogueData extends Resource

@export_node_path() var user_path : NodePath
@export var chained : bool
@export var finish_timeline : bool
@export var auto_hide : bool = true
@export var audio : AudioStream
@export_file("*.json") var phonemes: String
@export_range(0.2,99.9) var duration : float = 1.0
@export var anim : StringName = &"test"
@export var subtitles : TranslatorText = TranslatorText.new()
@export var propertys : Dictionary = {"look_at_user":true}
@export var dependence_key : String
@export var add_dependence : Variant
@export var condition_key : String
@export var condition_value : Variant
@export var dialogue_alternative : DialogueData

