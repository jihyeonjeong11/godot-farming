extends CanvasLayer

@export var ingame_menu_scene: PackedScene

var ingame_menu: CanvasLayer

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void :
	if not TransitionManager.is_transitioning and event.is_action("pause") and event.is_pressed():
		get_viewport().set_input_as_handled()
		show_ingame_menu()

func show_ingame_menu() -> void :
	if is_instance_valid(ingame_menu):
		return

	ingame_menu = ingame_menu_scene.instantiate()
	add_child(ingame_menu)
