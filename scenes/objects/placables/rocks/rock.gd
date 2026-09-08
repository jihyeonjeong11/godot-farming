extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")

## 부수면 나올 것. 떨어진 물건 쪽은 공용 item_stack_instance.tscn 하나를 돌려쓴다.
@export var drop_item: Item

@export var drop_count: int = 5

@export var scatter_radius: float = 20.0

const SCATTER_TIME := 0.25

func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damage_reached)
	animated_sprite_2d.hide()

func on_hurt(hit_damage: int) -> void:
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 1.0)
	await get_tree().create_timer(0.3).timeout
	material.set_shader_parameter("shake_intensity", 0.0)

func on_max_damage_reached() -> void:
	animated_sprite_2d.show()
	animated_sprite_2d.play("default")
	await animated_sprite_2d.animation_finished
	add_stone_scene.call_deferred()
	queue_free()

func add_stone_scene() -> void:
	var host := get_parent()
	if host == null or drop_item == null:
		return

	var stones: Array[Node2D] = []
	for i in drop_count:
		var stone_instance := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
		# add_child가 _ready를 돌리므로 그 전에 무엇인지 알려준다.
		stone_instance.stack = ItemStack.new(drop_item, 1)
		host.add_child(stone_instance)
		stone_instance.global_position = global_position
		stones.append(stone_instance)

	for i in stones.size():
		var target := global_position + _scatter_offset(i, stones.size())
		stones[i].create_tween().tween_property(
			stones[i], "global_position", target, SCATTER_TIME
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _scatter_offset(index: int, total: int) -> Vector2:
	if total <= 1:
		return Vector2.DOWN * scatter_radius

	var t := float(index) / float(total - 1)
	var angle := lerpf(PI * 0.15, PI * 0.85, t)
	return Vector2.RIGHT.rotated(angle) * scatter_radius
