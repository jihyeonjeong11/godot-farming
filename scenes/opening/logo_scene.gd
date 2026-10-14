extends Node2D

signal finished

@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	
	animation_player.play(&"appear_logo")
	await animation_player.animation_finished
	
	#finished.emit()


func _process(delta: float) -> void:
	pass
