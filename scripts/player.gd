class_name ApoPlayer
extends CharacterBody2D

@export var current_tool: ApoDataTypes.Tools = ApoDataTypes.Tools.None
@onready var hurt_component: ApoHurtComponent = $HurtComponent

@export var stats: Stats

var player_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	Inventory.set_player_reference(self)
	hurt_component.hurt.connect(on_hurt)
	stats.no_health.connect(die)

func die() -> void:
	print('player dead')
	queue_free()
	

func on_hurt(hit_damage: int) -> void:
	stats.health -= hit_damage
