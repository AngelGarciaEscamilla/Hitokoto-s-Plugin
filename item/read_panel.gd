class_name ReadPanel extends Control

@onready var title : Label = $Panel/title
@onready var autor : Label = $Panel/autor

@onready var content : Text = $Panel/ScrollContainer/content

func set_title(title_:StringName) -> void:
	title.text = title_

func set_autor(autor_:StringName) -> void:
	autor.text = "By "+autor_

func set_content(content_:TranslatorText) -> void:
	content.translator = content_
