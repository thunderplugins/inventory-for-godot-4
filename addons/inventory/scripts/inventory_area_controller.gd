extends Area2D

# Paths
@onready var inventory_manager: Node = get_parent().get_node("inventory_manager")
@onready var chest_manager: Node = get_parent().get_node("inventory_manager").chest_manager

# Interaction
func _on_area_entered(area: Area2D) -> void:
	# If touched chest
	if area.name == "chest_controller":
		chest_manager.load_items(area.items)
		inventory_manager.enter_chest_and_inventory()
		
	# If touched crafting table
	if area.name == "crafting_controller":
		inventory_manager.enter_crafting_and_inventory(area.menu_to_open)

func _on_area_exited(area: Area2D) -> void:
	# If left chest
	if area.name == "chest_controller":
		area.items = chest_manager.items
		inventory_manager.leave_entered_area()
	
	# If left crafting table
	if area.name == "crafting_controller":
		inventory_manager.leave_entered_area()
		
