class_name CraftingSlot
extends BaseInventorySlot

const RECIPE_TOOLTIP = preload("res://ui/reusables/craftings_panel/recipe_tooltip.tscn")
const LOCKED_ICON_COLOR := Color(1, 1, 1, 0.35)
const ICON_COLORS := [
	&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color",
	&"icon_hover_pressed_color", &"icon_focus_color", &"icon_disabled_color",
]

var recipe: CraftRecipe


func set_recipe(value: CraftRecipe) -> void:
	recipe = value
	set_stack(ItemStack.new(recipe.result_item(), recipe.result_amount) if recipe != null else null)
	set_craftable(recipe == null or recipe.can_craft())


func set_craftable(craftable: bool) -> void:
	for key in ICON_COLORS:
		if craftable:
			remove_theme_color_override(key)
		else:
			add_theme_color_override(key, LOCKED_ICON_COLOR)


func _make_custom_tooltip(_for_text: String) -> Object:
	if recipe == null:
		return null
	var tip: RecipeTooltip = RECIPE_TOOLTIP.instantiate()
	tip.show_recipe(recipe)
	return tip
