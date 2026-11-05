@tool
class_name Timeline extends Resource


@export var finished : bool
@export var one_shot : bool
@export var current_index : int:
	set(value):
		current_index = value
		call_deferred("set_finished")

func set_finished() -> void:
	if current_index > timeline.size()-1:
		finished = true
	else:
		if Engine.is_editor_hint():
			finished = false
@export var timeline : Array[DialogueData] = []


func has_next_dialogue() -> bool:
	return current_index <= timeline.size()-1

func current_dialogue() -> DialogueData:
	if !has_next_dialogue():
		return
	if condition_alternative(timeline[current_index]):
		timeline[current_index] = timeline[current_index].dialogue_alternative
		return current_dialogue()
	return timeline[current_index]

func next_dialogue() -> void:
	if !has_next_dialogue():return
	current_index += 1
	timeline[current_index]

func condition_alternative(dialogue:DialogueData) -> bool:
	if dialogue.condition_key.is_empty():
		return false
	return Hitokoto.get_var(dialogue.condition_key) == dialogue.condition_value

