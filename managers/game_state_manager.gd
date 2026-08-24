class_name GameStateManager
extends Node

## 지금 상태. 쓰는 건 여기뿐이고 밖에는 game_state_changed로 알린다.
## @export를 걸면 인스펙터에서 실제와 다른 값을 심을 수 있다. 그러면 부팅 때
## _set_state가 "안 바뀌었다"고 판단해 아무에게도 안 알리고 넘어간다.
var game_state: DataTypes.GameState = DataTypes.GameState.MainMenu

## 첫 전이를 아직 알리지 않았다.
var _announced := false


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
##
## 다만 첫 전이만은 값이 같아도 알린다. 부팅 때 game.gd가 메인 메뉴를 띄우면서
## enter_main_menu를 부르는데, 시작값이 이미 MainMenu라 여기서 삼켜버리면
## "메인 메뉴에 들어왔다"는 사건 자체가 없던 일이 된다. 그러면 AudioManager는
## 메뉴 BGM을 틀 계기를 영영 못 받는다.
func _set_state(new_state: DataTypes.GameState) -> void:
	if _announced and game_state == new_state:
		return

	_announced = true
	game_state = new_state
	SignalBus.game_state_changed.emit(game_state)
