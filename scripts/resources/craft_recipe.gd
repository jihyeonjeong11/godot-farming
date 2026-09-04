class_name CraftRecipe extends Resource
## 조합법 하나. 재료 목록과 결과물만 들고 있는 순수 데이터다.
##
## 재료는 CraftIngredient 다. ItemStack 은 RefCounted 라 @export 가 되지 않으므로
## 인스펙터에서 찍어 넣는 저작 데이터로는 쓸 수 없다.
## 실제로 깎고 만드는 일은 Inventory.craft() 가 한다.

@export var result: Item
@export var result_amount: int = 1
@export var ingredients: Array[CraftIngredient] = []

## 표시용 이름. 비우면 결과물 이름을 쓴다.
@export var recipe_name: String = ""


func display_name() -> String:
	if not recipe_name.is_empty():
		return recipe_name
	if result == null:
		return "???"
	if result_amount <= 1:
		return result.item_name
	return "%s x%d" % [result.item_name, result_amount]


## 재료를 "가진 수/필요 수" 로 늘어놓는다. 뭘 더 모아야 하는지 눈으로 바로 보이게 한다.
func describe() -> String:
	var lines: PackedStringArray = [display_name()]

	if result != null and not result.description.is_empty():
		lines.append(result.description)

	for need in ingredients:
		if need == null or need.item == null:
			continue
		lines.append("%s %d/%d" % [need.item.item_name, Inventory.count_item(need.item), need.amount])

	return "\n".join(lines)
