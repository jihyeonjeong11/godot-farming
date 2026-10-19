class_name BaseTooltip
extends VBoxContainer


func show_item(item: Item) -> void:
	%NameLabel.text = item.item_name
	%TypeLabel.text = DataTypes.ItemType.keys()[item.item_type]
	%DescriptionLabel.text = item.description
	%DescriptionLabel.visible = not str(item.description).is_empty()
	%Separator.visible = %DescriptionLabel.visible
