# TODO: this goes to game.tscn's children

extends Node

const RAIN_CHANCE := 0.5

signal rain_changed(is_raining: bool)

var raining := false


func _ready() -> void:
	SignalBus.time_tick_day.connect(determine_weather)


func determine_weather(_day: int) -> void:
	if randf() < RAIN_CHANCE:
		start_raining()
	else:
		stop_raining()


func start_raining() -> void:
	if raining:
		return

	raining = true
	rain_changed.emit(true)


func stop_raining() -> void:
	if not raining:
		return

	raining = false
	rain_changed.emit(false)


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
