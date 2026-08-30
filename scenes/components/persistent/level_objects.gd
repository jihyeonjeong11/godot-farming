extends LevelLayer
## 땅에 떨어져 있어 주울 수 있는 것들. 도구와 씨앗.
##
## 떨어진 물건은 전부 dropped_item.tscn 하나를 쓰므로 씬 경로로는 무엇인지 알 수 없다.
## 어떤 아이템인지는 "state"에 실어 보낸다 — LevelLayer가 add_child 다음에
## apply_state로 넘겨주고, DroppedItem이 그걸로 자기 그림과 컴포넌트를 맞춘다.

const DROP := "res://scenes/objects/pickables/dropped_item.tscn"


func _init() -> void:
	layer_id = &"objects"
	initial_objects = {
		"CornSeeds": _drop("res://scripts/resources/seeds/corn_seeds.tres", Vector2(178, 124)),
		"CarrotSeeds": _drop("res://scripts/resources/seeds/carrot_seeds.tres", Vector2(418, 153)),
		"PotatoSeeds": _drop("res://scripts/resources/seeds/potato_seeds.tres", Vector2(486, 223)),
		"ContainerItem": _drop("res://scripts/resources/buildables/container.tres", Vector2(340, 120)),
		"axe": _drop("res://scripts/resources/tools/axe.tres", Vector2(296, 255)),
		"bat": _drop("res://scripts/resources/tools/bat.tres", Vector2(47, 265)),
		"hoe": _drop("res://scripts/resources/tools/hoe.tres", Vector2(26, 151)),
		"pickaxe": _drop("res://scripts/resources/tools/pickaxe.tres", Vector2(286, 64)),
		"watering_can": _drop("res://scripts/resources/tools/watering_can.tres", Vector2(478, 82)),
	}


func _drop(item_path: String, position: Vector2) -> Dictionary:
	return {
		"scene": DROP,
		"position": position,
		"state": {"item": item_path},
	}
