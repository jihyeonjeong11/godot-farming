class_name CraftRecipe extends Resource
## 조합법 하나. 재료 목록과 결과물만 들고 있는 순수 데이터다.
##
## 아이템을 리소스 참조가 아니라 item_id 로 적는다. 참조로 적으면 조합법 하나마다
## ext_resource 가 딸려 붙고, 재료 한 줄이 또 다른 .tres 가 된다.
## id 를 실제 Item 으로 바꾸는 일은 ItemDB, 깎고 만드는 일은 Inventory.craft() 가 한다.

@export var result_id: StringName = &""
@export var result_amount: int = 1
## item_id -> 필요 개수.
@export var ingredients: Dictionary[StringName, int] = {}

## 표시용 이름. 비우면 결과물 이름을 쓴다.
@export var recipe_name: String = ""


func result_item() -> Item:
	return ItemDB.get_item(result_id)


func display_name() -> String:
	if not recipe_name.is_empty():
		return recipe_name

	var result := result_item()
	if result == null:
		return "???"
	if result_amount <= 1:
		return result.item_name
	return "%s x%d" % [result.item_name, result_amount]


## 재료를 "가진 수/필요 수" 로 늘어놓는다. 뭘 더 모아야 하는지 눈으로 바로 보이게 한다.
func describe() -> String:
	var lines: PackedStringArray = [display_name()]

	var result := result_item()
	if result != null and not result.description.is_empty():
		lines.append(result.description)

	for id in ingredients:
		var need := ItemDB.get_item(id)
		if need == null:
			continue
		lines.append("%s %d/%d" % [need.item_name, Inventory.count_item(need), ingredients[id]])

	return "\n".join(lines)


## id 가 전부 표에 있는지. 문자열로 적는 대가라 어딘가에서 한 번은 훑어야 한다.
func validate() -> PackedStringArray:
	var problems: PackedStringArray = []

	if not ItemDB.has_item(result_id):
		problems.append("결과물 id 없음: %s" % result_id)

	for id in ingredients:
		if not ItemDB.has_item(id):
			problems.append("재료 id 없음: %s" % id)
		elif ingredients[id] <= 0:
			problems.append("재료 개수가 0 이하: %s" % id)

	return problems
