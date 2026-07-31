@tool
class_name Inventory extends Component

######################################################################################################################################
#if wanna change fov with interpolation aim search for a meta name "target_fov" and change that
######################################################################################################################################

@export var inventory_scene : PackedScene:
	set(value):
		inventory_scene = value
		if value:
			inventory_panel = inventory_scene.instantiate()
var inventory_panel : Node

var timer_shoot : Timer = Timer.new()
var timer_charger : Timer = Timer.new()
var timer_use_item : Timer = Timer.new()

var only_interact : bool

func just_interact(value:bool) -> void:
	if value:
		slot_select(slot_interactive,true)
	only_interact = value
@export var can_change_slot : bool = true
@export var can_shoot : bool = true
@export var can_aim : bool = true
@export var use_inventory : bool = true
@export var enabled_aim : bool = true
@export var load_item_in_inventory : bool

@export_category("Slots")

@export var ammo : Dictionary = {
	"melee" : 0,
	"general_ammo" : 0,
	"9mm" : 0,
	".45" : 0,
	".22" : 0,
	".16" : 0,
	".12" : 0,
}
@export var inventory_slots : Array[Item] = []
@export var slots : Array[Asset] = []
@export var default : Weapon
@export var interval_asset_time : float = 0.3
@export var slot_interactive : int = 0:
	get:
		if Engine.is_editor_hint():return slot_interactive
		slot_interactive = clamp(slot_interactive,-1,slots.size()-1)
		return slot_interactive
@export var current_slot : int:
	get:
		if Engine.is_editor_hint():return current_slot
		current_slot = clamp(current_slot,0,slots.size()-1)
		return current_slot

@export_category("Attachment")
@export var pos_ray_aim : Vector3 = Vector3(0,0.4,-0.5)
@export var gun_attachment : Array[Array] = [
	[2,"holster_left","melee"],[1,"holster_right","melee"],[2,"holster_left","short"],[1,"holster_right","short"],[2,"gun_upper_back","large"],[1,"gun_shoulder","large"]
]
@export var hand_target : Node3D

var tween_animation : Tween

var current_item_index : int

var speed_walk_user : float
var speed_run_user : float
var global_delta : float
var anim_asset : bool 
var flag_show_inventory : bool = true
var flag_change_slot : bool = true
var flag_shoot : bool = true
var flag_charger : bool = true
var flag_change_inventory : bool = true
var shoot_no_auto : bool
var is_shooting : bool
var old_aim : bool
var aim : bool:
	set(value):
		if in_inventory || anim_asset:return
		if user is PhysicsBody3D:
			if user_front_asset():
				aim = false
				return
		if is_interacted():
			aim = false
			return
		aim = value
		change_strafe_user(aim)
		if aim == old_aim:return
		old_aim = aim
		if old_aim:
			aim_action()
		else:
			undo_aim()

func change_strafe_user(value:bool) -> void:
	if "strafe" in user && !user_strafe_init:
		user.strafe = value
var inventory_full : bool
var is_using : bool
var in_inventory : bool
var captured : bool
var reboot_repos : bool
var user_strafe_init : bool

var current_item : Item
var current_weapon : Weapon
var current_weapon_load: Weapon

const METAPATHFOV : String = "target_fov"
const PARAMETERSPATH : String = "parameters/"
const BLENDAMOUNTPATH : String = "/blend_amount"

signal use_item(item:Item)
signal shoot_weapon(weapon:Weapon)
signal charger_weapon(weapon:Weapon)
signal aim_weapon
signal repos_weapon(weapon:Weapon)
signal reboot_hand()
signal add_hand()
signal in_slot(index:float)

var animation_tree : AnimationTree
var inventory : ItemList
var current_cam : Camera3D
var interpolation : InterpolationState

func _ready() -> void:
	set_user()
	if !(user is Node3D):return
	if "strafe" in user:
		user_strafe_init = user.strafe
	GameTime.in_pause_game.connect(pause)
	reboot_hand.connect(show_all_attachment)
	add_hand.connect(attachment_visible)
	create_timers()
	create_use()
	if !Engine.is_editor_hint():
		find_inventory_list()
		create_inventory()
		GameSettings.load_settings.connect(set_meta_current_cam)
		call_deferred("find_nodes_requirements")
		call_deferred("reload_inventory")
		call_deferred("load_slot_deferred")

func find_nodes_requirements() -> void:
	owner = user
	current_cam = find_node(user,"Camera3D")
	interpolation = find_node(user,"InterpolationState")
	animation_tree = find_node(user,"AnimationTree")
	set_meta_current_cam()

func set_meta_current_cam() -> void:
	if current_cam:
		current_cam.set_meta(METAPATHFOV,current_cam.fov)

func reload_slots() -> void:
	var slots_duplicate : Array[Asset] = []
	for i in slots:
		if i:
			slots_duplicate.append(i.duplicate())
		else:
			slots_duplicate.append(default.duplicate())
	slots = slots_duplicate

func pause(value:bool) -> void:
	if in_inventory:
		hide_inventory()
		if "inventory_key" in user:
			if InputMap.has_action(user.inventory_key):
				Input.action_release(user.inventory_key)
				if captured:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if current_item:
		undo_use_item()

func load_slot_deferred() -> void:
	var index : int = -1
	current_slot = clamp(current_slot,0,slots.size()-1)
	delete_all_attachment()
	reload_slots()
	for asset in slots:
		index += 1
		if asset is Weapon:
			set_weapon(index,slots[index])
			attachment_gun_in_body(slots[index],index)
	if is_valid_slot(slot_interactive) && slots[slot_interactive] is Item:
		current_item = slots[slot_interactive]
	slot_select(current_slot)
	set_description_panel("")

func find_inventory_list() -> void:
	if !inventory_scene:return
	inventory = find_node(inventory_panel,"ItemList")

func get_interact() -> Interact:
	for child in user.get_children():
		if child is Interact:
			return child
	return null

func find_node(node: Node, class_type:String) -> Node:
	if node.is_class(class_type):
		return node
	for child in node.get_children():
		if child.name == class_type || child.name == class_type+node.name:
			return child
		var result = find_node(child, class_type)
		if result:
			return result
	return null


###############################################################################
#CREATE TREE
###############################################################################

func create_inventory() -> void:
	if !use_inventory:return
	if !inventory_scene && use_inventory:
		push_error("an inventory scene is not selected")
		return
	add_child(inventory_panel)
	inventory_panel.process_mode = Node.PROCESS_MODE_DISABLED
	inventory.item_selected.connect(select_item)

func create_use() -> void:
	add_child(timer_use_item)

func create_timers() -> void:
	timer_use_item.one_shot = true
	timer_use_item.timeout.connect(timeout_use_item)
	add_child(timer_shoot)
	timer_shoot.one_shot = true
	timer_shoot.timeout.connect(timeout_shoot)
	add_child(timer_charger)
	timer_charger.timeout.connect(timeout_charger)
	timer_charger.one_shot = true

func reload_inventory() -> void:
	if inventory_slots.is_empty():
		inventory_full = true
		return
	for i in inventory_slots.size():
		if inventory_slots[i] != null:
			add_item_panel(inventory_slots[i],i)

###############################################################################
#PROCWESS AND STATE MACHINE
##############################################################################

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():return
	if !user:return
	if !has_state():return
	global_delta = delta
	if user_front_asset():
		undo_aim()
	match user.state:
		Entity.IDLE:
			aim_process()
		Entity.WALK:
			aim_process()
		Entity.RUN:
			undo_aim()
			undo_aim_fov()
		Entity.FALL:
			undo_aim_fov()
		Humanoid.FALLEN:
			undo_aim_fov()
	if user.state > Entity.WALK && aim:
		aim = false

func user_front_asset() -> bool:
	if !(current_asset_in_hand() is RigidBody3D):return false
	return current_asset_in_hand().get_contact_count()

func stop_activities() -> void:
	current_asset_method("stop")
	aim = false
	undo_use_item()
	hide_inventory()
	timer_charger.stop()
	timer_use_item.stop()
	reboot_charger_action()
	stop_load_weapon()


func undo_use_item() -> void:
	revers_speed_item_weight()
	current_asset_method("undo_use",[user,self,current_item])
	flag_change_inventory = true
	is_using = false



###############################################################################
#INVENTORY
###############################################################################

func show_inventory() -> void:
	if !inventory_scene || !use_inventory :return
	if in_inventory ||  !flag_show_inventory:return
	if !(flag_show_inventory && !is_using):return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	in_inventory = true
	aim = false
	method(inventory_panel,"show",[self])
	user_method("freeze",[true])
	inventory_panel.process_mode = Node.PROCESS_MODE_INHERIT

func hide_inventory(ignore_freeze : bool = false) -> void:
	if !in_inventory || !flag_show_inventory :return
	if captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	in_inventory = false
	method(inventory_panel,"hide",[self])
	if user.velocity == Vector3.ZERO && !ignore_freeze:
		user_method("freeze",[false])
	if inventory && !inventory.get_selected_items().is_empty():
		if !is_interacted():
			slot_select(slot_interactive)
		else:
			load_item(current_item)
	inventory_panel.process_mode = Node.PROCESS_MODE_DISABLED

func select_item(index: int)  -> void:
	slots[slot_interactive] = inventory_slots[index]
	current_item = inventory_slots[index]
	current_item_index = index
	set_description_panel(inventory_slots[index].description.current_lenguage_text())

func used_item(item:Item) -> void:
	if is_using || !item || !(is_interacted() && flag_change_inventory && !in_inventory):return
	if true in [!flag_change_inventory,no_actions(),!item.can_use]:return
	emit_signal("use_item",item)
	set_animation(10,item.use_anim)
	user_has("state_hands",use_item_state)
	if item.time_use > 0.0:
		timer_use_item.wait_time = item.time_use
		timer_use_item.start()
	current_asset_method("init_animation_use")
	flag_change_inventory = false
	await get_tree().process_frame
	is_using = true

func load_item(item:Item,anim:bool=true) -> void:
	if current_slot != slot_interactive:return
	if item:
		unequip_current_item()
		set_animation(9,item.hold_anim)
		flag_show_inventory = true
		flag_change_inventory = true
		affect_speed_item_weight(item.weight)
		add_item_in_hand(item)
		current_weapon = null
		current_item = item
		if anim:
			anim_select_item(current_item)
		user_has("state_hands",hold_item_state)
		current_asset_method("hold")
	else:
		if current_asset_in_hand():
			reboot_asset_in_hand()

func anim_select_item(item:Item) -> void:
	var slot = current_slot
	var inter : Interact = get_interact()
	if current_asset_in_hand():
		method(current_asset_in_hand(),"select",[current_asset_in_hand()])
	if item:
		anim_asset = true
		if inter:
			inter.can_interact_no_share = false
		await play(get_animation_select(item),0.2,item.duration_anim)
		if item:
			stop(get_animation_select(item),0.2)
		if inter:
			inter.can_interact_no_share = true
		anim_asset = false

func get_items() -> Array[Item]:
	var items_return : Array[Item]
	for i in inventory_slots:
		if i:
			items_return.append(i)
	return items_return

func get_item(id:int) -> Item:
	var item_data : Item
	for item in inventory_slots:
		if item.id == id:
			item_data = item
	if !item_data:
		push_error("a item in inventory "+str(user)+"with id "+str(id)+"don´t exist")
	return item_data

func affect_speed_item_weight(weight:float) -> void:
	if !("friction" in user ):return
	user.friction = weight / 2

func revers_speed_item_weight() -> void:
	if !("friction" in user ):return
	user.friction = 0

func give_item(item: Item) -> void:
	if inventory_full:
		remove_item(inventory_slots.size()-1)
		add_item(item)
	else:
		add_item(item)

func add_item(item: Item) -> void:
	flag_shoot = false
	if !flag_change_inventory:return
	for i in inventory_slots.size():
		if !inventory_slots[i]:
			add_item_panel(item,i)
			return

func add_item_panel(item_:Item,i:int) -> void:
	inventory_slots[i] = item_
	if inventory:
		inventory.add_item(item_.name.current_lenguage_text_name(),item_.img)
	if inventory_slots[inventory_slots.size()-1] != null:
		inventory_full = true

func remove_item(index:int) -> void:
	if is_valid_slot_inventory(index) && !inventory_slots[index]:
		return
	if !inventory_slots[index].is_disposable:return
	inventory_full = false
	inventory_slots[index] = null
	if inventory:
		inventory.remove_item(index)
	current_item = null
	set_slot_interactive(null)
	set_description_panel("")
	reboot_asset_in_hand()

func timeout_use_item() -> void:
	flag_change_inventory = true
	current_asset_method("use",[user,self,current_item])

###############################################################################
#SLOTS WEAPONS
###############################################################################

func slot_select(slot_select: int,ignore_limit:bool=false) -> void:
	if slot_select < 0 || slot_select > slots.size()-1: return
	if !ignore_limit:
		if only_interact || no_actions():return
		if !slots || !can_change_slot:return
	unequip_current_item()
	stop_activities()
	emit_signal("in_slot",slot_select)
	if slot_select == slot_interactive && has_slot_interactive():
		current_slot = slot_select
		current_weapon_load = null
		if !ignore_limit:
			await anim_deselect_weapon(current_weapon)
		current_weapon = null
		undo_aim_fov()
		load_item(current_item)
	if slot_select != slot_interactive:
		current_slot = slot_select
		load_weapon(get_weapon(slot_select))

func set_slot_interactive(value:Variant) -> void:
	if has_slot_interactive():
		slots[slot_interactive] = value

func is_interacted() -> bool:
	return current_slot == slot_interactive

func has_slot_interactive() -> bool:
	return !(slot_interactive < 0 || slot_interactive > slots.size())

func unequip_weapon(slot:int) -> void:
	slot_select(slot_interactive)
	set_weapon(slot,default)
	attachment_gun_in_body(default,slot)

func charger_current_slot() -> void:
	if no_load_asset():return
	if no_actions():return
	if !ammo_available() || current_weapon.current_charger_full():
		return
	if current_weapon.is_melee():
		return
	emit_signal("charger_weapon",current_weapon)
	current_asset_method("charger",[current_weapon.current_charger])
	var missing_ammo : int
	var ammo : int
	if !divisible(current_weapon.current_charger, current_weapon.shoot_bullet):
		var slots = get_divisibles(current_weapon.charger, current_weapon.shoot_bullet)
		for i in slots:
			missing_ammo = i - current_weapon.current_charger
			ammo += missing_ammo
			break
	current_asset_method("bullet_at_time",[abs(abs(missing_ammo)-current_weapon.shoot_bullet)])
	charger_animation(current_weapon)
	var time := current_weapon.time_to_charger
	if current_weapon.bullet_at_time:
		time = time / current_weapon.charger
	flag_shoot = false
	flag_charger = false
	flag_change_slot = false
	timer_charger.wait_time = time
	timer_charger.start()

func charger_action() -> void:
	var limit_charger := current_weapon.charger
	current_weapon.current_charger = clamp(current_weapon.current_charger, 0, limit_charger)
	if !ammo_available() or current_weapon.current_charger_full():
		return
	if current_weapon.bullet_at_time:
		var bullet := current_weapon.shoot_bullet
		var available = ammo[current_weapon.type_ammo]
		var to_load := min(bullet, available, limit_charger - current_weapon.current_charger)
		current_weapon.current_charger += to_load
		ammo[current_weapon.type_ammo] -= to_load
		if !divisible(current_weapon.current_charger, bullet):
			for slot in get_divisibles(limit_charger, bullet):
				if slot > current_weapon.current_charger:
					var extra := min(slot - current_weapon.current_charger, ammo[current_weapon.type_ammo])
					current_weapon.current_charger += extra
					ammo[current_weapon.type_ammo] -= extra
					break
		reboot_charger_action()
		if !current_weapon.current_charger_full() and ammo_available():
			charger_animation(current_weapon)
			timer_charger.start()

			var ammo_enough := 0
			for slot in get_divisibles(limit_charger, bullet):
				if slot >= current_weapon.current_charger:
					ammo_enough = slot - current_weapon.current_charger
					break

			current_asset_method("bullet_at_time", [max(ammo_enough, bullet)])
			current_asset_method("charger_finished", [current_weapon.current_charger])
		else:
			current_asset_method("last_loaded_bullet")
			current_asset_method("charger_finished", [current_weapon.current_charger])
		return
	var missing := limit_charger - current_weapon.current_charger
	var to_load := min(missing, ammo[current_weapon.type_ammo])
	current_weapon.current_charger += to_load
	ammo[current_weapon.type_ammo] -= to_load

	current_asset_method("charger_finished", [current_weapon.current_charger])

func divisible(number:int, divisor:int) -> bool:
	if divisor == 0:
		return false
	return number % divisor == 0

func get_divisibles(limit:int, divisor:int) -> Array[int]:
	var result:Array[int] = []

	if divisor <= 0:
		return result

	for i in range(1, limit + 1):
		if i % divisor == 0:
			result.append(i)
	return result

func ammo_available() -> bool:
	var slots = get_divisibles(current_weapon.charger, current_weapon.shoot_bullet)
	for i in slots:
		if current_weapon.current_charger >= i:continue
		if current_weapon.current_charger + ammo[current_weapon.type_ammo] >= i:
			return true
	return false

func get_current_ammo() -> float:
	if get_weapon(current_slot):
		return ammo[get_weapon(current_slot).type_ammo]
	return 0.0

func timeout_charger() -> void:
	if !current_weapon.bullet_at_time:
		reboot_charger_action()
	charger_action()
	update_charger_slots()

func update_charger_slots() -> void:
	set_charger(current_slot,current_weapon.current_charger)

func add_ammo(received_ammo: int,type_ammo: String) -> void:
	ammo[type_ammo] += received_ammo

func unequip_current_item() -> void:
	revers_speed_item_weight()
	if is_interacted():
		if "state_hands" in user:
			user.state_hands = Humanoid.REPOS
		repos_animation(current_weapon)
		reboot_animation_per_item_use()
		reboot_animation_per_item_hold()
		reboot_asset_in_hand()
	current_item_index = 0
	set_slot_interactive(null)
	if inventory:
		inventory.deselect_all()

func drop_current_item() -> void:
	if current_weapon:
		if current_weapon == default || !current_weapon || !current_asset_in_hand():return
		var t = current_asset_in_hand().global_transform
		aim = false
		if current_weapon:
			stop_animation("aim"+current_weapon.type_weapon)
		stop_animation("repos"+current_weapon.type)
		var weapon = current_weapon
		var asset = current_asset_in_hand()
		hand_target.remove_child(asset)
		get_tree().current_scene.add_child(asset)
		method(asset,"drop")
		asset.global_transform = t
		reboot_asset_in_hand()
		has(asset,"weapon",current_weapon)
		set_weapon(current_slot,default)
	else:
		if !current_asset_in_hand():return
		var t = current_asset_in_hand().global_transform
		var asset = current_asset_in_hand()
		hand_target.remove_child(asset)
		get_tree().current_scene.add_child(asset)
		method(asset,"drop")
		asset.global_transform = t
		reboot_asset_in_hand()

func add_current_weapon(weapon: Weapon) -> void:
	if is_interacted():return
	reboot_charger_action()
	if get_weapon(current_slot):
		if current_weapon:
			stop_animation("aim"+current_weapon.type_weapon)
		drop_current_item()
		set_weapon(current_slot,weapon)
		current_weapon = weapon
		reboot_asset_in_hand()
		load_weapon(weapon,true,false)

func drop_all_items() -> void:
	for slot in gun_attachment:
		if !(slot[1] in user):continue
		var holster = user[slot[1]]
		if holster.get_children():
			var weapon : Node3D = holster.get_child(0)
			var weapon_rs : Weapon
			if "weapon" in weapon:
				weapon_rs = weapon.weapon
			var t = weapon.global_transform
			holster.remove_child(holster.get_child(0))
			set_weapon(slot[0],default.duplicate())
			if "weapon" in weapon:
				has(weapon,"weapon",weapon_rs)
			get_tree().current_scene.add_child(weapon)
			method(weapon,"drop")
			weapon.global_transform = t
	drop_current_item()

func reboot_asset_in_hand() -> void:
	if !hand_target:return
	if hand_target.get_child_count() > 0:
		for child in hand_target.get_children():
			is_using = false
			child.queue_free()
			emit_signal("reboot_hand")
			set_description_panel("")

func set_description_panel(desc:String) -> void:
	if !inventory_scene:return
	if inventory_panel.has_method("set_description"):
		for method in inventory_panel.get_method_list():
			if method.name == "set_description":
				for arg in method.args:
					if arg.size() == 6:
						inventory_panel.set_description(desc)

func current_asset_in_hand() -> Node3D:
	if !hand_target:return
	if hand_target.get_child_count() > 0:
		return hand_target.get_child(0)
	return null

func add_item_in_hand(item:Asset) -> void:
	if !hand_target:return
	if current_asset_in_hand():
		reboot_asset_in_hand()
	var slot = item.scene.instantiate()
	emit_signal("add_hand")
	has(slot,"inventory",self)
	has(slot,"weapon",get_weapon(current_slot))
	hand_target.add_child(slot)
	if slot is RigidBody3D:
		slot.freeze = false
	slot.scale = global_scale(slot)
	current_asset_method("load")

func no_load_asset() -> bool:
	if !current_weapon:return true
	if !current_weapon.scene:
		return false
	return current_weapon.scene && !current_asset_in_hand()

func undo_shoot() -> void:
	shoot_no_auto = false

func shoot() -> void:
	if in_inventory || !current_weapon || !can_shoot:return
	if is_shooting || shoot_no_auto:return
	if no_load_asset():return
	if !current_weapon.is_melee() && !ammo_available_shoot():return
	if current_weapon.fully_automatic:
		shoot_no_auto = false
	shoot_no_auto = !current_weapon.fully_automatic
	reboot_charger_action()
	var slot = current_slot
	var shoot_no_aim : bool
	flag_charger = true
	is_shooting = true
	if !aim:
		aim_animation(current_weapon)
		aim = true
		shoot_no_aim = true
		await get_tree().create_timer(interval_asset_time).timeout
	if !is_shooting:
		return
	is_shooting = false
	if current_slot != slot:
		return
	method(current_cam,("add_trauma"),[current_weapon.trauma])
	current_asset_method("shoot")
	create_bullet(current_weapon)
	emit_signal("shoot_weapon",current_weapon)
	flag_show_inventory = false
	flag_shoot = false
	timer_shoot.start()
	shoot_animation(current_weapon)
	if !current_weapon.is_melee():
		rest_charger_bullet(current_weapon.shoot_bullet)
		update_charger_slots()
	if aim && shoot_no_aim:
		await get_tree().create_timer(interval_asset_time).timeout
		aim = false

func ammo_available_shoot() -> bool:
	var slots = get_divisibles(current_weapon.charger, current_weapon.shoot_bullet)
	for i in slots:
		if current_weapon.current_charger >= i:
			return true
	return false

func rest_charger_bullet(value:int) -> void:
	current_weapon.current_charger -= value

func create_bullet(weapon_data: Weapon) -> void:
	var bullet: Node3D = weapon_data.bullet.instantiate()
	has(bullet, "weapon", weapon_data)
	has(bullet, "scope", weapon_data.scope)
	has(bullet, "velocity", weapon_data.velocity)
	has(bullet, "damage", weapon_data.damage_amount)
	has(bullet, "user", user)
	bullet.top_level = true
	var transform_data := get_bullet_transform()
	bullet.global_transform = transform_data.transform
	has(bullet, "forward", transform_data.forward)
	bullet.scale = weapon_data.bullet_size
	get_tree().current_scene.add_child(bullet)

func get_bullet_transform() -> Dictionary:
	if current_asset_in_hand():
		for i in current_asset_in_hand().get_children():
			if i.name == "target" and i is Node3D:
				return {
					"transform": i.global_transform,
					"forward": -i.global_transform.basis.z
				}
	if "cam_target" in user:
		return {
			"transform": user.cam_target.global_transform,
			"forward": -user.cam_target.global_transform.basis.z
		}
	return {
		"transform": user.global_transform,
		"forward": -user.global_transform.basis.z
	}

func timeout_shoot() -> void:
	flag_show_inventory = true
	reboot_charger_action()
	if aim:
		aim_animation(current_weapon)


func reboot_charger_action() -> void:
	if !aim:
		repos_animation(current_weapon)
	reboot_animation_per_weapon("charger")
	timer_charger.stop()
	flag_shoot = true
	flag_charger = true
	flag_change_slot = true


func is_charging() -> bool:
	return !timer_charger.is_stopped()

func is_using_item() -> bool:
	return !timer_use_item.is_stopped()

func anim_select_weapon(weapon:Weapon) -> void:
	var slot = current_slot
	var inter : Interact = get_interact()
	if get_attachment(slot) in user && user[get_attachment(slot)].get_children():
		method(user[get_attachment(slot)].get_child(0),"select",[get_attachment(slot)])
	if weapon:
		anim_asset = true
		if inter:
			inter.can_interact_no_share = false
		await play(get_animation_select(weapon),0.2,weapon.duration_anim)
		if weapon:
			stop(get_animation_select(weapon),0.2)
		if inter:
			inter.can_interact_no_share = true
		anim_asset = false
	
func anim_deselect_weapon(weapon:Weapon) -> void:
	var slot = current_slot
	var inter : Interact = get_interact()
	if get_attachment(slot) in user && user[get_attachment(slot)].get_children():
		method(user[get_attachment(slot)].get_child(0),"deselect",[get_attachment(slot)])
	if weapon:
		anim_asset = true
		if inter:
			inter.can_interact_no_share = false
		await play(get_animation_deselect(weapon),0.2,weapon.duration_anim)
		if weapon:
			stop(get_animation_deselect(weapon),0.2)
		if inter:
			inter.can_interact_no_share = true
		anim_asset = false

func stop_load_weapon() -> void:
	var inter : Interact = get_interact()
	var weapon : Weapon = current_weapon
	if weapon:
		stop(get_animation_select(weapon),0.2)
		stop(get_animation_deselect(weapon),0.2)
	if inter:
		inter.can_interact_no_share = true


func load_weapon(weapon: Weapon = null,animation:bool=true,first_animation = true) -> void:
	if !weapon:return
	reboot_animation_per_weapon("repos")
	if aim:
		aim_action()
	reboot_repos = true
	current_weapon_load = weapon
	if animation:
		if first_animation:
			if current_weapon_load != weapon:return
			if current_weapon:
				await anim_deselect_weapon(current_weapon)
			if current_weapon_load != weapon:return
			current_weapon = weapon
			reboot_asset_in_hand()
		else:
			if weapon.scene:
				add_item_in_hand(weapon)
			else:
				reboot_asset_in_hand()
		await anim_select_weapon(weapon)
		if current_weapon_load != weapon:return
	if first_animation:
		if weapon.scene:
			add_item_in_hand(weapon)
		else:
			reboot_asset_in_hand()
	reboot_repos = false
	flag_shoot = true
	flag_charger = true
	timer_shoot.wait_time = weapon.delay_to_shoot
	repos_animation(weapon)
	set_weapon(current_slot,weapon)



func get_animation_select(asset:Asset) -> String:
	if !asset:return ""
	return asset.select_anim

func get_animation_deselect(asset:Asset) -> String:
	if !asset:return ""
	return asset.deselect_anim

func aim_process() -> void:
	if is_interacted() || user_front_asset() || current_weapon && get_animation_blend("repos"+current_weapon.type) > 0.8:
		undo_aim_fov()
		aim = false
		return
	if !enabled_aim || !can_aim:return
	if aim && current_weapon:
		user_has("sensibility_cam",apply_input_sensibility_weapon,[current_weapon.sensibility_input])
		if current_cam:
			current_cam.fov = lerp(current_cam.fov,current_weapon.aim_fov,0.1)
	undo_aim_fov()

func undo_aim():
	if !enabled_aim:return
	if no_load_asset():return
	if !is_charging():
		change_strafe_user(false)
		aim = false
		repos_animation(current_weapon)
		current_asset_method("aim",[false])

func undo_aim_fov() -> void:
	if current_cam:
		var current_fov = current_cam.get_meta(METAPATHFOV)
		current_cam.fov = lerp(current_cam.fov,current_fov,0.1)
	if "sensibility_cam" in user:
		user_has("sensibility_cam",apply_input_sensibility_weapon,[user.sensibility_cam])

func aim_action() -> void:
	if no_load_asset():return
	await get_tree().process_frame
	reboot_charger_action()
	current_asset_method("aim",[true])
	emit_signal("aim_weapon")
	aim_animation(current_weapon)

###########################################################################################
#ANIMATION
###################################################################################

func has_animation(animation:String) -> bool:
	var anim : String = PARAMETERSPATH+animation+BLENDAMOUNTPATH
	var node_tr : AnimationNodeBlendTree = animation_tree.tree_root
	return node_tr.has_node(animation)

func play(animation:String,interpolation:float=0.2,duration:float=0.0)-> void:
	var anim : String = PARAMETERSPATH+animation+BLENDAMOUNTPATH
	if !animation_tree:return
	if !has_animation(animation):return
	if animation_tree[anim] == 1.0:return
	tween_animation = create_tween()
	tween_animation.tween_method(
	func(value):
		animation_tree.set(anim, value),
	animation_tree[anim], 1.0, interpolation)
	tween_animation.tween_callback(tween_animation.kill)
	await tween_animation.finished
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	
func stop(animation:String,interpolation:float=0.2) -> void:
	if !animation_tree:return
	if !has_animation(animation):return
	var value_init : float = animation_tree[PARAMETERSPATH+animation+BLENDAMOUNTPATH]
	tween_animation = create_tween()
	tween_animation.tween_method(
	func(value):
		animation_tree.set(PARAMETERSPATH + animation + BLENDAMOUNTPATH, value),
	value_init, 0.0, interpolation)
	tween_animation.tween_callback(tween_animation.kill)

func reboot_animation_per_weapon(path:String) -> void:
	var index : int = -1
	for weapon in slots:
		index += 1
		if weapon is Weapon:
			await stop_animation(path+get_weapon(index).type_weapon,0.0)

func reboot_animation_per_item_use() -> void:
	if !current_item:return
	stop_animation(current_item.use_anim)

func reboot_animation_per_item_hold() -> void:
	if !current_item:return
	stop_animation(current_item.hold_anim)

func apply_input_sensibility_weapon(sensibility: Vector2) -> void:
	if "current_sensibility_cam" in user:
		user.current_sensibility_cam = lerp(user.current_sensibility_cam,sensibility,global_delta*3.0)

func repos_animation(weapon:Weapon) -> void:
	reboot_animation_per_weapon("repos")
	current_asset_method("repos")
	if current_weapon:
		emit_signal("repos_weapon",weapon)
		set_animation(6,"repos"+weapon.type_weapon)
		user_has("state_hands",repos_state)

func charger_animation(weapon: Weapon) -> void:
	reboot_animation_per_weapon("charger")
	set_animation(8,"charger"+weapon.type_weapon)
	user_has("state_hands",charging_state)

func shoot_animation(weapon: Weapon) -> void:
	reboot_animation_per_weapon("shoot")
	set_animation(11,"shoot"+weapon.type_weapon)
	user_has("state_hands",shoot_state)

func aim_animation(weapon:Weapon) -> void:
	user_has("state_hands",aim_state)
	set_animation(7,"aim"+weapon.type_weapon)
	reboot_animation_per_weapon("aim")

func set_animation(index:int,value:String) -> void:
	if !interpolation:return
	interpolation.set_animation(index,value)

func get_attachment(slot:int) -> String:
	for i in gun_attachment:
		if i[0] == slot:
			return i[1]
	return ""

func attachment_gun_in_body(weapon: Weapon,slot_num:int) -> void:
	var anchor = attachment_property_slot(slot_num)
	if !anchor:
		return
	if !weapon || !weapon.scene:return
	var weapon_instance = weapon.scene.instantiate()
	await get_tree().process_frame
	if "weapon" in weapon_instance:
		weapon_instance.weapon = weapon
	for child in anchor.get_children():
		child.queue_free()
	anchor.add_child(weapon_instance)
	weapon_instance.scale = global_scale(weapon_instance)

func show_all_attachment() -> void:
	for slot_ in gun_attachment:
		if slot_[1] in user:
			if user[slot_[1]] is Node3D && is_valid_slot(slot_[0]):
				var weapon = slots[slot_[0]]
				if !weapon.scene:continue
				if weapon.type.to_lower() == slot_[2].to_lower():
					if user[slot_[1]].get_children():continue
					var inst = weapon.scene.instantiate()
					if "weapon" in inst:
						inst.weapon = weapon
					user[slot_[1]].add_child(inst)
					inst.scale = global_scale(inst)


func is_valid_slot(index: int) -> bool:
	return index >= 0 && index < slots.size()

func is_valid_slot_inventory(index: int) -> bool:
	return index >= 0 && index < inventory_slots.size()

func delete_all_attachment() -> void:
	for slot_ in gun_attachment:
		if slot_[1] in user:
			if user[slot_[1]] is Node3D && is_valid_slot(slot_[0]):
				var weapon = slots[slot_[0]]
				if weapon && !weapon.scene:continue
				if weapon && weapon.type.to_lower() == slot_[2].to_lower():
					if !user[slot_[1]].get_children():continue
					user[slot_[1]].get_child(0).queue_free()

func attachment_property_slot(slot:int) -> Variant:
	for slot_ in gun_attachment:
		if slot == slot_[0] && get_weapon(slot).type.to_lower() == slot_[2].to_lower():
			if slot_[1] in user:
				return user[slot_[1]]
	return null

func attachment_visible() -> void:
	for slot_ in gun_attachment:
		if current_weapon && current_slot == slot_[0] && current_weapon.type.to_lower() == slot_[2].to_lower():
			if slot_[1] in user:
				if user[slot_[1]] is Node3D:
					if user[slot_[1]].get_children():
						user[slot_[1]].get_child(0).queue_free()
				break


func global_scale(node:Node3D) -> Vector3:
	if !node || !node.is_inside_tree():
		return Vector3.ONE
	var scale = node.global_transform.basis.get_scale()
	return Vector3(
		1.0 / scale.x,
		1.0 / scale.y,
		1.0 / scale.z
	)

func no_actions() -> bool:
	if user_in_alignment():
		return user_in_alignment()
	if MissionManager.current_mission:
		return MissionManager.current_mission.state == MissionManager.current_mission.MissionState.FAILED && MissionManager.current_mission.failure_screen
	return false

func stop_animation(path: String,interpolation:float = 0.2) -> void:
	if animation_tree && has_animation(path):
		var tween := create_tween()
		tween.tween_property(animation_tree,PARAMETERSPATH+path+BLENDAMOUNTPATH,0.0,interpolation)
		await tween.finished

func user_in_alignment() -> bool:
	return user.has_meta("alignment") && user.get_meta("alignment")

###########################################################################################
#GETTER AND SETTER
###################################################################################

func get_current_weapon() -> Weapon:
	if get_weapon(current_slot):
		return get_weapon(current_slot)
	return null

func get_animation_blend(animation: String) -> float:
	if animation_tree:
		var path = "parameters/" + animation + "/blend_amount"
		var node_tr : AnimationNodeBlendTree = animation_tree.tree_root
		if node_tr.has_node(animation):
			return animation_tree.get(path)
	return 0.0

func get_weapon(slot:int) -> Weapon:
	if slots[slot] is Weapon:
		return slots[slot]
	return null

func set_weapon(slot:int,weapon:Weapon) -> void:
	slots[slot] = weapon

func get_charger(slot:int) -> float:
	return slots[slot].current_charger

func set_charger(slot:int,charger:float) -> void:
	slots[slot].current_charger = charger

func current_asset_method(method:String,args := []) -> void:
	var current = current_asset_in_hand()
	if current && current.has_method(method):
		if get_method_node_args(current,method).size() > args.size():
			return
		if args && !get_method_node_args(current,method):
			args = []
		current.callv(method,args)

func user_method(method:String,args := []) -> void:
	if user && user.has_method(method):
		if get_method_node_args(user,method).size() > args.size():
			return
		if args && !get_method_node_args(user,method):
			args = []
		user.callv(method,args)

func repos_state() -> void:
	user.state_hands = Humanoid.REPOS

func use_item_state() -> void:
	user.state_hands = Humanoid.USEITEM

func shoot_state() -> void:
	user.state_hands = Humanoid.SHOOT

func charging_state() -> void:
	user.state_hands = Humanoid.CHARGING

func aim_state() -> void:
	user.state_hands = Humanoid.AIM

func hold_item_state() -> void:
	user.state_hands = Humanoid.HOLDITEM
