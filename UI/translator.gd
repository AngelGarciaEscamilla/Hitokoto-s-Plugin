@tool
extends Resource

class_name TranslatorText

@export_multiline var textEN : String = "text in english"
@export_multiline var textES : String = "Texto en Español"
@export_multiline var textPT : String = "Texto em português"
@export_multiline var textFR : String = "Texte en français"
@export_multiline var textJA : String = "日本語テキスト"
@export_multiline var textAR : String = "النص العربي"
@export_multiline var textRU : String = "текст на русском языке"

var lenguageText = {}

func current_lenguage_text() -> String:
	
	lenguageText = {
		0.0: textEN,
		1.0: textES,
		2.0: textPT,
		3.0: textFR,
		4.0: textJA,
		5.0: textAR,
		6.0: textRU,
	}
	return lenguageText.get(GameSettings.get_current_lenguage(), textEN)

func current_lenguage_text_name() -> StringName:
	return StringName(current_lenguage_text())
