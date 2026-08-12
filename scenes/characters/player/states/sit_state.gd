extends ApoNodeState
## 앉기. sit 클립은 앉는 동작 3프레임짜리라, 끝나면 마지막 프레임에서 멈춰 자세가 유지된다.
## 다시 sit을 누르거나 움직이면 일어난다.

@export var player: ApoPlayerNew


func _on_enter() -> void:
	player.play_action("sit")


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	ApoGameInputEvents.movement_input()

	if player.key_just_pressed("sit") or ApoGameInputEvents.is_movement_input():
		transition.emit("Idle")
