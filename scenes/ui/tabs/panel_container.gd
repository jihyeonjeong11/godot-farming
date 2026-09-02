extends MarginContainer

var panels: Array[PanelContainer] = []

@onready var inventory: Button = %Inventory
@onready var crafting: Button = %Crafting
@onready var stats: Button = %Stats
@onready var settings: Button = %Settings

@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var crafting_panel: PanelContainer = %CraftingPanel
@onready var stats_panel: PanelContainer = %StatsPanel
@onready var settings_panel: PanelContainer = %SettingsPanel


func _ready() -> void:
	panels = [
		inventory_panel, crafting_panel, stats_panel, settings_panel
	]
	
	inventory.pressed.connect(show_panel.bind(panels[0]))
	crafting.pressed.connect(show_panel.bind(panels[1]))
	stats.pressed.connect(show_panel.bind(panels[2]))
	settings.pressed.connect(show_panel.bind(panels[3]))


func show_panel(panel_to_show: PanelContainer) -> void:
	for panel in panels:
		panel.hide()
		
	panel_to_show.show()
