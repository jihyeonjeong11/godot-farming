extends NodeState

@export var player: Player
## 발소리 간격(초). 뛰면 보폭이 빨라지니 더 짧게.
const FOOTSTEP_INTERVAL_WALK := 0.42
const FOOTSTEP_INTERVAL_RUN := 0.28

## 지형별 발소리. 도로(아스팔트)와 인도/실내 바닥(콘크리트)은 같은 딱딱한 소리로 묶는다.
const FOOTSTEP_BY_TERRAIN := {
	Player.TERRAIN_GRASS: AudioManager.SFX_FOOTSTEP_GRASS,
	Player.TERRAIN_CONCRETE: AudioManager.SFX_FOOTSTEP_CONCRETE,
	Player.TERRAIN_ASPHALT: AudioManager.SFX_FOOTSTEP_CONCRETE,
}

var _running: bool = false
var _footstep_timer: float = 0.0


func _on_enter() -> void:
	_running = player.key_held("run")
	_footstep_timer = 0.0   # 걷기 시작하자마자 첫 발소리가 나도록
	_play()


func _on_physics_process(delta: float) -> void:
	var direction := GameInputEvents.movement_input()
	var running := player.key_held("run")

	if direction != Vector2.ZERO:
		# 재생할 클립이 실제로 바뀔 때만 play()를 부른다.
		var turned := direction != player.direction_component.get_facing()
		player.direction_component.set_facing(direction)
		if turned or running != _running:
			_running = running
			_play()

	player.velocity = direction * player.get_move_speed(_running)
	player.move_and_slide()

	if direction != Vector2.ZERO:
		_tick_footstep(delta)


func _on_next_transitions() -> void:
	if GameInputEvents.use_tool() and player.can_attack():
		transition.emit("Attack")
	elif not GameInputEvents.is_movement_input():
		transition.emit("Idle")


func _on_exit() -> void:
	player.stop_action()


## 매 프레임 쏘면 SFX 풀(4개)이 바로 포화되고 소리도 뭉갠다. 보폭 간격으로만 낸다.
func _tick_footstep(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	_footstep_timer = FOOTSTEP_INTERVAL_RUN if _running else FOOTSTEP_INTERVAL_WALK
	SignalBus.sound_requested.emit(_footstep_sound())


## 흙이든 지형이 안 잡힌 칸이든 표에 없는 나머지는 기본 발소리로 묶는다.
func _footstep_sound() -> String:
	var key: String = FOOTSTEP_BY_TERRAIN.get(player.get_terrain(), AudioManager.SFX_FOOTSTEP)
	return key


func _play() -> void:
	player.play_action("run" if _running else "walk")
