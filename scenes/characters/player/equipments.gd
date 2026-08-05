extends AnimatedSprite2D

@onready var player: ApoPlayer = $".."

const AXE_IDLE: Dictionary = {
	Vector2.UP: &"axe_idle_back",
	Vector2.DOWN: &"axe_idle_front",
	Vector2.LEFT: &"axe_idle_left",
	Vector2.RIGHT: &"axe_idle_right",
}


func _physics_process(_delta: float) -> void:
	# 공격 애니메이션은 attack state가 소유한다. state가 _on_exit에서 반납할 때까지 손대지 않는다.
	# (is_playing()으로 판단하면, 재생이 끝난 프레임에 이 노드가 먼저 처리되어 idle을 덮어써
	#  attack state의 !is_playing() 종료 조건이 성립하지 않는다.)
	if String(animation).contains("attack"):
		return

	var next: StringName = AXE_IDLE.get(player.player_direction, &"")
	if next != &"":
		play(next)
