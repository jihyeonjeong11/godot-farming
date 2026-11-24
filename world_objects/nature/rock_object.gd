@tool
class_name RockObject extends WorldObject

const PICKAXE = preload("uid://boqllg37niafw")

const VARIANTS := [
	Rect2(5, 5, 28, 26),
	Rect2(39, 5, 26, 24),
	Rect2(73, 9, 22, 18),
	Rect2(7, 35, 28, 30),
	Rect2(35, 33, 34, 32),
	Rect2(69, 33, 30, 28),
]

var is_broken := false

@onready var sounds: AudioStreamPlayer2D = $Sounds

func default_state() -> Dictionary:
	return {"health": data.max_health, "variant": -1}


func is_deleting() -> bool:
	return is_broken


func on_hit(tool: DataTypes.Tools, damage: int) -> void:
	if is_broken:
		return
	sounds.stream = PICKAXE
	sounds.play()
	if damage >= state["health"]:
		destroy()
	else:
		state["health"] -= damage


func destroy() -> void:
	is_broken = true
	LootActions.drop_loot(data.loot_pool, global_position)
	SnapshotActions.remove(self)
	remove_from_group(&"object")
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	sprite.hide()
	await sounds.finished
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
