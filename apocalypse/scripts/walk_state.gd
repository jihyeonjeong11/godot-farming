extends ApoNodeState

@export var player: ApoPlayer
@export var animated_sprite_2d: AnimatedSprite2D
@export var equipment_sprite_2d: AnimatedSprite2D
@export var hit_component_collision_shape: CollisionShape2D
@export var speed: int = 50

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	var direction: Vector2 = ApoGameInputEvents.movement_input()

	if direction != Vector2.ZERO:
		player.player_direction = direction

	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
		equipment_sprite_2d.play("bat_idle_back")
		hit_component_collision_shape.position = Vector2(0, -11)
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
		equipment_sprite_2d.play("bat_idle_right")
		hit_component_collision_shape.position = Vector2(9, 0)
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
		equipment_sprite_2d.play("bat_idle_front")
		hit_component_collision_shape.position = Vector2(0, 10)
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")
		equipment_sprite_2d.play("bat_idle_left")
		hit_component_collision_shape.position = Vector2(-9, 0)

	player.velocity = direction * speed
	player.move_and_slide()


func _on_next_transitions() -> void:
	if !ApoGameInputEvents.is_movement_input():
		transition.emit("idle")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	animated_sprite_2d.stop()
	equipment_sprite_2d.stop()
