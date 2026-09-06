extends Node

const RECIPE_ROOT := "res://scripts/resources/recipes"

var _recipes: Array[CraftRecipe] = []


func _ready() -> void:
	_scan(RECIPE_ROOT)
	_recipes.sort_custom(func(a: CraftRecipe, b: CraftRecipe) -> bool:
		return a.display_name().naturalnocasecmp_to(b.display_name()) < 0)


func all() -> Array[CraftRecipe]:
	return _recipes.duplicate()


func for_result(id: StringName) -> Array[CraftRecipe]:
	var found: Array[CraftRecipe] = []
	for recipe in _recipes:
		if recipe.result_id == id:
			found.append(recipe)
	return found


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[RecipeDB] 폴더를 열지 못했다: %s" % path)
		return

	for sub_dir in dir.get_directories():
		_scan("%s/%s" % [path, sub_dir])

	for file_name in dir.get_files():
		var res_name := file_name.trim_suffix(".remap")
		if not res_name.ends_with(".tres"):
			continue

		var res_path := "%s/%s" % [path, res_name]
		var recipe := load(res_path) as CraftRecipe
		if recipe == null:
			continue

		var problems := recipe.validate()
		if not problems.is_empty():
			push_error("[RecipeDB] 조합법이 잘못됐다: %s\n%s" % [res_path, "\n".join(problems)])
			continue

		_recipes.append(recipe)
