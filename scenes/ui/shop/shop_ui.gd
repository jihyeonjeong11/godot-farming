extends CanvasLayer

# shopType: terminal - 현재는 하나만

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

## 왼쪽이 플레이어 가방, 오른쪽이 상인 물건.
## 거래대는 없다. 칸을 누르면 그 자리에서 한 개씩 오간다.
@onready var bag_grid: GridContainer = %BagGrid
@onready var merchant_grid: GridContainer = %MerchantGrid

var slots: Array = []

var _merchant_cells: Array[InventorySlot] = []
var _bag_cells: Array[InventorySlot] = []


func _ready() -> void:
	Inventory.inventory_updated.connect(refresh)

	# 가방 칸수는 변하지 않으므로 한 번만 만든다. 상인 격자는 상인마다 칸수가
	# 달라서 열 때마다 다시 짓는다(setup).
	_bag_cells = _build_cells(bag_grid, Inventory.inventory, Inventory.BASE_INVENTORY_LIMIT, "BagSlot", sell, "판매가")


## UIManager가 만든 직후에 부른다. 여닫기와 정지는 스택이 정하므로
## 여기서는 무엇을 그릴지만 받는다.
func setup(target_slots: Array) -> void:
	slots = target_slots

	if _merchant_cells.size() != slots.size():
		_merchant_cells = _build_cells(merchant_grid, slots, slots.size(), "MerchantSlot", buy, "구매가")
	else:
		# 칸수가 같아도 상인이 바뀌면 보던 배열이 달라진다. 다시 짓지 않는 대신
		# 출처만 갈아끼운다. 이걸 빼먹으면 앞 상인의 재고를 집게 된다.
		for cell in _merchant_cells:
			cell.source = slots

	refresh()


func refresh() -> void:
	_refresh_cells(_merchant_cells, slots)
	_refresh_cells(_bag_cells, Inventory.inventory)


## 상점은 버튼을 누른 순간에만 스탯이 필요하다. 그때는 플레이어가 이미 트리에
## 있으므로 미리 붙잡아둘 이유가 없다.
func _get_player_stats() -> BaseCharacterStats:
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	return player.stats if player != null else null


## 가방 칸을 눌렀을 때. 한 개를 상인에게 넘기고 값을 받는다.
func sell(index: int) -> void:
	var stack: ItemStack = Inventory.get_item(index)
	if stack == null or stack.item == null:
		return

	var stats: BaseCharacterStats = _get_player_stats()
	if stats == null:
		return

	# 상인이 받아줄 자리가 없으면 물건만 사라지는 일이 없도록 넘기기부터 해본다.
	if not _give_to_merchant(stack.item):
		return

	var price: int = stack.item.value
	Inventory.remove_item(index, 1)
	stats.gold += price

	refresh()


## 상인 칸을 눌렀을 때. 값을 치르고 한 개를 가방으로 옮긴다.
func buy(index: int) -> void:
	var stack: ItemStack = slots[index] if index < slots.size() else null
	if stack == null or stack.item == null:
		return

	var stats: BaseCharacterStats = _get_player_stats()
	if stats == null:
		return

	var price: int = stack.item.value
	if stats.gold < price:
		return

	# 가방이 꽉 찼는데 돈만 나가는 일이 없도록 넣기부터 시도한다.
	if not Inventory.add_item(stack.item):
		return

	stats.gold -= price

	stack.amount -= 1
	if stack.amount <= 0:
		slots[index] = null

	refresh()


## Inventory.add_item과 같은 규칙으로 상인 재고에 한 개를 얹는다.
## 쌓을 수 있으면 쌓고, 아니면 빈 칸을 찾는다. 둘 다 안 되면 false.
func _give_to_merchant(item: Items) -> bool:
	for stack in slots:
		if stack != null and stack.can_stack(item):
			stack.amount += 1
			return true

	for i in slots.size():
		if slots[i] == null:
			slots[i] = ItemStack.new(item, 1)
			return true

	return false


## 격자 하나를 통째로 다시 짓는다. 무엇을 보게 할지(source)와 몇 칸인지(count),
## 눌렀을 때 무엇을 할지(on_pressed), 툴팁에서 값을 뭐라 부를지(price_label)만
## 다르고 나머지는 같아서 두 격자가 이 함수를 쓴다.
func _build_cells(grid: GridContainer, source: Array, count: int, prefix: String, on_pressed: Callable, price_label: String) -> Array[InventorySlot]:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	var cells: Array[InventorySlot] = []

	for i in count:
		var cell: InventorySlot = INVENTORY_SLOT.instantiate()
		cell.name = "%s%d" % [prefix, i]
		cell.slot_index = i
		cell.source = source
		# 여기서는 끌어 옮기기를 막는다. 열어두면 값을 치르지 않고 물건이 오간다.
		cell.draggable = false
		cell.price_label = price_label
		cell.pressed.connect(on_pressed.bind(i))
		grid.add_child(cell)
		cells.append(cell)

	return cells


## 칸이 배열보다 많을 수 있다(상인 재고가 줄어든 경우). 넘치는 칸은 비운다.
func _refresh_cells(cells: Array[InventorySlot], source: Array) -> void:
	for i in cells.size():
		var stack: ItemStack = source[i] if i < source.size() else null
		if stack == null:
			cells[i].clear()
		else:
			cells[i].set_slot(stack)
