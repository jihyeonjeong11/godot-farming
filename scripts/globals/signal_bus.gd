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
