extends Node2D

const PHASE_HOURS := {
	GameState.BaseLighting.Day: 12,
	GameState.BaseLighting.Dusk: 18,
	GameState.BaseLighting.Night: 22,
}
const RADIATION_SHADER := preload("res://scenes/test_scenes/dog_compare/crt.gdshader")
const RADIATION_LAYER := 1

@export var lamp_position := Vector2(610, 930)
@export var firefly_area := Rect2(480, 880, 260, 120)

var _torch: PointLight2D
var _lamp: PointLight2D
var _fireflies: CPUParticles2D
var _status: Label
var _radiation_layer: CanvasLayer
var _radiation_material: ShaderMaterial


func _ready() -> void:
	_build_lamp()
	_build_fireflies()
	_build_radiation()
	_build_ui()
	GameState.lighting_changed.connect(_on_lighting_changed)
	TimeManager.time_tick.connect(_on_time_tick)
	_attach_torch.call_deferred()
	_raise_interface.call_deferred()
	_on_lighting_changed()


func _on_lighting_changed() -> void:
	var lighting := GameState.base_lighting
	_lamp.visible = lighting == GameState.BaseLighting.Night
	_fireflies.emitting = lighting == GameState.BaseLighting.Night
	if _torch != null:
		_torch.visible = lighting != GameState.BaseLighting.Day
	_refresh_status()


func _on_time_tick(_day: int, _hour: int, _minute: int) -> void:
	_refresh_status()


func _attach_torch() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	_torch = PointLight2D.new()
	_torch.texture = _radial_texture(256)
	_torch.color = Color("#ffc878")
	_torch.energy = 1.2
	_torch.texture_scale = 0.6
	player.add_child(_torch)
	_torch.visible = GameState.base_lighting != GameState.BaseLighting.Day


func _build_lamp() -> void:
	_lamp = PointLight2D.new()
	_lamp.texture = _radial_texture(256)
	_lamp.color = Color("#ffe6a0")
	_lamp.energy = 1.5
	_lamp.position = lamp_position
	add_child(_lamp)


func _build_fireflies() -> void:
	_fireflies = CPUParticles2D.new()
	_fireflies.position = firefly_area.get_center()
	_fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_fireflies.emission_rect_extents = firefly_area.size * 0.5
	_fireflies.amount = 24
	_fireflies.lifetime = 4.0
	_fireflies.gravity = Vector2.ZERO
	_fireflies.direction = Vector2.UP
	_fireflies.spread = 180.0
	_fireflies.initial_velocity_min = 2.0
	_fireflies.initial_velocity_max = 8.0
	_fireflies.scale_amount_min = 1.5
	_fireflies.scale_amount_max = 2.5
	_fireflies.color = Color("#f4ff8a")
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color.WHITE)
	fade.add_point(0.7, Color.WHITE)
	_fireflies.color_ramp = fade
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fireflies.material = material
	_fireflies.z_index = 10
	add_child(_fireflies)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	var box := VBoxContainer.new()
	panel.add_child(box)

	_status = Label.new()
	box.add_child(_status)

	for phase in PHASE_HOURS:
		var button := Button.new()
		button.text = "%s (%d시)" % [GameState.BaseLighting.keys()[phase], PHASE_HOURS[phase]]
		button.pressed.connect(_on_phase_button.bind(phase))
		box.add_child(button)

	var radiation_toggle := CheckButton.new()
	radiation_toggle.text = "CRT"
	radiation_toggle.toggled.connect(_on_radiation_toggled)
	box.add_child(radiation_toggle)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = _radiation_material.get_shader_parameter(&"intensity")
	slider.value_changed.connect(_on_radiation_intensity_changed)
	box.add_child(slider)

	var skip := Button.new()
	skip.text = "+1시간"
	skip.pressed.connect(_on_skip_hour)
	box.add_child(skip)


func _build_radiation() -> void:
	_radiation_layer = CanvasLayer.new()
	_radiation_layer.layer = RADIATION_LAYER
	_radiation_layer.visible = false
	add_child(_radiation_layer)

	_radiation_material = ShaderMaterial.new()
	_radiation_material.shader = RADIATION_SHADER
	_radiation_material.set_shader_parameter(&"intensity", 1.0)

	var rect := ColorRect.new()
	rect.material = _radiation_material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radiation_layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _raise_interface() -> void:
	var level := get_parent()
	if not "interface" in level:
		return
	var interface := level.get(&"interface") as CanvasLayer
	if interface != null and interface.layer <= RADIATION_LAYER:
		interface.layer = RADIATION_LAYER + 1


func _on_radiation_toggled(on: bool) -> void:
	_radiation_layer.visible = on


func _on_radiation_intensity_changed(value: float) -> void:
	_radiation_material.set_shader_parameter(&"intensity", value)


func _on_phase_button(phase: GameState.BaseLighting) -> void:
	TimeManager.skip_to(TimeManager.today(), PHASE_HOURS[phase])


func _on_skip_hour() -> void:
	var day := TimeManager.today()
	var hour := int(TimeManager.current_time["hour"]) + 1
	if hour >= TimeManager.HOURS_PER_DAY:
		hour = 0
		day += 1
	TimeManager.skip_to(day, hour, int(TimeManager.current_time["minute"]))


func _refresh_status() -> void:
	if _status == null:
		return
	var time: Dictionary = TimeManager.current_time
	_status.text = "%s\nDay %d  %02d:%02d" % [
		GameState.BaseLighting.keys()[GameState.base_lighting],
		int(time.get("day", 0)),
		int(time.get("hour", 0)),
		int(time.get("minute", 0)),
	]


func _radial_texture(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture
