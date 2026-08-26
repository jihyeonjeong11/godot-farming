# TODO: this goes to game.tscn's children

extends Node

## 하루가 바뀔 때 비가 올 확률.
const RAIN_CHANCE := 0.9

## 비가 시작되거나 그친 순간. 파티클·빗소리·화면 어둡게·밭 적시기가 이걸 구독한다.
## 매니저는 구독자가 누군지 모른다 — 그래서 씬이 갈려도 찾아다닐 필요가 없다.
signal rain_changed(is_raining: bool)

var raining := false


func _ready() -> void:
	start_raining()
	SignalBus.time_tick_day.connect(determine_weather)


## 하루가 넘어갔다. 오늘 비가 올지 정한다.
##
## 지금은 그날 바로 굴리지만, 나중에 며칠치를 미리 뽑는 예보 큐로 바꿔도
## 구독자는 하나도 안 바뀐다. 밖에서 보이는 건 rain_changed 뿐이라서다.
func determine_weather(_day: int) -> void:
	if randf() < RAIN_CHANCE:
		start_raining()
	else:
		stop_raining()


func start_raining() -> void:
	# 이미 오는 중이면 다시 알리지 않는다. 구독자가 연출을 처음부터 다시 트는 걸 막는다.
	if raining:
		return

	raining = true
	rain_changed.emit(true)


func stop_raining() -> void:
	if not raining:
		return

	raining = false
	rain_changed.emit(false)


## 디버그 전용. 하루가 현실 24분이라 날씨 바뀌는 걸 기다려서 확인할 수가 없다.
## 에디터/디버그 빌드에서만 K로 비를 켜고 끈다. 출시 빌드에는 안 들어간다.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_K:
		if raining:
			stop_raining()
		else:
			start_raining()

		print("[Weather] raining=", raining)
