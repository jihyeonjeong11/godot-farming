extends LevelLayer


func _init() -> void:
	layer_id = &"crops"
	initial_objects = {
		"Potato": {
			"scene": "res://scenes/objects/placables/crops/potato/potato.tscn",
			"position": Vector2(86, 67),
		},
		"Wheat": {
			"scene": "res://scenes/objects/placables/crops/wheat/wheat.tscn",
			"position": Vector2(121, 52),
		},
	}
