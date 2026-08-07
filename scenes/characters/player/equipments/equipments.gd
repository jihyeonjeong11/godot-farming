class_name Equipments
extends Node2D

@onready var hit_component: ApoHitComponent = $HitComponent
@onready var hit_shape: CollisionShape2D = $HitComponent/HitComponentShape2D

const QUICK_SLOT_ACTIONS: Array[StringName] = [
	&"select_inventory_1",
	&"select_inventory_2",
	&"select_inventory_3",
	&"select_inventory_4",
	&"select_inventory_5",
	&"select_inventory_6",
	&"select_inventory_7",
	&"select_inventory_8",
	&"select_inventory_9",
	&"select_inventory_10",
]

func _ready() -> void:
	hit_shape.disabled = true
	Inventory.selected_slot_changed.connect(_on_equipped_changed)
	Inventory.inventory_updated.connect(_on_equipped_changed)
	apply_equipped()


func _on_equipped_changed(_index: int = -1) -> void:
	apply_equipped()


func apply_equipped() -> void:
	var item := Inventory.get_selected_item()
	if item == null:
		hit_component.current_tool = ApoDataTypes.Tools.None
		hit_component.hit_damage = 0
		hit_component.knockback_vector = Vector2.ZERO
		return

	hit_component.current_tool = item.tool_type
	hit_component.hit_damage = item.melee_damage
	hit_component.knockback_vector = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if not ApoGameInputEvents.use_tool():
		return

	var item := Inventory.get_selected_item()
	if item == null:
		print("빈손")
		return

	match item.item_type:
		"tool":
				swing()
		"melee":
			print("melee 휘두름: %s" % item.item_name)
		_:
			print("액션 없음: %s (item_type=%s)" % [item.item_name, item.item_type])

func swing() -> void:
	hit_shape.set_deferred("disabled", false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	hit_shape.set_deferred("disabled", true)


func _unhandled_input(event: InputEvent) -> void:
	for i in QUICK_SLOT_ACTIONS.size():
		if event.is_action_pressed(QUICK_SLOT_ACTIONS[i]):
			Inventory.select_slot(i)
			get_viewport().set_input_as_handled()
			return
