extends LevelLayer
## 심어둔 작물. CropsCursorComponent가 갈린 땅 위에 여기로 심는다.
##
## 지금은 씬과 위치만 저장한다. 그래서 불러오면 자란 정도가 초기화된다.
## 생장 단계·물 준 여부는 GrowthCycleComponent 안에 있어서 밖에서 안 보인다.
## 나중에 노드별 상태를 한 겹 더 떠내는 방식으로 붙이면 된다.


func _init() -> void:
	layer_id = &"crops"
	initial_objects = {
		"Potato": {
			"scene": "res://scenes/objects/crops/potato/potato.tscn",
			"position": Vector2(86, 67),
		},
		"Wheat": {
			"scene": "res://scenes/objects/crops/wheat/wheat.tscn",
			"position": Vector2(121, 52),
		},
	}
