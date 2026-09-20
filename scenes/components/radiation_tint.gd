class_name RadiationTint
extends CanvasLayer

const FEATURE_GROUP := &"map_features"
const PLAYER_GROUP := &"player"

@export var tint_color: Color = Color(0.35, 1.0, 0.2)
@export var max_intensity: float = 10.0
@export var max_alpha: float = 0.45
@export var smoothing: float = 6.0

var _rect: ColorRect
var _alpha: float = 0.0


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.color = Color(tint_color, 0.0)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func _process(delta: float) -> void:
	var target := _target_alpha()
	_alpha = lerpf(_alpha, target, clampf(smoothing * delta, 0.0, 1.0))
	_rect.color = Color(tint_color, _alpha)
	_rect.visible = _alpha > 0.001


func _target_alpha() -> float:
	var features := get_tree().get_first_node_in_group(FEATURE_GROUP)
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	if features == null or player == null or max_intensity <= 0.0:
		return 0.0
	var intensity: float = features.get_effect_intensity(player.global_position, DataTypes.InfluenceType.Radiation)
	return clampf(intensity / max_intensity, 0.0, 1.0) * max_alpha
