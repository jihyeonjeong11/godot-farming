extends Control

@onready var play: Button = $Container/MarginContainer/VBoxContainer/Play
@onready var load_game: Button = $Container/MarginContainer/VBoxContainer/Load
@onready var settings: Button = $Container/MarginContainer/VBoxContainer/Settings
@onready var quit: Button = $Container/MarginContainer/VBoxContainer/Quit
@onready var menu_panel: PanelContainer = $Container
@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	settings_panel.visible = false

	play.pressed.connect(_on_play_pressed)
	load_game.pressed.connect(_on_load_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)


func _on_play_pressed() -> void:
	SignalBus.new_game_requested.emit()


func _on_load_pressed() -> void:
	SignalBus.load_game_requested.emit()


func _on_settings_pressed() -> void:
	menu_panel.visible = false
	settings_panel.open()


func _on_settings_closed() -> void:
	menu_panel.visible = true
	settings.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
