class_name DataTypes

enum Levels {
	MainMenu,
	Farm,
	RuinCity
}

enum Tools {
	None,        # 0
	AxeWood,     # 1
	MineRock,    # 2 
	TillGround,  # 3
	WaterCrops,  # 4
	PlantPotato, # 5
	Melee,       # 6
	Ranged,      # 7
	## 아래는 뒤에만 덧붙인다. .tres 는 tool_type 을 정수로 저장하므로
	## 중간에 끼워 넣으면 Melee(6)/Ranged(7) 를 쓰던 리소스가 통째로 밀린다.
	PlantWheat,  # 8
	PlantCorn,   # 9
}

## 갈린 땅 타일맵이 쓰는 terrain_set. 타일셋에 0번 하나뿐이다.
const SOIL_TERRAIN_SET: int = 0

## 땅 상태. 값이 곧 타일셋의 terrain 번호라 .tres 를 같이 고치지 않는 한 바꾸면 안 된다.
##
## WateredDirt 로는 칠하지 않는다. TilledDirt 와 다른 terrain 이라 오토타일이 서로
## 남으로 보고 이어 붙이질 않아, 밭이 칸마다 동그란 섬으로 쪼개진다. 물기는
## WateredSoilLayer 가 따로 그린다. 여기 남겨둔 건 타일셋에 그 번호가 있어서다.
enum SoilTerrains {
	TilledDirt = 4,
	WateredDirt = 5,
}

enum GrowthStates {
	Seed,
	Germination,
	Vegetative,
	Reproduction,
	Maturity,
	Harvesting
}
