extends Sprite2D

@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

@export var drop_items: Array[Items] = []

## 한 종류당 떨어지는 개수 범위.
@export var min_drop_count: int = 1
@export var max_drop_count: int = 2

## 떨어진 것이 밑동에서 흩어지는 거리(px).
@export var scatter_radius: float = 20.0

## 흩어지는 데 걸리는 시간(초).
## CollectableComponent.arm_delay(0.35)보다 짧아야 한다 — 자석이 켜진 뒤에는
## 그쪽이 global_position을 직접 밀기 때문에 서로 잡아당긴다.
const SCATTER_TIME := 0.25


func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	damage_component.max_damaged_reached.connect(on_max_damage_reached)
	animated_sprite_2d.hide()


func on_hurt(hit_damage: int) -> void:
	SignalBus.sound_requested.emit(AudioManager.SFX_TREE_HITTING)
	damage_component.apply_damage(hit_damage)
	material.set_shader_parameter("shake_intensity", 1.0)
	await get_tree().create_timer(0.3).timeout
	material.set_shader_parameter("shake_intensity", 0.0)


func on_max_damage_reached() -> void:
	animated_sprite_2d.show()
	animated_sprite_2d.play("default")
	await animated_sprite_2d.animation_finished
	# 신호를 받는 도중에 부모 트리에 노드를 붙이면 Godot이 싫어한다.
	spill_items.call_deferred()
	queue_free()


func spill_items() -> void:
	var host := get_parent()
	if host == null:
		return

	var spilled: Array[Node2D] = []
	for item in drop_items:
		if item == null:
			continue
		for i in randi_range(min_drop_count, max_drop_count):
			var dropped := DROPPED_ITEM.instantiate() as Node2D
			# add_child가 _ready를 돌리므로 그 전에 무엇인지 알려준다.
			dropped.item = item
			host.add_child(dropped)

			# 노드가 트리에 들어간 뒤에 좌표를 준다. 부모가 옮겨져 있으면
			# 붙이기 전에 넣은 global_position은 로컬 좌표로 오해받는다.
			dropped.global_position = global_position
			spilled.append(dropped)

	# 몇 개가 나왔는지 다 세고 나서 부채꼴을 나눈다.
	for i in spilled.size():
		var target := global_position + _scatter_offset(i, spilled.size())
		spilled[i].create_tween().tween_property(
			spilled[i], "global_position", target, SCATTER_TIME
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 밑동 아래쪽으로 부채꼴. 위로 던지면 자판기 스프라이트에 가려서 안 보인다.
func _scatter_offset(index: int, total: int) -> Vector2:
	if total <= 1:
		return Vector2.DOWN * scatter_radius

	var t := float(index) / float(total - 1)
	var angle := lerpf(PI * 0.15, PI * 0.85, t)
	return Vector2.RIGHT.rotated(angle) * scatter_radius
