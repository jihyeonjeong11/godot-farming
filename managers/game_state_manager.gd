class_name GameStateManager
extends Node

@export var game_state: DataTypes.GameState = DataTypes.GameState.MainMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.ui_stack_changed.connect(on_ui_stack_changed)


func enter_main_menu() -> void:
	_set_state(DataTypes.GameState.MainMenu)


func enter_gameplay() -> void:
	_set_state(DataTypes.GameState.Game)


## 정지는 게임 상태지 UI 상태가 아니다. UIManager는 "무엇이 열려 있나"만 알리고,
## 그게 게임을 멈추는지는 여기서 정한다. get_tree().paused 를 쓰는 유일한 자리.
func on_ui_stack_changed(pause_requested: bool) -> void:
	get_tree().paused = pause_requested


## 상태가 실제로 바뀐 순간에만 알린다. 포탈로 레벨만 갈아탈 때도 enter_gameplay가
## 다시 불리는데, 그때마다 알리면 듣는 쪽이 멀쩡한 HUD를 지웠다 다시 만든다.
func _set_state(new_state: DataTypes.GameState) -> void:
	if game_state == new_state:
		return
	game_state = new_state
	SignalBus.game_state_changed.emit(game_state)
