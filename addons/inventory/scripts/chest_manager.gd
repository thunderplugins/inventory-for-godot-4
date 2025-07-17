extends Node

# Exported Variables
# Paths
@export_group("Paths")
@export var inventory_manager: Node
@export var chest: Node
@export var chest_grid: Node

# Information
var slots = 0
var items = []
var info = {
	"selected_slot_positions": [],
	"right_clicked_slot_positions": [],
	"recent_holding_slot": null,
	"recent_holded_slot": null
}

# Processing
func _ready() -> void:
	save_slots_amount()
	remove_all_slots()
	add_all_slots()

func _process(_delta):
	# Update slots & items
	var slot_position = 0
	for slot in chest_grid.get_children():
		slot.update_item(items[slot_position])
		slot_position += 1

# Selectors
func get_first_selected_slot():
	return info.selected_slot_positions[0]
func get_second_selected_slot():
	return info.selected_slot_positions[1]
func get_recent_selected_slot():
	return info.selected_slot_positions.back()
func get_recent_holded_slot():
	return info.recent_holded_slot
func get_recent_holding_slot():
	return info.recent_holding_slot
func get_item_in_first_selected_slot():
	return items[get_first_selected_slot()]
func get_item_in_second_selected_slot():
	return items[get_second_selected_slot()]
func get_item_in_recent_selected_slot():
	return items[info.selected_slot_positions.back()]
func get_recent_right_clicked_slot():
	return info.right_clicked_slot_positions.back()
func get_item_in_recent_right_clicked_slot():
	return items[info.right_clicked_slot_positions.back()]
func get_item_in_recent_holded_slot():
	return inventory_manager.info.draggable_item.item
func get_item_in_recent_holding_slot():
	return items[info.recent_holding_slot]

func get_item_in_slot(slot_pos: int):
	var pos = 0
	for slot in chest.get_child(0).get_children():
		if int(str(slot.name)) == slot_pos:
			return items[pos]
		pos += 1
	return null

# Verifiers
func has_just_one_selected_slot():
	return info.selected_slot_positions.size() == 1
func has_at_least_one_selected_slot():
	return info.selected_slot_positions.size() > 0
func has_two_selected_slots():
	return info.selected_slot_positions.size() == 2
func has_holded_slot():
	return info.recent_holded_slot != null
func has_holding_slot():
	return info.recent_holding_slot != null
func has_same_holding_slot_as_holded_slot():
	return info.recent_holding_slot == info.recent_holded_slot

func has_item_in_first_selected_slot():
	return items[get_first_selected_slot()] != null
func has_item_in_second_selected_slot():
	return items[get_second_selected_slot()] != null
func has_item_in_recent_selected_slot():
	return items[info.selected_slot_positions.back()] != null
func has_item_in_recent_holded_slot():
	return inventory_manager.info.draggable_item != null
func has_item_in_recent_holding_slot():
	return items[info.recent_holding_slot] != null

func has_empty_slot():
	for item in items:
		if item == null:
			return true
	return false

# Slots Management
func save_slots_amount():
	slots = chest_grid.get_child_count()

func add_all_slots():
	# Add all visual slots
	for pos in slots:
		# Initialize the item
		items.append(null)
		
		# Set up the slot
		var slot_child = load("res://addons/inventory/scenes/slot.tscn").instantiate()
		slot_child.name = str(pos)
		slot_child.interacted.connect(slot_interacted)
		chest_grid.add_child(slot_child)

func remove_all_slots():
	for slot in chest_grid.get_children():
		slot.free()

func select_slot(slot_position):
	info.selected_slot_positions.append(slot_position)
	for slot in chest_grid.get_children():
		if slot.name == str(slot_position):
			slot.select()

func unselect_slots():
	for slot in chest_grid.get_children():
		slot.unselect()
	info.selected_slot_positions.clear()

func reselect_slot(slot_position):
	unselect_slots()
	select_slot(slot_position)

func unhold_slots():
	info.recent_holding_slot = null
	info.recent_holded_slot = null

func return_dragged_item_to_slot():
	items[info.recent_holded_slot] = inventory_manager.info.draggable_item.item

func remove_item(slot_pos: int):
	items[slot_pos] = null

func slot_interacted(slot_position: int, interaction_type: String, storage_name: String):
	# Save info
	if interaction_type == "holded_slot":
		info.recent_holded_slot = slot_position
	elif interaction_type == "entered_slot":
		info.recent_holding_slot = slot_position
	elif interaction_type == "exited_slot":
		info.recent_holding_slot = null
	elif interaction_type == "released_slot_while_holding":
		# If is dragging
		if has_holded_slot():
			if has_holding_slot() and not has_same_holding_slot_as_holded_slot():
				if has_item_in_recent_holded_slot() and has_item_in_recent_holding_slot():
					if get_item_in_recent_holded_slot().item.name == get_item_in_recent_holding_slot().item.name and get_item_in_recent_holded_slot().item.durability == get_item_in_recent_holding_slot().item.durability:
						transfer_amounts()
					else:
						swap_items()
						inventory_manager.emit_signal("added_item_to_storage", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
				elif has_item_in_recent_holded_slot():
					swap_items()
					inventory_manager.emit_signal("added_item_to_storage", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
			unhold_slots()
	elif interaction_type == "selected_slot":
		# If is selecting
		select_slot(slot_position)
		
		if has_two_selected_slots():
			if get_first_selected_slot() == get_second_selected_slot():
				unselect_slots()
			else:
				if has_item_in_first_selected_slot() and has_item_in_second_selected_slot():
					if get_item_in_first_selected_slot().item.name == get_item_in_second_selected_slot().item.name and get_item_in_first_selected_slot().item.durability == get_item_in_second_selected_slot().item.durability:
						transfer_amounts()
						unselect_slots()
					else:
						swap_items()
						unselect_slots()
						inventory_manager.emit_signal("added_item_to_storage", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
				elif has_item_in_first_selected_slot():
					swap_items()
					unselect_slots()
					inventory_manager.emit_signal("added_item_to_storage", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
				else:
					reselect_slot(slot_position)
	elif interaction_type == "released_right_inside":
		info.right_clicked_slot_positions.append(slot_position)
		if get_item_in_recent_right_clicked_slot() != null and has_empty_slot() and inventory_manager.allow_item_divison:
			divide_item(slot_position)
		info.right_clicked_slot_positions.clear()
		
	# Send slot notifications to the inventory manager
	inventory_manager.slot_interacted(slot_position, interaction_type, "chest")

# Transfer Items
func transfer_amounts():
	var first_amount
	var second_amount
	var first_slot
	var second_slot
	var stack_limit
	
	# If dragged
	if has_holded_slot():
		first_amount = get_item_in_recent_holded_slot().amount
		second_amount = get_item_in_recent_holding_slot().amount
		first_slot = get_recent_holded_slot()
		second_slot = get_recent_holding_slot()
		stack_limit = get_item_in_recent_holded_slot().item.stack_limit
	# If selected slots
	else:
		first_amount = get_item_in_first_selected_slot().amount
		second_amount = get_item_in_second_selected_slot().amount
		first_slot = get_first_selected_slot()
		second_slot = get_second_selected_slot()
		stack_limit = get_item_in_first_selected_slot().item.stack_limit
		
	if stack_limit > 1:
		# Calculate how much can be added to the second slot
		var can_add_amount = stack_limit - second_amount
		var amount_to_transfer = min(first_amount, can_add_amount)
		
		# Update the slots
		second_amount += amount_to_transfer
		first_amount -= amount_to_transfer
		
		# Update the array
		if first_amount > 0:
			# If dragged
			if has_holded_slot():
				inventory_manager.info.draggable_item.item.amount = first_amount
				return_dragged_item_to_slot()
			# If selected slots
			else:
				items[first_slot].amount = first_amount
		else:
			items[first_slot] = null
			
		items[second_slot].amount = second_amount  # This line now updates the second slot
	else:
		if has_holded_slot():
			return_dragged_item_to_slot()

# Swap Items
func swap_items():
	# If dragged
	if has_holded_slot():
		var temp = get_item_in_recent_holding_slot()
		items[info.recent_holding_slot] = get_item_in_recent_holded_slot()
		items[info.recent_holded_slot] = temp
	# If selected slots
	else:
		var temp = items[get_second_selected_slot()]
		items[get_second_selected_slot()] = items[get_first_selected_slot()]
		items[get_first_selected_slot()] = temp

# Divide Item
func divide_item(slot_position: int):
	var amount_per_slot = 0
	var leftover = 0
	amount_per_slot = int(get_item_in_recent_right_clicked_slot().amount / 2)
	leftover = int(get_item_in_recent_right_clicked_slot().amount % 2)
	if amount_per_slot > 0:
		items[get_recent_right_clicked_slot()].amount = amount_per_slot + leftover
		for pos in items.size():
			if items[pos] == null:
				var inventory_item = InventoryItem.new()
				inventory_item.item = get_item_in_recent_right_clicked_slot().item.duplicate()
				inventory_item.amount = amount_per_slot
				items[pos] = inventory_item
				break

# Drop Item
func drop_item(item_position):
	if has_at_least_one_selected_slot() and has_item_in_recent_selected_slot():
		items[get_recent_selected_slot()].amount -= 1
		spawn_item(get_item_in_recent_selected_slot().item, item_position)
		if get_item_in_recent_selected_slot().amount <= 0:
			items[get_recent_selected_slot()] = null
			unselect_slots()
		inventory_manager.emit_signal("dropped_item")

# Spawn Item
func spawn_item(item: Item, item_position: Vector2):
	inventory_manager.spawn_item(item, item_position)

# Load Items
func load_items(saved_items):
	set_process(false)
	if not saved_items.is_empty():
		items = saved_items
	# Initialize the empty items
	#for pos in slots:
	#	if not items.size() > pos:
	#		items[pos] = null
	set_process(true)
