class_name RecipeTooltip
extends VBoxContainer

const ICON_SIZE := Vector2(40, 40)
const ENOUGH_COLOR := Color(1, 1, 1)
const SHORT_COLOR := Color(0.95, 0.4, 0.35)


func show_recipe(recipe: CraftRecipe) -> void:
	%NameLabel.text = recipe.display_name()

	var result := recipe.result_item()
	var description := str(result.description) if result != null else ""
	%DescriptionLabel.text = description
	%DescriptionLabel.visible = not description.is_empty()

	for child in %IngredientList.get_children():
		child.queue_free()
	for id in recipe.ingredients:
		var item := ItemDB.get_item(id)
		if item != null:
			%IngredientList.add_child(_ingredient_row(item, recipe.ingredients[id]))


func _ingredient_row(item: Item, need: int) -> HBoxContainer:
	var have := InventoryManager.count_item(item)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)

	var icon := TextureRect.new()
	icon.texture = item.item_texture
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.text = "%s  %d/%d" % [item.item_name, have, need]
	label.add_theme_font_size_override(&"font_size", 24)
	label.add_theme_color_override(&"font_color", ENOUGH_COLOR if have >= need else SHORT_COLOR)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	return row
