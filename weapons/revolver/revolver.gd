extends WeaponItem




var current_charger

var inventory : Inventory

func _ready() -> void:
	save()
	set_propertys()

func shoot() -> void:
	pass


func bullet_at_time(ammo) -> void:
	print(str(ammo))

func last_loaded_bullet() -> void:
	inventory.user.play("test",1,0.1)

func stop() -> void:
	if inventory:
		inventory.user.stop("test",1)

func repos() -> void:
	pass

func drop() -> void:
	set_propertys()
