extends PanelContainer

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: TextureProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var hunger_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HungerBar
@onready var thirst_bar: TextureProgressBar = $MarginContainer/VBoxContainer/ThirstBar

@onready var gold_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/GoldLabel

@export var player_stats: BaseCharacterStats

func _ready() -> void:
	bind_stats(player_stats)

func bind_stats(stats: BaseCharacterStats) -> void:
	if stats == null:
		return

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


func setup_bar(bar: TextureProgressBar, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value


func on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health


func on_stamina_changed(new_stamina: int, max_stamina: int) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = new_stamina


func on_hunger_changed(new_hunger: int, max_hunger: int) -> void:
	hunger_bar.max_value = max_hunger
	hunger_bar.value = new_hunger


func on_thirst_changed(new_thirst: int, max_thirst: int) -> void:
	thirst_bar.max_value = max_thirst
	thirst_bar.value = new_thirst


func on_gold_changed(new_gold: int) -> void:
	gold_label.text = str(new_gold)
