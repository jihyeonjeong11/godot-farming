extends Node2D

signal finished

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:

	animation_player.play(&"appear_logo")
	await animation_player.animation_finished

	await get_tree().create_timer(0.3).timeout

	finished.emit()
