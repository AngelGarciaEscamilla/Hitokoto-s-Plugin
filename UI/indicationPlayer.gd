extends IndicationInterface

@export var label : Label

func set_indication(indication:String) -> void:
	label.text = indication