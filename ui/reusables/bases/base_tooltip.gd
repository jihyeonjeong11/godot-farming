class_name BaseTooltip
extends VBoxContainer


func show_item(item: Item) -> void:
	%NameLabel.text = item.item_name
	%TypeLabel.text = DataTypes.ItemType.keys()[item.item_type]
	%DescriptionLabel.text = item.description
	%DescriptionLabel.visible = not str(item.description).is_empty()

	for child in %StatsBox.get_children():
		child.queue_free()
	for stat in item.stat_lines():
		var label := Label.new()
		label.text = stat.text
		label.add_theme_color_override(&"font_color", stat.color)
		label.add_theme_font_size_override(&"font_size", 24)
		%StatsBox.add_child(label)
	%StatsBox.visible = not item.stat_lines().is_empty()

	%Separator.visible = %DescriptionLabel.visible or %StatsBox.visible
