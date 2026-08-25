class_name HurtComponent
extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_audio_stream_player: AudioStreamPlayer2D = $HitAudioStreamPlayer
@export var tool: DataTypes.Tools = DataTypes.Tools.None
@export var stats: BaseCharacterStats

signal hurt(hit_damage: int)

var last_knockback_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	animated_sprite_2d.visible = false
	animated_sprite_2d.animation_finished.connect(on_hit_effect_finished)


func _on_area_entered(area: Area2D) -> void:
	var hit_component = area as HitComponent
	
	if hit_component.owner == owner:
		return

	if hit_component == null:
		return

	if tool == hit_component.current_tool:
		play_hit_effect()
		last_knockback_direction = get_knockback_direction(hit_component)
		hurt.emit(hit_component.hit_damage)

func get_knockback_direction(hit_component: HitComponent) -> Vector2:
	if hit_component.knockback_vector != Vector2.ZERO:
		return hit_component.knockback_vector.normalized()

	return hit_component.global_position.direction_to(global_position)

func play_hit_effect() -> void:
	animated_sprite_2d.visible = true
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play("default")
	hit_audio_stream_player.play()

func on_hit_effect_finished() -> void:
	animated_sprite_2d.visible = false
	
