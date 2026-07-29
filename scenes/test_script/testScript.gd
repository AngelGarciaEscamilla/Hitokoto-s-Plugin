extends Control

@export var background : Control

func _ready():
	var tween : Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(background,"self_modulate",Color(1.0, 1.0, 1.0),0.5)

func exit() -> void:
	var tween : Tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(background,"self_modulate",Color.TRANSPARENT,0.5)
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout
