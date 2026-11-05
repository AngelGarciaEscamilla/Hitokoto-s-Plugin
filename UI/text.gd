@tool
class_name Text extends Label

@export var translator : TranslatorText
@export var text_extra :String


var lenguageText : Dictionary = {}

func _ready():
	autowrap_mode = TextServer.AUTOWRAP_ARBITRARY

func _physics_process(delta):
	if translator:
		if text_extra.is_empty():
			text = translator.current_lenguage_text()
		else:
			text = translator.current_lenguage_text() + " " +text_extra.to_upper()
