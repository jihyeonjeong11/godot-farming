extends NodeState


@export var player: Player
@export var duration: float = 0.0
## 히트박스를 여는 진행률(0~1). 휘두르기 끝머리에 맞게 한다.
@export_range(0.0, 1.0) var hit_at: float = 0.7

var _timed: bool = false
var _remaining: float = 0.0
var _hitbox_open: bool = false


func _on_enter() -> void:
	## TODO: needs refactor for watering can ammo
	print("ammo=", player.has_ammo(), " water=", player.is_mouse_on_water())

	if player.is_ranged():
		player.fire_ranged()
	elif player.is_melee_slash():
		player.play_slash_effect(duration)

	var action := player.attack_action()
	_timed = not player.has_action_clip(action)
	_remaining = duration

	if not _timed:
		player.play_action(action, duration)

	_hitbox_open = false
	player.set_hitbox_active(false)


func _on_physics_process(delta: float) -> void:
	if _timed:
		_remaining -= delta

	if not _hitbox_open and player.has_melee_shape() and _progress() >= hit_at:
		_hitbox_open = true
		player.set_hitbox_active(true)

	player.velocity = Vector2.ZERO
	player.move_and_slide()


func _progress() -> float:
	if _timed:
		return 1.0 - _remaining / duration if duration > 0.0 else 1.0
	return player.action_progress()


func _on_next_transitions() -> void:
	if _timed:
		if _remaining > 0.0:
			return
	elif player.is_action_playing():
		return

	player.finish_tool_use()
	transition.emit("Idle")

func _on_exit() -> void:
	player.set_hitbox_active(false)
	player.stop_action()
