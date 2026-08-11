class_name ApoCollectableComponent
extends Area2D
## 월드에 떨어진 아이템을 플레이어에게 빨려들어가게 만드는 컴포넌트.
##
## Area2D 반경이 자석 감지 범위, [member pickup_distance]가 실제 획득 거리다.
## 감지되면 부모 노드가 플레이어를 향해 가속하며 이동한다.

## 이 컴포넌트가 지급할 아이템 정의.
@export var item: Items

## 플레이어와 이 거리 안까지 붙으면 획득(px).
@export var pickup_distance := 4.0
## 최대 비행 속도(px/s).
@export var max_speed := 140.0
## 가속(px/s²). 처음엔 느리게 출발해 붙을수록 빨라진다.
@export var acceleration := 400.0

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


func _ready() -> void:
	set_physics_process(false)
	if arm_delay <= 0.0:
		return
	# monitoring을 껐다 켜면 이미 겹쳐 있던 body에 대해서도 body_entered가 다시 발동한다.
	monitoring = false
	await get_tree().create_timer(arm_delay).timeout
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is ApoPlayer):
		return
	if item == null:
		push_warning("item 미지정: %s" % get_parent().name)
		return
	_target = body
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var host := get_parent() as Node2D
	if host == null or _target == null:
		return

	var to_player: Vector2 = _target.global_position - host.global_position
	if to_player.length() <= pickup_distance:
		_collect()
		return

	_speed = minf(_speed + acceleration * delta, max_speed)
	host.global_position += to_player.normalized() * _speed * delta


func _collect() -> void:
	if Inventory.add_item(item) == true:
		_collected = true
		set_physics_process(false)
		get_parent().queue_free()
		
		return

	if not _warned:
		_warned = true
		push_warning("인벤토리에 넣지 못했습니다: %s" % item.item_name)
	set_physics_process(false)
	_target = null
