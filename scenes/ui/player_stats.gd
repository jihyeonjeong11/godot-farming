extends PanelContainer

@export var player_stats: Stats

@onready var texture_progress_bar: TextureProgressBar = $MarginContainer/TextureProgressBar

func _ready() -> void:
	texture_progress_bar.max_value = player_stats.max_health
	texture_progress_bar.value = player_stats.health

	player_stats.health_changed.connect(on_health_changed)


func on_health_changed(new_health: int) -> void:
	texture_progress_bar.value = new_health
