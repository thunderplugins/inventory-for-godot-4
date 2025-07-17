extends Node

# Exported Variables
@export_group("Settings")
@export var storages: Array[Storage]

# Paths
@export_group("Paths")
@export var inventory_manager: Node
@export var hotbar: Node

# Information
var items = []
var info = {
	"selected_slot_positions": [],
	"right_clicked_slot_positions": [],
	"recent_holding_slot": null,
	"recent_holded_slot": null,
	"recent_hotbar_slot": 0
}

# Processing
func _ready():
	remove_all_slots()
	add_all_slots()
	select_slot(info.recent_hotbar_slot)
	notify_grabbed_item()

func _process(_delta):
	# Update slots & items
	var slot_position = 0
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
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
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
			if int(str(slot.name)) == slot_pos:
				return items[pos]
			pos += 1
	return null
func get_storage_name(slot_position):
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
			if int(str(slot.name)) == slot_position:
				return str(get_node(storage.node_path).name)
	return ""

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

func dictionaries_are_equal(dict1: Dictionary, dict2: Dictionary) -> bool:
	# Check if the number of keys is the same
	if dict1.size() != dict2.size():
		return false
	
	# Check if all keys and their associated values in dict1 match those in dict2
	for key in dict1.keys():
		if not dict2.has(key): # Check if dict2 contains the key
			return false
		if dict1[key] != dict2[key]: # Check if the values are the same
			return false
	
	# If all checks pass, the dictionaries are equal
	return true
func has_items(given_items) -> bool:
	if given_items != null:
		var completed_items = {}
		
		# For each inventory item
		for inventory_item in items:
			# If inventory item exists
			if inventory_item != null:
				# For each given item name
				for given_item in given_items.keys():
					# Initializing the variables
					var given_item_name = given_item
					var given_item_amount = given_items[given_item]
					
					if not completed_items.has(given_item_name):
						completed_items[given_item_name] = 0
					
					# If we find the item we searched
					if inventory_item.item.name == given_item_name:
						if inventory_item.amount < given_item_amount:
							completed_items[given_item_name] += inventory_item.amount
							
							if completed_items[given_item_name] > given_item_amount:
								completed_items[given_item_name] = given_item_amount
						else:
							completed_items[given_item_name] = given_item_amount
							
					# If we found all items and its amounts
					if dictionaries_are_equal(given_items, completed_items):
						return true
	return false
func is_allowed_item(item_name: String, storage_name: String):
	for storage in storages:
		if get_node(storage.node_path).name == storage_name:
			if storage.allowed_items.is_empty():
				return true
			elif item_name in storage.allowed_items:
				return true
			return false
	return false
func are_allowed_items_to_swap():
	var first_item_name
	var second_item_name
	var first_item_storage
	var second_item_storage 
	
	# If dragged
	if has_holded_slot():
		first_item_name = get_item_in_recent_holded_slot().item.name
		second_item_name = get_item_in_recent_holding_slot().item.name
		first_item_storage = get_storage_name(get_recent_holded_slot())
		second_item_storage = get_storage_name(get_recent_holding_slot())
	# If selected slots
	else:
		first_item_name = get_item_in_first_selected_slot().item.name
		second_item_name = get_item_in_second_selected_slot().item.name
		first_item_storage = get_storage_name(get_first_selected_slot())
		second_item_storage = get_storage_name(get_second_selected_slot())
	
	if is_allowed_item(first_item_name, second_item_storage) and is_allowed_item(second_item_name, first_item_storage):
		return true
	return false

# Slots Management
func add_all_slots():
	var global_pos = 0
	for storage in storages:
		for number in get_node(storage.node_path).get_child(0).get_children():
			# Initialize the item
			items.append(null)
			
			# Set up the slot
			var slot_child = load("res://addons/inventory/scenes/slot.tscn").instantiate()
			slot_child.name = str(global_pos)
			slot_child.interacted.connect(slot_interacted)
			
			get_node(storage.node_path).get_child(0).add_child(slot_child)
			
			# Increment pos
			global_pos += 1

func remove_all_slots():
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
			slot.queue_free()

func select_slot(slot_position):
	info.selected_slot_positions.append(slot_position)
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
			if slot.name == str(slot_position):
				slot.select()

func unselect_slots():
	for storage in storages:
		for slot in get_node(storage.node_path).get_child(0).get_children():
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

func slot_interacted(slot_position: int, interaction_type: String, storage_name: String):
	# Save info
	if interaction_type == "holded_slot":
		if inventory_manager.has_opened_menu():
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
						if are_allowed_items_to_swap():
							swap_items()
							inventory_manager.emit_signal("moved_item_to", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
							notify_removed_item_from_hold()
						else:
							return_dragged_item_to_slot()
				elif has_item_in_recent_holded_slot():
					if is_allowed_item(get_item_in_recent_holded_slot().item.name, get_storage_name(get_recent_holding_slot())):
						swap_items()
						inventory_manager.emit_signal("moved_item_to", get_item_in_recent_holding_slot().item.name, slot_position, storage_name)
						notify_removed_item_from_hold()
					else:
						return_dragged_item_to_slot()
			elif has_item_in_recent_holded_slot():
				return_dragged_item_to_slot()
			unhold_slots()
	elif interaction_type == "selected_slot":
		if not inventory_manager.has_opened_menu():
			info.recent_hotbar_slot = slot_position
		
		# If is selecting
		select_slot(slot_position)
		notify_grabbed_item()
		
		if has_two_selected_slots():
			if get_first_selected_slot() == get_second_selected_slot():
				if inventory_manager.has_opened_menu():
					unselect_slots()
				else:
					reselect_slot(slot_position)
			else:
				if has_item_in_first_selected_slot() and has_item_in_second_selected_slot():
					if get_item_in_first_selected_slot().item.name == get_item_in_second_selected_slot().item.name and get_item_in_first_selected_slot().item.durability == get_item_in_second_selected_slot().item.durability:
						if inventory_manager.has_opened_menu():
							transfer_amounts()
							unselect_slots()
						else:
							reselect_slot(slot_position)
					else:
						if inventory_manager.has_opened_menu() and are_allowed_items_to_swap():
							swap_items()
							inventory_manager.emit_signal("moved_item_to", get_item_in_recent_selected_slot().item.name, slot_position, storage_name)
							notify_removed_item()
							unselect_slots()
						else:
							reselect_slot(slot_position)
				# Check for allowed items
				elif has_item_in_first_selected_slot() and inventory_manager.has_opened_menu() and is_allowed_item(get_item_in_first_selected_slot().item.name, get_storage_name(get_second_selected_slot())):
					swap_items()
					inventory_manager.emit_signal("moved_item_to", get_item_in_recent_selected_slot().item.name, slot_position, storage_name)
					notify_removed_item()
					unselect_slots()
				else:
					reselect_slot(slot_position)
	elif interaction_type == "released_right_inside":
		info.right_clicked_slot_positions.append(slot_position)
		if get_parent().allow_item_divison and get_item_in_recent_right_clicked_slot() != null:
			divide_item(get_storage_name(slot_position), slot_position)
		info.right_clicked_slot_positions.clear()
		
	# Send slot notifications to the inventory manager
	if not inventory_manager.has_opened_menu() and interaction_type == "holded_slot":
		pass
	else:
		inventory_manager.slot_interacted(slot_position, interaction_type, "storage")

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
func divide_item(slot_storage_name: String, slot_position: int):
	var amount_per_slot = 0
	var leftover = 0
	amount_per_slot = int(get_item_in_recent_right_clicked_slot().amount / 2)
	leftover = int(get_item_in_recent_right_clicked_slot().amount % 2)
	if amount_per_slot > 0:
		for pos in range(0,items.size()):
			if items[pos] == null:
				for storage in storages:
					var storage_name = get_storage_name(pos)
					if get_node(storage.node_path).name == storage_name:
						if storage.collect_items and is_allowed_item(get_item_in_recent_right_clicked_slot().item.name, get_storage_name(pos)):
							# Saves item
							var inventory_item = InventoryItem.new()
							inventory_item.item = get_item_in_recent_right_clicked_slot().item.duplicate()
							inventory_item.amount = amount_per_slot
							items[pos] = inventory_item
							items[get_recent_right_clicked_slot()].amount = amount_per_slot + leftover
							return
						break

# Collect Ttem
func collect_item(given_item: Item):
	# Check for allowed items
	var pos = 0
	for item in items:
		if item != null:
			if items[pos].item.name == given_item.name:
				if items[pos].amount < items[pos].item.stack_limit:
					items[pos].amount += 1
					inventory_manager.emit_signal("collected_item")
					return true
		pos += 1
	pos = 0
	for item in items:
		if item == null:
			# Check if storage can collect items
			var storage_name = get_storage_name(pos)
			for storage in storages:
				if get_node(storage.node_path).name == storage_name:
					if storage.collect_items and is_allowed_item(given_item.name, get_storage_name(pos)):
						# Collect item and notify that we did
						var inventory_item = InventoryItem.new()
						inventory_item.item = given_item
						inventory_item.amount = 1
						items[pos] = inventory_item
						inventory_manager.emit_signal("collected_item")
						return true
					else:
						break
		pos += 1
	return false

# Use Item
func use_item(remove_amount: int):
	if has_just_one_selected_slot() and has_item_in_first_selected_slot() and not inventory_manager.has_opened_menu():
		if items[get_recent_selected_slot()].item.max_durability != 0:
			items[get_recent_selected_slot()].item.durability -= remove_amount
			inventory_manager.emit_signal("used_item", items[get_recent_selected_slot()].item.name, remove_amount)
			if items[get_recent_selected_slot()].item.durability <= 0:
				if items[get_recent_selected_slot()].amount > 1:
					items[get_recent_selected_slot()].amount -= 1
					items[get_recent_selected_slot()].item.durability = items[get_recent_selected_slot()].item.max_durability
				else:
					inventory_manager.emit_signal("finished_item", items[get_recent_selected_slot()].item.name)
					items[get_recent_selected_slot()] = null

# Remove Items
func remove_items(given_items: Dictionary):
	var items_to_remove = given_items.duplicate()  # Avoid modifying the original dictionary
	
	var pos = 0
	for inventory_item in items:
		if items[pos] != null:  # Check if the item exists before accessing properties
			for given_item in items_to_remove.keys():
				var given_item_name = given_item
				var given_item_amount = items_to_remove[given_item_name]
				
				if items[pos] != null and items[pos].item.name == given_item_name:  # Extra safety check
					var remove_amount = min(given_item_amount, items[pos].amount)
					items[pos].amount -= remove_amount
					items_to_remove[given_item_name] -= remove_amount
					
					if items[pos].amount <= 0:
						items[pos] = null
		pos += 1

func remove_item(slot_pos: int):
	items[slot_pos] = null

# Drop Item
func drop_item(item_position):
	if has_at_least_one_selected_slot() and has_item_in_recent_selected_slot():
		items[get_recent_selected_slot()].amount -= 1
		spawn_item(get_item_in_recent_selected_slot().item, item_position)
		if get_item_in_recent_selected_slot().amount <= 0:
			items[get_recent_selected_slot()] = null
		inventory_manager.emit_signal("dropped_item")

# Spawn Item
func spawn_item(item: Item, item_position: Vector2):
	inventory_manager.spawn_item(item, item_position)

func notify_grabbed_item():
	if not inventory_manager.has_opened_menu():
		if has_item_in_recent_selected_slot():
			inventory_manager.emit_signal("holding_item", get_item_in_recent_selected_slot().item.name)

func notify_removed_item():
	if has_at_least_one_selected_slot():
		if not has_item_in_first_selected_slot():
			inventory_manager.emit_signal("removed_item_in", get_first_selected_slot(), get_storage_name(get_first_selected_slot()))

func notify_removed_item_from_hold():
	if has_holded_slot():
		if items[info.recent_holded_slot] == null:
			inventory_manager.emit_signal("removed_item_in", get_recent_holded_slot(), get_storage_name(get_recent_holded_slot()))
