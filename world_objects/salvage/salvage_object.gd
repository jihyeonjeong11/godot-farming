@tool
class_name SalvageObject extends WorldObject

const VARIANTS := {
	&"dead_crops": [
		Rect2(0, 0, 32, 32), Rect2(32, 0, 32, 32), Rect2(64, 0, 32, 32),
		Rect2(96, 0, 32, 32), Rect2(128, 0, 32, 32), Rect2(160, 0, 32, 32),
		Rect2(192, 0, 32, 32), Rect2(224, 0, 32, 32), Rect2(256, 0, 32, 32),
		Rect2(0, 32, 32, 64), Rect2(32, 32, 32, 64), Rect2(64, 32, 32, 64),
		Rect2(96, 32, 32, 64), Rect2(128, 32, 32, 64), Rect2(160, 32, 32, 64),
		Rect2(192, 32, 32, 64), Rect2(224, 32, 32, 64), Rect2(256, 32, 32, 64),
	],
}

var state: Dictionary = {
	"health": 1,
	"destroyed": false,
	"variant": -1,
}


func _ready() -> void:
	super()



func _apply_data() -> void:
	if not is_node_ready() or data == null:
		return
	var rects: Array = VARIANTS.get(data.id, [])
	if rects.is_empty() or data.texture == null:
		super()
		return
	if int(state.get("variant", -1)) < 0:
		state["variant"] = absi(hash(Vector2i(global_position.round()))) % rects.size()
	var rect: Rect2 = rects[int(state["variant"]) % rects.size()]
	var sheet := data.texture
	var origin := Vector2.ZERO
	if sheet is AtlasTexture:
		origin = sheet.region.position
		sheet = sheet.atlas
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = Rect2(origin + rect.position, rect.size)
	sprite.texture = tex
	sprite.offset = Vector2(-rect.size.x / 2.0, -rect.size.y)


func on_interact() -> void:
	pass


func on_hit(_tool: DataTypes.Tools, damage: int) -> void:
	if damage >= state["health"]:
		destroy()
	else:
		state["health"] -= damage


func destroy() -> void:
	state["destroyed"] = true
	LootActions.drop_loot(data.loot_pool, global_position)
	queue_free()
