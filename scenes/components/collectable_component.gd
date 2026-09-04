class_name CollectableComponent
extends Area2D
## 월드에 떨어진 아이템을 플레이어에게 빨려들어가게 만드는 컴포넌트.
##
## Area2D 반경이 자석 감지 범위, [member pickup_distance]가 실제 획득 거리다.
## 감지되면 부모 노드가 플레이어를 향해 가속하며 이동한다.

## 인스펙터에서 꽂는 원본 스펙. RefCounted 인 ItemStack 은 씬에 저장되지 않으므로
## 씬 쪽 입구는 계속 Item 이다. 꽂으면 1개짜리 뭉치가 만들어진다.
@export var item: Item: set = set_item, get = get_item

## 이 컴포넌트가 지급할 뭉치. ItemStackInstance 은 자기 것을 그대로 넘겨준다.
var stack: ItemStack

## 플레이어와 이 거리 안까지 붙으면 획득(px).
@export var pickup_distance := 4.0
## 최대 비행 속도(px/s). 이 캡에 걸린 뒤로는 등속이라, 프로파일 끝값보다 위에 둬야
## 마지막 구간이 평평해지지 않는다. 여기 걸리는 게 "가속처럼 안 보이는" 주범이었다.
@export var max_speed := 400.0

## 자석 감지 반경(px). item_stack_instance.tscn의 CollisionShape2D 반경과 맞춰둔다.
## 가속을 거리로 스케일하는 기준값이라, 실제 반경과 어긋나면 당기는 세기가 달라진다.
@export var magnet_radius := 40.0
## 반경 끝에서의 가속(px/s²).
@export var acceleration := 900.0
## 가까워질수록 가속이 커지는 정도. 0이면 예전 등가속, 클수록 끝에서 확 빨아들인다.
@export var pull_falloff := 1.5

## 가속이 발산하지 않게 자르는 최소 거리(px).
const PULL_MIN_DIST := 6.0

## 스폰 직후 이 시간 동안 자석을 끈다(초).
## 나무를 베면 로그가 플레이어 바로 옆에 떨어지기 때문에, 이 지연이 없으면
## 즉시 획득돼서 날아오는 연출이 보이지 않는다.
@export var arm_delay := 0.35

## @deprecated: [member item]으로 대체됨. stone.tscn이 아직 참조하고 있어 남겨둠.
@export var collectable_name: String

var _target: Node2D = null
var _speed := 0.0
var _collected := false
var _warned := false


func set_item(value: Item) -> void:
	stack = ItemStack.new(value, 1) if value != null else null


func get_item() -> Item:
	return stack.item if stack != null else null


func _ready() -> void:
	set_physics_process(false)
	if arm_delay <= 0.0:
		return
	monitoring = false
	await get_tree().create_timer(arm_delay).timeout
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	if stack == null or not stack.is_valid():
		push_warning("stack 미지정: %s" % get_parent().name)
		return
	_target = body
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var host := get_parent() as Node2D
	if host == null or _target == null:
		return

	var to_player: Vector2 = _target.global_position - host.global_position
	var dist := to_player.length()
	if dist <= pickup_distance:
		_collect()
		return

	var pull := acceleration * pow(magnet_radius / maxf(dist, PULL_MIN_DIST), pull_falloff)
	_speed = minf(_speed + pull * delta, max_speed)
	host.global_position += to_player.normalized() * minf(_speed * delta, dist)


func _collect() -> void:
	if Inventory.add_item(stack) == true:
		_collected = true
		set_physics_process(false)
		# 부모가 곧 사라지므로 위치 기반 플레이어는 못 쓴다. 전역 SFX 풀로 낸다.
		SignalBus.sound_requested.emit(AudioManager.SFX_ITEM_PICKUP)
		get_parent().queue_free()
		return

	if not _warned:
		_warned = true
		push_warning("인벤토리에 넣지 못했습니다: %s" % stack.item.item_name)
	set_physics_process(false)
	_target = null
