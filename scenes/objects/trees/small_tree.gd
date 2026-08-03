extends Sprite2D

@onready var hurt_component: ApoHurtComponent = $HurtComponent
@onready var damage_component: ApoDamageComponent = $DamageComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var log_scene = preload("res://scenes/objects/trees/log.tscn")

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damage_reached)
	animated_sprite_2d.hide()

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 1.0)
	await get_tree().create_timer(0.3).timeout
	material.set_shader_parameter("shake_intensity", 0.0)

func on_max_damage_reached() -> void:
	animated_sprite_2d.show()
	animated_sprite_2d.play("default")
	await animated_sprite_2d.animation_finished
	add_log_scene.call_deferred()
	queue_free()

func add_log_scene() -> void:
	var log_instance = log_scene.instantiate() as Node2D
	get_parent().add_child(log_instance)
	log_instance.global_position = global_position
