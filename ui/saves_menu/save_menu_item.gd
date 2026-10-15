extends Control

@onready var player: Player = $HBoxContainer/PlayerContainer/Player
@onready var player_container: PanelContainer = $HBoxContainer/PlayerContainer

func _ready() -> void:
	if player and player.is_freeze == false:
		player.is_freeze = true
