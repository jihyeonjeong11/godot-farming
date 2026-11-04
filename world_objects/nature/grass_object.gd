@tool
class_name GrassObject extends WorldObject

const CLUMPS := [
	Rect2(5, 32, 32, 30),
	Rect2(37, 34, 32, 26),
	Rect2(73, 32, 24, 32),
	Rect2(107, 36, 22, 26),
	Rect2(9, 64, 24, 26),
	Rect2(39, 68, 29, 28),
	Rect2(68, 64, 33, 32),
	Rect2(105, 66, 26, 28),
	Rect2(133, 46, 64, 50),
]

@export var variant: int = -1


func _apply_data() -> void:
	if not is_node_ready() or data == null or data.texture == null:
		return
	if variant < 0 or variant >= CLUMPS.size():
		variant = randi() % CLUMPS.size()
	var sheet := data.texture
	var origin := Vector2.ZERO
	if sheet is AtlasTexture:
		origin = sheet.region.position
		sheet = sheet.atlas
	var clump := AtlasTexture.new()
	clump.atlas = sheet
	clump.region = Rect2(origin + CLUMPS[variant].position, CLUMPS[variant].size)
	sprite.texture = clump
	sprite.offset = Vector2(-clump.get_width() / 2.0, -clump.get_height())
