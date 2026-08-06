class_name Items extends Resource

## 확졍 아님.

## melee, range, tool, consumable, material, artifact, ammo, seed, buildable, misc
@export var item_type = ""
@export var item_name = ""
@export var item_texture: Texture
## Execlusive for artifacts
@export var item_effect = ""
## 먹을 수 있다면 회복량. 아니면 -1
@export var edible = -1
## todo: i18n
@export var description = ""

@export var melee_damage: int
@export var melee_knockback: int

@export var max_stack: int
## droppable
@export_file("*.tscn") var world_scene_path: String = ""
