class_name DayNightCycleComponent
extends CanvasModulate

@export var day_night_gradient_texture: GradientTexture1D


func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)


func on_time_tick(_day: int, hour: int, minute: int) -> void:
	if day_night_gradient_texture == null:
		return

	var minutes_of_day: float = hour * TimeManager.MINUTES_PER_HOUR + minute
	var angle: float = minutes_of_day / (TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR) * TAU
	var sample_value: float = 0.5 * (sin(angle - PI * 0.5) + 1.0)
	color = day_night_gradient_texture.gradient.sample(sample_value)
