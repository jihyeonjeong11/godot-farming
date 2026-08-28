extends Node

const MINUTES_PER_DAY: int = 24 * 60
const MINUTES_PER_HOUR: int = 60
const GAME_MINUTE_DURARTION: float = TAU / MINUTES_PER_DAY

var game_speed: float = 1.0

var time: float = 0.0
var current_minute: int = -1
var current_hour: int = 0
var current_day: int = 0

var initial_day: int = 1
var initial_hour: int = 6
var initial_minute: int = 0

func set_initial_time() -> void:
	var initial_total_minutes = initial_day * MINUTES_PER_DAY + (initial_hour * MINUTES_PER_HOUR) + initial_minute
	time = initial_total_minutes * GAME_MINUTE_DURARTION

func _ready() -> void:
	set_initial_time()


## 잠자기처럼 시간을 한 번에 건너뛸 때 쓴다. 다음 _process 의 recalculate_time 이
## time_tick / time_tick_day 를 알아서 울려준다.
func skip_to(day: int, hour: int, minute: int = 0) -> void:
	var total_minutes: int = day * MINUTES_PER_DAY + hour * MINUTES_PER_HOUR + minute
	time = total_minutes * GAME_MINUTE_DURARTION
	

func _process(delta: float) -> void:
	time += delta * game_speed * GAME_MINUTE_DURARTION
	SignalBus.game_time.emit(time)
	recalculate_time()

func recalculate_time() -> void:
	var total_minutes: int = int(time / GAME_MINUTE_DURARTION)
	var day: int = int(total_minutes / MINUTES_PER_DAY)
	var current_day_minutes: int = total_minutes % MINUTES_PER_DAY
	var hour: int = int(current_day_minutes / MINUTES_PER_HOUR)
	var minute: int = int(current_day_minutes % MINUTES_PER_HOUR)

	if current_minute != minute:
		current_minute = minute
		SignalBus.time_tick.emit(day, hour, minute)

	if current_day != day:
		current_day = day
		SignalBus.time_tick_day.emit(day)
