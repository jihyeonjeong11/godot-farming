extends PanelContainer

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var stamina_bar: TextureProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var hunger_bar: TextureProgressBar = $MarginContainer/VBoxContainer/HungerBar
@onready var thirst_bar: TextureProgressBar = $MarginContainer/VBoxContainer/ThirstBar

var player_stats: Stats


## 플레이어가 사본을 만든 뒤에야 볼 값이 정해진다. 어느 쪽 _ready가 먼저 돌지
## 모르므로, 아직이면 시그널을 기다리고 이미 끝났으면 그 자리에서 붙는다.
func _ready() -> void:
	SignalBus.player_stats_ready.connect(bind_stats)

	if SignalBus.player_stats != null:
		bind_stats(SignalBus.player_stats)


func bind_stats(stats: Stats) -> void:
	if stats == null or stats == player_stats:
		return

	player_stats = stats

	setup_bar(health_bar, stats.health, stats.max_health)
	setup_bar(stamina_bar, stats.stamina, stats.max_stamina)
	setup_bar(hunger_bar, stats.hunger, stats.max_hunger)
	setup_bar(thirst_bar, stats.thirst, stats.max_thirst)

	stats.health_changed.connect(on_health_changed)
	stats.stamina_changed.connect(on_stamina_changed)
	stats.hunger_changed.connect(on_hunger_changed)
	stats.thirst_changed.connect(on_thirst_changed)


func setup_bar(bar: TextureProgressBar, value: int, max_value: int) -> void:
	bar.max_value = max_value
	bar.value = value


func on_health_changed(new_health: int) -> void:
	health_bar.value = new_health


func on_stamina_changed(new_stamina: int) -> void:
	stamina_bar.value = new_stamina


func on_hunger_changed(new_hunger: int) -> void:
	hunger_bar.value = new_hunger


func on_thirst_changed(new_thirst: int) -> void:
	thirst_bar.value = new_thirst
