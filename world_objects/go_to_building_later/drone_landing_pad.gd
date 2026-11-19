extends WorldObject


func on_interact() -> void:
	SignalBus.barter_opened.emit([])
