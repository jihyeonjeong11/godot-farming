extends ApoNodeState
## 걷기와 달리기. run 입력에 따라 클립과 속도를 같이 바꾼다.

@export var player: ApoPlayerNew

var _running: bool = false


func _on_enter() -> void:
	_running = player.key_held("run")
	_play()


func _on_physics_process(_delta: float) -> void:
	var direction := ApoGameInputEvents.movement_input()
	var running := player.key_held("run")

	if direction != Vector2.ZERO:
		# 재생할 클립이 실제로 바뀔 때만 play()를 부른다.
		var turned := direction != player.facing
		player.face(direction)
		if turned or running != _running:
			_running = running
			_play()

	player.velocity = direction * (player.run_speed if _running else player.walk_speed)
	player.move_and_slide()


func _on_next_transitions() -> void:
	if ApoGameInputEvents.use_tool():
		transition.emit("Attack")
	elif not ApoGameInputEvents.is_movement_input():
		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()


func _play() -> void:
	player.play_action("run" if _running else "walk")
