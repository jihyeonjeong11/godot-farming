extends NodeState

## 원거리형 추적. 붙으러 오지 않고 사거리 안에서 멈춰 뱉을 틈을 노린다.

@export var chase_speed: float = 22.0
@export var retreat_speed: float = 18.0
## 이 거리 안이면 멈춰서 뱉는다.
@export var spit_range: float = 140.0
## 이보다 가까우면 뒷걸음질 친다. 쿨다운 동안 거리를 다시 벌리기 위함이다.
@export var retreat_range: float = 56.0

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var navigation_agent_2d: NavigationAgent2D = $"../../NavigationAgent2D"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"

var player: Player
var sees_player: bool = false
var last_known_position: Vector2


func _on_enter() -> void:
	player = detection_component.get_player()
	if player != null:
		last_known_position = player.global_position
		sees_player = true


func _on_physics_process(_delta: float) -> void:
	if player == null:
		return

	sees_player = detection_component.is_player_in_range()
	if sees_player:
		last_known_position = player.global_position

	var distance: float = zombie.global_position.distance_to(player.global_position)
	var to_player: Vector2 = zombie.global_position.direction_to(player.global_position)

	## 뒷걸음질 칠 때도 얼굴은 플레이어 쪽을 본다.
	if sees_player and distance <= retreat_range:
		zombie.face_towards(to_player)
		play_animation("walk")
		zombie.velocity = -to_player * retreat_speed
		zombie.move_and_slide()
		return

	if sees_player and distance <= spit_range:
		zombie.face_towards(to_player)
		play_animation("idle")
		zombie.velocity = Vector2.ZERO
		zombie.move_and_slide()
		return

	navigation_agent_2d.target_position = last_known_position

	if navigation_agent_2d.is_navigation_finished():
		zombie.velocity = Vector2.ZERO
		zombie.move_and_slide()
		return

	var next_position: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_direction: Vector2 = zombie.global_position.direction_to(next_position)

	zombie.face_towards(target_direction)
	play_animation("walk")

	zombie.velocity = target_direction * chase_speed
	zombie.move_and_slide()


func play_animation(prefix: String) -> void:
	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play(prefix + "_back")
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play(prefix + "_right")
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play(prefix + "_front")
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play(prefix + "_left")


func _on_next_transitions() -> void:
	if player == null:
		transition.emit("idle")
		return

	if sees_player and zombie.attack_ready:
		var distance_to_target: float = zombie.global_position.distance_to(player.global_position)
		if distance_to_target <= spit_range:
			zombie.velocity = Vector2.ZERO
			transition.emit("attack")
			return

	if not sees_player and navigation_agent_2d.is_navigation_finished():
		zombie.velocity = Vector2.ZERO
		transition.emit("idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	player = null
