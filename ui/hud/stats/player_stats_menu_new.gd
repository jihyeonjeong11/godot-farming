extends MarginContainer

@onready var health_bar: ProgressBar = $HBoxContainer/HealthBar
@onready var health_label: Label = $HBoxContainer/HealthBar/HealthLabel
@onready var hunger_icon: TextureProgressBar = $HBoxContainer/HungerIcon
@onready var thirst_icon: TextureProgressBar = $HBoxContainer/ThirstIcon
@onready var gold_label: Label = $HBoxContainer/GoldLabel
@onready var day_label: Label = $HBoxContainer/DayLabel
@onready var time_label: Label = $HBoxContainer/TimeLabel

var _stats: BaseCharacterStats


func _ready() -> void:
	SignalBus.level_loaded.connect(bind_player)
	SignalBus.time_tick.connect(on_time_tick)
	bind_player()
	var tm := TimeManager.find(get_tree())
	if tm != null:
		on_time_tick(tm.today(), int(tm.current_time["hour"]), int(tm.current_time["minute"]))


func bind_player() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	bind_stats(player.stats if player != null else null)


func bind_stats(stats: BaseCharacterStats) -> void:
	if stats == null or stats == _stats:
		return

	if _stats != null:
		_stats.health_changed.disconnect(on_health_changed)
		_stats.hunger_changed.disconnect(on_hunger_changed)
		_stats.thirst_changed.disconnect(on_thirst_changed)
		_stats.gold_changed.disconnect(on_gold_changed)
	_stats = stats

	on_health_changed(stats.health, stats.current_max_health)
	on_hunger_changed(stats.hunger, stats.current_max_hunger)
	on_thirst_changed(stats.thirst, stats.current_max_thirst)
	on_gold_changed(stats.gold)
	stats.health_changed.connect(on_health_changed)
	stats.hunger_changed.connect(on_hunger_changed)
	stats.thirst_changed.connect(on_thirst_changed)
	stats.gold_changed.connect(on_gold_changed)


func on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health
	health_label.text = "%d / %d" % [new_health, max_health]


func on_hunger_changed(new_hunger: int, max_hunger: int) -> void:
	hunger_icon.max_value = max_hunger
	hunger_icon.value = new_hunger
	hunger_icon.tooltip_text = "허기 %d / %d" % [new_hunger, max_hunger]


func on_thirst_changed(new_thirst: int, max_thirst: int) -> void:
	thirst_icon.max_value = max_thirst
	thirst_icon.value = new_thirst
	thirst_icon.tooltip_text = "갈증 %d / %d" % [new_thirst, max_thirst]


func on_gold_changed(new_gold: int) -> void:
	gold_label.text = str(new_gold)


func on_time_tick(day: int, hour: int, minute: int) -> void:
	day_label.text = "Day %d" % day
	time_label.text = "%02d:%02d" % [hour, minute]
