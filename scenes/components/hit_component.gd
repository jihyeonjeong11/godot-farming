class_name HitComponent
extends Area2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var hit_damage: int = 1

@export var knockback_vector: Vector2 = Vector2.ZERO
