@icon("res://ui/reusables/panel_anchor/panel_anchor.svg")
class_name PanelAnchor extends Node2D


signal appeared()
signal disappeared()


@export var underlay: ColorRect
@export var menu: Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func appear() -> void :
	animation_player.play(&"appear")


	if is_instance_valid(menu) and not is_instance_valid(menu.get_focused_item()):
		menu.focus_first_item()

	if Settings.assist_menu_animations_is_on:
		if is_instance_valid(underlay):
			var tween: Tween = create_tween()
			tween.tween_property(underlay, "color:a", 0.5, 0.2).from(0)
		if is_instance_valid(menu):
			menu.seconds_before_accepting_input = 0.3
		await animation_player.animation_finished
	else:
		animation_player.seek(animation_player.current_animation_length)
		if is_instance_valid(underlay):
			underlay.color.a = 0.5
	appeared.emit()


	if is_instance_valid(menu) and not is_instance_valid(menu.get_focused_item()):
		menu.focus_first_item()


func disappear() -> void :
	animation_player.play(&"disappear")
	if Settings.assist_menu_animations_is_on:
		if is_instance_valid(underlay):
			var tween: Tween = create_tween()
			tween.tween_property(underlay, "color:a", 0, 0.2).from(0.5)
		await animation_player.animation_finished
	else:
		animation_player.seek(animation_player.current_animation_length)
		if is_instance_valid(underlay):
			underlay.color.a = 0
	hide()
	disappeared.emit()





func _on_visibility_changed() -> void :
	if is_instance_valid(underlay):
		underlay.visible = visible
