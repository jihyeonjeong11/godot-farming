extends LevelLayer
## 플레이어가 세워둔 것들. 상자처럼 자리를 차지하고 우클릭으로 만지는 물건.
##
## 주우면 사라지는 objects 레이어와 반대로, 여기 있는 것은 놓이면 계속 남는다.
##
## initial_objects가 비어 있다. 처음 놓인 상자는 씬에 직접 두고, 거기서 정한
## initial_items를 그대로 살리기 위함이다. 세이브가 없으면 LevelLayer가
## 자식을 건드리지 않고 넘어간다.
##
## 상자 속은 씬 경로와 위치만으로는 복원되지 않으므로, 상자가 capture_state/
## apply_state를 갖추고 LevelLayer가 그것까지 같이 떠낸다.


func _init() -> void:
	layer_id = &"buildables"
