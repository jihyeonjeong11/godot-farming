extends Node2D

@onready var dev_layer: CanvasLayer = $DevLayer

@export var respawn_spawn: StringName = &""

@onready var current_scene: Node = $CurrentScene
@onready var game_state_manager: GameStateManager = $GameStateManager

var _swapping := false


func _ready() -> void:
	if GlobalVars.is_dev == false:
		dev_layer.visible = false
	_free_tab_key()
	SignalBus.new_game_requested.connect(on_new_game_requested)
	SignalBus.load_game_requested.connect(on_load_game_requested)
	SignalBus.scene_change_requested.connect(on_scene_change_requested)
	SignalBus.main_menu_requested.connect(on_main_menu_requested)
	SignalBus.player_died.connect(on_player_died)
	swap_scene(GlobalVars.SCENE_MAINMENU)

func _free_tab_key() -> void:
	for action in [&"ui_focus_next", &"ui_focus_prev"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and (event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB):
				InputMap.action_erase_event(action, event)


func on_new_game_requested(slot: int) -> void:
	SaveAndLoad.select_slot(slot)
	Inventory.player_stats = null
	SaveAndLoad.clear_slot()
	SaveAndLoad.load_requested = false
	SaveAndLoad.fresh_start = true
	reset_quests()
	reset_weather()
	swap_level.call_deferred(DataTypes.Levels.Farm)
	SaveAndLoad.save_game.call_deferred()
	_open_intro_dialog.call_deferred()
	
	

func reset_quests() -> void:
	var manager := QuestManager.find(get_tree())
	if manager == null:
		push_warning("퀘스트 진행도를 비울 QuestManager 가 없다")
		return

	manager.reset_progress()


func reset_weather() -> void:
	var manager := WeatherManager.find(get_tree())
	if manager == null:
		push_warning("날씨를 되돌릴 WeatherManager 가 없다")
		return

	manager.set_weather(DataTypes.WeatherType.Sunny)


func _open_intro_dialog() -> void:
	var keys: Array[StringName] = [&"DIALOG_TUTORIAL_01_01", &"DIALOG_TUTORIAL_01_02", &"DIALOG_TUTORIAL_01_03", &"DIALOG_TUTORIAL_01_04"]
	SignalBus.dialog.emit(keys)


func on_load_game_requested(slot: int) -> void:
	SaveAndLoad.select_slot(slot)
	Inventory.player_stats = null
	SaveAndLoad.fresh_start = true
	# 인벤토리와 시간은 오토로드라 씬 교체와 무관하다. 여기서 바로 얹어도 된다.
	SaveAndLoad.load_game()
	swap_level.call_deferred(DataTypes.Levels.Farm)


func on_main_menu_requested() -> void:
	swap_scene.call_deferred(GlobalVars.SCENE_MAINMENU)


func on_scene_change_requested(scene_path: String, spawn_id: StringName) -> void:
	swap_scene.call_deferred(scene_path, spawn_id)


func _on_dev_tutorial_pressed() -> void:
	swap_level.call_deferred(DataTypes.Levels.Tutorial)


func on_player_died() -> void:
	await ScreenFade.fade_out()
	await get_tree().process_frame
	swap_level(DataTypes.Levels.Farm, respawn_spawn)
	var keys: Array[StringName] = [&"DIALOG_ON_DEATH"]
	SignalBus.dialog.emit(keys)
	revive_player()
	await ScreenFade.fade_in()


func revive_player() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		push_warning("되살릴 플레이어가 씬에 없다")
		return

	player.revive()

func swap_level(key: DataTypes.Levels, spawn_id: StringName = &"") -> void:
	swap_scene(GlobalVars.LEVEL_SCENES[key], spawn_id)


func swap_scene(path: String, spawn_id: StringName = &"") -> void:
	if _swapping:
		return

	path = ResourceUID.ensure_path(path)
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("씬을 불러오지 못했다: %s" % path)
		return

	_swapping = true

	if is_instance_valid(SaveAndLoad.current_level):
		SaveAndLoad.stash_level(SaveAndLoad.current_level)

	for child in current_scene.get_children():
		current_scene.remove_child(child)
		child.queue_free()

	var level_key: Variant = GlobalVars.LEVEL_SCENES.find_key(path)
	if level_key != null:
		SessionState.current_scene = level_key

	var instance := packed.instantiate()
	current_scene.add_child(instance)

	# 메인메뉴는 레벨이 아니다. null로 둬야 메뉴에서 실수로 저장이 나가지 않는다.
	SaveAndLoad.current_level = null if path == GlobalVars.SCENE_MAINMENU else instance

	# 씬마다 플레이어가 따로 박혀 있다. 문으로 들어왔으면 그 씬에 박힌 자리 대신
	# 문이 가리킨 스폰 지점에 세운다.
	if not spawn_id.is_empty():
		move_player_to_spawn(spawn_id)

	if path == GlobalVars.SCENE_MAINMENU:
		game_state_manager.enter_main_menu()
	else:
		game_state_manager.enter_gameplay()
	
	SignalBus.level_loaded.emit()
	_swapping = false

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
