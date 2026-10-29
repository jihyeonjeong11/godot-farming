extends Node2D

## 포물선으로 날아가는 산성 덩어리. 루트는 떨어질 자리에 두고 덩어리 그림만 날아간다.
## 그림자와 판정이 처음부터 그 자리에 있어야 플레이어가 보고 피할 수 있다.

const ACID_PUDDLE := preload("res://scenes/characters/enemy/zombie_spitter/acid_puddle.tscn")

@export var flight_time: float = 0.8
@export var arc_height: float = 48.0
## 떨어진 순간 판정을 열어두는 시간.
@export var impact_time: float = 0.1

var start_position: Vector2
var elapsed: float = 0.0
var landed: bool = false

@onready var glob: Sprite2D = $Glob
@onready var shadow: Sprite2D = $Shadow
@onready var hit_shape: CollisionShape2D = $HitComponent/CollisionShape2D


## add_child 다음에 부른다.
func launch(from: Vector2, to: Vector2) -> void:
	start_position = from
	global_position = to
	update_flight(0.0)


func _physics_process(delta: float) -> void:
	elapsed += delta

	if landed:
		if elapsed >= impact_time:
			finish()
		return

	var k: float = minf(elapsed / flight_time, 1.0)
	update_flight(k)
	if k >= 1.0:
		land()


func update_flight(k: float) -> void:
	var arc: float = 4.0 * k * (1.0 - k) * arc_height
	glob.global_position = start_position.lerp(global_position, k) + Vector2.UP * arc
	shadow.scale = Vector2.ONE * lerpf(0.4, 1.0, k)


func land() -> void:
	landed = true
	elapsed = 0.0
	glob.hide()
	hit_shape.set_deferred("disabled", false)


func finish() -> void:
	set_physics_process(false)
	var puddle := ACID_PUDDLE.instantiate() as Node2D
	get_parent().add_child(puddle)
	puddle.global_position = global_position
	queue_free()
