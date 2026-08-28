extends NodeState

@export var chase_speed: float = 24.0

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var navigation_agent_2d: NavigationAgent2D = $"../../NavigationAgent2D"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"

var player: Player


func _on_enter() -> void:
	player = detection_component.get_player()


func _on_physics_process(_delta: float) -> void:
	if player == null:
		return

	navigation_agent_2d.target_position = player.global_position

	if navigation_agent_2d.is_navigation_finished():
		zombie.velocity = Vector2.ZERO
		zombie.move_and_slide()
		return

	var next_position: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_direction: Vector2 = zombie.global_position.direction_to(next_position)

	zombie.face_towards(target_direction)
	play_walk_animation()

	zombie.velocity = target_direction * chase_speed
	zombie.move_and_slide()


func play_walk_animation() -> void:
	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")


func _on_next_transitions() -> void:

	if player == null:
		transition.emit("idle")
		return

	## 사거리 안에 들어오고 쿨다운이 끝났으면 바로 휘두른다.
	if zombie.attack_ready:
		var distance_to_target: float = zombie.global_position.distance_to(player.global_position)
		if distance_to_target <= zombie.attack_range:
			zombie.velocity = Vector2.ZERO
			transition.emit("attack")
			return

	var distance_to_player: float = detection_component.global_position.distance_to(player.global_position)
	if distance_to_player > detection_component.max_detection_range:
		zombie.velocity = Vector2.ZERO
		transition.emit("idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	player = null
