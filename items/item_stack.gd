class_name ItemStack extends RefCounted

var item: Item
var amount: int = 1
var current_ammo = 0

## TODO: 임시 값들: max_ammo로 파생되는 current_ammo 혹은 durability 등이 있다면 여기
func _init(p_item: Item = null, p_amount: int = 1) -> void:
	item = p_item
	amount = p_amount
	if p_item == null:
		return
	current_ammo = p_item.max_ammo if p_item.max_ammo > 0 else p_item.current_ammo


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


func free_space() -> int:
	if item == null or item.max_stack <= 0:
		return 0
	return maxi(item.max_stack - amount, 0)


static func slot_capacity(spec: Item) -> int:
	if spec == null:
		return 0
	return 1 if spec.max_stack <= 0 else spec.max_stack

func to_dict() -> Variant:
	if item == null:
		return null

	if item.item_id.is_empty():
		push_warning("item_id가 없어 저장할 수 없다: %s" % item.item_name)
		return null

	return {
		"item_id": item.item_id,
		"amount": amount,
		"current_ammo": current_ammo,
	}


static func from_dict(data: Variant) -> ItemStack:
	if data is not Dictionary:
		return null

	var id := StringName(data.get("item_id", ""))
	if id.is_empty():
		return null

	var spec := ItemDB.get_item(id)
	if spec == null:
		return null

	var stack := ItemStack.new(spec, maxi(int(data.get("amount", 1)), 1))
	if data.has("current_ammo"):
		stack.current_ammo = int(data["current_ammo"])
	return stack
