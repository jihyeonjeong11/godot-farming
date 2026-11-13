@tool
class_name SalvageObject extends WorldObject

var state: Dictionary = {
	"health": 1,
	"destroyed": false,
}


func _ready() -> void:
	if not Engine.is_editor_hint():
		state["health"] = data.max_health
		state = SnapshotActions.populate(global_position, data.id, state)
		if state.get("destroyed", false):
			queue_free()
			return
	super()


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
