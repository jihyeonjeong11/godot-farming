extends NodeState

@export var player: Player
@export var action: String = "hurt"


func _on_enter() -> void:
	player.velocity = Vector2.ZERO
	player.play_action(action)


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()
