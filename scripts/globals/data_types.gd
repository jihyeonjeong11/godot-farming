class_name DataTypes

enum GameState {
	MainMenu,
	Game
}

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
	PlantWheat,  # 8
	PlantCorn,   # 9
}

enum WearSlot {
	None,  # 0
	Armor, # 1
	Boots, # 2
}
enum ItemType {
	Misc,       # 0  아직 분류 안 된 것
	Junk,       # 1  주워서 팔거나 분해하는 잡동사니
	Consumable, # 2  먹거나 써서 없어지는 것
	Seeds,      # 3
	Tool,       # 4  tool_type 을 가진 도구
	Material,   # 5  제작 재료 (옛 "material" + "resource")
	Buildable,  # 6  땅에 세우는 것
	Wearable,   # 7  입는 것
	Melee,      # 8  근접 무기
}

static func item_type_label(type: ItemType) -> String:
	match type:
		ItemType.Junk: return "junk"
		ItemType.Consumable: return "consumable"
		ItemType.Seeds: return "seeds"
		ItemType.Tool: return "tool"
		ItemType.Material: return "material"
		ItemType.Buildable: return "buildable"
		ItemType.Wearable: return "wearable"
		ItemType.Melee: return "melee"
	return ""


const SOIL_TERRAIN_SET: int = 0

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
