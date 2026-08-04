class_name ApoCollectableComponent
extends Area2D

@export var collectable_name: String

func _on_body_entered(body: Node2D) -> void:
	if body is ApoPlayer:
		print("collected: ", collectable_name)
		
		get_parent().queue_free()
