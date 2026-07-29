
class_name SaveManager extends Component

#if you add a node by script set his owner to a parent so that save tha node , all node without will not be saved

@export var load_screen : PackedScene
@export var auto_load : bool = true

var save : SaveGame = SaveGame.new()

func _ready() -> void:
	Hitokoto.save_game.connect(save_game_data)
	if auto_load:
		load_game()
	call_deferred("connect_node_added")

func connect_node_added():
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	var parent := node.get_parent()

	while parent:
		if parent.is_in_group("save"):
			if node.owner == null:
				node.owner = parent.owner
			break
		parent = parent.get_parent()

func save_game_data(index:int) -> void:
	Hitokoto.emit_signal("saved")
	if !Hitokoto.can_save:return
	if !Hitokoto.verified_file_exist(save):
		save = SaveGame.new()
		save.save_game()
	save.index = index
	save.values = Hitokoto.values
	save.missions = MissionManager.missions
	save.calendar = GameTime.calendar
	save.current_weather = GameTime.current_weather
	save.current_scene = get_tree().current_scene.scene_file_path
	save_nodes()
	save.save_game()

func load_game() -> void:
	if !ResourceLoader.exists(Hitokoto.get_save_game_path()):return
	save = ResourceLoader.load(Hitokoto.get_save_game_path())
	if !Hitokoto.verified_file_exist(save):return
	if !save.save_scenes.has(get_tree().current_scene.scene_file_path):
		return
	change_scene()
	MissionManager.missions = save.missions
	Hitokoto.values = save.values
	GameTime.calendar = save.calendar
	GameTime.current_weather = save.current_weather
	call_deferred("load_nodes")

func change_scene() -> void:
	if !Hitokoto.is_load:
		Hitokoto.is_load = true
		if load_screen:
			Hitokoto.change_scene_load(save.current_scene,load_screen.resource_path)
		else:
			await get_tree().process_frame
			get_tree().change_scene_to_file(save.current_scene)

func save_nodes() -> void:
	var nodes = get_tree().get_nodes_in_group("save")
	save.save_scenes[get_tree().current_scene.scene_file_path] = []
	for node in nodes:
		if !node.is_inside_tree():
			continue
		set_owner_recursive(node, node)
		var packed := PackedScene.new()
		node.set_meta("parent",node.get_parent().get_path())
		var err := packed.pack(node)
		if err == OK:
			save.save_scenes[get_tree().current_scene.scene_file_path].append(packed)

func set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child.owner != null:
			child.owner = owner
		set_owner_recursive(child, owner)

func load_nodes() -> void:
	var nodes_list = get_tree().get_nodes_in_group("save")
	for node in nodes_list:
		node.queue_free()
	for i in save.save_scenes[get_tree().current_scene.scene_file_path]:
		var node_load = i.instantiate()
		if node_load.has_meta("parent"):
			get_node(node_load.get_meta("parent")).add_child(node_load)
	Hitokoto.emit_signal("loaded")

func get_player_saved_3d() -> PhysicsBody3D:
	for key in save.save_scenes:
		for node in save.save_scenes[key]:
			if inputs(node) && node is PhysicsBody3D:
				return node
	return null

func get_player_saved_2d() -> PhysicsBody2D:
	for key in save.save_scenes:
		for node in save.save_scenes[key]:
			if inputs(node) && node is PhysicsBody2D:
				return node
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
