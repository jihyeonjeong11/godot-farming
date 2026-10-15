class_name Title
extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	hide()


func appear() -> void:
	animation_player.play(&"appear")
	animation_player.queue(&"shine")
