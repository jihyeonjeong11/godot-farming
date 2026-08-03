extends ApoNodeState

@onready var detection_component: DetectionComponent = $"../../DetectionComponent"
@onready var hurt_component: ApoHurtComponent = $"../../HurtComponent"

@export var zombie: CharacterBody2D
@export var animated_sprite_2d: AnimatedSprite2D
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

@onready var idle_state_timer: Timer = Timer.new()

var idle_state_timeout: bool = false


func _ready() -> void:
	idle_state_timer.one_shot = true
	idle_state_timer.timeout.connect(on_idle_state_timeout)
	add_child(idle_state_timer)


func _on_physics_process(_delta: float) -> void:
	zombie.velocity = Vector2.ZERO
	zombie.move_and_slide()


func _on_next_transitions() -> void:
		
	if detection_component.is_player_in_range():
		transition.emit("chase")
		return
		
	if idle_state_timeout:
		transition.emit("walk")


func _on_enter() -> void:
	if zombie.npc_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif zombie.npc_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")
	elif zombie.npc_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif zombie.npc_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	else:
		animated_sprite_2d.play("idle_front")

	idle_state_timeout = false
	idle_state_timer.start(randf_range(min_idle_time, max_idle_time))


func _on_exit() -> void:
	animated_sprite_2d.stop()
	idle_state_timer.stop()


func on_idle_state_timeout() -> void:
	idle_state_timeout = true
