extends NodeState

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var hit_component_collision_shape: CollisionShape2D = $"../../HitComponent/ZombieHitComponent"

## 히트박스를 바라보는 쪽으로 얼마나 내밀지.
@export var hit_reach: float = 14.0
## 팔이 뻗는 구간. 이 프레임 동안에만 히트박스를 연다.
@export var hit_start_frame: int = 2
@export var hit_end_frame: int = 4

var is_attack_finished: bool = false
var is_hitbox_open: bool = false


func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(on_animation_finished)


func _on_enter() -> void:
	is_attack_finished = false
	is_hitbox_open = false

	## 휘두르기 직전에 한 번만 플레이어 쪽을 본다. 도중에는 방향을 바꾸지 않는다.
	var player: Player = detection_component.get_player()
	if player != null:
		zombie.face_towards(zombie.global_position.direction_to(player.global_position))

	hit_component_collision_shape.position = zombie.npc_direction * hit_reach
	play_attack_animation()

	zombie.velocity = Vector2.ZERO
	zombie.start_attack_cooldown()


func _on_physics_process(_delta: float) -> void:
	zombie.velocity = Vector2.ZERO
	zombie.move_and_slide()

	var frame: int = animated_sprite_2d.frame
	set_hitbox_open(frame >= hit_start_frame and frame <= hit_end_frame)


## disabled 를 매 프레임 set_deferred 하면 헛돈다. 바뀔 때만 건드린다.
func set_hitbox_open(open: bool) -> void:
	if open == is_hitbox_open:
		return

	is_hitbox_open = open
	hit_component_collision_shape.set_deferred("disabled", not open)


func play_attack_animation() -> void:
	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play("attack_back")
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play("attack_right")
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play("attack_front")
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("attack_left")
	else:
		animated_sprite_2d.play("attack_front")


func _on_next_transitions() -> void:
	if not is_attack_finished:
		return

	if detection_component.is_player_in_range():
		transition.emit("chase")
	else:
		transition.emit("idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	set_hitbox_open(false)


func on_animation_finished() -> void:
	is_attack_finished = true
