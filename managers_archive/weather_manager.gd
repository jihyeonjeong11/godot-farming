class_name WeatherManager
extends Node

const GROUP: StringName = &"weather_manager"
const RAIN_CHANCE := 0.5

signal weather_changed(weather: DataTypes.WeatherType)

var current_weather: DataTypes.WeatherType = DataTypes.WeatherType.Sunny


func _ready() -> void:
	add_to_group(GROUP)
	SignalBus.time_tick_day.connect(determine_weather)


static func find(tree: SceneTree) -> WeatherManager:
	return tree.get_first_node_in_group(GROUP) as WeatherManager


func determine_weather(_day: int) -> void:
	if randf() < RAIN_CHANCE:
		set_weather(DataTypes.WeatherType.Raining)
	else:
		set_weather(DataTypes.WeatherType.Sunny)


func set_weather(new_weather: DataTypes.WeatherType) -> void:
	if current_weather == new_weather:
		return

	current_weather = new_weather
	weather_changed.emit(current_weather)


func is_raining() -> bool:
	return current_weather == DataTypes.WeatherType.Raining


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_K:
		if is_raining():
			set_weather(DataTypes.WeatherType.Sunny)
		else:
			set_weather(DataTypes.WeatherType.Raining)

		print("[Weather] ", DataTypes.WeatherType.keys()[current_weather])
