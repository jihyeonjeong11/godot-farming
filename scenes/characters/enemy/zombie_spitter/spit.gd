extends NodeState

## 멈춰서 몸을 번쩍이며 부풀린 뒤(예고), 팔을 휘두르는 프레임에 산성 덩어리를 뱉는다.

const ACID_SPIT := preload("res://scenes/characters/enemy/zombie_spitter/acid_spit.tscn")

@onready var zombie: CharacterBody2D = $"../.."
@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../AnimatedSprite2D"

## 뱉기 전에 멈춰 번쩍이는 시간. 플레이어가 보고 피할 틈이다.
@export var windup_time: float = 0.6
@export var windup_color: Color = Color(0.6, 1.0, 0.3)
## 공격 애니메이션의 이 프레임에서 뱉는다.
@export var release_frame: int = 2
## 발밑 기준 입 위치.
@export var mouth_offset: Vector2 = Vector2(0, -20)

var elapsed: float = 0.0
var is_winding: bool = false
var has_fired: bool = false
var is_finished: bool = false
var base_modulate: Color


func _ready() -> void:
	animated_sprite_2d.animation_finished.connect(on_animation_finished)


func _on_enter() -> void:
	elapsed = 0.0
	is_winding = true
	has_fired = false
	is_finished = false

	var player: Player = detection_component.get_player()
	if player != null:
		zombie.face_towards(zombie.global_position.direction_to(player.global_position))

	## 예고 동안은 공격 첫 프레임에 멈춰 있는다.
	animated_sprite_2d.stop()
	animated_sprite_2d.animation = attack_animation()
	animated_sprite_2d.frame = 0
	base_modulate = animated_sprite_2d.modulate

	zombie.velocity = Vector2.ZERO
	zombie.start_attack_cooldown()


func _on_physics_process(delta: float) -> void:
	zombie.velocity = Vector2.ZERO
	zombie.move_and_slide()

	if is_winding:
		elapsed += delta
		var pulse: float = (sin(elapsed * 30.0) + 1.0) * 0.5
		animated_sprite_2d.modulate = base_modulate.lerp(windup_color, pulse)
		if elapsed >= windup_time:
			is_winding = false
			animated_sprite_2d.modulate = base_modulate
			animated_sprite_2d.play()
		return

	if not has_fired and animated_sprite_2d.frame >= release_frame:
		fire()


## 노리는 곳은 뱉는 순간의 플레이어 자리다. 날아가는 동안 그림자를 보고 비켜서면 피한다.
func fire() -> void:
	has_fired = true

	var player: Player = detection_component.get_player()
	var host := zombie.get_parent()
	if player == null or host == null:
		return

	var spit = ACID_SPIT.instantiate()
	host.add_child(spit)
	spit.launch(zombie.global_position + mouth_offset, player.global_position)


func attack_animation() -> StringName:
	if zombie.npc_direction == Vector2.UP:
		return &"attack_back"
	elif zombie.npc_direction == Vector2.RIGHT:
		return &"attack_right"
	elif zombie.npc_direction == Vector2.LEFT:
		return &"attack_left"
	return &"attack_front"


func _on_next_transitions() -> void:
	if not is_finished:
		return

	if detection_component.is_player_in_range():
		transition.emit("chase")
	else:
		transition.emit("idle")


func _on_exit() -> void:
	animated_sprite_2d.stop()
	animated_sprite_2d.modulate = base_modulate


func on_animation_finished() -> void:
	if not is_winding:
		is_finished = true
