class_name PlayerBuffComponent
extends Node


@export var stats: BaseCharacterStats

@export_range(0.0, 1.0) var hunger_slow_threshold: float = 0.5
@export_range(0.0, 1.0) var hunger_slow_multiplier: float = 0.5

const HUNGER_SLOW := &"hunger_slow"

var _buffs: Dictionary[StringName, StatBuff] = {}


func _ready() -> void:
	if stats == null:
		push_warning("PlayerBuffComponent에 stats가 없습니다.")
		return

	_buffs[HUNGER_SLOW] = StatBuff.new(
		BaseCharacterStats.Buffables.SPEED,
		hunger_slow_multiplier - 1.0,
		StatBuff.BuffType.MULTIPLY
	)

	stats.hunger_changed.connect(on_hunger_changed)
	on_hunger_changed(stats.hunger, stats.current_max_hunger)


func _exit_tree() -> void:
	if stats == null:
		return
	for key in _buffs:
		set_buff_active(key, false)


func on_hunger_changed(cur_hunger: int, max_hunger: int) -> void:
	var ratio: float = float(cur_hunger) / float(max_hunger) if max_hunger > 0 else 1.0
	set_buff_active(HUNGER_SLOW, ratio < hunger_slow_threshold)


func set_buff_active(key: StringName, active: bool) -> void:
	var buff: StatBuff = _buffs.get(key)
	if buff == null or active == stats.stat_buffs.has(buff):
		return

	if active:
		stats.add_buff(buff)
	else:
		stats.remove_buff(buff)
