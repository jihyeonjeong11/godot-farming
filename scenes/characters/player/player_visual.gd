class_name PlayerVisual
extends Control

@onready var body: AnimatedSprite2D = $Body


func _ready() -> void:
	for layer in body.get_children():
		if layer.has_method("sync"):
			layer.sync(body.animation, body.frame)
