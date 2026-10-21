extends PanelContainer

@onready var recipe_grid: GridContainer = %InventoryGrid


func _ready() -> void:
	for i in recipe_grid.get_child_count():
		var slot: CraftingSlot = recipe_grid.get_child(i)
		slot.clicked.connect(on_inventory_slot_clicked.bind(i))
	InventoryManager.updated_inventory.connect(refresh_recipes)
	visibility_changed.connect(refresh_recipes)
	refresh_recipes()


func refresh_recipes() -> void:
	var recipes := RecipeDB.all()
	for i in recipe_grid.get_child_count():
		var slot: CraftingSlot = recipe_grid.get_child(i)
		slot.set_recipe(recipes[i] if i < recipes.size() else null)

func on_inventory_slot_clicked(button: MouseButton, _shift: bool, index: int) -> void:
	var recipe: CraftRecipe = (recipe_grid.get_child(index) as CraftingSlot).recipe
	match button:
		MOUSE_BUTTON_LEFT:
			InventoryActions.craft(recipe)
		MOUSE_BUTTON_RIGHT:
			InventoryActions.craft_bulk(recipe)
