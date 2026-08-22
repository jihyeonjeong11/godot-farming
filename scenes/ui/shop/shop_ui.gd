extends CanvasLayer

# shopType: terminal - 현재는 하나만

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	SignalBus.barter_opened.connect(on_open_shop)
	pass
	
func on_open_shop() -> void:
	visible = true
