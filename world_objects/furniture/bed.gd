extends WorldObject

var day := 0

func on_interact() -> void:
	advance_day()

func advance_day() -> void:
	# 현재는 스포너에 아이템 추가하는 것만
	for object in get_tree().get_nodes_in_group(&"object"):
		if object is NatureSpawner:
			object.advance_day()
	day += 1
	SignalBus.time_tick_day.emit(day)
