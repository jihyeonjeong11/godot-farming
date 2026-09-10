class_name PlaceableObject
extends Resource

@export var object_id: String
@export var object_name: String
@export var destructible_tool: DataTypes.Tools
@export var object_texture: Texture
# 이 이름으로 group에 넣고, cursor로 소통하면 될듯?
@export var object_type: DataTypes.ObjectType
@export var interactable_actions: DataTypes.Interactable_actions

@export var object_max_health: int
@export var dropped_items: Array[Loot]

@export var centered: bool
@export var offset: Vector2i
@export var hurtbox_offset: Vector2i
# 32 = one tile
@export var hurtbox_radius: int = 32
@export var scatter_radius: int = 20
@export var collision_offset: Vector2i
@export var collision_radius: int = 32
