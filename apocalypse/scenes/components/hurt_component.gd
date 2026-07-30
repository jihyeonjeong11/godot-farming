class_name ApoHurtComponent
extends Area2D

@export var tool: ApoDataTypes.Tools = ApoDataTypes.Tools.None

signal hurt(hit_damage: int)

func _on_area_entered(area: Area2D) -> void:
	var hit_component = area as ApoHitComponent

	if hit_component == null:
		return

	if tool == hit_component.current_tool:
		hurt.emit(hit_component.hit_damage)
