extends Node

signal hour_passed
signal day_passed(day: int)
signal time_tick(day: int, hour: int, minute: int)

const GROUP: StringName = &"time_manager"
const SLEEP_HOLD_DURATION: float = 1.5
const WAKE_HOUR := 6
const DUSK_HOUR := 17
const NIGHT_HOUR := 20
const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const MINUTES_PER_DAY := HOURS_PER_DAY * MINUTES_PER_HOUR
const SECONDS_PER_GAME_MINUTE := 0.7
const MINUTES_PER_TICK := 10
const SECONDS_PER_TICK := SECONDS_PER_GAME_MINUTE * MINUTES_PER_TICK

const INITIAL_TIME: Dictionary = {
	"day": 0,
	"hour": 20,
	"minute": 0
}

var current_time: Dictionary:
	get:
		return GameState.current_time
	set(value):
		GameState.current_time = value

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


# GameState.current_time
# 베이스 레벨 타이머 -> advance -> signal -> 필요한 곳에서 사용
# 세션 스테이트 라이팅
# 튜토리얼 + 알파 시간 안 흐르는 부분
func pass_time() -> void:
	pass

func advance_day() -> void:
	if TransitionManager.is_transitioning:
		return
	await TransitionManager.fade_to_color(Color.BLACK)
	if int(current_time["hour"]) >= WAKE_HOUR:
		current_time["day"] = today() + 1
	current_time["hour"] = WAKE_HOUR
	current_time["minute"] = 0
	_elapsed = 0.0
	
	# 풀 확산
	SnapshotActions.spread()
	# 빈 tilled_soil 제거
	# 나무 확산
	# 돌 확산 - 깔아놓은 오브젝트 제거
	SnapshotActions.grow_objects()
	day_passed.emit(today())
	SnapshotActions.dry_all_soil()
	get_tree().call_group(WateredSoilLayer.GROUP, &"dry_all")
	_emit_tick()
	
	await get_tree().create_timer(SLEEP_HOLD_DURATION).timeout
	await TransitionManager.clear_fade()


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
	while _elapsed >= SECONDS_PER_TICK:
		_elapsed -= SECONDS_PER_TICK
		_advance_minutes(MINUTES_PER_TICK)


func _advance_minutes(minutes: int) -> void:
	current_time["minute"] += minutes
	while current_time["minute"] >= MINUTES_PER_HOUR:
		current_time["minute"] -= MINUTES_PER_HOUR
		current_time["hour"] += 1
	if current_time["hour"] >= HOURS_PER_DAY:
		current_time["hour"] -= HOURS_PER_DAY
		current_time["day"] += 1
	_emit_tick()


func today() -> int:
	return int(current_time["day"])


static func minutes_of(day: int, hour: int, minute: int) -> int:
	return day * MINUTES_PER_DAY + hour * MINUTES_PER_HOUR + minute


func total_minutes() -> int:
	return minutes_of(today(), int(current_time["hour"]), int(current_time["minute"]))


func skip_to(day: int, hour: int, minute: int = 0) -> void:
	current_time["day"] = day
	current_time["hour"] = hour
	current_time["minute"] = minute
	_elapsed = 0.0
	_emit_tick()


func lighting_for_hour(hour: int) -> GameState.BaseLighting:
	if hour >= WAKE_HOUR and hour < DUSK_HOUR:
		return GameState.BaseLighting.Day
	if hour >= DUSK_HOUR and hour < NIGHT_HOUR:
		return GameState.BaseLighting.Dusk
	return GameState.BaseLighting.Night


func _emit_tick() -> void:
	GameState.base_lighting = lighting_for_hour(int(current_time["hour"]))
	time_tick.emit(today(), int(current_time["hour"]), int(current_time["minute"]))
