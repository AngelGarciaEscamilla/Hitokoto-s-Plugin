extends EditorScript

func _run():
    ProjectSettings.set_setting("display/window/mode", "canvas_item")
    ProjectSettings.save()
