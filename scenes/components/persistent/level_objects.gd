extends LevelLayer
## 땅에 떨어져 있어 주울 수 있는 것들. 도구와 씨앗.


func _init() -> void:
	layer_id = &"objects"
	initial_objects = {
		"CornSeeds": {
			"scene": "res://scenes/objects/seeds/corn_seed.tscn",
			"position": Vector2(178, 124),
		},
		"CarrotSeeds": {
			"scene": "res://scenes/objects/seeds/carrot_seed.tscn",
			"position": Vector2(418, 153),
		},
		"PotatoSeeds": {
			"scene": "res://scenes/objects/seeds/potato_seed.tscn",
			"position": Vector2(486, 223),
		},
		"axe": {
			"scene": "res://scenes/objects/tools/axe.tscn",
			"position": Vector2(296, 255),
		},
		"bat": {
			"scene": "res://scenes/objects/tools/bat.tscn",
			"position": Vector2(47, 265),
		},
		"hoe": {
			"scene": "res://scenes/objects/tools/hoe.tscn",
			"position": Vector2(26, 151),
		},
		"pickaxe": {
			"scene": "res://scenes/objects/tools/pickaxe.tscn",
			"position": Vector2(286, 64),
		},
		"watering_can": {
			"scene": "res://scenes/objects/tools/watering_can.tscn",
			"position": Vector2(478, 82),
		},
	}
