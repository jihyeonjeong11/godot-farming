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

## 한 슬롯에 쌓을 수 있는 최대 개수. 0이면 스택 불가(도구, 무기 등).
## 실제 보유 개수는 Inventory의 슬롯이 들고 있다. 여기 두면 .tres가
## 프로젝트 전체 공유 인스턴스라 모든 슬롯이 같은 숫자를 쓰게 된다.
@export var max_stack: int
