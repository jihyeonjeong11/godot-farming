# Global scripts for all game events
# TODO: add some events
extends Node

signal dialog(text_key_arr: Array[StringName])

signal game_state_changed(game_state: DataTypes.GameState)

signal game_paused(is_paused: bool)
signal ingame_paused(is_paused: bool)

## UIManager.Layer 하나를 닫아달라는 요청. 실제로 닫을지는 UIManager가 정한다.
signal ui_close_requested(layer: int)

## UI 스택이 바뀐 순간. UIManager는 "무엇이 열려 있나"만 알리고,
## 그게 게임을 멈추는지는 GameStateManager가 판단한다.
signal ui_stack_changed(pause_requested: bool)

signal time_tick(day: int, hour: int, minute: int)
signal time_tick_day(day: int)

## 도구를 사용한 순간. 무엇을 할지는 듣는 쪽이 item.tool_type을 보고 정한다.
## 플레이어 씬이 레벨의 타일맵을 몰라도 되게 하는 통로.
signal tool_used(item: Item, user_position: Vector2, target_position: Vector2)

signal container_opened(slots: Array)

## 어느 슬롯으로 시작하는가. 메뉴의 슬롯 화면이 고른 번호를 싣는다.
signal new_game_requested(slot: int)

signal main_menu_requested()

## 어느 슬롯을 불러오는가.
signal load_game_requested(slot: int)

signal barter_opened(slots: Array)

## spawn_id 는 도착한 씬의 SpawnPoint 이름. 비어 있으면 그 씬에 박힌 자리에 그대로 선다.
signal scene_change_requested(scene_path: String, spawn_id: StringName)

signal player_died()

signal quest_progressed(quest_id: String)

signal quest_completed(quest_id: String)

signal quest_cleared(quest_id: String)

signal quest_list_changed()

signal enemy_killed(enemy_id: StringName)

# TODO: this is temp signal, need a system
signal sound_requested(soundKey: String)
