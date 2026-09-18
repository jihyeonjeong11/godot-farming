class_name TimeManager
extends Node

# 작물 성장, 날씨, 플레이어 스탯 재조정
signal advance_day

const GROUP: StringName = &"time_manager"
const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const SECONDS_PER_GAME_MINUTE := 0.7

# TODO: 계절 시스템
var season = [
]

# TODO: 특수한 컨디션들 예) 태풍, 외 이것저것
var weather_conditions = [

]

# 튜토리얼용 시간
const INITIAL_TIME: Dictionary = {
	"season": 'winter',
	"day": 0,
	"hour": 20,
	"minute": 0
}

var current_time : Dictionary = {
	"season": 'winter',
	"day": 0,
	"hour": 6,
	"minute": 0
}

var game_speed: float = 1.0
var is_running: bool = false

var _elapsed: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	SignalBus.new_game_requested.connect(_on_new_game)
	SignalBus.load_game_requested.connect(_on_load_game)
	SignalBus.main_menu_requested.connect(stop_time_advance)


static func find(tree: SceneTree) -> TimeManager:
	return tree.get_first_node_in_group(GROUP) as TimeManager


func _on_new_game(_slot: int) -> void:
	current_time = INITIAL_TIME.duplicate()
	start_time_advance()


func _on_load_game(_slot: int) -> void:
	start_time_advance()


func start_time_advance() -> void:
	is_running = true
	_elapsed = 0.0
	_emit_tick()


func stop_time_advance() -> void:
	is_running = false


func should_time_pass() -> bool:
	return is_running and not get_tree().paused


func _process(delta: float) -> void:
	if not should_time_pass():
		return

	_elapsed += delta * game_speed
	while _elapsed >= SECONDS_PER_GAME_MINUTE:
		_elapsed -= SECONDS_PER_GAME_MINUTE
		_tick_minute()


func _tick_minute() -> void:
	current_time["minute"] += 1
	if current_time["minute"] >= MINUTES_PER_HOUR:
		current_time["minute"] = 0
		current_time["hour"] += 1
	if current_time["hour"] >= HOURS_PER_DAY:
		current_time["hour"] = 0
		current_time["day"] += 1
		SignalBus.time_tick_day.emit(current_time["day"])
	_emit_tick()


func today() -> int:
	return current_time["day"]


func skip_to(day: int, hour: int, minute: int = 0) -> void:
	var day_changed: bool = day != current_time["day"]
	current_time["day"] = day
	current_time["hour"] = hour
	current_time["minute"] = minute
	_elapsed = 0.0
	if day_changed:
		SignalBus.time_tick_day.emit(day)
	_emit_tick()


func _emit_tick() -> void:
	SignalBus.time_tick.emit(current_time["day"], current_time["hour"], current_time["minute"])
