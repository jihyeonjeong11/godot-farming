extends Control

@onready var play: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Play
@onready var continue_menu: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Continue
@onready var exit: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Exit
@onready var settings: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Settings

var new_game_scene = preload("uid://p5khtom1236l")


@export var settings_scene: PackedScene
@export var character_customization_scene: PackedScene
@export var continue_scene: PackedScene


func _ready() -> void:
	exit.pressed.connect(_on_pressed_exit)
	settings.pressed.connect(_on_pressed_settings)
	play.pressed.connect(_on_pressed_play)
	continue_menu.pressed.connect(_on_pressed_continue)

func _on_pressed_play() -> void:
	# 세이브 슬롯
	# 이미 있는 슬롯 -> 로드
	# 없는 슬롯 -> character_customization 표시
	TransitionManager.go_to_scene(new_game_scene)
	#var character_customization = character_customization_scene.instantiate()
	#add_child(character_customization)
	
func _on_pressed_continue() -> void:
	# 세이브 저장한 것중 가장 최근껄로 로드함
	pass

	
func _on_pressed_exit() -> void:
	get_tree().quit()
	
func _on_pressed_settings() -> void:
	var settings_menu = settings_scene.instantiate()
	add_child(settings_menu)
