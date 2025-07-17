extends Button

# Paths
@export_group("Paths")
@export var crafting_manager: Node

@onready var item_container = get_parent().get_parent().get_parent()
@onready var category = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
@onready var crafting_menu = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()

func _on_pressed() -> void:
	crafting_manager._on_item_button_pressed(item_container.name, category.name, crafting_menu.name)
