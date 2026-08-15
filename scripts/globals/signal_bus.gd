# Global scripts for all game events
# TODO: add some events
extends Node

signal game_paused(is_paused: bool)
signal ingame_paused(is_paused: bool)

signal game_time(time: float)
signal time_tick(day: int, hour: int, minute: int)
signal time_tick_day(day: int)

## 도구를 사용한 순간. 무엇을 할지는 듣는 쪽이 item.tool_type을 보고 정한다.
## 플레이어 씬이 레벨의 타일맵을 몰라도 되게 하는 통로.
signal tool_used(item: Items, user_position: Vector2, target_position: Vector2)

## 우클릭한 순간. tool_used와 같은 통로인데 도구를 싣지 않는다.
## 빈손이어도 상자는 열려야 하기 때문이다.
signal interact_used(user_position: Vector2, target_position: Vector2)

## interact_used를 받은 쪽이 "내가 처리했다"고 남기는 자리.
## 시그널은 값을 돌려주지 못해서 이 깃발로 대신한다. 쏘는 쪽이 직전에 false로 두고
## 끝난 뒤 확인한다. 상자를 열었으면 손에 든 감자까지 먹히지 않게 하기 위함이다.
var interact_handled := false

## 상자 같은 것을 열었다. 어디에 그릴지는 UI가 정한다.
signal container_opened(slots: Array)

## 메인 메뉴에서 새 게임을 누른 순간. 어느 씬으로 갈지는 game.gd가 정한다.
signal new_game_requested()

## 메인 메뉴에서 불러오기를 누른 순간. 씬을 띄운 뒤 세이브를 얹는 건 game.gd가 한다.
signal load_game_requested()




	   #8  func _ready() -> void:
	   #9 +  SignalBus.test_global_event.connect(on_test_global_event)

	  #12 +func _unhandled_input(event: InputEvent) -> void:
	  #13 +  if event.is_action_pressed("hit"):
	  #14 +    SignalBus.test_global_event.emit()

	  #17 +func on_test_global_event() -> void:
	  #18 +  print("player: test_global_event 수신")
