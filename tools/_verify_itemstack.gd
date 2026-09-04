extends Node

const WOOD := preload("res://scripts/resources/pickables/log.tres")
const STONE := preload("res://scripts/resources/pickables/stone.tres")
const AXE := preload("res://scripts/resources/tools/axe.tres")
const WATERING_CAN := preload("res://scripts/resources/tools/watering_can.tres")
const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")

var _fails := 0


func _ready() -> void:
	await get_tree().process_frame
	_run()
	print("=== VERIFY %s ===" % ("FAIL(%d)" % _fails if _fails > 0 else "PASS"))
	get_tree().quit()


func _check(label: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("  ok   %s %s" % [label, detail])
	else:
		_fails += 1
		print("  FAIL %s %s" % [label, detail])


func _reset() -> void:
	for i in Inventory.inventory.size():
		Inventory.inventory[i] = null


func _run() -> void:
	print("--- id 비교로 합쳐지는가 (참조가 달라도) ---")
	_reset()
	var clone := WOOD.duplicate() as Item
	Inventory.add_item(ItemStack.new(WOOD, 5))
	Inventory.add_item(ItemStack.new(clone, 3))
	_check("duplicate 도 같은 칸에", Inventory.inventory[0] != null and Inventory.inventory[0].amount == 8,
		"amount=%d, 두번째칸=%s" % [Inventory.inventory[0].amount if Inventory.inventory[0] else -1, Inventory.inventory[1]])
	_check("count_item 이 duplicate 를 센다", Inventory.count_item(clone) == 8, "count=%d" % Inventory.count_item(clone))
	_check("consume_item 이 duplicate 로 깎는다", Inventory.consume_item(clone, 8) and Inventory.count_item(WOOD) == 0)

	print("--- max_stack 을 넘으면 다음 칸으로 ---")
	_reset()
	var ok_big: bool = Inventory.add_item(ItemStack.new(WOOD, 250))
	_check("250개 넣기 성공", ok_big)
	_check("100/100/50 으로 쪼개짐",
		Inventory.inventory[0].amount == 100 and Inventory.inventory[1].amount == 100 and Inventory.inventory[2].amount == 50,
		"%d/%d/%d" % [Inventory.inventory[0].amount, Inventory.inventory[1].amount, Inventory.inventory[2].amount])
	_check("총합 250", Inventory.count_item(WOOD) == 250, "count=%d" % Inventory.count_item(WOOD))

	print("--- 쌓이지 않는 물건(max_stack <= 0)은 칸당 하나 ---")
	_reset()
	Inventory.add_item(ItemStack.new(AXE, 3))
	_check("도끼 3개가 3칸을 쓴다",
		Inventory.inventory[0].amount == 1 and Inventory.inventory[1].amount == 1 and Inventory.inventory[2].amount == 1)
	_check("도끼끼리 can_stack 은 false", not Inventory.inventory[0].can_stack(ItemStack.new(AXE, 1)))

	print("--- item_id 가 비면 절대 합치지 않는다 ---")
	var blank_a := Item.new()
	var blank_b := Item.new()
	blank_a.max_stack = 99
	blank_b.max_stack = 99
	_check("빈 id 끼리 can_stack false", not ItemStack.new(blank_a, 1).can_stack(ItemStack.new(blank_b, 1)))

	print("--- 자리가 없으면 통째로 실패한다 ---")
	_reset()
	for i in Inventory.inventory.size():
		Inventory.inventory[i] = ItemStack.new(STONE, 100)
	var refused: bool = Inventory.add_item(ItemStack.new(WOOD, 1))
	_check("꽉 찬 가방은 거절", not refused)
	_check("거절해도 원본 그대로", Inventory.count_item(STONE) == 3000, "count=%d" % Inventory.count_item(STONE))

	print("--- 세이브 왕복 ---")
	var stack := ItemStack.new(WATERING_CAN, 1)
	var round_trip := ItemStack.from_dict(stack.to_dict())
	_check("to_dict/from_dict 왕복", round_trip != null and round_trip.item.item_id == "watering_can" and round_trip.amount == 1)
	_check("경로 없는 Item 은 null 로", ItemStack.new(Item.new(), 1).to_dict() == null)
	_check("깨진 dict 는 null 로", ItemStack.from_dict({"item": ""}) == null and ItemStack.from_dict(null) == null)

	print("--- ItemStackInstance: item 으로 꽂기 / stack 으로 꽂기 ---")
	var drop_a := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
	drop_a.item = STONE
	add_child(drop_a)
	_check("item 세터가 1개짜리 스택을 만든다", drop_a.stack != null and drop_a.stack.amount == 1 and drop_a.stack.item.item_id == "stone")
	_check("item 게터가 스택에서 나온다", drop_a.item != null and drop_a.item.item_id == "stone")
	_check("CollectableComponent 로 전달됨",
		drop_a.collectable_component.stack != null and drop_a.collectable_component.stack.item.item_id == "stone")

	var drop_b := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
	add_child(drop_b)
	drop_b.stack = ItemStack.new(WOOD, 7)
	_check("붙인 뒤 stack 을 꽂아도 반영", drop_b.item != null and drop_b.item.item_id == "log" and drop_b.stack.amount == 7)
	_check("세이브 왕복", ItemStack.from_dict(drop_b.capture_state()["stack"]).amount == 7)

	var drop_c := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
	add_child(drop_c)
	drop_c.apply_state({"item": STONE.resource_path})
	_check("옛 세이브 형식도 읽힌다", drop_c.stack != null and drop_c.stack.item.item_id == "stone")

	print("--- 상자 채우기 / 세이브 ---")
	var box := ContainerInventoryComponent.new()
	box.slot_count = 4
	add_child(box)
	var seeds: Array[Item] = [WOOD, STONE]
	var counts: Array[int] = [12, 3]
	box.fill(seeds, counts)
	_check("fill 이 스택을 만든다", box.slots[0].amount == 12 and box.slots[1].amount == 3)
	var captured := box.capture()
	box.apply(captured)
	_check("상자 세이브 왕복",
		box.slots[0].amount == 12 and box.slots[0].item.item_id == "log"
		and box.slots[1].amount == 3 and box.slots[1].item.item_id == "stone"
		and box.slots[2] == null,
		"%s/%s" % [box.slots[0].item.item_id, box.slots[1].item.item_id])

	print("--- 조합 ---")
	_reset()
	var recipe := CraftRecipe.new()
	recipe.result = STONE
	recipe.result_amount = 4
	var need := CraftIngredient.new()
	need.item = WOOD
	need.amount = 6
	recipe.ingredients = [need]
	_check("재료 없으면 못 만든다", not Inventory.can_craft(recipe))
	Inventory.add_item(ItemStack.new(WOOD.duplicate() as Item, 6))
	_check("duplicate 재료로도 만들 수 있다", Inventory.can_craft(recipe))
	_check("조합 성공", Inventory.craft(recipe))
	_check("재료 6 소모", Inventory.count_item(WOOD) == 0, "log=%d" % Inventory.count_item(WOOD))
	_check("결과 4개", Inventory.count_item(STONE) == 4, "stone=%d" % Inventory.count_item(STONE))


	print("--- 버리기: 칸 하나가 노드 하나로 ---")
	_reset()
	var stage := Node2D.new()
	add_child(stage)
	var fake_player := Node2D.new()
	fake_player.global_position = Vector2(100, 50)
	stage.add_child(fake_player)
	Inventory.player_node = fake_player

	Inventory.add_item(ItemStack.new(WOOD, 10))
	var before := stage.get_child_count()
	var dropped: bool = Inventory.drop_item(0)
	_check("drop_item 성공", dropped)
	_check("노드는 하나만 생긴다", stage.get_child_count() - before == 1,
		"생긴 수=%d" % (stage.get_child_count() - before))

	var node: ItemStackInstance = null
	for child in stage.get_children():
		if child is ItemStackInstance:
			node = child
	_check("그 노드가 10개를 들고 있다", node != null and node.stack.amount == 10,
		"amount=%d" % (node.stack.amount if node else -1))
	_check("칸은 비었다", Inventory.get_item(0) == null)
	_check("떨군 자리는 플레이어 위치", node != null and node.global_position == Vector2(100, 50))
	_check("CollectableComponent 도 10개", node != null and node.collectable_component.stack.amount == 10)

	# 되줍기: add_item 이 max_stack 을 넘겨 쪼개주는지까지 본다.
	_reset()
	Inventory.add_item(node.stack)
	_check("한 뭉치로 되줍힌다", Inventory.count_item(WOOD) == 10, "count=%d" % Inventory.count_item(WOOD))
