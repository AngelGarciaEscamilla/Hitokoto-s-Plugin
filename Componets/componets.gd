class_name Component extends Node

var user : Node:
	set(value):
		user = value

func set_user() -> void:
	user = get_parent()
	if name.contains("Node@"):
		name = get_script().get_global_name()

func has_state() -> bool:
	return ("state" in user)

func valid_user(type:String) -> bool:
	return user.is_class(type)

func has(node:Node,property:String,value:Variant) -> void:
	if !node:return
	if property in node:
		node[property] = value

func method(node:Node,method:String,args := []) -> void:
	if node && node.has_method(method):
		if get_method_node_args(node,method).size() > args.size():
			return
		if args && !get_method_node_args(node,method):
			args = []
		await node.callv(method,args)

func get_method_node_args(node:Node,name:String) -> Array:
	if !node:return []
	for i in node.get_method_list():
		if i.name == name:
			return i.args
	return []

func user_has(property:String,callback:Callable,args=[]) -> void:
	if !user:return
	if property in user:
		callback.callv(args)
