extends Node2D

@export_file("*.tscn") var scene_farm := "res://scenes/test_scenes/farm.tscn"
@export_file("*.tscn") var scene_city := "res://scenes/test_scenes/proc_gen_city_ruin.tscn"
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


func on_scene_change_requested(scene_path: String, spawn_id: StringName) -> void:
	swap_scene.call_deferred(scene_path, spawn_id)

func swap_scene(path: String, spawn_id: StringName = &"") -> void:
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

	# 씬마다 플레이어가 따로 박혀 있다. 문으로 들어왔으면 그 씬에 박힌 자리 대신
	# 문이 가리킨 스폰 지점에 세운다.
	if not spawn_id.is_empty():
		move_player_to_spawn(spawn_id)

	if path == scene_mainmenu:
		game_state_manager.enter_main_menu()
	else:
		game_state_manager.enter_gameplay()

	_swapping = false


## 지점을 못 찾아도 플레이어를 건드리지 않는다. 문이 잘못 가리켰다고
## 맵 밖으로 떨어뜨리는 것보다 씬에 박힌 자리에 서 있는 편이 낫다.
func move_player_to_spawn(spawn_id: StringName) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		push_warning("스폰 지점으로 옮길 플레이어가 씬에 없다: %s" % spawn_id)
		return

	for node in get_tree().get_nodes_in_group(SpawnPoint.GROUP):
		var point := node as SpawnPoint
		if point == null or point.spawn_id != spawn_id:
			continue

		player.global_position = point.global_position
		return

	push_warning("스폰 지점을 찾지 못했다: %s" % spawn_id)
