extends "res://scenes/characters/enemy/zombie/zombie.gd"

@export var flip_threshold: float = 0.2


func _init() -> void:
	npc_direction = Vector2.RIGHT


func face_towards(direction: Vector2) -> void:
	if absf(direction.x) < flip_threshold:
		return

	npc_direction = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	animated_sprite_2d.scale.x = -1.0 if npc_direction == Vector2.LEFT else 1.0


func on_hurt(hit_damage: int) -> void:
	super(hit_damage)

	if not is_dead:
		animated_sprite_2d.play("hurt")
