@tool
class_name Building
extends Node2D

const GROUP := &"building"

@export var has_inside: bool = false
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var footprint_shape: CollisionShape2D
@export var door_shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP)


func _draw() -> void:
	if texture == null:
		return
	var size := texture.get_size()
	draw_texture(texture, Vector2(-size.x * 0.5, -size.y))


func global_footprint_rect() -> Rect2:
	return _global_shape_rect(footprint_shape)


func global_door_rect() -> Rect2:
	return _global_shape_rect(door_shape)


func door_overlaps(area: Rect2) -> bool:
	var door := global_door_rect()
	return door.has_area() and door.intersects(area)


func overlaps(area: Rect2) -> bool:
	return global_footprint_rect().intersects(area) or door_overlaps(area)


func _global_shape_rect(shape_node: CollisionShape2D) -> Rect2:
	if shape_node == null:
		return Rect2()
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2()
	return shape_node.global_transform * Rect2(-rect_shape.size * 0.5, rect_shape.size)


func contains(global_point: Vector2) -> bool:
	if footprint_shape == null:
		return false
	var rect_shape := footprint_shape.shape as RectangleShape2D
	if rect_shape == null:
		return false
	var local := footprint_shape.global_transform.affine_inverse() * global_point
	return Rect2(-rect_shape.size * 0.5, rect_shape.size).has_point(local)
