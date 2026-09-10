extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.time_tick_day.connect(day_update)
	
func day_update(day: int) -> void:
	# 절차적 생성, 맵 오브젝트 업데이트
	pass
