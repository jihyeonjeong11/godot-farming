extends CharacterBody2D

@onready var hurt_component: ApoHurtComponent = $HurtComponent
@onready var damage_component: ApoDamageComponent = $DamageComponent

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damage_reached)

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)

func on_max_damage_reached() -> void:
	print("small zombie died")
	queue_free()
