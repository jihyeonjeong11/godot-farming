# Global scripts for all game events
# TODO: add some events
extends Node

signal game_state_changed(game_state: DataTypes.GameState)

signal game_paused(is_paused: bool)
signal ingame_paused(is_paused: bool)

## UIManager.Layer 하나를 닫아달라는 요청. 실제로 닫을지는 UIManager가 정한다.
signal ui_close_requested(layer: int)

## UI 스택이 바뀐 순간. UIManager는 "무엇이 열려 있나"만 알리고,
## 그게 게임을 멈추는지는 GameStateManager가 판단한다.
signal ui_stack_changed(pause_requested: bool)

signal game_time(time: float)
signal time_tick(day: int, hour: int, minute: int)
signal time_tick_day(day: int)

## 도구를 사용한 순간. 무엇을 할지는 듣는 쪽이 item.tool_type을 보고 정한다.
## 플레이어 씬이 레벨의 타일맵을 몰라도 되게 하는 통로.
signal tool_used(item: Item, user_position: Vector2, target_position: Vector2)

## 우클릭한 순간. tool_used와 같은 통로인데 도구를 싣지 않는다.
## 빈손이어도 상자는 열려야 하기 때문이다.
signal interact_used(user_position: Vector2, target_position: Vector2)

## interact_used를 받은 쪽이 "내가 처리했다"고 남기는 자리.
## 시그널은 값을 돌려주지 못해서 이 깃발로 대신한다. 쏘는 쪽이 직전에 false로 두고
var interact_handled := false


signal container_opened(slots: Array)

## 어느 슬롯으로 시작하는가. 메뉴의 슬롯 화면이 고른 번호를 싣는다.
signal new_game_requested(slot: int)

signal main_menu_requested()

## 어느 슬롯을 불러오는가.
signal load_game_requested(slot: int)

signal barter_opened(slots: Array)

## spawn_id 는 도착한 씬의 SpawnPoint 이름. 비어 있으면 그 씬에 박힌 자리에 그대로 선다.
signal scene_change_requested(scene_path: String, spawn_id: StringName)

# TODO: this is temp signal, need a system
signal sound_requested(soundKey: String)
