extends Sprite2D

const CELL := 64
const ROWS_PER_VARIANT := 4
const FRONT_ROW := 1

var part_index: int:
	set(v):
		part_index = v
		_apply()
		
@export var part: DataTypes.Vanity
@export var part_sprite: Texture2D

func _ready() -> void:
	texture = part_sprite
	hframes = texture.get_width() / CELL
	vframes = texture.get_height() / CELL
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	visible = part_index >= 0 and part_index < vframes / ROWS_PER_VARIANT
	if visible:
		frame = (part_index * ROWS_PER_VARIANT + FRONT_ROW) * hframes
