extends Node
## ItemDB 등록과 item_id 기반 세이브 왕복을 확인한다.
## 실행: --headless --path . tools/_verify_item_db.tscn --quit-after 300

const EXPECTED := 127
const DROP := preload("res://scenes/objects/pickables/item_stack_instance.tscn")

var _bad := 0


func _check(label: String, ok: bool) -> void:
	if not ok:
		_bad += 1
	print("%s %s" % ["OK  " if ok else "FAIL", label])


func _ready() -> void:
	_test_db()
	await _test_round_trip()
	print("문제 %d건" % _bad)
	get_tree().quit(1 if _bad > 0 else 0)


func _test_db() -> void:
	print("--- ItemDB ---")
	var ids := ItemDB.all_ids()
	_check("아이템 %d개 (기대 %d)" % [ids.size(), EXPECTED], ids.size() == EXPECTED)

	var axe := ItemDB.get_item(&"axe")
	_check("원본 객체가 나온다",
			axe != null and axe.resource_path == "res://scripts/resources/tools/axe.tres")
	_check("모르는 id 는 없다", ItemDB.has_item(&"stone") and not ItemDB.has_item(&"no_such"))
	_check("junk 100개", ItemDB.of_type(DataTypes.ItemType.Junk).size() == 100)

	var all_items := true
	for id in ids:
		if not (ItemDB.get_item(id) is Item):
			all_items = false
	_check("레시피 .tres 는 안 섞였다", all_items)


func _test_round_trip() -> void:
	print("--- item_type ---")
	# 문자열이던 시절엔 "material" 과 "resource" 가 갈라져 있었다. 합쳤는지 본다.
	var counts := {}
	for id in ItemDB.all_ids():
		var t: DataTypes.ItemType = ItemDB.get_item(id).item_type
		counts[t] = counts.get(t, 0) + 1
	print("  분포: ", counts)

	_check("분류 안 된 것이 없다", not counts.has(DataTypes.ItemType.Misc))
	_check("material 5개 (옛 material 4 + resource 1)",
			counts.get(DataTypes.ItemType.Material, 0) == 5)
	_check("scrap_metal 이 material 로 합쳐졌다",
			ItemDB.get_item(&"scrap_metal").item_type == DataTypes.ItemType.Material)
	_check("seeds 5개", counts.get(DataTypes.ItemType.Seeds, 0) == 5)
	_check("tool 4개", counts.get(DataTypes.ItemType.Tool, 0) == 4)
	_check("툴팁 글자는 그대로", ItemDB.get_item(&"axe").describe().contains("[tool]"))

	print("--- 세이브 왕복 ---")
	var axe := ItemDB.get_item(&"axe")

	var saved: Variant = ItemStack.new(axe, 3).to_dict()
	_check("경로가 아니라 id 로 적힌다",
			saved is Dictionary and saved.get("item_id") == "axe" and not saved.has("item"))

	var back := ItemStack.from_dict(saved)
	_check("되읽으면 같은 원본을 가리킨다",
			back != null and back.item == axe and back.amount == 3)

	_check("id 없는 임시 Item 은 저장 안 된다", ItemStack.new(Item.new(), 1).to_dict() == null)
	_check("모르는 id 는 null", ItemStack.from_dict({"item_id": "no_such", "amount": 1}) == null)
	_check("옛 경로 형식은 이제 안 읽힌다",
			ItemStack.from_dict({"item": "res://scripts/resources/tools/axe.tres"}) == null)

	print("--- 빈 스택 가드 ---")
	# item_id 는 String 이라 null 이 될 수 없다. 예전 가드는 item 이 null 일 때
	# 막아주는 척만 하고 그대로 크래시했다.
	_check("item 이 null 이면 안 유효", not ItemStack.new(null, 1).is_valid())
	_check("id 가 비면 안 유효", not ItemStack.new(Item.new(), 1).is_valid())
	_check("멀쩡한 것은 유효", ItemStack.new(axe, 1).is_valid())
	_check("id 없는 것끼리는 같은 종류가 아니다",
			not ItemStack.new(Item.new(), 1).is_same_kind(Item.new()))
	_check("같은 id 는 같은 종류", ItemStack.new(axe, 1).is_same_kind(ItemDB.get_item(&"axe")))
	_check("다른 id 는 다른 종류", not ItemStack.new(axe, 1).is_same_kind(ItemDB.get_item(&"hoe")))

	print("--- 레벨 초기 배치 ---")
	# level_objects 가 실어 보내는 모양을 실제 노드에 그대로 먹여본다.
	var layer := preload("res://scenes/components/persistent/level_objects.gd").new()
	var entry: Dictionary = layer.initial_objects["axe"]

	var drop := DROP.instantiate() as ItemStackInstance
	add_child(drop)
	drop.apply_state(entry["state"])
	await get_tree().process_frame

	_check("초기 배치가 살아남는다", is_instance_valid(drop))
	if is_instance_valid(drop):
		_check("초기 배치가 제 아이템을 문다", drop.item == axe)
		_check("컴포넌트까지 꽂힌다",
				drop.collectable_component.stack != null
				and drop.collectable_component.stack.item == axe)
