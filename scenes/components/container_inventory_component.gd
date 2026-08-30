class_name ContainerInventoryComponent
extends Node

@export var slot_count: int = 12

var slots: Array[ItemStack] = []


func _ready() -> void:
	# @export는 _init 다음에 들어온다. _init에서 잡으면 씬에서 정한 칸 수가 무시된다.
	slots.resize(maxi(slot_count, 0))


func fill(items: Array[Items], amounts: Array[int] = []) -> void:
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
		if stack == null or stack.item == null:
			out.append(null)
			continue

		# 코드로 만든 Items는 경로가 없어 다시 찾을 방법이 없다.
		if stack.item.resource_path.is_empty():
			push_warning("resource_path가 없어 저장할 수 없다: %s" % stack.item.item_name)
			out.append(null)
			continue

		out.append({
			"item": stack.item.resource_path,
			"amount": stack.amount,
		})

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
		var entry: Variant = data[i]
		if entry is not Dictionary:
			continue

		# load는 같은 경로에 대해 같은 인스턴스를 돌려준다.
		# ItemStack.can_stack이 Items를 참조로 비교하므로 duplicate하면 안 된다.
		var item := load(entry["item"]) as Items
		if item == null:
			push_warning("아이템을 불러오지 못했다: %s" % entry["item"])
			continue

		slots[i] = ItemStack.new(item, entry["amount"])
