extends NodeState


@export var player: Player
@export var duration: float = 0.0

var _timed: bool = false
var _remaining: float = 0.0


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

	player.set_hitbox_active(player.has_melee_shape())


func _on_physics_process(delta: float) -> void:
	if _timed:
		_remaining -= delta

	player.velocity = Vector2.ZERO
	player.move_and_slide()


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
