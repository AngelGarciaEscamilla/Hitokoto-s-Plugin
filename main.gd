@tool
extends EditorPlugin

const PANELPLUGIN := preload("res://addons/Hitokoto´s Plugin/hitokotoPanel.tscn")
var PANEL := PANELPLUGIN.instantiate()

const PLUGIN := "res://addons/Hitokoto´s Plugin/Hitokoto.gd"
const AUDIOMANAGER = "res://addons/Hitokoto´s Plugin/audioManager.gd"
const MISSIONMANAGER = "res://addons/Hitokoto´s Plugin/mission/missionManager.gd"
const GAMESETTINGS := "res://addons/Hitokoto´s Plugin/game_settings.gd"
const GAMETIME := "res://addons/Hitokoto´s Plugin/game_time.gd"

const PLUGIN_NAME := "Hitokoto"
const GAMESETTINGS_NAME := "GameSettings"
const GAMETIME_NAME := "GameTime"
const AUDIOMANAGER_NAME = "AudioManager"
const MISSIONMANAGER_NAME = "MissionManager"

func _enter_tree() -> void:
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BL,PANEL)
	PANEL.undo_redo = get_undo_redo()

func _enable_plugin() -> void:
	add_autoload_singleton(PLUGIN_NAME,PLUGIN)
	add_autoload_singleton(GAMESETTINGS_NAME,GAMESETTINGS)
	add_autoload_singleton(AUDIOMANAGER_NAME,AUDIOMANAGER)
	add_autoload_singleton(MISSIONMANAGER_NAME,MISSIONMANAGER)
	add_autoload_singleton(GAMETIME_NAME,GAMETIME)

func _disable_plugin() -> void:
	remove_autoload_singleton(PLUGIN_NAME)
	remove_autoload_singleton(GAMESETTINGS_NAME)
	remove_autoload_singleton(GAMETIME_NAME)
	remove_autoload_singleton(MISSIONMANAGER_NAME)
	remove_autoload_singleton(AUDIOMANAGER_NAME)
