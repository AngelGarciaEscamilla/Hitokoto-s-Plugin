class_name ScreenCallBack extends UI

@export var screen_scene : PackedScene

func play(propertys:Dictionary={}) -> void:
	stop()
	var screen = screen_scene.instantiate()
	for prop in propertys.keys():
		if !(prop is String):return
		if prop in screen:
			if typeof(screen[prop]) == typeof(propertys[prop]):
				screen[prop] = propertys[prop]
			else:
				push_error("it was about assigning a variable with a different value :"+str(self))
		else:
			push_error("the key "+prop+" was not found on the scene screen")
	add_child(screen)
	if "duration" in screen && (screen.duration is float || screen.duration is int):
		if screen.duration > 0:
			await get_tree().create_timer(screen.duration).timeout
	await method(screen,"exit")
	if screen.is_inside_tree():
		screen.queue_free()

func stop() -> void:
	var screen = screen_scene.instantiate()
	if screen.is_inside_tree():
		screen.queue_free()

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
