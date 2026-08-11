extends Control

@onready var play: Button = $Container/MarginContainer/VBoxContainer/Play
@onready var load_game: Button = $Container/MarginContainer/VBoxContainer/Load
@onready var settings: Button = $Container/MarginContainer/VBoxContainer/Settings
@onready var quit: Button = $Container/MarginContainer/VBoxContainer/Quit


func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	load_game.pressed.connect(_on_load_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	# 씬 교체는 CurrentScene을 쥔 game.gd만 할 수 있으므로 넘긴다.
	SignalBus.new_game_requested.emit()


func _on_load_pressed() -> void:
	# 세이브를 얹으려면 먼저 레벨이 떠 있어야 하므로 여기서도 game.gd에 넘긴다.
	SignalBus.load_game_requested.emit()


func _on_settings_pressed() -> void:
	print("settings")


func _on_quit_pressed() -> void:
	get_tree().quit()
