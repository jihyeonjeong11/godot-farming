# Global scripts for all game events
# TODO: add some events
extends Node

signal game_paused(is_paused: bool)
signal ingame_paused(is_paused: bool)

## PauseManager.Layer 하나를 닫아달라는 요청. 실제 상태는 PauseManager가 정한다.
signal ui_close_requested(layer: int)

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

## 플레이어가 _ready에서 만든 Stats 사본. 공유 .tres가 아니라 이 사본이 실제로 변한다.
## UI나 컴포넌트가 @export로 .tres를 직접 물면 아무도 안 건드리는 원본을 보게 된다.
var player_stats: Stats

## 위 사본이 준비된 순간. 노드 _ready 순서는 보장되지 않으므로, 늦게 붙는 쪽은
## 시그널을 놓치는 대신 player_stats를 직접 읽어 가면 된다.
signal player_stats_ready(stats: Stats)


## 상자 같은 것을 열었다. 어디에 그릴지는 UI가 정한다.
signal container_opened(slots: Array)

## 메인 메뉴에서 새 게임을 누른 순간. 어느 씬으로 갈지는 game.gd가 정한다.
signal new_game_requested()

## 메인 메뉴에서 불러오기를 누른 순간. 씬을 띄운 뒤 세이브를 얹는 건 game.gd가 한다.
signal load_game_requested()

signal barter_opened()

## 포탈을 밟았다. 실제 씬 교체는 game.gd가 한다.
## 밟은 쪽이 직접 get_tree().change_scene을 부르면 루트(Game)와 오토로드 연결이
## 끊긴 채로 갈아끼워지므로, 통로를 여기 하나로 묶는다.
signal scene_change_requested(scene_path: String)
