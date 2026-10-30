extends Camera2D

const PAN_SPEED := 900.0
const ZOOM_STEP := 1.15

var _dragging := false


func _process(delta: float) -> void:
	var dir := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	position += dir * PAN_SPEED * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			zoom = (zoom * ZOOM_STEP).clamp(Vector2.ONE * 0.1, Vector2.ONE * 6.0)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			zoom = (zoom / ZOOM_STEP).clamp(Vector2.ONE * 0.1, Vector2.ONE * 6.0)
		elif button.button_index == MOUSE_BUTTON_MIDDLE or button.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = button.pressed
	elif event is InputEventMouseMotion and _dragging:
		position -= (event as InputEventMouseMotion).relative / zoom.x
