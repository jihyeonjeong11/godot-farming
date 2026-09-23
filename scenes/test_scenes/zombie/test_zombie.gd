extends AnimatedSprite2D

# detection 로직
# raycast2d 영역

# 해당 영역이 플레이어와 겹치면 추격행동 시작
# 플레이어의 노이즈 - 총을 쏘는 등의 행동을 하면 영역이 넓어짐
# 해당 영역이 벗어난 상태로 10초정도 보이지 않는다면 추격 중지함

@export var speed := 40.0

var facing := "down"
var acting := false


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)


func _process(delta: float) -> void:
	if acting:
		return
	var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if dir == Vector2.ZERO:
		play("idle_" + facing)
		return
	position += dir * speed * delta
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0 else "side"
	else:
		facing = "down" if dir.y > 0 else "up"
	play("walk_" + facing)


func _unhandled_input(event: InputEvent) -> void:
	if acting:
		return
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		_attack("spit")
	elif mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT or event.is_action_pressed("hit"):
		_attack("claw")


func _attack(anim: String) -> void:
	acting = true
	var aim := get_global_mouse_position() - global_position
	if absf(aim.x) > absf(aim.y):
		facing = "right" if aim.x > 0 else "side"
	else:
		facing = "down" if aim.y > 0 else "up"
	play(anim if facing == "side" else anim + "_" + facing)


func _on_animation_finished() -> void:
	acting = false
	play("idle_" + facing)
