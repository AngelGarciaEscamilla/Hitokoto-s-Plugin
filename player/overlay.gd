extends Control

@onready var HUD = $"HUD"

var user : Node
var cam_name : String
var current_weapon : String

func hud()-> void:
	if get_viewport().get_camera_3d():
		cam_name = get_viewport().get_camera_3d().name
	if user:
		var fps_ : float = Engine.get_frames_per_second()
		HUD.text = "FPS: " +str(fps_)+  ": "+str(user.interact.get_bodies())+" F "+"
		"+str(user.velocity.length())+" // "+str(user.CURRENT_SPEED_LIMIT)+"
		//// d "+""+str(user.strafe)+"
		X:" + str(user.global_position.x) +"
		Y:" + str(user.global_position.y) +"
		Z:" + str(user.global_position.z) +"
		direction"+str(user.get_direction())+"
		Velocity:" + str(user.velocity) +" : "+str(user.is_exhausted())+"
		STATUS_HANDS:" + str(user.state_hands)+"
		STATUS_BODY:" + str(user.state)+"
		STADISTICS:" + str(user.stadistics)+"
		weapon:" + str(user.inventory.current_weapon)+"
		aim:" + str(user.inventory.aim)+"    w "+str(user.inventory.shoot_no_auto)+"
		damage in air:" + str(user.fall.strength_impact)+"
		talking:" + str(user.dialogue.is_talking)+","+str(user.dialogue.in_conversation)+"
		Time Scale:" + str(Engine.time_scale)+"
		Time:" + GameTime.get_time_string()+" : "+str(GameTime.get_time())+"
		delta:" + str(Hitokoto.global_delta)+"
		Resolution:" + str(get_viewport().get_visible_rect().size)+"
		inventory:" + str(user.inventory.inventory_slots)+" : "+str(user.inventory.current_item)+"
		hand_target:" + str(user.hand_target.get_children())+"
		slot:" + str(user.inventory.current_slot)+" : "+str(user.inventory.slots)+""+str(user.inventory.slot_interactive)+str(current_weapon)+"
		calendar:" + str(GameTime.calendar)+"
		time played:" + str(GameTime.get_time_passed())+"
		sensibility Input:" + str(user.current_sensibility_cam)+"
		missions:" + str(MissionManager.get_active_missions_names())+"
		ammo:" + str(user.inventory.ammo)+"
		dependences:" + str(Hitokoto.values)+"
		current speed:" + str(user.CURRENT_SPEED)+"
		cam:" + cam_name+" "+ str(user.cam_move)+" * "+ str(user.can_move)+"
		time left failure:" + str(MissionManager.get_time_left_failure())+"
		can_save:" + str(Hitokoto.can_save)+"
		GPU:" + RenderingServer.get_video_adapter_name()
	else:
		HUD.text = "lost player 3333333333333"

func hide() -> void:
	HUD.text = ""

func _process(delta):
	if user.inventory.current_weapon:
		current_weapon = user.inventory.current_weapon.name.current_lenguage_text() 
	else:
		current_weapon = "not found weapon"
	if Input.is_action_just_pressed("f2"):
		Hitokoto.save_data()
	if Input.is_action_just_pressed("f6"):
		Hitokoto.reboot_data()
	if Input.is_action_just_pressed("f1"):
		user.take_damage(9999)
