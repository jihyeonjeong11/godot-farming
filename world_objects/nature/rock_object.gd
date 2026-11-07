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

var state: Dictionary = {
	"health": 1,
	"variant": -1
}

func _ready() -> void:
	if not Engine.is_editor_hint():
		state["health"] = data.max_health
		state = SnapshotActions.populate(global_position, data.id, state)
	super()


func on_hit(tool: DataTypes.Tools, damage: int) -> void:
	if damage >= state["health"]:
		destroy()
	else:
		state["health"] -= damage


func destroy() -> void:
	LootActions.drop_loot(data.loot_pool, global_position)
	SnapshotActions.remove(global_position)
	queue_free()


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
	var rock := AtlasTexture.new()
	rock.atlas = sheet
	rock.region = Rect2(origin + rect.position, rect.size)
	sprite.texture = rock
	sprite.offset = Vector2(-rock.get_width() / 2.0, -rock.get_height())
