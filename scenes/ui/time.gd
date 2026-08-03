extends PanelContainer

## 테스트용 게임 속도 프리셋
@export var normal_speed: int = 5
@export var fast_speed: int = 100
@export var cheetah_speed: int = 200

@onready var day_label: Label = $MarginContainer/VBoxContainer/DayLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/PanelContainer/TimeLabel


func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)


func on_time_tick(day: int, hour: int, minute: int) -> void:
	day_label.text = "Day " + str(day)
	time_label.text = "%02d:%02d" % [hour, minute]


func _on_normal_speed_button_pressed() -> void:
	DayAndNightCycle.game_speed = normal_speed


func _on_fast_speed_button_pressed() -> void:
	DayAndNightCycle.game_speed = fast_speed


func _on_cheetah_speed_button_pressed() -> void:
	DayAndNightCycle.game_speed = cheetah_speed
