# Global scripts for all game events
# TODO: add some events
extends Node

signal game_paused(is_paused: bool)
signal ingame_paused(is_paused: bool)

signal game_time(time: float)
signal time_tick(day: int, hour: int, minute: int)
signal time_tick_day(day: int)




	   #8  func _ready() -> void:
	   #9 +  SignalBus.test_global_event.connect(on_test_global_event)

	  #12 +func _unhandled_input(event: InputEvent) -> void:
	  #13 +  if event.is_action_pressed("hit"):
	  #14 +    SignalBus.test_global_event.emit()

	  #17 +func on_test_global_event() -> void:
	  #18 +  print("player: test_global_event 수신")
