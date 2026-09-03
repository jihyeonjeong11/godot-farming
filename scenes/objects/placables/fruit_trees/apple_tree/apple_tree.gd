extends Sprite2D

const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

## 흔들면 떨어질 아이템. 씬이 무엇이 떨어지는지 들고 있고,
## 떨어진 물건 쪽은 공용 dropped_item.tscn 하나를 돌려쓴다.
@export var fruit_item: Item

## 사과가 밑동에서 흩어질 때까지 걸리는 시간(초).
## CollectableComponent.arm_delay(0.35)보다 짧아야 한다 — 자석이 켜진 뒤에는
## 그쪽이 global_position을 직접 밀기 때문에 서로 잡아당긴다.
const SCATTER_TIME := 0.25

## 상호작용 한 번에 넣어주는 초기 흔들림 세기(px).
@export var shake_strength: float = 3.0

## 흔들림이 0까지 잦아드는 데 걸리는 시간(초).
@export var shake_duration: float = 0.6

## 한 번 흔들 때 떨어지는 사과 개수.
@export var apples_per_shake: int = 3

## 사과가 밑동에서 흩어지는 거리(px).
@export var scatter_radius: float = 18.0

@onready var interactable_component: InteractableComponent = $InteractableComponent

var _shake_tween: Tween

## 스듀처럼 한 번 털면 재고가 빈다. 빈 나무도 흔들리기는 한다.
## 다시 열리게 하려면 restock()을 부른다 — 지금은 부르는 쪽이 없다.
var _has_fruit := true


func _ready() -> void:
	interactable_component.interacted.connect(on_interacted)


func on_interacted() -> void:
	SignalBus.sound_requested.emit("TREE_SHAKING")
	shake()

	if not _has_fruit:
		return

	_has_fruit = false
	# 신호를 받는 도중에 부모 트리에 노드를 붙이면 Godot이 싫어한다.
	drop_apples.call_deferred()


func restock() -> void:
	_has_fruit = true


func shake() -> void:
	# 씬의 ShaderMaterial이 resource_local_to_scene이라 나무마다 따로 흔들린다.
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return

	# 흔드는 도중에 또 흔들면 이전 감쇠가 새 세기를 도로 깎아버린다.
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	shader_material.set_shader_parameter("shake_intensity", shake_strength)

	_shake_tween = create_tween()
	_shake_tween.tween_property(
		shader_material, "shader_parameter/shake_intensity", 0.0, shake_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func drop_apples() -> void:
	var host := get_parent()
	if host == null:
		return

	for i in apples_per_shake:
		var apple := DROPPED_ITEM.instantiate() as Node2D
		apple.item = fruit_item
		host.add_child(apple)

		# 노드가 트리에 들어간 뒤에 좌표를 준다. 부모가 옮겨져 있으면
		# 붙이기 전에 넣은 global_position은 로컬 좌표로 오해받는다.
		apple.global_position = global_position

		apple.create_tween().tween_property(
			apple, "global_position", global_position + _scatter_offset(i), SCATTER_TIME
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 밑동 아래쪽으로 부채꼴. 위로 던지면 나무 스프라이트에 가려서 안 보인다.
func _scatter_offset(index: int) -> Vector2:
	if apples_per_shake <= 1:
		return Vector2.DOWN * scatter_radius

	var t := float(index) / float(apples_per_shake - 1)
	var angle := lerpf(PI * 0.15, PI * 0.85, t)
	return Vector2.RIGHT.rotated(angle) * scatter_radius
