extends "res://scenes/characters/enemy/zombie/chase.gd"


func play_walk_animation() -> void:
	if zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("run_left")
	else:
		animated_sprite_2d.play("run_right")
