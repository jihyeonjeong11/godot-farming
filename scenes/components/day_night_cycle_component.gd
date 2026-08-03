class_name DayNightCycleComponent
extends CanvasModulate

@export var initial_day: int = 1:
	set(id):
		initial_day = id
		DayAndNightCycle.initial_day = id
		DayAndNightCycle.set_initial_time()

@export var initial_hour: int = 12:
	set(ih):
		initial_hour = ih
		DayAndNightCycle.initial_hour = ih
		DayAndNightCycle.set_initial_time()

@export var initial_minute: int = 30:
	set(im):
		initial_minute = im
		DayAndNightCycle.initial_minute = im
		DayAndNightCycle.set_initial_time()

@export var day_night_gradient_texture: GradientTexture1D


func _ready() -> void:
	DayAndNightCycle.initial_day = initial_day
	DayAndNightCycle.initial_hour = initial_hour
	DayAndNightCycle.initial_minute = initial_minute
	DayAndNightCycle.set_initial_time()

	SignalBus.game_time.connect(on_game_time)


func on_game_time(time: float) -> void:
	if day_night_gradient_texture == null:
		return

	# time은 하루가 TAU. 자정에 0.0, 정오에 1.0이 되도록 매핑한다.
	var sample_value: float = 0.5 * (sin(time - PI * 0.5) + 1.0)
	color = day_night_gradient_texture.gradient.sample(sample_value)
