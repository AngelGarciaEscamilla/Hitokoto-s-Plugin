
class_name PauseMenu extends Control

@export var pause_menu_screen : PackedScene = preload("res://addons/Hitokoto's Plugin/UI/pauseMenu.tscn")
@onready var pause_menu : Control = pause_menu_screen.instantiate()
@export var escape_key : String = "ui_cancel"
@export var enabled : bool = true

var can_pause : bool = true
var player : Node3D
var pause : bool 
var captured : bool

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameTime.start_playtime_counter()
	player = Hitokoto.get_player_3d()
	if player is Entity:
		player.dead.connect(queue_free)
	MissionManager.fail_mission.connect(fail)
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func verified_pause() -> bool:
	if get_tree().paused != pause:
		return false
	return true

func _input(event:InputEvent) -> void:
	if !enabled:return
	if InputMap.has_action(escape_key) && event.is_action_pressed(escape_key) && can_pause:
		if !verified_pause():return
		pause = !get_tree().paused
		GameTime.pause_game(!get_tree().paused)
		await get_tree().process_frame
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			captured = true
		action_pause()

func action_pause() -> void:
	if get_tree().paused:paused()
	else:play()

func play() -> void:
	if pause_menu &&pause_menu.has_method("exit"):
		can_pause = false
		if captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		await pause_menu.exit()
	can_pause = true
	GameTime.start_playtime_counter()
	if pause_menu:pause_menu.queue_free()

func paused() -> void:
	GameTime.stop_playtime_counter()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	create_screen()

func create_screen() -> void:
	pause_menu = pause_menu_screen.instantiate()
	add_child(pause_menu)
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in pause_menu.get_children():
			child.process_mode = Node.PROCESS_MODE_ALWAYS

func fail(mission:Mission) -> void:
	queue_free()