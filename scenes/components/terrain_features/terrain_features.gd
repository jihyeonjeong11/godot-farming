extends Node

var farm_grid: Dictionary = {}
var dropped_objects: Array[Item] = []

const FARM_TILE_WIDTH = 32
const FARM_TILE_HEIGHT = 32

@onready var tilemap: TileMapLayer = $"../Tilemap"
@onready var level: Node2D = $"../Level"

var groups: Dictionary = {
	"nature": "nature",
}



func _ready() -> void:
	farm_grid = build_farm_grid()


func build_farm_grid() -> Dictionary:
	var grid := {}

	for y in FARM_TILE_HEIGHT:
		for x in FARM_TILE_WIDTH:
			grid[Vector2i(x, y)] = {}

	return grid


func has_cell(coords: Vector2i) -> bool:
	return farm_grid.has(coords)


func get_cell(coords: Vector2i) -> Dictionary:
	return farm_grid.get(coords, {})
