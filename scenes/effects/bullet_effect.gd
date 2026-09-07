class_name BulletEffect
extends HitComponent

const SPEED := 520.0
const MAX_DISTANCE := 180.0
const THICKNESS := 6.0

@onready var visual: Sprite2D = $Visual
@onready var sweep: CollisionShape2D = $CollisionShape2D

var shooter: Node = null

var _direction := Vector2.RIGHT
var _travelled := 0.0


func _ready() -> void:
	area_entered.connect(on_area_entered)


func launch(direction: Vector2, damage: int, knockback: int) -> void:
	_direction = direction.normalized()
	hit_damage = damage
	knockback_vector = _direction * knockback
	visual.rotation = _direction.angle() + PI

	var step := SPEED / float(Engine.physics_ticks_per_second)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(step + THICKNESS, THICKNESS)
	sweep.shape = rect
	sweep.rotation = _direction.angle()
	sweep.position = -_direction * step * 0.5


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	position += _direction * step
	_travelled += step

	if _travelled >= MAX_DISTANCE:
		queue_free()


func on_area_entered(area: Area2D) -> void:
	if area is not HurtComponent or area.owner == shooter:
		return

	queue_free()
