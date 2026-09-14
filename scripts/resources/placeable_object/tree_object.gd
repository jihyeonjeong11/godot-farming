class_name TreeObject extends PlaceableObject

## 단계별 그림. 마지막이 다 자란 나무다.
@export var growth_textures: Array[Texture2D]
## 하루에 한 단계 자랄 확률.
@export_range(0.0, 1.0) var grow_chance: float = 0.2
## 다 자란 나무가 하루에 주변에 묘목을 떨어뜨릴 확률.
@export_range(0.0, 1.0) var spread_chance: float = 0.15
@export_range(1, 8) var spread_radius: int = 3
## 다 자라기 전 단계의 체력. 도끼 한 번이면 없어진다.
@export var sapling_health: int = 1


func max_stage() -> int:
	return maxi(growth_textures.size() - 1, 0)
