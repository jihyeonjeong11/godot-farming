extends CanvasLayer

signal transition_started()
signal transition_covered()
signal changing_scene(next_scene_path: String)
signal transition_finished()

# bed -> advance_day -> fade_to_color black -> clear_fade

const FADE_ANIMATION: StringName = &"fade_through_color"

var is_transitioning: bool = false

var scene_path: String = ""
var next_spawn_id: StringName = &""


@onready var color_rect: ColorRect = $Color
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func fade_to_color(color: Color = Color.BLACK, duration: float = 1.0) -> void:
	is_transitioning = true
	transition_started.emit()
	color_rect.color = color
	var middle_time: float = animation_player.get_animation(FADE_ANIMATION).get_marker_time(&"middle")
	animation_player.play_section_with_markers(FADE_ANIMATION, &"start", &"middle", -1, middle_time / duration)
	await animation_player.animation_finished
	transition_covered.emit()


func clear_fade() -> void:
	animation_player.play_section_with_markers(FADE_ANIMATION, &"middle", &"end")
	await animation_player.animation_finished
	animation_player.stop()
	transition_finished.emit()
	is_transitioning = false


func go_to_scene(next_scene: Variant, spawn_id: StringName = &"") -> void:
	if is_transitioning:
		return
	scene_path = next_scene if next_scene is String else next_scene.resource_path
	next_spawn_id = spawn_id
	await fade_to_color(Color.BLACK)
	swap_scene()
	await clear_fade()


func swap_scene() -> void :
	if not scene_path.is_empty():
		changing_scene.emit(scene_path)
		var err = get_tree().change_scene_to_file(scene_path)
		assert (err == OK, "Cannot find scene \"%s\"" % scene_path)
