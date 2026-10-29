extends Node2D

## TODO: 오브젝트 인스턴스로 넣어야 방사능 관련 가능함.
@export var cooldown: float = 2.5

var armed: bool = true

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detector: Area2D = $Detector
@onready var cooldown_timer: Timer = $CooldownTimer


func _ready() -> void:
	detector.body_entered.connect(_on_body_entered)
	animation_player.animation_finished.connect(_on_animation_finished)
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	animation_player.play("idle")


func ignite() -> void:
	if not armed:
		return
	armed = false
	animation_player.play("windup")


func _on_body_entered(_body: Node2D) -> void:
	ignite()


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"windup":
			animation_player.play("burst")
		&"burst":
			animation_player.play("cooldown")
			cooldown_timer.start(cooldown)


func _on_cooldown_timeout() -> void:
	armed = true
	animation_player.play("idle")
	if detector.has_overlapping_bodies():
		ignite()
