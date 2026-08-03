extends ApoNodeState

@export var chase_speed: float = 24.0

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var navigation_agent_2d: NavigationAgent2D = $"../../NavigationAgent2D"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hit_component_collision_shape: CollisionShape2D = $"../../HitComponent/ZombieHitComponent"


var player: ApoPlayer


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

	## 8방향 이동을 상하좌우 4방향 애니메이션으로 뭉갠다. 성분이 큰 축을 따른다.
	if absf(target_direction.x) > absf(target_direction.y):
		zombie.npc_direction = Vector2.RIGHT if target_direction.x > 0.0 else Vector2.LEFT
	else:
		zombie.npc_direction = Vector2.DOWN if target_direction.y > 0.0 else Vector2.UP

	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
		hit_component_collision_shape.position = Vector2(0, -8)
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
		hit_component_collision_shape.position = Vector2(8, 0)
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
		hit_component_collision_shape.position = Vector2(0, 8)
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")
		hit_component_collision_shape.position = Vector2(-8, 0)

	zombie.velocity = target_direction * chase_speed
	zombie.move_and_slide()


func _on_next_transitions() -> void:
	
	if player == null:
		transition.emit("idle")
		return

	var distance_to_player: float = detection_component.global_position.distance_to(player.global_position)
	if distance_to_player > detection_component.max_detection_range:
		zombie.velocity = Vector2.ZERO
		transition.emit("idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	player = null
