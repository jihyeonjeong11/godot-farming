class_name Items extends Resource

## 확졍 아님.

## melee, range, tool, consumable, material, artifact, ammo, seed, buildable, misc
@export var item_type = ""
@export var tool_type: ApoDataTypes.Tools = ApoDataTypes.Tools.None
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

## 씨앗일 때 심으면 자라날 작물 씬. 씨앗 종류마다 작물이 다르므로
## 커서 쪽에 if문을 늘리지 않고 아이템 리소스가 직접 들고 있는다.
@export_file("*.tscn") var crop_scene_path: String = ""

## 손에 들었을 때 재생할 장비 스프라이트 애니메이션 접두사.
## "axe" → axe_idle_front / axe_attack_front. 비어 있으면 손에 아무것도 안 그린다.
@export var anim_prefix: StringName = &""
## droppable
@export_file("*.tscn") var world_scene_path: String = ""
