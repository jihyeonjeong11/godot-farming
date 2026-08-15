extends LevelLayer
## 맵에 원래 박혀 있는 것들. 돌·나무처럼 심지 않았지만 부술 수는 있는 것.


func _init() -> void:
	layer_id = &"nature"
	initial_objects = {
		"Rock": {
			"scene": "res://scenes/objects/rocks/Rock.tscn",
			"position": Vector2(162, 193),
		},
		"Rock2": {
			"scene": "res://scenes/objects/rocks/Rock.tscn",
			"position": Vector2(173, 276),
		},
		"SmallTree": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(250, 214),
		},
		"SmallTree2": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(410, 224),
		},
		"Rock3": {
			"scene": "res://scenes/objects/rocks/Rock.tscn",
			"position": Vector2(108, 96),
		},
		"Rock4": {
			"scene": "res://scenes/objects/rocks/Rock.tscn",
			"position": Vector2(452, 312),
		},
		"Rock5": {
			"scene": "res://scenes/objects/rocks/Rock.tscn",
			"position": Vector2(360, 132),
		},
		"SmallTree3": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(88, 204),
		},
		"SmallTree4": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(324, 72),
		},
		"SmallTree5": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(212, 312),
		},
		"SmallTree6": {
			"scene": "res://scenes/objects/trees/SmallTree.tscn",
			"position": Vector2(468, 156),
		},
	}
