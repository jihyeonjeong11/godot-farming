extends NodeState


@export var player: Player
@export var duration: float = 0.0


func _on_enter() -> void:
	player.play_action(player.attack_action(), duration)
	player.set_hitbox_active(player.has_melee_shape())


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	if not player.is_action_playing():
		player.finish_tool_use()
		transition.emit("Idle")

func _on_exit() -> void:
	player.set_hitbox_active(false)
	player.stop_action()
