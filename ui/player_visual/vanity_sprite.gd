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



# 해당 파일에서 인덱스를 가져와서 offset값이 따라 배치하면 됨.
func _ready() -> void:
	texture = part_sprite
	hframes = texture.get_width() / CELL
	vframes = texture.get_height() / CELL
	part_index = GameState.player_vanity[part]


func _apply() -> void:
	if not is_node_ready():
		return
	visible = part_index >= 0 and part_index < vframes / ROWS_PER_VARIANT
	if visible:
		frame = (part_index * ROWS_PER_VARIANT + FRONT_ROW) * hframes
