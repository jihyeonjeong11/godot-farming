class_name WorldObjectData
extends Resource

@export var id: StringName
@export var name: StringName
@export var description: String
@export var texture: Texture2D
@export var type: DataTypes.ObjectType
@export var is_interactable: bool = false
@export var loot_pool: Array[LootData]

@export var max_health: int = 1

# nature
@export var max_growth_stage: int
@export var growth_textures: Array[Texture]

# crops
@export var days_until_harvest: int
@export var regrow_days: int
@export var is_raised: bool
