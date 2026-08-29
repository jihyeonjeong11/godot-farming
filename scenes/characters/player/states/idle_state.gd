extends NodeState
## 가만히 서 있는 상태. 나머지 상태로 들어가는 관문 역할을 한다.

@export var player: Player


func _on_enter() -> void:
	player.play_action("idle")


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()

	if GameInputEvents.use_tool():
		transition.emit("Attack")
	elif player.key_just_pressed("jump"):
		transition.emit("Jump")
	elif player.key_just_pressed("emote"):
		transition.emit("Emote")
	elif player.key_just_pressed("sit"):
		transition.emit("Sit")
	elif player.key_just_pressed("climb"):
		transition.emit("Climb")
	elif GameInputEvents.is_movement_input():
		transition.emit("Walk")
