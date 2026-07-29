extends Label

@export var color : ColorRect

func _ready() -> void:
	enter()

func enter() -> void:
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(color,"self_modulate",Color(1.0, 1.0, 1.0),0.75)
	await tween.finished

func exit() -> void:
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(color,"self_modulate",Color.TRANSPARENT,0.75)
	await tween.finished
