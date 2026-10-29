extends Node2D

## 산성 덩어리가 떨어진 자리에 잠깐 남는 장판. 위에 서 있으면 주기마다 맞는다.

@export var lifetime: float = 3.0
@export var tick_interval: float = 0.5
@export var tick_open_time: float = 0.1
@export var fade_time: float = 0.5

var age: float = 0.0
var is_open: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var hit_shape: CollisionShape2D = $HitComponent/CollisionShape2D


func _physics_process(delta: float) -> void:
	age += delta

	if age >= lifetime:
		set_open(false)
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, fade_time)
		tween.tween_callback(queue_free)
		return

	## 서 있기만 하면 area_entered 가 다시 오지 않는다. 판정을 껐다 켜서 주기마다 다시 맞힌다.
	set_open(fmod(age, tick_interval) < tick_open_time)


## disabled 를 매 프레임 set_deferred 하면 헛돈다. 바뀔 때만 건드린다.
func set_open(open: bool) -> void:
	if open == is_open:
		return

	is_open = open
	hit_shape.set_deferred("disabled", not open)
