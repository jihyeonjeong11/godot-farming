class_name NeedsDecayComponent
extends Node

@export var stats: BaseCharacterStats

@export var hunger_decay_per_hour: int = 2
@export var thirst_decay_per_hour: int = 5
@export var health_decay_per_hour: int = 1

var last_decay_hour: int = -1

func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)

func on_time_tick(_day: int, hour: int, _minute: int) -> void:
	if hour == last_decay_hour:
		return

	var is_first_tick: bool = last_decay_hour == -1
	last_decay_hour = hour

	if is_first_tick or stats == null:
		return
		
	stats._on_hunger_set(maxi(stats.hunger - hunger_decay_per_hour, 0))
	stats._on_thirst_set(maxi(stats.thirst - thirst_decay_per_hour, 0))
