class_name ItemStack extends RefCounted

var item: Item
var amount: int = 1

## TODO: 임시 값들: max_ammo로 파생되는 current_ammo 혹은 durability 등이 있다면 여기
func _init(p_item: Item = null, p_amount: int = 1) -> void:
	item = p_item
	amount = p_amount


## item_id 는 String 이라 절대 null 이 아니다. 빈 문자열이 "없음"이다.
func is_valid() -> bool:
	return item != null and not item.item_id.is_empty() and amount > 0

func is_same_kind(other: Item) -> bool:
	if item == null or other == null:
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

	# 경로가 아니라 id 로 적는다. 경로로 적으면 .tres 를 옮기는 순간 세이브가 끊긴다.
	# 코드로 만든 임시 Item 은 id 가 없어 되찾을 방법이 없다.
	if item.item_id.is_empty():
		push_warning("item_id가 없어 저장할 수 없다: %s" % item.item_name)
		return null

	return {
		"item_id": item.item_id,
		"amount": amount,
	}


static func from_dict(data: Variant) -> ItemStack:
	if data is not Dictionary:
		return null

	var id := StringName(data.get("item_id", ""))
	if id.is_empty():
		return null

	# 모르는 id 면 ItemDB 가 경고를 남긴다. 여기서는 조용히 접는다.
	var spec := ItemDB.get_item(id)
	if spec == null:
		return null

	return ItemStack.new(spec, maxi(int(data.get("amount", 1)), 1))
