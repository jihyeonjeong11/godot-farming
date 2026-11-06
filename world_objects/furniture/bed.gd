extends WorldObject

func on_interact() -> void:
	await TimeManager.advance_day()
	SaveManager.save_current_game()
