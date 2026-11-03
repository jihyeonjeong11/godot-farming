class_name WorldObjectData
extends Resource

@export var id: StringName
@export var name: StringName
@export var description: String
@export var texture: Texture2D
@export var type: DataTypes.ObjectType
@export var is_interactable: bool = false

# nature
@export var growth_stage: int = 0
@export var max_growth_stage: int
@export var growth_textures: Array[Texture]
