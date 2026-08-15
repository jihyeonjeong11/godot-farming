extends ApoNodeState
## 한 번 재생하고 끝나면 Idle로 돌아가는 상태.
##
## Attack / Hurt / Jump / Emote가 이 스크립트를 공유한다. 노드마다 action만 다르게 넣는다.
## 재생할 클립은 SpriteFrames에서 loop가 꺼져 있어야 끝을 판정할 수 있다.

@export var player: ApoPlayerNew
## 비워두면 들고 있는 툴이 클립을 정한다(Attack). 채워두면 그 클립으로 고정된다.
@export var action: String = ""

## 재생이 끝난 뒤 도구 사용을 월드에 알린다. Attack만 켠다.
## Hurt·Jump·Emote는 월드를 건드리지 않으므로 꺼둔 채로 같은 스크립트를 쓴다.
@export var use_tool_on_finish: bool = false

## 이 길이(초)에 맞춰 재생한다. 0이면 시트 속도 그대로.
## 툴마다 프레임 수가 달라서 안 맞추면 도끼가 맨손보다 굼뜨게 느껴진다.
@export var duration: float = 0.0


func _on_enter() -> void:
	player.play_action(action if not action.is_empty() else player.attack_action(), duration)


func _on_physics_process(_delta: float) -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _on_next_transitions() -> void:
	if not player.is_action_playing():
		# Idle로 넘기기 전에 알린다. 넘긴 뒤면 이 프레임에 Idle이 다시 use_tool을
		# 읽어서 곧바로 Attack으로 되돌아가는 일이 생긴다.
		if use_tool_on_finish:
			player.finish_tool_use()

		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()
