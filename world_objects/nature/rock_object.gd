@tool
class_name RockObject extends WorldObject

const VARIANTS := [
	Rect2(5, 5, 28, 26),
	Rect2(39, 5, 26, 24),
	Rect2(73, 9, 22, 18),
	Rect2(7, 35, 28, 30),
	Rect2(35, 33, 34, 32),
	Rect2(69, 33, 30, 28),
]
const BASE_SIZE := Vector2(24, 12)

@export var variant: int = -1

@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D

var state: Dictionary = {
	"health": 1
}

func _ready() -> void:
	super()
	state = SnapshotActions.populate(global_position, data.id, state)


func _apply_data() -> void:
	if not is_node_ready() or data == null or data.texture == null:
		return
	if variant < 0 or variant >= VARIANTS.size():
		variant = randi() % VARIANTS.size()
	var sheet := data.texture
	var origin := Vector2.ZERO
	if sheet is AtlasTexture:
		origin = sheet.region.position
		sheet = sheet.atlas
	var rock := AtlasTexture.new()
	rock.atlas = sheet
	rock.region = Rect2(origin + VARIANTS[variant].position, VARIANTS[variant].size)
	sprite.texture = rock
	sprite.offset = Vector2(-rock.get_width() / 2.0, -rock.get_height())
	_apply_collision(rock)


func _apply_collision(tex: Texture2D) -> void:
	var size := BASE_SIZE.min(tex.get_size())
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape_2d.shape = shape
	collision_shape_2d.position = Vector2(0, -size.y / 2.0)
