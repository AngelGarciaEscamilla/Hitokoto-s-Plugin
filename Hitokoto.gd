@tool
extends Node

var new_scene_match : String
var can_save : bool = true
var global_delta : float
var current_game : int = 1
var is_load : bool
var values : Dictionary = {}
var load : LoadScene
var data_path = SaveGame.new().save_path


signal saved
signal loaded
signal save_game(index:int)
signal reboot


func get_save_game_path() -> String:
	var char_count : int = 0
	for char in data_path:
		if char == ".":
			break
		char_count += 1
	return data_path.insert(char_count,"_"+str(current_game))

func _process(delta : float) -> void:
	global_delta = delta
	if Engine.is_editor_hint():return


	

####################################################################################
#LOAD
####################################################################################

func change_scene_load(new_scene: String,load_screen:String) -> void:
	new_scene_match = new_scene
	await get_tree().process_frame
	if FileAccess.file_exists(load_screen):
		get_tree().change_scene_to_file(load_screen)
	await get_tree().process_frame
	load = LoadScene.new()
	get_tree().current_scene.add_child(load)

func eliminate_dir_path(path):
	DirAccess.remove_absolute(path)

####################################################################################
#TOOLS
###################################################################################

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

func method(node:Node,method:String,args := []) -> Variant:
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() > args.size():
			return
		if args && !get_method_node_args(node,method):
			args = []
		return node.callv(method,args)
	return null

func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []

func has(node:Node,property:String,callback:Callable,args=[]) -> void:
	if !node:return
	if property in node:
		callback.callv(args)

func find_script_path(script_name:String) -> String:
	var dir := DirAccess.open("res://")
	if dir == null:
		return ""
	return _search_script_path(dir, script_name)

func _search_script_path(dir:DirAccess, script_name:String) -> String:
	dir.list_dir_begin()
	var file := dir.get_next()

	while file != "":
		var full_path := dir.get_current_dir().path_join(file)

		if dir.current_is_dir():
			if file != "." and file != "..":
				var sub := DirAccess.open(full_path)
				var result := _search_script_path(sub, script_name)
				if result != "":
					return result
		else:
			if file == script_name + ".gd":
				return full_path

		file = dir.get_next()

	dir.list_dir_end()
	return ""

static func round_number(x) -> float:
	var xround = round(x * 1000) / 1000.0
	return xround

static func verified_file_exist(data) -> bool:
	if !data:return false
	else:return true

######################################################################################################
#DEPENDENCE
########################################################################

func set_var(key:String,value : Variant) -> void:
	values[key] = value

func get_var(key:String) -> Variant:
	return values.get(key)

func has_var(key:String) -> bool:
	return values.has(key)

func clear_values():
	values.clear()

#####################################################################################################
#find_nodes
############################################################################

func get_player_3d() -> Node3D:
	if !get_tree().current_scene:return 
	for child in get_tree().current_scene.get_children():
		if ((inputs(child)) && child is PhysicsBody3D && child is Node3D):
			return child
		if !child.get_children():continue
		for child_two in child.get_children():
			if ((inputs(child)) && child is PhysicsBody3D && child is Node3D):
				return child
	return null

func get_players_3d() -> Array[Node3D]:
	if !get_tree().current_scene:return []
	var players : Array[Node3D] = []
	for child in get_tree().current_scene.get_children():
		if ((inputs(child)) && child is PhysicsBody3D && child is Node3D):
			players.append(child)
		if !child.get_children():continue
		for child_two in child.get_children():
			if ((inputs(child)) && child is PhysicsBody3D && child is Node3D):
				players.append(child)
	return players

func get_player_2d() -> Node2D:
	if !get_tree().current_scene:return 
	for child in get_tree().current_scene.get_children():
		if ((inputs(child)) && child is PhysicsBody2D && child is Node2D):
			return child
		if !child.get_children():continue
		for child_two in child.get_children():
			if ((inputs(child)) && child is PhysicsBody2D && child is Node2D):
				return child
	return null

func get_players_2d() -> Array[Node2D]:
	if !get_tree().current_scene:return []
	var players : Array[Node2D] = []
	for child in get_tree().current_scene.get_children():
		if ((inputs(child)) && child is PhysicsBody2D && child is Node2D):
			players.append(child)
		if !child.get_children():continue
		for child_two in child.get_children():
			if ((inputs(child)) && child is PhysicsBody2D && child is Node2D):
				players.append(child)
	return players

func get_navigation_mesh() -> NavigationRegion3D:
	if !get_tree().current_scene:return 
	for child in get_tree().current_scene.get_children():
		if child is NavigationRegion3D:
			return child
		for child_two in child.get_children():
			if child is NavigationRegion3D:
				return child
	return null

func inputs(node:Node) -> bool:
	var script = node.get_script()
	if !script:
		return false
	var path = script.resource_path
	if path.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if !file:
		return false
	var code := file.get_as_text()
	file.close()
	return (
		code.find(".is_action_just_pressed") != -1
		|| code.find(".is_action_just_released") != -1
		|| code.find(".is_action_pressed") != -1
	)

########################################################################################
#RANDOMIZER
######################################################################################################

static func random_letter() -> String:
	var alphabet = "abcdefghijklmnopqrstuvwxyz"
	var random_letter : int = randf_range(-26,26)
	return alphabet[random_letter]

static func random_key_in_dic(dic:Dictionary):
	var keys = dic.keys()
	if !keys:
		return null
	return keys[randi() % keys.size()]

static func get_random_element(array: Array) -> Variant:
	if array.size() == 1:
		return array[0]
	if array.is_empty():
		return null
	return array[randi() % array.size()-1]

###############################################################################################################
#SAVE
###############################################################################################################

func save(node:Node) -> void:
	node.add_to_group("save")

func remove_save(node:Node) -> void:
	node.remove_from_group("save")

func save_data(index:int=-1) -> void:
	print_stack()
	if index < 0:
		index = current_game
	emit_signal("save_game",index)

func reboot_data(index:int=-1) -> void:
	if index < 0:
		index = current_game
	var char_count : int = 0
	for char in data_path:
		if char == ".":
			break
		char_count += 1
	eliminate_dir_path(data_path.insert(char_count,"_"+str(index)))
	emit_signal("reboot")


func game_exist(index:int) -> SaveGame:
	var char_count := 0
	for char in data_path:
		if char == ".":
			break
		char_count += 1

	var path := data_path.insert(char_count, "_" + str(index))

	if !FileAccess.file_exists(path):
		return null

	return ResourceLoader.load(path)