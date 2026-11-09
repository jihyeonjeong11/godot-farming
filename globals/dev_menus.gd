extends CanvasLayer

var activation_code: String = "0129"
var activation_code_so_far: String = ""


## TODO: cheat/dev codes for developer.

var is_active: bool = true

const GRID_TOGGLE_KEY := KEY_F9
const SNAPSHOT_KEY := KEY_F2
const SNAPSHOT_VIEW_LAYER := 100
const SNAPSHOT_VIEW_WIDTH := 960.0
const GRID_COLOR := Color(1, 1, 1, 0.25)
const CURSOR_CELL_COLOR := Color(1, 0.85, 0.2, 0.35)
const TARGET_OBJECT_COLOR := Color(0.3, 1.0, 0.4, 0.9)
const TARGET_BUILDING_COLOR := Color(0.3, 0.7, 1.0, 0.9)
const VANITY_VARIANTS := [3, 2, 3, 2]


var grid_layer: CanvasLayer
var grid: Node2D
var snapshot_layer: CanvasLayer
var snapshot_view: TextEdit

func _ready() -> void :
	if not OS.is_debug_build():
		prints("Disabling OPs in non-debug build.")
		process_mode = ProcessMode.PROCESS_MODE_DISABLED
		return
	#dev_fill_inventory()
	#dev_give_wearables()
	dev_give_tools()
	dev_give_seed()
	dev_give_campfire_materials()
	dev_give_chest()
	dev_shuffle_outfit()
	dev_build_grid()
	dev_build_snapshot_view()




func _process(_delta: float) -> void:
	if not grid_layer.visible:
		return
	var tilemap := CursorActions.current_land()
	grid.global_transform = tilemap.global_transform if tilemap != null else Transform2D.IDENTITY
	grid.queue_redraw()
	dev_get_mouse_target()

func dev_get_mouse_target() -> void:
	
	pass


func dev_build_grid() -> void:
	grid_layer = CanvasLayer.new()
	grid_layer.follow_viewport_enabled = true
	grid_layer.visible = false
	add_child(grid_layer)
	grid = Node2D.new()
	grid.draw.connect(draw_grid)
	grid_layer.add_child(grid)


func dev_build_snapshot_view() -> void:
	snapshot_layer = CanvasLayer.new()
	snapshot_layer.layer = SNAPSHOT_VIEW_LAYER
	snapshot_layer.visible = false
	add_child(snapshot_layer)
	snapshot_view = TextEdit.new()
	snapshot_view.editable = false
	snapshot_view.focus_mode = Control.FOCUS_NONE
	snapshot_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	snapshot_view.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	snapshot_view.custom_minimum_size.x = SNAPSHOT_VIEW_WIDTH
	snapshot_layer.add_child(snapshot_view)


func draw_grid() -> void:
	var size := float(Constants.tile_size)
	var viewport := get_viewport()
	var world_to_grid := grid.global_transform.affine_inverse()
	var screen_to_grid := world_to_grid * viewport.get_canvas_transform().affine_inverse()
	var view := Rect2(screen_to_grid * Vector2.ZERO, Vector2.ZERO).expand(screen_to_grid * viewport.get_visible_rect().size)
	var first := Vector2i((view.position / size).floor())
	var last := Vector2i((view.end / size).ceil())
	for x in range(first.x, last.x + 1):
		grid.draw_line(Vector2(x, first.y) * size, Vector2(x, last.y) * size, GRID_COLOR)
	for y in range(first.y, last.y + 1):
		grid.draw_line(Vector2(first.x, y) * size, Vector2(last.x, y) * size, GRID_COLOR)
	var target_object = SessionState.target_dict["object"]
	if is_instance_valid(target_object):
		grid.draw_rect(world_to_grid * (target_object as WorldObject).global_collision_rect(), TARGET_OBJECT_COLOR, false)
	var target_building = SessionState.target_dict["building"]
	if is_instance_valid(target_building):
		var building := target_building as Building
		var footprint := world_to_grid * building.global_footprint_rect()
		grid.draw_rect(footprint, TARGET_BUILDING_COLOR, false, 2.0)
		grid.draw_string(ThemeDB.fallback_font, footprint.position + Vector2(2, -4), building.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TARGET_BUILDING_COLOR)
	var target_pos = SessionState.target_dict["pos"]
	if target_pos == null:
		return
	var target_cell := ((world_to_grid * (target_pos as Vector2)) / size).floor()
	grid.draw_rect(Rect2(target_cell * size, Vector2.ONE * size), CURSOR_CELL_COLOR)


func dev_shuffle_outfit() -> void:
	for part in VANITY_VARIANTS.size():
		GameState.player_vanity[part] = randi_range(0, VANITY_VARIANTS[part] - 1)


func dev_fill_inventory() -> void:
	var ids := ItemDB.all_ids()
	ids.shuffle()
	for id in ids.slice(0, 5):
		var item := ItemDB.get_item(id)
		var amount := randi_range(1, ItemStack.slot_capacity(item))
		InventoryActions.obtain(ItemStack.new(item, amount))
	var consumable = ItemDB.dev_get_random_item_by_type(DataTypes.ItemType.Consumable)
	InventoryActions.obtain(ItemStack.new(consumable, 5))

const DEV_WEARABLES := [&"gas_mask", &"bulletproof_vest", &"military_boots"]

func dev_give_tools() -> void:
	for item in ItemDB.of_type(DataTypes.ItemType.Tool):
		InventoryActions.obtain(ItemStack.new(item, 1))


func dev_give_seed() -> void:
	var seed_item = ItemDB.dev_get_random_item_by_type(DataTypes.ItemType.Seeds)
	InventoryActions.obtain(ItemStack.new(seed_item, 5))


func dev_give_campfire_materials() -> void:
	for recipe in RecipeDB.for_result(&"campfire"):
		for id in recipe.ingredients:
			InventoryActions.obtain(ItemStack.new(ItemDB.get_item(id), recipe.ingredients[id]))


func dev_give_chest() -> void:
	InventoryActions.obtain(ItemStack.new(ItemDB.get_item(&"chest"), 1))


func dev_give_wearables() -> void:
	for id in DEV_WEARABLES:
		InventoryActions.obtain(ItemStack.new(ItemDB.get_item(id), 1))
		

## 농장 밖에서는 snapshot()이 빈 값을 돌려준다. 그대로 넣으면 저장해둔 농장 상태가 지워진다.
func dev_save_snapshot() -> void:
	var snapshot := GameState.farm_snapshot
	if snapshot.is_empty():
		prints("[dev] 스냅샷 건너뜀: 저장할 농장 상태가 없다")
	else:
		GameState.farm_snapshot = snapshot
		prints("[dev] 스냅샷 저장:", snapshot.size(), "칸")
	snapshot_view.text = str(snapshot)
	snapshot_layer.visible = true


func _input(event: InputEvent) -> void :
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == GRID_TOGGLE_KEY:
		grid_layer.visible = not grid_layer.visible
		return
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == SNAPSHOT_KEY:
		if snapshot_layer.visible:
			snapshot_layer.visible = false
		else:
			dev_save_snapshot()
		return
	if not is_active and event.is_pressed() and not event.is_echo():
		if event is InputEventKey:
			var key: String = event.as_text().to_lower()
			if key == activation_code[activation_code_so_far.length()]:
				activation_code_so_far += key
				if activation_code_so_far == activation_code:
					is_active = true
					activation_code_so_far = ""
		#elif event is InputEventJoypadButton:
			#var button_index: String = str(event.button_index)
			#if button_index == alt_activation_code[activation_code_so_far.length()]:
				#activation_code_so_far += button_index
				#if activation_code_so_far == activation_code:
					#is_active = true
					#activation_code_so_far = ""
