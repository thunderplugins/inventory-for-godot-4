extends Node

# Things you can do:
# spawn_item(item: Item, item_position: Vector2) - to summon items.
# use the signals - to know which item to show on hand or to know which
# armor to show on body, to know when to play sounds, to know when you 
# can break or place blocks, etc.
# customize everything.

# Variables
@export_group("Settings")
@export var allow_item_divison = true
@export var allow_item_drop = true
@export var open_inventory_input = "ui_accept"
@export var drop_item_input = "ui_focus_next"
@export var use_item_input = "ui_text_delete"

# Paths
@onready var main = get_parent().get_parent()
@onready var player = get_parent()

@export_group("Paths")
@export var storage_manager: Node
@export var chest_manager: Node
@export var crafting_manager: Node

@export var hotbar: Node
@export var chest: Node
@export var equipment: Node

@export var craft_section: Node

# Signals
signal opened_menu(menu_name: String)
signal closed_menu(menu_name: String)
signal opened_chest()
signal closed_chest()

signal moved_item_to(item_name: String, slot: int, storage_name: String)
signal removed_item_in(slot: int, storage_name: String)
signal used_item(item_name: String, amount: int)
signal finished_item(item_name: String)
signal crafted_item(item_name: String)
signal dropped_item()
signal collected_item()
signal holding_item(item_name: String)

# Information
var entered_area
var info = {
	"draggable_item": null,
	"dragging": false
}

# Verifiers
func has_opened_menu():
	return entered_area != null

# Selectors
func get_item_via_slot(slot: int, menu_name: String):
	if menu_name == "storage":
		return storage_manager.get_item_in_slot(slot)
	elif menu_name == "chest":
		return chest_manager.get_item_in_slot(slot)

# Processing
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(open_inventory_input):
		if entered_area == null:
			enter_crafting_and_inventory("crafting_menu")
		elif entered_area == "crafting_menu":
			leave_entered_area()
		
	if Input.is_action_just_pressed(drop_item_input) and allow_item_drop:
		drop_item(get_parent().position + Vector2(0, 70))
		
	if Input.is_action_just_pressed(use_item_input):
		storage_manager.use_item(1)
		
	# Process dragging
	if info.dragging:
		info.draggable_item.position = get_viewport().get_mouse_position()

# Global Slot Management
func slot_interacted(slot_position: int, interaction_type: String, menu_name: String):
	# Save info
	if interaction_type == "holded_slot":
		# Load item data
		var item
		if menu_name == "storage":
			item = get_item_via_slot(slot_position, "storage")
		elif menu_name == "chest":
			item = get_item_via_slot(slot_position, "chest")
			
		# Add draggable item
		if item != null:
			# Remove item from slot
			if menu_name == "storage":
				storage_manager.remove_item(slot_position)
			elif menu_name == "chest":
				chest_manager.remove_item(slot_position)
			
			# Spawn draggable item
			var draggable_item = load("res://addons/inventory/scenes/draggable_item.tscn").instantiate()
			draggable_item.item = item
			draggable_item.position = get_viewport().get_mouse_position()
			add_child(draggable_item)
			move_child(draggable_item, 0)
			
			# Start dragging
			info.dragging = true
			info.draggable_item = draggable_item
	elif interaction_type == "released_slot_while_holding":
		reset_drag()
	elif interaction_type == "released_slot_inside_or_outside":
		# Process storage and chest dragging
		if menu_name == "chest" and chest_manager.has_item_in_recent_holded_slot() and not chest_manager.has_holding_slot() and storage_manager.has_holding_slot():
			swap_inventory_and_chest_items()
			reset_drag()
		elif menu_name == "storage" and storage_manager.has_item_in_recent_holded_slot() and not storage_manager.has_holding_slot() and chest_manager.has_holding_slot():
			swap_inventory_and_chest_items()
			reset_drag()
		# Reset drag and hold
		elif menu_name == "chest" and chest_manager.has_item_in_recent_holded_slot() and not chest_manager.has_holding_slot():
			chest_manager.return_dragged_item_to_slot()
			reset_drag()
		elif menu_name == "storage" and storage_manager.has_item_in_recent_holded_slot() and not storage_manager.has_holding_slot():
			storage_manager.return_dragged_item_to_slot()
			reset_drag()
	elif interaction_type == "selected_slot":
		# Process storage and chest selections
		if storage_manager.has_at_least_one_selected_slot() and chest_manager.has_at_least_one_selected_slot():
			# If inventory slot was the last to get selected
			if menu_name == "storage":
				if storage_manager.has_item_in_recent_selected_slot() and chest_manager.has_item_in_recent_selected_slot():
					if storage_manager.get_item_in_recent_selected_slot().item.name == chest_manager.get_item_in_recent_selected_slot().item.name and storage_manager.get_item_in_recent_selected_slot().item.durability == chest_manager.get_item_in_recent_selected_slot().item.durability:
						transfer_amounts("storage")
						unselect_all_slots()
					else:
						swap_inventory_and_chest_items()
						unselect_all_slots()
				elif chest_manager.has_item_in_first_selected_slot():
					swap_inventory_and_chest_items()
					unselect_all_slots()
				else:
					chest_manager.unselect_slots()
					storage_manager.reselect_slot(storage_manager.get_recent_selected_slot())
			# If chest slot was the last to get selected
			elif menu_name == "chest":
				if chest_manager.has_item_in_recent_selected_slot() and storage_manager.has_item_in_recent_selected_slot():
					if storage_manager.get_item_in_recent_selected_slot().item.name == chest_manager.get_item_in_recent_selected_slot().item.name and storage_manager.get_item_in_recent_selected_slot().item.durability == chest_manager.get_item_in_recent_selected_slot().item.durability:
						transfer_amounts("chest")
						unselect_all_slots()
					else:
						swap_inventory_and_chest_items()
						unselect_all_slots()
				elif storage_manager.has_item_in_first_selected_slot():
					swap_inventory_and_chest_items()
					unselect_all_slots()
				else:
					storage_manager.unselect_slots()
					chest_manager.reselect_slot(chest_manager.get_recent_selected_slot())

func unselect_all_slots():
	storage_manager.unselect_slots()
	chest_manager.unselect_slots()

func reset_drag():
	if info.dragging:
		info.draggable_item.queue_free()
		info.draggable_item = null
		info.dragging = false
		storage_manager.unhold_slots()
		chest_manager.unhold_slots()

func transfer_amounts(recent_menu_name: String):
	var first_amount
	var second_amount
	var first_slot
	var second_slot
	var stack_limit
	
	if recent_menu_name == "storage":
		first_amount = chest_manager.get_item_in_recent_selected_slot().amount
		second_amount = storage_manager.get_item_in_recent_selected_slot().amount
		first_slot = chest_manager.get_recent_selected_slot()
		second_slot = storage_manager.get_recent_selected_slot()
		stack_limit = chest_manager.get_item_in_recent_selected_slot().item.stack_limit
	elif recent_menu_name == "chest":
		first_amount = storage_manager.get_item_in_recent_selected_slot().amount
		second_amount = chest_manager.get_item_in_recent_selected_slot().amount
		first_slot = storage_manager.get_recent_selected_slot()
		second_slot = chest_manager.get_recent_selected_slot()
		stack_limit = storage_manager.get_item_in_recent_selected_slot().item.stack_limit
	
	# Calculate how much can be added to the second slot
	var can_add_amount = stack_limit - second_amount
	var amount_to_transfer = min(first_amount, can_add_amount)
	
	# Update the slots
	second_amount += amount_to_transfer
	first_amount -= amount_to_transfer
	
	if recent_menu_name == "storage":
		# Update the array
		if first_amount > 0:
			chest_manager.items[first_slot].amount = first_amount
		else:
			chest_manager.items[first_slot] = null
		storage_manager.items[second_slot].amount = second_amount  # This line now updates the second slot
	elif recent_menu_name == "chest":
		# Update the array
		if first_amount > 0:
			storage_manager.items[first_slot].amount = first_amount
		else:
			storage_manager.items[first_slot] = null
		chest_manager.items[second_slot].amount = second_amount  # This line now updates the second slot

# Swap Items
func swap_inventory_and_chest_items():
	# If dragged accross menus
	if storage_manager.has_holded_slot() and chest_manager.has_holding_slot():
		var temp = chest_manager.get_item_in_recent_holding_slot()
		chest_manager.items[chest_manager.get_recent_holding_slot()] = storage_manager.get_item_in_recent_holded_slot()
		storage_manager.items[storage_manager.get_recent_holded_slot()] = temp
	elif chest_manager.has_holded_slot() and storage_manager.has_holding_slot():
		var temp = storage_manager.get_item_in_recent_holding_slot()
		storage_manager.items[storage_manager.get_recent_holding_slot()] = chest_manager.get_item_in_recent_holded_slot()
		chest_manager.items[chest_manager.get_recent_holded_slot()] = temp
	# If dragged on each menu
	elif storage_manager.has_holded_slot():
		var temp = storage_manager.items[storage_manager.get_recent_holded_slot()]
		chest_manager.items[chest_manager.get_recent_holding_slot()] = storage_manager.items[storage_manager.get_recent_holded_slot()]
		storage_manager.items[storage_manager.get_recent_holded_slot()] = temp
	elif chest_manager.has_holded_slot():
		var temp = chest_manager.items[chest_manager.get_recent_holded_slot()]
		storage_manager.items[storage_manager.get_recent_holding_slot()] = chest_manager.items[chest_manager.get_recent_holded_slot()]
		chest_manager.items[chest_manager.get_recent_holded_slot()] = temp
	# If selected slots
	else:
		var temp = chest_manager.items[chest_manager.get_recent_selected_slot()]
		chest_manager.items[chest_manager.get_recent_selected_slot()] = storage_manager.items[storage_manager.get_recent_selected_slot()]
		storage_manager.items[storage_manager.get_recent_selected_slot()] = temp

# Drop Item
func drop_item(item_position):
	storage_manager.drop_item(item_position)
	chest_manager.drop_item(item_position)

# Spawn item
func spawn_item(item: Item, item_position: Vector2):
	var item_child = load("res://addons/inventory/scenes/item.tscn").instantiate()
	item_child.item = item
	item_child.position = item_position
	item_child.scale = Vector2(1, 1)
	main.add_child(item_child)

# Menus
func hide_all_inventory_storages():
	for storage in storage_manager.storages:
		storage_manager.get_node(storage.node_path).hide()

func show_all_inventory_storages():
	for storage in storage_manager.storages:
		storage_manager.get_node(storage.node_path).show()

func hide_all_menus():
	hide_all_inventory_storages()
	chest.hide()
	for menu in crafting_manager.crafting_menus:
		menu.hide()
	craft_section.hide()
	equipment.hide()

func enter_chest_and_inventory():
	hide_all_menus()
	show_all_inventory_storages()
	chest.show()
	entered_area = "chest"
	emit_signal("opened_chest")
	$VBoxContainer.alignment = 1
	unselect_all_slots()

func enter_crafting_and_inventory(crafting_menu_name: String):
	hide_all_menus()
	show_all_inventory_storages()
	for menu in crafting_manager.crafting_menus:
		if menu.name == crafting_menu_name:
			menu.show()
	equipment.show()
	entered_area = crafting_menu_name
	emit_signal("opened_menu", crafting_menu_name)
	$VBoxContainer.alignment = 1
	unselect_all_slots()

func leave_entered_area():
	hide_all_menus()
	hotbar.show()
	if entered_area == "chest":
		emit_signal("closed_chest")
	else:
		emit_signal("closed_menu", entered_area)
	entered_area = null
	$VBoxContainer.alignment = 2
	unselect_all_slots()
	storage_manager.select_slot(storage_manager.info.recent_hotbar_slot)
