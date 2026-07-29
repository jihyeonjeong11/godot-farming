extends ApoNodeState

@export var player: ApoPlayer
@export var animated_sprite_2d: AnimatedSprite2D
@export var equipment_sprite_2d: AnimatedSprite2D

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	if !equipment_sprite_2d.is_playing():
		transition.emit("Idle")


func _on_enter() -> void:
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
		equipment_sprite_2d.play("bat_attack_back")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
		equipment_sprite_2d.play("bat_attack_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
		equipment_sprite_2d.play("bat_attack_left")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")
		equipment_sprite_2d.play("bat_attack_right")
	else:
		animated_sprite_2d.play("idle_front")
		equipment_sprite_2d.play("bat_attack_front")


func _on_exit() -> void:
	equipment_sprite_2d.play("bat_idle_front")
