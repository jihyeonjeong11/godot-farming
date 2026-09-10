extends LevelLayer
## 땅에 떨어져 있어 주울 수 있는 것들. 도구와 씨앗.
##
## 떨어진 물건은 전부 item_stack_instance.tscn 하나를 쓰므로 씬 경로로는 무엇인지 알 수 없다.
## 어떤 아이템인지는 "state"에 실어 보낸다 — LevelLayer가 add_child 다음에
## apply_state로 넘겨주고, ItemStackInstance이 그걸로 자기 그림과 컴포넌트를 맞춘다.
##
## 실어 보내는 모양은 세이브와 똑같은 ItemStack.to_dict() 형식이다. 초기 배치만
## 다른 모양이면 ItemStackInstance이 읽는 형식이 둘로 갈린다.

const DROP := "res://scenes/objects/pickables/item_stack_instance.tscn"


func _init() -> void:
	layer_id = &"objects"
	initial_objects = {
		"CornSeeds": _drop(&"corn_seeds", Vector2(178, 124)),
		"CarrotSeeds": _drop(&"carrot_seeds", Vector2(418, 153)),
		"PotatoSeeds": _drop(&"potato_seeds", Vector2(486, 223)),
		"ContainerItem": _drop(&"container", Vector2(340, 120)),
		"axe": _drop(&"axe", Vector2(296, 255)),
		"bat": _drop(&"bat", Vector2(47, 265)),
		"hoe": _drop(&"hoe", Vector2(26, 151)),
		"pickaxe": _drop(&"pickaxe", Vector2(286, 64)),
		"watering_can": _drop(&"watering_can", Vector2(478, 82)),
	}


func _drop(item_id: StringName, position: Vector2) -> Dictionary:
	return {
		"scene": DROP,
		"position": position,
		"state": {"stack": {"item_id": String(item_id), "amount": 1}},
	}
