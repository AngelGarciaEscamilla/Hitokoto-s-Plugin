@tool
class_name DialogueManager extends Component

var subtitles : Node
@onready var voice : Voice = Voice.new()
@export var interpolation_anim : float = 0.2
@export var distance_listener : float = 5
@export var limit_distance_dialogue : bool = true

@export_category(&"Dialogues")
@export var timeline : Timeline
var current_dialogue_reproduce : DialogueData
@export var disabled : bool:
	set(value):
		disabled = value
		if value:
			process_mode = Node.PROCESS_MODE_DISABLED
		else:
			process_mode = Node.PROCESS_MODE_INHERIT

var is_talking : bool 
var in_conversation : bool
var process_function : bool
var pause : bool
var conversation_index : int
var current_text_dialogue : String

var interpolation : Tween
var mixer : AnimationMixer
var timeline_owner : DialogueManager
var current : Node


signal finished_dialogue(current:DialogueData)
signal init_dialogue(current:DialogueData)

const PARAMETERSPATH : String = "parameters/"
const BLENDAMOUNTPATH : String = "/blend_amount"

func _ready() -> void:
	set_user()
	mixer = find_animation_node(user)

func get_current_user() -> Node:
	if timeline.current_dialogue().user_path.is_empty():
		return get_parent()
	return get_tree().current_scene.get_child(0).get_node_or_null(timeline.current_dialogue().user_path)

	
func find_dialogue(parent:Node) -> DialogueManager:
	var user_dialogue
	for child in parent.get_children():
		if child is DialogueManager:
			user_dialogue = child
	return user_dialogue

func start_conversation() -> void:
	if "state" in user:
		if user.state == Humanoid.FALLEN:
			return
	if !timeline || process_function:return
	process_function = true
	if !timeline.has_next_dialogue() || timeline.finished || !get_current_user():
		in_conversation = false
		process_function = false
		reset_ui()
		return
	var dialogue_user = find_dialogue(get_current_user())
	var current_dialogue = timeline.current_dialogue()
	if dialogue_user:
		if timeline_owner && timeline_owner != self:
			timeline_owner.pause_conversation()
		if pause:
			process_function = false
			pause = false
			return
		in_conversation = true
		dialogue_user.timeline_owner = self
		await dialogue_user.reproduce_dialogue(current_dialogue)
		if timeline.one_shot && timeline.current_dialogue().chained:
			timeline.finished = timeline.current_dialogue().finish_timeline
			process_function = false
			timeline.current_index += 1
			start_conversation()
			return
		if !timeline.one_shot:
			timeline.finished = timeline.current_dialogue().finish_timeline
			timeline.current_index += 1
			process_function = false
			start_conversation()
			return
		timeline.finished = timeline.current_dialogue().finish_timeline
		timeline.current_index += 1
		process_function = false

func _process(delta:float) -> void:
	if distance_listener > 0:
		if limit_distance_dialogue && !on_near_from_target(distance_listener):
			pause_conversation()


func on_near_from_target(distance:float) -> bool:
	if !valid_user("Node3D"):return false
	if !current:
		current = Hitokoto.get_player_3d()
	if !current || !user: return false
	var result = user.global_position.distance_squared_to(current.global_position) <= distance * distance
	return result

func stop_conversation() -> void:
	in_conversation = false
	stop_dialogue()

func stop() -> void:
	stop_dialogue()
	stop_conversation()

func condition_alternative(dialogue:DialogueData) -> bool:
	if dialogue.condition_key.is_empty():
		return false
	return Hitokoto.get_var(dialogue.condition_key) == dialogue.condition_value

func reproduce_dialogue(dialogue: DialogueData) -> void:
	if !dialogue || disabled:
		return
	stop_dialogue()
	if current_dialogue_reproduce:
		emit_signal("finished_dialogue",current_dialogue_reproduce)
	is_talking = true
	if dialogue.condition_key.is_empty():
		set_dialogue_UI(dialogue)
	else:
		if condition_alternative(dialogue):
			reproduce_dialogue(dialogue.dialogue_alternative)
			return
		else:
			set_dialogue_UI(dialogue)
	emit_signal("init_dialogue",dialogue)
	method(user,"talking",[dialogue])
	interpolate_anim_value(dialogue.anim, 0.0, 1.0, interpolation_anim)
	lipsync_anim(dialogue)
	current_dialogue_reproduce = dialogue
	await get_tree().create_timer(dialogue.duration).timeout
	if !current_dialogue_reproduce:return
	if !is_talking:
		await interpolate_anim_value(dialogue.anim, 1.0, 0.0, interpolation_anim)
		if dialogue.auto_hide:
			await reset_ui()
		emit_signal("finished_dialogue",dialogue)
		return
	if dialogue == current_dialogue_reproduce:
		await interpolate_anim_value(dialogue.anim, 1.0, 0.0, interpolation_anim)
	if dialogue.auto_hide:
		await reset_ui()
	emit_signal("finished_dialogue",dialogue)

func lipsync_anim(dialogue:DialogueData) -> void:
	var phonemes_json = FileAccess.open(dialogue.phonemes,FileAccess.READ)
	if phonemes_json:
		var phonemes = phonemes_json.get_as_text()
		var data = JSON.parse_string(phonemes)
		if phonemes:
			for phoneme in data["phonemes"]:
				interpolate_anim_value(phoneme["value"], 0.0, 1.0, interpolation_anim)
				var duration = phoneme["end"] - phoneme["start"]
				await get_tree().create_timer(duration).timeout
				interpolate_anim_value(phoneme["value"], 1.0, 0.0, interpolation_anim)
				if is_talking:
					break

func create_ui(dialogue:DialogueData) -> void:
	voice = Voice.new()
	subtitles = get_tree().get_first_node_in_group("subtitles")
	if !subtitles:return
	add_child(voice)
	if !dialogue.subtitles.current_lenguage_text().is_empty() && GameSettings.is_subtitles():
		for property_name in dialogue.propertys.keys():
			if property_name is String || property_name is StringName:
				if property_name in subtitles:
					subtitles.set(property_name,dialogue.propertys[property_name])
		method(subtitles,"enter")

func reset_ui() -> void:
	if subtitles_exist():
		subtitles.text = subtitles.text.replace(current_text_dialogue,"")
		if subtitles.text.is_empty():
			await method(subtitles,"exit")

	if voice && voice.is_inside_tree():
		voice.queue_free()
	is_talking = false
	if get_parent() == get_tree().current_scene:
		queue_free()

func subtitles_exist() -> bool:
	return subtitles && subtitles.is_inside_tree()

func interpolate_anim_value(path: String, start_value: float, end_value: float, duration: float) -> void:
	if !mixer:return
	if mixer is AnimationTree:
		var node_tr : AnimationNodeBlendTree = mixer.tree_root
		var anim_path : String = PARAMETERSPATH+path+BLENDAMOUNTPATH
		if !node_tr.has_node(path):
			return
		interpolation = create_tween()
		mixer[anim_path] = start_value
		interpolation.tween_property(mixer , anim_path, end_value, duration)
		await interpolation.finished
	if mixer is AnimationPlayer:
		if start_value == 1.0 && end_value == 0.0:
			mixer.stop()
		else:
			mixer.play(path)

func find_animation_node(node: Node) -> AnimationMixer:
	if node is AnimationMixer:
		return node
	for child in node.get_children():
		var result = find_animation_node(child)
		if result:
			return result
	return null

func pause_conversation() -> void:
	reset_ui()
	if in_conversation:
		pause = true

func stop_dialogue() -> void:
	if "animation_tree" in user && current_dialogue_reproduce:
		interpolation.kill()
		var tween := create_tween()
		tween.tween_property(
			user.animation_tree,
			PARAMETERSPATH + current_dialogue_reproduce.anim + BLENDAMOUNTPATH,
			0.0,
			0.2
		)
		current_dialogue_reproduce = null
	if voice:
		voice.stop()
	await reset_ui()

func update_global_values(dialogue: DialogueData) -> void:
	if dialogue:
		if !dialogue.dependence_key.is_empty():
			Hitokoto.set_var(dialogue.dependence_key,dialogue.add_dependence)

func set_dialogue_UI(dialogue : DialogueData) -> void:
	create_ui(dialogue)
	if GameSettings.is_subtitles() && !dialogue.subtitles.current_lenguage_text().is_empty():
		var tab : String = "\n"
		if subtitles.text.is_empty():
			tab = ""
		current_text_dialogue = tab+dialogue.subtitles.current_lenguage_text()
		subtitles.text += current_text_dialogue
	if voice:
		voice.stream = dialogue.audio
		voice.play()
