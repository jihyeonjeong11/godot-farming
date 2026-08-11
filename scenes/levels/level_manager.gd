class_name LevelManager
extends Node

@export_file("*.tscn") var scene_farm := "res://scenes/apo_test_scene_forest.tscn"
@export_file("*.tscn") var scene_city := "res://scenes/apo_test_scene_outside.tscn"
@export_file("*.tscn") var scene_mainmenu := "res://scenes/mainmenu.tscn"

@onready var current_level: ApoDataTypes.Levels


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 게임 처음 시작.
	if true:
		current_level = ApoDataTypes.Levels.MainMenu
