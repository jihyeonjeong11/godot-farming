class_name Menu extends VerticalMenu

signal actioned_with_effect(item: Control)


enum ActionEffects{
	None, 
	Flash
}


@export var selection_changed_sound: AudioStream
@export var actioned_sound: AudioStream
@export var play_actioned_sound: bool = true
@export var cancel_sound: AudioStream
@export var play_cancel_sound: bool = true
@export var action_effect: ActionEffects = ActionEffects.None

func _on_focus_entered(item: Control) -> void :
	if play_actioned_sound and actioned_sound:
		SoundManager.play_ui_sound(actioned_sound)

	match action_effect:
		ActionEffects.Flash:
			lock()
			pointer.select()
			await get_tree().create_timer(0.5).timeout
			unlock()

	actioned_with_effect.emit(item)


func _on_menu_actioned(item: Control) -> void :
	if play_actioned_sound and actioned_sound:
		SoundManager.play_ui_sound(actioned_sound)

	match action_effect:
		ActionEffects.Flash:
			lock()
			pointer.select()
			await get_tree().create_timer(0.5).timeout
			unlock()

	actioned_with_effect.emit(item)


func _on_menu_selection_changed(_item: Control) -> void :
	if selection_changed_sound and is_visible_in_tree():
		SoundManager.play_ui_sound(selection_changed_sound)


func _on_menu_focused(_item: Control) -> void :
	pointer.point.call_deferred()


func _on_cancelled() -> void :
	if play_cancel_sound and cancel_sound:
		SoundManager.play_ui_sound(cancel_sound)
