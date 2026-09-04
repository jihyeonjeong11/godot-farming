class_name ItemStack extends RefCounted

var item: Item
var amount: int = 1

## TODO: 임시 값들: max_ammo로 파생되는 current_ammo 혹은 durability 등이 있다면 여기
func _init(p_item: Item = null, p_amount: int = 1) -> void:
	item = p_item
	amount = p_amount


func is_valid() -> bool:
	return item.item_id != null and amount > 0

func is_same_kind(other: Item) -> bool:
	if item.item_id == null or other == null:
		return false
	if item.item_id.is_empty():
		return false
	return item.item_id == other.item_id

func can_stack(other: ItemStack) -> bool:
	if other == null or not other.is_valid():
		return false
	if not is_same_kind(other.item):
		return false
	# max_stack <= 0 은 "쌓이지 않는 물건"이다(도구 등).
	if item.max_stack <= 0:
		return false
	return amount < item.max_stack


## 이 칸에 더 들어갈 수 있는 여유. 쌓이지 않는 물건은 0.
func free_space() -> int:
	if item == null or item.max_stack <= 0:
		return 0
	return maxi(item.max_stack - amount, 0)


## 한 칸에 최대 몇 개까지 담기는가. 쌓이지 않는 물건은 칸당 하나다.
static func slot_capacity(spec: Item) -> int:
	if spec == null:
		return 0
	return 1 if spec.max_stack <= 0 else spec.max_stack

func to_dict() -> Variant:
	if item == null:
		return null

	# 코드로 만든 Item 은 경로가 없어 다시 찾을 방법이 없다.
	if item.resource_path.is_empty():
		push_warning("resource_path가 없어 저장할 수 없다: %s" % item.item_name)
		return null

	return {
		"item": item.resource_path,
		"amount": amount,
	}


static func from_dict(data: Variant) -> ItemStack:
	if data is not Dictionary:
		return null

	var path: String = data.get("item", "")
	if path.is_empty():
		return null

	var spec := load(path) as Item
	if spec == null:
		push_warning("아이템을 불러오지 못했다: %s" % path)
		return null

	return ItemStack.new(spec, maxi(int(data.get("amount", 1)), 1))
