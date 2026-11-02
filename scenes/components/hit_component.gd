class_name HitComponent
extends Area2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@export var hit_damage: int = 1

@export var knockback_vector: Vector2 = Vector2.ZERO
@export var max_hits: int = 0
@export var resolve_by_distance: bool = false

var hit_count: int = 0
var _hit_targets: Array[Area2D] = []


func reset_hits(limit: int) -> void:
	max_hits = limit
	hit_count = 0
	_hit_targets.clear()


func can_hit() -> bool:
	return max_hits <= 0 or hit_count < max_hits


func register_hit() -> void:
	hit_count += 1
	if can_hit():
		return
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)


func _physics_process(_delta: float) -> void:
	if not resolve_by_distance or not can_hit():
		return
	var origin: Vector2 = owner.global_position if owner is Node2D else global_position
	var candidates: Array[HurtComponent] = []
	for area in get_overlapping_areas():
		var hurt := area as HurtComponent
		if hurt != null and hurt.owner != owner and not _hit_targets.has(hurt):
			candidates.append(hurt)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: HurtComponent, b: HurtComponent) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	for hurt in candidates:
		if not can_hit():
			return
		_hit_targets.append(hurt)
		if hurt.receive_hit(current_tool, hit_damage, hurt.get_knockback_direction(self)):
			register_hit()
