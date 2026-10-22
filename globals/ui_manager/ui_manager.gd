extends CanvasLayer

@export var ingame_menu_scene: PackedScene
@export var settings_scene: PackedScene

var ingame_menu: CanvasLayer

func _ready() -> void:
	SignalBus.dialogue_requested.connect(_on_dialogue_requested)

func _on_dialogue_requested(resource: DialogueResource, key: String, from_node: Node) -> void:
	var extra_states: Array = []
	if is_instance_valid(from_node):
		extra_states.append(from_node)
	DialogueManager.show_dialogue_balloon(resource, key, extra_states)

func _input(event: InputEvent) -> void :
	if not TransitionManager.is_transitioning and event.is_action("pause") and event.is_pressed():
		get_viewport().set_input_as_handled()
		show_ingame_menu()

func show_ingame_menu() -> void :
	if is_instance_valid(ingame_menu):
		return

	ingame_menu = ingame_menu_scene.instantiate()
	ingame_menu.settings_requested.connect(show_settings)
	add_child(ingame_menu)

func show_settings() -> void:
	var settings_menu: SettingsMenu = settings_scene.instantiate()
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_menu.closed.connect(on_settings_closed)
	add_child(settings_menu)

func on_settings_closed() -> void:
	SignalBus.pause_game(false)
