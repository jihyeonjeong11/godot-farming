extends NodeState

@export var player: Player
@export var action: String = ""

@export var use_tool_on_finish: bool = false

@export var duration: float = 0.0


func _on_enter() -> void:
	
	player.play_action(action if not action.is_empty() else player.attack_action(), duration)


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	if not player.is_action_playing():
		if use_tool_on_finish:
			player.finish_tool_use()

		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()
