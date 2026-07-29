@tool
class_name HitokotoPanel extends Control

@onready var euler = $ScrollContainer/VBoxContainer/SectionRandom/HBoxContainer/Euler
@onready var grades = $ScrollContainer/VBoxContainer/SectionRandom/HBoxContainer/grades
@onready var hour = $ScrollContainer/VBoxContainer/Time/h/hour
@onready var minute = $ScrollContainer/VBoxContainer/Time/h/minute
@onready var lenguage_option = $ScrollContainer/VBoxContainer/Lenguage/h/lenguageOption

var undo_redo : EditorUndoRedoManager

func _ready() -> void:
	call_deferred("load_propertys")

func load_propertys() -> void:
	var settings := EditorInterface.get_editor_settings()
	var grade_random_rotation = settings.get_setting("Hitokoto/Mapping/Grades_Random_Rotation")
	var language = settings.get_setting("Hitokoto/Accessibility/Lenguage")
	var hours = settings.get_setting("Hitokoto/Time/Hours")
	var minutes = settings.get_setting("Hitokoto/Time/Minutes")
	if grade_random_rotation != null:
		grades.value = grade_random_rotation
	if language != null:
		lenguage_option.selected = language
	if hours != null:
		hour.value = hours
	if minutes != null:
		minute.value = minutes

func _on_action_pressed() -> void:
	var euler_selection = euler.selected
	var selection := EditorInterface.get_selection()
	var value = grades.value
	undo_redo.create_action("Rotate")
	for node in selection.get_selected_nodes():
		if node is Node3D:
			var random_value = randf_range(0,deg_to_rad(value))
			var rot = node.rotation
			match euler_selection:
				0:rot.y = fposmod(node.rotation.y + random_value, PI*2)
				1:rot.x = fposmod(node.rotation.y + random_value, PI*2)
				2:rot.z = fposmod(node.rotation.y + random_value, PI*2)
			undo_redo.add_do_property(node,"rotation",rot)
			undo_redo.add_undo_property(node,"rotation",node.rotation)
	undo_redo.commit_action()

func update_time():
	var current_root := EditorInterface.get_edited_scene_root()
	if !current_root:return
	var sun : Marker3D = current_root.get_tree().get_first_node_in_group("sun")
	var minutes :float = minute.value
	var hours :float = hour.value
	if !sun:return
	undo_redo.create_action("Change Time"+" : "+GameTime.get_time_string())
	GameTime.set_time(hours,minutes)
	var rot = sun.rotation_degrees
	undo_redo.add_do_property(sun,"rotation_degrees",rot)
	undo_redo.add_undo_property(sun,"rotation_degrees",sun.rotation_degrees)
	undo_redo.commit_action()
	EditorInterface.get_editor_settings().set_setting("Hitokoto/Time/Hours", hour.value)
	EditorInterface.get_editor_settings().set_setting("Hitokoto/Time/Minutes",minute.value)

func _on_hour_value_changed(value:float):
	update_time()

func _on_minute_value_changed(value:float):
	update_time()

func _on_lenguage_option_item_selected(index:int) -> void:
	undo_redo.create_action("Change Lenguage")
	EditorInterface.get_editor_settings().set_setting("Hitokoto/Accessibility/Lenguage",index)
	GameSettings.set_lenguage(index)
	undo_redo.commit_action()

func _on_update_settings_pressed():
	undo_redo.create_action("Save Data Settings")
	GameSettings.save()
	undo_redo.commit_action()

func _on_reboot_settings_pressed():
	undo_redo.create_action("Reboot Data Settings")
	GameSettings.reboot()
	undo_redo.commit_action()

func _on_reset_time_pressed() -> void:
	var current_root := EditorInterface.get_edited_scene_root()
	if !current_root:return
	var sun : Marker3D = current_root.get_tree().get_first_node_in_group("sun")
	if !sun:return
	undo_redo.create_action("Reset Time")
	minute.value = 0
	hour.value = 0
	GameTime.set_time(0,0)
	undo_redo.commit_action()

func _on_grades_value_changed(value: float):
	EditorInterface.get_editor_settings().set_setting("Hitokoto/Mapping/Grades_Random_Rotation",value)
