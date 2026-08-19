extends NodeState

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"

@export var friction: float = 500.0


func _on_physics_process(delta: float) -> void:
	zombie.velocity = zombie.knockback
	zombie.move_and_slide()

	zombie.knockback = zombie.knockback.move_toward(Vector2.ZERO, friction * delta)


func _on_next_transitions() -> void:
	if zombie.knockback != Vector2.ZERO:
		return

	if detection_component.is_player_in_range():
		transition.emit("chase")
	else:
		transition.emit("idle")


func _on_enter() -> void:
	animated_sprite_2d.stop()


func _on_exit() -> void:
	zombie.knockback = Vector2.ZERO
	zombie.velocity = Vector2.ZERO
