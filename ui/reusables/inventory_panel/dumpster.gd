extends Control

const FRAME := Vector2(96, 160)

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	resized.connect(fit)
	mouse_entered.connect(open)
	mouse_exited.connect(close)
	animated_sprite_2d.animation = &"open"
	animated_sprite_2d.frame = 0
	fit()


func fit() -> void:
	var s := maxf(floorf(minf(size.x / FRAME.x, size.y / FRAME.y)), 1.0)
	animated_sprite_2d.scale = Vector2(s, s)
	animated_sprite_2d.position = size / 2


func _has_point(point: Vector2) -> bool:
	var frame_size := FRAME * animated_sprite_2d.scale
	return Rect2(animated_sprite_2d.position - frame_size / 2, frame_size).has_point(point)


func open() -> void:
	animated_sprite_2d.play(&"open")


func close() -> void:
	animated_sprite_2d.play_backwards(&"open")


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	InventoryActions.trash_held()
