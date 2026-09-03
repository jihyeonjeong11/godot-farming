extends Control

const GAME_THEME := preload("res://scenes/ui/game_theme.tres")
const PANEL_TEX := preload("res://assets/UI/nine_slice_panel.png")

const MAX_TOAST_LIMIT := 3
const TOAST_HEIGHT := 40.0
const TOAST_GAP := 4.0
const ICON_SIZE := 24.0
const MARGIN := 20.0
const RISE := 24.0
const FADE := 0.2
const HOLD := 2.0

var toasts: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Inventory.item_gained.connect(_on_item_gained)


func _on_item_gained(item: Items, amount: int) -> void:
	if item == null:
		return
	show_toast(item.item_texture, "+%d" % amount)


func show_toast(icon: Texture2D, text: String) -> void:
	if toasts.size() >= MAX_TOAST_LIMIT:
		_dismiss(toasts[0])

	var panel := _build_panel(icon, text)
	toasts.append(panel)
	add_child(panel)
	_start(panel)


func _panel_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = PANEL_TEX
	style.set_texture_margin_all(8)
	style.set_content_margin_all(8)
	return style


func _build_panel(icon: Texture2D, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = GAME_THEME
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.custom_minimum_size.y = TOAST_HEIGHT
	panel.modulate.a = 0.0

	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -MARGIN
	panel.offset_top = -MARGIN
	panel.offset_right = -MARGIN
	panel.offset_bottom = -MARGIN

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = text
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	return panel


func _start(panel: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(panel):
		return

	panel.set_meta("base_y", panel.position.y)
	_move_to_slot(panel, toasts.find(panel), true)

	var life := panel.create_tween()
	panel.set_meta("life", life)
	life.tween_property(panel, "modulate:a", 1.0, FADE)
	life.tween_interval(HOLD)
	life.tween_property(panel, "modulate:a", 0.0, FADE)
	life.tween_callback(_expire.bind(panel))


func _move_to_slot(panel: Control, index: int, rising: bool) -> void:
	var target: float = panel.get_meta("base_y") - index * (TOAST_HEIGHT + TOAST_GAP)

	if panel.has_meta("move"):
		var prev: Tween = panel.get_meta("move")
		if prev != null and prev.is_valid():
			prev.kill()

	if rising:
		panel.position.y = target + RISE

	var move := panel.create_tween()
	panel.set_meta("move", move)
	move.tween_property(panel, "position:y", target, FADE) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _relayout() -> void:
	for i in toasts.size():
		if toasts[i].has_meta("base_y"):
			_move_to_slot(toasts[i], i, false)


func _expire(panel: Control) -> void:
	toasts.erase(panel)
	panel.queue_free()
	_relayout()


func _dismiss(panel: Control) -> void:
	if panel.has_meta("life"):
		var life: Tween = panel.get_meta("life")
		if life != null and life.is_valid():
			life.kill()

	toasts.erase(panel)

	var out := panel.create_tween()
	out.tween_property(panel, "modulate:a", 0.0, FADE)
	out.tween_callback(panel.queue_free)

	_relayout()
