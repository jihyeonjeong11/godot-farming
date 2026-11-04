@tool
class_name TreeObject extends WorldObject

const BASE_SIZE := Vector2(24, 12)

@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _apply_data() -> void:
	if not is_node_ready() or data == null:
		return
	var stage := data.growth_stage
	var tex: Texture2D = data.growth_textures[stage] if stage < data.growth_textures.size() else null
	sprite.texture = tex
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height()) if tex else Vector2.ZERO
	_apply_collision(stage, tex)


func _apply_collision(stage: int, tex: Texture2D) -> void:
	if stage == 0 or tex == null:
		collision_shape_2d.shape = null
		collision_shape_2d.disabled = true
		return
	var size := BASE_SIZE.min(tex.get_size())
	var rect := Rect2(Vector2(-size.x / 2.0, -size.y), size)
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision_shape_2d.shape = shape
	collision_shape_2d.position = rect.get_center()
	collision_shape_2d.disabled = false
