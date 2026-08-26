class_name Items extends Resource

## 확졍 아님.

## melee, range, tool, consumable, material, artifact, ammo, seed, buildable, misc
@export var item_type = ""
@export var tool_type: DataTypes.Tools = DataTypes.Tools.None
@export var item_name = ""
@export var item_texture: Texture
## Execlusive for artifacts
@export var item_effect = ""
## 먹을 수 있다면 회복량. 아니면 -1
@export var edible = -1
## 먹었을 때 채워주는 허기. 0이면 허기에는 영향이 없다.
@export var hunger = 0
## 먹었을 때 채워주는 갈증. 0이면 갈증에는 영향이 없다.
@export var thirst = 0
## todo: i18n
@export var description = ""

@export var melee_damage: int
@export var melee_knockback: int

@export var value: int

## 근접 판정을 몸에서 얼마나 밀어낼지(px). 리치가 긴 무기일수록 크다.
@export var melee_reach: float = 18.0
## 근접 판정 원의 반지름(px). melee_shape가 비어 있을 때만 쓴다.
@export var melee_radius: float = 14.0

## 근접 판정 모양. 비워두면 melee_radius짜리 원을 코드가 만들어 붙인다.
## 도끼처럼 "앞 칸"을 찍는 툴은 여기에 RectangleShape2D를 넣는다.
## 원이 아닌 모양은 바라보는 방향에 따라 회전한다 — x축이 앞쪽이다.
@export var melee_shape: Shape2D

## 대상 칸까지 닿는 거리(px). 밭갈기·심기 같은 타일 조작을 이걸로 자른다.
## 근접 판정과는 별개 축이다. 괭이는 때리는 범위가 아니라 닿는 칸이 중요하다.
@export var use_range: float = 20.0

@export var max_stack: int

## 씨앗일 때 심으면 자라날 작물 씬. 씨앗 종류마다 작물이 다르므로
## 커서 쪽에 if문을 늘리지 않고 아이템 리소스가 직접 들고 있는다.
@export_file("*.tscn") var crop_scene_path: String = ""

## buildable일 때 땅에 놓으면 세워질 씬. crop_scene_path와 같은 이유로 여기 둔다.
## 커서에 if문을 늘리지 않고 아이템이 자기가 무엇이 되는지 직접 들고 있는다.
@export_file("*.tscn") var buildable_scene_path: String = ""

## 손에 들었을 때 재생할 장비 스프라이트 애니메이션 접두사.
## "axe" → axe_idle_front / axe_attack_front. 비어 있으면 손에 아무것도 안 그린다.
@export var anim_prefix: StringName = &""
## droppable
@export_file("*.tscn") var world_scene_path: String = ""


## 툴팁 한 덩어리. 의미 있는 줄만 골라 넣는다 — 빈 설명이나 0짜리
## 수치까지 다 찍으면 읽을 것보다 건너뛸 것이 많아진다.
##
## 문자열을 부르는 쪽이 짜지 않고 아이템이 직접 만든다. 필드가 늘 때
## 칸·퀵바·상자·상점을 일일이 고치지 않기 위해서다.
##
## price_label은 value를 무엇으로 부를지. 가방에서는 "가치"지만
## 상점에서는 같은 숫자가 "구매가"나 "판매가"가 된다.
func describe(price_label: String = "가치") -> String:
	var lines: PackedStringArray = [item_name]

	if not item_type.is_empty():
		lines.append("[%s]" % item_type)

	if not description.is_empty():
		lines.append(description)

	if melee_damage > 0:
		lines.append("공격력 %d" % melee_damage)

	if edible > 0:
		lines.append("회복량 %d" % edible)

	if hunger > 0:
		lines.append("허기 +%d" % hunger)

	if thirst > 0:
		lines.append("갈증 +%d" % thirst)

	if value > 0:
		lines.append("%s %d" % [price_label, value])

	return "\n".join(lines)
