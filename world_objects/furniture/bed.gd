extends WorldObject

func on_interact() -> void:
	TimeManager.advance_day()
