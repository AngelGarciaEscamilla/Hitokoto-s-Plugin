
class_name SettingsInNodes extends Node

@export var enabled : bool = true
@export var nodes : Array[PropertyNode]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameSettings.load_settings.connect(update_nodes)
	update_nodes()

func get_node_by_name(path: NodePath) -> Node:
	if path.is_empty():
		return get_parent()

	var scene := get_tree().current_scene
	if !scene:
		return null
	return get_node_or_null(path)

func update_nodes() -> void:
	if !enabled:return
	for node in nodes:
		if !node:continue
		var node_valid = get_node_by_name(node.node_path)
		if node_valid:
			if node.property in node_valid:
				if GameSettings.has_setting(node.path_setting):
					node_valid[node.property] = GameSettings.get_setting(node.path_setting)
				else:
					push_error("not found a setting with path " + node.path_setting)
			else:
				push_error(str(node_valid)+" hasn´t property " + node.property)
