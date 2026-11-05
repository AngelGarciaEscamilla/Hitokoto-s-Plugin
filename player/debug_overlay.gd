class_name DebugOverlay extends Component

@export var HUD : PackedScene 
var hud : Node

@export var enabled: bool
@export var key_hud: String

var toggle : bool

func _ready():
	set_user()
	if HUD:
		hud= HUD.instantiate()
		add_child(hud)
		if "user" in hud:
			hud.user = user

func _process(delta) -> void:
	if !HUD:return
	if enabled && InputMap.has_action(key_hud):
		if Input.is_action_just_pressed(key_hud):
			toggle = !toggle
	if toggle:
		if hud.has_method("hud"):
			hud.hud()
	else:
		if hud.has_method("hide"):
			hud.hide()
