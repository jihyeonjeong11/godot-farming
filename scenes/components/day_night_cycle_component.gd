class_name DayNightCycleComponent
extends CanvasModulate

@export var day_night_gradient_texture: GradientTexture1D

var _tint: Color = Color.WHITE
var _in_game := false


func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)
	SignalBus.game_state_changed.connect(on_game_state_changed)


func on_game_state_changed(game_state: DataTypes.GameState) -> void:
	_in_game = game_state == DataTypes.GameState.Game
	_apply()


func on_time_tick(_day: int, hour: int, minute: int) -> void:
	if day_night_gradient_texture == null:
		return

	var minutes_of_day: float = hour * TimeManager.MINUTES_PER_HOUR + minute
	var angle: float = minutes_of_day / (TimeManager.HOURS_PER_DAY * TimeManager.MINUTES_PER_HOUR) * TAU
	var sample_value: float = 0.5 * (sin(angle - PI * 0.5) + 1.0)
	_tint = day_night_gradient_texture.gradient.sample(sample_value)
	_apply()


func _apply() -> void:
	color = _tint if _in_game else Color.WHITE
