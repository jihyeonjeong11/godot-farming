extends TileMapLayer

const GROUP := &"tilled_soil"


func _ready() -> void:
	add_to_group(GROUP)
	_restore_snapshot.call_deferred()


func _restore_snapshot() -> void:
	GridActions.restore(GameState.farm_snapshot)
