class_name GameStateManager
extends Node
var game_state: DataTypes.GameState = DataTypes.GameState.MainMenu

var _announced := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.ui_stack_changed.connect(on_ui_stack_changed)


func enter_main_menu() -> void:
	_set_state(DataTypes.GameState.MainMenu)


func enter_gameplay() -> void:
	_set_state(DataTypes.GameState.Game)

func on_ui_stack_changed(pause_requested: bool) -> void:
	get_tree().paused = pause_requested


func _set_state(new_state: DataTypes.GameState) -> void:
	if _announced and game_state == new_state:
		return

	_announced = true
	game_state = new_state
	SignalBus.game_state_changed.emit(game_state)
