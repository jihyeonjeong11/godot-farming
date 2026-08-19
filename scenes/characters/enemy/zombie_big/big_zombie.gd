extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent
@onready var die_audio_stream_player: AudioStreamPlayer2D = $DieAudioStreamPlayer
@onready var hit_component: HitComponent = $HitComponent
@onready var state_machine: NodeStateMachine = $StateMachine

@export var stats: Stats

@export var min_walk_cycle: int = 2
@export var max_walk_cycle: int = 6

@export var min_range = 8
@export var max_range = 100

var walk_cycles: int
var current_walk_cycle: int

@export var knockback_speed: float = 120.0

var npc_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

var knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	stats = stats.duplicate()
	hit_component.hit_damage = stats.base_damage
	hurt_component.hurt.connect(on_hurt)
	stats.no_health.connect(die)

	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)


func on_hurt(hit_damage: int) -> void:
	stats.health -= hit_damage

	if is_dead:
		return

	knockback = hurt_component.last_knockback_direction * knockback_speed
	state_machine.transition_to("hit")


func die() -> void:
	is_dead = true
	
	state_machine.set_process(false)
	state_machine.set_physics_process(false)
	velocity = Vector2.ZERO

	hurt_component.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)

	animated_sprite_2d.flip_h = false
	animated_sprite_2d.play("die")
	die_audio_stream_player.play()

	await animated_sprite_2d.animation_finished
	if die_audio_stream_player.playing:
		await die_audio_stream_player.finished

	queue_free()
