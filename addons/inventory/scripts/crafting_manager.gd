extends Node

# Exported Variables
@export_group("Settings")
@export var recipes: Array[Recipe]
@export var crafting_menus: Array[Node]

# Paths
@export_group("Paths")
@onready var main = get_parent().get_parent().get_parent()
@onready var player = get_parent().get_parent()

@export var inventory_manager: Node
@export var storage_manager: Node

@export var equipment: Node

@export var crafting_section: Node
@export var craftable_item: Node
@export var description: Node
@export var needed_items_list: Node
@export var craft_button: Node

# Information
@onready var all_items = preload("res://addons/inventory/data/items.tres").items

var items = {}
var selected_item: Item

# Selectors
func get_item(item_name: String):
	for item in all_items:
		if item.name == item_name:
			return item
	return null

func _on_item_button_pressed(item_name: String, category: String, crafting_menu_name: String):
	# Show the needed items list
	crafting_section.show()
	equipment.hide()
	
	# Get the item we want to craft via name
	var item_to_craft = get_item(item_name)
	
	# Show details of the item before crafting and save selelected item
	craftable_item.texture = item_to_craft.texture
	description.text = item_to_craft.description
	remove_needed_items()
	items.clear()
	for recipe in recipes:
		if recipe.item_name == item_name:
			for needed_item in recipe.needed_items:
				var item = get_item(needed_item.item_name)
				load_needed_items(item, needed_item.amount)
				items[needed_item.item_name] = needed_item.amount
	selected_item = item_to_craft
		
	# Enable or disable craft button if we have enough items
	if storage_manager.has_items(items):
		craft_button.disabled = false
	else:
		craft_button.disabled = true

func _on_equipment_button_pressed() -> void:
	crafting_section.hide()
	equipment.show()

func _on_category_button_pressed(category_name: String, crafting_menu_name: String):
	hide_all_crafting_menu_item_sections()
	for menu in crafting_menus:
		if menu.name == crafting_menu_name:
			# Set the item setion
			menu.get_node("items").get_node(category_name).show()

func hide_all_crafting_menu_item_sections():
	for menu in crafting_menus:
		for section in menu.get_node("items").get_children():
			section.hide()

# Craft Ttem
func _on_craft_pressed():
	# Check if has enough items then spawn item
	if storage_manager.has_items(items):
		selected_item = selected_item.duplicate(true)
		selected_item.durability = selected_item.max_durability
		inventory_manager.spawn_item(selected_item, player.position)
		inventory_manager.emit_signal("crafted_item", selected_item.name)
		storage_manager.remove_items(items)
		
	# Enable or disable craft button if we have enough items
	if storage_manager.has_items(items):
		craft_button.disabled = false
	else:
		craft_button.disabled = true

func remove_needed_items():
	for needed_item in needed_items_list.get_children():
		needed_item.queue_free() 

func load_needed_items(item: Item, amount: int):
	var amount_child = load("res://addons/inventory/scenes/needed_amount.tscn").instantiate()
	amount_child.text = str(amount) + "x"
	
	var item_child = load("res://addons/inventory/scenes/needed_item.tscn").instantiate()
	item_child.get_node("item_texture").texture = item.texture

	needed_items_list.add_child(amount_child)
	needed_items_list.add_child(item_child)
