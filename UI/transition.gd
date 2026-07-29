extends Control

@export var background : Control

func enter():
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(background,"self_modulate",Color(1.0, 1.0, 1.0),0.75)
	await tween.finished
	tween.kill()

func exit() -> void:
	background.self_modulate = Color(1.0, 1.0, 1.0)
	var tween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(background,"self_modulate",Color.TRANSPARENT,0.75)
	await tween.finished
	tween.kill()
