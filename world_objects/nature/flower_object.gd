@tool
class_name FlowerObject extends GrassObject

const VARIANTS := [
	Rect2(0, 0, 32, 32),
	Rect2(32, 0, 32, 32),
	Rect2(64, 0, 32, 32),
]

func get_drop_item_id() -> StringName:
	return StringName("%s_%d" % [data.id, state["variant"]])


func _apply_data() -> void:
	if not is_node_ready() or data == null or data.texture == null:
		return
	if state.get("variant", -1) < 0:
		state["variant"] = randi() % VARIANTS.size()
	var rect: Rect2 = VARIANTS[int(state["variant"])]
	var sheet := data.texture
	var origin := Vector2.ZERO
	if sheet is AtlasTexture:
		origin = sheet.region.position
		sheet = sheet.atlas
	var flower := AtlasTexture.new()
	flower.atlas = sheet
	flower.region = Rect2(origin + rect.position, rect.size)
	sprite.texture = flower
	sprite.offset = Vector2(-rect.size.x / 2.0, -rect.size.y)
