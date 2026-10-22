extends Control

const DIR_SUFFIX := {
	Vector2.UP: "up",
	Vector2.LEFT: "left",
	Vector2.DOWN: "down",
	Vector2.RIGHT: "right",
}
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
const CELL := 64

var dir = DIR_SUFFIX[Vector2.DOWN]

func _ready() -> void:
	resized.connect(fit)
	fit()

func fit() -> void:
	var s := maxf(floorf(minf(size.x, size.y) / CELL), 1.0)
	animated_sprite_2d.scale = Vector2(s, s)
	animated_sprite_2d.position = size / 2


func vanity_sprite(part: int) -> VanitySprite:
	for child in animated_sprite_2d.get_children():
		if child is VanitySprite and child.part == part:
			return child
	return null
