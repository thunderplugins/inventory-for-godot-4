extends Control

# Settings
@export_group("Textures")
@export var normal_texture = Texture2D
@export var selected_texture = Texture2D

# Reference
@onready var menu = get_parent().get_parent().get_parent().get_parent()

@onready var slot_texture = $slot_texture
@onready var item_texture = $item_texture
@onready var amount = $amount
@onready var details = $details
@onready var durability = $durability
@onready var holding_timer = $holding_timer

# Signals
signal interacted()

# Information
@onready var storage_name: String = get_parent().get_parent().name

var is_mouse_inside = false
var is_mouse_inside_gui = false

# Verifiers
func finished_holding_time():
	return holding_timer.time_left == 0

# Processing
func _process(_delta: float) -> void:
	if is_mouse_inside:
		details.position = Vector2(15,-18) + get_local_mouse_position()

func _input(event):
	if is_mouse_inside:
		if event is InputEventMouseButton and not event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				call_deferred("emit_signal", "interacted", get_slot(), "released_slot_while_holding", storage_name)

# Managing interaction
func _on_interact_detector_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# To divide items
			emit_signal("interacted", get_slot(), "released_right_inside", storage_name)

func _on_interact_detector_button_down() -> void:
	holding_timer.start()

func _on_interact_detector_button_up() -> void:
	if is_mouse_inside and not finished_holding_time():
		# If released less than 0.3 after holding, select slot
		emit_signal("interacted", get_slot(), "selected_slot", storage_name)
	# For dragging accross storage and chest
	emit_signal("interacted", get_slot(), "released_slot_inside_or_outside", storage_name)
	holding_timer.stop()

func _on_holding_timer_timeout() -> void:
	# To get the draggable item
	emit_signal("interacted", get_slot(), "holded_slot", storage_name)

func _on_interact_detector_mouse_entered() -> void:
	is_mouse_inside = true
	# To get the placeholers to drop the dragged item
	emit_signal("interacted", get_slot(), "entered_slot", storage_name)

func _on_interact_detector_mouse_exited() -> void:
	is_mouse_inside = false
	# To erase the recent placeholder
	emit_signal("interacted", get_slot(), "exited_slot", storage_name)

# Functions
func get_slot():
	var string: String = self.name
	return int(string)

func select():
	slot_texture.texture = selected_texture

func unselect():
	slot_texture.texture = normal_texture

func update_item(inventory_item: InventoryItem):
	if inventory_item != null:
		# Update visual items (texture)
		item_texture.texture = inventory_item.item.texture
		# Update visual items (amount)
		if inventory_item.amount == 1:
			amount.text = ""
		elif inventory_item.amount < 1:
			clear_item()
		else:
			amount.text = str(inventory_item.amount)
		# Update visual items (details)		
		if is_mouse_inside:
			details.text = inventory_item.item.name
			details.show()
		else:
			details.hide()
		details.size.x = 0
		# Update durability
		if inventory_item.item.max_durability != 0 and inventory_item.item.max_durability != 1:
			durability.value = inventory_item.item.durability
			durability.max_value = inventory_item.item.max_durability
			durability.show()
			if inventory_item.item.durability < 1:
				durability.hide() 
		else:
			durability.hide()
	else:
		clear_item()

func clear_item():
	item_texture.texture = null
	amount.text = ""
	durability.hide()
	details.hide()
