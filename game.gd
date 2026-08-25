extends Node2D

@export_file("*.tscn") var scene_farm := "res://scenes/test_scenes/player_test.tscn"
@export_file("*.tscn") var scene_city := "res://scenes/test_scene_outside.tscn"
@export_file("*.tscn") var scene_mainmenu := "res://scenes/mainmenu.tscn"

@onready var current_scene: Node = $CurrentScene
@onready var game_state_manager: GameStateManager = $GameStateManager

var _swapping := false


func _ready() -> void:
	_free_tab_key()
	SignalBus.new_game_requested.connect(on_new_game_requested)
	SignalBus.load_game_requested.connect(on_load_game_requested)
	SignalBus.scene_change_requested.connect(on_scene_change_requested)
	SignalBus.main_menu_requested.connect(on_main_menu_requested)
	swap_scene(scene_mainmenu)

func _free_tab_key() -> void:
	for action in [&"ui_focus_next", &"ui_focus_prev"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and (event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB):
				InputMap.action_erase_event(action, event)


func on_new_game_requested() -> void:
	SaveAndLoad.load_requested = false
	SaveAndLoad.fresh_start = true
	swap_scene.call_deferred(scene_farm)

func on_load_game_requested() -> void:
	SaveAndLoad.load_requested = true
	SaveAndLoad.fresh_start = true
	# 인벤토리와 시간은 오토로드라 씬 교체와 무관하다. 여기서 바로 얹어도 된다.
	SaveAndLoad.load_inventory()
	SaveAndLoad.load_time()
	swap_scene.call_deferred(scene_farm)


func on_main_menu_requested() -> void:
	swap_scene.call_deferred(scene_mainmenu)


func on_scene_change_requested(scene_path: String) -> void:
	swap_scene.call_deferred(scene_path)

func swap_scene(path: String) -> void:
	if _swapping:
		return

	var packed := load(path) as PackedScene
	if packed == null:
		push_error("씬을 불러오지 못했다: %s" % path)
		return

	_swapping = true

	for child in current_scene.get_children():
		current_scene.remove_child(child)
		child.queue_free()

	current_scene.add_child(packed.instantiate())

	if path == scene_mainmenu:
		game_state_manager.enter_main_menu()
	else:
		game_state_manager.enter_gameplay()

	_swapping = false
