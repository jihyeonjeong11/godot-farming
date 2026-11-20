extends CanvasLayer

var activation_code: String = "0129"
var activation_code_so_far: String = ""


## TODO: cheat/dev codes for developer.

var is_active: bool = true
var show_target_info: bool = false
var dev_start_hour: int = 21

const GRID_TOGGLE_KEY := KEY_F9
const SNAPSHOT_KEY := KEY_F2
const RANDOM_NEEDS_KEY := KEY_F3
const TARGET_INFO_KEY := KEY_F10
const SNAPSHOT_VIEW_LAYER := 100
const SNAPSHOT_VIEW_WIDTH := 1200.0
const SNAPSHOT_FONT_SIZE := 22
const SNAPSHOT_BG_COLOR := Color(0.08, 0.08, 0.1, 0.95)
const GRID_COLOR := Color(1, 1, 1, 0.25)
const CURSOR_CELL_COLOR := Color(1, 0.85, 0.2, 0.35)
const TARGET_OBJECT_COLOR := Color(0.3, 1.0, 0.4, 0.9)
const TARGET_BUILDING_COLOR := Color(0.3, 0.7, 1.0, 0.9)
const VANITY_VARIANTS := [3, 2, 3, 2]


var grid_layer: CanvasLayer
var grid: Node2D
var snapshot_layer: CanvasLayer
var snapshot_view: TextEdit
var snapshot_key: String = ""
var snapshot_tabs: HFlowContainer
var level_ids: Array[String] = []

func _ready() -> void :
	if not OS.is_debug_build():
		prints("Disabling OPs in non-debug build.")
		process_mode = ProcessMode.PROCESS_MODE_DISABLED
		return
	#dev_fill_inventory()
	#dev_give_wearables()
	dev_give_tools()
	dev_give_seed()
	#dev_give_recipe_materials(&"campfire")
	dev_give_recipe_materials(&"water_collector")
	dev_give_chest()
	dev_give_sword()
	dev_give_stone()
	dev_give_new_items()
	dev_shuffle_outfit()
	#dev_start_late()
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
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.custom_minimum_size.x = SNAPSHOT_VIEW_WIDTH
	snapshot_layer.add_child(panel)
	snapshot_tabs = HFlowContainer.new()
	panel.add_child(snapshot_tabs)
	snapshot_view = TextEdit.new()
	snapshot_view.editable = false
	snapshot_view.focus_mode = Control.FOCUS_NONE
	snapshot_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	snapshot_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	snapshot_view.add_theme_font_size_override(&"font_size", SNAPSHOT_FONT_SIZE)
	snapshot_view.add_theme_color_override(&"font_readonly_color", Color(0.9, 0.9, 0.9))
	var background := StyleBoxFlat.new()
	background.bg_color = SNAPSHOT_BG_COLOR
	background.set_content_margin_all(8)
	snapshot_view.add_theme_stylebox_override(&"normal", background)
	snapshot_view.add_theme_stylebox_override(&"read_only", background)
	panel.add_child(snapshot_view)


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


func dev_start_late() -> void:
	GameState.current_time["hour"] = dev_start_hour
	SignalBus.new_game_requested.connect(func(_slot: int) -> void: TimeManager.skip_to(0, dev_start_hour))


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


func dev_give_recipe_materials(result_id: StringName) -> void:
	for recipe in RecipeDB.for_result(result_id):
		for id in recipe.ingredients:
			InventoryActions.obtain(ItemStack.new(ItemDB.get_item(id), recipe.ingredients[id]))


func dev_give_chest() -> void:
	InventoryActions.obtain(ItemStack.new(ItemDB.get_item(&"chest"), 1))


func dev_give_sword() -> void:
	InventoryActions.obtain(ItemStack.new(ItemDB.get_item(&"longsword"), 1))


func dev_give_stone() -> void:
	InventoryActions.obtain(ItemStack.new(ItemDB.get_item(&"stone"), 10))


func dev_give_new_items() -> void:
	for id in [&"bandage", &"rope", &"machine_parts", &"jar_of_pickles", &"glass_shards"]:
		InventoryActions.obtain(ItemStack.new(ItemDB.get_item(id), 3))


func dev_give_wearables() -> void:
	for id in DEV_WEARABLES:
		InventoryActions.obtain(ItemStack.new(ItemDB.get_item(id), 1))
		

func dev_open_snapshot() -> void:
	var level := get_tree().current_scene as BaseLevel
	snapshot_key = String(level.level_id) if level != null else ""
	dev_show_snapshot()
	snapshot_layer.visible = true


func dev_cycle_snapshot(step: int) -> void:
	var keys := dev_snapshot_keys()
	var index := keys.find(snapshot_key)
	snapshot_key = keys[wrapi(index + step, 0, keys.size())]
	dev_show_snapshot()


func dev_snapshot_keys() -> Array[String]:
	if level_ids.is_empty():
		dev_scan_level_ids("res://levels")
	var keys: Array[String] = level_ids.duplicate()
	for key: String in GameState.snapshots:
		if key not in keys:
			keys.append(key)
	keys.sort()
	return keys if not keys.is_empty() else [""]


func dev_scan_level_ids(dir_path: String) -> void:
	var regex := RegEx.create_from_string("(?m)^level_id = &\"([^\"]+)\"")
	for file in DirAccess.get_files_at(dir_path):
		if not file.ends_with(".tscn"):
			continue
		var found := regex.search(FileAccess.get_file_as_string(dir_path.path_join(file)))
		if found != null and found.get_string(1) not in level_ids:
			level_ids.append(found.get_string(1))
	for dir in DirAccess.get_directories_at(dir_path):
		dev_scan_level_ids(dir_path.path_join(dir))


func dev_select_snapshot(key: String) -> void:
	snapshot_key = key
	dev_show_snapshot()


func dev_build_snapshot_tabs(keys: Array[String]) -> void:
	for child in snapshot_tabs.get_children():
		child.queue_free()
	for key in keys:
		var button := Button.new()
		button.text = "%s (%d)" % [key if not key.is_empty() else "-", GameState.snapshots.get(key, {}).size()]
		button.toggle_mode = true
		button.button_pressed = key == snapshot_key
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override(&"font_size", SNAPSHOT_FONT_SIZE)
		button.pressed.connect(dev_select_snapshot.bind(key))
		snapshot_tabs.add_child(button)


func dev_show_snapshot() -> void:
	var keys := dev_snapshot_keys()
	dev_build_snapshot_tabs(keys)
	var snapshot: Dictionary = GameState.snapshots.get(snapshot_key, {})
	var lines := PackedStringArray()
	lines.append("%s  (%d칸)   PgUp/PgDn: 키 변경" % [snapshot_key if not snapshot_key.is_empty() else "-", snapshot.size()])
	lines.append("")
	var cells := snapshot.keys()
	cells.sort()
	for cell in cells:
		lines.append("%s  %s" % [cell, snapshot[cell]])
	snapshot_view.text = "\n".join(lines)


func dev_randomize_needs() -> void:
	var stats := GameState.player_stat
	if stats == null:
		return
	stats.hunger = randi_range(0, stats.current_max_hunger)
	stats.thirst = randi_range(0, stats.current_max_thirst)
	prints("[dev] 허기/갈증:", stats.hunger, stats.thirst)


func _input(event: InputEvent) -> void :
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == GRID_TOGGLE_KEY:
		grid_layer.visible = not grid_layer.visible
		return
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == SNAPSHOT_KEY:
		if snapshot_layer.visible:
			snapshot_layer.visible = false
		else:
			dev_open_snapshot()
		return
	if is_active and snapshot_layer.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN]:
		dev_cycle_snapshot(-1 if event.keycode == KEY_PAGEUP else 1)
		get_viewport().set_input_as_handled()
		return
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == RANDOM_NEEDS_KEY:
		dev_randomize_needs()
		return
	if is_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == TARGET_INFO_KEY:
		show_target_info = not show_target_info
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
