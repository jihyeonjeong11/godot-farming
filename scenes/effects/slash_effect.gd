class_name SlashEffect
extends AnimatedSprite2D

const ART_SCALE := 1.4

const DIR_OFFSET := {
	&"back": Vector2(-16, -45),
	&"front": Vector2(-16, -29),
	&"left": Vector2(-28, -34),
	&"right": Vector2(-16, -34),
}


func _ready() -> void:
	animation_finished.connect(queue_free)


func play_direction(suffix: StringName, duration: float = 0.0) -> void:
	if sprite_frames == null or not sprite_frames.has_animation(suffix):
		queue_free()
		return

	offset = DIR_OFFSET[suffix]
	scale = Vector2(ART_SCALE, ART_SCALE)

	var length := clip_length(suffix)
	if duration > 0.0 and length > 0.0:
		speed_scale = length / duration

	play(suffix)


func clip_length(clip: StringName) -> float:
	var count := sprite_frames.get_frame_count(clip)
	var fps := sprite_frames.get_animation_speed(clip)
	if count <= 0 or fps <= 0.0:
		return 0.0

	return count / fps
