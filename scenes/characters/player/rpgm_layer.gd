extends Sprite2D

const CELL := 64
const ROWS_PER_VARIANT := 4

@export var variant := 0:
	set(v):
		variant = v
		_apply()

var _cell := Vector2i.ZERO


func _ready() -> void:
	if texture:
		hframes = texture.get_width() / CELL
		vframes = texture.get_height() / CELL
	_apply()


func variant_count() -> int:
	return vframes / ROWS_PER_VARIANT


func sync(anim: StringName, frame_i: int) -> void:
	var body := get_parent() as AnimatedSprite2D
	if body == null or not body.sprite_frames.has_animation(anim):
		return
	var tex := body.sprite_frames.get_frame_texture(anim, frame_i) as AtlasTexture
	if tex == null:
		return
	_cell = Vector2i(tex.region.position) / CELL
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var row := variant * ROWS_PER_VARIANT + _cell.y
	if row >= vframes:
		return
	frame = row * hframes + _cell.x
