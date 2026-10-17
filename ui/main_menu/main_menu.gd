extends Control

@onready var play: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Play
@onready var continue_menu: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Continue
@onready var exit: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Exit
@onready var settings: ButtonBase = $CenterContainer/MarginContainer/VBoxContainer/Settings

var tutorial_scene = preload("uid://p5khtom1236l")
var farm_scene = preload("uid://bmainfarm0001")

@export var save_slots_scene: PackedScene
@export var settings_scene: PackedScene
@export var character_customization_scene: PackedScene
@export var continue_scene: PackedScene

var selected_slot: int = -1


func _ready() -> void:
	exit.pressed.connect(_on_pressed_exit)
	settings.pressed.connect(_on_pressed_settings)
	play.pressed.connect(_on_pressed_play)
	continue_menu.pressed.connect(_on_pressed_continue)

func _on_pressed_play() -> void:
	var save_menu = save_slots_scene.instantiate()
	add_child(save_menu)
	save_menu.closed.connect(save_menu.queue_free)
	save_menu.slot_chosen.connect(_on_slot_chosen.bind(save_menu))


func _on_slot_chosen(slot: int, is_empty: bool, save_menu: Node) -> void:
	selected_slot = slot
	await save_menu.close()
	save_menu.queue_free()

	if not is_empty:
		SaveManager.load_game(selected_slot)
		TransitionManager.go_to_scene(farm_scene)
		return

	var customization = character_customization_scene.instantiate()
	add_child(customization)
	customization.confirmed.connect(_on_customization_confirmed)
	customization.cancelled.connect(_on_customization_cancelled.bind(customization))


func _on_customization_confirmed() -> void:
	var vanity := GameState.player_vanity.duplicate()
	SaveManager.new_game(selected_slot)
	GameState.player_vanity.assign(vanity)
	SessionState.new_game()
	if GameState.did_skip_tutorial:
		TransitionManager.go_to_scene(tutorial_scene)
	else:
		# 튜토에서 얻는 아이템은 주고
		TransitionManager.go_to_scene(farm_scene)



func _on_customization_cancelled(customization: Node) -> void:
	selected_slot = -1
	customization.queue_free()
	_on_pressed_play()


func _on_pressed_continue() -> void:
	# 세이브 저장한 것중 가장 최근껄로 로드함
	pass

	
func _on_pressed_exit() -> void:
	get_tree().quit()
	
func _on_pressed_settings() -> void:
	var settings_menu = settings_scene.instantiate()
	add_child(settings_menu)
