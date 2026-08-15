class_name ContainerInventoryComponent
extends Node
## 아이템을 담아두는 물건에 붙인다. 담을 곳만 갖고, 여는 UI는 모른다.
##
## 칸은 Inventory와 같은 모양이다. 빈 칸은 null로 남겨야 자리가 밀리지 않는다.
## 칸 수는 씬마다 다르다. 새 종류를 만들 때 스크립트가 아니라 이 값만 바꾼다.

@export var slot_count: int = 12

var slots: Array[ItemStack] = []


func _ready() -> void:
	# @export는 _init 다음에 들어온다. _init에서 잡으면 씬에서 정한 칸 수가 무시된다.
	slots.resize(maxi(slot_count, 0))


## 처음 내용물을 채운다. 앞 칸부터 하나씩 놓고, 칸이 모자라면 남는 것은 버린다.
## 부모 씬이 _ready에서 부른다. 이때는 slots가 이미 잡혀 있다.
## amounts는 items와 같은 순서. 짧으면 나머지는 1개로 본다.
func fill(items: Array[Items], amounts: Array[int] = []) -> void:
	for i in mini(items.size(), slots.size()):
		if items[i] == null:
			continue

		var amount: int = amounts[i] if i < amounts.size() else 1
		slots[i] = ItemStack.new(items[i], maxi(amount, 1))


## 칸 순서 그대로 떠낸다. 빈 칸은 null로 남겨야 불러올 때 자리가 밀리지 않는다.
## 아이템 자체(.tres)는 프로젝트 리소스라 저장하지 않고 경로만 적는다.
## 형식은 플레이어 인벤토리 세이브와 같다.
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
