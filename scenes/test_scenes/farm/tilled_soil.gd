extends TileMapLayer



func _ready() -> void:
	print('made')
	SnapshotActions.populate(global_position, 'tilled_soil', {})
	_restore_snapshot.call_deferred()


func _restore_snapshot() -> void:
	GridActions.restore(GameState.farm_snapshot)
