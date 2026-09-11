class_name PlaceableObject
extends Resource

@export var object_id: String
@export var object_name: String
@export var destructible_tool: DataTypes.Tools
@export var object_texture: Texture
@export var animated_texture: Array[Texture]
# 이 이름으로 group에 넣고, cursor로 소통하면 될듯?
@export var object_type: DataTypes.ObjectType
@export var interactable_actions: DataTypes.InteractableActions

@export var object_max_health: int
@export var dropped_items: Array[Loot]

@export var centered: bool
@export var offset: Vector2i
@export var sprite_scale: float = 1.0
@export var hurtbox_offset: Vector2i
# 32 = one tile
@export var hurtbox_radius: int = 32
@export var scatter_radius: int = 20
@export var collision_offset: Vector2i
@export var collision_radius: int = 32

@export_group("Shake")
@export var shake_intensity: float = 0.0
@export var shake_speed: float = 20.0
## 0 이면 스프라이트 높이 전체를 쓴다.
@export var shake_bend_height: float = 0.0
@export var shake_duration: float = 0.3

@export_group("Animation")
@export var sprite_frames: SpriteFrames
@export var default_animation: StringName
@export var toggle_animation: StringName
@export var toggle_on_sfx: String
@export var toggle_off_sfx: String
