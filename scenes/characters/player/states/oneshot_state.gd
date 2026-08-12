extends ApoNodeState
## 한 번 재생하고 끝나면 Idle로 돌아가는 상태.
##
## Attack / Hurt / Jump / Emote가 이 스크립트를 공유한다. 노드마다 action만 다르게 넣는다.
## 재생할 클립은 SpriteFrames에서 loop가 꺼져 있어야 끝을 판정할 수 있다.

@export var player: ApoPlayerNew
## 비워두면 들고 있는 툴이 클립을 정한다(Attack). 채워두면 그 클립으로 고정된다.
@export var action: String = ""


func _on_enter() -> void:
	player.play_action(action if not action.is_empty() else player.attack_action())


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	if not player.is_action_playing():
		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()
