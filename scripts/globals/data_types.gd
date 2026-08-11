class_name ApoDataTypes

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

enum GrowthStates {
	Seed,
	Germination,
	Vegetative,
	Reproduction,
	Maturity,
	Harvesting
}
