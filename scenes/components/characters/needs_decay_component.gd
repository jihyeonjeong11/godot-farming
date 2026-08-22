class_name NeedsDecayComponent
extends Node

@export var hunger_decay_per_hour: int = 2
@export var thirst_decay_per_hour: int = 5
@export var health_decay_per_hour: int = 1


var stats: Stats
var last_decay_hour: int = -1

func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)
	SignalBus.player_stats_ready.connect(bind_stats)

	if SignalBus.player_stats != null:
		bind_stats(SignalBus.player_stats)


func bind_stats(player_stats: Stats) -> void:
	stats = player_stats


## 시간은 게임 내 1분마다 들어온다. 시(hour)가 바뀐 순간에만 한 번 깎는다.
func on_time_tick(_day: int, hour: int, _minute: int) -> void:
	if hour == last_decay_hour:
		return

	# 첫 틱은 기준 시각만 잡고 넘어간다. 시작하자마자 깎이지 않도록.
	var is_first_tick: bool = last_decay_hour == -1
	last_decay_hour = hour

	if is_first_tick or stats == null:
		return

	stats.health = maxi(stats.health - health_decay_per_hour, 0)
	stats.hunger = maxi(stats.hunger - hunger_decay_per_hour, 0)
	stats.thirst = maxi(stats.thirst - thirst_decay_per_hour, 0)
