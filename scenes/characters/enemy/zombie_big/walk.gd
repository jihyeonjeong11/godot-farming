extends ApoNodeState

@onready var detection_component: DetectionComponent = $"../../DetectionComponent"

@export var zombie: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var navigation_agent_2d: NavigationAgent2D
@export var hit_component_collision_shape: CollisionShape2D
@export var min_speed: float = 8.0
@export var max_speed: float = 16.0

var speed: float


func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(on_safe_velocity_computed)


## 네비게이션 맵 위의 임의 지점을 다음 목적지로 잡는다.
func set_movement_target() -> void:
	var target_position: Vector2 = NavigationServer2D.map_get_random_point(
		navigation_agent_2d.get_navigation_map(),
		navigation_agent_2d.navigation_layers,
		false
	)
	navigation_agent_2d.target_position = target_position
	speed = randf_range(min_speed, max_speed)


func _on_physics_process(_delta: float) -> void:
	if navigation_agent_2d.is_navigation_finished():
		zombie.current_walk_cycle += 1
		set_movement_target()
		return

	var target_position: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_direction: Vector2 = zombie.global_position.direction_to(target_position)

	if absf(target_direction.x) > absf(target_direction.y):
		zombie.npc_direction = Vector2.RIGHT if target_direction.x > 0.0 else Vector2.LEFT
	else:
		zombie.npc_direction = Vector2.DOWN if target_direction.y > 0.0 else Vector2.UP

	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play("walk_back")
		hit_component_collision_shape.position = Vector2(0, -12)
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play("walk_right")
		hit_component_collision_shape.position = Vector2(12, 0)
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play("walk_front")
		hit_component_collision_shape.position = Vector2(0, 12)
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("walk_left")
		hit_component_collision_shape.position = Vector2(-12, 0)

	var new_velocity: Vector2 = target_direction * speed

	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.velocity = new_velocity
	else:
		zombie.velocity = new_velocity
		zombie.move_and_slide()


func on_safe_velocity_computed(safe_velocity: Vector2) -> void:
	if zombie.is_dead:
		return

	zombie.velocity = safe_velocity
	zombie.move_and_slide()


func _on_next_transitions() -> void:
	
	if detection_component.is_player_in_range():
		transition.emit("chase")
		return
	
	if zombie.current_walk_cycle >= zombie.walk_cycles:
		zombie.velocity = Vector2.ZERO
		transition.emit("idle")


func _on_enter() -> void:
	zombie.current_walk_cycle = 0
	zombie.walk_cycles = randi_range(zombie.min_walk_cycle, zombie.max_walk_cycle)
	set_movement_target()


func _on_exit() -> void:
	animated_sprite_2d.stop()
