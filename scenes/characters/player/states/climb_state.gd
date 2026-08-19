extends NodeState
## 사다리 오르기. 시트에 climb은 뒷모습 한 방향뿐이라 play_action이 접미사 없이 떨어뜨린다.
## 루프 클립이므로 climb을 다시 누를 때까지 계속 돈다.

@export var player: Player


func _on_enter() -> void:
	player.direction_component.set_facing(Vector2.UP)
	player.play_action("climb")


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	if player.key_just_pressed("climb"):
		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()
