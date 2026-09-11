class_name Crops extends PlaceableObject

@export var growth_textures: Array[Texture2D]
@export_range(1, 365) var days_until_harvest: int
@export var interactable_action: DataTypes.InteractableActions = DataTypes.InteractableActions.Harvest

@export_group("Regrow")
@export_range(0, 365) var regrow_days: int = 0
@export var regrow_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Vegetative
@export var regrow_texture: Texture2D
@export_range(0, 99) var max_harvests: int = 0


func regrows() -> bool:
	return regrow_days > 0


func can_harvest_again(harvest_count: int) -> bool:
	if not regrows():
		return false

	return max_harvests == 0 or harvest_count < max_harvests
