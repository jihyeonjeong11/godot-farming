class_name ContainerInventoryComponent
extends Node

@export var slot_count: int = 12

var slots: Array[ItemStack] = []


func _ready() -> void:
	slots.resize(maxi(slot_count, 0))


## 씬에서 정해둔 초기 물건을 채운다. 입구는 Item 배열이다 — RefCounted 인 ItemStack 은
## 씬에 저장되지 않으므로 인스펙터가 줄 수 있는 것은 스펙뿐이다. 뭉치는 여기서 만든다.
func fill(items: Array[Item], amounts: Array[int] = []) -> void:
	for i in mini(items.size(), slots.size()):
		if items[i] == null:
			continue

		var amount: int = amounts[i] if i < amounts.size() else 1
		slots[i] = ItemStack.new(items[i], maxi(amount, 1))

## 한 칸이라도 차 있으면 false.
func is_empty() -> bool:
	for stack in slots:
		if stack != null and stack.item != null:
			return false
	return true


func capture() -> Array:
	var out := []

	for stack in slots:
		# 저장할 수 없는 칸(코드로 만든 Item 등)은 null 로 남는다. 자리는 밀리지 않는다.
		out.append(stack.to_dict() if stack != null else null)

	return out


## 칸 수는 이 상자의 것을 따른다. 세이브가 더 길면 넘치는 만큼 버린다.
## 상자 크기를 줄이는 밸런스 조정을 해도 불러오기가 깨지지 않게 하기 위함이다.
func apply(data: Array) -> void:
	slots.resize(maxi(slot_count, 0))

	for i in slots.size():
		slots[i] = null

	if data.size() > slots.size():
		push_warning("칸이 %d개 줄어 그만큼 버린다" % (data.size() - slots.size()))

	for i in mini(data.size(), slots.size()):
		slots[i] = ItemStack.from_dict(data[i])
