extends PanelContainer

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: TextureProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var hunger_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HungerBar
@onready var thirst_bar: TextureProgressBar = $MarginContainer/VBoxContainer/ThirstBar

@onready var gold_text: Control = $MarginContainer/VBoxContainer/HBoxContainer/GoldText
@onready var gold_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/GoldText/GoldLabel

const BAR_NAMES := {
	&"HealthBar": "체력",
	&"StaminaBar": "기력",
	&"HungerBar": "허기",
	&"ThirstBar": "갈증",
}

var _stats: BaseCharacterStats

func _ready() -> void:
	gold_label.resized.connect(fit_gold_text)
	fit_gold_text()
	SignalBus.level_loaded.connect(bind_player)
	bind_player()


func bind_player() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	bind_stats(player.stats if player != null else null)


func bind_stats(stats: BaseCharacterStats) -> void:
	if stats == null or stats == _stats:
		return

	if _stats != null:
		_stats.health_changed.disconnect(on_health_changed)
		_stats.stamina_changed.disconnect(on_stamina_changed)
		_stats.hunger_changed.disconnect(on_hunger_changed)
		_stats.thirst_changed.disconnect(on_thirst_changed)
		_stats.gold_changed.disconnect(on_gold_changed)
	_stats = stats

	setup_bar(health_bar, stats.health, stats.current_max_health)
	setup_bar(stamina_bar, stats.stamina, stats.current_max_stamina)
	setup_bar(hunger_bar, stats.hunger, stats.current_max_hunger)
	setup_bar(thirst_bar, stats.thirst, stats.current_max_thirst)
	
	gold_label.text = str(stats.gold)

	stats.health_changed.connect(on_health_changed)
	stats.stamina_changed.connect(on_stamina_changed)
	stats.hunger_changed.connect(on_hunger_changed)
	stats.thirst_changed.connect(on_thirst_changed)
	stats.gold_changed.connect(on_gold_changed)


func fit_gold_text() -> void:
	gold_text.custom_minimum_size = gold_label.size * gold_label.scale


func setup_bar(bar: TextureProgressBar, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value
	bar.tooltip_text = "%s %d / %d" % [BAR_NAMES[bar.name], value, max_value]


func on_health_changed(new_health: int, max_health: int) -> void:
	setup_bar(health_bar, new_health, max_health)


func on_stamina_changed(new_stamina: int, max_stamina: int) -> void:
	setup_bar(stamina_bar, new_stamina, max_stamina)


func on_hunger_changed(new_hunger: int, max_hunger: int) -> void:
	setup_bar(hunger_bar, new_hunger, max_hunger)


func on_thirst_changed(new_thirst: int, max_thirst: int) -> void:
	setup_bar(thirst_bar, new_thirst, max_thirst)


func on_gold_changed(new_gold: int) -> void:
	gold_label.text = str(new_gold)
