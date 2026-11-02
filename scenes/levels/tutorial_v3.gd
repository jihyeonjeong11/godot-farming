extends "res://scenes/levels/base_level.gd"

const LONGSWORD = preload("uid://cc468nspnvreg")
const ARROW_MARGIN := 56.0

@onready var player: Player = $Player
@onready var corpse: Node2D = $CorpseSoldier
@onready var pen_zombie: CharacterBody2D = $PenZombie
@onready var horde_zombie: CharacterBody2D = $Horde/Zombie

@onready var corpse_gate: Area2D = $Stages/CorpseGate
@onready var check_corpse: Actionable = $Stages/CorpseGate/CheckCorpse
@onready var pen_gate: Area2D = $Stages/PenGate
@onready var need_weapon: Actionable = $Stages/PenGate/NeedWeapon
@onready var pen_blocker: StaticBody2D = $Stages/PenBlocker
@onready var horde_gate: Area2D = $Stages/HordeGate
@onready var anomaly_gate: Area2D = $Stages/AnomalyGate
@onready var anomaly_passed_gate: Area2D = $Stages/AnomalyPassedGate
@onready var back_gate: Area2D = $Stages/BackGate
@onready var back_blocker: StaticBody2D = $Stages/BackBlocker
@onready var back_gate_marker: Marker2D = $Stages/BackGateMarker
@onready var exit_marker: Marker2D = $Stages/ExitMarker

var flags: Dictionary = {}
var objective_target: Node2D
var objective_label: Label
var objective_arrow: Polygon2D


func _enter() -> void:
	SoundManager.play_ambient_sound(preload("uid://bdj6ooc1akmde"))
	_build_objective_ui()

	corpse_gate.body_entered.connect(_on_corpse_gate_body_entered)
	pen_gate.body_entered.connect(_on_pen_gate_body_entered)
	horde_gate.body_entered.connect(_on_horde_gate_body_entered)
	anomaly_gate.body_entered.connect(_on_anomaly_gate_body_entered)
	anomaly_passed_gate.body_entered.connect(_on_anomaly_passed_gate_body_entered)
	back_gate.body_entered.connect(_on_back_gate_body_entered)
	pen_zombie.stats.health_depleted.connect(_on_pen_zombie_killed)
	InventoryManager.updated_inventory.connect(_check_weapon)

	_set_objective("Search the corpse in the yard", corpse)
	_flag("startup")
	dialogue("start")
	_check_weapon()


func _process(_delta: float) -> void:
	_update_objective_arrow()


func _flag(key: String) -> bool:
	if flags.has(key):
		return false
	flags[key] = true
	return true


func _build_objective_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	objective_label = Label.new()
	objective_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	objective_label.offset_top = 24.0
	objective_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 30)
	objective_label.add_theme_constant_override("outline_size", 8)
	objective_label.add_theme_color_override("font_outline_color", Color.BLACK)
	layer.add_child(objective_label)

	objective_arrow = Polygon2D.new()
	objective_arrow.polygon = PackedVector2Array([Vector2(18, 0), Vector2(-12, -13), Vector2(-5, 0), Vector2(-12, 13)])
	objective_arrow.color = Color(1.0, 0.85, 0.3)
	layer.add_child(objective_arrow)


func _set_objective(text: String, target: Node2D) -> void:
	objective_label.text = text
	objective_target = target


func _flash_objective() -> void:
	var tween := create_tween()
	tween.tween_property(objective_label, "modulate", Color(1.0, 0.4, 0.4), 0.12)
	tween.tween_property(objective_label, "modulate", Color.WHITE, 0.12)
	tween.set_loops(2)


func _update_objective_arrow() -> void:
	if not is_instance_valid(objective_target):
		objective_arrow.visible = false
		return
	objective_arrow.visible = true

	var screen := get_viewport().get_visible_rect().size
	var point := get_viewport().get_canvas_transform() * objective_target.global_position
	var bounds := Rect2(Vector2.ZERO, screen).grow(-ARROW_MARGIN)
	if bounds.has_point(point):
		objective_arrow.position = point + Vector2(0, -110 + sin(Time.get_ticks_msec() * 0.006) * 8.0)
		objective_arrow.rotation = PI / 2.0
		return

	var center := screen / 2.0
	var direction := (point - center).normalized()
	var reach := minf(
		(center.x - ARROW_MARGIN) / maxf(absf(direction.x), 0.001),
		(center.y - ARROW_MARGIN) / maxf(absf(direction.y), 0.001))
	objective_arrow.position = center + direction * reach
	objective_arrow.position.y = maxf(objective_arrow.position.y, 90.0)
	objective_arrow.rotation = direction.angle()


func _on_corpse_gate_body_entered(body: Node2D) -> void:
	if not body is Player or not _flag("sighted_corpse"):
		return
	_set_objective("Search the corpse for a weapon [E]", corpse)
	check_corpse.action()


func _check_weapon() -> void:
	if flags.has("obtained_sword") or InventoryManager.count_item(LONGSWORD) == 0:
		return
	_flag("obtained_sword")
	pen_gate.queue_free()
	pen_blocker.queue_free()
	_set_objective("Kill the zombie in the pen", pen_zombie)
	dialogue("obtained_sword")
	SessionState.change_camera_target(pen_zombie)
	await DialogueManager.dialogue_ended
	SessionState.change_camera_target(player)


func _on_pen_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	body.is_freeze = true
	body.face(Vector2.DOWN)
	need_weapon.action()
	await need_weapon.dialogue_ended
	body.is_freeze = false


func _on_pen_zombie_killed() -> void:
	if not _flag("killed_pen_zombie"):
		return
	back_blocker.queue_free()
	_set_objective("Head to the north gate", back_gate_marker)


func _on_horde_gate_body_entered(body: Node2D) -> void:
	if not body is Player or not _flag("sighted_horde"):
		return
	horde_gate.queue_free()
	dialogue("zombie_horde")
	SessionState.change_camera_target(horde_zombie)
	await DialogueManager.dialogue_ended
	SessionState.change_camera_target(player)


func _on_anomaly_gate_body_entered(body: Node2D) -> void:
	if not body is Player or not _flag("sighted_anomaly"):
		return
	anomaly_gate.queue_free()
	dialogue("anomaly")


func _on_anomaly_passed_gate_body_entered(body: Node2D) -> void:
	if not body is Player or not flags.has("sighted_anomaly") or not _flag("passed_anomaly"):
		return
	anomaly_passed_gate.queue_free()
	dialogue("anomaly_passed")


func _on_back_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if not flags.has("killed_pen_zombie"):
		_flash_objective()
		return
	if not _flag("arrived_back_gate"):
		return
	back_gate.queue_free()
	_set_objective("Leave the camp", exit_marker)
	dialogue("entrance_arrived")
