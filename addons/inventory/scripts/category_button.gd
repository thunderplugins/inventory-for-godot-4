extends Button

# Paths
@export_group("Paths")
@export var crafting_manager: Node

@onready var category_container = get_parent()
@onready var crafting_menu = get_parent().get_parent().get_parent().get_parent()

func _on_pressed() -> void:
	crafting_manager._on_category_button_pressed(category_container.name, crafting_menu.name)
